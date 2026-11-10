#!/usr/bin/env bash

# ==========================================================
#                  🌿 GESTOR GIT
# ==========================================================
# Proyecto: DWS / DWES2
#
# Compatible con:
#   - Linux / Bash
#   - Windows 11 / Git Bash
#
# Ramas:
#   - TEORIA
#   - codigo
#   - main
#
# Flujo de trabajo (estilo empresa):
#   - Commits con prefijo Conventional Commits
#   - Revisión de cambios antes de commitear
#   - No se pushea a main sin confirmación explícita
#   - Deshacer con revert si está publicado, reset si es local
#   - Sincronización segura de ramas divergidas con rebase
# ==========================================================

set -u
set -o pipefail

# ==========================================================
# CONFIGURACIÓN
# ==========================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

RAMAS=("TEORIA" "codigo" "main")
RAMA_PROTEGIDA="main"
REMOTO="origin"

SELECTED_BRANCH=""

# ==========================================================
# COLORES
# ==========================================================

RESET="\033[0m"

ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
MAGENTA="\033[1;35m"
CIAN="\033[1;36m"
BLANCO="\033[1;37m"
GRIS="\033[0;37m"

# ==========================================================
# FUNCIONES VISUALES
# ==========================================================

limpiar_pantalla() {
    clear 2>/dev/null || printf '\033c'
}

titulo() {

    limpiar_pantalla

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║                 🌿  GESTOR GIT                        ║${RESET}"
    echo -e "${CIAN}║                  Proyecto DWS                         ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
}

linea() {
    echo -e "${GRIS}────────────────────────────────────────────────────────${RESET}"
}

pausa() {
    echo
    read -r -p "Pulsa ENTER para continuar..." _
}

ok()     { echo -e "${VERDE}🟢 $1${RESET}"; }
aviso()  { echo -e "${AMARILLO}🟡 $1${RESET}"; }
error()  { echo -e "${ROJO}🔴 $1${RESET}"; }
info()   { echo -e "${AZUL}🔵 $1${RESET}"; }

# Pregunta s/n. Devuelve 0 si la respuesta es sí.

confirmar() {

    local pregunta="${1:-¿Continuar?}"
    local respuesta

    read -r -p "$pregunta (s/n): " respuesta

    [[ "$respuesta" == "s" || "$respuesta" == "S" ]]
}

# Ejecuta un log/diff largo con paginador si existe less.

paginar() {

    if command -v less >/dev/null 2>&1; then
        less -R
    else
        cat
    fi
}

# ==========================================================
# COMPROBACIONES INICIALES
# ==========================================================

comprobar_entorno() {

    # Sin terminal interactiva los 'read' fallan en bucle.
    if [ ! -t 0 ]; then
        error "Este script necesita una terminal interactiva."
        return 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        error "Git no está instalado o no está disponible en PATH."
        echo
        echo "En Windows, asegúrate de ejecutar este script desde Git Bash."
        echo "En Linux, instala Git con el gestor de paquetes de tu distribución."
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        error "Esta carpeta no es un repositorio Git."
        echo
        echo "Repositorio esperado:"
        echo "  $SCRIPT_DIR"
        return 1
    fi

    if ! git remote get-url "$REMOTO" >/dev/null 2>&1; then
        aviso "No existe el remoto '$REMOTO'."
        echo
        echo "Puedes añadirlo con:"
        echo
        echo "  git remote add $REMOTO <URL>"
        echo
        return 1
    fi

    # Identidad de Git: sin esto los commits salen sin autor válido.
    if [ -z "$(git config user.name 2>/dev/null)" ] ||
       [ -z "$(git config user.email 2>/dev/null)" ]; then
        aviso "Git no tiene user.name / user.email configurados."
        echo
        echo "Los commits podrían fallar o salir mal firmados. Configúralo con:"
        echo
        echo "  git config --global user.name  \"Tu Nombre\""
        echo "  git config --global user.email \"tu@email.com\""
        echo
    fi

    return 0
}

# ==========================================================
# INFORMACIÓN GIT
# ==========================================================

rama_actual() {
    git branch --show-current 2>/dev/null || true
}

hay_cambios() {
    [ -n "$(git status --porcelain 2>/dev/null)" ]
}

rama_existe() {
    git show-ref --verify --quiet "refs/heads/$1"
}

remoto_existe() {
    git show-ref --verify --quiet "refs/remotes/$REMOTO/$1"
}

# Devuelve el número de commits de diferencia con el remoto.
# Uso: contar_diferencia <rama> <adelante|atras>

contar_diferencia() {

    local rama="$1"
    local direccion="$2"

    if ! rama_existe "$rama" || ! remoto_existe "$rama"; then
        echo 0
        return
    fi

    case "$direccion" in

        adelante)
            git rev-list --count "$REMOTO/$rama..$rama" 2>/dev/null || echo 0
            ;;

        atras)
            git rev-list --count "$rama..$REMOTO/$rama" 2>/dev/null || echo 0
            ;;

    esac
}

# Devuelve el nombre de la operación Git pendiente
# (merge, rebase, cherry-pick, revert) o nada si no hay.

