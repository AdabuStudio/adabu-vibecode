# Adabù VibeCode Protocol — Rules

## Prima di lavorare

Ogni agente deve:

1. leggere `PROJECT.yaml`;
2. leggere `RULES.md`;
3. leggere `STATE.md`;
4. leggere `TASKS.md`;
5. leggere `DECISIONS.md`;
6. leggere `HANDOFF.md`;
7. controllare Git prima di modificare codice.

Comandi minimi:

```bash
git status
git branch --show-current
git log --oneline -10
```

Se `HANDOFF.md` contiene una sezione **Interruzione** non chiusa, quello è il punto di ripartenza: non ricominciare il task da capo.

## Fonte di verità

Dipende da `project.runtime` in `PROJECT.yaml`:

- `repo` → il codice e Git sono la verità tecnica.
- `infra` → lo stato reale della macchina è la verità; il repo contiene config e runbook. Prima di dichiarare qualcosa, **verificalo sulla macchina**.
- `local` → non c'è Git: `STATE.md` e `HANDOFF.md` sono l'unica memoria. Vanno aggiornati con più disciplina, non meno.

I file di questa cartella sono la memoria operativa condivisa.

Se documentazione e realtà divergono:
1. verificare la realtà (codice / macchina);
2. verificare Git dove esiste;
3. aggiornare la documentazione.

`STATE.md` riporta in testa `Last verified commit`. Se diverge da `HEAD`, il primo compito è capire quanto:

```bash
git log --oneline <sha>..HEAD
```

## Durante il lavoro

- Non rifare lavoro già completato.
- Non modificare parti non necessarie al task.
- Preservare le modifiche di altri agenti.
- Non cambiare architettura senza una ragione concreta.
- Non introdurre dipendenze inutilmente.
- Non eliminare codice senza verificarne l'uso.
- Non modificare credenziali o secret.
- Non inserire secret nel repository. I secret stanno in `.env` locale, mai committato; `.env.example` va tenuto aggiornato ad ogni nuova variabile.
- Non fare force push.
- Non fare reset distruttivi.
- Non scartare modifiche utente.
- Preferire modifiche piccole, verificabili e reversibili.
- Prima di lavorare su un file modificato da altri, controllare `git diff`.

## Decisioni

Le decisioni architetturali significative vanno in `DECISIONS.md`.

Non riaprire decisioni già prese salvo: nuova evidenza, bug, cambiamento dei requisiti, richiesta esplicita.

## Stato

Quando cambia materialmente il progetto, aggiornare `STATE.md` e il suo `Last verified commit`.

`STATE.md` descrive il progetto adesso. Non è un diario.

## Task

Aggiornare `TASKS.md` quando: un task viene completato, emerge un nuovo task, cambia la priorità, viene scoperto un blocker.

I task in `NOW` devono essere **bounded**: con un criterio di completamento verificabile senza intervento umano (test che passa, build senza warning, endpoint che risponde). Un task senza criterio di completamento non va in `NOW`.

## Handoff — fine sessione ordinata

Prima di terminare una sessione significativa:

1. verificare il lavoro;
2. eseguire test/build pertinenti;
3. aggiornare `STATE.md`;
4. aggiornare `TASKS.md`;
5. aggiornare `DECISIONS.md` se necessario;
6. riscrivere `HANDOFF.md`.

`HANDOFF.md` rappresenta solo il passaggio di consegne corrente.

## Cambio agente a metà task

Vale quando la sessione si interrompe senza chiudere il task: limite di token o quota, crash, timeout, cambio deliberato di agente.

**L'agente uscente:**

1. Non lasciare il working tree sporco e non tracciato:

```bash
git add -A
git commit -m "wip: <task> — interrotto, vedi HANDOFF"
```

Se il lavoro è instabile, prima isolalo: `git switch -c wip/<task-slug>`

2. Scrivere in `HANDOFF.md` la sezione **Interruzione**:
   - motivo dell'interruzione;
   - file toccati, ciascuno con stato: completo / a metà / non iniziato;
   - ultimo comando eseguito e suo esito reale;
   - comando successivo previsto;
   - cosa **non** è stato verificato (test non girati, build non fatta, deploy non provato).

3. Aggiungere il proprio nome in `agents.worked_so_far` in `PROJECT.yaml`.

**Se l'interruzione è improvvisa** e l'agente non riesce a scrivere nulla, il primo compito di chi entra è ricostruire da:

```bash
git status && git diff && git log --oneline -5
```

e solo dopo continuare.

**L'agente entrante** non riparte da zero e non rifà il lavoro: legge `HANDOFF.md`, verifica con `git diff` che corrisponda alla realtà, e continua dal punto indicato. Se `HANDOFF.md` e `git diff` divergono, vince `git diff` e va segnalato.

## Scelta dell'agente

Il protocollo è model-neutral: nessuna regola qui dipende da un agente specifico.

La scelta di quale agente usare sta in `PROJECT.yaml` sotto `agents`:

- `primary` → l'agente preferito per questo progetto, per coerenza di stile e architettura.
- `constraints` → vincoli reali del progetto (tool necessari, dimensione di contesto, edit multi-file). Un agente che non li soddisfa non va usato qui, a prescindere dalla preferenza.

