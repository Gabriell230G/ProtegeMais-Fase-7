# Gera as figuras SVG do README do Protege+ (claro e escuro), no estilo do README do Controle S5.
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from svgkit import *

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
LOGO = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'logo.png')
os.makedirs(OUT, exist_ok=True)


def grava(nome, conteudo):
    open(os.path.join(OUT, nome), 'w', encoding='utf-8').write(conteudo)


def duplo(nome, fn):
    for tema in (CLARO, ESCURO):
        grava(f'{nome}-{tema["nome"]}.svg', fn(tema))


# ================================================================== cabecalho
def cabecalho():
    W, H = 1280, 360
    c = []
    c.append('<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1A4DA0"/>'
             '<stop offset=".55" stop-color="#123A80"/><stop offset="1" stop-color="#0A2559"/></linearGradient>'
             f'<clipPath id="r"><rect width="{W}" height="{H}" rx="18"/></clipPath>'
             '<filter id="sh" x="-20%" y="-20%" width="140%" height="160%"><feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#020B24" flood-opacity=".45"/></filter>'
             '<radialGradient id="brilho" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".22"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>'
             '</defs>')
    c.append('<g clip-path="url(#r)">')
    c.append(f'<rect width="{W}" height="{H}" fill="url(#g)"/>')
    c.append('<g fill="none" stroke="#FFFFFF">' + ''.join(
        f'<circle cx="1180" cy="-30" r="{r}" stroke-opacity="{o}" stroke-width="2"/>' for r, o in [(330, .07), (255, .06), (180, .05)]) + '</g>')
    c.append('<circle cx="700" cy="420" r="210" fill="#FFFFFF" fill-opacity=".035"/>')
    c.append('<g fill="#FFFFFF" fill-opacity=".10">' + ''.join(
        f'<circle cx="{620 + i * 18}" cy="{40 + j * 18}" r="1.4"/>' for i in range(9) for j in range(5)) + '</g>')
    # faixa das quatro cores
    for i, cor in enumerate(['#2E8B3A', '#0E7C8C', '#4C8DF6', '#F2A900']):
        c.append(f'<rect x="{i * W / 4}" y="{H - 7}" width="{W / 4}" height="7" fill="{cor}"/>')
    c.append('</g>')
    # logo com brilho
    c.append('<circle cx="112" cy="128" r="86" fill="url(#brilho)"/>')
    c.append(g_surge(f'<image x="62" y="70" width="100" height="117" href="{png_data(LOGO)}"/>', .05, .7))
    x0 = 196
    c.append(g_surge(texto('HACKGOV  ·  ENTERPRISE CHALLENGE EGESP  ·  FASE 7', x0, 84, 15, 600, '#FFFFFF', track=.12, op=.78), .1))
    t1 = texto('Protege', x0, 156, 70, 800, '#FFFFFF')
    wpr = largura('Protege', 70, 800)
    t2 = texto('+', x0 + wpr + 2, 156, 70, 800, '#7EE08E')
    c.append(g_surge(t1 + t2, .2, .7))
    c.append(g_surge(linhas(['Canal nacional de denúncias que protege quem denuncia', 'e prova, para quem fiscaliza, tudo o que o órgão fez.'],
                            x0, 202, 21, 31, w=400, fill='#FFFFFF', op=.88), .35))
    # chips
    cx = x0
    t = 'Atividade Visão de Futuro'
    wt = largura(t, 15, 600) + 32
    chip1 = rr(cx, 268, wt, 36, 18, fill='#FFFFFF', stroke='#FFFFFF', sw=1.5, extra=' fill-opacity=".12" stroke-opacity=".35"') + texto(t, cx + 16, 291, 15, 600, '#FFFFFF')
    cx += wt + 12
    t = 'Trilha ancorada em blockchain'
    wt2 = largura(t, 15, 600) + 50
    chip2 = (rr(cx, 268, wt2, 36, 18, fill='#FFFFFF') + f'<circle cx="{cx + 20}" cy="286" r="5" fill="#2E8B3A"/>'
             f'<circle cx="{cx + 20}" cy="286" r="5" fill="#2E8B3A">{pulso(5, 11, 2.2, .45)}</circle>' + texto(t, cx + 34, 291, 15, 600, '#0A2559'))
    c.append(g_surge(chip1 + chip2, .5))
    # cartao do painel
    px, py, pw, ph = 868, 46, 360, 262
    card = [rr(px, py, pw, ph, 14, fill='#FFFFFF', extra=' filter="url(#sh)"')]
    for i, cor in enumerate(['#FF5F57', '#FEBC2E', '#28C840']):
        card.append(f'<circle cx="{px + 22 + i * 15}" cy="{py + 21}" r="4.5" fill="{cor}"/>')
    card.append(texto('FILA DE ATENDIMENTO', px + pw - 18, py + 26, 11.5, 700, '#57606A', 'end', track=.1))
    card.append(f'<line x1="{px}" y1="{py + 42}" x2="{px + pw}" y2="{py + 42}" stroke="#E6EAEF" stroke-width="1.5"/>')
    for t, xx in [('PROTOCOLO', px + 18), ('TIPO', px + 132), ('URGÊNCIA', px + pw - 18)]:
        card.append(texto(t, xx, py + 64, 10.5, 600, '#8C959F', 'end' if t == 'URGÊNCIA' else 'start', track=.08))
    linhas_f = [('CRÍTICA', '#CF222E', '#FFEBE9'), ('ALTA', '#BC4C00', '#FFF1E5'), ('MÉDIA', '#9A6700', '#FFF8C5')]
    for i, (rot, cor, fundo) in enumerate(linhas_f):
        yy = py + 80 + i * 38
        row = ''
        if i == 0:
            row += rr(px + 8, yy - 4, pw - 16, 34, 8, fill='#FFF4F4')
        row += rr(px + 18, yy + 7, 88, 8, 4, fill='#D0D7DE') + rr(px + 132, yy + 4, 76, 7, 3.5, fill='#D0D7DE') + rr(px + 132, yy + 15, 52, 6, 3, fill='#E6EAEF')
        wc = largura(rot, 11, 700) + 18
        row += rr(px + pw - 18 - wc, yy + 1, wc, 22, 11, fill=fundo) + texto(rot, px + pw - 18 - wc / 2, yy + 16, 11, 700, cor, 'middle', track=.04)
        card.append(g_surge(row, .7 + i * .18, .5, 4))
    yb = py + ph - 46
    card.append(f'<line x1="{px}" y1="{yb - 12}" x2="{px + pw}" y2="{yb - 12}" stroke="#E6EAEF" stroke-width="1.5"/>')
    card.append(texto('Trilha de auditoria  ·  checkpoint #12 ancorado', px + 18, yb + 8, 12, 500, '#424A53'))
    card.append(rr(px + 18, yb + 20, pw - 36, 7, 3.5, fill='#E6EAEF'))
    card.append(f'<rect x="{px + 18}" y="{yb + 20}" width="{pw - 36}" height="7" rx="3.5" fill="#2E8B3A">'
                f'<animate attributeName="width" values="0;0;{pw - 36}" keyTimes="0;.4;1" dur="2.4s" fill="freeze" {SPL}/></rect>')
    c.append(g_surge(''.join(card), .3, .7, 10))
    # selo verificado
    sx, sy = px + pw - 6, py + ph - 4
    c.append(f'<circle cx="{sx}" cy="{sy}" r="26" fill="#2E8B3A" opacity=".35">{pulso(26, 40, 2.4, .35)}</circle>')
    c.append(g_surge(f'<circle cx="{sx}" cy="{sy}" r="26" fill="#2E8B3A" stroke="#FFFFFF" stroke-width="4"/>'
                     f'<path d="M{sx - 10} {sy + 1} L{sx - 3} {sy + 8} L{sx + 11} {sy - 7}" fill="none" stroke="#FFFFFF" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>', 1.6, .5, 0))
    grava('header.svg', svg(W, H, ''.join(c), 'Protege+: canal nacional de denúncias que protege quem denuncia e prova, para quem fiscaliza, tudo o que o órgão fez'))


