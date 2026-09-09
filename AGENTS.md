<!-- adabu-vibecode:entrypoint -->
# Agent Entrypoint

Questo repository usa il **Adabù VibeCode Protocol**.

Prima di modificare qualsiasi cosa, leggi in ordine:

1. `00_PROTOCOL/PROJECT.yaml`
2. `00_PROTOCOL/RULES.md`
3. `00_PROTOCOL/STATE.md`
4. `00_PROTOCOL/TASKS.md`
5. `00_PROTOCOL/DECISIONS.md`
6. `00_PROTOCOL/HANDOFF.md`

Poi:

```bash
git status && git branch --show-current && git log --oneline -10
```

`RULES.md` prevale sui default del tuo agente.

Prima di chiudere la sessione — o se vieni interrotto — esegui la procedura di handoff descritta in `RULES.md`.