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
    local pendiente

    rama="$(rama_actual)"

    echo -e "${BLANCO}📂 Proyecto:${RESET} DWS / DWES2"
    echo -e "${GRIS}$SCRIPT_DIR${RESET}"

    echo

    if [ -n "$rama" ]; then
        echo -e "${BLANCO}🌿 Rama actual:${RESET} ${MAGENTA}$rama${RESET}"
    else
        echo -e "${AMARILLO}⚠️ HEAD separado${RESET}"
    fi

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        echo
        error "Hay una operación pendiente: $pendiente."
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
        echo "    Sincroniza primero con git pull $REMOTO $rama"
        echo "    o revisa la opción 7 (Merge)."
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
# COMMIT + PUSH
# ==========================================================

hacer_push() {

    local rama
    local pendiente
    local confirmar
    local mensaje
    local atras

    titulo
    mostrar_cabecera

    pendiente="$(operacion_pendiente || true)"

    if [ -n "$pendiente" ]; then
        error "Tienes una operación Git pendiente: $pendiente."
        echo
        git status
        echo
        aviso "Finaliza o cancela la operación antes de hacer commit."
        pausa
        return
    fi

    seleccionar_rama "Selecciona una rama:" || {
        pausa
        return
    }

    rama="$SELECTED_BRANCH"

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
        echo "Sincroniza primero la rama:"
        echo
        echo "  git pull $REMOTO $rama"
        echo
        echo "Después repite esta opción (no repetirá el commit)."
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
# TABLA DE ESTADO DE LAS RAMAS
# ==========================================================

# Tabla de todas las ramas del proyecto.
# Antes estaba duplicada en "Ver estado" y en el dashboard.

mostrar_tabla_ramas() {

    local actual
    local rama
    local adelante
    local atras
    local cambios
    local estado

    actual="$(rama_actual)"

    printf " %-12s %-23b %-9s %-9s\n" \
        "RAMA" "ESTADO" "LOCAL +" "REMOTO -"

    linea

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

# Muestra el último commit de la rama actual.
# Antes estaba duplicado en estadísticas y dashboard.

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

    if command -v less >/dev/null 2>&1; then
        git log "$rama" "${formato[@]}" | less -R
    else
        git log "$rama" "${formato[@]}"
    fi

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
# MERGE
# ==========================================================

hacer_merge() {

    titulo

    local destino
    local origen
    local commits
    local confirmar
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
        aviso "Haz commit o guarda tus cambios antes del merge."
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

    fi

    pausa
}

# ==========================================================
# CONTINUAR MERGE
# ==========================================================

continuar_merge() {

    titulo

    if [ "$(operacion_pendiente || true)" != "merge" ]; then
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

    if [ "$(operacion_pendiente || true)" != "merge" ]; then
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
    local pendiente
    local rama
    local adelante
    local atras
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

    # ------------------------------------------------------
    # OPERACIÓN PENDIENTE
    # ------------------------------------------------------

    pendiente="$(operacion_pendiente || true)"

    if [ "$pendiente" = "merge" ]; then

        echo
        echo -e "${ROJO}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${ROJO}║                 ⚠️ MERGE PENDIENTE                  ║${RESET}"
        echo -e "${ROJO}╚══════════════════════════════════════════════════════╝${RESET}"

        echo
        echo "   Tienes un merge que necesita atención."
        echo "   🔧 Opción 8 → Continuar merge"
        echo "   🛑 Opción 9 → Cancelar merge"

    elif [ -n "$pendiente" ]; then
        echo
        error "Hay una operación pendiente: $pendiente."
    fi

    # ------------------------------------------------------
    # CONEXIÓN + ACTUALIZAR REMOTO
    # (una sola llamada de red en lugar de dos)
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

    if [ -n "$pendiente" ]; then
        echo -e "${ROJO}🔴 Hay una operación pendiente: $pendiente.${RESET}"
        avisos=1
    fi

    if hay_cambios; then
        echo -e "${AMARILLO}🟡 Hay cambios locales sin commit.${RESET}"
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
