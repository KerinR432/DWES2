#!/bin/bash

# ==========================================================
#                 🌿 GESTOR GIT
# ==========================================================
# Proyecto: DWS
# Ramas: TEORIA / codigo / main
# ==========================================================

set -u

# ----------------------------------------------------------
# CONFIGURACIÓN
# ----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

RAMAS=("TEORIA" "codigo" "main")


# ----------------------------------------------------------
# COLORES
# ----------------------------------------------------------

RESET="\033[0m"
ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
MAGENTA="\033[1;35m"
CIAN="\033[1;36m"
BLANCO="\033[1;37m"
GRIS="\033[0;37m"


# ----------------------------------------------------------
# FUNCIONES VISUALES
# ----------------------------------------------------------

titulo() {
    clear

    echo
    echo -e "${CIAN}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║              🌿  GESTOR GIT                     ║${RESET}"
    echo -e "${CIAN}║             Sistema de control                  ║${RESET}"
    echo -e "${CIAN}╚══════════════════════════════════════════════════╝${RESET}"
    echo
}


linea() {
    echo -e "${GRIS}──────────────────────────────────────────────────${RESET}"
}

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


# ----------------------------------------------------------
# COMPROBACIONES
# ----------------------------------------------------------

hay_merge_pendiente() {

    if [ -f ".git/MERGE_HEAD" ]; then
        return 0
    fi

    return 1
}


hay_cambios() {

    if [ -n "$(git status --porcelain)" ]; then
        return 0
    fi

    return 1
}


rama_existe() {

    git show-ref --verify --quiet "refs/heads/$1"
}


remoto_existe() {

    git show-ref --verify --quiet "refs/remotes/origin/$1"
}


# ----------------------------------------------------------
# SELECCIONAR RAMA
# ----------------------------------------------------------

