#!/usr/bin/env bash
# ============================================================
#   Panel Profesional — J Hazael Moreno
#   Operadores: Claro Nicaragua & Tigo Nicaragua
# ============================================================
set -uo pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; W='\033[1;37m'; D='\033[0;90m'; N='\033[0m'

DESTDIR="/usr/local/lib/bhttp"
SERVER_PY="$DESTDIR/bhttp-server.py"
UNIT="/etc/systemd/system/bhttp.service"
SERVICE="bhttp"
CONFIG="/etc/bhttp/nullcore.conf"
CANDIDATOS=(8080 80 8443 443 2082 2095 8880 2052 3128)

PUERTO=""
SSHPORT=22
VERSION="2.0.0"

rojo()  { printf "${R}%s${N}\n" "$*"; }
verde() { printf "${G}%s${N}\n" "$*"; }
info()  { printf "  ${D}%s${N}\n" "$*"; }
paso()  { printf "\n${C}[%s]${N} ${W}%s${N}\n" "$1" "$2"; }
linea() { printf "${D}────────────────────────────────────────────────────────${N}\n"; }

banner() {
  clear
  echo -e ""
  echo -e "${C}════════════════════════════════════════════════════════${N}"
  echo -e "${W}         PANEL BHTTP — ${G}J HAZAEL MORENO${N}"
  echo -e "${Y}    [+] Soporte: ${W}Claro Nicaragua${Y} & ${W}Tigo Nicaragua${N}"
  echo -e "${C}════════════════════════════════════════════════════════${N}"
  linea
}

check_root() {
  if [ "$(id -u 2>/dev/null || echo 0)" != 0 ]; then
    rojo "Ejecuta como root: sudo bash $0"
    exit 2
  fi
}

cargar_config() {
  mkdir -p /etc/bhttp
  [ -f "$CONFIG" ] && source "$CONFIG"
  [ -z "${PUERTO:-}" ] && PUERTO=""
  [ -z "${SSHPORT:-}" ] && SSHPORT=22
}

guardar_config() {
  mkdir -p /etc/bhttp
  cat > "$CONFIG" <<EOF
PUERTO=${PUERTO}
SSHPORT=${SSHPORT}
EOF
}

ocupados() {
  if command -v ss >/dev/null 2>&1; then
    ss -tln 2>/dev/null | tail -n +2 | awk '{print $4}' | sed 's/.*://'
  fi | grep -E '^[0-9]+$' | sort -u
}
libre() { ! ocupados | grep -qx "$1"; }

