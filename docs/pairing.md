# Pareamento de Dispositivos

O OpenClaw requer pareamento para acesso ao dashboard pelo navegador.

## Primeiro Acesso (Recomendado)

A forma mais simples de acessar o dashboard pela primeira vez:

```bash
./claw dashboard
```

Isso mostra a URL com o token de autenticacao. Abra no navegador.

## Pareamento Manual

Se preferir parear manualmente:

```bash
# 1. Acesse https://SEU-DOMINIO no navegador
#    O navegador vai solicitar pareamento

# 2. No servidor, veja os pedidos pendentes
./claw pairing list

# 3. Aprove o dispositivo
./claw pairing approve <CODIGO>
```

## Verificar Dispositivos Pareados

```bash
./claw pairing list
```

## Como Funciona

Quando voce acessa o dashboard pelo navegador, o OpenClaw identifica o
dispositivo e verifica se esta pareado. Dispositivos nao pareados recebem
erro `1008 - pairing required` e ficam em estado "pending" ate serem
aprovados via CLI.

Os dados de pareamento ficam em `.openclaw/devices/`:
- `pending.json` - Dispositivos aguardando aprovacao
- `paired.json` - Dispositivos aprovados

## Problemas Comuns

### "Disconnected from gateway (1006)"

Causas possiveis:
1. Servico nao esta rodando: `docker service ps NOME-DO-STACK_openclaw`
2. Token invalido: verifique `.env`
3. trustedProxies nao configurado: verifique `.openclaw/openclaw.json`

### Pareamento nao funciona apos reinstalacao

Limpe o cache/cookies do navegador para o dominio e tente novamente.
O navegador pode estar usando uma chave de sessao antiga.
