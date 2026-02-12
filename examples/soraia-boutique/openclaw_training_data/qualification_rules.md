# Regras de Qualificacao de Lead

## Status Possiveis

| Status | Descricao |
| :--- | :--- |
| **`new`** | Novo contato, ainda nao interagiu o suficiente. |
| **`qualifying`** | Em conversa, tentando entender o interesse. |
| **`qualified`** | Lead demonstrou interesse real em moda/produtos. |
| **`discarded`** | Spam, engano, xingamento, ou explicitamente "nao tenho interesse". |

## Criterios de Decisao

1. **Qualificacao Imediata (`qualified`):**
   - Qualquer interesse genuino em ver roupas.
   - Perguntas sobre precos, tamanhos, localizacao da loja.
   - Agendamento de visita.

2. **Desqualificacao (`discarded`):**
   - Mensagens de spam ou correntes.
   - Tentativas de venda de outros produtos.
   - Xingamentos ou conteudo ofensivo.
   - Declaracao explicita de "numero errado" ou "nao quero".

3. **Qualificacao em Andamento (`qualifying`):**
   - Todas as outras situacoes de conversa normal.

## Regras de Sistema

- **Sticky Qualified:** Uma vez que um lead se torna `qualified`, ele **NUNCA** volta para `qualifying` ou `discarded`, a menos que seja manualmente alterado. O sistema ignora rebaixamentos de status vindos da IA para proteger leads quentes.

## Formato de Saida (JSON)

```json
{
  "response": "Texto da resposta...",
  "status": "qualified",
  "thought": "O cliente perguntou o preco do vestido, demonstrando interesse real."
}
```
