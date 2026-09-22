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

echo
read -p "📝 Mensaje del commit: " mensaje

if [ -z "$mensaje" ]; then
    echo "❌ El mensaje del commit no puede estar vacío"
    exit 1
fi

echo
echo "🔄 Cambiando a $rama..."
git checkout "$rama"

echo "📦 Añadiendo cambios..."
git add .

echo "💾 Creando commit..."
git commit -m "$mensaje"

echo "⬆️ Haciendo push..."
git push origin "$rama"

echo
echo "✅ Commit y push realizados correctamente"
