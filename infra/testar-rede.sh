#!/usr/bin/env bash
# =============================================================================
# Protege+ | Fase 7, Parte 2: testa a borda de rede de verdade
# =============================================================================
# Sobe o nginx com infra/nginx/protege.conf na frente da API e confere, com
# requisicoes reais, cada defesa de rede descrita no documento.
#
# Requisitos: nginx, openssl, curl, python3 (Linux ou WSL).
# A API precisa estar no ar com o proxy declarado confiavel e o endereco
# publico na lista de origens (variaveis de ambiente da API):
#     PROTEGE_PROXY_CONFIAVEL=true
#     CORS_ORIGENS=https://localhost:8443
#
# Uso:  API_PORTA=8080 CHAVE_IOT=backend/data/iot-chave.txt bash infra/testar-rede.sh
# Portas usadas pelo proxy de teste: 8088 (HTTP) e 8443 (HTTPS).
# =============================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1

INFRA="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$INFRA/.." && pwd)"
API_PORTA="${API_PORTA:-8080}"
CHAVE_IOT="${CHAVE_IOT:-$RAIZ/backend/data/iot-chave.txt}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@protege.gov.br}"
ADMIN_SENHA="${ADMIN_SENHA:-admin123}"
HTTPS="https://localhost:8443"
EXEC="$INFRA/nginx/.execucao"
PKI="$INFRA/pki/saida"
DISP="$PKI/dispositivos"
mkdir -p "$INFRA/resultados"
SAIDA="$INFRA/resultados/rede-$(date +%Y%m%d-%H%M%S).txt"

OKS=0; FALHAS=0
linha() { echo "$*" | tee -a "$SAIDA"; }
ok()    { OKS=$((OKS+1));       linha "  [OK]     $1"; if [ -n "${2:-}" ]; then linha "           $2"; fi; }
falha() { FALHAS=$((FALHAS+1)); linha "  [FALHA]  $1"; if [ -n "${2:-}" ]; then linha "           $2"; fi; }
confere() { # descricao, esperado, obtido
  if [ "$2" = "$3" ]; then ok "$1" "obtido: $3"; else falha "$1" "esperado: $2 | obtido: $3"; fi
}
secao() { linha ""; linha "--- $1"; }
c() { curl -s --cacert "$PKI/ac-servidor.crt" --max-time 20 "$@"; }
codigo() { c -o /dev/null -w "%{http_code}" "$@"; }

for p in nginx openssl curl python3; do
  command -v "$p" >/dev/null || { echo "Falta o programa: $p"; exit 1; }
done
curl -s -o /dev/null --max-time 5 "http://127.0.0.1:$API_PORTA/api/stats/resumo" \
  || { echo "API fora do ar em 127.0.0.1:$API_PORTA. Suba a API com PROTEGE_PROXY_CONFIAVEL=true e CORS_ORIGENS=https://localhost:8443."; exit 1; }
[ -f "$CHAVE_IOT" ] || { echo "Chave IoT nao encontrada em $CHAVE_IOT (defina CHAVE_IOT)."; exit 1; }

[ -f "$PKI/servidor.crt" ] || bash "$INFRA/pki/gerar-certificados.sh"

# ---------- monta a execucao do nginx ----------------------------------------
rm -rf "$EXEC"; mkdir -p "$EXEC/certs" "$EXEC/tmp"
cp "$PKI/servidor.crt" "$PKI/servidor.key" "$PKI/ac-dispositivos.crt" "$EXEC/certs/"
# Mesma configuracao da producao, so trocando as portas (80/443 -> 8088/8443)
# e acrescentando uma rota que aponta para uma API desligada.
sed -e 's/listen 443 ssl http2;/listen 8443 ssl http2;/' -e 's/listen 80;/listen 8088;/' \
    -e '/listen \[::\]/d' -e 's#https://$host$request_uri#https://$host:8443$request_uri#' \
    "$INFRA/nginx/protege.conf" > "$EXEC/protege.conf"
python3 - "$EXEC/protege.conf" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read(); i = s.rstrip().rfind('}')
s = s[:i] + "    # So no teste: a mesma borda diante de uma API desligada.\n" \
           "    location = /__teste/api-fora-do-ar { proxy_pass http://api_desligada; }\n" + s[i:]
