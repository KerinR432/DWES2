#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "📂 Proyecto: $SCRIPT_DIR"
echo
echo "Selecciona la rama:"
echo "1) TEORIA"
echo "2) codigo"
echo "3) main"
echo

read -p "Rama: " opcion

case $opcion in
    1)
        rama="TEORIA"
        ;;
    2)
        rama="codigo"
        ;;
    3)
        rama="main"
        ;;
    *)
        echo "❌ Opción no válida"
        exit 1
        ;;
esac

echo "🔄 Cambiando a la rama $rama..."
git checkout "$rama"

echo "⬇️ Haciendo pull de $rama..."
git pull origin "$rama"

echo "✅ Rama $rama actualizada correctamente"