operacion_pendiente() {

    local git_dir

    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 1

    if [ -f "$(git rev-parse --git-path MERGE_HEAD 2>/dev/null)" ]; then
        echo "merge"
        return 0
    fi

    if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
        echo "rebase"
        return 0
    fi

    if [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
        echo "cherry-pick"
        return 0
    fi

    if [ -f "$git_dir/REVERT_HEAD" ]; then
        echo "revert"
        return 0
    fi

    return 1
}

# Resumen de cambios del árbol de trabajo:
#   preparados / sin preparar / sin seguimiento

resumen_cambios() {

    local preparados
    local sin_preparar
    local sin_seguimiento

    preparados="$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')"
    sin_preparar="$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')"
    sin_seguimiento="$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"

    echo "preparados=$preparados sin_preparar=$sin_preparar sin_seguimiento=$sin_seguimiento"
}

# ==========================================================
# CAMBIAR DE RAMA
# ==========================================================

cambiar_rama() {

    local destino="$1"
    local actual

    actual="$(rama_actual)"

    if [ "$actual" = "$destino" ]; then
        return 0
    fi

    if ! rama_existe "$destino"; then
        error "La rama '$destino' no existe."
        return 1
    fi

    if hay_cambios; then
        error "Tienes cambios locales sin guardar."
        echo
        git status --short
        echo
        aviso "Haz commit (opción 2) o guárdalos en stash (opción 5) antes de cambiar de rama."
        return 1
    fi

    info "Cambiando a la rama '$destino'..."

    if git checkout "$destino"; then
        ok "Ahora estás en '$destino'."
        return 0
    fi

    error "No se ha podido cambiar a '$destino'."
    return 1
}

# ==========================================================
# CABECERA
# ==========================================================

mostrar_cabecera() {

    local rama
    local pendiente
    local autor
    local email

    rama="$(rama_actual)"
    autor="$(git config user.name 2>/dev/null || true)"
    email="$(git config user.email 2>/dev/null || true)"

    echo -e "${BLANCO}📂 Proyecto:${RESET} DWS / DWES2"
    echo -e "${GRIS}$SCRIPT_DIR${RESET}"

    if [ -n "$autor" ]; then
        echo -e "${BLANCO}👤 Autor Git:${RESET} ${autor} <${email}>"
    fi

    echo

    if [ -n "$rama" ]; then
        echo -e "${BLANCO}🌿 Rama actual:${RESET} ${MAGENTA}$rama${RESET}"
    else
        echo -e "${AMARILLO}⚠️ HEAD separado${RESET}"
    fi

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        echo
        error "Hay una operación pendiente: $pendiente (opción 12)."
    fi

    echo
}

# ==========================================================
# SELECCIONAR RAMA
# ==========================================================

# Muestra el menú de ramas y deja la elección en SELECTED_BRANCH.
# La etiqueta permite reutilizarla (rama destino, origen, etc.).

seleccionar_rama() {

    local etiqueta="${1:-Selecciona una rama}"
    local opcion
    local rama
    local indice

    echo
    echo -e "${BLANCO}${etiqueta}${RESET}"
    echo

    indice=1
    for rama in "${RAMAS[@]}"
    do
        echo "  $indice) $rama"
        indice=$((indice + 1))
    done

    echo

    read -r -p "Opción: " opcion

    if [[ "$opcion" =~ ^[0-9]+$ ]] &&
       [ "$opcion" -ge 1 ] &&
       [ "$opcion" -le "${#RAMAS[@]}" ]
    then
        rama="${RAMAS[$((opcion - 1))]}"
    else
        error "Opción no válida."
        return 1
    fi

    if ! rama_existe "$rama"; then
        error "La rama local '$rama' no existe."
        return 1
    fi

    SELECTED_BRANCH="$rama"

    return 0
}

# ==========================================================
# PULL
# ==========================================================

hacer_pull() {

    local rama
    local pendiente

    titulo
    mostrar_cabecera

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        error "Hay una operación Git pendiente: $pendiente."
        echo
        git status
        echo
        aviso "Finaliza o cancela la operación antes de hacer pull (opción 12)."
        pausa
        return
    fi

    if hay_cambios; then
        error "Tienes cambios locales sin commit."
        echo
        git status --short
        echo
        aviso "Haz commit (opción 2) o guárdalos en stash (opción 5) antes de hacer pull."
        pausa
        return
    fi

    seleccionar_rama "Selecciona una rama:" || {
        pausa
        return
    }

    rama="$SELECTED_BRANCH"

    echo
    info "Cambiando a $rama..."

    if ! cambiar_rama "$rama"; then
        pausa
        return
    fi

    echo
    info "Haciendo pull de $REMOTO/$rama..."

    # --ff-only: si las ramas han divergido, el pull se detiene
    # en lugar de crear un merge automático.

    if ! git pull --ff-only "$REMOTO" "$rama"; then
        echo
        error "El pull no se ha podido completar."
        echo
        echo "Causas habituales:"
        echo
        echo "  - Las ramas local y remota han divergido."
        echo "    Usa la opción 7 (Sincronizar rama divergida)."
        echo
        echo "  - No hay conexión con el remoto."
        pausa
        return
    fi

    echo
    ok "Rama $rama actualizada correctamente."

    pausa
}

# ==========================================================
# TIPO DE COMMIT (CONVENTIONAL COMMITS)
# ==========================================================

# Devuelve el prefijo del commit (feat:, fix:...) o cadena vacía.

elegir_tipo_commit() {

    local opcion

    echo
    echo -e "${BLANCO}🏷️ TIPO DE CAMBIO (Conventional Commits)${RESET}"
    linea
    echo
    echo "  1) feat      → Nueva funcionalidad"
    echo "  2) fix       → Corrección de un error"
    echo "  3) docs      → Documentación"
    echo "  4) style     → Formato (no cambia el código)"
    echo "  5) refactor  → Reorganización del código"
    echo "  6) test      → Pruebas"
    echo "  7) chore     → Tareas de mantenimiento"
    echo "  8) Sin tipo (mensaje libre)"
    echo

    read -r -p "Opción: " opcion

    case "$opcion" in

        1) echo "feat" ;;
        2) echo "fix" ;;
        3) echo "docs" ;;
        4) echo "style" ;;
        5) echo "refactor" ;;
        6) echo "test" ;;
        7) echo "chore" ;;
        8) echo "" ;;
        *)
            aviso "Opción no válida: se usará mensaje sin tipo."
            echo ""
            ;;

    esac
}

# ==========================================================
# COMMIT + PUSH
# ==========================================================

