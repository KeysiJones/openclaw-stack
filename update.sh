#!/bin/bash
# ============================================
# OpenClaw Stack - Atualizacao
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
erro() { echo -e "${RED}[ERRO]${NC} $1"; }

if [ ! -f .env ]; then
    erro "Arquivo .env nao encontrado. Rode ./setup.sh primeiro."
    exit 1
fi

set -a
source .env
set +a

STACK="${OPENCLAW_STACK_NAME:-openclaw}"

echo ""
echo "========================================"
echo "  OpenClaw Stack - Atualizacao"
echo "========================================"
echo ""

# 1. Build nova imagem
info "Baixando atualizacoes e reconstruindo imagem..."
if ! docker build --no-cache -t "${STACK}:latest" .; then
    echo ""
    warn "Falha no build. Tentando recuperacao..."
    docker system prune -f || true
    if ! docker build --no-cache -t "${STACK}:latest" .; then
        erro "Build falhou novamente. Verifique os logs acima."
        exit 1
    fi
fi
ok "Nova imagem construida: ${STACK}:latest"

# 2. Redeploy
info "Atualizando stack..."
export OPENCLAW_GATEWAY_TOKEN OPENCLAW_DOMAIN OPENCLAW_STACK_NAME OPENCLAW_TRAEFIK_NETWORK OPENCLAW_BASE_PATH
docker stack deploy -c docker-compose.yml "$STACK"

echo ""
info "Aguardando atualizacao (30s)..."
sleep 30

if docker service ls --filter "name=${STACK}_openclaw" --format '{{.Replicas}}' | grep -q "1/1"; then
    ok "Atualizado com sucesso!"
else
    warn "Servico pode estar reiniciando. Verifique:"
    echo "  docker service ps ${STACK}_openclaw --no-trunc"
fi

echo ""
echo -e "Acesse: ${CYAN}https://${OPENCLAW_DOMAIN}${NC}"
echo ""
