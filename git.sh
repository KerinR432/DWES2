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
# ==========================================================

set -u
set -o pipefail

# ==========================================================
# CONFIGURACIÓN
# ==========================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

RAMAS=("TEORIA" "codigo" "main")
RAMA_PRINCIPAL="main"
REMOTO="origin"

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

ok() {
    echo -e "${VERDE}🟢 $1${RESET}"
}

aviso() {
    echo -e "${AMARILLO}🟡 $1${RESET}"
}

error() {
    echo -e "${ROJO}🔴 $1${RESET}"
}

info() {
    echo -e "${AZUL}🔵 $1${RESET}"
}

# ==========================================================
# COMPROBACIONES INICIALES
# ==========================================================

comprobar_entorno() {

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

    return 0
}

# ==========================================================
# INFORMACIÓN GIT
# ==========================================================

rama_actual() {
    git branch --show-current 2>/dev/null || true
}

hay_merge_pendiente() {
    [ -f "$(git rev-parse --git-path MERGE_HEAD 2>/dev/null)" ]
}

hay_rebase_pendiente() {

    local git_dir

    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 1

    [ -d "$git_dir/rebase-merge" ] ||
    [ -d "$git_dir/rebase-apply" ]
}

hay_cherry_pick_pendiente() {

    local git_dir

    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 1

    [ -f "$git_dir/CHERRY_PICK_HEAD" ]
}

hay_revert_pendiente() {

    local git_dir

    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 1

    [ -f "$git_dir/REVERT_HEAD" ]
}

