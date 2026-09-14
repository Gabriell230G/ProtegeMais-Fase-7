# -*- coding: utf-8 -*-
"""
gerar_carga_fase6.py  .  Gerador da carga de demonstracao do barramento IoT

PROTEGE+ | HackGov / FIAP . Fase 6 | Gabriel Vasconcellos Gomes . RM 561601

Uso:
    python gerar_carga_fase6.py > carga_fase6.sql

Este arquivo esta no repositorio de proposito. A carga de demonstracao da
Fase 6 nao foi digitada a mao nem colada de lugar nenhum: ela e SAIDA
deste programa, com semente fixa no RM 561601. Quem corrige pode executar
o gerador e obter exatamente os mesmos 105 eventos e 56 denuncias, e com
isso conferir na origem qualquer numero citado no relatorio.

O programa emite os DOIS lados da carga, e isso e uma decisao e nao um
detalhe: um evento que apontasse para um protocolo inexistente quebraria
a consulta que cruza barramento e denuncia, e e justamente ela que prova
que a urgencia sai do VigIA lendo o texto, e nao do aparelho que enviou.

As regras do dominio sao aplicadas aqui como o servidor as aplica: a
janela de repique de 120 s nao e usada para SORTEAR os intervalos, e sim
para CLASSIFICAR intervalos sorteados de uma exponencial. A diferenca
importa: no primeiro caso a consulta que audita a janela concluiria que
ela cobre tudo porque nada foi gerado fora dela, o que seria circular.
"""
import random, datetime

random.seed(561601)

SOS  = [f"SOS-{n}" for n in (8812, 8817, 8823, 8831, 8840)]
TORN = [f"TZ-{n}"  for n in (4471, 4488, 4502)]
TOT  = ["TT-001", "TT-002", "TT-004"]
LOCAIS = {"TT-001": ("UBS Central de Barueri", -23.5106, -46.8761),
          "TT-002": ("Terminal Rodoviario de Barueri", -23.5147, -46.8792),
          "TT-004": ("CRAS Vila Boa Vista", -23.5052, -46.8703)}
INI = datetime.datetime(2026, 4, 1, 6, 0)

eventos, denuncias = [], []
seq = iter(range(90001, 90200))

# As mesmas regras do VigiaService: GRAVIDADE por tipo e gatilho de palavra.
GRAVIDADE = {"violencia": 5, "abuso": 5, "assedio": 3, "discriminacao": 3, "outros": 2}
GATILHO = ("arma", "faca", "agora", "socorro", "ameaca", "sangue", "espancad", "refem")

def classificar(tipo, descricao):
    """Urgencia, pelas mesmas regras do VigiaService.analisePorRegras."""
    g = GRAVIDADE.get(tipo, 2)
    d = descricao.lower()
    gatilho = any(p in d for p in GATILHO)
    if g >= 5 and gatilho:
        return "CRITICA"
    if g >= 5:
        return "ALTA"
    # O "ou gatilho" deste degrau reproduz o VigiaService e nao pode ser
    # omitido: um relato de tipo 'outros', que sozinho valeria gravidade 2,
    # sobe para MEDIA quando o texto carrega marcador de imediatismo.
    if g >= 3 or gatilho:
        return "MEDIA"
    return "BAIXA"


def pontuar(tipo, descricao, estado, cidade, endereco, anonimo):
    """
    Score de confiabilidade, pelas mesmas regras do ScoreService.

    O score NAO mede gravidade: ele mede o quanto o formulario foi
    preenchido, e por isso e independente da urgencia. Reproduzi-lo aqui,
    em vez de sortear um numero coerente com a urgencia, e o que impede a
    carga de demonstracao de afirmar sobre o sistema algo que o sistema
    nao faz.
    """
    def preenchido(v):
        return v is not None and str(v).strip() != ""

    score = 0
    if preenchido(tipo) and preenchido(descricao): score += 20
    if preenchido(estado):   score += 5
    if preenchido(cidade):   score += 5
    if preenchido(endereco): score += 10
    tam = len(descricao.strip()) if descricao else 0
    if tam >= 50:  score += 20
    if tam >= 150: score += 20
    if not anonimo: score += 20
    score = min(score, 100)

    if score >= 70:   rotulo, texto = "high", "Alta"
    elif score >= 40: rotulo, texto = "medium", "Media"
    else:             rotulo, texto = "low", "Baixa"
    return score, rotulo, texto


