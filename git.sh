#!/bin/bash

# ==========================================================
#                  🌿 GESTOR GIT
# ==========================================================
# Proyecto: DWS / DWES2
# Ramas oficiales: TEORIA / codigo / main
#
# Compatible con:
#   - Linux Mint
#   - Windows 11 + Git Bash
#
# IMPORTANTE:
#   Este script NO utiliza rutas específicas del ordenador.
#   Puede ejecutarse desde cualquier ubicación dentro del repo.
# ==========================================================

set -u
set -o pipefail


# ==========================================================
# CONFIGURACIÓN
# ==========================================================

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
# LOCALIZAR REPOSITORIO
# ==========================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

if ! cd "$SCRIPT_DIR" 2>/dev/null; then
    echo "❌ No se puede acceder a la carpeta del script."
    exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo
    echo -e "${ROJO}❌ ERROR${RESET}"
    echo "El script no está dentro de un repositorio Git."
    echo
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

if ! cd "$REPO_ROOT" 2>/dev/null; then
    echo
    echo -e "${ROJO}❌ No se puede acceder a la raíz del repositorio.${RESET}"
    exit 1
fi


# ==========================================================
# FUNCIONES VISUALES
# ==========================================================

limpiar() {
    clear 2>/dev/null || printf '\033c'
}


titulo() {

    limpiar

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║                 🌿  GESTOR GIT                       ║${RESET}"
    echo -e "${CIAN}║                 Proyecto DWS                         ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
}


linea() {
    echo -e "${GRIS}────────────────────────────────────────────────────────${RESET}"
}


pausa() {
    echo
    read -r -p "Pulsa ENTER para continuar..."
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
# INFORMACIÓN DEL SISTEMA
# ==========================================================

detectar_sistema() {

    case "$(uname -s 2>/dev/null)" in

        Linux*)
            SISTEMA="Linux Mint / Linux"
            ;;

        MINGW*|MSYS*|CYGWIN*)
            SISTEMA="Windows 11 / Git Bash"
            ;;

        *)
            SISTEMA="Sistema desconocido"
            ;;

    esac
}


# ==========================================================
# COMPROBACIONES GIT
# ==========================================================

rama_actual() {
    git branch --show-current
}


rama_existe() {
    git show-ref --verify --quiet "refs/heads/$1"
}


remoto_existe() {
    git show-ref --verify --quiet "refs/remotes/$REMOTO/$1"
}


hay_cambios() {

    [ -n "$(git status --porcelain 2>/dev/null)" ]
}


hay_merge_pendiente() {

    [ -f "$(git rev-parse --git-path MERGE_HEAD)" ]
}


hay_rebase_pendiente() {

    local rebase_merge
    local rebase_apply

    rebase_merge="$(git rev-parse --git-path rebase-merge)"
    rebase_apply="$(git rev-parse --git-path rebase-apply)"

    [ -d "$rebase_merge" ] || [ -d "$rebase_apply" ]
}


hay_cherry_pick_pendiente() {

    [ -f "$(git rev-parse --git-path CHERRY_PICK_HEAD)" ]
}


hay_revert_pendiente() {

    [ -f "$(git rev-parse --git-path REVERT_HEAD)" ]
}


hay_operacion_pendiente() {

    hay_merge_pendiente ||
    hay_rebase_pendiente ||
    hay_cherry_pick_pendiente ||
    hay_revert_pendiente
}


mostrar_operacion_pendiente() {

    if hay_merge_pendiente; then
        error "Hay un MERGE pendiente."
        return
    fi

    if hay_rebase_pendiente; then
        error "Hay un REBASE pendiente."
        return
    fi

    if hay_cherry_pick_pendiente; then
        error "Hay un CHERRY-PICK pendiente."
        return
    fi

    if hay_revert_pendiente; then
        error "Hay un REVERT pendiente."
        return
    fi
}


# ==========================================================
# COMPROBAR CAMBIOS DE UNA RAMA
# ==========================================================

contar_adelante() {

    local rama="$1"

    git rev-list --count "$REMOTO/$rama..$rama" 2>/dev/null || echo 0
}