hacer_push() {

    local rama
    local pendiente
    local tipo
    local mensaje
    local mensaje_final
    local atras

    titulo
    mostrar_cabecera

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        error "Tienes una operación Git pendiente: $pendiente."
        echo
        git status
        echo
        aviso "Finaliza o cancela la operación antes de hacer commit (opción 12)."
        pausa
        return
    fi

    seleccionar_rama "Selecciona una rama:" || {
        pausa
        return
    }

    rama="$SELECTED_BRANCH"

    # ------------------------------------------------------
    # Aviso de rama protegida (buena práctica de empresa)
    # ------------------------------------------------------

    if [ "$rama" = "$RAMA_PROTEGIDA" ]; then
        echo
        echo -e "${ROJO}⚠️ ESTÁS A PUNTO DE TRABAJAR EN '$RAMA_PROTEGIDA'${RESET}"
        linea
        echo
        echo "En un entorno profesional la rama principal está protegida:"
        echo "los cambios se integran mediante Pull Request, no con push directo."
        echo
        if ! confirmar "¿Quieres continuar de todos modos?"; then
            aviso "Operación cancelada."
            pausa
            return
        fi
    fi

    echo
    echo -e "${BLANCO}📤 COMMIT + PUSH${RESET}"
    linea

    if ! cambiar_rama "$rama"; then
        pausa
        return
    fi

    echo
    echo -e "${BLANCO}📋 CAMBIOS ACTUALES${RESET}"
    linea

    git status --short

    if ! hay_cambios; then
        echo
        ok "No hay cambios para hacer commit."
        pausa
        return
    fi

    # ------------------------------------------------------
    # Revisión de cambios antes de añadir (code review propio)
    # ------------------------------------------------------

    echo
    if confirmar "¿Quieres revisar los cambios antes de añadirlos?"; then

        echo
        echo -e "${BLANCO}📊 RESUMEN${RESET}"
        linea
        echo

        git diff --stat
        git diff --cached --stat

        echo
        if confirmar "¿Quieres ver el detalle completo (diff)?"; then
            echo
            git diff HEAD | paginar
        fi

        echo
        aviso "Recuerda: los archivos nuevos (sin seguimiento) no aparecen en el diff,"
        echo "pero sí se incluirán en el commit."
    fi

    echo
    aviso "Se utilizará 'git add -A'."
    echo "Esto incluirá archivos nuevos, modificados y eliminados."
    echo

    if ! confirmar "¿Quieres continuar?"; then
        aviso "Operación cancelada."
        pausa
        return
    fi

    echo
    info "Preparando archivos..."

    if ! git add -A; then
        error "No se han podido preparar los archivos."
        pausa
        return
    fi

    # ------------------------------------------------------
    # Mensaje con Conventional Commits
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}📦 CAMBIOS PREPARADOS${RESET}"
    linea

    git status --short

    tipo="$(elegir_tipo_commit)"

    echo
    read -r -p "📝 Mensaje del commit: " mensaje

    if [ -z "$mensaje" ]; then
        error "El mensaje no puede estar vacío."
        git restore --staged . 2>/dev/null || true
        pausa
        return
    fi

    if [ -n "$tipo" ]; then
        mensaje_final="$tipo: $mensaje"
    else
        mensaje_final="$mensaje"
    fi

    echo
    info "Commit: $mensaje_final"

    echo
    info "Creando commit..."

    if ! git commit -m "$mensaje_final"; then
        error "No se pudo crear el commit."
        pausa
        return
    fi

    echo
    ok "Commit creado correctamente."

    # ------------------------------------------------------
    # Comprobar el remoto ANTES del push para no chocar
    # contra un rechazo por no-fast-forward.
    # ------------------------------------------------------

    echo
    info "Comprobando el remoto..."

    if ! git fetch "$REMOTO"; then
        error "No se ha podido contactar con el remoto."
        echo
        echo "El commit está guardado localmente."
        echo "Puedes volver a intentar el push más tarde."
        pausa
        return
    fi

    atras="$(contar_diferencia "$rama" "atras")"

    if [ "$atras" -gt 0 ]; then

        error "El remoto tiene $atras commit(s) que no tienes en local."
        echo
        echo "Si haces push ahora, Git lo rechazaría."
        echo
        echo "Sincroniza primero con la opción 7 (Sincronizar rama divergida)"
        echo "y después repite esta opción (no repetirá el commit)."
        pausa
        return
    fi

    echo
    info "Subiendo a $REMOTO/$rama..."

    if ! git push "$REMOTO" "$rama"; then
        echo
        error "El push ha fallado."
        echo
        echo "El commit sigue guardado localmente."
        echo
        echo "Puedes volver a intentarlo con:"
        echo
        echo "  git push $REMOTO $rama"

        pausa
        return
    fi

    echo
    ok "Commit y push realizados correctamente."

    pausa
}

# ==========================================================
# VER CAMBIOS (DIFF)
# ==========================================================

ver_cambios() {

    titulo
    mostrar_cabecera

    local resumen
    local preparados
    local sin_preparar
    local sin_seguimiento

    echo -e "${BLANCO}👁️ CAMBIOS DEL PROYECTO${RESET}"
    linea
    echo

    git status --short

    if ! hay_cambios; then
        ok "No hay cambios: el árbol de trabajo está limpio."
        pausa
        return
    fi

    resumen="$(resumen_cambios)"
    preparados="${resumen#preparados=}"
    preparados="${preparados%% *}"
    sin_preparar="${resumen#*sin_preparar=}"
    sin_preparar="${sin_preparar%% *}"
    sin_seguimiento="${resumen#*sin_seguimiento=}"

    echo
    linea
    echo "   📦 Preparados (staged):        $preparados"
    echo "   ✏️  Sin preparar (modified):    $sin_preparar"
    echo "   ❓ Sin seguimiento (untracked): $sin_seguimiento"
    linea

    echo
    echo -e "${BLANCO}📊 RESUMEN DEL DIFF${RESET}"
    linea
    echo

    if [ "$sin_preparar" -gt 0 ]; then
        echo -e "${BLANCO}— Sin preparar —${RESET}"
        git diff --stat
        echo
    fi

    if [ "$preparados" -gt 0 ]; then
        echo -e "${BLANCO}— Preparados —${RESET}"
        git diff --cached --stat
        echo
    fi

    if [ "$sin_seguimiento" -gt 0 ]; then
        echo -e "${BLANCO}— Sin seguimiento (no están en el diff) —${RESET}"
        git ls-files --others --exclude-standard
        echo
    fi

    if confirmar "¿Quieres ver el detalle completo (diff)?"; then
        echo
        git diff HEAD | paginar
    fi

    pausa
}

# ==========================================================
# STASH
# ==========================================================

hacer_stash() {

    local opcion
    local mensaje
    local fecha

    titulo
    mostrar_cabecera

    echo -e "${BLANCO}📦 STASH — CAMBIOS TEMPORALES${RESET}"
    linea
    echo

    echo "  1) 💾 Guardar los cambios actuales"
    echo "  2) 📋 Listar stashes guardados"
    echo "  3) 📤 Recuperar el último (pop)"
    echo "  4) 📤 Aplicar el último sin borrarlo (apply)"
    echo "  0) ↩️  Volver"
    echo

    read -r -p "Opción: " opcion

    case "$opcion" in

        1)
            if ! hay_cambios; then
                ok "No hay cambios que guardar."
                pausa
                return
            fi

            fecha="$(date '+%d/%m/%Y %H:%M')"
            read -r -p "📝 Descripción (ENTER = WIP $fecha): " mensaje

            if [ -z "$mensaje" ]; then
                mensaje="WIP $fecha"
            fi

            echo
            info "Guardando cambios en stash..."

            # -u incluye los archivos sin seguimiento.

            if git stash push -u -m "$mensaje"; then
                echo
                ok "Cambios guardados: \"$mensaje\""
                aviso "El árbol de trabajo queda limpio."
            else
                echo
                error "No se han podido guardar los cambios."
            fi
            ;;

        2)
            echo
            echo -e "${BLANCO}📋 STASHES GUARDADOS${RESET}"
            linea
            echo

            if [ -z "$(git stash list 2>/dev/null)" ]; then
                ok "No hay stashes guardados."
            else
                git stash list
            fi
            ;;

        3|4)
            if [ -z "$(git stash list 2>/dev/null)" ]; then
                ok "No hay stashes que recuperar."
                pausa
                return
            fi

            if hay_cambios; then
                error "Tienes cambios sin guardar en el árbol de trabajo."
                echo
                aviso "Haz commit (opción 2) o guárdalos antes de recuperar un stash."
                pausa
                return
            fi

            echo

            if [ "$opcion" = "3" ]; then
                info "Recuperando el último stash (pop)..."
                if git stash pop; then
                    echo
                    ok "Stash recuperado y eliminado de la lista."
                else
                    echo
                    error "Hay conflictos al recuperar el stash."
                    echo
                    echo "El stash NO se ha borrado: sigue en la lista."
                    echo
                    echo "Para resolverlos:"
                    echo
                    echo "   1. Edita los archivos en conflicto."
                    echo "   2. git add <archivo>"
                    echo "   3. git stash drop   (cuando termines)"
                fi
            else
                info "Aplicando el último stash (apply, se conserva)..."
                if git stash apply; then
                    echo
                    ok "Stash aplicado. El stash sigue guardado en la lista."
                else
                    echo
                    error "Hay conflictos al aplicar el stash."
                    echo
                    echo "El stash sigue intacto en la lista."
                fi
            fi
            ;;

        0)
            return
            ;;

        *)
            error "Opción no válida."
            ;;

    esac

    pausa
}