# ================================================================== selos (badges)
SELOS = [('linguagem', 'Java 17', '#B85A00'), ('framework', 'Spring Boot 3.3', '#3F7F20'), ('contrato', 'Solidity 0.8.28', '#5B5FC7'),
         ('borda', 'nginx · TLS 1.3 · mTLS', '#0F7A3B'), ('testes', '217 + 21 · 0 falhas', '#1A7F37'),
         ('ataques', '11 de 11 bloqueados', '#B42318'), ('LGPD', 'nada pessoal fora do sistema', '#1A4DA0')]


def selos():
    for i, (rot, val, cor) in enumerate(SELOS, 1):
        w1 = largura(rot, 13, 500) + 22
        w2 = largura(val, 13, 600) + 22
        W = w1 + w2
        c = (rr(0, 0, W, 28, 6, fill=cor) + f'<path d="M6 0 H{w1} V28 H6 A6 6 0 0 1 0 22 V6 A6 6 0 0 1 6 0Z" fill="#24292F"/>'
             + texto(rot, 11, 18.5, 13, 500, '#FFFFFF') + texto(val, w1 + 11, 18.5, 13, 600, '#FFFFFF'))
        grava(f'selo-{i}.svg', svg(round(W, 1), 28, c, f'{rot}: {val}'))


BOTOES = [('site', 'Acessar o site', '#1A4DA0', 'play'), ('video', 'Vídeo da Fase 7', '#CF222E', 'play'),
          ('documento', 'Documento técnico', '#24292F', 'doc'), ('relatorio', 'Relatório final EGESP', '#24292F', 'doc')]


def botoes():
    for nome, t, cor, ic in BOTOES:
        wt = largura(t, 15, 600)
        W = wt + 66
        c = rr(0, 0, W, 42, 21, fill=cor) + icone(ic, 24, 21, 20, '#FFFFFF', 2.4) + texto(t, 44, 26.5, 15, 600, '#FFFFFF')
        grava(f'botao-{nome}.svg', svg(round(W, 1), 42, c, t))


SECOES = {'visao': 'bussola', 'fase': 'estrela', 'seguranca': 'escudo', 'redes': 'rede', 'estatistica': 'grafico', 'blockchain': 'bloco',
          'anteriores': 'relogio', 'executar': 'play', 'usuarios': 'pessoas', 'arquitetura': 'camadas', 'endpoints': 'tomada',
          'banco': 'banco', 'testes': 'frasco', 'estrutura': 'pasta', 'docs': 'doc', 'roadmap': 'bandeira', 'funcoes': 'faisca'}


def icones_secao():
    for nome, ic in SECOES.items():
        grava(f'ic-{nome}.svg', f'<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">'
              f'<path d="{ICONES[ic]}" fill="none" stroke="#3B7DDD" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>')


