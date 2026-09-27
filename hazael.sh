#!/bin/bash 
#========================================================== 
# INSTALADOR DE SCRIPTS MÚLTIPLES DE ASAEL 
# EDICIÓN DE SERVIDOR PREMIUM 
# 
# EDICIÓN SEGURA HTTPS / TLS 
#========================================================== 
set -o pipefail 
#========================================================= 
# COLORES 
#========================================================= 
REINICIAR="\e[0m" 
NEGRITA="\e[1m" 
ATENUADO="\e[2m" 
ROJO="\e[1;91m" 
VERDE="\e[1;92m" 
AMARILLO="\e[1;93m" 
AZUL="\e[1;94m" 
MAGENTA="\e[1;95m" 
CIAN="\e[1;96m" 
BLANCO="\e[1;97m" 
GRIS="\e[1;90m" 
ROSA="\e[38;5;213m" 
PÚRPURA="\e[38;5;141m" 
VIOLETA="\e[38;5;177m" 
CIELO="\e[38;5;117m" 
LIMA="\e[38;5;154m" 
ORO="\e[38;5;220m" 
NARANJA="\e[38;5;214m" 
AGUA="\e[38;5;159m" 
#========================================================== 
# VARIABLES PRINCIPALES 
#========================================================= 
BASE="/etc/asael" 
TMP="/tmp/asael_install" 
# SOLO HTTPS 
REPO="https://github.com/kevinaldaircama/multi-script.git" 
INSTALL_PROTOCOLS="ON" 
SERVER_DOMAIN="" 
SERVER_IP="" 
DOMAIN_IP="" 
DOMAIN_IP_MATCH="NO" 
DNS_PROVIDER="Desconocido" 
SSL_TUNNEL="OFF" 
PROXY_STATUS="OFF" 
CLIENT_IP="" 
OS_NAME="" 
HOSTNAME_VALUE="" 
DATE_NOW="" 
SSHD_CFG="/etc/ssh/sshd_config" 
#============================================================ 
# CONFIGURACIÓN DE CURL / TLS 
#========================================================== 
export CURL_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt" 
CURL_COMMON=( 
    --silent 
    --show-error 
    --location 
    --fail 
    --connect-timeout 7 
    --max-time 20 
    --retry 2 
    --retry-delay 1 
    --tlsv1.2 
    --proto '=https' 
) 
#========================================================== 
# LIMPIEZA 
#======================================================== 
cleanup() {
    rm -rf "$TMP" 
} 
trap cleanup EXIT 
#========================================================== 
# FUNCIONES VISUALES 
#========================================================= 
clear_screen() { 
    clear 2>/dev/null || true 
} 
linea() { 
    echo -e "${GRIS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" 
} 
linea_color() { 
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" 
} 
titulo() { 
    clear_screen 
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}" 
    echo -e "${CYAN}║${RESET} ${PINK}${BOLD} ASAEL MULTI SCRIPT${RESET} ${CYAN}║${RESET}" 
    echo -e "${CYAN}║${RESET} ${PURPLE}${BOLD} INSTALADOR PREMIUM v4.0${RESET} ${CYAN}║${RESET}" 
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}" 
    echo 
    echo -e "${CIELO} 🚀 SECURE EDITION 🚀${RESET}" 
    echo 
} 
sección() { 
    echo 
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${RESET}" 
    echo -e "${PURPLE}║${RESET} ${WHITE}${BOLD} $1${RESET}" 
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${RESET}" 
    echo 
} 
ok() { 
    echo -e " ${VERDE}✔${RESET} ${WHITE}$1${RESET}" 
} 
info() { 
    echo -e " ${CYAN}◆${RESET} ${WHITE}$1${RESET}" 
} 
warn() { 
    echo -e " ${AMARILLO}⚠${RESET} ${WHITE}$1${RESET}" 
} 
fail() { 
    echo -e " ${ROJO}✖${RESET} ${WHITE}$1${RESET}" 
} 
loading() { 
    local TEXT="$1" 
    echo -ne " ${CYAN}${TEXT}${RESET} " 
    for i in 1 2 3; do 
        echo -ne "${PURPLE}●${RESET}" 
        sleep 0.12 
    done 
    echo 
} 
pausa() { 
    sleep "${1:-1}" 
} 
error_exit() { 
    echo 
    echo -e "${ROJO}╔═══════════════════════════════════════════════════════════╗${RESET}" 
    echo -e "${ROJO}║${RESET} ${WHITE}${BOLD}❌ INSTALACIÓN DETENIDA${RESET}" 
    echo -e "${ROJO}╚═══════════════════════════════════════════════════════════╝${RESET}" 
    echo 
    echo -e " ${ROJO}✖${RESET} ${WHITE}$1${RESET}" 
    echo 
    cleanup 
    exit 1 
}
#========================================================== 
# VALIDAR URL HTTPS 
#========================================================== 
validate_https_url() { 
    local URL="$1" 
    if [[ "$URL" != https://* ]]; then 
        fail "URL insegura rechazada:" 
        echo -e " ${ROJO}$URL${RESET}" 
        return 1 
    fi 
    if [[ "$URL" =~ [[:space:]] ]]; then 
        fail "La URL contiene espacios." 
        return 1 
    fi 
    return 0 
} 
#============================================================ 
# RAÍZ 
#=========================================================== 
if [[ "$EUID" -ne 0 ]]; then 
    echo 
    echo -e "${ROJO}╔═══════════════════════════════════════════════════════════╗${RESET}" 
    echo -e "${ROJO}║${RESET} ${WHITE}${BOLD}🔒 PERMISOS ROOT NECESARIOS${RESET}" 
    echo -e "${ROJO}╚═══════════════════════════════════════════════════════════╝${RESET}" 
    echo 
    echo -e "${AMARILLO}Ejecuta:${RESET}" 
    echo 
    echo -e "${CYAN}sudo -i${RESET}" 
    echo 
    exit 1 
fi 
#============================================================= 
# SISTEMA OPERATIVO 
#=========================================================== 
if [[ ! -f /etc/os-release ]]; then 
    error_exit "No se pudo detectar el sistema operativo." 
fi 
source /etc/os-release 
if [[ "${ID:-}" != "ubuntu" ]]; then 
    error_exit "Este instalador solamente es compatible con Ubuntu." 
fi 
#============================================================= 
# VALIDAR URL PRINCIPAL 
#========================================================== 
validate_https_url "$REPO" || 
    error_exit "El repositorio no utiliza HTTPS." 
#============================================================ 
# CABECERA 
#================================================================= 
titulo 
echo -e "${VERDE} ● SISTEMA COMPATIBLE DETECTADO ●${RESET}" 
echo 
echo -e "${WHITE}Sistema : ${CIELO}${PRETTY_NAME}${RESET}" 
echo -e "${WHITE}Usuario : ${ORO}root${RESET}" 
echo -e "${WHITE}Proyecto:${MAGENTA}Asael Multi Script${RESET}" 
echo -e "${WHITE}Seguridad: ${VERDE}HTTPS / TLS 1.2+${RESET}" 
echo 
linea_color
#============================================================ 
# PASO 0 • DEPENDENCIAS 
#================================================================ 
sección "📦 PASO 0 • PREPARANDO EL SISTEMA" 
echo -e "${GRIS}Instalando las herramientas necesarias para Asael.${RESET}" 
echo 
export DEBIAN_FRONTEND=noninteractive 
loading "Actualizando repositorios" 
apt-get update -y >/dev/null 2>&1 || 
    error_exit "No se pueden actualizar los repositorios." 
ok "Repositorios actualizados." 
loading "Instalando dependencias" 
apt-get install -y \ 
    curl \ 
    wget \ 
    git \ 
    jq \ 
    ca-certificates \ 
    dnsutils \ 
    sudo \ 
    openssl \ 
    unzip \ 
    zip \ 
    tar \ 
    nano \ 
    cron \ 
    net-tools \ 
    lsof \ 
    screen \ 
    bc \ 
    socat \ 
    openssh-server \ 
    ufw \ 
    fail2ban \ 
    >/dev/null 2>&1 || 
    error_exit "No se pudieron instalar las dependencias." 
update-ca-certificates >/dev/null 2>&1 || true 
ok "Dependencias instaladas." 
#============================================================ 
# COMPROBAR HTTPS 
#================================================================= 
sección "🔐 PASO 1 • SEGURIDAD HTTPS" 
info "Verificando conexiones TLS..." 
ok "TLS/HTTPS operativo." 
info "Repositorio:" 
echo -e " ${VERDE}🔒 ${REPO}${RESET}" 
#=========================================================== 
# PASO 4 • DOMINIO 
#================================================================ 
sección "🌐 PASO 2 • CONFIGURACIÓN DE DOMINIO" 
loading "Detectando IP pública" 
SERVER_IP="$(curl "${CURL_COMMON[@]}" -4 https://api.ipify.org 2>/dev/null)" || true 
[[ -z "$SERVER_IP" ]] && SERVER_IP="$(hostname -I 2>/dev/null | awk '{print $1}')" 
[[ -z "$SERVER_IP" ]] && SERVER_IP="Desconocida" 
read -r -p "$(echo -e "${CYAN}🌐 Dominio del VPS (ENTER = usar IP ${SERVER_IP}):${RESET} ")" SERVER_DOMAIN 
SERVER_DOMAIN="$(printf '%s' "$SERVER_DOMAIN" | tr -d '[:space:]')" 
if [[ -z "$SERVER_DOMAIN" ]]; then 
    SERVER_DOMAIN="$SERVER_IP" 
    DOMAIN_MODE="IP" 
    ok "Sin dominio. Se utilizará la IP del VPS: $SERVER_IP" 
elif [[ "$SERVER_DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]] && [[ "$SERVER_DOMAIN" == *.* ]]; then 
    DOMAIN_MODE="DOMAIN" 
    ok "Dominio configurado: $SERVER_DOMAIN" 
else 
    warn "Dominio inválido. Se utilizará la IP del VPS: $SERVER_IP" 
    SERVER_DOMAIN="$SERVER_IP" 
    DOMAIN_MODE="IP" 
fi 
DOMAIN_IP_MATCH="NO" 
DNS_PROVIDER="Desconocido" 
loading "Comprobando DNS" 
DOMAIN_IP="" 
if [[ "${DOMAIN_MODE:-DOMAIN}" == "DOMAIN" ]]; then 
    DOMAIN_IP="$(dig +short A "$SERVER_DOMAIN" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)" 
fi 
if [[ -n "$DOMAIN_IP" && 
      "$DOMAIN_IP" == "$SERVER_IP" ]]; then 
    DOMAIN_IP_MATCH="YES" 
    ok "El dominio apunta correctamente al VPS." 
else 
    warn "El dominio todavía no apunta a este VPS." 
    [[ -n "$DOMAIN_IP" ]] && { 
        echo -e " ${GRIS}IP encontrado:${RESET} ${AMARILLO}$DOMAIN_IP${RESET}" 
        echo -e " ${GRIS}IP VPS:${RESET} ${CYAN}$SERVER_IP${RESET}" 
    } 
fi 
NS="$(dig +short NS "$SERVER_DOMAIN" | tr '\n' ' ')" 
if echo "$NS" | grep -qi "cloudflare"; then 
    DNS_PROVIDER="Cloudflare" 
elif echo "$NS" | grep -Eqi "awsdns|route53"; then 
    DNS_PROVIDER="AWS Route 53" 
elif echo "$NS" | grep -Eqi "google"; then 
    DNS_PROVIDER="Google Cloud DNS" 
elif echo "$NS" | grep -qi "azure"; then 
    DNS_PROVIDER="Azure DNS" 
elif echo "$NS" | grep -qi "namecheap"; then 
    DNS_PROVIDER="Namecheap" 
elif echo "$NS" | grep -qi "godaddy"; then 
    DNS_PROVIDER="GoDaddy" 
elif echo "$NS" | grep -qi "porkbun"; then 
    DNS_PROVIDER="Porkbun" 
fi 
echo 
echo -e " ${GRIS}Proveedor DNS:${RESET} ${CIELO}$DNS_PROVIDER${RESET}" 
#========================================================== 
# OPENSSH 
#================================================================ 
sección "🔒 PASO 3 • CONFIGURANDO SSH" 
loading "Activando OpenSSH" 
systemctl enable ssh >/dev/null 2>&1 || 
    error_exit "No se pudo habilitar OpenSSH." 
systemctl restart ssh >/dev/null 2>&1 || 
    error_exit "No se pudo iniciar OpenSSH." 
if systemctl is-active --quiet ssh; then 
    ok "OpenSSH activo." 
else 
    error_exit "OpenSSH no está activo." 
fi 
#========================================================== 
# REFUERZO DE SSH 
#========================================================= 
info "Aplicando protección SSH..." 
if [[ -f "$SSHD_CFG" ]]; then 
    cp "$SSHD_CFG" "${SSHD_CFG}.asael.backup" 
    sed -i \ 
        -e '/^[[:space:]]*#\?[[:space:]]*MaxAuthTries[[:space:]]/d' \ 
        -e '/^[[:space:]]*#\?[[:space:]]*ClientAliveInterval[[:space:]]/d' \ 
        -e '/^[[:space:]]*#\?[[:space:]]*ClientAliveCountMax[[:space:]]/d' \ 
        "$SSHD_CFG" 
    cat >> "$SSHD_CFG" <<'EOF' 
#======================================================== 
# Configuración SSH de Asael 
#================================================================= 
MaxAuthTries 3 
ClientAliveInterval 300 
ClientAliveCountMax 2 
EOF 
fi 
if sshd -t >/dev/null 2>&1; then 
    systemctl restart ssh 
    ok "Configuración SSH válida." 
else 
    fail "Error en la configuración SSH." 
    if [[ -f "${SSHD_CFG}.asael.backup" ]]; then 
        cp "${SSHD_CFG}.asael.backup" "$SSHD_CFG" 
        systemctl restart ssh 
        ok "Configuración SSH anterior restaurada." 
    fi 
fi 
#============================================================ 
# FAIL2BAN 
#================================================================= 
sección "🛡️ PASO 4 • PROTECCIÓN FAIL2BAN" 
mkdir -p /etc/fail2ban 
cat > /etc/fail2ban/jail.local <<'EOF' 
[DEFAULT] 
bantime = 1h 
findtime = 10m 
maxretry = 3 
[sshd] 
enabled = true 
port = ssh 
backend = systemd 
EOF 
systemctl enable fail2ban >/dev/null 2>&1 || true 
systemctl restart fail2ban >/dev/null 2>&1 || true 
if systemctl is-active --quiet fail2ban; then 
    ok "Fail2Ban activo." 
else 
    warn "Fail2Ban no pudo iniciarse." 
fi
#============================================================ 
# FIREWALL 
#================================================================ 
sección "🔥 PASO 5 • CONFIGURANDO FIREWALL" 
info "Restableciendo reglas UFW..." 
ufw --force reset >/dev/null 2>&1 || true 
ufw default deny incoming >/dev/null 2>&1 
ufw default allow outgoing >/dev/null 2>&1 
# SSH 
ufw allow 22/tcp >/dev/null 2>&1 
# Web 
ufw allow 80/tcp >/dev/null 2>&1 
ufw allow 443/tcp >/dev/null 2>&1 
# OpenVPN TCP 
ufw allow 1194/tcp >/dev/null 2>&1 
# Activar 
ufw --force enable >/dev/null 2>&1 || 
    warn "No se pudo activar UFW." 
if ufw status | grep -q "Status: active"; then 
    ok "Firewall activo." 
else 
    warn "UFW no está activo." 
fi 
#============================================================ 
# DESCARGAR ASAEL 
#================================================================ 
sección "📥 PASO 6 • INSTALANDO ASAEL" 
rm -rf "$TMP" 
mkdir -p "$TMP" 
validate_https_url "$REPO" || 
    error_exit "Repositorio inseguro." 
loading "Descargando repositorio mediante HTTPS" 
git config --global protocol.version 2 
if ! git clone \ 
    --depth 1 \ 
    "$REPO" \ 
    "$TMP" >/dev/null 2>&1; then 
    error_exit "No se pudieron descargar los archivos mediante HTTPS." 
fi 
ok "Repositorio descargado mediante HTTPS." 
#============================================================ 
# COMPROBAR CONTENIDO 
#=========================================================== 
if [[ ! -d "$TMP" ]]; then 
    error_exit "El repositorio descargado está vacío." 
fi 
if [[ ! -f "$TMP/menu.sh" ]]; then 
    warn "No se encontró menu.sh en el repositorio." 
fi 
#============================================================ 
# INSTALAR ARCHIVOS 
#=========================================================== 
mkdir -p "$BASE" 
cp -a "$TMP"/. "$BASE"/ || 
    error_exit "No se pudieron copiar los archivos." 
mkdir -p \ 
    "$BASE/protocolos" \ 
    "$BASE/usuarios" \ 
    "$BASE/sistema" \ 
    "$BASE/logs" \ 
    "$BASE/herramientas" 
if [[ -d "$TMP/telegram" ]]; then 
    mkdir -p "$BASE/telegram" 
    cp -a "$TMP/telegram"/. "$BASE/telegram"/ 
    rm -f "$BASE/telegram/README.md" "$BASE/telegram/health.sh" "$BASE/telegram/service.sh" "$BASE/telegram/setup.sh" "$BASE/telegram/update.sh" 
fi 
#========================================================== 
# PERMISOS CORRECTOS 
#========================================================= 
find "$BASE" \ 
    -type d \ 
    -exec chmod 755 {} \; 
find "$BASE" \ 
    -type f \ 
    -name "*.sh" \ 
    -exec chmod 755 {} \; 
ok "Archivos instalados." 
#============================================================ 
# CONFIGURACIÓN PRINCIPAL 
#================================================================ 
sección "⚙️ PASO 7 • CONFIGURACIÓN PRINCIPAL" 
cat > "$BASE/config.conf" <<EOF 
#============================================================ 
# ASAEL MULTI SCRIPT 
# CONFIGURACIÓN 
#========================================================== 
SERVER_DOMAIN="$SERVER_DOMAIN" 
SERVER_IP="$SERVER_IP" 
DOMAIN_MODE="${DOMAIN_MODE:-DOMAIN}" 
DNS_PROVIDER="$DNS_PROVIDER" 
DOMAIN_IP_MATCH="$DOMAIN_IP_MATCH" 
SSL_TUNNEL="OFF" 
PROXY_STATUS="OFF" 
AUTO_START=OFF 
#======================================================== 
# SEGURIDAD 
#========================================================= 
HTTPS_ONLY="ON" 
TLS_MIN_VERSION="1.2" 
#========================================================= 
# PROTOCOLOS 
#========================================================= 
OPENSSH=ON 
DROPBEAR=OFF 
SSL=OFF 
BADVPN=OFF 
UDP_CUSTOM=OFF 
HYSTERIA=OFF 
XRAY=OFF 
V2RAY=OFF 
OPENVPN=OFF 
BHTTP=OFF 
ZIPVPN=OFF 
WEBSOCKET=OFF 
TROJAN=OFF 
SHADOWSOCKS=OFF 
SOCKS5=OFF 
#========================================================== 
# SISTEMA 
#========================================================= 
SYSTEMDNS=OFF 
SQUID=OFF 
WEBMIN=OFF 
FAIL2BAN=ON 
BBR=OFF 
EOF 
chmod 600 "$BASE/config.conf" 
ok "Configuración segura creada." 
#========================================================== 
# COMANDO MENU 
#========================================================== 
cat > /usr/local/bin/menu <<'EOF' 
#!/bin/bash 
BASE="/etc/asael" 
if [[ -f "$BASE/menu.sh" ]]; then 
    exec bash "$BASE/menu.sh" "$@" 
fi 
echo "❌ No se encontró $BASE/menu.sh" 
exit 1 
EOF 
chmod 755 /usr/local/bin/menu 
ok "Comando 'menu' instalado." 
#============================================================ 
# PASO 8 • ACCESO RAÍZ 
#================================================================ 
sección "👑 PASO 8 • ACCESO ROOT" 
echo -e "${WHITE}¿Deseas establecer una contraseña para root?${RESET}" 
echo 
echo -e "${VERDE}Y${RESET} = Establecer contraseña" 
echo -e "${ROJO}N${RESET} = Continuar sin habilitar root por contraseña" 
echo 
read -r -p \ 
    "$(echo -e "${ORO}[Y/N]:${RESET} ")" \ 
    ROOT_ACCESS 
ROOT_ACCESS="$(printf '%s' "$ROOT_ACCESS" | tr '[:upper:]' '[:lower:]')" 
if [[ "$ROOT_ACCESS" == "y" ]]; then 
    echo 
    passwd root 
    if [[ $? -eq 0 ]]; then 
        if [[ -f "$SSHD_CFG" ]]; then 
            sed -i \ 
                -e '/^[[:space:]]*#\?[[:space:]]*PermitRootLogin[[:space:]]/d' \ 
                -e '/^[[:space:]]*#\?[[:space:]]*PasswordAuthentication[[:space:]]/d' \ 
                "$SSHD_CFG" 
            cat >> "$SSHD_CFG" <<'EOF' 
#========================================================== 
# Acceso root de Asael 
#========================================================== 
PermitRootLogin yes 
PasswordAuthentication yes 
EOF 
            if sshd -t >/dev/null 2>&1; then 
                systemctl restart ssh 
                ok "Acceso root habilitado." 
            else 
                fail "La configuración SSH no es válida." 
            fi 
        fi 
    else 
        fail "No se pudo cambiar la contraseña." 
    fi 
else 
    info "Root por contraseña no fue habilitada." 
fi 
#============================================================ 
# FUNCIÓN GENERAL DE MÓDULOS 
#================================================================= 
sección "🚀 PASO 9 • INSTALACIÓN DE PROTOCOLOS" 
echo -e "${WHITE}Instalando los módulos disponibles.${RESET}" 
echo 
instalar_modulo() { 
    local NOMBRE="$1" 
    local ARCHIVO="$2" 
    local VARIABLE="$3" 
    echo 
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${RESET}" 
    echo -e "${PURPLE}║${RESET} ${WHITE}${BOLD}📦 $NOMBRE${RESET}" 
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${RESET}" 
    echo 
    if [[ ! -f "$ARCHIVO" ]]; then 
        warn "$NOMBRE no encontrado." 
        echo -e " ${GRIS}Archivo:${RESET} $ARCHIVO" 
        return 2 
    fi 
    chmod 755 "$ARCHIVO" 
    info "Ejecutando modo automático..." 
    if bash "$ARCHIVO" --auto; then 
        if [[ -n "$VARIABLE" ]] && 
           grep -q "^${VARIABLE}=ON" "$BASE/config.conf" 2>/dev/null; then 
            ok "$NOMBRE instalado correctamente." 
        else 
            ok "$NOMBRE finalizó correctamente." 
        fi 
        return 0 
    fi 
    fail "$NOMBRE terminó con errores." 
    return 1 
} 
#========================================================== 
# OPENSSH 
#========================================================= 
echo 
info "Verificando OpenSSH..." 
if systemctl is-active --quiet ssh; then 
    sed -i \ 
        's/^OPENSSH=.*/OPENSSH=ON/' \ 
        "$BASE/config.conf" 
    ok "OpenSSH instalado correctamente." 
else 
    sed -i \ 
        's/^OPENSSH=.*/OPENSSH=OFF/' \ 
        "$BASE/config.conf" 
    fail "OpenSSH no está activo." 
fi 
#============================================================ 
# DROPBEAR 
#=========================================================== 
instalar_modulo \ 
    "Dropbear" \ 
    "$BASE/protocolos/dropbear.sh" \ 
    "DROPBEAR" 
#========================================================= 
# TÚNEL SSL 
#=========================================================== 
instalar_modulo \ 
    "SSL Tunnel" \ 
    "$BASE/protocolos/ssl.sh" \ 
    "SSL" 
#======================================================== 
# XRAY / V2RAY 
#========================================================== 
XRAY_SCRIPT="" 
if [[ -f "$BASE/protocolos/xray.sh" ]]; then 
    XRAY_SCRIPT="$BASE/protocolos/xray.sh" 
elif [[ -f "$BASE/protocolos/v2ray.sh" ]]; then 
    XRAY_SCRIPT="$BASE/protocolos/v2ray.sh" 
fi 
if [[ -n "$XRAY_SCRIPT" ]]; then 
    instalar_modulo \ 
        "Xray / VMess" \ 
        "$XRAY_SCRIPT" \ 
        "XRAY" 
else 
    warn "No se encontró xray.sh ni v2ray.sh." 
fi 
#============================================================ 
# UDP PERSONALIZADO 
#========================================================== 
instalar_modulo \ 
    "UDP Custom" \ 
    "$BASE/protocolos/udpcustom.sh" \ 
    "UDP_CUSTOM" 
#============================================================ 
# BADVPN 
#================================================================= 
instalar_modulo \ 
    "BadVPN UDPGW" \ 
    "$BASE/protocolos/badvpn.sh" \ 
    "BADVPN" 
#============================================================ 
# ZIVPN 
#========================================================== 
instalar_modulo \ 
    "ZiVPN" \ 
    "$BASE/protocolos/zivpn.sh" \ 
    "ZIPVPN" 
#======================================================== 
# OPENVPN 
#========================================================== 
instalar_modulo \ 
    "OpenVPN" \ 
    "$BASE/protocolos/openvpn.sh" \ 
    "OPENVPN" 
#========================================================== 
# BHTTP 
#=========================================================== 
instalar_modulo \ 
    "BHTTP" \ 
    "$BASE/protocolos/bhttp.sh" \ 
    "BHTTP" 
#======================================================== 
# ESTADO DE PROTOCOLOS 
#================================================================= 
sección "📊 ESTADO DE PROTOCOLOS" 
show_protocol() { 
    local NAME="$1" 
    local VAR="$2" 
    local VALUE 
    VALUE="$( \
        grep "^${VAR}=" "$BASE/config.conf" 2>/dev/null | \
        cut -d '=' -f2 | \
        tr -d '"' \
    )" 
    if [[ "$VALUE" == "ON" ]]; then 
        echo -e " ${VERDE}●${RESET} ${WHITE}${NAME}:${RESET} ${VERDE}ACTIVO${RESET}" 
    else 
        echo -e " ${GRIS}○${RESET} ${WHITE}${NAME}:${RESET} ${GRIS}NO INSTALADO${RESET}" 
    fi 
} 
show_protocol "OpenSSH" "OPENSSH" 
show_protocol "Dropbear" "DROPBEAR" 
show_protocol "SSL Tunnel" "SSL" 
show_protocol "UDP Custom" "UDP_CUSTOM" 
show_protocol "BadVPN" "BADVPN" 
show_protocol "ZiVPN" "ZIPVPN" 
show_protocol "Xray" "XRAY" 
show_protocol "OpenVPN" "OPENVPN" 
#========================================================= 
# BANNER SSH 
#========================================================= 
sección "🎨 PASO 10 • CONFIGURANDO BANNER" 
cat > /etc/profile.d/asael-banner.sh <<'EOF' 
#!/bin/bash 
[[ $- != *i* ]] && return 
BASE="/etc/asael" 
CONFIG="$BASE/config.conf" 
CYAN="\e[1;96m" 
GREEN="\e[1;92m" 
RED="\e[1;91m" 
YELLOW="\e[1;93m" 
MAGENTA="\e[1;95m" 
PINK="\e[38;5;213m" 
PURPLE="\e[38;5;141m" 
SKY="\e[38;5;117m" 
WHITE="\e[1;97m" 
GRAY="\e[1;90m" 
RESET="\e[0m" 
SERVER="$(hostname)" 
DOMAIN="-" 
if [[ -f "$CONFIG" ]]; then 
    source "$CONFIG" 2>/dev/null 
    DOMAIN="${SERVER_DOMAIN:--}" 
fi 
UPTIME="$(uptime -p 2>/dev/null | sed 's/up //')" 
FECHA="$(date '+%d-%m-%Y')" 
HORA="$(date '+%H:%M:%S')" 
RAM="$(free -h 2>/dev/null | awk '/Mem:/ {print $3 "/" $2}')" 
CARGA="$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | sed 's/^ //')" 
echo 
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}" 
echo -e "${CYAN}║${RESET} ${PINK}${BOLD} 🚀 ASAEL MULTI SCRIPT 🚀${RESET} ${CYAN}║${RESET}" 
echo -e "${CYAN}║${RESET} ${PURPLE} SERVIDOR SEGURO${RESET} ${CYAN}║${RESET}" 
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}" 
echo 
echo -e "${CYAN}┌────────────────── SERVIDOR ──────────────────┐${RESET}" 
echo -e " ${WHITE}🖥 Servidor :${RESET} ${SKY}$SERVER${RESET}" 
echo -e " ${WHITE}🌐 Dominio :${RESET} ${MAGENTA}$DOMAIN${RESET}" 
echo -e " ${WHITE}🔐 HTTPS :${RESET} ${GREEN}ACTIVO${RESET}" 
echo -e " ${WHITE}⏱ Tiempo de actividad :${RESET} ${GREEN}${UPTIME:-Desconocido}${RESET}" 
echo -e " ${WHITE}💾 RAM :${RESET} ${GREEN}${RAM:-Desconocida}${RESET}" 
echo -e " ${WHITE}⚡ Carga :${RESET} ${YELLOW}${CARGA:-Desconocida}${RESET}" 
echo -e " ${WHITE}📅 Fecha :${RESET} ${YELLOW}$FECHA${RESET}" 
echo -e " ${WHITE}🕐 Hora :${RESET} ${CYAN}$HORA${RESET}" 
echo -e "${CYAN}└─────────────────────────────────────────────┘${RESET}" 
echo 
echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${RESET}" 
echo -e "${PURPLE}║${RESET} ${WHITE}${BOLD} ⭐ CRÉDITOS ⭐${RESET} ${PURPLE}║${RESET}" 
echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════╣${RESET}" 
echo -e "${PURPLE}║${RESET} ${GRAY}Proyecto :${RESET} ${PINK}Asael Multi Script${RESET}" 
echo -e "${PURPLE}║${RESET} ${GRAY}Autor :${RESET} ${WHITE}Asael${RESET}" 
echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${RESET}" 
echo 
EOF 
chmod 755 /etc/profile.d/asael-banner.sh 
ok "Banner configurado." 
echo 
linea_color 
echo -e "${VERDE} ¡INSTALACIÓN COMPLETADA CON ÉXITO!${RESET}" 
linea_color 
echo -e "${WHITE}Escribe ${CYAN}menu${WHITE} para abrir el panel de control.${RESET}" 
echo
