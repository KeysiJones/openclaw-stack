#!/bin/sh
# ============================================
# OpenClaw Stack - Backup Daemon (Sidecar)
# Executa backup diario dos dados persistentes
# Retem os ultimos 7 dias de backups
# ============================================

BACKUP_DIR="/backups"
SOURCE_DIR="/data"
RETENTION_DAYS=7
INTERVAL_SECONDS=86400  # 24h

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

do_backup() {
    TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
    BACKUP_FILE="${BACKUP_DIR}/openclaw-backup-${TIMESTAMP}.tar.gz"

    log "Iniciando backup..."

    if [ ! -d "$SOURCE_DIR" ] || [ -z "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
        log "Diretorio de dados vazio ou inexistente. Pulando backup."
        return 0
    fi

    tar czf "$BACKUP_FILE" -C "$SOURCE_DIR" .
    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log "Backup criado: ${BACKUP_FILE} (${SIZE})"
    else
        log "ERRO: Falha ao criar backup."
        rm -f "$BACKUP_FILE"
        return 1
    fi

    # Limpar backups antigos (reter ultimos RETENTION_DAYS dias)
    REMOVED=0
    find "$BACKUP_DIR" -name "openclaw-backup-*.tar.gz" -mtime +${RETENTION_DAYS} -type f | while read OLD; do
        rm -f "$OLD"
        REMOVED=$((REMOVED + 1))
        log "Removido backup antigo: $(basename "$OLD")"
    done

    TOTAL=$(ls -1 "$BACKUP_DIR"/openclaw-backup-*.tar.gz 2>/dev/null | wc -l)
    log "Backups retidos: ${TOTAL} (max ${RETENTION_DAYS} dias)"
}

# --- Main Loop ---
log "Backup daemon iniciado (intervalo: ${INTERVAL_SECONDS}s, retencao: ${RETENTION_DAYS} dias)"
mkdir -p "$BACKUP_DIR"

# Primeiro backup apos 60s (dar tempo ao openclaw iniciar)
log "Aguardando 60s antes do primeiro backup..."
sleep 60
do_backup

while true; do
    log "Proximo backup em ${INTERVAL_SECONDS}s..."
    sleep "$INTERVAL_SECONDS"
    do_backup
done
