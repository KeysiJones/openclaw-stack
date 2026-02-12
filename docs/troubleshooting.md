# Troubleshooting

## Servico nao inicia

```bash
# Verificar status detalhado
docker service ps NOME-DO-STACK_openclaw --no-trunc

# Ver logs
docker service logs NOME-DO-STACK_openclaw --tail 100
```

## "Gateway auth is set to token, but no token is configured"

**Causa:** A variavel `OPENCLAW_GATEWAY_TOKEN` nao esta chegando ao container.
O `docker stack deploy` nao le o arquivo `.env` automaticamente.

**Solucao:** Sempre use `./setup.sh` ou `./update.sh`, que exportam as variaveis
antes de chamar `docker stack deploy`. Se fizer deploy manual:

```bash
set -a && source .env && set +a
docker stack deploy -c docker-compose.yml $OPENCLAW_STACK_NAME
```

## "Pool overlaps with other one on this address space"

**Causa:** Conflito de rede overlay no Docker Swarm.

**Solucao:**
1. Verifique redes existentes: `docker network ls`
2. Remova redes nao utilizadas: `docker network prune`
3. Se o problema persistir, verifique se o servico esta na rede correta
   no `docker-compose.yml`

## Traefik nao roteia para o OpenClaw

1. Verifique se o dominio resolve para o IP do servidor:
   ```bash
   dig +short SEU-DOMINIO
   ```

2. Verifique se a rede do Traefik esta correta:
   ```bash
   grep TRAEFIK_NETWORK .env
   docker network ls | grep traefik
   ```

3. Verifique os labels do servico:
   ```bash
   docker service inspect NOME-DO-STACK_openclaw --pretty
   ```

4. Confira se o Traefik esta na mesma rede:
   ```bash
   docker service inspect traefik_traefik --format '{{json .Spec.TaskTemplate.Networks}}'
   ```

## "502 Bad Gateway" no Traefik

**Causa:** O OpenClaw ainda nao iniciou ou `trustedProxies` nao esta configurado.

**Solucao:** Verifique `.openclaw/openclaw.json`:
```json
{
  "gateway": {
    "trustedProxies": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
}
```

Se o arquivo nao existir, rode `./setup.sh` novamente (ele e idempotente).

## "Disconnected from gateway" / "pairing required"

**Causa:** O navegador nao esta pareado com o gateway.

**Solucao:**
```bash
# Link direto com token
./claw dashboard

# Ou pareamento manual
./claw pairing list
./claw pairing approve <CODIGO>
```

Veja [pairing.md](pairing.md) para mais detalhes.

## Build demora muito ou falha

O build clona o OpenClaw do GitHub e instala dependencias Node.js.
Pode levar 5-10 minutos na primeira vez.

Se falhar:
```bash
# Limpar cache do Docker e tentar novamente
docker system prune -f
docker build --no-cache -t NOME-DO-STACK:latest .
```

Se falhar por falta de memoria (OOM), aumente o swap:
```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

## Variaveis nao substituidas no compose

Se o deploy mostra `${OPENCLAW_DOMAIN}` literalmente nas labels do Traefik,
as variaveis nao foram exportadas.

**Solucao:** Nunca use `docker stack deploy` diretamente. Use `./setup.sh`
ou `./update.sh`, ou exporte manualmente:

```bash
set -a && source .env && set +a
docker stack deploy -c docker-compose.yml $OPENCLAW_STACK_NAME
```