# ==========================================================
# DESHACER ÚLTIMO COMMIT
# ==========================================================

deshacer_commit() {

    titulo
    mostrar_cabecera

    local rama
    local pendiente
    local publicado
    local ultimo

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        error "Hay una operación pendiente: $pendiente (opción 12)."
        pausa
        return
    fi

    rama="$(rama_actual)"

    if [ -z "$rama" ]; then
        error "No puedes deshacer commits con HEAD separado."
        pausa
        return
    fi

    if ! git rev-parse --quiet --verify "HEAD~1" >/dev/null 2>&1; then
        error "No hay un commit anterior al que volver."
        pausa
        return
    fi

    ultimo="$(git log -1 --format='%h  %s')"

    echo -e "${BLANCO}↩️ DESHACER ÚLTIMO COMMIT${RESET}"
    linea
    echo

    echo "   Rama:   $rama"
    echo "   Commit: $ultimo"
    echo

    # ¿Está el commit publicado en el remoto?
    # Si el remoto contiene HEAD, deshacerlo en local obligaría
    # a reescribir historia publicada (force push): prohibido.

    if remoto_existe "$rama" &&
       git merge-base --is-ancestor HEAD "$REMOTO/$rama" 2>/dev/null; then
        publicado=1
    else
        publicado=0
    fi

    if [ "$publicado" -eq 1 ]; then

        echo -e "${AMARILLO}⚠️ Este commit YA ESTÁ publicado en $REMOTO/$rama.${RESET}"
        echo
        echo "Despublicar historial requiere force push (mala práctica)."
        echo "La forma segura de deshacerlo es crear un commit inverso:"
        echo "git revert."
        echo

        if ! confirmar "¿Crear commit inverso (revert)?"; then
            aviso "Operación cancelada."
            pausa
            return
        fi

        echo
        info "Creando commit inverso..."

        if git revert --no-edit HEAD; then
            echo
            ok "Commit inverso creado."
            aviso "Falta publicarlo: opción 2 (Commit + Push) o git push $REMOTO $rama."
        else
            echo
            error "No se pudo crear el commit inverso."
        fi

    else

        echo -e "${VERDE}🟢 Este commit todavía NO está publicado.${RESET}"
        echo
        echo "Se puede deshacer con seguridad usando reset --soft:"
        echo "los cambios vuelven al área de preparados (no se pierde nada)."
        echo

        if ! confirmar "¿Deshacer el commit con reset --soft?"; then
            aviso "Operación cancelada."
            pausa
            return
        fi

        echo
        info "Deshaciendo commit..."

        if git reset --soft HEAD~1; then
            echo
            ok "Commit deshecho."
            aviso "Los cambios siguen preparados: revísalos con la opción 4."
        else
            echo
            error "No se pudo deshacer el commit."
        fi

    fi

    pausa
}

# ==========================================================
# SINCRONIZAR RAMA DIVERGIDA
# ==========================================================

sincronizar_rama() {

    titulo
    mostrar_cabecera

    local rama
    local pendiente
    local adelante
    local atras

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        error "Hay una operación pendiente: $pendiente (opción 12)."
        pausa
        return
    fi

    echo -e "${BLANCO}🔁 SINCRONIZAR RAMA${RESET}"
    linea

    seleccionar_rama "Rama a sincronizar:" || {
        pausa
        return
    }

    rama="$SELECTED_BRANCH"

    echo
    info "Actualizando información del remoto..."

    if ! git fetch "$REMOTO"; then
        error "No se ha podido contactar con el remoto."
        pausa
        return
    fi

    adelante="$(contar_diferencia "$rama" "adelante")"
    atras="$(contar_diferencia "$rama" "atras")"

    echo
    echo -e "${BLANCO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "   Rama:   $rama"
    echo "   Local:  $adelante commit(s) por subir"
    echo "   Remoto: $atras commit(s) por bajar"
    echo -e "${BLANCO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo

    # ------------------------------------------------------
    # Caso: todo actualizado
    # ------------------------------------------------------

    if [ "$adelante" -eq 0 ] && [ "$atras" -eq 0 ]; then
        ok "La rama ya está sincronizada."
        pausa
        return
    fi

    # ------------------------------------------------------
    # Caso: solo falta push
    # ------------------------------------------------------

    if [ "$atras" -eq 0 ]; then
        ok "No hay nada que bajar del remoto."
        aviso "Solo necesitas subir: opción 2 (Commit + Push)."
        pausa
        return
    fi

    # ------------------------------------------------------
    # Caso: solo falta pull (fast-forward limpio)
    # ------------------------------------------------------

    if [ "$adelante" -eq 0 ]; then

        info "Estás detrás del remoto. Actualización rápida (fast-forward)..."

        if ! cambiar_rama "$rama"; then
            pausa
            return
        fi

        echo

        if git pull --ff-only "$REMOTO" "$rama"; then
            echo
            ok "Rama $rama actualizada correctamente."
        else
            echo
            error "No se pudo actualizar."
        fi

        pausa
        return
    fi

    # ------------------------------------------------------
    # Caso: divergida (el push se rechazaría)
    # ------------------------------------------------------

    error "La rama está DIVERGIDA: hay commits distintos en local y remoto."

    echo
    echo "Plan de sincronización:"
    echo
    echo "   Tus $adelante commit(s) locales se reordenarán ENCIMA de los"
    echo "   $atras commit(s) nuevos del remoto (rebase)."
    echo
    echo "Ventaja: historial lineal, sin commits de merge automáticos."

    echo
    if ! confirmar "¿Sincronizar con rebase?"; then
        aviso "Operación cancelada."
        pausa
        return
    fi

    if ! cambiar_rama "$rama"; then
        pausa
        return
    fi

    echo
    info "Aplicando rebase sobre $REMOTO/$rama..."

    if git pull --rebase "$REMOTO" "$rama"; then

        echo
        ok "Sincronización completada."
        aviso "Ahora la rama está a la par del remoto con tus commits encima."
        echo
        echo "Falta publicarlos: opción 2 (Commit + Push) o:"
        echo
        echo "   git push $REMOTO $rama"

    else

        echo
        error "SE HAN ENCONTRADO CONFLICTOS durante el rebase."

        echo
        echo -e "${BLANCO}Archivos en conflicto:${RESET}"
        echo

        git diff --name-only --diff-filter=U

        echo
        echo "Cómo continuar:"
        echo
        echo "   1. Edita los archivos en conflicto."
        echo "   2. git add <archivo>"
        echo "   3. git rebase --continue"
        echo
        echo "Para abandonar y volver al estado inicial:"
        echo
        echo "   git rebase --abort"
        echo
        echo "La opción 12 (Resolver operación pendiente) te guía por estos pasos."

    fi

    pausa
}

