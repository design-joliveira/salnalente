#!/bin/bash

# Navega para a pasta onde o script está
cd "$(dirname "$0")"

# Pede o nome do cliente
echo "Qual o nome do cliente? (ex: fernando)"
read CLIENT

if [ -z "$CLIENT" ]; then
  echo "❌ Nome do cliente não informado."
  exit 1
fi

FOTOS_DIR="$CLIENT/fotos"
JSON_FILE="$CLIENT/fotos.json"

if [ ! -d "$FOTOS_DIR" ]; then
  echo "❌ Pasta '$FOTOS_DIR' não encontrada."
  exit 1
fi

FILES=$(ls "$FOTOS_DIR" | grep -iE '\.(jpg|jpeg|png|webp)$' | sort)

if [ -z "$FILES" ]; then
  echo "❌ Nenhuma foto encontrada em '$FOTOS_DIR'."
  exit 1
fi

echo "[" > "$JSON_FILE"
LAST=$(echo "$FILES" | tail -1)
while IFS= read -r file; do
  if [ "$file" = "$LAST" ]; then
    echo "  \"$file\"" >> "$JSON_FILE"
  else
    echo "  \"$file\"," >> "$JSON_FILE"
  fi
done <<< "$FILES"
echo "]" >> "$JSON_FILE"

echo "✅ $JSON_FILE gerado com sucesso:"
cat "$JSON_FILE"