# ================================================================== numeros
def numeros(T):
    W, H = 1280, 172
    dados = [('26', 'falhas de segurança corrigidas', T['azul']), ('11/11', 'ataques reais bloqueados', T['azul']),
             ('39/39', 'verificações de rede', T['tq']), ('217+21', 'testes automatizados', T['vd'])]
    g, n = 24, len(dados)
    cw = (W - 4 - g * (n - 1)) / n
    c = []
    for i, (num, rot, cor) in enumerate(dados):
        x = 2 + i * (cw + g)
        t = (rr(x, 2, cw, H - 4, 16, fill=T['card'], stroke=T['borda'], sw=1.5) + texto(num, x + 26, 78, 50, 700, cor)
             + texto(rot, x + 26, 114, 18, 500, T['sec']))
        lb = cw * .62
        t += (f'<line x1="{x + 26}" y1="140" x2="{x + 26 + lb:.1f}" y2="140" stroke="{cor}" stroke-width="5" stroke-linecap="round" '
              f'stroke-dasharray="{lb:.0f}" stroke-dashoffset="{lb:.0f}">{desenha(lb, .3 + i * .15, 1.0)}</line>')
        c.append(g_surge(t, i * .15, .6))
    return svg(W, H, ''.join(c), 'Em números: 26 falhas de segurança corrigidas; 11 de 11 ataques reais bloqueados; 39 de 39 verificações de rede; 217 testes Java e 21 do contrato')


# ================================================================== cartoes em fluxo (generico)
def cartoes_fluxo(T, passos, W=1280, H=290, destaque=None, tag=None, titulo=''):
    n = len(passos)
    gap = 54
    cw = (W - 4 - gap * (n - 1)) / n
    ch = H - 40
    y0 = 30
    c = []
    for i, (ic, tit, sub) in enumerate(passos):
        x = 2 + i * (cw + gap)
        dst = (i == destaque)
        cor = T['azul']
        p = rr(x, y0, cw, ch, 16, fill=T['card'], stroke=cor if dst else T['borda'], sw=2.5 if dst else 1.5)
        p += f'<circle cx="{x + 24}" cy="{y0 + 24}" r="12" fill="{cor}" fill-opacity=".12"/>' + texto(str(i + 1), x + 24, y0 + 29, 13, 700, cor, 'middle')
        p += f'<circle cx="{x + cw / 2:.1f}" cy="{y0 + 76}" r="34" fill="{cor}" fill-opacity=".10"/>' + icone(ic, x + cw / 2, y0 + 76, 34, cor, 2.6)
        p += texto(tit, x + cw / 2, y0 + 146, 21, 600, T['ink'], 'middle')
        p += linhas(sub, x + cw / 2, y0 + 176, 15.5, 22, w=400, fill=T['mut'], anchor='middle')
        if dst and tag:
            wt = largura(tag, 12, 700, .08) + 26
            p += rr(x + cw / 2 - wt / 2, y0 - 13, wt, 26, 13, fill=cor) + texto(tag, x + cw / 2, y0 + 4, 12, 700, T['card'] if T['nome'] == 'dark' else '#FFFFFF', 'middle', track=.08)
        c.append(g_surge(p, .1 + i * .18, .55))
        if i < n - 1:
            ax = x + cw + 8
            c.append(f'<line x1="{ax}" y1="{y0 + ch / 2}" x2="{ax + gap - 22}" y2="{y0 + ch / 2}" stroke="{T["mut"]}" stroke-width="2" '
                     f'stroke-dasharray="6 6" stroke-linecap="round">{marcha(1.2, 12)}</line>'
                     f'<path d="M{ax + gap - 24} {y0 + ch / 2 - 6} L{ax + gap - 16} {y0 + ch / 2} L{ax + gap - 24} {y0 + ch / 2 + 6}" fill="none" stroke="{T["mut"]}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>')
    return svg(W, H, ''.join(c), titulo)


def fluxo(T):
    passos = [('lapis', 'Denúncia', ['anônima ou identificada,', 'com protocolo']),
              ('faisca', 'VigIA', ['classifica a urgência;', 'a IA só sobe, nunca baixa']),
              ('lista', 'Fila priorizada', ['urgência, score', 'e antiguidade']),
              ('olho', 'Atendimento', ['cada perfil vê só', 'o que precisa ver']),
              ('corrente', 'Trilha ancorada', ['hash encadeado e', 'testemunha na blockchain'])]
    return cartoes_fluxo(T, passos, destaque=4, tag='NOVO NA FASE 7',
                         titulo='Fluxo: 1 Denúncia anônima ou identificada, com protocolo ➜ 2 VigIA classifica a urgência ➜ 3 Fila priorizada ➜ 4 Atendimento por perfil ➜ 5 Trilha ancorada na blockchain')


