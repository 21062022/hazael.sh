#!/bin/bash

#=========================================================
#        HAZAEL MORENO MULTI SCRIPT INSTALLER
#        LICENSE SYSTEM v4.0 (BYPASSED / FREE MODE)
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
SKY="\e[38;5;117m"
GOLD="\e[38;5;220m"

#=========================================================
# VARIABLES PRINCIPALES
#=========================================================

BASE="/etc/kevintech"
TMP="/tmp/kevintech_install"

REPO="https://github.com/21062022/hazael.sh.git"

SERVER_DOMAIN=""
SERVER_IP=""
DOMAIN_IP=""
DOMAIN_IP_MATCH="NO"
DNS_PROVIDER="Desconocido"

LICENSE_OWNER="Hazael Moreno"
LICENSE_RESELLER="Directo"
LICENSE_TYPE="unlimited"
LICENSE_DELETE_AT="Indefinido"
LICENSE_BOT="@multiscriptkeygen_bot"

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

linea_color() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

titulo() {
    clear_screen
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${PINK}${BOLD}              HAZAEL MORENO MULTI SCRIPT${RESET}            ${CYAN}║${RESET}"
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

validate_https_url() {
    local URL="$1"
    if [[ "$URL" != https://* ]]; then
        fail "URL insegura rechazada:"
        echo -e " ${RED}$URL${RESET}"
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

validate_https_url "$REPO" || error_exit "El repositorio no utiliza HTTPS."

titulo

echo -e "${GREEN}             ● SISTEMA COMPATIBLE DETECTADO ●${RESET}"
echo
echo -e "${WHITE}Sistema : ${SKY}${PRETTY_NAME}${RESET}"
echo -e "${WHITE}Usuario : ${GOLD}root${RESET}"
echo -e "${WHITE}Proyecto: ${MAGENTA}Hazael Moreno Multi Script${RESET}"
echo -e "${WHITE}Modo    : ${GREEN}Sin Key / Acceso Libre${RESET}"
echo
linea_color

#=========================================================
# PASO 0: DEPENDENCIAS
#=========================================================

seccion "📦 PASO 0  •  PREPARANDO EL SISTEMA"

export DEBIAN_FRONTEND=noninteractive

loading "Actualizando repositorios"
apt-get update -y >/dev/null 2>&1 || error_exit "No se pudieron actualizar los repositorios."
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
    >/dev/null 2>&1 || error_exit "No se pudieron instalar las dependencias."

update-ca-certificates >/dev/null 2>&1 || true
ok "Dependencias instaladas."

#=========================================================
# PASO 1: ACCESO LIBRE
#=========================================================

seccion "🔑 PASO 1  •  CONFIGURACIÓN DE ACCESO"
ok "Sistema configurado en modo libre (sin restricciones de Key)."
ok "Propietario asignado: $LICENSE_OWNER"

#=========================================================
# PASO 2: DOMINIO
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

#=========================================================
# PASO 3: SSH Y SEGURIDAD
#=========================================================

seccion "🔒 PASO 3  •  CONFIGURANDO SSH Y FAIL2BAN"

loading "Activando OpenSSH"
systemctl enable ssh >/dev/null 2>&1 || error_exit "No se pudo habilitar OpenSSH."
systemctl restart ssh >/dev/null 2>&1 || error_exit "No se pudo iniciar OpenSSH."
ok "OpenSSH activo."

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
ok "Fail2Ban configurado."

#=========================================================
# PASO 4: FIREWALL
#=========================================================

seccion "🔥 PASO 4  •  CONFIGURANDO FIREWALL"

ufw --force reset >/dev/null 2>&1 || true
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1
ufw allow 22/tcp >/dev/null 2>&1
ufw allow 80/tcp >/dev/null 2>&1
ufw allow 443/tcp >/dev/null 2>&1
ufw allow 53/udp >/dev/null 2>&1
ufw allow 1194/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1 || warn "No se pudo activar UFW."
ok "Firewall configurado."

#=========================================================
# PASO 5: DESCARGAR REPOSITORIO Y PANEL
#=========================================================

seccion "📥 PASO 5  •  INSTALANDO SISTEMA"

rm -rf "$TMP"
mkdir -p "$TMP"

loading "Descargando repositorio mediante HTTPS"
git config --global protocol.version 2
if ! git clone --depth 1 "$REPO" "$TMP" >/dev/null 2>&1; then
    error_exit "No se pudieron descargar los archivos mediante HTTPS."
fi

mkdir -p "$BASE"
cp -a "$TMP"/. "$BASE"/ || error_exit "No se pudieron copiar los archivos."

mkdir -p \
    "$BASE/protocolos" \
    "$BASE/usuarios" \
    "$BASE/sistema" \
    "$BASE/logs" \
    "$BASE/herramientas"

find "$BASE" -type d -exec chmod 755 {} \;
find "$BASE" -type f -name "*.sh" -exec chmod 755 {} \;
ok "Archivos instalados correctamente."

#=========================================================
# PASO 6: CONFIGURACIÓN PRINCIPAL
#=========================================================

seccion "⚙️ PASO 6  •  CONFIGURACIÓN PRINCIPAL"

cat > "$BASE/config.conf" <<EOF
SERVER_DOMAIN="$SERVER_DOMAIN"
SERVER_IP="$SERVER_IP"
DOMAIN_MODE="${DOMAIN_MODE:-DOMAIN}"
DNS_PROVIDER="$DNS_PROVIDER"
DOMAIN_IP_MATCH="YES"
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
DROPBEAR=ON
SSL=ON
BADVPN=ON
UDP_CUSTOM=ON
SLOWDNS=ON
XRAY=ON
OPENVPN=ON
BHTTP=ON
ZIPVPN=ON
FAIL2BAN=ON
EOF

chmod 600 "$BASE/config.conf"

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

# Enlace dinámico robusto para el comando menu
if [[ -f "$BASE/menu.sh" ]]; then
    ln -sf "$BASE/menu.sh" /usr/local/bin/menu
elif [[ -f "$BASE/hazael.sh" ]]; then
    ln -sf "$BASE/hazael.sh" /usr/local/bin/menu
else
    cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash
BASE="/etc/kevintech"
if [[ -f "$BASE/menu.sh" ]]; then
    exec bash "$BASE/menu.sh" "$@"
elif [[ -f "$BASE/hazael.sh" ]]; then
    exec bash "$BASE/hazael.sh" "$@"
else
    echo "❌ No se encontró el script principal del menú."
fi
EOF
fi

chmod 755 /usr/local/bin/menu
ok "Comando 'menu' instalado con éxito."

#=========================================================
# PASO 7: CONFIGURACIÓN DE MÓDULOS (NO BLOQUEANTE)
#=========================================================

seccion "🚀 PASO 7  •  CONFIGURANDO PROTOCOLOS"

instalar_modulo_seguro() {
    local NOMBRE="$1"
    local ARCHIVO="$2"
    if [[ -f "$ARCHIVO" ]]; then
        chmod 755 "$ARCHIVO"
        info "Configurando $NOMBRE..."
        echo "" | bash "$ARCHIVO" --auto >/dev/null 2>&1 &
        ok "$NOMBRE preparado."
    fi
}

instalar_modulo_seguro "Dropbear" "$BASE/protocolos/dropbear.sh"
instalar_modulo_seguro "SSL Tunnel" "$BASE/protocolos/ssl.sh"
[[ -f "$BASE/protocolos/xray.sh" ]] && instalar_modulo_seguro "Xray" "$BASE/protocolos/xray.sh"
[[ -f "$BASE/protocolos/v2ray.sh" ]] && instalar_modulo_seguro "V2Ray" "$BASE/protocolos/v2ray.sh"
instalar_modulo_seguro "UDP Custom" "$BASE/protocolos/udpcustom.sh"
instalar_modulo_seguro "BadVPN" "$BASE/protocolos/badvpn.sh"
instalar_modulo_seguro "ZiVPN" "$BASE/protocolos/zivpn.sh"
instalar_modulo_seguro "SlowDNS" "$BASE/protocolos/slowdns.sh"
instalar_modulo_seguro "OpenVPN" "$BASE/protocolos/openvpn.sh"
instalar_modulo_seguro "BHTTP" "$BASE/protocolos/bhttp.sh"

seccion "🎉 INSTALACIÓN COMPLETADA"
echo -e "${GREEN}¡El script completo se ha instalado sin bloqueos!${RESET}"
echo -e "Escribe ${CYAN}${BOLD}menu${RESET} para abrir el panel de control de tu servidor."
echo