Un agente che non rispetta un vincolo dichiarato deve fermarsi e segnalarlo in `HANDOFF.md`, non aggirarlo.

## Sincronizzazioni esterne

Il sync è **in uscita**: repo → ClickUp / Mente-AI. Nulla viene mai riscritto nel
repo da una destinazione esterna. Se un task nasce su ClickUp, viene letto al
bootstrap e riportato in `TASKS.md`: da quel momento `TASKS.md` è autoritativo
per il lavoro tecnico.

### Aggancio della destinazione

Ogni destinazione in `PROJECT.yaml` ha `bound: true|false`.

Con `bound: false` l'agente **non sincronizza e non indovina**. Chiede a Federico:

> Destinazione ClickUp per questo progetto? Incolla l'URL (task o lista).
> Cadenza: `always` (ogni fine sessione) / `on_command` (solo se te lo chiedo) / `on_milestone` (solo su cambiamenti sostanziali)?

Ricevuto l'URL: deduce dal percorso se è un task (`/t/<id>` → `task_id`) o una
lista (`/li/<id>` → `list_id`), compila **uno solo** dei due, più `url` e `cadence`,
e mette `bound: true`. Se l'URL non è né l'uno né l'altro, lo chiede di nuovo invece
di indovinare.

Il comportamento cambia di conseguenza:

- `task_id` → il sync aggiorna la descrizione del task e aggiunge un commento.
- `list_id` → il sync lavora sui task dentro la lista; non crea task nuovi senza
  approvazione esplicita.

Non agganciare mai una lista generica condivisa tra più progetti: i task si
mescolano e il sync scrive nel posto di qualcun altro. In quel caso si chiede un
task dedicato.
`url` resta salvato in chiaro perché Federico possa verificare a colpo d'occhio
che la destinazione sia quella giusta.

Se Federico non risponde o dice di lasciar perdere, resta `bound: false` e la cosa
finisce in `HANDOFF.md` → To verify. Non si chiede una seconda volta nella stessa
sessione.

L'aggancio si fa una volta sola. Non riproporre la domanda ad ogni bootstrap se
`bound: true`.

### Cadenza

| Valore | Quando sincronizzare |
|---|---|
| `always` | ad ogni handoff di fine sessione |
| `on_command` | solo quando Federico dice esplicitamente "sincronizza" |
| `on_milestone` | solo su cambiamento sostanziale (sotto) |
| `never` | mai |

Un **cambiamento sostanziale** è uno di questi, e nessun altro:

- una nuova voce in `DECISIONS.md`;
- un cambio di stack o di architettura;
- un deploy in produzione;
- un blocker che ferma il progetto;
- la chiusura di una fase in `TASKS.md`.

Aggiungere un file, correggere un bug o completare un singolo task **non** è un
cambiamento sostanziale. Nel dubbio, non sincronizzare: chiedi.

### Regole di esecuzione

Il sync non avviene durante il lavoro. Avviene come ultimo passo dell'handoff,
**dopo il commit**: se il sync fallisce, il lavoro è comunque salvo.

Dopo un sync riuscito, aggiornare `last_synced` con la data.

`HANDOFF.md` non si sincronizza mai: è effimero e cambia più volte al giorno.

Il cervello cliente `00_[CLIENTE]_AI` è in **sola lettura**. Brand voice, KPI e
contesto business restano lì e non vengono copiati nel repo; `PROJECT.yaml` ci
punta e basta.

Payload ClickUp: sintetico. Niente pipe fuori dalle tabelle, niente documenti
lunghi — la scrittura fallisce in silenzio. Oltre ~100 righe, spezzare o accorciare.
Dopo la scrittura, **rileggere** per confermare che sia andata a buon fine.

### Routing suggerito quando Federico non specifica

Istanza di memoria — dipende da chi lavora, non dal progetto:

- `mente-ai` è la memoria personale di Federico. **Se l'agente ha il tool MENTE, la
  usa sempre**: aggancio automatico al bootstrap, lettura del contesto all'inizio,
  scrittura secondo cadenza. Nessuna domanda, salvo confermare il nome `project`.
- **Se l'agente non ha il tool** (sessione di un membro del team): salta mente-ai in
  silenzio. Non chiedere, non segnalare come mancanza, non mettere `bound: false`
  se era `true` — il repo è condiviso e l'aggancio resta valido per chi ha il tool.
- `mind-exsafe` **solo su richiesta esplicita**. Mai proporla, mai dedurla dal tipo
  di progetto o dal cliente.
- Mai entrambe sullo stesso progetto.
- Lo scope interno lo assegna MENTE dal `project`: l'agente non sceglie chapter.

- `lab` → ClickUp lista dedicata in 05-LAB, se Federico la vuole.
- `client` → ClickUp task nell'area del cliente.
- `internal` → ClickUp area interna.
- `infra` → ClickUp solo se il lavoro è tracciato come task.
- `personal` → chiedere.
- `unknown` → non proporre nulla.

Questo è un suggerimento da proporre, non una destinazione da usare senza conferma.