# ================================================================== as quatro partes
def partes(T):
    W, H = 1280, 372
    dados = [('PARTE 1', 'Segurança', T['azul'], 'escudo', '26', 'falhas corrigidas', ['11 ataques reais, 11 bloqueados', 'políticas escritas do código', 'backup verificado por hash']),
             ('PARTE 2', 'Redes', T['tq'], 'rede', '39/39', 'verificações de rede', ['borda nginx com TLS 1.3', 'certificado por aparelho', 'API caída responde 190 e 180']),
             ('PARTE 3', 'Estatística', T['lj'], 'grafico', 'r = −0,50', 'gravidade × prazo', ['p-valor e intervalo de 95%', 'regressão simples e múltipla', 'equipe necessária: 5, não 3']),
             ('PARTE 4', 'Blockchain', T['vd'], 'bloco', '0', 'dados pessoais na cadeia', ['contrato AncoraProtege', '21 testes, 100% das linhas', 'pega o corte que ninguém vê'])]
    g = 24
    cw = (W - 4 - g * 3) / 4
    c = []
    for i, (eb, tit, cor, ic, num, rot, bl) in enumerate(dados):
        x = 2
        x = 2 + i * (cw + g)
        p = rr(x, 2, cw, H - 4, 16, fill=T['card'], stroke=T['borda'], sw=1.5)
        p += f'<clipPath id="cp{i}"><rect x="{x}" y="2" width="{cw}" height="{H - 4}" rx="16"/></clipPath><rect x="{x}" y="2" width="{cw}" height="7" fill="{cor}" clip-path="url(#cp{i})"/>'
        p += f'<circle cx="{x + cw - 44:.1f}" cy="58" r="26" fill="{cor}" fill-opacity=".12"/>' + icone(ic, x + cw - 44, 58, 28, cor, 2.6)
        p += texto(eb, x + 24, 50, 13, 700, cor, track=.12) + texto(tit, x + 24, 80, 26, 700, T['ink'])
        p += texto(num, x + 24, 146, 40, 700, T['ink']) + texto(rot, x + 24, 174, 16, 500, T['mut'])
        p += f'<line x1="{x + 24}" y1="200" x2="{x + cw - 24:.1f}" y2="200" stroke="{T["grade"]}" stroke-width="1.5"/>'
        for j, b in enumerate(bl):
            yy = 236 + j * 40
            p += icone('check', x + 36, yy - 6, 20, cor, 2.4) + texto(b, x + 56, yy, 16, 500, T['sec'])
        c.append(g_surge(p, .1 + i * .15, .6))
    return svg(W, H, ''.join(c), 'As quatro Partes da Fase 7: Segurança (26 falhas corrigidas, 11 ataques bloqueados); Redes (39 de 39 verificações); Estatística (correlação −0,50 entre gravidade e prazo); Blockchain (nenhum dado pessoal na cadeia)')


# ================================================================== ataques
ATAQ = [('C01', 'Entrar como administrador', 'token com o segredo antigo', '401 · 401 · 401', 'C I'),
        ('C02', 'Ver mais do que o perfil permite', '6 ações fora do perfil', '403 nas seis', 'C'),
        ('C03', 'Descobrir a senha de um servidor', '25 senhas com IP falso', '16 × 401, depois 429', 'C D'),
        ('C04', 'Descobrir se há denúncia', '40 protocolos sorteados', '0 encontrados, 429', 'C'),
        ('C05', 'Rodar script no painel', '<script> numa denúncia', 'guardado como texto', 'I'),
        ('C06', 'Enterrar casos reais', '8 denúncias falsas seguidas', '4 aceitas, 4 × 429', 'D'),
        ('C07', 'Plantar malware como prova', '.exe renomeado; 7 MB', '415 e 413', 'I D'),
        ('C08', 'Esgotar a memória', 'JSON de 400 KB sem login', '413 antes de ler', 'D'),
        ('C09', 'Localizar a vítima', 'tornozeleira sem chave', 'nenhum dado de local', 'C'),
        ('C10', 'Sequestrar os dados', 'ransomware no backup', 'marcado ALTERADO', 'I D'),
        ('C11', 'Não deixar rastro', 'conferir a trilha', '22 recusas registradas', 'I')]


def ataques(T):
    import textwrap
    W, cols, rows = 1280, 4, 3
    g = 18
    cw = (W - 4 - g * (cols - 1)) / cols
    ch = 166
    H = rows * ch + (rows - 1) * g + 4
    c = []
    for i in range(12):
        col, lin = i % cols, i // cols
        x, y = 2 + col * (cw + g), 2 + lin * (ch + g)
        if i == 11:
            p = rr(x, y, cw, ch, 14, fill=T['ink']) + texto('11 de 11', x + cw / 2, y + 74, 44, 700, T['card'], 'middle')
            p += texto('ataques bloqueados', x + cw / 2, y + 106, 17, 500, T['card'], 'middle', op=.85)
            p += texto('0 falhas · 27/10/2026', x + cw / 2, y + 138, 14, 500, T['card'], 'middle', op=.6)
            c.append(g_surge(p, .2 + i * .07, .5))
            continue
        cod, obj, como, resp, pil = ATAQ[i]
        p = rr(x, y, cw, ch, 14, fill=T['card'], stroke=T['borda'], sw=1.5)
        p += texto(cod, x + 20, y + 32, 14, 700, T['mut'], track=.06)
        xx = x + cw - 18
        for pl in reversed(pil.split()):
            p += f'<circle cx="{xx - 12}" cy="{y + 27}" r="12" fill="{T["p" + pl]}"/>' + texto(pl, xx - 12, y + 32, 12.5, 700, T['tx' + pl], 'middle')
            xx -= 30
        ol = textwrap.wrap(obj, 25)
        p += linhas(ol, x + 20, y + 64, 17.5, 23, w=600, fill=T['ink'])
        p += texto(como, x + 20, y + 64 + 23 * len(ol) + 2, 14.5, 400, T['mut'])
        p += f'<line x1="{x + 20}" y1="{y + ch - 44}" x2="{x + cw - 20:.1f}" y2="{y + ch - 44}" stroke="{T["grade"]}" stroke-width="1.5"/>'
        p += icone('check', x + 30, y + ch - 21, 20, T['ok'], 2.4) + texto(resp, x + 48, y + ch - 15, 15, 600, T['ink'])
        c.append(g_surge(p, .1 + i * .07, .5))
    return svg(W, H, ''.join(c), 'Os 11 ataques simulados contra a API real, todos bloqueados: ' + '; '.join(f'{a[0]} {a[1]}: {a[3]}' for a in ATAQ))


