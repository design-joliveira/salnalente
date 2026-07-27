#!/bin/bash

# Gera $PAGINA/fotos.json a partir das imagens em $PAGINA/fotos/
# Uso: ./gerar-fotos-pagina.command
#      ./gerar-fotos-pagina.command sessoes

cd "$(dirname "$0")"

PAGES="home sessoes galeria sobre"

if [ -n "$1" ]; then
  PAGE="$1"
else
  echo "Qual página? (home / sessoes / galeria / sobre)"
  read PAGE
fi

PAGE=$(echo "$PAGE" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

case " $PAGES " in
  *" $PAGE "*) ;;
  *)
    echo "❌ Página inválida: '$PAGE'. Use: $PAGES"
    exit 1
    ;;
esac

FOTOS_DIR="$PAGE/fotos"
JSON_FILE="$PAGE/fotos.json"

if [ ! -d "$FOTOS_DIR" ]; then
  echo "❌ Pasta '$FOTOS_DIR' não encontrada."
  exit 1
fi

python3 - "$FOTOS_DIR" "$JSON_FILE" <<'PY'
import json
import sys
from pathlib import Path

fotos_dir = Path(sys.argv[1])
json_file = Path(sys.argv[2])

exts = {".jpg", ".jpeg", ".png", ".webp"}
files = sorted(
    p.name for p in fotos_dir.iterdir()
    if p.is_file() and p.suffix.lower() in exts
)

if not files:
    print(f"❌ Nenhuma foto em '{fotos_dir}'.")
    sys.exit(1)

json_file.write_text(
    json.dumps(files, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
print(f"✅ {json_file} gerado com {len(files)} foto(s).")
print(json_file.read_text(encoding="utf-8"))
PY
