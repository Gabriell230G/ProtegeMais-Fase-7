#!/usr/bin/env bash
# =============================================================================
# Protege+ | Sobe a borda nginx (HTTPS em 8443) e deixa no ar para o painel.js
# =============================================================================
# Monta o nginx do mesmo jeito que o infra/testar-rede.sh: mesma configuracao
# de producao (infra/nginx/protege.conf), so trocando as portas 80/443 por
# 8088/8443. A diferenca e que aqui a borda fica ligada ate voce mandar parar.
#
# Requisitos: nginx, openssl, python3 (Linux ou WSL) e a API no ar em
# 127.0.0.1:8080 com PROTEGE_PROXY_CONFIAVEL=true e
# CORS_ORIGENS=https://localhost:8443.
#
# Uso:  bash testes-navegador/subir-borda.sh          (sobe)
#       bash testes-navegador/subir-borda.sh parar    (derruba)
# =============================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1

AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/.." && pwd)"
INFRA="$RAIZ/infra"
PKI="$INFRA/pki/saida"
EXEC="$AQUI/.borda"
API_PORTA="${API_PORTA:-8080}"

if [ "${1:-}" = "parar" ]; then
  if [ -f "$EXEC/nginx.pid" ]; then nginx -p "$EXEC/" -c nginx.conf -s quit && echo "Borda desligada."; else echo "A borda nao estava no ar."; fi
  exit 0
fi

for p in nginx openssl python3; do
  command -v "$p" >/dev/null || { echo "Falta o programa: $p"; exit 1; }
done
[ -f "$PKI/servidor.crt" ] || bash "$INFRA/pki/gerar-certificados.sh"

rm -rf "$EXEC"; mkdir -p "$EXEC/certs" "$EXEC/tmp"
cp "$PKI/servidor.crt" "$PKI/servidor.key" "$PKI/ac-dispositivos.crt" "$EXEC/certs/"
sed -e 's/listen 443 ssl http2;/listen 8443 ssl http2;/' -e 's/listen 80;/listen 8088;/' \
    -e '/listen \[::\]/d' -e 's#https://$host$request_uri#https://$host:8443$request_uri#' \
    "$INFRA/nginx/protege.conf" > "$EXEC/protege.conf"
cat > "$EXEC/nginx.conf" <<EOF
worker_processes 1;
pid nginx.pid;
error_log error.log warn;
events { worker_connections 256; }
http {
    types { text/html html; text/css css; application/javascript js; application/json json;
            image/png png; image/jpeg jpg jpeg; image/svg+xml svg; image/x-icon ico; font/woff2 woff2; }
    default_type application/octet-stream;
    access_log access.log;
    client_body_temp_path tmp/body; proxy_temp_path tmp/proxy; fastcgi_temp_path tmp/fcgi;
    uwsgi_temp_path tmp/uwsgi; scgi_temp_path tmp/scgi;
    upstream protege_api   { server 127.0.0.1:$API_PORTA max_fails=3 fail_timeout=10s; keepalive 16; }
    map "" \$protege_raiz { default "$RAIZ"; }
    include protege.conf;
}
EOF

nginx -t -p "$EXEC/" -c nginx.conf 2>"$EXEC/teste-config.txt" || { cat "$EXEC/teste-config.txt"; exit 1; }
nginx -p "$EXEC/" -c nginx.conf
echo "Borda no ar: https://localhost:8443 (certificado da AC em infra/pki/saida/ac-servidor.crt)"
echo "Para desligar: bash testes-navegador/subir-borda.sh parar"
