#!/bin/bash

# Gera downloads.json a partir das previews em <cliente>-download/fotos/
# Mantém links do Drive já preenchidos se o arquivo já existir.
# Registra a entrega em entregas/entregas.json (novo envio ou atualização).

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
LOG_FILE="entregas/entregas.json"

if [ ! -d "$FOTOS_DIR" ]; then
  echo "❌ Pasta '$FOTOS_DIR' não encontrada."
  echo "   Crie a pasta e copie as previews (baixa resolução) para lá."
  exit 1
fi

mkdir -p entregas

# Conta fotos antes de perguntar (para mostrar no prompt)
COUNT=$(ls "$FOTOS_DIR" 2>/dev/null | grep -iE '\.(jpg|jpeg|png|webp)$' | wc -l | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
  echo "❌ Nenhuma foto encontrada em '$FOTOS_DIR'."
  exit 1
fi

echo ""
echo "Encontrei $COUNT foto(s) em $FOTOS_DIR"
echo "Isso é um novo envio ou só atualização do envio anterior?"
echo "  1) Novo envio   (soma no histórico do mês)"
echo "  2) Atualização  (substitui a quantidade do último envio deste cliente)"
echo "  3) Não registrar no histórico"
read -p "Escolha [1/2/3]: " MODO

case "$MODO" in
  1|2|3) ;;
  *)
    echo "❌ Opção inválida."
    exit 1
    ;;
esac

python3 - "$FOTOS_DIR" "$JSON_FILE" "$LOG_FILE" "$CLIENT" "$MODO" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

fotos_dir = Path(sys.argv[1])
json_file = Path(sys.argv[2])
log_file = Path(sys.argv[3])
client = sys.argv[4].strip().lower()
modo = sys.argv[5].strip()

exts = {".jpg", ".jpeg", ".png", ".webp"}
files = sorted(
    p.name for p in fotos_dir.iterdir()
    if p.is_file() and p.suffix.lower() in exts
)

if not files:
    print(f"❌ Nenhuma foto encontrada em '{fotos_dir}'.")
    sys.exit(1)

count = len(files)

# ── downloads.json ──────────────────────────────────────────
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
print(f"✅ {json_file} gerado com {count} foto(s).")
if filled:
    print(f"   {filled} link(s) do Drive preservado(s); preencha os que estão vazios.")
else:
    print("   Cole o link /view de cada foto no campo \"drive\".")

# ── entregas.json ───────────────────────────────────────────
if modo == "3":
    print("   Histórico: não registrado.")
    print()
    print(json_file.read_text(encoding="utf-8"))
    sys.exit(0)

log_file.parent.mkdir(parents=True, exist_ok=True)
log = []
if log_file.exists():
    try:
        loaded = json.loads(log_file.read_text(encoding="utf-8"))
        if isinstance(loaded, list):
            log = loaded
    except Exception:
        log = []

now = datetime.now(timezone.utc).astimezone()
today = now.date().isoformat()
stamp = now.isoformat(timespec="seconds")

if modo == "1":
    entry = {
        "client": client,
        "date": today,
        "count": count,
        "updatedAt": stamp,
    }
    log.append(entry)
    print(f"✅ Histórico: novo envio registrado — {client}, {count} foto(s) em {today}.")
elif modo == "2":
    last_idx = None
    for i in range(len(log) - 1, -1, -1):
        if isinstance(log[i], dict) and log[i].get("client") == client:
            last_idx = i
            break
    if last_idx is None:
        entry = {
            "client": client,
            "date": today,
            "count": count,
            "updatedAt": stamp,
        }
        log.append(entry)
        print(f"⚠️  Não havia envio anterior de '{client}'. Criei um novo: {count} foto(s).")
    else:
        prev = log[last_idx].get("count", "?")
        log[last_idx]["count"] = count
        log[last_idx]["updatedAt"] = stamp
        print(f"✅ Histórico: atualizado último envio de '{client}' — {prev} → {count} foto(s).")

log_file.write_text(
    json.dumps(log, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)

print()
print(json_file.read_text(encoding="utf-8"))
PY
