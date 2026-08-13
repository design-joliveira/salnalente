#!/bin/bash
cd "$(dirname "$0")"

PORT=8765
URL="http://127.0.0.1:${PORT}/ordenar.html"

if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Servidor já está rodando na porta ${PORT}."
else
  echo "Subindo servidor em ${URL}"
  echo "Deixe esta janela aberta enquanto estiver curando as fotos."
  echo "Para encerrar: Ctrl+C"
  echo
  python3 -m http.server "$PORT" --bind 127.0.0.1 &
  SERVER_PID=$!
  trap 'kill $SERVER_PID 2>/dev/null' EXIT
  sleep 0.4
fi

open -a "Google Chrome" "$URL" 2>/dev/null || open "$URL"

# Se acabamos de subir o servidor, mantém o terminal aberto com os logs
if [ -n "${SERVER_PID:-}" ]; then
  wait "$SERVER_PID"
fi
