#!/usr/bin/env bash
# Adabù VibeCode Protocol — mappatura tier → modello LOCALE, per harness.
#
# PROJECT.yaml → ai_routing.tiers dice quali modelli usa il team, per fornitore.
# Ma i modelli davvero disponibili dipendono dall'harness e dall'account di
# questa macchina (Codex CLI, Codex in IDE, Claude Code, OpenCode, Kimi…).
# Questo script tiene quella mappatura fuori dal repo, in un file per macchina:
#
#   ${XDG_CONFIG_HOME:-~/.config}/adabu-vibecode/tiers.yaml
#
# Ordine di risoluzione (lo applica `get`, e lo segue l'agente):
#   1. file locale, sezione del tuo harness
#   2. PROJECT.yaml → ai_routing.tiers.<tier>.<fornitore dell'harness>
#   3. niente: l'agente lo dice, non inventa un nome
#
# Uso:
#   tiers.sh set  <harness> economic=<modello> base=<modello> premium=<modello>
#   tiers.sh get  <harness> [tier]       # mappatura risolta, con la fonte
#   tiers.sh show                        # contenuto del file locale
#   tiers.sh unset <harness>             # torna ai default di PROJECT.yaml
#
# Harness noti e fornitore in PROJECT.yaml:
#   codex → openai     claude-code → claude     altri → stesso nome
#
# Compatibile con bash 3.2 (macOS). Nessuna dipendenza oltre awk.

set -euo pipefail

TIERS="economic base premium"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/adabu-vibecode"
CONF="${ADABU_TIERS_FILE:-$CONF_DIR/tiers.yaml}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${ADABU_PROJECT_YAML:-$HERE/PROJECT.yaml}"

die() { echo "tiers.sh: $*" >&2; exit 1; }

usage() { sed -n '16,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

check_harness() {
  echo "$1" | grep -qE '^[a-z0-9][a-z0-9-]*$' \
    || die "nome harness non valido: '$1' (minuscole, cifre, trattini)"
}

check_tier() {
  case " $TIERS " in *" $1 "*) ;; *) die "tier sconosciuto: '$1' (economic | base | premium)";; esac
}

provider_of() {
  case "$1" in
    codex|codex-*)             echo openai ;;
    claude-code|claude|claude-*) echo claude ;;
    *)                         echo "$1" ;;
  esac
}

# valore locale: harness tier → modello (vuoto se assente)
local_get() {
  [ -f "$CONF" ] || return 0
  awk -v h="$1" -v t="$2" '
    /^[^ #][^:]*:/ { cur=$0; sub(/:.*/, "", cur); next }
    cur==h && $0 ~ "^  "t":" {
      v=$0; sub(/^[^:]*:[ ]*/, "", v); sub(/[ ]*#.*/, "", v); print v; exit
    }' "$CONF"
}

# valore di progetto: tier fornitore → modello, da ai_routing.tiers
project_get() {
  [ -f "$PROJECT" ] || return 0
  awk -v t="$1" -v p="$2" '
    /^ai_routing:/            { in_r=1; next }
    in_r && /^[^ #]/          { in_r=0 }
    in_r && /^  tiers:/       { in_t=1; next }
    in_t && /^  [^ #]/        { in_t=0 }
    in_t && /^    [a-z]+:/    { cur=$1; sub(/:.*/, "", cur); next }
    in_t && cur==t && $0 ~ "^      "p":" {
      v=$0; sub(/^[^:]*:[ ]*/, "", v); sub(/[ ]*#.*/, "", v); print v; exit
    }' "$PROJECT"
}

cmd_set() {
  [ $# -ge 2 ] || usage 1
  local h="$1"; shift
  check_harness "$h"
  local pairs="" kv t m
  for kv in "$@"; do
    case "$kv" in *=*) ;; *) die "atteso tier=modello, trovato '$kv'";; esac
    t="${kv%%=*}"; m="${kv#*=}"
    check_tier "$t"
    echo "$m" | grep -qE '^[A-Za-z0-9._:/@-]+$' || die "nome modello non valido: '$m'"
    pairs="$pairs$t=$m;"
  done

  mkdir -p "$(dirname "$CONF")"
  [ -f "$CONF" ] || printf '%s\n' \
    "# Mappatura tier → modello di QUESTA macchina, per harness." \
    "# Gestita da 00_PROTOCOL/tiers.sh. Vince su PROJECT.yaml → ai_routing.tiers." \
    "# Non va in nessun repo: descrive l'account e gli strumenti di chi lavora qui." \
    > "$CONF"

  # riscrive la sezione dell'harness: chiavi esistenti aggiornate, nuove aggiunte
  awk -v h="$h" -v pairs="$pairs" -v order="$TIERS" '
    BEGIN {
      n=split(pairs, a, ";")
      for (i=1; i<=n; i++) if (a[i]!="") { k=a[i]; sub(/=.*/, "", k); v=a[i]; sub(/^[^=]*=/, "", v); want[k]=v }
      split(order, ord, " ")
    }
    function flush(   i, k) {
      for (i=1; i<=3; i++) { k=ord[i]; if ((k in want) && !(k in done)) print "  " k ": " want[k] }
    }
    /^[^ #][^:]*:/ {
      if (cur==h) flush()
      cur=$0; sub(/:.*/, "", cur); if (cur==h) found=1
      print; next
    }
    cur==h && /^  [a-z]+:/ {
      k=$0; sub(/^  /, "", k); sub(/:.*/, "", k)
      if (k in want) { print "  " k ": " want[k]; done[k]=1; next }
    }
    { print }
    END {
      if (cur==h) flush()
      if (!found) { print h ":"; flush() }
    }' "$CONF" > "$CONF.tmp"
  mv "$CONF.tmp" "$CONF"
  echo "salvato in $CONF"
  cmd_get "$h"
}

cmd_get() {
  [ $# -ge 1 ] || usage 1
  local h="$1" only="${2:-}" p t v src
  check_harness "$h"
  [ -z "$only" ] || check_tier "$only"
  p="$(provider_of "$h")"
  for t in $TIERS; do
    [ -z "$only" ] || [ "$only" = "$t" ] || continue
    v="$(local_get "$h" "$t")"; src="locale"
    if [ -z "$v" ]; then v="$(project_get "$t" "$p")"; src="PROJECT.yaml ($p)"; fi
    if [ -z "$v" ]; then v="—"; src="non configurato"; fi
    if [ -n "$only" ]; then echo "$v"; else printf '%-9s %-24s %s\n' "$t" "$v" "$src"; fi
  done
}

cmd_show() {
  if [ -f "$CONF" ]; then cat "$CONF"; else echo "nessuna mappatura locale ($CONF non esiste)"; fi
}

cmd_unset() {
  [ $# -eq 1 ] || usage 1
  check_harness "$1"
  [ -f "$CONF" ] || { echo "niente da rimuovere"; return 0; }
  awk -v h="$1" '
    /^[^ #][^:]*:/ { cur=$0; sub(/:.*/, "", cur) }
    cur!=h { print }' "$CONF" > "$CONF.tmp"
  mv "$CONF.tmp" "$CONF"
  echo "rimosso '$1': torna ai default di PROJECT.yaml"
}

case "${1:-}" in
  set)   shift; cmd_set "$@" ;;
  get)   shift; cmd_get "$@" ;;
  show)  cmd_show ;;
  unset) shift; cmd_unset "$@" ;;
  -h|--help|help|"") usage 0 ;;
  *) usage 1 ;;
esac