# ================================================================== topologia
def topologia(T):
    W, H = 1280, 494
    c = []
    def zona(x, y, w, h, nome, cor, dash=False, atraso=0):
        z = rr(x, y, w, h, 16, fill=cor, stroke=cor, sw=1.5, extra=f' fill-opacity=".06" stroke-opacity=".55"' + (' stroke-dasharray="7 6"' if dash else ''))
        z += texto(nome, x + 18, y + 30, 13, 700, cor, track=.1)
        return g_surge(z, atraso, .5)
    def caixa(x, y, w, h, ic, tit, sub, cor, atraso, forte=False):
        b = rr(x, y, w, h, 12, fill=T['card'], stroke=cor if forte else T['borda'], sw=2.2 if forte else 1.5)
        b += f'<circle cx="{x + 30}" cy="{y + h / 2}" r="18" fill="{cor}" fill-opacity=".12"/>' + icone(ic, x + 30, y + h / 2, 20, cor, 2.4)
        b += texto(tit, x + 58, y + h / 2 - 3, 16, 600, T['ink']) + texto(sub, x + 58, y + h / 2 + 17, 13, 400, T['mut'])
        return g_surge(b, atraso, .5)
    # zonas
    c.append(zona(2, 2, 250, 330, 'INTERNET', T['mut']))
    c.append(zona(282, 2, 280, 330, 'DMZ', T['lj'], atraso=.15))
    c.append(zona(592, 2, 300, 330, 'APLICAÇÃO', T['azul'], atraso=.3))
    c.append(zona(922, 2, 356, 330, 'DADOS', T['tq'], atraso=.45))
    c.append(zona(2, 352, 560, 140, 'GESTÃO', T['mut'], dash=True, atraso=.6))
    c.append(zona(592, 352, 686, 140, 'FORA DO SERVIDOR', T['vd'], atraso=.75))
    # caixas
    c.append(caixa(20, 60, 214, 70, 'pessoas', 'Cidadã', 'navegador ou celular', T['mut'], .2))
    c.append(caixa(20, 150, 214, 70, 'servidor', 'Servidor público', 'painel com perfil', T['mut'], .25))
    c.append(caixa(20, 240, 214, 70, 'alerta', 'Aparelhos de campo', 'cada um com certificado', T['mut'], .3))
    c.append(caixa(300, 120, 244, 110, 'cadeado', 'nginx', 'TLS 1.3 · TLS mútuo', T['lj'], .4, True))
    tg = 'TESTADO NESTA FASE'
    wt = largura(tg, 11, 700, .08) + 22
    c.append(g_surge(rr(422 - wt / 2, 107, wt, 24, 12, fill=T['lj']) + texto(tg, 422, 123, 11, 700, '#FFFFFF', 'middle', track=.08), .9))
    c.append(g_surge(texto('limites · CSP · HSTS', 422, 258, 13, 500, T['mut'], 'middle') + texto('39 verificações, 0 falhas', 422, 280, 13, 600, T['lj'], 'middle'), .5))
    c.append(caixa(612, 80, 260, 70, 'servidor', 'API Protege+ #1', 'Spring Boot, JWT, perfis', T['azul'], .5))
    c.append(caixa(612, 190, 260, 70, 'servidor', 'API Protege+ #2', 'se a #1 cair, a #2 atende', T['azul'], .55))
    c.append(caixa(942, 60, 316, 70, 'banco', 'PostgreSQL primário', 'trilha encadeada por SHA-256', T['tq'], .6))
    c.append(caixa(942, 150, 316, 70, 'banco', 'Réplica contínua', 'em outra zona', T['tq'], .65))
    c.append(caixa(942, 240, 316, 70, 'cadeado', 'Backup cifrado', 'hash no manifesto e na trilha', T['tq'], .7))
    c.append(caixa(20, 400, 520, 70, 'chave', 'VPN com segundo fator', 'único caminho para administrar; tudo registrado', T['mut'], .8))
    c.append(caixa(612, 400, 646, 70, 'bloco', 'Blockchain (Rede Blockchain Brasil)', 'ancoragem horária da trilha e das evidências: nada pessoal', T['vd'], .85))
    # fluxos
    def fio(d, cor, atraso):
        return (f'<path d="{d}" fill="none" stroke="{cor}" stroke-width="2.2" stroke-dasharray="7 7" stroke-linecap="round">'
                f'{surge(atraso, .4)}{marcha(1.1, 14)}</path>')
    for y in (95, 185, 275):
        c.append(fio(f'M236 {y} C268 {y} 268 175 298 175', T['mut'], 1.0))
    c.append(fio('M546 165 C580 165 580 115 610 115', T['lj'], 1.1))
    c.append(fio('M546 185 C580 185 580 225 610 225', T['lj'], 1.1))
    c.append(fio('M874 115 C908 115 908 95 940 95', T['azul'], 1.2))
    c.append(fio('M874 225 C908 225 908 105 940 105', T['azul'], 1.2))
    c.append(fio('M1100 132 L1100 148', T['tq'], 1.3))
    c.append(fio('M832 262 L832 398', T['vd'], 1.4))
    return svg(W, H, ''.join(c), 'Topologia de rede em zonas: a internet só alcança a borda nginx (DMZ, testada nesta fase), a borda só alcança as duas instâncias da API, e só a API alcança o banco com réplica e backup; administração só por VPN; a trilha é ancorada na blockchain')


