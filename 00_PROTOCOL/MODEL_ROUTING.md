# Model Routing & Escalation

Usa sempre il modello **meno capace che svolge correttamente il task**.
I modelli premium non sono il default: sono uno strumento di escalation.

Questo file parla solo di **tier**. I nomi dei modelli stanno in un posto solo,
`PROJECT.yaml` → `ai_routing.tiers`. I modelli ruotano ogni pochi mesi: quando
cambiano si aggiornano tre righe lì, e il protocollo resta valido.

| Tier | Ruolo |
|---|---|
| `economic` | lavoro semplice, ripetitivo, a rischio nullo |
| `base` | il default. La maggior parte del lavoro quotidiano |
| `premium` | ragionare, decidere, sbloccare, verificare |

### Tier locali per harness

`PROJECT.yaml` dice quali modelli usa il team, per fornitore. Ma quali modelli
ci sono davvero dipende dall'harness e dall'account della macchina: Codex CLI,
Codex nell'IDE, Claude Code, OpenCode, Kimi non vedono lo stesso elenco.

Per questo ogni macchina può avere la sua mappatura, fuori da qualsiasi repo:

```bash
00_PROTOCOL/tiers.sh get codex                 # mappatura risolta, con la fonte
00_PROTOCOL/tiers.sh set codex economic=<m> base=<m> premium=<m>
00_PROTOCOL/tiers.sh unset codex               # torna ai default di PROJECT.yaml
```

Il file è `~/.config/adabu-vibecode/tiers.yaml` e vale per tutti i progetti
della macchina. Il nome dell'harness è libero (`codex`, `claude-code`,
`opencode`, `kimi`…): `codex` legge i default `openai`, `claude-code` i default
`claude`, gli altri la chiave con il proprio nome.

Ordine di risoluzione, sempre questo:

1. file locale, sezione del tuo harness;
2. `PROJECT.yaml` → `ai_routing.tiers.<tier>.<fornitore>`;
3. niente: lo dici, **non inventi un nome di modello**.

Quando Federico dice **"imposta i tier"**, l'agente:

1. lancia `tiers.sh get <harness>` e mostra cosa risolve oggi;
2. chiede a Federico i modelli per i tier che vanno cambiati — se l'harness
   espone l'elenco dei modelli disponibili, lo propone come scelta, altrimenti
   chiede e basta;
3. salva con `tiers.sh set` e mostra il risultato.

Non si compila da soli dai nomi visti in documentazione o in altri progetti:
un modello annunciato non è un modello disponibile. `tiers.sh` non tocca mai
`PROJECT.yaml` e non va committato niente.

---

## I quattro livelli

### SIMPLE → `economic`

Modifiche CSS e piccoli ritocchi UI; rinomina di file o variabili; documentazione;
correzioni minime; test semplici; modifica di contenuti; ricerca di riferimenti;
operazioni ripetitive; CRUD banale; componenti semplici.

Se il tier `economic` non è configurato o non è disponibile, scendi a `base`.
**Mai `premium`.**

### STANDARD → `base`

Feature normali; API semplici; CRUD completo; componenti frontend; integrazione
backend/frontend; test; refactor locali; bug con causa identificabile; query
normali; implementazione da specifiche chiare.

È il grosso del lavoro: indicativamente **60-80%** delle sessioni.

### COMPLEX → `premium` per capire, `base` per fare

Bug con causa sconosciuta; refactor su più moduli; architettura; integrazioni
esterne complesse; performance; concorrenza; problemi di stato; modifiche
cross-system; requisiti ambigui; legacy difficile; task con molte soluzioni
possibili.

Il tier `premium` serve per **analisi, pianificazione, root cause, architettura**.
Quando il problema è compreso e il piano è stabile, l'esecuzione torna a `base`.

### CRITICAL → `premium` per il piano, revisione indipendente se il rischio la merita

Authentication; authorization; sicurezza; permessi; pagamenti; dati sensibili;
migrazioni distruttive; rischio di perdita dati; infrastruttura di produzione;
deploy irreversibili; alto blast radius; business logic critica.

`premium` per pianificare, verificare l'architettura e identificare i rischi.
L'esecuzione può scendere a `base` **se il piano è deterministico**.

Per le operazioni più rischiose si può aggiungere una revisione finale con un
modello premium **di un fornitore diverso** da quello che ha pianificato:

```
premium A → piano      premium B → piano
base      → esecuzione base      → esecuzione
premium B → revisione  premium A → revisione
```

La doppia revisione **non** è automatica. Si usa quando il rischio la giustifica.

---

## Escalation

Sali di tier quando è vera almeno una di queste:

1. due tentativi di implementazione falliti sullo stesso problema;
2. root cause ancora sconosciuta;
3. bassa confidenza sulla soluzione;
4. requisiti contraddittori;
5. il task tocca più sottosistemi core;
6. blast radius elevato;
7. rischio per l'integrità dei dati;
8. rischio di sicurezza;
9. rischio in produzione;
10. serve una decisione architetturale importante.

**Dopo due tentativi falliti ci si ferma.** Non si insiste con lo stesso modello:

```
STOP → documenta il problema → proponi l'escalation
```

L'escalation deve avere una ragione concreta e scritta. "Più costoso" non
significa "più adatto".

## De-escalation

Quando un tier premium ha identificato la root cause, prodotto un piano, scelto
l'architettura o sciolto l'ambiguità, la domanda è sempre:

> Il resto del lavoro richiede ancora questo tier?

Se no, **si scende**. Il modello potente serve a pensare, decidere, sbloccare e
verificare — non necessariamente a scrivere tutto il codice.

---

## Come avviene davvero il cambio

Un agente **non può cambiare il proprio modello a metà sessione**. Ma non gli
serve: può **delegarne un pezzo**. Ci sono due meccanismi, e si scelgono in base
a quanto lavoro resta.

### 1. Delega a sessione separata — il caso normale

L'agente apre una sotto-sessione su un tier diverso, le dà un mandato delimitato,
e riprende con il risultato. Claude Code, Codex e Hermes lo fanno tutti e tre.

**Verso l'alto**, quando serve capire e non eseguire:

```
sessione base → sotto-sessione premium: "trova la causa di X, non implementare"
             ← ritorna diagnosi e piano
sessione base → esegue
```

Costa molto meno che portare tutta la sessione su premium, perché il tier alto
vede solo il problema, non l'intera cronologia.

**Verso il basso**, per lavoro delimitato e ripetitivo: rinominare su quaranta
file, generare test boilerplate, uniformare import. Più sotto-sessioni
`economic` in parallelo, il parent raccoglie.

Regole della delega:

- Il mandato è **chiuso**: obiettivo, file o area, criterio di fine. Una
  sotto-sessione senza criterio di fine non si apre.
- La sotto-sessione **non eredita la conversazione**: tutto ciò che le serve sta
  nel mandato.
- **Non rilegge il protocollo.** Nessun bootstrap, nessun giro sui sei file: il
  parent le passa le poche righe che le servono. Cinque sotto-sessioni che
  leggono tutto sono cinque volte il costo d'ingresso, per niente.
- Scrive codice, **non scrive nei file del protocollo**. STATE, TASKS, DECISIONS
  e HANDOFF li tocca solo il parent, che è l'unico ad avere il quadro.
- **Non annida**: una sotto-sessione non ne apre altre, salvo mandato esplicito.

### 2. Cambio della sessione principale — quando il grosso del lavoro resta

Se il tier sbagliato riguarda tutto il lavoro rimanente, delegare non serve: va
cambiata la sessione. Lì l'agente non può farlo da sé, quindi:

1. **classifica** e dichiara il tier;
2. **si ferma** quando ricorre una condizione di escalation;
3. **scrive** in `HANDOFF.md` quale tier serve e perché.

Il cambio lo esegue chi lancia la sessione: Federico, o l'orchestratore.

Distinzione che conta:

- **Stesso fornitore, tier diverso**: stato leggero. Basta la riga di routing in
  `HANDOFF.md`, il resto del contesto è nel repo.
- **Fornitore diverso**: è a tutti gli effetti un **cambio agente**, e si applica
  la procedura *Interruzione* di `RULES.md` — commit wip, file toccati con il
  loro stato, ultimo comando con l'esito reale, cosa non è stato verificato.

---

## Dichiarazione di classificazione

Prima di un task significativo, l'agente dichiara:

```
Task complexity:   SIMPLE | STANDARD | COMPLEX | CRITICAL
Recommended tier:  ECONOMIC | BASE | PREMIUM
Current tier:      <quello su cui sto girando>
Escalation:        YES | NO
Reason:            <una frase>
```

Per i task `SIMPLE` e `STANDARD` **non si interrompe Federico**: si procede sul
tier corretto. L'escalation si propone solo quando è materialmente utile, e si
spiega in una frase comprensibile:

> Passo al tier premium: il problema tocca autenticazione, schema DB e gestione
> sessioni.

> Resto sul tier base: il task è locale, reversibile e ben definito.

Se l'agente sta già girando su un tier più alto del necessario, lo dice e propone
di scendere. Vale in entrambe le direzioni.

---

## Vincoli di progetto

`PROJECT.yaml` → `ai_routing.overrides` può vietare tier o fissare un fornitore
per un progetto specifico. Un vincolo dichiarato **vince sulla classificazione**:
se `premium` è vietato e il task lo richiederebbe, l'agente si ferma e lo scrive
in `HANDOFF.md` invece di aggirarlo.
