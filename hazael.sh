#!/bin/bash

#=========================================================
#        KEVINTECH MULTI SCRIPT INSTALLER
#        LICENSE SYSTEM v4.0 (BYPASSED / SIN KEY)
#        PREMIUM SERVER EDITION
#
#        HTTPS / TLS SECURE EDITION
#=========================================================

set -o pipefail

#=========================================================
# COLORES
#=========================================================

RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

RED="\e[1;91m"
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
BLUE="\e[1;94m"
MAGENTA="\e[1;95m"
CYAN="\e[1;96m"
WHITE="\e[1;97m"
GRAY="\e[1;90m"

PINK="\e[38;5;213m"
PURPLE="\e[38;5;141m"
VIOLET="\e[38;5;177m"
SKY="\e[38;5;117m"
LIME="\e[38;5;154m"
GOLD="\e[38;5;220m"
ORANGE="\e[38;5;214m"
AQUA="\e[38;5;159m"

#=========================================================
# VARIABLES PRINCIPALES
#=========================================================

BASE="/etc/kevintech"
TMP="/tmp/kevintech_install"

REPO="https://github.com/kevinaldaircama/multi-script.git"

INSTALL_PROTOCOLS="ON"

SERVER_DOMAIN=""
SERVER_IP=""
DOMAIN_IP=""
DOMAIN_IP_MATCH="NO"
DNS_PROVIDER="Desconocido"

SSL_TUNNEL="OFF"
PROXY_STATUS="OFF"

# VALORES FIJOS SIN KEY
LICENSE_OWNER="Hazael Moreno"
LICENSE_RESELLER="Directo"
LICENSE_TYPE="unlimited"
LICENSE_DELETE_AT="Indefinido"
LICENSE_BOT="@multiscriptkeygen_bot"

CLIENT_IP=""
OS_NAME=""
HOSTNAME_VALUE=""
DATE_NOW=""

SSHD_CFG="/etc/ssh/sshd_config"

#=========================================================
# CONFIGURACIÓN DE CURL / TLS
#=========================================================

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

#=========================================================
# LIMPIEZA
#=========================================================

cleanup() {
    rm -rf "$TMP"
}

trap cleanup EXIT

#=========================================================
# FUNCIONES VISUALES
#=========================================================

clear_screen() {
    clear 2>/dev/null || true
}

linea() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

linea_color() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

titulo() {

    clear_screen

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${PINK}${BOLD}                 KEVINTECH MULTI SCRIPT${RESET}              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} ${PURPLE}${BOLD}                 PREMIUM INSTALLER v4.0${RESET}              ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

    echo
    echo -e "${SKY}              🚀  S E C U R E   E D I T I O N  🚀${RESET}"
    echo

}

seccion() {

    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PURPLE}║${RESET} ${WHITE}${BOLD} $1${RESET}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

}

ok() {
    echo -e " ${GREEN}✔${RESET} ${WHITE}$1${RESET}"
}

info() {
    echo -e " ${CYAN}◆${RESET} ${WHITE}$1${RESET}"
}

warn() {
    echo -e " ${YELLOW}⚠${RESET} ${WHITE}$1${RESET}"
}

fail() {
    echo -e " ${RED}✖${RESET} ${WHITE}$1${RESET}"
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
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET} ${WHITE}${BOLD}❌ INSTALACIÓN DETENIDA${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e " ${RED}✖${RESET} ${WHITE}$1${RESET}"
    echo

    cleanup

    exit 1
}

#=========================================================
# VALIDAR URL HTTPS
#=========================================================

