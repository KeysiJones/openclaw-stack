# Exemplo: Soraia Boutique

Exemplo completo de configuracao de treinamento para uma boutique de moda feminina.

## Arquivos

| Arquivo | Descricao |
|---------|-----------|
| `system_prompt.md` | Prompt principal com persona "Schirley", consultora de estilo |
| `knowledge.md` | Base de conhecimento (endereco, horarios, produtos, promocoes) |
| `qualification_rules.md` | Regras de qualificacao de leads |
| `follow_up_prompt.md` | Template para mensagens de follow-up no WhatsApp |

## Como Usar

1. Copie os arquivos para `.openclaw/workspace/openclaw_training_data/`:
   ```bash
   cp examples/soraia-boutique/openclaw_training_data/* .openclaw/workspace/openclaw_training_data/
   ```
2. Edite com as informacoes do seu negocio
3. Reinicie o servico:
   ```bash
   ./update.sh
   ```

Ou use como referencia para criar seus proprios arquivos a partir dos templates em `templates/`.