hay_operacion_pendiente() {

    hay_merge_pendiente ||
    hay_rebase_pendiente ||
    hay_cherry_pick_pendiente ||
    hay_revert_pendiente
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

contar_adelante() {

    local rama="$1"

    if ! rama_existe "$rama"; then
        echo 0
        return
    fi

    if ! remoto_existe "$rama"; then
        echo 0
        return
    fi

    git rev-list --count "$REMOTO/$rama..$rama" 2>/dev/null || echo 0
}

contar_atras() {

    local rama="$1"

    if ! rama_existe "$rama"; then
        echo 0
        return
    fi

    if ! remoto_existe "$rama"; then
        echo 0
        return
    fi

    git rev-list --count "$rama..$REMOTO/$rama" 2>/dev/null || echo 0
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
        aviso "Haz commit o guarda los cambios antes de cambiar de rama."
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

    rama="$(rama_actual)"

    echo -e "${BLANCO}📂 Proyecto:${RESET} DWS / DWES2"
    echo -e "${GRIS}$SCRIPT_DIR${RESET}"

    echo

    if [ -n "$rama" ]; then
        echo -e "${BLANCO}🌿 Rama actual:${RESET} ${MAGENTA}$rama${RESET}"
    else
        echo -e "${AMARILLO}⚠️ HEAD separado${RESET}"
    fi

    if hay_merge_pendiente; then
        echo
        error "Hay un MERGE pendiente."
    fi

    if hay_rebase_pendiente; then
        echo
        error "Hay un REBASE pendiente."
    fi

    echo
}

# ==========================================================
# SELECCIONAR RAMA
# ==========================================================

seleccionar_rama() {

    echo
    echo -e "${BLANCO}Selecciona una rama:${RESET}"
    echo
    echo "  1) TEORIA"
    echo "  2) codigo"
    echo "  3) main"
    echo

    local opcion
    local rama

    read -r -p "Opción: " opcion

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
            error "Opción no válida."
            return 1
            ;;

    esac

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

    titulo
    mostrar_cabecera

    if hay_operacion_pendiente; then
        error "Hay una operación Git pendiente."
        echo
        git status
        echo
        aviso "Finaliza o cancela la operación antes de hacer pull."
        pausa
        return
    fi

    if hay_cambios; then
        error "Tienes cambios locales sin commit."
        echo
        git status --short
        echo
        aviso "Haz commit o guarda los cambios antes de hacer pull."
        pausa
        return
    fi

    seleccionar_rama || {
        pausa
        return
    }

    local rama="$SELECTED_BRANCH"

    echo
    info "Cambiando a $rama..."

    if ! cambiar_rama "$rama"; then
        pausa
        return
    fi

    echo
    info "Actualizando información del remoto..."

    if ! git fetch "$REMOTO"; then
        error "No se ha podido actualizar la información del remoto."
        pausa
        return
    fi

    echo
    info "Haciendo pull de $REMOTO/$rama..."

    if ! git pull "$REMOTO" "$rama"; then
        echo
        error "El pull no se ha podido completar."
        echo
        echo "Si Git muestra conflictos, revísalos antes de continuar."
        pausa
        return
    fi

    echo
    ok "Rama $rama actualizada correctamente."

    pausa
}

# ==========================================================
# COMMIT + PUSH
# ==========================================================

hacer_push() {

    titulo
    mostrar_cabecera

    if hay_operacion_pendiente; then
        error "Tienes una operación Git pendiente."
        echo
        git status
        echo
        aviso "Finaliza o cancela la operación antes de hacer commit."
        pausa
        return
    fi

    seleccionar_rama || {
        pausa
        return
    }

    local rama="$SELECTED_BRANCH"

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

    echo
    aviso "Se utilizará 'git add -A'."
    echo "Esto incluirá archivos nuevos, modificados y eliminados."
    echo

    local confirmar

    read -r -p "¿Quieres continuar? (s/n): " confirmar

    if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
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

    echo
    echo -e "${BLANCO}📦 CAMBIOS PREPARADOS${RESET}"
    linea

    git status --short

    echo
    local mensaje

    read -r -p "📝 Mensaje del commit: " mensaje

    if [ -z "$mensaje" ]; then
        error "El mensaje no puede estar vacío."
        git restore --staged . 2>/dev/null || true
        pausa
        return
    fi

    echo
    info "Creando commit..."

    if ! git commit -m "$mensaje"; then
        error "No se pudo crear el commit."
        pausa
        return
    fi

    echo
    ok "Commit creado correctamente."

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
# ESTADO DE LAS RAMAS
# ==========================================================

obtener_estado_rama() {

    local rama="$1"
    local adelante
    local atras

    if ! rama_existe "$rama"; then
        echo "NO_EXISTE"
        return
    fi

    if ! remoto_existe "$rama"; then
        echo "SIN_REMOTO"
        return
    fi

    adelante="$(contar_adelante "$rama")"
    atras="$(contar_atras "$rama")"

    if [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then
        echo "DIVERGIDA"

    elif [ "$adelante" -gt 0 ]; then
        echo "PUSH"

    elif [ "$atras" -gt 0 ]; then
        echo "PULL"

    else
        echo "OK"
    fi
}

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
    printf " %-12s %-23s %-9s %-9s\n" \
        "RAMA" "ESTADO" "LOCAL +" "REMOTO -"

    linea

    local rama
    local adelante
    local atras
    local cambios
    local estado
    local actual

    actual="$(rama_actual)"

    for rama in "${RAMAS[@]}"
    do

        if ! rama_existe "$rama"; then

            printf " %-12s ${ROJO}%-23s${RESET}\n" \
                "$rama" "❌ No existe"

            continue
        fi

        if ! remoto_existe "$rama"; then

            printf " %-12s ${AMARILLO}%-23s${RESET}\n" \
                "$rama" "⚠️ Sin remoto"

            continue
        fi

        adelante="$(contar_adelante "$rama")"
        atras="$(contar_atras "$rama")"

        cambios=""

        if [ "$actual" = "$rama" ]; then
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

    titulo

    seleccionar_rama || {
        pausa
        return
    }

    local rama="$SELECTED_BRANCH"

    echo
    echo -e "${BLANCO}📜 HISTORIAL — $rama${RESET}"
    linea
    echo

    git log "$rama" \
        --graph \
        --pretty=format:"%C(yellow)%h%Creset | %C(cyan)%ad%Creset | %C(green)%an%Creset | %s" \
        --date="format:%d/%m/%Y %H:%M"

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
    read -r -p "¿Quieres ver los cambios completos? (s/n): " respuesta

    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then

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

    echo -e "${BLANCO}👤 GIT BLAME${RESET}"
    linea
    echo

    local archivo

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

    if command -v less >/dev/null 2>&1; then
        git blame "$archivo" | less -R
    else
        git blame "$archivo"
    fi

    pausa
}

# ==========================================================
# SELECCIONAR RAMA PARA MERGE
# ==========================================================

seleccionar_rama_merge() {

    local tipo="$1"
    local opcion
    local seleccion

    echo

    if [ "$tipo" = "destino" ]; then
        echo -e "${BLANCO}RAMA DESTINO:${RESET}"
    else
        echo -e "${BLANCO}RAMA ORIGEN:${RESET}"
    fi

    echo
    echo "  1) TEORIA"
    echo "  2) codigo"
    echo "  3) main"
    echo

    read -r -p "Opción: " opcion

    case "$opcion" in

        1)
            seleccion="TEORIA"
            ;;

        2)
            seleccion="codigo"
            ;;

        3)
            seleccion="main"
            ;;

        *)
            error "Opción no válida."
            return 1
            ;;

    esac

    if ! rama_existe "$seleccion"; then
        error "La rama '$seleccion' no existe."
        return 1
    fi

    if [ "$tipo" = "destino" ]; then
        MERGE_DESTINO="$seleccion"
    else
        MERGE_ORIGEN="$seleccion"
    fi

    return 0
}