# ================================================================== correlacoes (forest plot)
def correlacoes(T):
    W, H = 1280, 380
    dados = [('Gravidade do tipo', -0.50, -0.62, -0.35, '< 0,001'), ('Urgência da triagem', -0.25, -0.41, -0.08, '0,005'),
             ('Tamanho do relato', 0.09, -0.09, 0.27, '0,303'), ('Score de confiabilidade', -0.03, -0.20, 0.15, '0,764'),
             ('Denúncia anônima', -0.02, -0.19, 0.16, '0,852')]
    x0, x1, vmin, vmax = 300, 900, -0.7, 0.4
    X = lambda v: x0 + (x1 - x0) * (v - vmin) / (vmax - vmin)
    y0, dy = 70, 52
    c = [rr(2, 2, W - 4, H - 4, 16, fill=T['card'], stroke=T['borda'], sw=1.5)]
    for v in (-0.6, -0.4, -0.2, 0, 0.2, 0.4):
        c.append(f'<line x1="{X(v):.1f}" y1="{y0 - 26}" x2="{X(v):.1f}" y2="{y0 + dy * 4 + 26}" stroke="{T["grade"]}" stroke-width="1.5"/>')
        c.append(texto(f'{v:.1f}'.replace('.', ',').replace('-', '−') if v else '0', X(v), y0 + dy * 4 + 52, 14, 500, T['mut'], 'middle'))
    c.append(f'<line x1="{X(0):.1f}" y1="{y0 - 26}" x2="{X(0):.1f}" y2="{y0 + dy * 4 + 26}" stroke="{T["sec"]}" stroke-width="2"/>')
    c.append(texto('r', 952, 36, 13, 700, T['mut'], track=.08) + texto('IC 95%', 1030, 36, 13, 700, T['mut'], track=.08))
    for i, (nome, r, lo, hi, p) in enumerate(dados):
        y = y0 + i * dy
        sig = not (lo <= 0 <= hi)
        cor = T['azul'] if sig else T['mut']
        L = X(hi) - X(lo)
        row = texto(nome, x0 - 24, y + 6, 17, 600 if sig else 400, T['ink'], 'end')
        row += (f'<line x1="{X(lo):.1f}" y1="{y}" x2="{X(hi):.1f}" y2="{y}" stroke="{cor}" stroke-width="4" stroke-linecap="round" '
                f'stroke-dasharray="{L:.0f}" stroke-dashoffset="{L:.0f}">{desenha(L, .3 + i * .15, .8)}</line>')
        row += f'<circle cx="{X(r):.1f}" cy="{y}" r="9" fill="{cor}" stroke="{T["card"]}" stroke-width="3"/>'
        rt = f'{r:+.2f}'.replace('.', ',').replace('-', '−').replace('+', '')
        ci = f'[{lo:.2f}; {hi:.2f}]'.replace('.', ',').replace('-', '−')
        row += texto(rt, 952, y + 6, 17, 700 if sig else 400, T['ink']) + texto(ci, 1030, y + 6, 15, 400, T['sec'])
        lb = 'relação' if sig else 'sem evidência'
        row += texto(lb, W - 26, y + 6, 14.5, 600 if sig else 400, cor if sig else T['mut'], 'end')
        c.append(g_surge(row, .1 + i * .15, .5))
    c.append(texto('◂ quanto mais grave, mais rápido', X(-0.68), y0 + dy * 4 + 52, 13.5, 500, T['mut']) if False else '')
    c.append(texto('correlação com o tempo até a conclusão (n = 123), com intervalo de 95%', (x0 + x1) / 2, H - 22, 14, 500, T['mut'], 'middle'))
    return svg(W, H, ''.join(c), 'Correlação com o tempo de atendimento: gravidade do tipo −0,50 e urgência −0,25 têm relação; tamanho do relato, score de confiabilidade e anonimato não têm evidência de relação')


# ================================================================== ancoragem (decisao, no estilo do S5)
def ancoragem(T):
    W, H = 1280, 430
    c = []
    # loop tracejado de volta
    c.append(f'<path d="M1110 150 C1110 40 760 30 640 30 C520 30 200 40 200 150" fill="none" stroke="{T["mut"]}" stroke-width="2" stroke-dasharray="7 7" opacity=".7">{marcha(1.4, 14)}</path>')
    c.append(f'<path d="M193 140 L200 152 L207 140" fill="none" stroke="{T["mut"]}" stroke-width="2" stroke-linecap="round"/>')
    wt = largura('a cada hora', 14, 500) + 28
    c.append(rr(640 - wt / 2, 17, wt, 28, 14, fill=T['card'], stroke=T['borda']) + texto('a cada hora', 640, 36, 14, 500, T['mut'], 'middle'))
    # caixa 1
    b = rr(40, 160, 320, 104, 14, fill=T['card'], stroke=T['borda']) + texto('Rotina de ancoragem', 200, 200, 21, 600, T['ink'], 'middle')
    b += texto('lê o estado da trilha na API', 200, 228, 15, 400, T['mut'], 'middle')
    b += rr(64, 278, 272, 40, 12, fill=T['card2'], stroke=T['borda']) + texto('último checkpoint', 84, 304, 14, 500, T['mut']) + texto('#12', 316, 305, 18, 700, T['ink'], 'end')
    c.append(g_surge(b, .1))
    c.append(f'<line x1="362" y1="212" x2="458" y2="212" stroke="{T["mut"]}" stroke-width="2"/><path d="M450 205 L460 212 L450 219" fill="none" stroke="{T["mut"]}" stroke-width="2" stroke-linecap="round"/>')
    c.append(f'<circle cx="376" cy="212" r="6" fill="{T["vd"]}"/>')
    # losango
    cx, cy, rx, ry = 640, 212, 178, 92
    los = f'<path d="M{cx} {cy - ry} L{cx + rx} {cy} L{cx} {cy + ry} L{cx - rx} {cy} Z" fill="{T["ruimbg"]}" stroke="{T["ruim"]}" stroke-width="2"/>'
    los += texto('O último checkpoint', cx, cy - 10, 18, 600, T['ink'], 'middle') + texto('ainda confere?', cx, cy + 18, 18, 700, T['ruim'], 'middle')
    c.append(g_surge(los, .35))
    # sim
    c.append(f'<line x1="{cx + rx + 2}" y1="{cy}" x2="{908}" y2="{cy}" stroke="{T["mut"]}" stroke-width="2"/><path d="M900 205 L910 212 L900 219" fill="none" stroke="{T["mut"]}" stroke-width="2" stroke-linecap="round"/>')
    c.append(texto('SIM', 862, cy - 12, 13, 700, T['ok'], 'middle', track=.1))
    ok = rr(912, 152, 336, 120, 14, fill=T['okbg'], stroke=T['ok'], sw=2) + texto('Ancora o novo checkpoint', 1080, 196, 20, 600, T['ink'], 'middle')
    ok += texto('hash da trilha + raiz Merkle', 1080, 224, 15, 400, T['sec'], 'middle') + texto('das evidências; nada pessoal', 1080, 246, 15, 400, T['sec'], 'middle')
    c.append(g_surge(ok, .6))
    # nao
    c.append(f'<line x1="{cx}" y1="{cy + ry + 2}" x2="{cx}" y2="342" stroke="{T["mut"]}" stroke-width="2"/><path d="M633 334 L640 344 L647 334" fill="none" stroke="{T["mut"]}" stroke-width="2" stroke-linecap="round"/>')
    c.append(texto('NÃO', cx + 16, 324, 13, 700, T['ruim'], track=.1))
    ruim = rr(440, 346, 400, 74, 14, fill=T['ruimbg'], stroke=T['ruim'], sw=2) + texto('Recusa e dá o alerta', 640, 378, 19, 600, T['ink'], 'middle')
    ruim += texto('a trilha foi cortada ou alterada', 640, 404, 15, 400, T['sec'], 'middle')
    c.append(g_surge(ruim, .8))
    return svg(W, H, ''.join(c), 'Ancoragem: a cada hora a rotina lê o estado da trilha; se o último checkpoint ainda confere, ancora um novo (hash da trilha e raiz Merkle das evidências, nada pessoal); se não confere, recusa e dá o alerta, porque a trilha foi cortada ou alterada')


