# OpenClaw Stack

Deploy do OpenClaw em Docker Swarm com Traefik e backup automatico.

## Pre-requisitos

| Componente | Versao Minima | Observacao |
|---|---|---|
| Docker Engine | 20.10+ | `docker version` para verificar |
| Docker Swarm | - | Deve estar inicializado (`docker swarm init`) |
| Traefik | v2.5+ (recomendado v3.x) | Rodando como servico no Swarm |
| Portainer CE | 2.11+ | Opcional, para gerenciamento visual |
| Git | qualquer | Para clonar o repositorio |
| RAM | 2GB+ | Build consome memoria; limite do servico e 4GB |
| Disco | 10GB+ | Imagem + node_modules + backups |

Seu servidor deve ter:
- Docker Swarm inicializado
- Traefik rodando com rede overlay (normalmente `traefik-public`)
- Dominio com DNS apontando para o IP do servidor (registro A)

## Instalacao

```bash
# 1. Clone o repositorio
git clone https://github.com/SEU-USUARIO/openclaw-stack.git
cd openclaw-stack

# 2. De permissao aos scripts
chmod +x setup.sh update.sh claw backup-daemon.sh

# 3. Execute o setup
./setup.sh
```

O setup vai perguntar:
- **Dominio** (ex: `openclaw.meudominio.com.br`)
- **Nome do stack** (padrao: `openclaw`)
- **Rede do Traefik** (padrao: `traefik-public` - o setup lista as redes disponiveis)

Depois ele gera o token, builda a imagem, configura o gateway e faz o deploy.

## Primeiro Acesso

Apos o setup, acesse `https://SEU-DOMINIO` no navegador.

Para obter o link direto com token de autenticacao:

```bash
./claw dashboard
```

Para mais detalhes sobre pareamento de dispositivos, veja [docs/pairing.md](docs/pairing.md).

## Comandos Uteis

```bash
# CLI do OpenClaw (wrapper para docker exec)
./claw <comando>

# Exemplos:
./claw config list          # Ver configuracoes
./claw channels login       # Conectar WhatsApp/Telegram
./claw channels status      # Status das conexoes
./claw pairing list         # Dispositivos pareados
./claw dashboard            # URL do dashboard com token
```

### Gerenciamento do Stack

```bash
# Status do servico
docker service ps NOME-DO-STACK_openclaw

# Logs em tempo real
docker service logs NOME-DO-STACK_openclaw -f --tail 50

# Parar tudo
docker stack rm NOME-DO-STACK

# Redeploy (apos alterar .env ou docker-compose.yml)
set -a && source .env && set +a
docker stack deploy -c docker-compose.yml $OPENCLAW_STACK_NAME
```

## Atualizacao

```bash
./update.sh
```

Reconstroi a imagem com o codigo mais recente do OpenClaw e faz redeploy automatico.

## Treinamento (Training Data)

Os arquivos de treinamento definem a personalidade e conhecimento do agente. Ficam em `.openclaw/workspace/openclaw_training_data/`:

| Arquivo | Descricao |
|---------|-----------|
| `system_prompt.md` | Prompt principal (persona, regras, formato de resposta) |
| `knowledge.md` | Base de conhecimento (produtos, horarios, FAQ) |
| `qualification_rules.md` | Regras de qualificacao de leads |
| `follow_up_prompt.md` | Template para mensagens de follow-up |

- Templates limpos estao em `templates/`
- Um exemplo completo (Soraia Boutique) esta em `examples/soraia-boutique/`

## Backup

Backup automatico diario com retencao de 7 dias. Os backups ficam em `./backups/`.

Veja [docs/backups.md](docs/backups.md) para detalhes sobre restauracao e configuracao.

## Estrutura do Projeto

```
openclaw-stack/
├── .env                    # Suas variaveis (gerado pelo setup)
├── .openclaw/              # Dados persistentes (gerado pelo setup)
│   ├── openclaw.json       # Config do gateway
│   ├── devices/            # Dispositivos pareados
│   └── workspace/          # Workspace do agente + training data
├── backups/                # Backups automaticos
├── Dockerfile              # Build do OpenClaw
├── docker-compose.yml      # Definicao do stack Swarm
├── setup.sh                # Instalacao inicial
├── update.sh               # Atualizacao
├── claw                    # CLI wrapper
├── backup-daemon.sh        # Script do sidecar de backup
├── templates/              # Templates limpos para treinamento
├── examples/               # Exemplo completo (Soraia Boutique)
└── docs/                   # Documentacao adicional
```

## Variaveis de Ambiente

| Variavel | Descricao | Padrao |
|----------|-----------|--------|
| `OPENCLAW_GATEWAY_TOKEN` | Token de autenticacao | Gerado pelo setup |
| `OPENCLAW_DOMAIN` | Dominio para Traefik | (obrigatorio) |
| `OPENCLAW_STACK_NAME` | Nome do stack Swarm | `openclaw` |
| `OPENCLAW_TRAEFIK_NETWORK` | Rede overlay do Traefik | `traefik-public` |
| `OPENCLAW_BASE_PATH` | Caminho absoluto da instalacao | Gerado pelo setup |

## Troubleshooting

Veja [docs/troubleshooting.md](docs/troubleshooting.md).
