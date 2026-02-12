# Regras de Qualificacao de Lead

## Status Possiveis

| Status | Descricao |
| :--- | :--- |
| **`new`** | Novo contato, ainda nao interagiu. |
| **`qualifying`** | Em conversa, avaliando interesse. |
| **`qualified`** | Interesse real demonstrado. |
| **`discarded`** | Spam, engano ou sem interesse. |

## Criterios de Decisao

1. **Qualificacao Imediata (`qualified`):**
   - (Defina seus criterios aqui)
   - Exemplo: Qualquer interesse genuino no produto/servico

2. **Desqualificacao (`discarded`):**
   - Mensagens de spam
   - Numero errado
   - Xingamentos

3. **Em Andamento (`qualifying`):**
   - Todas as outras conversas normais

## Regra de Protecao

**Sticky Qualified:** Uma vez `qualified`, NUNCA rebaixar automaticamente.

## Formato de Saida (JSON)

```json
{
  "response": "Texto da resposta...",
  "status": "qualified",
  "thought": "Justificativa do status."
}
```

---

Consulte examples/soraia-boutique/ para ver um exemplo completo.
