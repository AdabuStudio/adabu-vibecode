#!/usr/bin/env bash
# Adabù VibeCode Protocol — installer / updater
#
#   curl -fsSL https://raw.githubusercontent.com/AdabuStudio/adabu-vibecode/main/install.sh | bash
#   ./install.sh /path/to/repo
#
# Idempotente. Aggiorna le regole del protocollo, non tocca mai i contenuti del progetto.

set -euo pipefail

PROTOCOL_VERSION=7
DIR="00_PROTOCOL"
TARGET="${1:-$PWD}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# File di protocollo: sovrascritti ad ogni update.
PROTOCOL_FILES=(README.md RULES.md MODEL_ROUTING.md BOOTSTRAP_PROMPT.md tiers.sh)
# File di progetto: creati se mancanti, MAI sovrascritti.
PROJECT_FILES=(PROJECT.yaml STATE.md TASKS.md DECISIONS.md HANDOFF.md)

cd "$TARGET"
mkdir -p "$DIR"

# ── Git: inizializza se assente ──────────────────────────────────────
if [ ! -d .git ]; then
  git init -q
  echo "  creato      .git  (repository locale inizializzato)"
fi

# ── .gitignore: garantisce le esclusioni minime ──────────────────────
IGNORE=(".env" ".env.local" "wp-config.php" "*.sql" "*.sql.gz" "*.pem" "*.key"
        "id_rsa" "node_modules/" ".DS_Store" "wp-content/uploads/" "vendor/")
touch .gitignore
ADDED=0
for pat in "${IGNORE[@]}"; do
  grep -qxF "$pat" .gitignore || { echo "$pat" >> .gitignore; ADDED=$((ADDED+1)); }
done
[ "$ADDED" -gt 0 ] && echo "  esteso      .gitignore  (+$ADDED regole)"

# ── Scansione segreti tra i file GIÀ TRACCIATI ───────────────────────
LEAKS=$(git ls-files 2>/dev/null | grep -Ei '(^|/)(wp-config\.php|\.env(\.|$)|.*\.sql$|.*\.pem$|.*\.key$|id_rsa)' || true)
CONTENT=$(git grep -lEi '(AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH) PRIVATE KEY|DB_PASSWORD[[:space:]]*[,=])' -- . 2>/dev/null || true)
LEAKS=$(printf '%s\n%s\n' "$LEAKS" "$CONTENT" | sed '/^$/d' | sort -u)

# ── Memoria operativa sparsa, da migrare nel protocollo ──────────────
STRAY=""
for f in NOTES.md TODO.md CONTEXT.md PROJECT-SUMMARY.md ARCHITECTURE.md .cursorrules .windsurfrules; do
  [ -f "$f" ] && STRAY="$STRAY$f\n"
done
STRAY=$(printf '%b' "$STRAY" | sed '/^$/d')


INSTALLED=0
[ -f "$DIR/.protocol-version" ] && INSTALLED=$(cat "$DIR/.protocol-version")

echo "→ target:  $TARGET"
echo "→ versione: ${INSTALLED:-nessuna} → $PROTOCOL_VERSION"
echo

for f in "${PROTOCOL_FILES[@]}"; do
  cp "$SRC/$DIR/$f" "$DIR/$f"
  echo "  aggiornato  $DIR/$f"
done
chmod +x "$DIR/tiers.sh"

for f in "${PROJECT_FILES[@]}"; do
  if [ -f "$DIR/$f" ]; then
    echo "  invariato   $DIR/$f  (contenuto di progetto)"
  else
    cp "$SRC/$DIR/$f" "$DIR/$f"
    echo "  creato      $DIR/$f"
  fi
done

# ── protocol.version: è metadato di protocollo, non contenuto di progetto ──
if grep -qE '^  version: [0-9]+' "$DIR/PROJECT.yaml"; then
  CUR=$(sed -nE 's/^  version: ([0-9]+).*/\1/p' "$DIR/PROJECT.yaml" | head -1)
  if [ "$CUR" != "$PROTOCOL_VERSION" ]; then
    # awk e non `sed 0,/re/`: quell'indirizzo è solo GNU, sul sed BSD di macOS
    # non fa nulla. Cambia solo la prima occorrenza (protocol.version).
    awk -v v="$PROTOCOL_VERSION" '!done && /^  version: [0-9]+/ { sub(/[0-9]+/, v); done=1 } { print }' \
      "$DIR/PROJECT.yaml" > "$DIR/PROJECT.yaml.tmp"
    mv "$DIR/PROJECT.yaml.tmp" "$DIR/PROJECT.yaml"
    echo "  allineato   $DIR/PROJECT.yaml  (protocol.version $CUR → $PROTOCOL_VERSION)"
  fi
fi

# ── ai_routing: aggiunto ai PROJECT.yaml che non ce l'hanno (upgrade da v6) ──
# Unica eccezione alla regola "i file di progetto non si toccano": aggiunge un
# blocco di configurazione mancante, non modifica nulla di già scritto.
if ! grep -q '^ai_routing:' "$DIR/PROJECT.yaml"; then
  { echo
    awk '/^# >>> adabu-vibecode:ai_routing >>>/,/^# <<< adabu-vibecode:ai_routing <<</' \
      "$SRC/$DIR/PROJECT.yaml"
  } >> "$DIR/PROJECT.yaml"
  echo "  esteso      $DIR/PROJECT.yaml  (aggiunto blocco ai_routing, contenuto preservato)"