contar_atras() {

    local rama="$1"

    git rev-list --count "$rama..$REMOTO/$rama" 2>/dev/null || echo 0
}


# ==========================================================
# CABECERA
# ==========================================================

mostrar_cabecera() {

    local actual

    actual="$(rama_actual)"

    echo -e "${BLANCO}📂 REPOSITORIO${RESET}"
    linea

    echo "   DWS / DWES2"
    echo -e "   ${GRIS}$REPO_ROOT${RESET}"

    echo
    echo -e "${BLANCO}💻 SISTEMA${RESET}"
    linea

    echo "   $SISTEMA"

    echo
    echo -e "${BLANCO}🌿 RAMA ACTUAL${RESET}"
    linea

    if [ -n "$actual" ]; then
        echo -e "   ${MAGENTA}$actual${RESET}"
    else
        echo -e "   ${ROJO}⚠️ HEAD separado${RESET}"
    fi

    if hay_operacion_pendiente; then
        echo
        mostrar_operacion_pendiente
    fi

    echo
}


# ==========================================================
# COMPROBAR ORIGIN
# ==========================================================

comprobar_origin() {

    git remote get-url "$REMOTO" >/dev/null 2>&1
}


# ==========================================================
# FETCH
# ==========================================================

actualizar_remoto() {

    if ! comprobar_origin; then
        error "No existe el remoto '$REMOTO'."
        return 1
    fi

    info "Actualizando información de $REMOTO..."

    if git fetch "$REMOTO" --prune; then
        ok "Información del remoto actualizada."
        return 0
    fi

    error "No se pudo actualizar el remoto."
    return 1
}


# ==========================================================
# SELECCIONAR RAMA
# ==========================================================

seleccionar_rama() {

    echo
    echo -e "${BLANCO}Selecciona una rama:${RESET}"
    echo
    echo "  1) 🌿 TEORIA"
    echo "  2) 💻 codigo"
    echo "  3) ⭐ main"
    echo

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

    return 0
}


# ==========================================================
# CAMBIAR DE RAMA DE FORMA SEGURA
# ==========================================================

cambiar_rama() {

    local destino="$1"
    local actual

    actual="$(rama_actual)"

    if [ "$actual" = "$destino" ]; then
        return 0
    fi

    if hay_operacion_pendiente; then
        mostrar_operacion_pendiente
        echo
        aviso "No puedes cambiar de rama mientras exista una operación pendiente."
        return 1
    fi

    if hay_cambios; then
        error "Tienes cambios locales sin guardar."
        echo
        git status --short
        echo
        aviso "Haz commit o guarda tus cambios antes de cambiar de rama."
        return 1
    fi

    info "Cambiando de $actual a $destino..."

    if git switch "$destino"; then
        ok "Ahora estás en $destino."
        return 0
    fi

    error "No se pudo cambiar a $destino."
    return 1
}


# ==========================================================
# PULL
# ==========================================================