# ================================================================== estrada (como executar)
def estrada(T):
    W, H = 1280, 470
    xs = [130, 334, 538, 742, 946, 1150]
    yc, A = 235, 62
    Y = lambda x: yc - A * math.cos(math.pi * (x - xs[0]) / (xs[1] - xs[0]))
    pts = [(x, Y(x)) for x in range(10, 1231, 6)]
    d = 'M' + ' L'.join(f'{x:.0f} {y:.1f}' for x, y in pts)
    comp = sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))
    c = [f'<path d="{d}" fill="none" stroke="{T["estrada"]}" stroke-width="38" stroke-linecap="round"/>',
         f'<path d="{d}" fill="none" stroke="{T["linha_estrada"]}" stroke-width="3" stroke-dasharray="14 12" stroke-linecap="round"/>',
         f'<path d="{d}" fill="none" stroke="{T["azul"]}" stroke-width="6" stroke-linecap="round" stroke-dasharray="{comp:.0f}" stroke-dashoffset="{comp:.0f}" opacity=".85">{desenha(comp, .2, 2.6)}</path>']
    # bandeira
    fx, fy = 1238, Y(1230)
    c.append(f'<line x1="{fx}" y1="{fy - 6}" x2="{fx}" y2="{fy - 62}" stroke="{T["ink"]}" stroke-width="3"/><path d="M{fx} {fy - 62} L{fx - 30} {fy - 52} L{fx} {fy - 42} Z" fill="{T["vd"]}"/>')
    paradas = [('play', 'JDK 17', ['o Maven vem sozinho', 'na primeira execução'], False),
               ('frasco', 'Testes', ['.\\build.cmd clean test', '217 testes, 0 falhas'], True),
               ('servidor', 'API no ar', ['.\\build.cmd run', 'localhost:8080'], True),
               ('globo', 'Site', ['py -m http.server 5500', 'localhost:5500'], True),
               ('chave', 'Entrar', ['admin@protege.gov.br', 'senha admin123'], False),
               ('escudo', 'Provas', ['ataques, rede e', 'blockchain gravados'], False)]
    for i, (x, (ic, tit, sub, cmd)) in enumerate(zip(xs, paradas)):
        y = Y(x)
        cima = (i % 2 == 0)
        p = f'<circle cx="{x}" cy="{y:.1f}" r="30" fill="{T["card"]}" stroke="{T["azul"]}" stroke-width="2.5"/>' + icone(ic, x, y, 26, T['azul'], 2.4)
        p += f'<circle cx="{x + 22}" cy="{y - 22:.1f}" r="12" fill="{T["azul"]}"/>' + texto(str(i + 1), x + 22, y - 17.5, 13, 700, '#FFFFFF', 'middle')
        ty = y - 108 if cima else y + 70
        p += texto(tit, x, ty, 20, 600, T['ink'], 'middle')
        for j, s in enumerate(sub):
            mono = cmd and j == 0
            p += texto(s.replace('\\\\', '\\'), x, ty + 26 + j * 22, 14 if mono else 15, 'mono' if mono else 400, T['azul'] if mono else T['mut'], 'middle')
        c.append(g_surge(p, .3 + i * .35, .5))
    return svg(W, H, ''.join(c), 'Como executar: 1 JDK 17 ➜ 2 testes com build.cmd clean test (217, 0 falhas) ➜ 3 API no ar com build.cmd run ➜ 4 site com py -m http.server 5500 ➜ 5 entrar como admin ➜ 6 provas gravadas de ataques, rede e blockchain')


