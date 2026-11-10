# Adabù VibeCode Protocol

Questa cartella contiene il protocollo operativo condiviso per progetti sviluppati con più AI coding agent.

Agenti supportati:
- Codex
- Claude Code
- Kimi
- GLM
- OpenCode
- altri agenti CLI compatibili

## Obiettivo

Rendere il repository la fonte di verità operativa condivisa, così che un agente possa continuare il lavoro lasciato da un altro senza dipendere dalla cronologia di una singola chat.

## Ordine di lettura

Sempre, prima di lavorare:

1. `PROJECT.yaml`
2. `RULES.md`
3. `STATE.md`
4. `TASKS.md`
5. `HANDOFF.md`

Su necessità: `MODEL_ROUTING.md` (escalation o delega), `DECISIONS.md` (area già
decisa), `BOOTSTRAP_PROMPT.md` (primo ingresso). `RULES.md` dice quando.

Poi deve controllare:

```bash
git status
git branch --show-current
git log --oneline -10
```

## Principio

- Git = verità tecnica e storico delle modifiche
- STATE.md = stato attuale
- TASKS.md = cosa resta da fare
- DECISIONS.md = decisioni tecniche consolidate
- HANDOFF.md = passaggio di consegne corrente
- PROJECT.yaml = identità, routing esterno, mappatura tier → modello
- RULES.md = regole universali
- MODEL_ROUTING.md = quale tier di modello per quale tipo di lavoro

La memoria non deve vivere in una singola chat AI.