validate_https_url() {

    local URL="$1"

    if [[ "$URL" != https://* ]]; then
        fail "URL insegura rechazada:"
        echo -e " ${RED}$URL${RESET}"
        return 1
    fi

    if [[ "$URL" =~ [[:space:]] ]]; then
        fail "La URL contiene espacios."
        return 1
    fi

    return 0
}

#=========================================================
# ROOT
#=========================================================

if [[ "$EUID" -ne 0 ]]; then

    echo
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET} ${WHITE}${BOLD}🔒 PERMISOS ROOT NECESARIOS${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    echo -e "${YELLOW}Ejecuta:${RESET}"
    echo
    echo -e "${CYAN}sudo -i${RESET}"
    echo

    exit 1
fi

#=========================================================
# SISTEMA OPERATIVO
#=========================================================

if [[ ! -f /etc/os-release ]]; then
    error_exit "No se pudo detectar el sistema operativo."
fi

source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
    error_exit "Este instalador solamente es compatible con Ubuntu."
fi

#=========================================================
# VALIDAR REPO
#=========================================================

validate_https_url "$REPO" ||
    error_exit "El repositorio no utiliza HTTPS."

#=========================================================
# CABECERA
#=========================================================

titulo

echo -e "${GREEN}             ● SISTEMA COMPATIBLE DETECTADO ●${RESET}"
echo

echo -e "${WHITE}Sistema : ${SKY}${PRETTY_NAME}${RESET}"
echo -e "${WHITE}Usuario : ${GOLD}root${RESET}"
echo -e "${WHITE}Proyecto: ${MAGENTA}KevinTech Multi Script${RESET}"
echo -e "${WHITE}Modo    : ${GREEN}Sin Key / Acceso Libre${RESET}"

echo
linea_color

#=========================================================
# PASO 0
# DEPENDENCIAS
#=========================================================

seccion "📦 PASO 0  •  PREPARANDO EL SISTEMA"

echo -e "${GRAY}Instalando las herramientas necesarias para KevinTech.${RESET}"
echo

export DEBIAN_FRONTEND=noninteractive

loading "Actualizando repositorios"

apt-get update -y >/dev/null 2>&1 ||
    error_exit "No se pudieron actualizar los repositorios."

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

#=========================================================
# PASO 1 Y 2 (OMITIDOS / BYPASS DE LICENCIA)
#=========================================================

seccion "🔑 PASO 1  •  CONFIGURACIÓN DE ACCESO"

ok "Sistema configurado en modo libre (sin restricciones de Key)."
ok "Propietario asignado: $LICENSE_OWNER"

#=========================================================
# PASO 4
# DOMINIO
#=========================================================

seccion "🌐 PASO 2  •  CONFIGURACIÓN DE DOMINIO"

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

if [[ -n "$DOMAIN_IP" && "$DOMAIN_IP" == "$SERVER_IP" ]]; then
    DOMAIN_IP_MATCH="YES"
    ok "El dominio apunta correctamente al VPS."
else
    warn "El dominio todavía no apunta a este VPS."
    [[ -n "$DOMAIN_IP" ]] && {
        echo -e " ${GRAY}IP encontrada:${RESET} ${YELLOW}$DOMAIN_IP${RESET}"
        echo -e " ${GRAY}IP VPS:${RESET} ${CYAN}$SERVER_IP${RESET}"
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

echo -e " ${GRAY}Proveedor DNS:${RESET} ${SKY}$DNS_PROVIDER${RESET}"

#=========================================================
# PASO 5
# OPENSSH
#=========================================================

seccion "🔒 PASO 3  •  CONFIGURANDO SSH"

loading "Activando OpenSSH"

systemctl enable ssh >/dev/null 2>&1 || error_exit "No se pudo habilitar OpenSSH."
systemctl restart ssh >/dev/null 2>&1 || error_exit "No se pudo iniciar OpenSSH."

if systemctl is-active --quiet ssh; then
    ok "OpenSSH activo."
else
    error_exit "OpenSSH no está activo."
fi

#=========================================================
# SSH HARDENING
#=========================================================

info "Aplicando protección SSH..."

if [[ -f "$SSHD_CFG" ]]; then
    cp "$SSHD_CFG" "${SSHD_CFG}.kevintech.backup"
    sed -i \
        -e '/^[[:space:]]*#\?[[:space:]]*MaxAuthTries[[:space:]]/d' \
        -e '/^[[:space:]]*#\?[[:space:]]*ClientAliveInterval[[:space:]]/d' \
        -e '/^[[:space:]]*#\?[[:space:]]*ClientAliveCountMax[[:space:]]/d' \
        "$SSHD_CFG"

    cat >> "$SSHD_CFG" <<'EOF'

#=========================================================
# KevinTech SSH configuration
#=========================================================

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
    if [[ -f "${SSHD_CFG}.kevintech.backup" ]]; then
        cp "${SSHD_CFG}.kevintech.backup" "$SSHD_CFG"
        systemctl restart ssh
        ok "Configuración SSH anterior restaurada."
    fi
fi

#=========================================================
# FAIL2BAN
#=========================================================

seccion "🛡️ PASO 4  •  PROTECCIÓN FAIL2BAN"

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

#=========================================================
# FIREWALL
#=========================================================

seccion "🔥 PASO 5  •  CONFIGURANDO FIREWALL"

info "Restableciendo reglas UFW..."

ufw --force reset >/dev/null 2>&1 || true
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

ufw allow 22/tcp >/dev/null 2>&1
ufw allow 80/tcp >/dev/null 2>&1
ufw allow 443/tcp >/dev/null 2>&1
ufw allow 53/udp >/dev/null 2>&1
ufw allow 1194/tcp >/dev/null 2>&1

ufw --force enable >/dev/null 2>&1 || warn "No se pudo activar UFW."

if ufw status | grep -q "Status: active"; then
    ok "Firewall activo."
else
    warn "UFW no está activo."
fi

#=========================================================
# PASO 8
# DESCARGAR KEVINTECH
#=========================================================

seccion "📥 PASO 6  •  INSTALANDO KEVINTECH"

rm -rf "$TMP"
mkdir -p "$TMP"

validate_https_url "$REPO" || error_exit "Repositorio inseguro."

loading "Descargando repositorio mediante HTTPS"

git config --global protocol.version 2

if ! git clone --depth 1 "$REPO" "$TMP" >/dev/null 2>&1; then
    error_exit "No se pudieron descargar los archivos mediante HTTPS."
fi

ok "Repositorio descargado mediante HTTPS."

if [[ ! -d "$TMP" ]]; then
    error_exit "El repositorio descargado está vacío."
fi

mkdir -p "$BASE"
cp -a "$TMP"/. "$BASE"/ || error_exit "No se pudieron copiar los archivos."

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

find "$BASE" -type d -exec chmod 755 {} \;
find "$BASE" -type f -name "*.sh" -exec chmod 755 {} \;

ok "Archivos instalados."

#=========================================================
# CONFIGURACIÓN PRINCIPAL
#=========================================================

seccion "⚙️ PASO 7  •  CONFIGURACIÓN PRINCIPAL"

cat > "$BASE/config.conf" <<EOF
#=========================================================
# KEVINTECH MULTI SCRIPT
# CONFIGURATION (BYPASSED)
#=========================================================

SERVER_DOMAIN="$SERVER_DOMAIN"
SERVER_IP="$SERVER_IP"
DOMAIN_MODE="${DOMAIN_MODE:-DOMAIN}"

DNS_PROVIDER="$DNS_PROVIDER"
DOMAIN_IP_MATCH="$DOMAIN_IP_MATCH"

SSL_TUNNEL="OFF"
PROXY_STATUS="OFF"

AUTO_START=OFF

HTTPS_ONLY="ON"
TLS_MIN_VERSION="1.2"

LICENSE_API="LOCAL"
LICENSE_OWNER="$LICENSE_OWNER"
LICENSE_RESELLER="$LICENSE_RESELLER"
LICENSE_TYPE="$LICENSE_TYPE"
LICENSE_DELETE_AT="$LICENSE_DELETE_AT"

OPENSSH=ON
DROPBEAR=OFF
SSL=OFF
BADVPN=OFF
UDP_CUSTOM=OFF
HYSTERIA=OFF
SLOWDNS=OFF
XRAY=OFF
V2RAY=OFF
OPENVPN=OFF
BHTTP=OFF
ZIPVPN=OFF
WEBSOCKET=OFF
TROJAN=OFF
SHADOWSOCKS=OFF
SOCKS5=OFF

SYSTEMDNS=OFF
SQUID=OFF
WEBMIN=OFF
FAIL2BAN=ON
BBR=OFF
EOF

chmod 600 "$BASE/config.conf"

#=========================================================
# LICENSE CONF
#=========================================================

cat > "$BASE/license.conf" <<EOF
LICENSE_OWNER="$LICENSE_OWNER"
LICENSE_RESELLER="$LICENSE_RESELLER"
LICENSE_TYPE="$LICENSE_TYPE"
LICENSE_DELETE_AT="$LICENSE_DELETE_AT"

LICENSE_API="LOCAL"
LICENSE_STATUS="VALIDATED"
LICENSE_BOT="$LICENSE_BOT"

HTTPS_ONLY="ON"
TLS_MIN_VERSION="1.2"
EOF

chmod 600 "$BASE/license.conf"

ok "Configuración segura creada."

#=========================================================
# COMANDO MENU
#=========================================================

cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash

BASE="/etc/kevintech"

if [[ -f "$BASE/menu.sh" ]]; then
    exec bash "$BASE/menu.sh" "$@"
fi

echo "❌ No se encontró $BASE/menu.sh"
exit 1
EOF

chmod 755 /usr/local/bin/menu

ok "Comando 'menu' instalado."

#=========================================================
# PASO 10
# ACCESO ROOT
#=========================================================

seccion "👑 PASO 8  •  ACCESO ROOT"

echo -e "${WHITE}¿Deseas establecer una contraseña para root?${RESET}"
echo
echo -e "${GREEN}Y${RESET} = Establecer contraseña"
echo -e "${RED}N${RESET} = Continuar sin habilitar root por contraseña"
echo

read -r -p "$(echo -e "${GOLD}[Y/N]:${RESET} ")" ROOT_ACCESS
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
    info "Root por contraseña no fue habilitado."
fi

#=========================================================
# MÓDULOS
#=========================================================

seccion "🚀 PASO 9  •  INSTALACIÓN DE PROTOCOLOS"

instalar_modulo() {
    local NOMBRE="$1"
    local ARCHIVO="$2"
    local VARIABLE="$3"

    if [[ ! -f "$ARCHIVO" ]]; then
        return 2
    fi

    chmod 755 "$ARCHIVO"
    info "Instalando $NOMBRE..."

    if bash "$ARCHIVO" --auto >/dev/null 2>&1; then
        ok "$NOMBRE instalado."
        return 0
    fi
    return 1
}

if systemctl is-active --quiet ssh; then
    sed -i 's/^OPENSSH=.*/OPENSSH=ON/' "$BASE/config.conf"
fi

instalar_modulo "Dropbear" "$BASE/protocolos/dropbear.sh" "DROPBEAR"
instalar_modulo "SSL Tunnel" "$BASE/protocolos/ssl.sh" "SSL"

XRAY_SCRIPT=""
[[ -f "$BASE/protocolos/xray.sh" ]] && XRAY_SCRIPT="$BASE/protocolos/xray.sh"
[[ -f "$BASE/protocolos/v2ray.sh" ]] && XRAY_SCRIPT="$BASE/protocolos/v2ray.sh"
[[ -n "$XRAY_SCRIPT" ]] && instalar_modulo "Xray / VMess" "$XRAY_SCRIPT" "XRAY"

instalar_modulo "UDP Custom" "$BASE/protocolos/udpcustom.sh" "UDP_CUSTOM"
instalar_modulo "BadVPN UDPGW" "$BASE/protocolos/badvpn.sh" "BADVPN"
instalar_modulo "ZiVPN" "$BASE/protocolos/zivpn.sh" "ZIPVPN"
instalar_modulo "SlowDNS" "$BASE/protocolos/slowdns.sh" "SLOWDNS"
instalar_modulo "OpenVPN" "$BASE/protocolos/openvpn.sh" "OPENVPN"
instalar_modulo "BHTTP" "$BASE/protocolos/bhttp.sh" "BHTTP"

#=========================================================
# BANNER SSH
#=========================================================

seccion "🎨 PASO 10  •  CONFIGURANDO BANNER"

cat > /etc/profile.d/kevintech-banner.sh <<'EOF'
#!/bin/bash
[[ $- != *i* ]] && return

BASE="/etc/kevintech"
CONFIG="$BASE/config.conf"

CYAN="\e[1;96m"
GREEN="\e[1;92m"
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

echo
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET} ${PINK}${BOLD}             🚀 KEVINTECH MULTI SCRIPT 🚀${RESET}           ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET} ${PURPLE}                 SECURE SERVER (FREE MODE) ${RESET}          ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo
echo -e " ${WHITE}🖥 Servidor :${RESET} ${SKY}$SERVER${RESET}"
echo -e " ${WHITE}🌐 Dominio  :${RESET} ${MAGENTA}$DOMAIN${RESET}"
echo -e " ${WHITE}⚡ Panel    :${RESET} ${GREEN}menu${RESET}"
echo
EOF

chmod 755 /etc/profile.d/kevintech-banner.sh

seccion "🎉 INSTALACIÓN COMPLETADA"
echo -e "${GREEN}¡El script se ha instalado con éxito sin requerir ninguna Key!${RESET}"
echo -e "Escribe ${CYAN}${BOLD}menu${RESET} para abrir el panel de control de tu servidor."
echo