# ================================================================== linha do tempo do projeto
def linha_tempo(T):
    import datetime
    W, H = 1280, 330
    d0 = datetime.date(2026, 3, 1)
    X = lambda d, m: 150 + (1010 - 150) * ((datetime.date(2026, m, d) - d0).days) / ((datetime.date(2026, 11, 3) - d0).days)
    yH, yE = 120, 220
    c = []
    for i, nm in enumerate(['mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov']):
        xm = X(1, 3 + i)
        c.append(f'<line x1="{xm:.1f}" y1="60" x2="{xm:.1f}" y2="270" stroke="{T["grade"]}" stroke-width="1.5"/>' + texto(nm, xm + 6, 296, 13.5, 500, T['mut']))
    for y, nome, cor in [(yH, 'HackGov', T['azul']), (yE, 'Enterprise', T['am'])]:
        L = X(3, 11) - X(10, 3)
        c.append(texto(nome, 16, y + 6, 16, 700, T['ink']))
        if nome == 'Enterprise':
            c.append(texto('Challenge', 16, y + 26, 16, 700, T['ink']))
        c.append(f'<line x1="{X(10, 3):.1f}" y1="{y}" x2="{X(3, 11):.1f}" y2="{y}" stroke="{cor}" stroke-width="4" stroke-linecap="round" '
                 f'stroke-dasharray="{L:.0f}" stroke-dashoffset="{L:.0f}" opacity=".45">{desenha(L, .1, 1.8)}</line>')
    hk = [(16, 3, 'F1', 0), (29, 3, 'F2', 0), (13, 5, 'F3', 0), (21, 5, 'F4', 1), (13, 9, 'F5', 0), (14, 9, 'F6', 1)]
    ec = [(16, 4, 'A1', 0), (18, 5, 'A2', 0), (13, 9, 'A4', 0)]
    k = 0
    for lst, y, cor, cima in [(hk, yH, T['azul'], True), (ec, yE, T['am'], False)]:
        for d, m, tag, niv in lst:
            x = X(d, m); s = -1 if cima else 1
            ty = y + s * (30 + 36 * niv)
            p = f'<circle cx="{x:.1f}" cy="{y}" r="9" fill="{cor}" stroke="{T["card"]}" stroke-width="3"/>'
            if niv:
                p += f'<line x1="{x:.1f}" y1="{y + s * 10}" x2="{x:.1f}" y2="{ty - s * 24}" stroke="{T["borda"]}" stroke-width="1.5"/>'
            p += texto(tag, x, ty + (0 if cima else 12), 15, 700, T['ink'], 'middle')
            p += texto(f'{d:02d}/{m:02d}', x, ty + (-18 if cima else 30), 12, 500, T['mut'], 'middle')
            c.append(g_surge(p, .4 + k * .12, .4, 0)); k += 1
    xa = X(3, 11)
    c.append(f'<line x1="{xa:.1f}" y1="{yH}" x2="{xa:.1f}" y2="{yE}" stroke="{T["ink"]}" stroke-width="3"/>')
    for y, tag in [(yH, 'F7'), (yE, 'A5')]:
        c.append(f'<circle cx="{xa:.1f}" cy="{y}" r="13" fill="{T["ruim"]}" opacity=".3">{pulso(13, 26, 2.2, .3)}</circle>'
                 f'<circle cx="{xa:.1f}" cy="{y}" r="11" fill="{T["ink"]}" stroke="{T["card"]}" stroke-width="3"/>')
    c.append(texto('F7', xa, yH - 26, 15, 700, T['ink'], 'middle') + texto('A5', xa, yE + 40, 15, 700, T['ink'], 'middle'))
    wt = largura('AGORA · 03/11', 12, 700, .08) + 24
    c.append(rr(xa - wt - 14, (yH + yE) / 2 - 14, wt, 28, 14, fill=T['ruim']) + texto('AGORA · 03/11', xa - wt / 2 - 14, (yH + yE) / 2 + 5, 12, 700, '#FFFFFF', 'middle', track=.08))
    # proximos passos
    c.append(f'<line x1="{xa + 14:.1f}" y1="{(yH + yE) / 2}" x2="1072" y2="{(yH + yE) / 2}" stroke="{T["mut"]}" stroke-width="2" stroke-dasharray="6 6">{marcha(1.2, 12)}</line>')
    nx = 1078
    p = rr(nx, 64, W - nx - 4, 210, 14, fill=T['card'], stroke=T['borda'], extra=' stroke-dasharray="6 5"')
    p += texto('PRÓXIMOS PASSOS', nx + 18, 94, 11.5, 700, T['mut'], track=.1)
    for j, t in enumerate(['testar com usuárias', 'login gov.br', 'Rede Blockchain', 'Brasil (RBB)']):
        if j == 3:
            p += texto(t, nx + 40, 132 + 2 * 40 + 20, 15, 500, T['sec'])
            continue
        p += f'<circle cx="{nx + 26}" cy="{127 + j * 40}" r="5" fill="none" stroke="{T["azul"]}" stroke-width="2"/>' + texto(t, nx + 40, 132 + j * 40, 15, 500, T['sec'])
    c.append(g_surge(p, 1.8, .6))
    return svg(W, H, ''.join(c), 'Linha do tempo: HackGov F1 16/03, F2 29/03, F3 13/05, F4 21/05, F5 13/09, F6 14/09; Enterprise Challenge A1 16/04, A2 18/05, A4 13/09; agora, 03/11, Fase 7 e Atividade 5; próximos passos: testar com usuárias, login gov.br e Rede Blockchain Brasil')


if __name__ == '__main__':
    cabecalho(); selos(); botoes(); icones_secao()
    for nome, fn in [('numeros', numeros), ('fluxo', fluxo), ('partes', partes), ('ataques', ataques), ('topologia', topologia),
                     ('correlacoes', correlacoes), ('ancoragem', ancoragem), ('estrada', estrada), ('linha-tempo', linha_tempo)]:
        duplo(nome, fn)
    print('ok', len(os.listdir(OUT)))
