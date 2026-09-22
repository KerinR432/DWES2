#!/bin/bash

# ==========================================
#        GESTOR GIT - PROYECTO
# ==========================================

set -e

# Carpeta donde está este script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Ramas del proyecto
RAMAS=("TEORIA" "codigo" "main")


# ==========================================
# FUNCIONES
# ==========================================

pausa() {
    echo
    read -p "Pulsa ENTER para continuar..."
}


seleccionar_rama() {

    echo
    echo "Selecciona una rama:"
    echo "1) TEORIA"
    echo "2) codigo"
    echo "3) main"
    echo

    read -p "Opción: " opcion

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
            return 1
            ;;
    esac

    return 0
}


# ==========================================
# PULL
# ==========================================

hacer_pull() {

    seleccionar_rama || return

    echo
    echo "🔄 Cambiando a $rama..."

    git checkout "$rama"

    echo
    echo "⬇️ Actualizando $rama..."

    git pull origin "$rama"

    echo
    echo "✅ Rama $rama actualizada."

    pausa
}


# ==========================================
# COMMIT + PUSH
# ==========================================

hacer_push() {

    seleccionar_rama || return

    echo
    echo "🔄 Cambiando a $rama..."

    git checkout "$rama"

    echo
    echo "📋 Cambios actuales:"
    git status --short

    echo
    read -p "📝 Mensaje del commit: " mensaje

    if [ -z "$mensaje" ]; then
        echo "❌ El mensaje no puede estar vacío."
        pausa
        return
    fi

    echo
    echo "📦 Añadiendo archivos..."

    git add .

    echo
    echo "💾 Creando commit..."

    git commit -m "$mensaje"

    echo
    echo "⬆️ Subiendo a origin/$rama..."

    git push origin "$rama"

    echo
    echo "✅ Commit y push realizados correctamente."

    pausa
}


# ==========================================
# ESTADO
# ==========================================

ver_estado() {

    echo
    echo "🔎 ACTUALIZANDO INFORMACIÓN DEL REMOTO..."
    echo

    git fetch origin

    echo
    echo "=========================================="
    echo "          ESTADO DEL PROYECTO"
    echo "=========================================="

    for rama in "${RAMAS[@]}"
    do

        echo
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📌 RAMA: $rama"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Cambiar de rama
        git checkout "$rama" > /dev/null 2>&1

        # Cambios sin commit
        cambios=$(git status --porcelain)

        # Commits locales pendientes de push
        adelante=$(git rev-list --count "origin/$rama..$rama")

        # Commits que existen en remoto pero no local
        atras=$(git rev-list --count "$rama..origin/$rama")

        # Último commit
        autor=$(git log -1 --format="%an")
        fecha=$(git log -1 --format="%ad" --date="format:%d/%m/%Y %H:%M")
        mensaje=$(git log -1 --format="%s")

        if [ -n "$cambios" ]; then
            echo "🟡 Tienes cambios sin commit"
        fi

        if [ "$adelante" -gt 0 ]; then
            echo "🔵 Tienes $adelante commit(s) pendiente(s) de PUSH"
        fi

        if [ "$atras" -gt 0 ]; then
            echo "🔴 Te faltan $atras commit(s) del remoto"
        fi

        if [ -z "$cambios" ] && [ "$adelante" -eq 0 ] && [ "$atras" -eq 0 ]; then
            echo "🟢 Todo actualizado"
        fi

        echo
        echo "Último commit:"
        echo "👤 Autor:   $autor"
        echo "📅 Fecha:   $fecha"
        echo "📝 Mensaje: $mensaje"

    done

    echo
    echo "=========================================="

    pausa
}


# ==========================================
# HISTORIAL
# ==========================================

ver_historial() {

    seleccionar_rama || return

    echo
    echo "📜 HISTORIAL DE $rama"
    echo

    git log "$rama" \
        --pretty=format:"%C(yellow)%h%Creset | %C(cyan)%ad%Creset | %C(green)%an%Creset | %s" \
        --date="format:%d/%m/%Y %H:%M" \
        --graph

    echo
    pausa
}


# ==========================================
# CAMBIOS DE UN COMMIT
# ==========================================

ver_commit() {

    echo
    read -p "🔑 Introduce el ID del commit: " commit

    if [ -z "$commit" ]; then
        echo "❌ No has introducido ningún commit."
        pausa
        return
    fi

    echo
    echo "🔍 Información del commit:"
    echo

    git show --stat "$commit"

    echo
    echo "¿Quieres ver los cambios completos?"
    read -p "(s/n): " respuesta

    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
        echo
        git show "$commit"
    fi

    pausa
}


# ==========================================
# GIT BLAME
# ==========================================

ver_blame() {

    echo
    read -p "📄 Introduce el nombre del archivo: " archivo

    if [ ! -f "$archivo" ]; then
        echo "❌ El archivo no existe."
        pausa
        return
    fi

    echo
    echo "👤 QUIÉN MODIFICÓ CADA LÍNEA"
    echo

    git blame "$archivo"

    pausa
}


# ==========================================
# MENU
# ==========================================

while true
do

    clear

    echo "╔════════════════════════════════╗"
    echo "║          GESTOR GIT            ║"
    echo "╠════════════════════════════════╣"
    echo "║ 1. 📥 Pull                    ║"
    echo "║ 2. 📤 Commit + Push           ║"
    echo "║ 3. 🔎 Ver estado              ║"
    echo "║ 4. 📜 Ver historial           ║"
    echo "║ 5. 🔍 Ver cambios de commit   ║"
    echo "║ 6. 👤 Ver quién modificó      ║"
    echo "║ 7. 🚪 Salir                   ║"
    echo "╚════════════════════════════════╝"
    echo

    read -p "Selecciona una opción: " opcion

    case $opcion in

        1)
            hacer_pull
            ;;

        2)
            hacer_push
            ;;

        3)
            ver_estado
            ;;

        4)
            ver_historial
            ;;

        5)
            ver_commit
            ;;

        6)
            ver_blame
            ;;

        7)
            echo
            echo "👋 Saliendo..."
            exit 0
            ;;

        *)
            echo
            echo "❌ Opción no válida."
            sleep 2
            ;;

    esac

done
