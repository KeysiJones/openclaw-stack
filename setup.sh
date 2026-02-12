#!/bin/bash
# ============================================
# OpenClaw Stack - Setup Inicial
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
erro() { echo -e "${RED}[ERRO]${NC} $1"; }

echo ""
echo "========================================"
echo "  OpenClaw Stack - Setup Inicial"
echo "========================================"
echo ""

# --- 1. Verificar Docker ---
if ! command -v docker &> /dev/null; then
    erro "Docker nao encontrado. Instale o Docker Engine 20.10+."
    exit 1
fi

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0")
DOCKER_MAJOR=$(echo "$DOCKER_VERSION" | cut -d. -f1)
if [ "$DOCKER_MAJOR" -lt 20 ] 2>/dev/null; then
    erro "Docker $DOCKER_VERSION detectado. Versao minima: 20.10+"
    exit 1
fi
ok "Docker $DOCKER_VERSION"

# --- 2. Verificar Docker Swarm ---
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    erro "Docker Swarm nao esta ativo."
    echo "       Execute: docker swarm init"
    exit 1
fi
ok "Docker Swarm ativo"

# --- 3. Configuracao ---
if [ -f .env ]; then
    info "Arquivo .env ja existe. Usando configuracao existente."
    set -a
    source .env
    set +a
else
    echo ""
    read -p "Dominio para o OpenClaw (ex: openclaw.meudominio.com.br): " OPENCLAW_DOMAIN
    if [ -z "$OPENCLAW_DOMAIN" ]; then
        erro "Dominio nao pode ser vazio."
        exit 1
    fi

    read -p "Nome do stack [openclaw]: " OPENCLAW_STACK_NAME
    OPENCLAW_STACK_NAME="${OPENCLAW_STACK_NAME:-openclaw}"

    # Listar redes overlay disponiveis para ajudar o usuario
    echo ""
    info "Redes overlay disponiveis:"
    docker network ls --filter driver=overlay --format '  - {{.Name}}' 2>/dev/null
    echo ""
    read -p "Nome da rede overlay do Traefik [traefik-public]: " OPENCLAW_TRAEFIK_NETWORK
    OPENCLAW_TRAEFIK_NETWORK="${OPENCLAW_TRAEFIK_NETWORK:-traefik-public}"

    # Gerar token
    if command -v uuidgen &> /dev/null; then
        OPENCLAW_GATEWAY_TOKEN=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
    else
        OPENCLAW_GATEWAY_TOKEN=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
    fi

    OPENCLAW_BASE_PATH="$SCRIPT_DIR"

    cat > .env << EOF
# OpenClaw Stack - Gerado por setup.sh em $(date '+%Y-%m-%d %H:%M:%S')
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_DOMAIN=$OPENCLAW_DOMAIN
OPENCLAW_STACK_NAME=$OPENCLAW_STACK_NAME
OPENCLAW_TRAEFIK_NETWORK=$OPENCLAW_TRAEFIK_NETWORK
OPENCLAW_BASE_PATH=$OPENCLAW_BASE_PATH
EOF

    ok "Arquivo .env criado"
    set -a
    source .env
    set +a
fi

# --- 4. Verificar rede do Traefik ---
if ! docker network ls --format '{{.Name}}' | grep -q "^${OPENCLAW_TRAEFIK_NETWORK}$"; then
    warn "Rede '${OPENCLAW_TRAEFIK_NETWORK}' nao encontrada."
    echo ""
    echo "  Essa rede normalmente e criada pelo Traefik."
    echo "  Se voce tem certeza que o Traefik esta configurado, verifique o nome da rede."
    echo ""
    read -p "Deseja criar a rede '${OPENCLAW_TRAEFIK_NETWORK}'? [s/N]: " CREATE_NET
    if [ "$CREATE_NET" = "s" ] || [ "$CREATE_NET" = "S" ]; then
        docker network create --driver overlay --attachable "$OPENCLAW_TRAEFIK_NETWORK"
        ok "Rede '${OPENCLAW_TRAEFIK_NETWORK}' criada"
    else
        warn "Continuando sem criar a rede. O deploy pode falhar."
    fi
else
    ok "Rede '${OPENCLAW_TRAEFIK_NETWORK}' encontrada"
fi

# --- 5. Build da imagem ---
echo ""
info "Construindo imagem Docker (isso pode levar alguns minutos)..."
docker build -t "${OPENCLAW_STACK_NAME}:latest" .
ok "Imagem construida: ${OPENCLAW_STACK_NAME}:latest"

# --- 6. Criar diretorios de persistencia ---
mkdir -p .openclaw/workspace/openclaw_training_data
mkdir -p backups

# --- 7. Gerar openclaw.json ---
if [ ! -f .openclaw/openclaw.json ]; then
    cat > .openclaw/openclaw.json << 'JSONEOF'
{
  "gateway": {
    "trustedProxies": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
}
JSONEOF
    ok "openclaw.json criado com trustedProxies"
else
    info "openclaw.json ja existe"
fi

# --- 8. Copiar templates ---
if [ -d templates/openclaw_training_data ] && [ -z "$(ls -A .openclaw/workspace/openclaw_training_data/ 2>/dev/null)" ]; then
    cp templates/openclaw_training_data/* .openclaw/workspace/openclaw_training_data/
    ok "Templates de treinamento copiados para .openclaw/workspace/openclaw_training_data/"
    info "Edite os arquivos com as informacoes do seu negocio."
    info "Consulte examples/soraia-boutique/ para um exemplo completo."
fi

# --- 9. Deploy ---
echo ""
info "Fazendo deploy do stack '${OPENCLAW_STACK_NAME}'..."

export OPENCLAW_GATEWAY_TOKEN OPENCLAW_DOMAIN OPENCLAW_STACK_NAME OPENCLAW_TRAEFIK_NETWORK OPENCLAW_BASE_PATH
docker stack deploy -c docker-compose.yml "$OPENCLAW_STACK_NAME"

ok "Stack deployed"

# --- 10. Aguardar ---
echo ""
info "Aguardando servico iniciar (30s)..."
sleep 30

if docker service ls --filter "name=${OPENCLAW_STACK_NAME}_openclaw" --format '{{.Replicas}}' | grep -q "1/1"; then
    ok "Servico rodando!"
else
    warn "Servico pode ainda estar iniciando. Verifique com:"
    echo "  docker service ps ${OPENCLAW_STACK_NAME}_openclaw"
fi

# --- 11. Instrucoes ---
echo ""
echo "========================================"
echo -e "  ${GREEN}Setup Completo!${NC}"
echo "========================================"
echo ""
echo -e "  Acesse: ${CYAN}https://${OPENCLAW_DOMAIN}${NC}"
echo ""
echo "  Primeiro acesso (parear navegador):"
echo "    ./claw dashboard"
echo ""
echo "  Comandos uteis:"
echo "    ./claw channels login       # Conectar WhatsApp/Telegram"
echo "    ./claw channels status      # Status das conexoes"
echo "    ./claw config list          # Ver configuracoes"
echo ""
echo "  Logs:"
echo "    docker service logs ${OPENCLAW_STACK_NAME}_openclaw --tail 50 -f"
echo ""
echo "  Documentacao:"
echo "    docs/pairing.md             # Pareamento de dispositivos"
echo "    docs/backups.md             # Sistema de backup"
echo "    docs/troubleshooting.md     # Resolucao de problemas"
echo ""