open(p, "w").write(s)
PY
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
    upstream api_desligada { server 127.0.0.1:9; }
    map "" \$protege_raiz { default "$RAIZ"; }
    include protege.conf;
}
EOF

nginx -t -p "$EXEC/" -c nginx.conf 2>"$EXEC/teste-config.txt" || { cat "$EXEC/teste-config.txt"; exit 1; }
nginx -p "$EXEC/" -c nginx.conf || exit 1
trap 'nginx -p "$EXEC/" -c nginx.conf -s quit 2>/dev/null' EXIT
for i in $(seq 1 20); do curl -s -o /dev/null http://127.0.0.1:8088/ && break; sleep 0.3; done

linha "PROTEGE+ | Teste da borda de rede (Parte 2) | $(date '+%d/%m/%Y %H:%M')"
linha "nginx $(nginx -v 2>&1 | sed 's/.*\///') na frente da API em 127.0.0.1:$API_PORTA"

# ---------- 1. Transporte -----------------------------------------------------
secao "1. Confidencialidade em transito (TLS)"
confere "HTTP simples e redirecionado para HTTPS" "301 https://localhost:8443/" \
  "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' http://localhost:8088/)"
for v in tls1_3 tls1_2; do
  P=$(echo | openssl s_client -connect localhost:8443 -servername localhost -$v -CAfile "$PKI/ac-servidor.crt" 2>/dev/null \
      | grep -m1 -oE "^New, TLSv1\.[0-9]" | sed 's/New, //')
  case $v in tls1_3) E=TLSv1.3;; tls1_2) E=TLSv1.2;; esac
  confere "$E aceito" "$E" "${P:-recusado}"
done
SAIDA_TLS11=$(echo | openssl s_client -connect localhost:8443 -tls1_1 -cipher 'DEFAULT:@SECLEVEL=0' 2>&1)
if echo "$SAIDA_TLS11" | grep -q "^New, TLSv1.1"; then
  falha "TLS 1.1 recusado" "o servidor aceitou TLS 1.1"
elif echo "$SAIDA_TLS11" | grep -qiE "alert protocol version|unsupported protocol|wrong version|no protocols available"; then
  ok "TLS 1.1 recusado" "$(echo "$SAIDA_TLS11" | grep -m1 -oiE "alert protocol version|unsupported protocol|wrong version number|no protocols available")"
else
  falha "TLS 1.1 recusado" "resposta inesperada do openssl"
fi
CIF=$(echo | openssl s_client -connect localhost:8443 -tls1_2 2>/dev/null | grep -m1 -E "Cipher *:" | sed 's/.*: *//')
case "$CIF" in ECDHE-*) ok "Troca de chaves com sigilo futuro (ECDHE)" "cifra: $CIF";;
                *) falha "Troca de chaves com sigilo futuro (ECDHE)" "cifra: ${CIF:-?}";; esac
confere "Certificado confere com a AC e com o nome localhost" "0" \
  "$(curl -s -o /dev/null -w '%{ssl_verify_result}' --cacert "$PKI/ac-servidor.crt" $HTTPS/)"
curl -s -o /dev/null --max-time 5 --cacert "$PKI/ac-dispositivos.crt" $HTTPS/ 2>/dev/null; R=$?  # confia so em outra AC
confere "Cliente sem a AC recusa a conexao (impede servidor falso)" "60" "$R"

# ---------- 2. Cabecalhos e superficie ---------------------------------------
secao "2. Integridade da pagina e superficie exposta"
CAB=$(c -D - -o /dev/null $HTTPS/)
for h in "Strict-Transport-Security: max-age=31536000" "Content-Security-Policy: default-src 'self'" \
         "X-Content-Type-Options: nosniff" "X-Frame-Options: DENY" "Referrer-Policy: no-referrer"; do
  if echo "$CAB" | grep -qi "^${h}"; then ok "Cabecalho ${h%%:*}"; else falha "Cabecalho ${h%%:*}" "ausente"; fi
