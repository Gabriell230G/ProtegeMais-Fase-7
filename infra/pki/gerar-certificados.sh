#!/usr/bin/env bash
# Protege+ | Fase 7, Parte 2: certificados da demonstracao de rede.
#
# Cria duas autoridades certificadoras (AC) internas, de proposito separadas:
#   ac-servidor      assina o certificado HTTPS do proxy (em producao: ICP-Brasil
#                    ou uma AC publica como a Let's Encrypt)
#   ac-dispositivos  assina um certificado por aparelho de campo (botao de
#                    panico, tornozeleira, totem). Vazar a chave de um aparelho
#                    compromete so aquele aparelho, que e revogado sozinho.
#
# Uso: bash infra/pki/gerar-certificados.sh      (Git Bash no Windows)
# Saida: infra/pki/saida/ (fora do Git: contem chaves privadas)
set -euo pipefail
# No Git Bash do Windows, impede que "/C=BR/..." vire um caminho de pasta.
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
mkdir -p saida/dispositivos
cd saida
umask 077

DIAS=825
assunto() { echo "/C=BR/O=Protege Mais - demonstracao/CN=$1"; }

ac() { # nome, titulo
  [ -f "$1.key" ] && return
  openssl ecparam -name prime256v1 -genkey -noout -out "$1.key"
  openssl req -x509 -new -key "$1.key" -sha256 -days 3650 -subj "$(assunto "$2")" \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" -out "$1.crt"
  echo "AC criada: $2"
}

ac ac-servidor "AC Servidores Protege Mais"
ac ac-dispositivos "AC Dispositivos de Campo Protege Mais"

if [ ! -f servidor.key ]; then
  openssl ecparam -name prime256v1 -genkey -noout -out servidor.key
  openssl req -new -key servidor.key -subj "$(assunto protege.local)" -out servidor.csr
  printf "subjectAltName=DNS:localhost,DNS:protege.local,IP:127.0.0.1\nextendedKeyUsage=serverAuth\nkeyUsage=critical,digitalSignature\nbasicConstraints=CA:FALSE\n" > servidor.ext
  openssl x509 -req -in servidor.csr -CA ac-servidor.crt -CAkey ac-servidor.key -CAcreateserial \
    -days $DIAS -sha256 -extfile servidor.ext -out servidor.crt 2>/dev/null
  rm -f servidor.csr servidor.ext
  echo "Certificado do servidor: localhost, protege.local, 127.0.0.1"
fi

# Um certificado por aparelho, com o identificador no CN.
for d in SOS-8812 TZ-4471 TT-001; do   # os mesmos ids do simulador-iot.html
  [ -f "dispositivos/$d.key" ] && continue
  openssl ecparam -name prime256v1 -genkey -noout -out "dispositivos/$d.key"
  openssl req -new -key "dispositivos/$d.key" -subj "$(assunto "$d")" -out "dispositivos/$d.csr"
  printf "extendedKeyUsage=clientAuth\nkeyUsage=critical,digitalSignature\nbasicConstraints=CA:FALSE\n" > dispositivos/cliente.ext
  openssl x509 -req -in "dispositivos/$d.csr" -CA ac-dispositivos.crt -CAkey ac-dispositivos.key \
    -CAcreateserial -days 365 -sha256 -extfile dispositivos/cliente.ext -out "dispositivos/$d.crt" 2>/dev/null
  rm -f "dispositivos/$d.csr" dispositivos/cliente.ext
  echo "Certificado do aparelho $d"
done

# Um aparelho "pirata": certificado valido, mas assinado por uma AC que nao e a nossa.
if [ ! -f dispositivos/PIRATA.key ]; then
  openssl ecparam -name prime256v1 -genkey -noout -out dispositivos/PIRATA.key
  openssl req -x509 -new -key dispositivos/PIRATA.key -sha256 -days 30 -subj "$(assunto SOS-8812)" \
    -out dispositivos/PIRATA.crt
  echo "Certificado pirata (autoassinado, CN copiado de um aparelho real), para o teste"
fi
echo "Pronto: $(pwd)"