# ==========================================================
# MERGE
# ==========================================================

hacer_merge() {

    titulo

    local destino
    local origen
    local commits
    local confirmar
    local atras_destino

    if hay_operacion_pendiente; then
        error "Ya existe una operación Git pendiente."
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
        aviso "Haz commit o guarda tus cambios antes del merge."
        pausa
        return
    fi

    echo -e "${BLANCO}🔀 MERGE SEGURO${RESET}"
    linea

    seleccionar_rama_merge "destino" || {
        pausa
        return
    }

    destino="$MERGE_DESTINO"

    echo

    seleccionar_rama_merge "origen" || {
        pausa
        return
    }

    origen="$MERGE_ORIGEN"

    if [ "$destino" = "$origen" ]; then
        error "No puedes fusionar una rama consigo misma."
        pausa
        return
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

    read -r -p "¿Quieres continuar? (s/n): " confirmar

    if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
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

    atras_destino="$(contar_atras "$destino")"

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

    fi

    pausa
}

# ==========================================================
# CONTINUAR MERGE
# ==========================================================

continuar_merge() {

    titulo

    if ! hay_merge_pendiente; then
        ok "No hay ningún merge pendiente."
        pausa
        return
    fi

    echo -e "${BLANCO}🔧 MERGE PENDIENTE${RESET}"
    linea
    echo

    git status

    echo
    echo -e "${BLANCO}📋 ARCHIVOS EN CONFLICTO${RESET}"
    linea
    echo

    git diff --name-only --diff-filter=U

    echo
    echo "Para resolver los conflictos:"
    echo
    echo "   1. Edita los archivos afectados."
    echo "   2. Guarda los cambios."
    echo "   3. Ejecuta: git add <archivo>"
    echo "   4. Ejecuta: git commit"
    echo
    echo "Después podrás hacer push desde la opción 2."

    pausa
}

# ==========================================================
# CANCELAR MERGE
# ==========================================================