# ==========================================================
# TABLA DE ESTADO DE LAS RAMAS
# ==========================================================

mostrar_tabla_ramas() {

    local actual
    local rama
    local adelante
    local atras
    local cambios
    local estado

    actual="$(rama_actual)"

    printf " %-12s %-24s %-9s %-9s\n" \
        "RAMA" "ESTADO" "LOCAL +" "REMOTO -"

    linea

    for rama in "${RAMAS[@]}"
    do

        if ! rama_existe "$rama"; then

            printf " %-12s %-23b\n" \
                "$rama" "${ROJO}❌ No existe${RESET}"

            continue
        fi

        if ! remoto_existe "$rama"; then

            printf " %-12s %-23b\n" \
                "$rama" "${AMARILLO}⚠️ Sin remoto${RESET}"

            continue
        fi

        adelante="$(contar_diferencia "$rama" "adelante")"
        atras="$(contar_diferencia "$rama" "atras")"
        cambios=""

        if [ "$rama" = "$actual" ]; then
            cambios="$(git status --porcelain 2>/dev/null)"
        fi

        if [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then

            estado="${ROJO}🔴 Divergida${RESET}"

        elif [ -n "$cambios" ]; then

            estado="${AMARILLO}🟡 Cambios locales${RESET}"

        elif [ "$adelante" -gt 0 ]; then

            estado="${AZUL}🔵 Push pendiente${RESET}"

        elif [ "$atras" -gt 0 ]; then

            estado="${ROJO}🔴 Pull pendiente${RESET}"

        else

            estado="${VERDE}🟢 Actualizada${RESET}"

        fi

        printf " %-12s %-23b +%-8s -%-8s\n" \
            "$rama" \
            "$estado" \
            "$adelante" \
            "$atras"

    done
}

# ==========================================================
# ÚLTIMO COMMIT
# ==========================================================

mostrar_ultimo_commit() {

    local prefijo="${1:-   }"

    if ! git log -1 >/dev/null 2>&1; then
        echo
        aviso "No hay información de commit disponible."
        return 1
    fi

    echo
    echo "${prefijo}👤 Autor:   $(git log -1 --format='%an')"
    echo "${prefijo}📅 Fecha:   $(git log -1 --format='%ad' --date='format:%d/%m/%Y %H:%M')"
    echo "${prefijo}📝 Mensaje: $(git log -1 --format='%s')"
    echo "${prefijo}🔑 Commit:  $(git log -1 --format='%h')"

    return 0
}

# ==========================================================
# ESTADO DE LAS RAMAS
# ==========================================================

ver_estado() {

    titulo
    mostrar_cabecera

    echo -e "${BLANCO}🔎 ESTADO DEL PROYECTO${RESET}"
    linea

    if ! git fetch "$REMOTO"; then
        echo
        aviso "No se ha podido actualizar el remoto."
        echo "El estado puede no estar completamente actualizado."
    fi

    echo
    mostrar_tabla_ramas

    echo

    if hay_cambios; then
        aviso "La rama actual tiene cambios locales sin commit."
    else
        ok "La rama actual no tiene cambios sin commit."
    fi

    echo

    echo -e "${BLANCO}📌 SIGNIFICADO${RESET}"
    linea

    echo "🟢 Actualizada    → Todo sincronizado"
    echo "🟡 Cambios        → Hay modificaciones locales"
    echo "🔵 Push pendiente → Hay commits por subir"
    echo "🔴 Pull pendiente → Hay commits nuevos en remoto"
    echo "🔴 Divergida      → Hay commits diferentes en ambos lados"

    pausa
}

# ==========================================================
# HISTORIAL
# ==========================================================

ver_historial() {

    local rama
    local -a formato

    titulo

    seleccionar_rama "Selecciona una rama:" || {
        pausa
        return
    }

    rama="$SELECTED_BRANCH"

    echo
    echo -e "${BLANCO}📜 HISTORIAL — $rama${RESET}"
    linea
    echo

    formato=(
        --graph
        --pretty=format:"%C(yellow)%h%Creset | %C(cyan)%ad%Creset | %C(green)%an%Creset | %s"
        --date="format:%d/%m/%Y %H:%M"
    )

    git log "$rama" "${formato[@]}" | paginar

    echo
    echo

    pausa
}

# ==========================================================
# VER COMMIT
# ==========================================================

ver_commit() {

    titulo

    local commit
    local respuesta

    read -r -p "🔑 ID del commit: " commit

    if [ -z "$commit" ]; then
        error "No has introducido ningún commit."
        pausa
        return
    fi

    echo

    if ! git cat-file -e "$commit^{commit}" 2>/dev/null; then
        error "El commit '$commit' no existe."
        pausa
        return
    fi

    echo
    if confirmar "¿Quieres ver los cambios completos?"; then

        echo
        echo -e "${BLANCO}🔬 CAMBIOS COMPLETOS${RESET}"
        linea
        echo

        git show --format=fuller "$commit"

    else

        echo
        git show --stat --oneline "$commit"

    fi

    pausa
}

# ==========================================================
# BLAME
# ==========================================================

ver_blame() {

    titulo

    local archivo

    echo -e "${BLANCO}👤 GIT BLAME${RESET}"
    linea
    echo

    read -r -p "📄 Archivo: " archivo

    if [ -z "$archivo" ]; then
        error "No has indicado ningún archivo."
        pausa
        return
    fi

    if [ ! -f "$archivo" ]; then
        error "El archivo no existe: $archivo"
        pausa
        return
    fi

    echo
    echo -e "${BLANCO}👤 QUIÉN MODIFICÓ CADA LÍNEA${RESET}"
    linea
    echo

    git blame "$archivo" | paginar

    pausa
}

# ==========================================================
# MERGE
# ==========================================================

hacer_merge() {

    titulo

    local destino
    local origen
    local commits
    local atras_destino
    local pendiente

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        error "Ya existe una operación Git pendiente: $pendiente."
        echo
        git status
        pausa
        return
    fi

    if hay_cambios; then
        error "Tienes cambios locales sin commit."
        echo
        git status --short
        echo
        aviso "Haz commit (opción 2) o guárdalos en stash (opción 5) antes del merge."
        pausa
        return
    fi

    echo -e "${BLANCO}🔀 MERGE SEGURO${RESET}"
    linea

    seleccionar_rama "RAMA DESTINO:" || {
        pausa
        return
    }

    destino="$SELECTED_BRANCH"

    echo

    seleccionar_rama "RAMA ORIGEN:" || {
        pausa
        return
    }

    origen="$SELECTED_BRANCH"

    if [ "$destino" = "$origen" ]; then
        error "No puedes fusionar una rama consigo misma."
        pausa
        return
    fi

    if [ "$destino" = "$RAMA_PROTEGIDA" ]; then
        echo
        echo -e "${ROJO}⚠️ El destino es '$RAMA_PROTEGIDA'.${RESET}"
        echo
        echo "En un entorno profesional esto se haría mediante Pull Request."
        echo
        if ! confirmar "¿Quieres hacer el merge igualmente?"; then
            aviso "Merge cancelado."
            pausa
            return
        fi
    fi

    echo
    info "Actualizando información del remoto..."

    if ! git fetch "$REMOTO"; then
        aviso "No se ha podido actualizar el remoto."
    fi

    commits="$(git rev-list --count "$destino..$origen" 2>/dev/null || echo 0)"

    echo
    echo -e "${BLANCO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}🔀 OPERACIÓN${RESET}"
    echo
    echo -e "   ${MAGENTA}$origen${RESET}  →  ${CIAN}$destino${RESET}"
    echo
    echo "   Commits a incorporar: $commits"
    echo -e "${BLANCO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if [ "$commits" -eq 0 ]; then
        info "No hay commits de $origen que incorporar en $destino."
        pausa
        return
    fi

    aviso "El merge se realizará solamente en LOCAL."
    echo "No se hará push automáticamente."
    echo

    if ! confirmar "¿Quieres continuar?"; then
        aviso "Merge cancelado."
        pausa
        return
    fi

    echo
    info "Cambiando a $destino..."

    if ! cambiar_rama "$destino"; then
        pausa
        return
    fi

    echo
    info "Comprobando si $destino tiene cambios nuevos en remoto..."

    atras_destino="$(contar_diferencia "$destino" "atras")"

    if [ "$atras_destino" -gt 0 ]; then

        aviso "$destino tiene $atras_destino commit(s) nuevos en remoto."
        echo
        echo "Actualizando mediante fast-forward..."

        if ! git pull --ff-only "$REMOTO" "$destino"; then
            error "No se pudo actualizar $destino."
            echo
            echo "No se ha realizado el merge."
            pausa
            return
        fi

    fi

    echo
    info "Realizando merge de $origen..."

    if git merge --no-edit "$origen"; then

        echo
        ok "MERGE COMPLETADO"
        echo
        echo -e "   ${MAGENTA}$origen${RESET} → ${CIAN}$destino${RESET}"
        echo
        aviso "El merge está solamente en LOCAL."
        echo
        echo "Para subirlo:"
        echo
        echo "   git push $REMOTO $destino"

    else

        echo
        error "SE HAN ENCONTRADO CONFLICTOS."
        echo

        git status --short

        echo
        echo -e "${BLANCO}Archivos en conflicto:${RESET}"
        echo

        git diff --name-only --diff-filter=U

        echo
        echo "Después de resolverlos:"
        echo
        echo "   git add <archivo>"
        echo "   git commit"
        echo "   git push $REMOTO $destino"
        echo
        echo "Para cancelar:"
        echo
        echo "   git merge --abort"
        echo
        echo "La opción 12 (Resolver operación pendiente) te guía por estos pasos."

    fi

    pausa
}

# ==========================================================
# RESOLVER OPERACIÓN PENDIENTE
# ==========================================================

# Punto único de salida para merges, rebases, cherry-picks y
# reverts a medias: explica el estado y ofrece cancelar.

resolver_operacion() {

    titulo
    mostrar_cabecera

    local pendiente
    local opcion

    pendiente="$(operacion_pendiente || true)"

    if [ -z "$pendiente" ]; then
        ok "No hay ninguna operación Git pendiente."
        pausa
        return
    fi

    echo -e "${ROJO}⚠️ OPERACIÓN PENDIENTE: $pendiente${RESET}"
    linea
    echo

    git status

    echo
    echo -e "${BLANCO}📋 ARCHIVOS EN CONFLICTO${RESET}"
    linea
    echo

    git diff --name-only --diff-filter=U

    echo
    echo -e "${BLANCO}Cómo continuar:${RESET}"
    echo

    case "$pendiente" in

        merge)
            echo "   1. Edita los archivos en conflicto."
            echo "   2. git add <archivo>"
            echo "   3. git commit"
            ;;

        rebase)
            echo "   1. Edita los archivos en conflicto."
            echo "   2. git add <archivo>"
            echo "   3. git rebase --continue"
            ;;

        cherry-pick)
            echo "   1. Edita los archivos en conflicto."
            echo "   2. git add <archivo>"
            echo "   3. git cherry-pick --continue"
            ;;

        revert)
            echo "   1. Edita los archivos en conflicto."
            echo "   2. git add <archivo>"
            echo "   3. git revert --continue"
            ;;

    esac

    echo
    echo -e "${BLANCO}O cancela y vuelve al estado anterior:${RESET}"
    echo
    echo "   git $pendiente --abort"
    echo
    echo -e "${BLANCO}¿Qué quieres hacer?${RESET}"
    echo
    echo "  1) ✅ Ya lo he resuelto yo (comprobar estado)"
    echo "  2) 🛑 Cancelar la operación (abort)"
    echo "  0) ↩️  Volver sin hacer nada"
    echo

    read -r -p "Opción: " opcion

    case "$opcion" in

        1)
            echo
            pendiente="$(operacion_pendiente || true)"

            if [ -z "$pendiente" ]; then
                ok "Operación resuelta correctamente."
            else
                error "Sigue pendiente la operación: $pendiente."
            fi
            ;;

        2)
            echo
            if ! confirmar "¿Seguro que quieres descartar la operación '$pendiente'?"; then
                aviso "Cancelado por el usuario."
                pausa
                return
            fi

            echo
            info "Cancelando operación..."

            if git "$pendiente" --abort; then
                echo
                ok "Operación '$pendiente' cancelada. Repositorio en su estado anterior."
            else
                echo
                error "No se pudo cancelar automáticamente."
                echo "Ejecuta manualmente: git $pendiente --abort"
            fi
            ;;

        0)
            return
            ;;

        *)
            error "Opción no válida."
            ;;

    esac

    pausa
}

