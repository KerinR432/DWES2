#!/bin/bash

# ==================================================
#              GESTOR GIT - PROYECTO
# ==================================================

set -e

# Carpeta donde está este script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Ramas disponibles
RAMAS=("TEORIA" "codigo" "main")


# ==================================================
# FUNCIONES GENERALES
# ==================================================

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

    case "$opcion" in
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
            echo "❌ Opción no válida."
            return 1
            ;;
    esac
}


# ==================================================
# PULL
# ==================================================

hacer_pull() {

    seleccionar_rama || return

    echo
    echo "🔄 Cambiando a $rama..."

    git checkout "$rama"

    echo
    echo "⬇️ Actualizando información del remoto..."

    git fetch origin

    echo
    echo "⬇️ Haciendo pull de $rama..."

    git pull origin "$rama"

    echo
    echo "✅ Rama $rama actualizada correctamente."

    pausa
}


# ==================================================
# COMMIT + PUSH
# ==================================================

hacer_push() {

    seleccionar_rama || return

    echo
    echo "🔄 Cambiando a $rama..."

    git checkout "$rama"

    echo
    echo "📋 Archivos modificados:"
    echo

    git status --short

    echo

    # Comprobar si hay cambios
    if git diff --quiet && git diff --cached --quiet && \
       [ -z "$(git ls-files --others --exclude-standard)" ]; then

        echo "🟢 No hay cambios para hacer commit."
        pausa
        return
    fi

    read -p "¿Quieres añadir estos cambios? (s/n): " confirmar

    if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
        echo "❌ Operación cancelada."
        pausa
        return
    fi

    echo
    echo "📦 Añadiendo cambios..."

    git add .

    echo
    read -p "📝 Mensaje del commit: " mensaje

    if [ -z "$mensaje" ]; then
        echo "❌ El mensaje no puede estar vacío."
        pausa
        return
    fi

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


# ==================================================
# ESTADO DE TODAS LAS RAMAS
# ==================================================

ver_estado() {

    echo
    echo "🔎 Actualizando información del remoto..."
    echo

    git fetch origin

    echo
    echo "=========================================="
    echo "          ESTADO DEL PROYECTO"
    echo "=========================================="

    rama_actual=$(git branch --show-current)

    for rama in "${RAMAS[@]}"
    do

        echo
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📌 RAMA: $rama"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        git checkout "$rama" > /dev/null 2>&1

        cambios=$(git status --porcelain)

        adelante=$(git rev-list --count "origin/$rama..$rama")

        atras=$(git rev-list --count "$rama..origin/$rama")

        autor=$(git log -1 --format="%an")
        fecha=$(git log -1 --format="%ad" --date="format:%d/%m/%Y %H:%M")
        mensaje=$(git log -1 --format="%s")

        if [ -n "$cambios" ]; then
            echo "🟡 Tienes cambios sin commit."
        fi

        if [ "$adelante" -gt 0 ]; then
            echo "🔵 Tienes $adelante commit(s) pendiente(s) de PUSH."
        fi

        if [ "$atras" -gt 0 ]; then
            echo "🔴 Te faltan $atras commit(s) del remoto."
        fi

        if [ -z "$cambios" ] && [ "$adelante" -eq 0 ] && [ "$atras" -eq 0 ]; then
            echo "🟢 Todo actualizado."
        fi

        echo
        echo "Último commit:"
        echo "👤 Autor:   $autor"
        echo "📅 Fecha:   $fecha"
        echo "📝 Mensaje: $mensaje"

    done

    # Volver a la rama original
    if [ -n "$rama_actual" ]; then
        git checkout "$rama_actual" > /dev/null 2>&1
    fi

    echo
    echo "=========================================="

    pausa
}


# ==================================================
# HISTORIAL
# ==================================================

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


# ==================================================
# VER CAMBIOS DE UN COMMIT
# ==================================================

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

    if ! git show --stat "$commit"; then
        echo
        echo "❌ Ese commit no existe."
        pausa
        return
    fi

    echo
    read -p "¿Quieres ver los cambios completos? (s/n): " respuesta

    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
        echo
        git show "$commit"
    fi

    pausa
}


# ==================================================
# GIT BLAME
# ==================================================

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