cancelar_merge() {

    titulo

    if ! hay_merge_pendiente; then
        ok "No hay ningún merge pendiente."
        pausa
        return
    fi

    echo -e "${ROJO}⚠️ MERGE PENDIENTE${RESET}"
    linea
    echo

    git status

    echo
    aviso "Se cancelará el merge actual."
    echo
    echo "Los cambios realizados por el merge serán descartados."
    echo

    local confirmar

    read -r -p "¿Quieres cancelar el merge? (s/n): " confirmar

    if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
        aviso "Operación cancelada."
        pausa
        return
    fi

    if git merge --abort; then
        echo
        ok "Merge cancelado correctamente."
    else
        echo
        error "No se pudo cancelar el merge automáticamente."
    fi

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

    local total_commits
    local autores
    local archivos
    local ramas_locales

    total_commits="$(git rev-list --all --count 2>/dev/null || echo 0)"
    autores="$(git log --all --format='%an' 2>/dev/null | sort -u | wc -l | tr -d ' ')"
    archivos="$(git ls-files | wc -l | tr -d ' ')"
    ramas_locales="$(git branch --format='%(refname:short)' | wc -l | tr -d ' ')"

    echo "📝 Commits totales:  $total_commits"
    echo "👥 Autores:          $autores"
    echo "📁 Archivos:         $archivos"
    echo "🌿 Ramas locales:    $ramas_locales"

    echo
    echo -e "${BLANCO}👥 AUTORES${RESET}"
    linea
    echo

    git shortlog -sne --all

    echo
    echo -e "${BLANCO}📌 ÚLTIMO COMMIT${RESET}"
    linea
    echo

    git log -1 \
        --pretty=format:"👤 Autor:   %an%n📅 Fecha:   %ad%n📝 Mensaje: %s%n🔑 Commit:  %h" \
        --date="format:%d/%m/%Y %H:%M"

    echo
    pausa
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
    # Archivos LOG
    # ------------------------------------------------------

    if find . \
        -type f \
        -name "*.log" \
        -not -path "./.git/*" \
        -print -quit 2>/dev/null | grep -q .
    then
        echo -e "${AMARILLO}⚠️ Se han encontrado archivos .log${RESET}"
        encontrados=1
    fi

    # ------------------------------------------------------
    # Carpetas habituales
    # ------------------------------------------------------

    if [ -d "node_modules" ]; then
        aviso "Existe la carpeta node_modules/"
        encontrados=1
    fi

    if [ -d ".vscode" ]; then
        aviso "Existe la carpeta .vscode/"
        encontrados=1
    fi

    if [ -d ".idea" ]; then
        aviso "Existe la carpeta .idea/"
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
        echo "Se recomienda crear uno para evitar subir archivos innecesarios."

    fi

    pausa
}

# ==========================================================
# DASHBOARD
# ==========================================================