seleccionar_rama() {

    echo
    echo -e "${BLANCO}Selecciona una rama:${RESET}"
    echo
    echo "  1) TEORIA"
    echo "  2) codigo"
    echo "  3) main"
seleccionar_rama() {

    echo
    echo "Selecciona una rama:"
    echo "1) TEORIA"
    echo "2) codigo"
    echo "3) main"
    echo

    read -p "Opción: " opcion

    case "$opcion" in
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
            error "Opción no válida."
            echo "❌ Opción no válida"
            return 1
            ;;
    esac

    return 0
}


# ----------------------------------------------------------
# CABECERA DEL PROYECTO
# ----------------------------------------------------------

mostrar_cabecera() {

    rama_actual=$(git branch --show-current)

    echo -e "${BLANCO}📂 Proyecto:${RESET} DWS"
    echo -e "${GRIS}$SCRIPT_DIR${RESET}"

    echo

    if [ -n "$rama_actual" ]; then
        echo -e "${BLANCO}🌿 Rama actual:${RESET} ${MAGENTA}$rama_actual${RESET}"
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
# PULL
# ==========================================================

hacer_pull() {

    titulo
    mostrar_cabecera

    if hay_merge_pendiente; then
        error "Tienes un merge pendiente."
        echo
        echo "Termina o cancela el merge antes de hacer un pull."
        pausa
        return
    fi

    seleccionar_rama || {
        pausa
        return
    }

    echo
    info "Cambiando a $rama..."

    if ! git checkout "$rama"; then
        echo
        error "No se puede cambiar a $rama."
        echo "Comprueba si tienes cambios locales pendientes."
        pausa
        return
    fi

    echo
    info "Actualizando información del remoto..."

    git fetch origin

    echo
    info "Haciendo pull de $rama..."

    if ! git pull origin "$rama"; then
        echo
        error "El pull no se ha podido completar."
        pausa
        return
    fi

    echo
    ok "Rama $rama actualizada correctamente."
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


# ==========================================================
# COMMIT + PUSH
# ==========================================================

hacer_push() {

    titulo
    mostrar_cabecera

    if hay_merge_pendiente; then
        error "Tienes un merge pendiente."
        echo "Resuelve el merge antes de hacer un commit normal."
        pausa
        return
    fi

    seleccionar_rama || {
        pausa
        return
    }

    echo
    info "Cambiando a $rama..."

    if ! git checkout "$rama"; then
        error "No se puede cambiar a $rama."
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
    aviso "Se utilizará: git add ."
    echo "Esto añadirá todos los cambios del proyecto."

    echo
    read -p "¿Quieres continuar? (s/n): " confirmar

    if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
        aviso "Operación cancelada."
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
    info "Preparando archivos..."
    echo "📦 Añadiendo archivos..."

    git add .

    echo
    echo -e "${BLANCO}📦 ARCHIVOS PREPARADOS${RESET}"
    linea

    git status --short

    echo
    read -p "📝 Mensaje del commit: " mensaje

    if [ -z "$mensaje" ]; then
        error "El mensaje no puede estar vacío."
        git restore --staged .
        pausa
        return
    fi

    echo
    info "Creando commit..."

    if ! git commit -m "$mensaje"; then
        error "No se ha podido crear el commit."
        pausa
        return
    fi

    echo
    info "Subiendo a origin/$rama..."

    if ! git push origin "$rama"; then
        echo
        error "El push ha fallado."
        echo "El commit sigue guardado localmente."
        pausa
        return
    fi

    echo
    ok "Commit y push realizados correctamente."
    echo "💾 Creando commit..."

    git commit -m "$mensaje"

    echo
    echo "⬆️ Subiendo a origin/$rama..."

    git push origin "$rama"

    echo
    echo "✅ Commit y push realizados correctamente."

    pausa
}


# ==========================================================
# ESTADO DE LAS RAMAS
# ==========================================================

ver_estado() {

    titulo
    mostrar_cabecera

    echo -e "${BLANCO}🔎 ACTUALIZANDO ESTADO${RESET}"
    linea

    if ! git fetch origin; then
        echo
        aviso "No se ha podido actualizar el remoto."
        echo "El estado puede no ser completamente actual."
    fi

    echo

    printf "%-12s %-18s %-8s %-8s\n" "RAMA" "ESTADO" "LOCAL" "REMOTO"
    linea
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

        if ! rama_existe "$rama"; then
            printf "%-12s %-18s\n" "$rama" "❌ No existe"
            continue
        fi

        if ! remoto_existe "$rama"; then
            printf "%-12s %-18s\n" "$rama" "⚠️ Sin remoto"
            continue
        fi

        cambios=$(git status --porcelain "$rama" 2>/dev/null)

        adelante=$(git rev-list --count "origin/$rama..$rama")
        atras=$(git rev-list --count "$rama..origin/$rama")

        if [ -n "$cambios" ]; then
            estado="🟡 Cambios"
        elif [ "$adelante" -gt 0 ] && [ "$atras" -gt 0 ]; then
            estado="🔴 Divergida"
        elif [ "$adelante" -gt 0 ]; then
            estado="🔵 Push"
        elif [ "$atras" -gt 0 ]; then
            estado="🔴 Pull"
        else
            estado="🟢 OK"
        fi

        printf "%-12s %-18s +%-7s -%-7s\n" \
            "$rama" \
            "$estado" \
            "$adelante" \
            "$atras"
    done

    echo

    echo -e "${BLANCO}📌 SIGNIFICADO${RESET}"
    echo "🟢 OK       → Todo sincronizado"
    echo "🟡 Cambios  → Hay modificaciones locales"
    echo "🔵 Push     → Hay commits por subir"
    echo "🔴 Pull     → Hay commits nuevos en remoto"
    echo "🔴 Divergida → Hay cambios en ambos lados"
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
    echo -e "${BLANCO}📜 HISTORIAL DE $rama${RESET}"
    linea
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


# ==========================================================
# VER COMMIT
# ==========================================================

ver_commit() {

    titulo

    read -p "🔑 ID del commit: " commit

    if [ -z "$commit" ]; then
        error "No has introducido ningún commit."
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
    echo -e "${BLANCO}🔍 INFORMACIÓN DEL COMMIT${RESET}"
    linea
    echo

    if ! git show --stat "$commit"; then
        error "Ese commit no existe."
        pausa
        return
    fi

    echo
    read -p "¿Quieres ver los cambios completos? (s/n): " respuesta
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


# ==========================================================
# BLAME
# ==========================================================

ver_blame() {

    titulo

    read -p "📄 Archivo: " archivo

    if [ ! -f "$archivo" ]; then
        error "El archivo no existe."
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
    echo -e "${BLANCO}👤 QUIÉN MODIFICÓ CADA LÍNEA${RESET}"
    linea
    echo "👤 QUIÉN MODIFICÓ CADA LÍNEA"
    echo

    git blame "$archivo"

    pausa
}


# ==========================================================
# MERGE SEGURO
# ==========================================================

hacer_merge() {

    titulo

    if hay_merge_pendiente; then
        error "Ya existe un merge pendiente."
        echo
        echo "Utiliza:"
        echo "8) Continuar merge"
        echo "9) Cancelar merge"
        pausa
        return
    fi

    if hay_cambios; then
        error "Tienes cambios locales sin commit."
        echo
        git status --short
        echo
        echo "Haz commit antes de realizar el merge."
        pausa
        return
    fi

    echo -e "${BLANCO}🔀 MERGE${RESET}"
    linea

    echo
    echo "RAMA DESTINO:"
    echo "1) TEORIA"
    echo "2) codigo"
    echo "3) main"
    echo

    read -p "Opción: " opcion_destino

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
    echo "1) TEORIA"
    echo "2) codigo"
    echo "3) main"
    echo

    read -p "Opción: " opcion_origen

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

    echo
    info "Actualizando información del remoto..."

    git fetch origin

    commits=$(git rev-list --count "$destino..$origen")

    echo
    echo -e "${BLANCO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}🔀 OPERACIÓN${RESET}"
    echo
    echo -e "   ${MAGENTA}$origen${RESET}  →  ${CIAN}$destino${RESET}"
    echo
    echo "   Commits a incorporar: $commits"
    echo -e "${BLANCO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if [ "$commits" -eq 0 ]; then
        echo
        info "No hay commits nuevos que fusionar."
        pausa
        return
    fi

    echo
    aviso "El merge se realizará solamente en LOCAL."
    echo "El script NO hará push automáticamente."

    echo
    read -p "¿Quieres continuar? (s/n): " confirmar

    if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
        aviso "Merge cancelado."
        pausa
        return
    fi

    echo
    info "Cambiando a $destino..."

    if ! git checkout "$destino"; then
        error "No se puede cambiar a $destino."
        pausa
        return
    fi

    echo
    info "Actualizando $destino..."

    if ! git pull --ff-only origin "$destino"; then
        error "No se pudo actualizar $destino."
        pausa
        return
    fi

    echo
    info "Realizando merge de $origen..."

    if git merge "$origen"; then

        echo
        ok "MERGE COMPLETADO"
        echo
        echo "$origen → $destino"

        echo
        aviso "El merge está solamente en LOCAL."

        echo
        echo "Para subirlo:"
        echo
        echo "    git push origin $destino"

    else

        echo
        error "SE HAN ENCONTRADO CONFLICTOS"
        echo

        git status --short

        echo
        echo "Resuelve los conflictos y después:"
        echo
        echo "    git add <archivo>"
        echo "    git commit"
        echo "    git push origin $destino"

        echo
        echo "Si quieres cancelar:"
        echo
        echo "    git merge --abort"
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
    echo -e "${BLANCO}Archivos con conflictos:${RESET}"
    echo

    git diff --name-only --diff-filter=U

    echo
    echo "Resuelve los conflictos en los archivos."
    echo
    echo "Después:"
    echo
    echo "    git add <archivo>"
    echo "    git commit"
    echo "    git push origin <rama>"

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

    read -p "¿Quieres cancelar el merge? (s/n): " confirmar

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

    remoto=$(git remote get-url origin 2>/dev/null || true)

    if [ -z "$remoto" ]; then
        error "No existe el remoto 'origin'."
        pausa
        return
    fi

    echo "📡 origin:"
    echo "$remoto"

    echo
    info "Comprobando conexión..."

    if git ls-remote origin HEAD > /dev/null 2>&1; then
        ok "Conexión con el remoto correcta."
    else
        error "No se ha podido conectar con el remoto."
    fi

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

    total_commits=$(git rev-list --all --count)
    autores=$(git log --all --format='%an' | sort -u | wc -l)
    archivos=$(git ls-files | wc -l)
    ramas=$(git branch --format='%(refname:short)' | wc -l)

    echo "📝 Commits totales:  $total_commits"
    echo "👥 Autores:          $autores"
    echo "📁 Archivos:         $archivos"
    echo "🌿 Ramas locales:    $ramas"

    echo
    echo -e "${BLANCO}👥 AUTORES${RESET}"
    linea

    git shortlog -sne --all

    echo
    echo -e "${BLANCO}📌 ÚLTIMO COMMIT${RESET}"
    linea

    git log -1 \
        --pretty=format:"👤 %an%n📅 %ad%n📝 %s%n🔑 %h" \
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

    for archivo in ".env" ".env.local" ".env.production" "*.log"
    do
        if compgen -G "$archivo" > /dev/null; then
            echo -e "${AMARILLO}⚠️ Encontrado: $archivo${RESET}"
            encontrados=1
        fi
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
        echo
        aviso "Comprueba que estos archivos estén correctamente gestionados por .gitignore."
    fi

    echo
    echo -e "${BLANCO}📄 .gitignore${RESET}"
    linea

    if [ -f ".gitignore" ]; then
        cat .gitignore
    else
        aviso "No existe .gitignore."
        echo
        echo "Puedes crear uno para evitar subir archivos innecesarios."
    fi

    pausa
}


# ==========================================================
# DASHBOARD INICIAL
# ==========================================================

dashboard() {

    clear

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║                 🌿  GESTOR GIT                       ║${RESET}"
    echo -e "${CIAN}║              Panel de control DWS                    ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo

    # ------------------------------------------------------
    # INFORMACIÓN DEL PROYECTO
    # ------------------------------------------------------

    rama_actual=$(git branch --show-current)

    echo -e "${BLANCO}📂 PROYECTO${RESET}"
    linea

    echo "   DWS"
    echo "   $SCRIPT_DIR"

    echo
    echo -e "${BLANCO}🌿 RAMA ACTUAL${RESET}"
    linea

    if [ -n "$rama_actual" ]; then
        echo -e "   ${MAGENTA}$rama_actual${RESET}"
    else
        echo -e "   ${ROJO}⚠️ HEAD separado${RESET}"
    fi

    # ------------------------------------------------------
    # MERGE PENDIENTE
    # ------------------------------------------------------

    if hay_merge_pendiente; then

        echo
        echo -e "${ROJO}╔════════════════════════════════════════════════════╗${RESET}"
        echo -e "${ROJO}║              ⚠️  MERGE PENDIENTE                  ║${RESET}"
        echo -e "${ROJO}╚════════════════════════════════════════════════════╝${RESET}"

        echo
        echo "   Tienes un merge que necesita atención."
        echo "   Puedes utilizar:"
        echo
        echo "   🔧 Opción 8 → Continuar merge"
        echo "   🛑 Opción 9 → Cancelar merge"
    fi

    # ------------------------------------------------------
    # ACTUALIZAR REMOTO
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌐 CONEXIÓN${RESET}"
    linea

    if git ls-remote origin HEAD > /dev/null 2>&1; then
        echo -e "   ${VERDE}🟢 Origin conectado${RESET}"
    else
        echo -e "   ${ROJO}🔴 No se puede conectar con origin${RESET}"
    fi

    # ------------------------------------------------------
    # FETCH
    # ------------------------------------------------------

    echo
    info "Comprobando ramas..."

    git fetch origin > /dev/null 2>&1

    # ------------------------------------------------------
    # TABLA DE RAMAS
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}🌿 ESTADO DE LAS RAMAS${RESET}"
    linea

    printf "   %-12s %-22s %-8s %-8s\n" \
        "RAMA" "ESTADO" "LOCAL" "REMOTO"

    echo

    for rama in "${RAMAS[@]}"
    do

        if ! rama_existe "$rama"; then

            printf "   %-12s ${ROJO}%-22s${RESET}\n" \
                "$rama" "❌ No existe"

            continue
        fi

        if ! remoto_existe "$rama"; then

            printf "   %-12s ${AMARILLO}%-22s${RESET}\n" \
                "$rama" "⚠️ Sin remoto"

            continue
        fi

        adelante=$(git rev-list --count "origin/$rama..$rama")
        atras=$(git rev-list --count "$rama..origin/$rama")

        # --------------------------------------------------
        # CAMBIOS LOCALES
        # --------------------------------------------------

        cambios=""

        if [ "$rama" = "$rama_actual" ]; then
            cambios=$(git status --porcelain)
        fi

        # --------------------------------------------------
        # DETERMINAR ESTADO
        # --------------------------------------------------

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

        printf "   %-12s %-22b +%-7s -%-7s\n" \
            "$rama" \
            "$estado" \
            "$adelante" \
            "$atras"

    done

    # ------------------------------------------------------
    # ÚLTIMO COMMIT
    # ------------------------------------------------------

    echo
    echo -e "${BLANCO}📝 ÚLTIMO COMMIT${RESET}"
    linea

    autor=$(git log -1 --format="%an")
    fecha=$(git log -1 --format="%ad" --date="format:%d/%m/%Y %H:%M")
    mensaje=$(git log -1 --format="%s")
    hash=$(git log -1 --format="%h")

    echo
    echo "   👤 Autor:   $autor"
    echo "   📅 Fecha:   $fecha"
    echo "   📝 Mensaje: $mensaje"
    echo "   🔑 Commit:  $hash"

    # ------------------------------------------------------
    # ESTADÍSTICAS RÁPIDAS
    # ------------------------------------------------------

    total_commits=$(git rev-list --all --count)
    autores=$(git log --all --format='%an' | sort -u | wc -l)

    echo
    echo -e "${BLANCO}📊 RESUMEN${RESET}"
    linea

    echo "   📝 Commits: $total_commits"
    echo "   👥 Autores: $autores"
    echo "   🌿 Ramas:   ${#RAMAS[@]}"

    # ------------------------------------------------------
    # AVISOS
    # ------------------------------------------------------

    echo

    avisos=0

    for rama in "${RAMAS[@]}"
    do

        if remoto_existe "$rama"; then

            adelante=$(git rev-list --count "origin/$rama..$rama")
            atras=$(git rev-list --count "$rama..origin/$rama")

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

    # ------------------------------------------------------
    # PIE
    # ------------------------------------------------------

    echo
    echo -e "${CIAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CIAN}║              Selecciona una opción                   ║${RESET}"
    echo -e "${CIAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
}


# ==========================================================
# MENU PRINCIPAL
# ==========================================================

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
            clear
            echo
            echo -e "${CIAN}👋 Hasta luego.${RESET}"
            echo
            exit 0
            ;;

        *)
            error "Opción no válida."
            sleep 1.5
            ;;

    esac

done


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
