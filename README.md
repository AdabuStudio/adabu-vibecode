# Adabù VibeCode Protocol

Memoria operativa condivisa per progetti sviluppati con più AI coding agent
(Claude Code, Codex, Kimi, GLM, OpenCode e successivi).

Il principio: la memoria del progetto vive nel repository, non nella cronologia
di una singola chat. Un agente può continuare il lavoro lasciato da un altro
leggendo dei file, non ricostruendo una conversazione.

## Installazione

Procedura unica, identica per ogni progetto — con git, senza git, con o senza remote:

```bash
cd <progetto>
curl -sL https://github.com/AdabuStudio/adabu-vibecode/archive/main.tar.gz | tar xz -C /tmp
/tmp/adabu-vibecode-main/install.sh .
```

Non serve autenticazione: il repo è pubblico e la riga funziona da qualsiasi
macchina, incluso un agente senza credenziali git. Prende sempre l'ultima versione.

Lo script, oltre a installare il protocollo:

- inizializza `git` se manca;
- estende `.gitignore` con le esclusioni minime (`.env`, `wp-config.php`, `*.sql`, chiavi);
- **scansiona i file già tracciati** e avvisa se contengono segreti, con i comandi per rimuoverli;
- riporta se esiste un remote e come crearlo.

Alla fine stampa i **prossimi passi del tuo caso specifico** — con i comandi già
pronti da copiare. Non devi ricordarti quale procedura seguire: la riconosce lui.

Casi gestiti automaticamente:

| Situazione rilevata | Cosa fa |
|---|---|
| cartella senza git | `git init`, e propone la pubblicazione come passo opzionale |
| repo locale senza remote | mostra il comando `gh repo create` |
| repo già su GitHub | chiude con `git push` |
| segreti tracciati | li elenca come **passo 1**, prima di tutto il resto |
| memoria sparsa (`TODO.md`, `CLAUDE.md` con regole proprie, `.cursorrules`…) | la elenca nel prompt di bootstrap da incollare, con l'istruzione di migrarla |

## Aggiornamento

Stesso comando. Lo script:

- **sovrascrive** `README.md`, `RULES.md`, `MODEL_ROUTING.md`, `BOOTSTRAP_PROMPT.md`, `tiers.sh` — sono il protocollo, versionato qui
- **non tocca** `PROJECT.yaml`, `STATE.md`, `TASKS.md`, `DECISIONS.md`, `HANDOFF.md` — sono il progetto
- **estende** `AGENTS.md` / `CLAUDE.md` preesistenti anteponendo il blocco di puntamento, senza perdere il contenuto

È idempotente: rieseguirlo non fa danni.

## Primo avvio in un progetto

Apri un agente nel repo e dagli `00_PROTOCOL/BOOTSTRAP_PROMPT.md`.
Ricostruisce lo stato reale dal codice e da Git, compila i file, e si ferma.

## Struttura

| File | Ruolo |
|---|---|
| `PROJECT.yaml` | identità, runtime, agenti, routing esterno, mappatura tier → modello |
| `RULES.md` | regole universali — non modificare per progetto |
| `MODEL_ROUTING.md` | quale tier di modello per quale lavoro, escalation e de-escalation |
| `tiers.sh` | mappatura tier → modello locale per harness (`~/.config/adabu-vibecode/tiers.yaml`), fuori dal repo |
| `STATE.md` | fotografia dello stato adesso |
| `TASKS.md` | NOW / NEXT / BLOCKED / BACKLOG |
| `DECISIONS.md` | decisioni tecniche consolidate |
| `HANDOFF.md` | passaggio di consegne corrente — effimero |

Alla root: `AGENTS.md` e `CLAUDE.md` puntano qui dentro. Servono perché ogni
agente al boot legge un file diverso.

## Nei workspace Coder

Aggiungi `coder-startup.sh` allo `startup_script` del template. Installa il
protocollo se manca, avvisa se è vecchio, **non aggiorna da solo** — un update
automatico lascerebbe il working tree sporco a inizio sessione.

Per aggiornare, dentro il workspace:

```bash
avc-update .
```

## Versione

Protocollo v7 — *Model Routing & Escalation*.
Vedi `00_PROTOCOL/.protocol-version` nei repo installati.
