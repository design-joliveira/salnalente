#!/bin/bash

# Gera downloads.json a partir das previews em <cliente>-download/fotos/
# Mantém links do Drive já preenchidos se o arquivo já existir.

cd "$(dirname "$0")"

echo "Qual o nome do cliente? (ex: fernando)"
read CLIENT

if [ -z "$CLIENT" ]; then
  echo "❌ Nome do cliente não informado."
  exit 1
fi

DOWNLOAD_DIR="${CLIENT}-download"
FOTOS_DIR="$DOWNLOAD_DIR/fotos"
JSON_FILE="$DOWNLOAD_DIR/downloads.json"

if [ ! -d "$FOTOS_DIR" ]; then
  echo "❌ Pasta '$FOTOS_DIR' não encontrada."
  echo "   Crie a pasta e copie as previews (baixa resolução) para lá."
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
    print(f"❌ Nenhuma foto encontrada em '{fotos_dir}'.")
    sys.exit(1)

existing = {}
if json_file.exists():
    try:
        data = json.loads(json_file.read_text(encoding="utf-8"))
        if isinstance(data, list):
            for item in data:
                if isinstance(item, dict) and item.get("preview"):
                    existing[item["preview"]] = (item.get("drive") or "").strip()
    except Exception:
        pass

items = [
    {"preview": name, "drive": existing.get(name, "")}
    for name in files
]

json_file.write_text(
    json.dumps(items, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)

filled = sum(1 for i in items if i["drive"])
print(f"✅ {json_file} gerado com {len(items)} foto(s).")
if filled:
    print(f"   {filled} link(s) do Drive preservado(s); preencha os que estão vazios.")
else:
    print("   Cole o link /view de cada foto no campo \"drive\".")
print()
print(json_file.read_text(encoding="utf-8"))
PY