hacer_pull() {

    titulo
    mostrar_cabecera

    if hay_operacion_pendiente; then
        mostrar_operacion_pendiente
        echo
        aviso "Finaliza o cancela la operación pendiente antes de hacer pull."
        pausa
        return
    fi

    seleccionar_rama || {
        pausa
        return
    }

    echo
    echo -e "${BLANCO}📥 PULL${RESET}"
    linea

    echo
    info "Rama seleccionada: $rama"

    if ! cambiar_rama "$rama"; then
        pausa
        return
    fi

    echo

    if ! actualizar_remoto; then
        pausa
        return
    fi

    echo
    info "Comprobando estado de $rama..."

    local adelante
    local atras

    adelante="$(contar_adelante "$rama")"
    atras="$(contar_atras "$rama")"

    if [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then

        error "La rama está DIVERGIDA."
        echo
        echo "   Commits locales pendientes: $adelante"
        echo "   Commits remotos pendientes: $atras"
        echo
        aviso "No se realizará ningún pull automático."
        echo "Revisa la divergencia manualmente."
        pausa
        return

    fi

    if [ "$atras" -eq 0 ]; then
        echo
        ok "La rama $rama ya está actualizada."
        pausa
        return
    fi

    echo
    echo "   Commits nuevos en remoto: $atras"
    echo

    info "Realizando fast-forward..."

    if git pull --ff-only "$REMOTO" "$rama"; then
        echo
        ok "Rama $rama actualizada correctamente."
    else
        echo
        error "El pull no se pudo completar."
        echo "No se ha creado ningún merge automático."
    fi

    pausa
}


# ==========================================================
# COMMIT + PUSH
# ==========================================================

hacer_push() {

    titulo
    mostrar_cabecera

    if hay_operacion_pendiente; then
        mostrar_operacion_pendiente
        echo
        aviso "Finaliza la operación pendiente antes de hacer commit."
        pausa
        return
    fi

    seleccionar_rama || {
        pausa
        return
    }

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
    info "Preparando cambios..."

    if ! git add -A; then
        error "No se pudieron preparar los archivos."
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
        error "El mensaje del commit no puede estar vacío."
        git restore --staged .
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
    info "Actualizando información del remoto..."

    if ! git fetch "$REMOTO" --prune; then
        aviso "No se pudo actualizar el remoto."
        echo "El commit permanece guardado localmente."
        pausa
        return
    fi

    local adelante
    local atras

    adelante="$(contar_adelante "$rama")"
    atras="$(contar_atras "$rama")"

    echo
    echo "Estado antes del push:"
    echo "   📤 Local pendiente: $adelante"
    echo "   📥 Remoto pendiente: $atras"

    if [ "$atras" -gt 0 ]; then

        echo
        error "El remoto tiene commits que esta copia no tiene."
        echo
        echo "Primero debes hacer:"
        echo
        echo "   Pull"
        echo
        aviso "No se realizará ningún push forzado."
        pausa
        return

    fi

    echo
    info "Subiendo a $REMOTO/$rama..."

    if git push -u "$REMOTO" "$rama"; then

        echo
        ok "Commit y push realizados correctamente."

    else

        echo
        error "El push ha fallado."
        echo "El commit sigue guardado localmente."
        echo
        echo "No se ha utilizado ningún push forzado."

    fi

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

    echo
    if ! actualizar_remoto; then
        aviso "El estado remoto puede no estar completamente actualizado."
    fi

    echo
    printf " %-12s %-20s %-10s %-10s\n" \
        "RAMA" "ESTADO" "LOCAL +" "REMOTO -"

    linea

    local rama
    local estado
    local adelante
    local atras

    for rama in "${RAMAS[@]}"
    do

        if ! rama_existe "$rama"; then

            printf " %-12s ${ROJO}%-20s${RESET}\n" \
                "$rama" "❌ No existe"

            continue
        fi

        if ! remoto_existe "$rama"; then

            printf " %-12s ${AMARILLO}%-20s${RESET}\n" \
                "$rama" "⚠️ Sin remoto"

            continue
        fi

        adelante="$(contar_adelante "$rama")"
        atras="$(contar_atras "$rama")"
        estado="$(obtener_estado_rama "$rama")"

        case "$estado" in

            OK)
                estado_texto="${VERDE}🟢 Actualizada${RESET}"
                ;;

            PUSH)
                estado_texto="${AZUL}🔵 Push pendiente${RESET}"
                ;;

            PULL)
                estado_texto="${ROJO}🔴 Pull pendiente${RESET}"
                ;;

            DIVERGIDA)
                estado_texto="${ROJO}🔴 Divergida${RESET}"
                ;;

            *)
                estado_texto="${GRIS}❓ Desconocido${RESET}"
                ;;

        esac

        printf " %-12s %-20b %-10s %-10s\n" \
            "$rama" \
            "$estado_texto" \
            "+$adelante" \
            "-$atras"

    done

    echo

    echo -e "${BLANCO}📌 SIGNIFICADO${RESET}"
    linea

    echo " 🟢 Actualizada    → Local y remoto están sincronizados"
    echo " 🔵 Push pendiente  → Hay commits locales por subir"
    echo " 🔴 Pull pendiente  → Hay commits nuevos en GitHub"
    echo " 🔴 Divergida       → Existen commits diferentes en ambos lados"
    echo

    if hay_cambios; then
        aviso "La rama actual tiene cambios locales sin commit."
    else
        ok "La rama actual no tiene cambios sin commit."
    fi

    if hay_operacion_pendiente; then
        echo
        mostrar_operacion_pendiente
    fi

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

    echo
    echo -e "${BLANCO}📜 HISTORIAL — $rama${RESET}"
    linea
    echo

    if command -v less >/dev/null 2>&1; then

        git log "$rama" \
            --graph \
            --decorate \
            --date="format:%d/%m/%Y %H:%M" \
            --pretty=format:"%C(yellow)%h%Creset | %C(cyan)%ad%Creset | %C(green)%an%Creset | %s%Creset" \
            | less -R

    else

        git log "$rama" \
            --graph \
            --decorate \
            --date="format:%d/%m/%Y %H:%M" \
            --pretty=format:"%h | %ad | %an | %s"

        echo

    fi

    pausa
}