fi

# ── Entrypoint alla root ─────────────────────────────────────────────
# Se il file esiste già con contenuto proprio, il blocco va in testa e il
# resto resta intatto. Il marker evita di inserirlo due volte.

MARKER="<!-- adabu-vibecode:entrypoint -->"

install_entrypoint() {
  local file="$1"
  if [ -f "$file" ] && grep -qF "$MARKER" "$file"; then
    echo "  invariato   $file  (blocco già presente)"
    return
  fi
  if [ -f "$file" ]; then
    { cat "$SRC/AGENTS.md"; echo; echo "---"; echo; cat "$file"; } > "$file.tmp"
    mv "$file.tmp" "$file"
    echo "  esteso      $file  (contenuto esistente preservato)"
    STRAY=$(printf '%s\n%s' "$STRAY" "$file (contenuto sotto il separatore)" | sed '/^$/d')
  else
    cp "$SRC/AGENTS.md" "$file"
    echo "  creato      $file"
  fi
}

install_entrypoint AGENTS.md
install_entrypoint CLAUDE.md

echo "$PROTOCOL_VERSION" > "$DIR/.protocol-version"

# ── .env.example ─────────────────────────────────────────────────────
[ -f .env.example ] || { touch .env.example; echo "  creato      .env.example"; }


# ── Stato remoto ─────────────────────────────────────────────────────
REMOTE=$(git remote get-url origin 2>/dev/null || true)
echo
if [ -n "$REMOTE" ]; then
  echo "Remote: $REMOTE"
else
  echo "Remote: nessuno — il progetto vive solo in locale."
  echo "        Per pubblicarlo:  gh repo create <org>/<nome> --private --source=. --push"
fi

if [ -n "$LEAKS" ]; then
  echo
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  ATTENZIONE — file sensibili TRACCIATI da git                   ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo "$LEAKS" | sed 's/^/  • /'
  echo
  echo "  NON pubblicare questo repo finché non li rimuovi:"
  echo "$LEAKS" | sed 's/^/      git rm --cached "/;s/$/"/'
  echo "      git commit -m \"chore: rimuove file sensibili dal tracking\""
  echo
  echo "  I file restano sul disco: git smette solo di seguirli."
  echo "  Se il repo è GIÀ pubblicato, i segreti sono nella storia:"
  echo "  vanno considerati compromessi e ruotati (password DB, chiavi API)."
fi

echo
echo "────────────────────────────────────────────────────────────────"
if [ "$INSTALLED" = "0" ]; then
  echo " PROTOCOLLO INSTALLATO (v$PROTOCOL_VERSION) — prossimi passi"
else
  echo " PROTOCOLLO AGGIORNATO (v$INSTALLED → v$PROTOCOL_VERSION)"
  echo " I contenuti di progetto non sono stati toccati."
fi
echo "────────────────────────────────────────────────────────────────"
STEP=1
n() { echo; echo " $STEP. $1"; STEP=$((STEP+1)); }

if [ -n "$LEAKS" ]; then
  n "RIMUOVI I SEGRETI DAL TRACKING — prima di ogni altra cosa"
  echo "$LEAKS" | sed 's/^/      git rm --cached "/;s/$/"/'
  echo "      git commit -m \"chore: rimuove file sensibili dal tracking\""
fi

n "AVVIA IL BOOTSTRAP"
echo "      Apri il tuo agente in questa cartella e incollagli:"
echo
echo "        Leggi 00_PROTOCOL/BOOTSTRAP_PROMPT.md ed esegui il bootstrap."
if [ -n "$STRAY" ]; then
  echo "        Nel repo c'è memoria pre-esistente da migrare:"
  echo "$STRAY" | sed 's/^/          - /'
  echo "        Applica la sezione \"Migrazione di memoria pre-esistente\":"
  echo "        smista i contenuti nei file del protocollo, riduci CLAUDE.md"
  echo "        al solo blocco entrypoint, e dimmi cosa hai spostato."
fi
echo "        Non scrivere codice: ricostruisci lo stato, fammi le domande,"
echo "        e fermati."

n "RISPONDI ALLE SUE DOMANDE (tipo progetto, ClickUp, Mente-AI, cadenza)"
echo "      e verifica che STATE.md descriva il progetto come lo conosci."

n "SALVA"
echo "      git add -A && git commit -m \"chore: VibeCode Protocol v$PROTOCOL_VERSION\""

if [ -z "$REMOTE" ]; then
  n "OPZIONALE — pubblica il repo"
  if [ -n "$LEAKS" ]; then
    echo "      NON farlo finché non hai eseguito il passo 1."
  fi
  echo "      gh repo create AdabuStudio/<nome> --private --source=. --push"
  echo "      (AdabuStudio per lavoro cliente/agenzia, FabitusWeb per progetti tuoi)"
else
  n "ALLINEA IL REMOTE"
  echo "      git push"
fi
echo