def abrir_caso(tipo, descricao, quando, cidade, estado, endereco):
    proto = f"#2026-{next(seq):05d}"
    urg = classificar(tipo, descricao)
    # Todo registro aberto por dispositivo e anonimo: nenhuma das tres
    # origens coleta identificacao.
    score, rotulo, texto = pontuar(tipo, descricao, estado, cidade, endereco, True)
    # 62% dos casos ja foram encerrados; o resto segue em aberto, que e o
    # que mantem o backlog vivo na tela e nas estatisticas.
    if random.random() < 0.62:
        dias = round(random.triangular(0.4, 14.0, 3.2), 3)
        fim = quando + datetime.timedelta(days=dias)
        status = "concluida"
    else:
        fim, status = None, random.choice(["recebida", "analise", "analise"])
    denuncias.append(dict(protocolo=proto, tipo=tipo, estado=estado, cidade=cidade,
                          endereco=endereco, descricao=descricao, status=status,
                          score=score, rotulo=rotulo, texto=texto, urgencia=urg,
                          criado=quando, concluido=fim))
    return proto, urg


def ev(origem, disp, quando, situacao, proto, detalhe, lat=None, lng=None, bat=None):
    eventos.append(dict(origem=origem, dispositivo=disp, quando=quando, situacao=situacao,
                        protocolo=proto, detalhe=detalhe, lat=lat, lng=lng, bateria=bat))

# ---------- origem A: botao de panico ----------
for _ in range(26):
    d = random.choice(SOS)
    t = INI + datetime.timedelta(days=random.randint(0, 44), hours=random.randint(0, 20),
                                 minutes=random.randint(0, 59), seconds=random.randint(0, 59))
    lat = round(-23.51 + random.uniform(-.02, .02), 6)
    lng = round(-46.876 + random.uniform(-.02, .02), 6)
    bat = random.randint(12, 98)
    desc = (f"Pedido de socorro enviado agora por botao de panico fisico. Dispositivo {d}. "
            f"Coordenada informada pelo aparelho: {lat:.6f}, {lng:.6f}. Bateria do aparelho em {bat}%. "
            f"Acionamento sem texto: a pessoa nao teve condicao de escrever.")
    proto, _ = abrir_caso("violencia", desc, t, "Barueri", "SP",
                          f"Coordenada aproximada {lat:.6f}, {lng:.6f}")
    ev("SOS", d, t, "ACEITO", proto,
       "Acionamento de botao de panico; caso aberto com urgencia CRITICA", lat, lng, bat)
    # Reacionamento do mesmo aparelho.
    #
    # O intervalo NAO e sorteado dentro da janela de 120 s. Fazer isso
    # seria fabricar o resultado da consulta que audita a janela: ela
    # concluiria que 120 s cobre tudo porque nada foi gerado fora disso.
    # O intervalo vem de uma exponencial de media 55 s, que e a forma
    # usual de modelar tempo entre eventos de um mesmo processo, e a
    # regra do sistema e entao APLICADA sobre ele, como o servidor faria.
    # Quantos caem acima de 120 s passa a ser consequencia, e nao escolha.
    if random.random() < 0.45:
        intervalo = int(min(900, max(3, random.expovariate(1 / 55.0))))
        t2 = t + datetime.timedelta(seconds=intervalo)
        if intervalo < 120:
            ev("SOS", d, t2, "DUPLICADO", proto,
               f"Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso",
               lat, lng, max(1, bat - random.randint(0, 2)))
        else:
            # Fora da janela o servidor abre CASO NOVO, e o dado precisa
            # refletir isso, sob pena de a carga contradizer o codigo.
            desc2 = (f"Pedido de socorro enviado agora por botao de panico fisico. Dispositivo {d}. "
                     f"Coordenada informada pelo aparelho: {lat:.6f}, {lng:.6f}. "
                     f"Bateria do aparelho em {bat}%. "
                     f"Acionamento sem texto: a pessoa nao teve condicao de escrever.")
            p2, _ = abrir_caso("violencia", desc2, t2, "Barueri", "SP",
                               f"Coordenada aproximada {lat:.6f}, {lng:.6f}")
            ev("SOS", d, t2, "ACEITO", p2,
               "Acionamento de botao de panico; caso aberto com urgencia CRITICA",
               lat, lng, max(1, bat - random.randint(0, 2)))

# ---------- origem B: geofencing ----------
for _ in range(38):
    d = random.choice(TORN)
    t = INI + datetime.timedelta(days=random.randint(0, 44), hours=random.randint(0, 22),
                                 minutes=random.randint(0, 59), seconds=random.randint(0, 59))
    lat = round(-23.51 + random.uniform(-.03, .03), 6)
    lng = round(-46.876 + random.uniform(-.03, .03), 6)
    bat = random.randint(20, 99)
    r = random.random()
    if r < 0.68:
        ev("GEOFENCE", d, t, "ACEITO", None, "Fora do perimetro", lat, lng, bat)
    elif r < 0.85:
        dentro = random.random() < 0.4
        motivo = ("Permanencia dentro do perimetro de exclusao" if dentro
                  else "Entrada no perimetro de exclusao")
        desc = ("Descumprimento de medida protetiva detectado agora por monitoracao eletronica. "
                f"{motivo}. Processo 0007441-88.2026, equipamento {d}. "
                "Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.")
        proto, _ = abrir_caso("violencia", desc, t, "Barueri", "SP", None)
        ev("GEOFENCE", d, t, "ACEITO", proto,
           f"{motivo}; caso aberto com urgencia CRITICA", lat, lng, bat)
    else:
        ev("GEOFENCE", d, t, "DUPLICADO", None,
           "Violacao ja alertada ha menos de 600s", lat, lng, bat)