# ==========================================================
# VER COMMIT
# ==========================================================

ver_commit() {

    titulo

    echo -e "${BLANCO}🔍 INFORMACIÓN DE COMMIT${RESET}"
    linea
    echo

    read -r -p "🔑 ID o hash del commit: " commit

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

    echo -e "${BLANCO}📋 INFORMACIÓN${RESET}"
    linea
    echo

    git show --stat --decorate --format=fuller "$commit"

    echo
    read -r -p "¿Quieres ver los cambios completos? (s/n): " respuesta

    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then

        echo
        echo -e "${BLANCO}🔬 CAMBIOS COMPLETOS${RESET}"
        linea
        echo

        git show --format=fuller "$commit"

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

    echo
    echo -e "${BLANCO}$tipo${RESET}"
    echo

    echo "  1) TEORIA"
    echo "  2) codigo"
    echo "  3) main"
    echo

    read -r -p "Opción: " opcion

    case "$opcion" in

        1)
            if [ "$tipo" = "RAMA DESTINO:" ]; then
                destino="TEORIA"
            else
                origen="TEORIA"
            fi
            ;;

        2)
            if [ "$tipo" = "RAMA DESTINO:" ]; then
                destino="codigo"
            else
                origen="codigo"
            fi
            ;;

        3)
            if [ "$tipo" = "RAMA DESTINO:" ]; then
                destino="main"
            else
                origen="main"
            fi
            ;;

        *)
            error "Opción no válida."
            return 1
            ;;

    esac

    return 0
}


# ==========================================================
# MERGE
# ==========================================================

