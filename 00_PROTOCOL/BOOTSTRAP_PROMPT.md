# Bootstrap Prompt — Adabù VibeCode Protocol

Stai entrando in un progetto già esistente e già sviluppato in parte con Kimi.

L'obiettivo di questa sessione NON è iniziare subito nuove feature.

Devi prima integrare e inizializzare il **Adabù VibeCode Protocol** già presente nella cartella:

`00_PROTOCOL`

Questa cartella deve diventare la memoria operativa condivisa del progetto.

## Regola iniziale

NON modificare codice applicativo durante il bootstrap.

Prima devi:

1. analizzare il repository;
2. controllare Git;
3. ricostruire lo stato del progetto;
4. aggiornare i file del protocollo;
5. preparare il passaggio di consegne.

Non fare reset Git.
Non fare force checkout.
Non scartare modifiche non committate.
Non sovrascrivere informazioni utili.

## Leggi prima

Leggi nell'ordine:

1. `00_PROTOCOL/README.md`
2. `00_PROTOCOL/PROJECT.yaml`
3. `00_PROTOCOL/RULES.md`
4. `00_PROTOCOL/STATE.md`
5. `00_PROTOCOL/TASKS.md`
6. `00_PROTOCOL/DECISIONS.md`
7. `00_PROTOCOL/HANDOFF.md`

Poi esegui almeno:

```bash
git status
git branch --show-current
git log --oneline -20
git diff
git diff --cached
```


## Migrazione di memoria pre-esistente

Prima di tutto, cerca memoria operativa che vive fuori dal protocollo:

- contenuto in `CLAUDE.md` o `AGENTS.md` **sotto** la riga `---` che segue il blocco entrypoint
- vecchi file tipo `NOTES.md`, `TODO.md`, `PROJECT-SUMMARY.md`, `*-CONTEXT.md`
- board o JSON di stato esterni al repo, se te li segnala Federico

Se ne trovi, smistalo — non duplicarlo:

| Contenuto trovato | Destinazione |
|---|---|
| stack, architettura, come si builda/testa | `STATE.md` |
| scelte tecniche e loro motivazione | `DECISIONS.md` (`Status: inferred`) |
| cose da fare, TODO, FIXME | `TASKS.md` |
| divieti e zone delicate ("non toccare X") | `STATE.md` → Important files, e `HANDOFF.md` → Do not touch |
| brand voice, KPI, contesto business del cliente | **non importare**: resta nel cervello cliente, `PROJECT.yaml` ci punta |

Poi riduci `CLAUDE.md` e `AGENTS.md` al solo blocco entrypoint: elimina tutto
ciò che sta sotto il separatore, una volta che è stato spostato.

Elenca nell'output finale cosa hai migrato e da dove.

## Analisi

Analizza:

- README e documentazione
- struttura directory
- configurazioni
- dipendenze
- frontend
- backend
- API
- database/schema/migrations
- test
- script
- CI/CD
- Docker/devcontainer
- `.env.example`
- deployment
- TODO
- FIXME
- commenti significativi
- cronologia Git recente

Identifica:

- stack tecnologico
- architettura
- funzionalità implementate
- funzionalità parziali
- lavori recenti
- codice incompleto
- problemi noti
- servizi esterni
- modalità install/run/test/build/deploy
- punti delicati del progetto

Non inventare informazioni.

Usa `UNKNOWN` o `TO VERIFY` quando non puoi determinare qualcosa con sicurezza.

## Aggiorna il protocollo

Aggiorna:

- `PROJECT.yaml`
- `STATE.md`
- `TASKS.md`
- `DECISIONS.md`
- `HANDOFF.md`

Non cambiare `RULES.md` salvo errore evidente o richiesta esplicita.

### PROJECT.yaml

Configura ciò che puoi dedurre con sicurezza:

- project.name
- project.slug
- project.type
- repository.current_branch
- repository.main_branch

Tipi progetto ammessi:

- lab
- client
- internal
- personal
- unknown

Non inventare routing ClickUp o Mente-AI.

Se non conosci i valori, lascia `enabled: false` e `null`.

### STATE.md

Deve diventare una fotografia concisa dello stato attuale.

### TASKS.md

Ricostruisci:

- NOW
- NEXT
- BLOCKED
- BACKLOG
- RECENTLY DONE

Non inventare una roadmap enorme.

### DECISIONS.md

Aggiungi solo decisioni realmente deducibili o documentate.

Usa `Status: inferred` se dedotte.

### HANDOFF.md

Ricostruisci ciò che probabilmente stava facendo Kimi e indica il prossimo passo più sensato.

## Routing esterno

NON sincronizzare ClickUp o Mente-AI durante questo bootstrap.

Se in `PROJECT.yaml` una destinazione ha `bound: false`, alla fine dell'analisi
chiedi a Federico — una domanda per destinazione, tutte insieme, non una alla volta:

1. **ClickUp** — incolla l'URL del task, oppure "no".
2. **Mente-AI** — project e chapter (`work-clienti` | `operations` | `ai-workspace`), oppure "no".
3. **Cervello cliente** — URL del documento `00_[CLIENTE]_AI` se esiste, solo per lettura.
4. Per ciascuna destinazione agganciata: cadenza `always` / `on_command` / `on_milestone`.

Proponi il routing suggerito per il tipo di progetto (vedi `RULES.md`) come default,
ma non darlo per buono senza risposta.

Con le risposte, compila `sync` in `PROJECT.yaml` ed estrai gli id dagli URL.
Senza risposte, lascia `bound: false` e annota in `HANDOFF.md` → To verify.

## Output finale

Quando hai finito mostrami:

1. Project reconstruction
2. Most recent work
3. Current working tree
4. Protocol files updated
5. Proposed next task
6. External routing status
7. Risks / uncertainties

Poi FERMATI.

Non iniziare nuove implementazioni.
Non sincronizzare ClickUp.
Non sincronizzare Mente-AI.
