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

Prima di tutto verifica su quale macchina sei (`hostname`): le regole della macchina,
se esistono, sono già nelle istruzioni globali del tuo strumento e valgono insieme
a quelle del protocollo.

Il bootstrap è **l'unica sessione in cui leggi tutto il protocollo**: dopo, vale
la lettura a due livelli descritta in `RULES.md`.

Leggi nell'ordine:

1. `00_PROTOCOL/README.md`
2. `00_PROTOCOL/PROJECT.yaml`
3. `00_PROTOCOL/RULES.md`
4. `00_PROTOCOL/MODEL_ROUTING.md`
5. `00_PROTOCOL/STATE.md`
6. `00_PROTOCOL/TASKS.md`
7. `00_PROTOCOL/DECISIONS.md`
8. `00_PROTOCOL/HANDOFF.md`

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

Non toccare `ai_routing`: i default valgono per tutti i progetti. Compila
`ai_routing.overrides` solo se emerge un vincolo reale di questo progetto
(budget chiuso, un solo fornitore ammesso) e segnalalo a Federico.
I modelli disponibili su questa macchina non si scrivono qui: lancia
`00_PROTOCOL/tiers.sh get <tuo harness>` e, se risolve un tier come "non
configurato", dillo nell'output finale (punto 7) — Federico lo sistema con
"imposta i tier".

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

## Memoria esterna in lettura

Se hai il tool MENTE (`mente-ai`), prima di ricostruire cerca il progetto nella
memoria: decisioni e contesto salvati da sessioni precedenti. È una fonte in più,
non una verità: se contraddice codice o git, vince il repo e la discrepanza va in
`HANDOFF.md`. Se non hai il tool, salta questo passo senza segnalarlo.

## Routing esterno

NON sincronizzare ClickUp o Mente-AI durante questo bootstrap.

Se in `PROJECT.yaml` una destinazione ha `bound: false`, alla fine dell'analisi
chiedi a Federico — una domanda per destinazione, tutte insieme, non una alla volta:

1. **ClickUp** — incolla l'URL, oppure "no". Un **task** se è un progetto cliente
   (sta nell'area del cliente), una **lista** se è un lab o un prodotto con vita
   propria (lista dedicata in 05-LAB). Non agganciare liste generiche condivise
   tra più progetti, tipo "Task Generici": chiedi un task dedicato.
2. **Memoria AI** — non è una domanda di scelta. Vedi la regola in `RULES.md`:
   se hai il tool MENTE, l'aggancio a `mente-ai` è automatico e chiedi solo conferma
   del nome `project`; se non ce l'hai, salta senza chiedere niente.
   `mind-exsafe` non si propone mai.
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
