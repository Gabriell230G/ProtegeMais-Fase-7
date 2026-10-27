#!/bin/bash
# Exercicios que exigem parar a API: (A) insider altera o banco direto,
# (B) perda total do banco e restauracao pelo backup.
# Uso: bash exercicios_insider_e_recuperacao.sh <protege-backend.jar> <h2.jar>
# Rodar a partir da pasta backend (onde fica a pasta data/). Funciona no Git Bash.
JAR=${1:-target/protege-backend-1.0.0.jar}
H2=${2:-$HOME/.m2/repository/com/h2database/h2/2.2.224/h2-2.2.224.jar}
API=http://127.0.0.1:8080/api
log() { echo "[$(date +%H:%M:%S)] $*"; }
token() { curl -s -X POST $API/auth/login -H 'Content-Type: application/json' -d "{\"email\":\"$1\",\"senha\":\"$2\"}" | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])'; }
subir() { java -jar "$JAR" > servidor-exercicio-$1.log 2>&1 & echo $! > pid; for i in $(seq 1 60); do curl -s -m 2 $API/vigia/status >/dev/null && return; sleep 1; done; log "API nao subiu"; exit 1; }
parar() { kill "$(cat pid)" 2>/dev/null; sleep 3; }
total() { curl -s "$API/stats" -H "Authorization: Bearer $1" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("total"))'; }
integridade() { curl -s "$API/auditoria/integridade" -H "Authorization: Bearer $1"; }

[ -f pid ] || subir 0
AUD=$(token auditor@protege.gov.br auditor123)
ADM=$(token admin@protege.gov.br admin123)
log "Estado inicial | denuncias: $(total $ADM) | integridade: $(integridade $AUD)"
BACKUP=$(ls data/backups/protege-*.zip | tail -1)
log "Ultimo backup disponivel: $(basename $BACKUP)"

echo
log "=== Exercicio A: funcionario com acesso ao servidor altera a trilha direto no banco ==="
parar
log "API parada. Insider abre o arquivo do banco e reescreve o registro 3 da trilha e apaga o registro 5"
java -cp "$H2" org.h2.tools.Shell -url "jdbc:h2:file:./data/protege" -user sa \
  -sql "SELECT ID, ACAO, USUARIO, RESULTADO FROM AUDITORIA_LOG WHERE ID IN (3,5); UPDATE AUDITORIA_LOG SET USUARIO='outra.pessoa@protege.gov.br' WHERE ID=3; DELETE FROM AUDITORIA_LOG WHERE ID=5;" 2>&1 | grep -v JAVA_TOOL
subir A
AUD=$(token auditor@protege.gov.br auditor123)
log "API de volta. Verificacao de integridade pedida pelo AUDITOR:"
integridade $AUD; echo

echo
log "=== Exercicio B: o disco do banco e perdido (ou sequestrado por ransomware) ==="
parar
ADULTERADO=data/protege.mv.db.adulterado-pelo-insider
mv data/protege.mv.db "$ADULTERADO"
log "Banco removido da pasta de dados. Restaurando do backup $(basename $BACKUP), conferindo antes o hash do manifesto"
ATUAL=$(sha256sum "$BACKUP" | cut -d' ' -f1)
REG=$(grep "$(basename $BACKUP)" data/backups/manifesto.sha256 | cut -d' ' -f1)
log "SHA-256 atual:      $ATUAL"
log "SHA-256 registrado: $REG"
[ "$ATUAL" = "$REG" ] && log "Confere: backup integro, pode restaurar" || { log "DIVERGE: restauracao recusada"; exit 1; }
unzip -o -q "$BACKUP" -d data
subir B
AUD=$(token auditor@protege.gov.br auditor123)
ADM=$(token admin@protege.gov.br admin123)
log "API restaurada | denuncias: $(total $ADM) | integridade: $(integridade $AUD)"
log "Arquivo adulterado preservado como prova: $ADULTERADO"
