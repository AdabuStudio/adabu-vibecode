#!/usr/bin/env bash
# Da incollare nello startup_script del template Coder, dopo il clone del repo.
#
# Comportamento voluto:
#   - protocollo assente  → lo installa
#   - protocollo presente e aggiornato → non fa nulla
#   - protocollo presente ma vecchio → AVVISA, non aggiorna
#
# L'update non è automatico di proposito: modificherebbe file a workspace avviato
# e l'agente troverebbe un working tree sporco che non ha prodotto lui.
# Per aggiornare davvero:  ~/.local/bin/avc-update <cartella>

PROTOCOL_REPO="https://oauth2:${GITHUB_TOKEN}@github.com/AdabuStudio/adabu-vibecode"
WORK="/home/coder/${REPO_NAME:-workspace}"

[ -d "$WORK/.git" ] || exit 0

rm -rf /tmp/avc
git clone -q --depth 1 "$PROTOCOL_REPO" /tmp/avc 2>/dev/null || exit 0

LATEST=$(cat /tmp/avc/00_PROTOCOL/.protocol-version 2>/dev/null || echo 0)
CURRENT=$(cat "$WORK/00_PROTOCOL/.protocol-version" 2>/dev/null || echo 0)

if [ "$CURRENT" = "0" ]; then
  echo "→ VibeCode Protocol assente: installo v$LATEST"
  bash /tmp/avc/install.sh "$WORK"
elif [ "$CURRENT" != "$LATEST" ]; then
  echo "⚠  VibeCode Protocol v$CURRENT — disponibile v$LATEST"
  echo "   aggiorna con: avc-update $WORK   (non a metà task)"
fi

# comando di update sempre disponibile nel workspace
mkdir -p ~/.local/bin
cat > ~/.local/bin/avc-update <<'INNER'
#!/usr/bin/env bash
rm -rf /tmp/avc
git clone -q --depth 1 "https://oauth2:${GITHUB_TOKEN}@github.com/AdabuStudio/adabu-vibecode" /tmp/avc
bash /tmp/avc/install.sh "${1:-$PWD}"
INNER
chmod +x ~/.local/bin/avc-update
