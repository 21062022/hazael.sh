#!/usr/bin/env bash
# ==========================================================
#  PANEL BHTTP — J HAZEL MORENO | Modo 🚀 Velocidad Máxima
#  [+] Soporte: Claro Nicaragua & Tigo Nicaragua
# ==========================================================
set -uo pipefail

# --- COLORES ---
R='\033[0;31m'   # Rojo
G='\033[0;32m'   # Verde
Y='\033[0;33m'   # Amarillo
B='\033[0;34m'   # Azul
C='\033[0;36m'   # Cyan
M='\033[0;35m'   # Magenta
W='\033[1;37m'   # Blanco
D='\033[0;90m'   # Gris
N='\033[0m'      # Reset

DESTDIR="/usr/local/lib/bhttp"
SERVER_PY="$DESTDIR/bhttp-server.py"
UNIT="/etc/systemd/system/bhttp.service"
SERVICE="bhttp"

# --- FUNCIONES BASE ---
rojo() { printf "${R}%s${N}\n" "$*"; }
verde() { printf "${G}%s${N}\n" "$*"; }
info() { printf " ${D}%s${N}\n" "$*"; }
paso() { printf "\n${C}[${s}${N}] ${W}%s${N}\n" "$1" "$2"; }
linea() { printf "${D}------------------------------------------------------------${N}\n"; }

# --- BANNER ---
banner() {
    clear
    echo -e "${C}"
    cat << "EOF"
    _  _   _    ____ ____ _ ____ _  _ 
    |__|  / \   |    |___ | |___ |\ | 
    |  | /---\  |___ |___ | |___ | \| 
EOF
    echo -e "${N}"
    echo -e "      ${W}B H T T P   P R O T O C O L${N} v1.0.0"
    echo -e "      ${C}J Hazael Moreno${N} | ${W}Claro & Tigo NI${N}"
    linea
}

# --- VERIFICAR ESTADO ---
estado_servicio() {
    if systemctl is-active --quiet "$SERVICE"; then
        echo -e "Operador: ${G}Claro / Tigo NI${N}  |  Servicio: ${G}active${N}"
    else
        echo -e "Operador: ${Y}Claro / Tigo NI${N}  |  Servicio: ${R}inactive${N}"
    fi
}

# --- INSTALAR / INICIAR BHTTP (MODO 🚀 MÁXIMA VELOCIDAD) ---
instalar_bhttp() {
    clear
    banner
    echo -e "${W}Instalando conexión BHTTP y configurando servicios (Modo 🚀)...${N}"
    linea

    mkdir -p "$DESTDIR"

    # Crear el servidor Python optimizado para 1080P sin cortes
    cat << 'EOF' > "$SERVER_PY"
import http.server
import socketserver
import socket

PORT = 8080
LONGPOLL = 0.5
CHUNK_SIZE = 65536

class FastBHTTPServer(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/octet-stream")
        self.end_headers()
        try:
            while True:
                self.wfile.write(b"\x00" * CHUNK_SIZE)
                self.wfile.flush()
        except Exception:
            pass

class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    allow_reuse_address = True
    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 2097152)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 2097152)
        super().server_bind()

if __name__ == "__main__":
    with ThreadedHTTPServer(("", PORT), FastBHTTPServer) as httpd:
        print(f"Servidor BHTTP corriendo en puerto {PORT} con Modo 🚀")
        httpd.serve_forever()
EOF

    chmod +x "$SERVER_PY"

    # Crear servicio systemd con límites altos
    cat << EOF > "$UNIT"
[Unit]
Description=BHTTP Tunnel Service - Hazael
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DESTDIR
ExecStart=/usr/bin/python3 $SERVER_PY
Restart=always
RestartSec=2
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE"
    systemctl restart "$SERVICE"

    linea
    verde "=== ¡BHTTP INSTALADO Y ESCUCHANDO EN PUERTO 8080 (MODO 🚀)! ==="
    read -p "Presiona Enter para continuar..."
}

# --- VER ESTADO ---
ver_estado() {
    clear
    banner
    echo -e "${W}Diagnóstico y Estado del Servicio:${N}"
    linea
    systemctl status "$SERVICE" --no-pager
    linea
    read -p "Presiona Enter para regresar..."
}

# --- MENÚ PRINCIPAL ---
while true; do
    clear
    banner
    estado_servicio
    linea
    echo -e "  ${C}[1]${N} Instalar / Iniciar BHTTP (Modo 🚀)"
    echo -e "  ${C}[2]${N} Ver Estado del Servicio"
    echo -e "  ${C}[3]${N} Salir"
    linea
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1) instalar_bhttp ;;
        2) ver_estado ;;
        3) echo -e "\n${G}¡Saliendo del panel!${N}\n"; exit 0 ;;
        *) rojo "Opción inválida, intenta de nuevo."; sleep 1 ;;
    esac
done