dashboard() {

    limpiar_pantalla

    local actual
    local rama
    local adelante
    local atras
    local cambios
    local estado_texto
    local autor
    local fecha
    local mensaje
    local hash
    local total_commits
    local autores
    local avisos

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

    if hay_merge_pendiente; then

        echo
        echo -e "${ROJO}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${ROJO}║                 ⚠️ MERGE PENDIENTE                  ║${RESET}"
        echo -e "${ROJO}╚══════════════════════════════════════════════════════╝${RESET}"

        echo
        echo "   Tienes un merge que necesita atención."
        echo "   🔧 Opción 8 → Continuar merge"
        echo "   🛑 Opción 9 → Cancelar merge"
    fi

    # ------------------------------------------------------
    # CONEXIÓN
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌐 CONEXIÓN${RESET}"
    linea

    if git ls-remote "$REMOTO" HEAD >/dev/null 2>&1; then
        echo -e "   ${VERDE}🟢 Origin conectado${RESET}"
    else
        echo -e "   ${ROJO}🔴 No se puede conectar con origin${RESET}"
    fi

    # ------------------------------------------------------
    # ACTUALIZAR REMOTO
    # ------------------------------------------------------

    echo
    info "Actualizando estado remoto..."

    git fetch "$REMOTO" >/dev/null 2>&1 || true

    # ------------------------------------------------------
    # ESTADO DE LAS RAMAS
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌿 ESTADO DE LAS RAMAS${RESET}"
    linea
    echo

    printf " %-12s %-23s %-9s %-9s\n" \
        "RAMA" "ESTADO" "LOCAL +" "REMOTO -"

    echo

    for rama in "${RAMAS[@]}"
    do

        if ! rama_existe "$rama"; then

            printf " %-12s ${ROJO}%-23s${RESET}\n" \
                "$rama" "❌ No existe"

            continue
        fi

        if ! remoto_existe "$rama"; then

            printf " %-12s ${AMARILLO}%-23s${RESET}\n" \
                "$rama" "⚠️ Sin remoto"

            continue
        fi

        adelante="$(contar_adelante "$rama")"
        atras="$(contar_atras "$rama")"

        cambios=""

        if [ "$rama" = "$actual" ]; then
            cambios="$(git status --porcelain 2>/dev/null)"
        fi

        if [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then

            estado_texto="${ROJO}🔴 Divergida${RESET}"

        elif [ -n "$cambios" ]; then

            estado_texto="${AMARILLO}🟡 Cambios locales${RESET}"

        elif [ "$adelante" -gt 0 ]; then

            estado_texto="${AZUL}🔵 Push pendiente${RESET}"

        elif [ "$atras" -gt 0 ]; then

            estado_texto="${ROJO}🔴 Pull pendiente${RESET}"

        else

            estado_texto="${VERDE}🟢 Actualizada${RESET}"

        fi

        printf " %-12s %-23b +%-8s -%-8s\n" \
            "$rama" \
            "$estado_texto" \
            "$adelante" \
            "$atras"

    done

    # ------------------------------------------------------
    # ÚLTIMO COMMIT
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}📝 ÚLTIMO COMMIT — RAMA ACTUAL${RESET}"
    linea

    if [ -n "$actual" ] && git log -1 >/dev/null 2>&1; then

        autor="$(git log -1 --format='%an')"
        fecha="$(git log -1 --format='%ad' --date='format:%d/%m/%Y %H:%M')"
        mensaje="$(git log -1 --format='%s')"
        hash="$(git log -1 --format='%h')"

        echo
        echo "   👤 Autor:   $autor"
        echo "   📅 Fecha:   $fecha"
        echo "   📝 Mensaje: $mensaje"
        echo "   🔑 Commit:  $hash"

    else

        echo
        aviso "No hay información de commit disponible."

    fi

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
    echo "   🌿 Ramas configuradas: ${#RAMAS[@]}"

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

            adelante="$(contar_adelante "$rama")"
            atras="$(contar_atras "$rama")"

            if [ "$adelante" -gt 0 ]; then
                echo -e "${AZUL}🔵 $rama: $adelante commit(s) pendiente(s) de PUSH.${RESET}"
                avisos=1
            fi

            if [ "$atras" -gt 0 ]; then
                echo -e "${ROJO}🔴 $rama: $atras commit(s) pendiente(s) de PULL.${RESET}"
                avisos=1
            fi

        fi

    done

    if hay_cambios; then
        echo -e "${AMARILLO}🟡 Hay cambios locales sin commit.${RESET}"
        avisos=1
    fi

    if hay_merge_pendiente; then
        echo -e "${ROJO}🔴 Hay un merge pendiente.${RESET}"
        avisos=1
    fi

    if hay_rebase_pendiente; then
        echo -e "${ROJO}🔴 Hay un rebase pendiente.${RESET}"
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

        echo
        echo -e "${BLANCO}HISTORIAL${RESET}"
        linea
        echo "  4. 📜 Ver historial"
        echo "  5. 🔍 Ver cambios de commit"
        echo "  6. 👤 Ver quién modificó"

        echo
        echo -e "${BLANCO}RAMAS${RESET}"
        linea
        echo "  7. 🔀 Merge"
        echo "  8. 🔧 Continuar merge"
        echo "  9. 🛑 Cancelar merge"

        echo
        echo -e "${BLANCO}INFORMACIÓN${RESET}"
        linea
        echo " 10. 🌐 Información del remoto"
        echo " 11. 📊 Estadísticas"
        echo " 12. 🧹 Comprobar archivos"

        echo
        echo "  0. 🚪 Salir"

        echo
        read -r -p "Selecciona una opción: " opcion

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
                continuar_merge
                ;;

            9)
                cancelar_merge
                ;;

            10)
                ver_remoto
                ;;

            11)
                ver_estadisticas
                ;;

            12)
                comprobar_archivos
                ;;

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
