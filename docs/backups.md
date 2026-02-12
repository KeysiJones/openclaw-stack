# Sistema de Backup

## Arquitetura

O backup roda como um **servico sidecar** no Docker Swarm, usando um container Alpine Linux que executa o script `backup-daemon.sh` em loop.

### Componentes

| Componente | Caminho |
|------------|---------|
| Script | `backup-daemon.sh` (raiz do projeto) |
| Configuracao Docker | `docker-compose.yml` (servico `backup`) |
| Diretorio de saida | `./backups/` |
| Dados de origem | `./.openclaw/` (montado como `/data` read-only) |

## Configuracao

| Parametro | Valor |
|-----------|-------|
| Intervalo entre backups | 24 horas (`INTERVAL_SECONDS=86400`) |
| Retencao | 7 dias (`RETENTION_DAYS=7`) |
| Delay inicial | 60 segundos |
| Formato do arquivo | `openclaw-backup-YYYY-MM-DD_HHMMSS.tar.gz` |
| Imagem Docker | `alpine:latest` |
| Limite de memoria | 128M |

## Como Funciona

1. O container inicia e aguarda 60 segundos
2. Compacta todo o conteudo de `.openclaw/` em um `.tar.gz`
3. Remove backups com mais de 7 dias
4. Dorme por 24 horas e repete

## Verificando o Status

```bash
# Status do servico de backup
docker service ps NOME-DO-STACK_backup

# Logs do daemon
docker service logs NOME-DO-STACK_backup --tail 20

# Listar backups existentes
ls -lah backups/
```

## Restaurando um Backup

```bash
# 1. Parar o servico OpenClaw
docker service scale NOME-DO-STACK_openclaw=0

# 2. Extrair o backup (substituindo os dados atuais)
tar xzf backups/openclaw-backup-YYYY-MM-DD_HHMMSS.tar.gz -C .openclaw/

# 3. Reiniciar o servico
docker service scale NOME-DO-STACK_openclaw=1
```

## Alterando o Intervalo

Edite `INTERVAL_SECONDS` em `backup-daemon.sh`:

| Frequencia | Valor |
|------------|-------|
| A cada 6 horas | `21600` |
| Diario (padrao) | `86400` |
| Semanal | `604800` |

Apos alterar, faca o redeploy:

```bash
set -a && source .env && set +a
docker stack deploy -c docker-compose.yml $OPENCLAW_STACK_NAME
```