# ==========================================================
# INFORMACIÓN DEL REMOTO
# ==========================================================

ver_remoto() {

    titulo

    echo -e "${BLANCO}🌐 INFORMACIÓN DEL REMOTO${RESET}"
    linea
    echo

    local remoto_url

    remoto_url="$(git remote get-url "$REMOTO" 2>/dev/null || true)"

    if [ -z "$remoto_url" ]; then
        error "No existe el remoto '$REMOTO'."
        pausa
        return
    fi

    echo -e "${BLANCO}📡 REMOTO${RESET}"
    echo
    echo "   Nombre: $REMOTO"
    echo "   URL:    $remoto_url"

    echo
    info "Comprobando conexión..."

    if git ls-remote "$REMOTO" HEAD >/dev/null 2>&1; then
        ok "Conexión con el remoto correcta."
    else
        error "No se pudo conectar con el remoto."
    fi

    echo
    echo -e "${BLANCO}🌿 RAMAS REMOTAS${RESET}"
    linea
    echo

    git branch -r

    pausa
}

# ==========================================================
# ESTADÍSTICAS
# ==========================================================

ver_estadisticas() {

    titulo

    echo -e "${BLANCO}📊 ESTADÍSTICAS DEL PROYECTO${RESET}"
    linea
    echo

    echo "📝 Commits totales:  $(git rev-list --all --count 2>/dev/null || echo 0)"
    echo "👥 Autores:          $(git log --all --format='%an' 2>/dev/null | sort -u | wc -l | tr -d ' ')"
    echo "📁 Archivos:         $(git ls-files | wc -l | tr -d ' ')"
    echo "🌿 Ramas locales:    $(git branch --format='%(refname:short)' | wc -l | tr -d ' ')"

    echo
    echo -e "${BLANCO}👥 AUTORES${RESET}"
    linea
    echo

    git shortlog -sne --all

    echo
    echo -e "${BLANCO}📌 ÚLTIMO COMMIT${RESET}"
    linea

    mostrar_ultimo_commit "   "

    echo
    pausa
}

