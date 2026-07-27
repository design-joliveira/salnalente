#!/bin/bash

# Compatibilidade: gera home/fotos.json
# Prefira: ./gerar-fotos-pagina.command home

cd "$(dirname "$0")"
exec ./gerar-fotos-pagina.command home