instalar_servidor() {
  banner
  echo -e "${W}  Instalando conexión BHTTP y configurando servicios...${N}"
  linea
  command -v python3 >/dev/null 2>&1 || { rojo "Falta python3. Instálalo: apt install -y python3"; return 1; }
  
  paso "1/3" "Selección de puerto"
  local primer_libre=""
  for p in "${CANDIDATOS[@]}"; do libre "$p" && { primer_libre="$p"; break; }; done
  if [ -z "$PUERTO" ]; then
    read -r -p "  Puerto BHTTP [${primer_libre:-8080}]: " PUERTO
    [ -z "$PUERTO" ] && PUERTO="${primer_libre:-8080}"
  fi

  paso "2/3" "Generando demonio Python local"
  mkdir -p "$DESTDIR"
  cat > "$SERVER_PY" << 'PYEOF'
#!/usr/bin/env python3
import argparse, asyncio, hashlib, sys
MAGIC = b"BHP1"
LONGPOLL = 2.0
def keystream(sess, mode, seq, d, n):
    base = hashlib.sha256(sess + bytes([mode]) + seq.to_bytes(8, "big") + bytes([d]))
    out = bytearray(); c = 0
    while len(out) < n:
        h = base.copy(); h.update(c.to_bytes(4, "big")); out += h.digest(); c += 1
    return bytes(out[:n])
def mask(data, sess, mode, seq, d):
    return bytes(a ^ b for a, b in zip(data, keystream(sess, mode, seq, d, len(data))))
class Session:
    def __init__(self, sess, backend):
        self.sess = sess; self.backend = backend
        self.cond = asyncio.Condition(); self.up_next = 0
        self.up_pending = {}; self.down_raw = bytearray()
        self.down_chunks = {}; self.down_assign = 0
        self.eof = False; self.closed = False; self.br = None; self.bw = None
    async def connect(self):
        host, port = self.backend
        self.br, self.bw = await asyncio.open_connection(host, port)
        asyncio.create_task(self._reader())
    async def _reader(self):
        try:
            while True:
                data = await self.br.read(65536)
                if not data: break
                async with self.cond:
                    self.down_raw += data; self.cond.notify_all()
        except Exception:
            pass
        finally:
            async with self.cond:
                self.eof = True; self.cond.notify_all()
    async def upload(self, seq, data):
        async with self.cond:
            if data: self.up_pending[seq] = data
            while self.up_next in self.up_pending:
                chunk = self.up_pending.pop(self.up_next)
                try:
                    self.bw.write(chunk); await self.bw.drain()
                except Exception:
                    self.closed = True
                self.up_next += 1
    async def download(self, seq, maxlen, deadline):
        if maxlen <= 0: maxlen = 1399
        loop = asyncio.get_running_loop()
        async with self.cond:
            while True:
                if seq < self.down_assign: return self.down_chunks.get(seq, b"")
                if seq == self.down_assign:
                    if self.down_raw:
                        take = bytes(self.down_raw[:maxlen]); del self.down_raw[:maxlen]
                        self.down_chunks[self.down_assign] = take; self.down_assign += 1
                        self.cond.notify_all(); return take
                    if self.eof:
                        self.down_assign += 1; self.cond.notify_all(); return b""
                if not self.eof and loop.time() < deadline:
                    try:
                        await asyncio.wait_for(self.cond.wait(), timeout=max(0.01, deadline - loop.time()))
                    except asyncio.TimeoutError:
                        pass
                    continue
                self.down_assign += 1; self.cond.notify_all(); return b""
    async def close(self):
        async with self.cond: self.closed = True; self.cond.notify_all()
        try: self.bw.close()
        except Exception: pass
class Server:
    def __init__(self, host, port, backend):
        self.host, self.port, self.backend = host, port, backend
        self.sessions = {}; self.slock = asyncio.Lock()
    async def get_session(self, sess):
        async with self.slock:
            s = self.sessions.get(sess)
            if s is None or s.closed:
                s = Session(sess, self.backend); await s.connect()
                self.sessions[sess] = s
            return s
    async def handle(self, reader, writer):
        try:
            while True:
                hdr = await reader.readexactly(29)
                mode = hdr[0]; sess = hdr[1:17]
                seq = int.from_bytes(hdr[17:25], "big")
                ln = int.from_bytes(hdr[25:29], "big")
                payload = b""
                if ln and mode in (0, 1, 2, 3):
                    raw = await reader.readexactly(ln)
                    payload = mask(raw, sess, mode, seq, 0)
                s = await self.get_session(sess)
                if mode == 1:
                    await s.upload(seq, payload)
                    writer.write(bytes([0]) + (0).to_bytes(4, "big")); await writer.drain()
                elif mode == 2:
                    chunk = await s.download(seq, ln if ln > 0 else 1399, asyncio.get_running_loop().time() + LONGPOLL)
                    real = len(chunk)
                    masked = mask(chunk, sess, mode, seq, 1) if chunk else b""
                    body = real.to_bytes(4, "big") + masked
                    writer.write(bytes([2]) + len(body).to_bytes(4, "big") + body); await writer.drain()
                else:
                    return
        except Exception:
            pass
        finally:
            try: writer.close()
            except Exception: pass
    async def serve(self):
        srv = await asyncio.start_server(self.handle, self.host, self.port, backlog=512)
        async with srv: await srv.serve_forever()
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, required=True)
    ap.add_argument("--backend-host", default="127.0.0.1")
    ap.add_argument("--backend-port", type=int, default=22)
    a = ap.parse_args()
    asyncio.run(Server(a.host, a.port, (a.backend_host, a.backend_port)).serve())
if __name__ == "__main__":
    main()
PYEOF
  chmod +x "$SERVER_PY"

  paso "3/3" "Activando servicio systemd"
  cat > "$UNIT" <<EOF
[Unit]
Description=BHTTP Server Hazael Moreno
After=network.target
[Service]
Type=simple
ExecStart=$(command -v python3) $SERVER_PY --host 0.0.0.0 --port $PUERTO --backend-host 127.0.0.1 --backend-port $SSHPORT
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable "$SERVICE" >/dev/null 2>&1
  systemctl restart "$SERVICE"
  guardar_config
  
  verde "\n=== ¡BHTTP INSTALADO Y ESCUCHANDO EN PUERTO $PUERTO! ==="
  read -p "  Presiona Enter para continuar..."
}

menu_principal() {
  while true; do
    banner
    local estado
    estado=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "no instalado")
    echo -e "  Operador: ${C}Claro / Tigo NI${N}  |  Servicio: ${estado}"
    linea
    echo -e "  ${G}[1]${N}  Instalar / Iniciar BHTTP"
    echo -e "  ${G}[2]${N}  Ver Estado del Servicio"
    echo -e "  ${R}[3]${N}  Salir"
    linea
    read -r -p "  Selecciona una opción: " op
    case $op in
      1) instalar_servidor ;;
      2) systemctl status "$SERVICE" --no-pager; read -p "  Enter para continuar..." ;;
      3) exit 0 ;;
      *) rojo "Opción inválida" ;;
    esac
  done
}

check_root
cargar_config
menu_principal