# ==========================================================
# CREAR .gitignore
# ==========================================================

crear_gitignore() {

    if [ -f ".gitignore" ]; then
        aviso "Ya existe un .gitignore en el proyecto."
        return 1
    fi

    cat > .gitignore << 'EOF'
# --- Entorno y credenciales (NUNCA subir al repo) ---
.env
.env.*
!.env.example

# --- Dependencias ---
node_modules/
vendor/

# --- IDEs y editores ---
.idea/
.vscode/
*.swp
*.swo

# --- Sistema ---
.DS_Store
Thumbs.db
desktop.ini

# --- Build y caché ---
dist/
build/
.cache/

# --- Logs y temporales ---
*.log
*.bak
*.tmp
EOF

    return 0
}

# ==========================================================
# COMPROBAR ARCHIVOS SOSPECHOSOS
# ==========================================================

comprobar_archivos() {

    titulo

    echo -e "${BLANCO}🧹 COMPROBACIÓN DE ARCHIVOS${RESET}"
    linea
    echo

    local encontrados=0
    local archivo
    local carpeta

    # ------------------------------------------------------
    # Archivos de entorno
    # ------------------------------------------------------

    for archivo in ".env" ".env.local" ".env.production"
    do
        if [ -f "$archivo" ]; then
            echo -e "${AMARILLO}⚠️ Encontrado: $archivo${RESET}"
            encontrados=1
        fi
    done

    # ------------------------------------------------------
    # Archivos temporales y de registro
    # ------------------------------------------------------

    if find . \
        -type f \
        \( -name "*.log" -o -name "*.bak" -o -name ".DS_Store" \) \
        -not -path "./.git/*" \
        -print -quit 2>/dev/null | grep -q .
    then
        echo -e "${AMARILLO}⚠️ Se han encontrado archivos .log, .bak o .DS_Store${RESET}"
        encontrados=1
    fi

    # ------------------------------------------------------
    # Carpetas habituales que no deberían subirse
    # ------------------------------------------------------

    for carpeta in "node_modules" "vendor" "dist" ".vscode" ".idea"
    do
        if [ -d "$carpeta" ]; then
            aviso "Existe la carpeta $carpeta/"
            encontrados=1
        fi
    done

    # ------------------------------------------------------
    # Archivos que Git ya está siguiendo y no debería
    # ------------------------------------------------------

    if git ls-files --error-unmatch .env >/dev/null 2>&1; then
        error ".env ESTÁ SEGUIDO POR GIT: credenciales posiblemente publicadas."
        encontrados=1
    fi

    echo

    if [ "$encontrados" -eq 0 ]; then
        ok "No se han encontrado archivos habituales para ignorar."
    else
        aviso "Comprueba que estos archivos estén correctamente gestionados por .gitignore."
    fi

    echo
    echo -e "${BLANCO}📄 .gitignore${RESET}"
    linea
    echo

    if [ -f ".gitignore" ]; then

        cat .gitignore

    else

        aviso "No existe .gitignore."

        echo
        if confirmar "¿Quieres crear uno con la configuración recomendada?"; then
            echo
            if crear_gitignore; then
                ok ".gitignore creado."
                echo
                aviso "Recuerda hacer commit para que afecte a todo el equipo."
                cat .gitignore
            else
                error "No se pudo crear el .gitignore."
            fi
        fi

    fi

    pausa
}

# ==========================================================
# DASHBOARD
# ==========================================================