hacer_merge() {

    titulo

    if hay_operacion_pendiente; then
        mostrar_operacion_pendiente
        echo
        aviso "Debes resolver primero la operación pendiente."
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

    seleccionar_rama_merge "RAMA DESTINO:" || {
        pausa
        return
    }

    seleccionar_rama_merge "RAMA ORIGEN:" || {
        pausa
        return
    }

    if [ "$destino" = "$origen" ]; then
        error "No puedes fusionar una rama consigo misma."
        pausa
        return
    fi

    echo
    info "Actualizando información del remoto..."

    if ! actualizar_remoto; then
        pausa
        return
    fi

    if ! rama_existe "$destino" || ! rama_existe "$origen"; then
        error "Una de las ramas seleccionadas no existe localmente."
        pausa
        return
    fi

    local commits

    commits="$(git rev-list --count "$destino..$origen" 2>/dev/null || echo 0)"

    echo
    echo -e "${BLANCO}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLANCO}║                    🔀 MERGE                          ║${RESET}"
    echo -e "${BLANCO}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "   ${MAGENTA}$origen${RESET}  →  ${CIAN}$destino${RESET}"
    echo
    echo "   Commits a incorporar: $commits"
    echo

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
    info "Comprobando que $destino esté actualizado..."

    local atras_destino

    atras_destino="$(contar_atras "$destino")"

    if [ "$atras_destino" -gt 0 ]; then

        aviso "$destino tiene $atras_destino commit(s) nuevos en remoto."
        echo
        echo "Actualizando mediante fast-forward..."

        if ! git pull --ff-only "$REMOTO" "$destino"; then
            error "No se pudo actualizar $destino."
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
        echo "   git push origin $destino"

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
        echo "   git push origin $destino"
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
    echo "Resuelve los conflictos y después ejecuta:"
    echo
    echo "   git add <archivo>"
    echo "   git commit"
    echo
    echo "Cuando el merge esté terminado podrás hacer push."

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

    if ! comprobar_origin; then
        error "No existe el remoto '$REMOTO'."
        pausa
        return
    fi

    remoto_url="$(git remote get-url "$REMOTO")"

    echo -e "${BLANCO}📡 REMOTO${RESET}"
    echo
    echo "   Nombre: $REMOTO"
    echo "   URL:    $remoto_url"

    echo
    info "Comprobando conexión..."

    if git ls-remote "$REMOTO" HEAD >/dev/null 2>&1; then
        ok "Conexión con GitHub correcta."
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

    total_commits="$(git rev-list --all --count 2>/dev/null || echo 0)"
    autores="$(git log --all --format='%an' 2>/dev/null | sort -u | wc -l)"
    archivos="$(git ls-files | wc -l)"
    ramas_locales="$(git branch --format='%(refname:short)' | wc -l)"
    ramas_remotas="$(git branch -r | wc -l)"

    echo "📝 Commits totales:   $total_commits"
    echo "👥 Autores:           $autores"
    echo "📁 Archivos:          $archivos"
    echo "🌿 Ramas locales:     $ramas_locales"
    echo "🌐 Ramas remotas:     $ramas_remotas"

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

    encontrados=0

    patrones=(
        ".env"
        ".env.local"
        ".env.production"
        "*.log"
    )

    for patron in "${patrones[@]}"
    do

        while IFS= read -r archivo
        do

            [ -n "$archivo" ] || continue

            echo -e "${AMARILLO}⚠️ Encontrado: $archivo${RESET}"
            encontrados=1

        done < <(compgen -G "$patron" 2>/dev/null || true)

    done

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
# ÚLTIMO COMMIT DE UNA RAMA
# ==========================================================

mostrar_ultimo_commit() {

    local rama="$1"

    if ! rama_existe "$rama"; then
        return
    fi

    echo
    echo -e "${BLANCO}$rama${RESET}"
    echo "   🔑 $(git log -1 --format='%h' "$rama")"
    echo "   👤 $(git log -1 --format='%an' "$rama")"
    echo "   📅 $(git log -1 --format='%ad' --date='format:%d/%m/%Y %H:%M' "$rama")"
    echo "   📝 $(git log -1 --format='%s' "$rama")"
}


# ==========================================================
# DASHBOARD
# ==========================================================

dashboard() {

    limpiar

    detectar_sistema

    rama_actual="$(rama_actual)"

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║                 🌿  GESTOR GIT                       ║${RESET}"
    echo -e "${CIAN}║                Panel DWS / DWES2                     ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo

    # ------------------------------------------------------
    # PROYECTO
    # ------------------------------------------------------

    echo -e "${BLANCO}📂 PROYECTO${RESET}"
    linea

    echo "   DWS / DWES2"
    echo -e "   ${GRIS}$REPO_ROOT${RESET}"

    echo
    echo -e "${BLANCO}💻 SISTEMA${RESET}"
    linea

    echo "   $SISTEMA"

    echo
    echo -e "${BLANCO}🌿 RAMA ACTUAL${RESET}"
    linea

    if [ -n "$rama_actual" ]; then
        echo -e "   ${MAGENTA}$rama_actual${RESET}"
    else
        echo -e "   ${ROJO}⚠️ HEAD separado${RESET}"
    fi

    # ------------------------------------------------------
    # OPERACIONES PENDIENTES
    # ------------------------------------------------------

    if hay_operacion_pendiente; then

        echo
        echo -e "${ROJO}╔════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${ROJO}║              ⚠️ OPERACIÓN PENDIENTE                  ║${RESET}"
        echo -e "${ROJO}╚════════════════════════════════════════════════════════╝${RESET}"
        echo

        mostrar_operacion_pendiente

        echo
        echo "   Utiliza las opciones correspondientes para resolverla."

    fi

    # ------------------------------------------------------
    # CONEXIÓN
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌐 CONEXIÓN${RESET}"
    linea

    if comprobar_origin; then

        remoto_url="$(git remote get-url "$REMOTO")"

        if git ls-remote "$REMOTO" HEAD >/dev/null 2>&1; then
            echo -e "   ${VERDE}🟢 GitHub conectado${RESET}"
        else
            echo -e "   ${ROJO}🔴 No se puede conectar con GitHub${RESET}"
        fi

        echo -e "   ${GRIS}$remoto_url${RESET}"

    else

        echo -e "   ${ROJO}🔴 No existe origin${RESET}"

    fi

    # ------------------------------------------------------
    # FETCH
    # ------------------------------------------------------

    echo
    info "Actualizando estado remoto..."

    git fetch "$REMOTO" --prune >/dev/null 2>&1 || true

    # ------------------------------------------------------
    # RAMAS
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌿 ESTADO DE LAS RAMAS${RESET}"
    linea
    echo

    printf " %-12s %-23s %-9s %-9s\n" \
        "RAMA" "ESTADO" "LOCAL +" "REMOTO -"

    echo

    local rama
    local adelante
    local atras
    local estado
    local estado_texto

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

        if [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then

            estado_texto="${ROJO}🔴 Divergida${RESET}"

        elif [ "$adelante" -gt 0 ]; then

            estado_texto="${AZUL}🔵 Push pendiente${RESET}"

        elif [ "$atras" -gt 0 ]; then

            estado_texto="${ROJO}🔴 Pull pendiente${RESET}"

        else

            estado_texto="${VERDE}🟢 Actualizada${RESET}"

        fi

        if [ "$rama" = "$rama_actual" ] && hay_cambios; then
            estado_texto="${AMARILLO}🟡 Cambios locales${RESET}"
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

    if [ -n "$rama_actual" ]; then

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
        aviso "HEAD separado."

    fi

    # ------------------------------------------------------
    # RESUMEN
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}📊 RESUMEN${RESET}"
    linea

    total_commits="$(git rev-list --all --count 2>/dev/null || echo 0)"
    autores="$(git log --all --format='%an' 2>/dev/null | sort -u | wc -l)"

    echo
    echo "   📝 Commits: $total_commits"
    echo "   👥 Autores: $autores"
    echo "   🌿 Ramas:   ${#RAMAS[@]}"

    # ------------------------------------------------------
    # AVISOS
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}⚠️ AVISOS${RESET}"
    linea
    echo

    avisos=0

    for rama in "${RAMAS[@]}"
    do

        if remoto_existe "$rama"; then

            adelante="$(contar_adelante "$rama")"
            atras="$(contar_atras "$rama")"

            if [ "$adelante" -gt 0 ]; then
                echo -e "${AZUL}🔵 $rama → $adelante commit(s) pendiente(s) de PUSH.${RESET}"
                avisos=1
            fi

            if [ "$atras" -gt 0 ]; then
                echo -e "${ROJO}🔴 $rama → $atras commit(s) pendiente(s) de PULL.${RESET}"
                avisos=1
            fi

            if [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then
                echo -e "${ROJO}⚠️ $rama → RAMA DIVERGIDA.${RESET}"
                avisos=1
            fi

        fi

    done

    if [ -n "$rama_actual" ] && hay_cambios; then

        echo -e "${AMARILLO}🟡 $rama_actual → Hay cambios locales sin commit.${RESET}"
        avisos=1

    fi

    if hay_operacion_pendiente; then

        echo -e "${ROJO}🔴 Existe una operación Git pendiente.${RESET}"
        avisos=1

    fi

    if [ "$avisos" -eq 0 ]; then

        echo -e "${VERDE}🟢 No hay avisos pendientes.${RESET}"

    fi

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║              Selecciona una opción                   ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
}


# ==========================================================
# MENU PRINCIPAL
# ==========================================================

menu_principal() {

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
                limpiar
                echo
                echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
                echo -e "${CIAN}║              👋 Hasta luego, Ruvik                  ║${RESET}"
                echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
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

detectar_sistema
menu_principal

