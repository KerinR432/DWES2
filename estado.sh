#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "🔎 Comprobando estado del repositorio..."
echo

# Actualizar información del remoto sin modificar archivos
git fetch origin

for rama in TEORIA codigo main
do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 Rama: $rama"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Cambiar a la rama
    git checkout "$rama" > /dev/null 2>&1

    # Comprobar cambios sin commit
    cambios=$(git status --porcelain)

    # Commits locales que no están en remoto
    adelante=$(git rev-list --count "origin/$rama..$rama")

    # Commits remotos que no están en local
    atras=$(git rev-list --count "$rama..origin/$rama")

    if [ -n "$cambios" ]; then
        echo "🟡 Tienes cambios sin hacer commit"
    fi

    if [ "$adelante" -gt 0 ]; then
        echo "🔵 Tienes $adelante commit(s) pendiente(s) de push"
    fi

    if [ "$atras" -gt 0 ]; then
        echo "🔴 Te faltan $atras commit(s) del remoto"
    fi

    if [ -z "$cambios" ] && [ "$adelante" -eq 0 ] && [ "$atras" -eq 0 ]; then
        echo "🟢 Todo actualizado"
    fi

    echo
done

echo "✅ Comprobación terminada"