dashboard() {

    limpiar_pantalla

    local actual
    local pendiente
    local rama
    local adelante
    local atras
    local total_commits
    local autores
    local avisos
    local resumen
    local preparados
    local sin_preparar
    local sin_seguimiento

    actual="$(rama_actual)"

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║                 🌿  GESTOR GIT                        ║${RESET}"
    echo -e "${CIAN}║              Panel de control DWS                     ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo

    # ------------------------------------------------------
    # PROYECTO
    # ------------------------------------------------------

    echo -e "${BLANCO}📂 PROYECTO${RESET}"
    linea

    echo "   DWS / DWES2"
    echo -e "   ${GRIS}$SCRIPT_DIR${RESET}"

    # ------------------------------------------------------
    # SISTEMA
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}💻 SISTEMA${RESET}"
    linea

    if [ -n "${OSTYPE:-}" ]; then
        echo "   $OSTYPE"
    else
        echo "   Bash / Sistema desconocido"
    fi

    if [ -n "$(git config user.name 2>/dev/null)" ]; then
        echo "   👤 $(git config user.name) <$(git config user.email 2>/dev/null)>"
    else
        echo -e "   ${ROJO}👤 Git sin user.name/email configurados${RESET}"
    fi

    # ------------------------------------------------------
    # RAMA ACTUAL
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌿 RAMA ACTUAL${RESET}"
    linea

    if [ -n "$actual" ]; then
        echo -e "   ${MAGENTA}$actual${RESET}"
    else
        echo -e "   ${ROJO}⚠️ HEAD separado${RESET}"
    fi

    # ------------------------------------------------------
    # OPERACIÓN PENDIENTE
    # ------------------------------------------------------

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then

        echo
        echo -e "${ROJO}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${ROJO}║        ⚠️ OPERACIÓN PENDIENTE: $pendiente${RESET}"
        echo -e "${ROJO}╚══════════════════════════════════════════════════════╝${RESET}"

        echo
        echo "   Necesita atención."
        echo "   🔧 Opción 12 → Resolver operación pendiente"

    fi

    # ------------------------------------------------------
    # CONEXIÓN + ACTUALIZAR REMOTO
    # (una sola llamada de red)
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌐 CONEXIÓN${RESET}"
    linea
    echo

    info "Actualizando estado remoto..."

    if git fetch "$REMOTO" >/dev/null 2>&1; then
        echo -e "   ${VERDE}🟢 Origin conectado${RESET}"
    else
        echo -e "   ${ROJO}🔴 No se puede conectar con origin${RESET}"
        echo "   El estado remoto puede estar desactualizado."
    fi

    # ------------------------------------------------------
    # ESTADO DE LAS RAMAS
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌿 ESTADO DE LAS RAMAS${RESET}"
    linea
    echo

    mostrar_tabla_ramas

    # ------------------------------------------------------
    # ÚLTIMO COMMIT
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}📝 ÚLTIMO COMMIT — RAMA ACTUAL${RESET}"
    linea

    mostrar_ultimo_commit "   "

    # ------------------------------------------------------
    # RESUMEN
    # ------------------------------------------------------

    total_commits="$(git rev-list --all --count 2>/dev/null || echo 0)"
    autores="$(git log --all --format='%an' 2>/dev/null | sort -u | wc -l | tr -d ' ')"

    echo
    echo -e "${BLANCO}📊 RESUMEN${RESET}"
    linea

    echo
    echo "   📝 Commits: $total_commits"
    echo "   👥 Autores: $autores"
    echo "   🌿 Ramas del proyecto: ${#RAMAS[@]}"

    # ------------------------------------------------------
    # AVISOS
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}⚠️ AVISOS${RESET}"
    linea

    avisos=0

    for rama in "${RAMAS[@]}"
    do

        if remoto_existe "$rama"; then

            adelante="$(contar_diferencia "$rama" "adelante")"
            atras="$(contar_diferencia "$rama" "atras")"

            if [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then
                echo -e "${ROJO}🔴 $rama: DIVERGIDA (+$adelante / -$atras) → opción 7${RESET}"
                avisos=1
            elif [ "$adelante" -gt 0 ]; then
                echo -e "${AZUL}🔵 $rama: $adelante commit(s) pendiente(s) de PUSH.${RESET}"
                avisos=1
            elif [ "$atras" -gt 0 ]; then
                echo -e "${ROJO}🔴 $rama: $atras commit(s) pendiente(s) de PULL.${RESET}"
                avisos=1
            fi

        fi

    done

    if [ -n "$pendiente" ]; then
        echo -e "${ROJO}🔴 Hay una operación pendiente: $pendiente.${RESET}"
        avisos=1
    fi

    if hay_cambios; then

        resumen="$(resumen_cambios)"
        preparados="${resumen#preparados=}"
        preparados="${preparados%% *}"
        sin_preparar="${resumen#*sin_preparar=}"
        sin_preparar="${sin_preparar%% *}"
        sin_seguimiento="${resumen#*sin_seguimiento=}"

        echo -e "${AMARILLO}🟡 Cambios locales: $preparados preparados, $sin_preparar modificados, $sin_seguimiento sin seguimiento.${RESET}"
        avisos=1
    fi

    if [ "$avisos" -eq 0 ]; then
        echo -e "${VERDE}🟢 No hay avisos pendientes.${RESET}"
    fi

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║              Selecciona una opción                    ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
}

# ==========================================================
# MENU PRINCIPAL
# ==========================================================

menu_principal() {

    local opcion

    while true
    do

        dashboard

        echo -e "${BLANCO}TRABAJO${RESET}"
        linea
        echo "  1. 📥 Pull"
        echo "  2. 📤 Commit + Push"
        echo "  3. 🔎 Ver estado"
        echo "  4. 👁️ Ver cambios (diff)"

        echo
        echo -e "${BLANCO}CAMBIOS${RESET}"
        linea
        echo "  5. 📦 Stash (guardar/recuperar)"
        echo "  6. ↩️ Deshacer último commit"
        echo "  7. 🔁 Sincronizar rama divergida"

        echo
        echo -e "${BLANCO}HISTORIAL${RESET}"
        linea
        echo "  8. 📜 Ver historial"
        echo "  9. 🔍 Ver cambios de commit"
        echo " 10. 👤 Ver quién modificó"

        echo
        echo -e "${BLANCO}RAMAS${RESET}"
        linea
        echo " 11. 🔀 Merge"
        echo " 12. 🔧 Resolver operación pendiente"

        echo
        echo -e "${BLANCO}INFORMACIÓN${RESET}"
        linea
        echo " 13. 🌐 Información del remoto"
        echo " 14. 📊 Estadísticas"
        echo " 15. 🧹 Comprobar archivos / .gitignore"

        echo
        echo "  0. 🚪 Salir"

        echo
        read -r -p "Selecciona una opción: " opcion

        case "$opcion" in

            1)  hacer_pull ;;
            2)  hacer_push ;;
            3)  ver_estado ;;
            4)  ver_cambios ;;
            5)  hacer_stash ;;
            6)  deshacer_commit ;;
            7)  sincronizar_rama ;;
            8)  ver_historial ;;
            9)  ver_commit ;;
            10) ver_blame ;;
            11) hacer_merge ;;
            12) resolver_operacion ;;
            13) ver_remoto ;;
            14) ver_estadisticas ;;
            15) comprobar_archivos ;;

            0)
                limpiar_pantalla
                echo
                echo -e "${CIAN}👋 Hasta luego.${RESET}"
                echo
                exit 0
                ;;

            *)
                error "Opción no válida."
                sleep 1
                ;;

        esac

    done
}

# ==========================================================
# INICIO
# ==========================================================

if ! comprobar_entorno; then
    echo
    read -r -p "Pulsa ENTER para salir..." _
    exit 1
fi

menu_principal