done
if echo "$CAB" | grep -qiE "^server: nginx/[0-9]"; then falha "Versao do servidor escondida"; else ok "Versao do servidor escondida" "$(echo "$CAB" | grep -i '^server:' | tr -d '\r')"; fi
confere "Pagina aponta para a API no mesmo endereco" "1" \
  "$(c $HTTPS/ | grep -c 'window.PROTEGE_API_URL="/api"')"
for u in /backend/pom.xml /database/01_ddl_oracle.sql /.git/config /blockchain/package.json \
         /infra/pki/saida/servidor.key /seguranca/simular_ataques.py /simulador-iot.html /h2-console /swagger-ui/index.html; do
  confere "Nao serve $u" "404" "$(codigo $HTTPS$u)"
done

# ---------- 3. Autenticacao de aparelhos (TLS mutuo) --------------------------
secao "3. Aparelhos de campo: certificado + chave"
CHAVE=$(tr -d '\r\n' < "$CHAVE_IOT")
SOS='{"dispositivo":"SOS-8812","lat":-23.5106,"lng":-46.8761,"bateria":80}'
iot() { c -o /tmp/protege-iot.json -w "%{http_code}" -X POST "$HTTPS/api/iot/acionamento" \
          -H "Content-Type: application/json" -d "$SOS" "$@"; }
R=$(iot -H "X-Device-Key: $CHAVE"); B=$(cat /tmp/protege-iot.json)
confere "Sem certificado: barrado no proxy, nem chega a API" "403 proxy" "$R $(echo "$B" | grep -o '"origem":"proxy"' | cut -d'"' -f4)"
R=$(iot -H "X-Device-Key: $CHAVE" --cert "$DISP/PIRATA.crt" --key "$DISP/PIRATA.key")
confere "Certificado pirata (CN copiado de aparelho real, outra AC): barrado" "403" "$R"
R=$(iot -H "X-Device-Key: chave-errada" --cert "$DISP/SOS-8812.crt" --key "$DISP/SOS-8812.key")
confere "Certificado valido com chave errada: a API recusa" "401" "$R"
R=$(iot -H "X-Device-Key: $CHAVE" --cert "$DISP/SOS-8812.crt" --key "$DISP/SOS-8812.key")
if [ "$R" = "201" ] || [ "$R" = "200" ]; then ok "Certificado valido e chave certa: aceito" "obtido: $R"; else falha "Certificado valido e chave certa: aceito" "obtido: $R"; fi
confere "Painel continua lendo /api/iot/resumo sem certificado (rota de pessoa, com login)" "401" \
  "$(codigo $HTTPS/api/iot/resumo)"

# ---------- 4. Origem real atras do proxy ------------------------------------
secao "4. Rastreabilidade: o IP que a trilha grava"
TOK=$(c -X POST $HTTPS/api/auth/login -H 'Content-Type: application/json' \
      -d "{\"email\":\"$ADMIN_EMAIL\",\"senha\":\"$ADMIN_SENHA\"}" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))' 2>/dev/null)
if [ -n "$TOK" ]; then ok "Login pela borda funciona"; else falha "Login pela borda funciona" "sem token"; fi
LOGIN_FALSO='{"email":"ninguem@exemplo.com","senha":"x"}'
confere "Pagina do proprio endereco publico pode chamar a API (CORS)" "401" \
  "$(codigo -X POST $HTTPS/api/auth/login -H 'Origin: https://localhost:8443' -H 'Content-Type: application/json' -d "$LOGIN_FALSO")"
confere "Site de terceiros nao usa a sessao do servidor publico (CORS)" "403" \
  "$(codigo -X POST $HTTPS/api/auth/login -H 'Origin: https://site-falso.example' -H 'Content-Type: application/json' -d "$LOGIN_FALSO")"
ORIGEM=127.0.0.2
curl -s -o /dev/null --interface $ORIGEM http://127.0.0.1:8088/ 2>/dev/null || ORIGEM=127.0.0.1
c --interface $ORIGEM -o /dev/null -X POST $HTTPS/api/auth/login -H 'Content-Type: application/json' \
  -H 'X-Forwarded-For: 6.6.6.6' -d '{"email":"invasor@exemplo.com","senha":"tentativa"}'