# ==================================================
# MERGE
# ==================================================

hacer_merge() {

    echo
    echo "=========================================="
    echo "              🔀 MERGE"
    echo "=========================================="

    echo
    echo "Selecciona la RAMA DESTINO:"
    echo "1) TEORIA"
    echo "2) codigo"
    echo "3) main"
    echo

    read -p "Opción: " opcion_destino

    case "$opcion_destino" in
        1)
            destino="TEORIA"
            ;;
        2)
            destino="codigo"
            ;;
        3)
            destino="main"
            ;;
        *)
            echo "❌ Opción no válida."
            pausa
            return
            ;;
    esac


    echo
    echo "Selecciona la RAMA ORIGEN:"
    echo "1) TEORIA"
    echo "2) codigo"
    echo "3) main"
    echo

    read -p "Opción: " opcion_origen

    case "$opcion_origen" in
        1)
            origen="TEORIA"
            ;;
        2)
            origen="codigo"
            ;;
        3)
            origen="main"
            ;;
        *)
            echo "❌ Opción no válida."
            pausa
            return
            ;;
    esac


    # No permitir merge de la misma rama
    if [ "$destino" = "$origen" ]; then
        echo
        echo "❌ No puedes hacer merge de una rama consigo misma."
        pausa
        return
    fi


    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔀 OPERACIÓN:"
    echo
    echo "   $origen  →  $destino"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


    # Comprobar cambios sin guardar
    if [ -n "$(git status --porcelain)" ]; then

        echo
        echo "⚠️ Tienes cambios locales sin commit:"
        git status --short

        echo
        echo "❌ Haz commit o guarda los cambios antes del merge."

        pausa
        return
    fi


    echo
    read -p "¿Quieres continuar con el merge? (s/n): " confirmar

    if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
        echo "❌ Merge cancelado."
        pausa
        return
    fi


    echo
    echo "🔄 Cambiando a $destino..."

    git checkout "$destino"


    echo
    echo "⬇️ Actualizando $destino..."

    git pull origin "$destino"


    echo
    echo "🔀 Haciendo merge de $origen..."

    if ! git merge "$origen"; then

        echo
        echo "=========================================="
        echo "⚠️ CONFLICTO DE MERGE"
        echo "=========================================="
        echo
        echo "Git ha encontrado conflictos."
        echo
        echo "Archivos afectados:"
        git status --short
        echo
        echo "Resuelve los conflictos manualmente."
        echo "Después ejecuta:"
        echo
        echo "    git add ."
        echo "    git commit"
        echo
        echo "Y finalmente:"
        echo
        echo "    git push origin $destino"

        pausa
        return
    fi


    echo
    echo "⬆️ Subiendo $destino al remoto..."

    git push origin "$destino"


    echo
    echo "=========================================="
    echo "✅ MERGE COMPLETADO"
    echo "=========================================="
    echo
    echo "$origen → $destino"

    pausa
}


# ==================================================
# MENU PRINCIPAL
# ==================================================

while true
do

    clear

    echo
    echo "╔══════════════════════════════════════╗"
    echo "║             GESTOR GIT               ║"
    echo "╠══════════════════════════════════════╣"
    echo "║ 1. 📥 Pull                           ║"
    echo "║ 2. 📤 Commit + Push                  ║"
    echo "║ 3. 🔎 Ver estado                     ║"
    echo "║ 4. 📜 Ver historial                  ║"
    echo "║ 5. 🔍 Ver cambios de commit          ║"
    echo "║ 6. 👤 Ver quién modificó             ║"
    echo "║ 7. 🔀 Merge                          ║"
    echo "║ 8. 🚪 Salir                          ║"
    echo "╚══════════════════════════════════════╝"
    echo

    echo "📂 Proyecto:"
    echo "$SCRIPT_DIR"

    echo
    echo "🌿 Rama actual: $(git branch --show-current)"
    echo

    read -p "Selecciona una opción: " opcion

    case "$opcion" in

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
            hacer_merge
            ;;

        8)
            echo
            echo "👋 Saliendo del gestor Git..."
            exit 0
            ;;

        *)
            echo
            echo "❌ Opción no válida."
            sleep 2
            ;;

    esac

done
