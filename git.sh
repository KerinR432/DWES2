#!/usr/bin/env bash

# ==========================================================
#                  🌿 GESTOR GIT
# ==========================================================
# Proyecto: DWS
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

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║                 🌿  GESTOR GIT                        ║${RESET}"
    echo -e "${CIAN}║                  Proyecto DWS                         ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
    exit 1
fi

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

    return 0
}

# ==========================================================
# INFORMACIÓN GIT
# ==========================================================

rama_actual() {
    git branch --show-current 2>/dev/null || true
}

hay_merge_pendiente() {
    [ -f ".git/MERGE_HEAD" ]
}

hay_cambios() {
    [ -n "$(git status --porcelain 2>/dev/null)" ]
}

rama_existe() {
    git show-ref --verify --quiet "refs/heads/$1"
}

remoto_existe() {
    git show-ref --verify --quiet "refs/remotes/origin/$1"
}

# ==========================================================
# CABECERA
# ==========================================================

mostrar_cabecera() {

    local rama
    rama="$(rama_actual)"

    echo -e "${BLANCO}📂 Proyecto:${RESET} DWS"
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
    info "Comprobando que la rama $rama existe..."

    if ! rama_existe "$rama"; then
        error "La rama local '$rama' no existe."
        pausa
        return
    fi

    echo
    info "Cambiando a $rama..."

    if ! git checkout "$rama"; then
        error "No se puede cambiar a $rama."
        echo "Comprueba si tienes cambios locales pendientes."
        pausa
        return
    fi

    echo

    if ! git fetch origin; then
        error "No se ha podido actualizar la información del remoto."
        pausa
        return
    fi

    echo
    info "Haciendo pull de origin/$rama..."

    if ! git pull origin "$rama"; then
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

    if hay_merge_pendiente; then
        error "Tienes un merge pendiente."
        echo
        echo "Resuelve o cancela el merge antes de hacer un commit normal."
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
    info "Preparando archivos..."

    if ! git add .; then
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

    if ! git push origin "$rama"; then
        echo
        error "El push ha fallado."
        echo
        echo "El commit sigue guardado localmente."
        echo "Puedes volver a intentar:"
        echo
        echo "  git push origin $rama"
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

    if ! git fetch origin; then
        echo
        aviso "No se ha podido actualizar el remoto."
        echo "El estado puede no estar completamente actualizado."
    fi

    echo
    printf " %-12s %-20s %-10s %-10s\n" \
        "RAMA" "ESTADO" "LOCAL +" "REMOTO -"

    printf "%-12s %-22s %-8s %-8s\n" \
        "RAMA" "ESTADO" "LOCAL" "REMOTO"

    linea

    local rama
    local adelante
    local atras
    local cambios
    local estado

    for rama in "${RAMAS[@]}"
    do

        if ! rama_existe "$rama"; then

            printf "%-12s ${ROJO}%-22s${RESET}\n" \
                "$rama" "❌ No existe"

            continue
        fi

        if ! remoto_existe "$rama"; then

            printf "%-12s ${AMARILLO}%-22s${RESET}\n" \
                "$rama" "⚠️ Sin remoto"

            continue
        fi

        adelante=$(git rev-list --count "origin/$rama..$rama" 2>/dev/null || echo 0)
        atras=$(git rev-list --count "$rama..origin/$rama" 2>/dev/null || echo 0)

        cambios=""

        if [ "$(rama_actual)" = "$rama" ]; then
            cambios=$(git status --porcelain 2>/dev/null)
        fi

        if [ -n "$cambios" ]; then

            estado="${AMARILLO}🟡 Cambios locales${RESET}"

        elif [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then

            estado="${ROJO}🔴 Divergida${RESET}"

        elif [ "$adelante" -gt 0 ]; then

            estado="${AZUL}🔵 Push pendiente${RESET}"

        elif [ "$atras" -gt 0 ]; then

            estado="${ROJO}🔴 Pull pendiente${RESET}"

        else

            estado="${VERDE}🟢 Actualizada${RESET}"

        fi

        printf "%-12s %-22b +%-7s -%-7s\n" \
            "$rama" \
            "$estado" \
            "$adelante" \
            "$atras"

    if hay_cambios; then
        aviso "La rama actual tiene cambios locales sin commit."
    else
        ok "La rama actual no tiene cambios sin commit."
    fi

    echo

    echo -e "${BLANCO}📌 SIGNIFICADO${RESET}"
    linea
    echo "🟢 Actualizada   → Todo sincronizado"
    echo "🟡 Cambios       → Hay modificaciones locales"
    echo "🔵 Push pendiente → Hay commits por subir"
    echo "🔴 Pull pendiente → Hay commits nuevos en remoto"
    echo "🔴 Divergida     → Hay cambios en ambos lados"

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

    local archivo

    read -r -p "📄 Archivo: " archivo

    if [ ! -f "$archivo" ]; then
        error "El archivo no existe."
        pausa
        return
    fi

    echo
    echo -e "${BLANCO}👤 QUIÉN MODIFICÓ CADA LÍNEA${RESET}"
    linea
    echo

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

    local destino
    local origen
    local opcion_destino
    local opcion_origen
    local commits
    local confirmar

    if hay_merge_pendiente; then
        error "Ya existe un merge pendiente."
        echo
        echo "Utiliza:"
        echo "  8) Continuar merge"
        echo "  9) Cancelar merge"
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

    echo
    echo "RAMA DESTINO:"
    echo "  1) TEORIA"
    echo "  2) codigo"
    echo "  3) main"
    echo

    read -r -p "Opción: " opcion_destino

    case "$opcion_destino" in

        1) destino="TEORIA" ;;
        2) destino="codigo" ;;
        3) destino="main" ;;

        *)
            error "Opción no válida."
            pausa
            return
            ;;

    esac

    echo
    echo "RAMA ORIGEN:"
    echo "  1) TEORIA"
    echo "  2) codigo"
    echo "  3) main"
    echo

    read -r -p "Opción: " opcion_origen

    case "$opcion_origen" in

        1) origen="TEORIA" ;;
        2) origen="codigo" ;;
        3) origen="main" ;;

        *)
            error "Opción no válida."
            pausa
            return
            ;;

    esac

    if [ "$destino" = "$origen" ]; then
        error "No puedes fusionar una rama consigo misma."
        pausa
        return
    fi

    if ! rama_existe "$destino"; then
        error "La rama destino '$destino' no existe."
        pausa
        return
    fi

    if ! rama_existe "$origen"; then
        error "La rama origen '$origen' no existe."
        pausa
        return
    fi

    echo
    info "Actualizando información del remoto..."

    if ! git fetch origin; then
        aviso "No se ha podido actualizar el remoto."
    fi

    commits=$(git rev-list --count "$destino..$origen" 2>/dev/null || echo 0)

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

    if ! git pull --ff-only origin "$destino"; then
        error "No se pudo actualizar $destino mediante fast-forward."
        echo
        echo "No se ha realizado el merge."
        pausa
        return
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
    echo "Después puedes ejecutar:"
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

    local remoto

    remoto=$(git remote get-url origin 2>/dev/null || true)

    if [ -z "$remoto" ]; then
        error "No existe el remoto 'origin'."
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

    if git ls-remote origin HEAD >/dev/null 2>&1; then
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

    total_commits=$(git rev-list --all --count 2>/dev/null || echo 0)
    autores=$(git log --all --format='%an' 2>/dev/null | sort -u | wc -l | tr -d ' ')
    archivos=$(git ls-files | wc -l | tr -d ' ')
    ramas_locales=$(git branch --format='%(refname:short)' | wc -l | tr -d ' ')

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

    for archivo in ".env" ".env.local" ".env.production"
    do
        if [ -f "$archivo" ]; then
            echo -e "${AMARILLO}⚠️ Encontrado: $archivo${RESET}"
            encontrados=1

        done < <(compgen -G "$patron" 2>/dev/null || true)

    done

    # Buscar archivos .log de forma segura
    if compgen -G "*.log" >/dev/null 2>&1; then
        echo -e "${AMARILLO}⚠️ Se han encontrado archivos .log${RESET}"
        encontrados=1
    fi

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
    actual="$(rama_actual)"

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║                 🌿  GESTOR GIT                        ║${RESET}"
    echo -e "${CIAN}║              Panel de control DWS                     ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo

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

    echo
    echo -e "${BLANCO}🌐 CONEXIÓN${RESET}"
    linea

    if git ls-remote origin HEAD >/dev/null 2>&1; then
        echo -e "   ${VERDE}🟢 Origin conectado${RESET}"
    else

        echo -e "   ${ROJO}🔴 No existe origin${RESET}"

    fi

    echo
    info "Actualizando estado remoto..."

    git fetch origin >/dev/null 2>&1 || true

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
    local cambios
    local estado

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

        adelante=$(git rev-list --count "origin/$rama..$rama" 2>/dev/null || echo 0)
        atras=$(git rev-list --count "$rama..origin/$rama" 2>/dev/null || echo 0)

        cambios=""

        if [ "$rama" = "$actual" ]; then
            cambios=$(git status --porcelain 2>/dev/null)
        fi

        if [ -n "$cambios" ]; then

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

    echo
    echo -e "${BLANCO}📝 ÚLTIMO COMMIT — RAMA ACTUAL${RESET}"
    linea

    local autor
    local fecha
    local mensaje
    local hash

    autor=$(git log -1 --format="%an" 2>/dev/null || echo "-")
    fecha=$(git log -1 --format="%ad" --date="format:%d/%m/%Y %H:%M" 2>/dev/null || echo "-")
    mensaje=$(git log -1 --format="%s" 2>/dev/null || echo "-")
    hash=$(git log -1 --format="%h" 2>/dev/null || echo "-")

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

    local total_commits
    local autores

    total_commits=$(git rev-list --all --count 2>/dev/null || echo 0)
    autores=$(git log --all --format='%an' 2>/dev/null | sort -u | wc -l | tr -d ' ')

    echo
    echo -e "${BLANCO}📊 RESUMEN${RESET}"
    linea

    total_commits="$(git rev-list --all --count 2>/dev/null || echo 0)"
    autores="$(git log --all --format='%an' 2>/dev/null | sort -u | wc -l)"

    echo
    echo "   📝 Commits: $total_commits"
    echo "   👥 Autores: $autores"
    echo "   🌿 Ramas:   ${#RAMAS[@]}"

    echo
    echo -e "${BLANCO}⚠️ AVISOS${RESET}"
    linea

    local avisos=0

    for rama in "${RAMAS[@]}"
    do

        if remoto_existe "$rama"; then

            adelante=$(git rev-list --count "origin/$rama..$rama" 2>/dev/null || echo 0)
            atras=$(git rev-list --count "$rama..origin/$rama" 2>/dev/null || echo 0)

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

    if hay_merge_pendiente; then
        echo -e "${ROJO}🔴 Hay un merge pendiente.${RESET}"
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