IP=$(c -H "Authorization: Bearer $TOK" "$HTTPS/api/auditoria?acao=LOGIN_NEGADO&tamanho=1" \
     | python3 -c 'import sys,json;print(json.load(sys.stdin)["conteudo"][0]["origemIp"])' 2>/dev/null)
confere "Login forjando X-Forwarded-For: 6.6.6.6 fica registrado com o IP real" "$ORIGEM" "${IP:-?}"

# ---------- 5. Disponibilidade ------------------------------------------------
secao "5. Disponibilidade: abuso barrado na borda"
DEN='{"tipo":"outros","descricao":"Teste de limite da borda de rede, sem dado real.","estado":"SP","cidade":"Barueri","anonimo":true}'
SEQ=""
for i in 1 2 3 4; do
  SEQ="$SEQ $(c --interface 127.0.0.3 -o /dev/null -w '%{http_code}' -X POST $HTTPS/api/denuncias \
              -H 'Content-Type: application/json' -d "$DEN" 2>/dev/null || echo X)"
done
confere "Rajada de denuncias da mesma origem: a 4a e barrada no proxy" "201 201 201 429" "${SEQ# }"
head -c 400000 /dev/zero | tr '\0' 'a' > /tmp/protege-grande.txt
confere "JSON de 400 KB: barrado no proxy" "413" \
  "$(codigo -X POST $HTTPS/api/denuncias -H 'Content-Type: application/json' --data-binary @/tmp/protege-grande.txt)"
head -c 1000000 /dev/urandom > /tmp/protege-1mb.bin
confere "Evidencia de 1 MB passa pela borda (a API responde: protocolo inexistente)" "404" \
  "$(codigo -X POST $HTTPS/api/denuncias/protocolo/QUALQUER/evidencias -F arquivo=@/tmp/protege-1mb.bin)"
head -c 7000000 /dev/urandom > /tmp/protege-7mb.bin
confere "Arquivo de 7 MB como evidencia: barrado no proxy" "413" \
  "$(codigo -X POST $HTTPS/api/denuncias/protocolo/QUALQUER/evidencias -F arquivo=@/tmp/protege-7mb.bin)"
rm -f /tmp/protege-grande.txt /tmp/protege-1mb.bin /tmp/protege-7mb.bin /tmp/protege-iot.json

INI=$(date +%s%N)
R=$(c -o /tmp/protege-queda.json -w '%{http_code}' $HTTPS/__teste/api-fora-do-ar); FIM=$(date +%s%N)
MS=$(( (FIM-INI)/1000000 ))
confere "API fora do ar: resposta clara em JSON, e nao uma pagina travada" "503 proxy" \
  "$R $(grep -o '"origem":"proxy"' /tmp/protege-queda.json | cut -d'"' -f4)"
if [ $MS -lt 4000 ]; then ok "Resposta da queda em menos de 4 s" "$MS ms"; else falha "Resposta da queda em menos de 4 s" "$MS ms"; fi
rm -f /tmp/protege-queda.json

# Conexao lenta de proposito (slowloris): manda o cabecalho aos poucos.
LENTA=$(python3 - <<'PY'
import socket, ssl, time
ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
s = ctx.wrap_socket(socket.create_connection(("127.0.0.1", 8443)), server_hostname="localhost")
s.send(b"GET / HTTP/1.1\r\nHost: localhost\r\n")
inicio = time.time(); s.settimeout(1)
while time.time() - inicio < 25:
    try:
        s.send(b"X-a: b\r\n"); dado = s.recv(100)
        if not dado: break
    except socket.timeout:
        continue
    except Exception:
        break
    break
print(round(time.time() - inicio))
PY
)
if [ "${LENTA:-99}" -le 13 ]; then ok "Conexao lenta de proposito (slowloris) derrubada" "em ${LENTA} s"; else falha "Conexao lenta de proposito (slowloris) derrubada" "${LENTA} s"; fi

# ---------- resumo -------------------------------------------------------------
linha ""
linha "RESULTADO: $OKS verificacoes OK, $FALHAS falhas"
linha "Relatorio: ${SAIDA#$RAIZ/}"
[ $FALHAS -eq 0 ]