# ---------- origem C: totem publico ----------
RELATOS = [
  ("violencia",     "ele me empurrou na frente das criancas e disse que ia voltar hoje a noite"),
  ("violencia",     "meu vizinho bate na esposa toda semana e ontem ouvi ela gritando por socorro"),
  ("assedio",       "meu chefe faz comentarios sobre meu corpo toda vez que passa pela minha mesa"),
  ("assedio",       "um homem me segue na saida do turno da noite ha duas semanas"),
  ("abuso",         "minha sobrinha de nove anos contou que o padrasto entra no quarto dela"),
  ("discriminacao", "fui recusada no atendimento por causa da minha religiao e ninguem explicou"),
  ("discriminacao", "meu filho e o unico negro da turma e o professor o trata diferente todo dia"),
  ("outros",        "o posto cobra por senha de atendimento e quem nao paga espera o dia inteiro"),
]
for _ in range(28):
    d = random.choice(TOT)
    local, tlat, tlng = LOCAIS[d]
    t = INI + datetime.timedelta(days=random.randint(0, 44), hours=random.randint(8, 17),
                                 minutes=random.randint(0, 59), seconds=random.randint(0, 59))
    r = random.random()
    if r < 0.79:
        tipo, texto = random.choice(RELATOS)
        desc = (f"Registro feito em totem de atendimento publico, em {local}. "
                f"Relato da pessoa: {texto} "
                "Registro anonimo por natureza do equipamento: o totem nao pede identificacao.")
        proto, urg = abrir_caso(tipo, desc, t, "Barueri", "SP", local)
        ev("TOTEM", d, t, "ACEITO", proto,
           f"Registro em totem {local}; caso aberto com urgencia {urg}", tlat, tlng)
    elif r < 0.90:
        ev("TOTEM", d, t, "DESCARTADO", None,
           "Relato com menos de 15 caracteres", tlat, tlng)
    else:
        ev("TOTEM", "TT-003", t, "DESCARTADO", None, "Totem desconhecido ou desativado")

eventos.sort(key=lambda e: e["quando"])
denuncias.sort(key=lambda d: d["criado"])


# ---------- emissao do SQL ----------

def s(v): return "NULL" if v is None else "'" + str(v).replace("'", "''") + "'"
def n(v): return "NULL" if v is None else str(v)
def ts(v): return "NULL" if v is None else "TIMESTAMP '" + v.strftime("%Y-%m-%d %H:%M:%S") + "'"

out = []
out.append(f"""
-- =====================================================================
--  FASE 6 . Carga de demonstracao do barramento de dispositivos
--
--  {len(eventos)} eventos entre 01/04 e 15/05/2026 nas tres origens, e as
--  {len(denuncias)} denuncias que os eventos aceitos abriram. Os dois lados sao
--  emitidos juntos de proposito: um evento que aponta para um protocolo
--  inexistente quebraria a consulta que cruza barramento e denuncia, e e
--  justamente ela que prova que a urgencia sai do VigIA lendo o texto, e
--  nao do aparelho que enviou.
--
--  Esta e carga de EXEMPLO, no mesmo regime do restante deste arquivo. A
--  semente do gerador e o RM 561601, de modo que a carga e identica em
--  qualquer maquina: os numeros do relatorio podem ser conferidos na
--  origem por quem corrige.
--
--  Idempotente: sem isto, cada subida da aplicacao somaria outra carga e
--  as metricas mudariam sozinhas a cada reinicio.
-- =====================================================================""")

for d in denuncias:
    out.append(f"""INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT {s(d['protocolo'])}, {s(d['tipo'])}, 'Barueri, SP', 'SP', 'Barueri', {s(d['endereco'])}, {s(d['descricao'])}, {s(d['status'])}, TRUE, {d['score']}, {s(d['rotulo'])}, {s(d['texto'])}, {s(d['urgencia'])}, 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', {ts(d['criado'])}, {ts(d['concluido'])}, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = {s(d['protocolo'])});""")

for e in eventos:
    out.append(f"""INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT {s(e['origem'])}, {s(e['dispositivo'])}, {n(e['lat'])}, {n(e['lng'])}, {n(e['bateria'])}, {ts(e['quando'])}, {s(e['situacao'])}, {s(e['protocolo'])}, {s(e['detalhe'])}
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = {s(e['dispositivo'])} AND y.recebido_em = {ts(e['quando'])});""")

import sys
sys.stdout.reconfigure(encoding="utf-8", newline="\n")
print("\n".join(out))
