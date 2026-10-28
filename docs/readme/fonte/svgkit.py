# Kit para SVGs de README: texto convertido em contorno (Inter), temas claro/escuro e animacao SMIL.
import base64, math
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

INTER = '/usr/share/fonts/opentype/inter/'
ARQ = {400: INTER + 'Inter-Regular.otf', 500: INTER + 'Inter-Medium.otf', 600: INTER + 'Inter-SemiBold.otf',
       700: INTER + 'Inter-Bold.otf', 800: INTER + 'InterDisplay-ExtraBold.otf', 'mono': '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
       'monob': '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'}
_F = {}


def _fonte(w):
    if w not in _F:
        tt = TTFont(ARQ[w])
        blob = hb.Blob.from_file_path(ARQ[w])
        face = hb.Face(blob)
        font = hb.Font(face)
        _F[w] = (tt, tt.getGlyphSet(), tt['head'].unitsPerEm, font, tt.getGlyphOrder())
    return _F[w]


def _molda(s, w, track=0.0):
    tt, gs, upm, font, order = _fonte(w)
    buf = hb.Buffer(); buf.add_str(s); buf.guess_segment_properties()
    hb.shape(font, buf, {'kern': True, 'liga': False})
    out, x = [], 0
    for inf, pos in zip(buf.glyph_infos, buf.glyph_positions):
        out.append((order[inf.codepoint], x + pos.x_offset, pos.y_offset))
        x += pos.x_advance + track * upm
    return out, x - (track * upm if out else 0), upm


def largura(s, size, w=400, track=0.0):
    _, adv, upm = _molda(s, w, track)
    return adv * size / upm


def texto(s, x, y, size, w=400, fill='#000', anchor='start', track=0.0, op=None, extra=''):
    """Devolve <path> com o texto em contorno. y e a linha de base."""
    if not s:
        return ''
    tt, gs, upm, font, order = _fonte(w)
    glifos, adv, _ = _molda(s, w, track)
    k = size / upm
    larg = adv * k
    x0 = x - (larg if anchor == 'end' else larg / 2 if anchor == 'middle' else 0)
    pen = SVGPathPen(gs, ntos=lambda v: ('%.1f' % v).rstrip('0').rstrip('.'))
    for nome, gx, gy in glifos:
        tp = TransformPen(pen, (k, 0, 0, -k, x0 + gx * k, y - gy * k))
        gs[nome].draw(tp)
    d = pen.getCommands()
    o = f' opacity="{op}"' if op is not None else ''
    return f'<path d="{d}" fill="{fill}"{o}{extra}/>'


def linhas(lst, x, y, size, lh, **kw):
    return ''.join(texto(t, x, y + i * lh, size, **kw) for i, t in enumerate(lst))


# --------------------------------------------------------------- animacao
SPL = 'calcMode="spline" keySplines="0 0 1 1;.2 .8 .2 1"'


def surge(atraso, dur=0.6):
    t = atraso + dur
    return f'<animate attributeName="opacity" values="0;0;1" keyTimes="0;{atraso / t:.3f};1" dur="{t:.2f}s" fill="freeze" {SPL}/>'


def g_surge(conteudo, atraso, dur=0.6, dy=8):
    t = atraso + dur
    return (f'<g>{surge(atraso, dur)}<animateTransform attributeName="transform" type="translate" values="0 {dy};0 {dy};0 0" '
            f'keyTimes="0;{atraso / t:.3f};1" dur="{t:.2f}s" fill="freeze" {SPL}/>{conteudo}</g>')


def marcha(periodo=1.5, passo=24):
    return f'<animate attributeName="stroke-dashoffset" from="{passo}" to="0" dur="{periodo}s" repeatCount="indefinite"/>'


def pulso(r0, r1, dur=2.2, op0=.35):
    return (f'<animate attributeName="r" values="{r0};{r1};{r0}" dur="{dur}s" repeatCount="indefinite"/>'
            f'<animate attributeName="opacity" values="{op0};0;{op0}" dur="{dur}s" repeatCount="indefinite"/>')


def desenha(comprimento, atraso, dur=1.2):
    t = atraso + dur
    return (f'<animate attributeName="stroke-dashoffset" values="{comprimento:.0f};{comprimento:.0f};0" keyTimes="0;{atraso / t:.3f};1" '
            f'dur="{t:.2f}s" fill="freeze" {SPL}/>')


# --------------------------------------------------------------- temas
CLARO = dict(nome='light', card='#FFFFFF', card2='#F6F8FA', borda='#D0D7DE', ink='#1F2328', sec='#424A53', mut='#656D76',
             grade='#E6EAEF', estrada='#E4E8EE', linha_estrada='#FFFFFF', sombra='#1F2328',
             azul='#1A4DA0', tq='#0E7C8C', lj='#BF6200', vd='#2E8B3A', am='#B88600',
             ok='#1A7F37', okbg='#DAFBE1', av='#9A6700', avbg='#FFF8C5', ruim='#CF222E', ruimbg='#FFEBE9',
             pC='#1A4DA0', pI='#D98E04', pD='#0E8A8A', txC='#FFFFFF', txI='#1F2328', txD='#FFFFFF', branco='#FFFFFF')
ESCURO = dict(nome='dark', card='#161B22', card2='#0D1117', borda='#30363D', ink='#E6EDF3', sec='#C9D1D9', mut='#8B949E',
              grade='#21262D', estrada='#21262D', linha_estrada='#484F58', sombra='#000000',
              azul='#58A6FF', tq='#39C5CF', lj='#F0883E', vd='#3FB950', am='#E3B341',
              ok='#3FB950', okbg='#12261E', av='#D29922', avbg='#2B2111', ruim='#F85149', ruimbg='#2D1214',
              pC='#4C8DF6', pI='#E3A008', pD='#2BB3B3', txC='#FFFFFF', txI='#0D1117', txD='#0D1117', branco='#FFFFFF')


def svg(w, h, corpo, titulo):
    t = titulo.replace('&', 'e').replace('<', '').replace('>', '').replace('"', "'")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}" role="img" aria-label="{t}"><title>{t}</title>{corpo}</svg>')


def rr(x, y, w, h, r, fill='none', stroke='none', sw=1.5, extra=''):
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{extra}/>'


def png_data(caminho):
    return 'data:image/png;base64,' + base64.b64encode(open(caminho, 'rb').read()).decode()


# --------------------------------------------------------------- icones (caixa 48x48, traco)
ICONES = {
    'escudo': 'M24 6 L38 11.5 V23 C38 32.5 32 39.5 24 42.5 C16 39.5 10 32.5 10 23 V11.5 Z M18 24 L22.5 28.5 L30.5 19.5',
    'rede': 'M24 9.5 A4.5 4.5 0 1 0 24.01 9.5 Z M11 34 A4.5 4.5 0 1 0 11.01 34 Z M37 34 A4.5 4.5 0 1 0 37.01 34 Z M21.6 17.6 L13.4 30.4 M26.4 17.6 L34.6 30.4 M15.5 38.5 L32.5 38.5',
    'grafico': 'M9 9 V39 H40 M15 32 L23 22 L29 27 L38 15 M33 15 H38 V20',
    'bloco': 'M24 6 L39 14.5 V31.5 L24 40 L9 31.5 V14.5 Z M9 14.5 L24 23 L39 14.5 M24 23 V40',
    'play': 'M24 6 A18 18 0 1 0 24.01 6 Z M20 16.5 L32 24 L20 31.5 Z',
    'pessoas': 'M18 22 A6 6 0 1 0 18.01 22 Z M7 39 C7 32 12 28.5 18 28.5 C24 28.5 29 32 29 39 M32 21 A5 5 0 1 0 32.01 21 Z M31 27.5 C36.5 27.5 41 30.5 41 37',
    'camadas': 'M24 8 L41 16.5 L24 25 L7 16.5 Z M7 24 L24 32.5 L41 24 M7 31.5 L24 40 L41 31.5',
    'tomada': 'M18 6 V15 M30 6 V15 M13 15 H35 V23 C35 29 30 33 24 33 C18 33 13 29 13 23 Z M24 33 V42',
    'banco': 'M24 7 C33 7 39 9.5 39 12.5 C39 15.5 33 18 24 18 C15 18 9 15.5 9 12.5 C9 9.5 15 7 24 7 Z M9 12.5 V35.5 C9 38.5 15 41 24 41 C33 41 39 38.5 39 35.5 V12.5 M9 24 C9 27 15 29.5 24 29.5 C33 29.5 39 27 39 24',
    'frasco': 'M19 6 H29 M20.5 6 V18 L9.5 37 C8.3 39.2 9.7 42 12.3 42 H35.7 C38.3 42 39.7 39.2 38.5 37 L27.5 18 V6 M14.5 30 H33.5',
    'pasta': 'M6 13 C6 11 7.5 9.5 9.5 9.5 H19 L23 14 H38.5 C40.5 14 42 15.5 42 17.5 V35 C42 37 40.5 38.5 38.5 38.5 H9.5 C7.5 38.5 6 37 6 35 Z',
    'doc': 'M12 6 H29 L38 15 V40 C38 41.2 37.2 42 36 42 H12 C10.8 42 10 41.2 10 40 V8 C10 6.8 10.8 6 12 6 Z M29 6 V15 H38 M16 24 H32 M16 30 H32 M16 36 H26',
    'relogio': 'M24 6 A18 18 0 1 1 7.5 16.8 M24 14 V24 L31 28 M6 8 V17 H15',
    'estrela': 'M24 5 L28.5 18.5 L42.5 19.5 L31.5 28 L35.5 42 L24 34 L12.5 42 L16.5 28 L5.5 19.5 L19.5 18.5 Z',
    'bandeira': 'M11 42 V6 M11 8 H36 L31 16 L36 24 H11',
    'bussola': 'M24 6 A18 18 0 1 0 24.01 6 Z M24 11 L29 24 L24 37 L19 24 Z',
    'lapis': 'M31 8 L40 17 L18 39 L7 41 L9 30 Z M27 12 L36 21',
    'faisca': 'M24 6 L27.5 20.5 L42 24 L27.5 27.5 L24 42 L20.5 27.5 L6 24 L20.5 20.5 Z',
    'lista': 'M17 12 H40 M17 24 H40 M17 36 H40 M9 12 H10 M9 24 H10 M9 36 H10',
    'olho': 'M4 24 C9 14 16 10 24 10 C32 10 39 14 44 24 C39 34 32 38 24 38 C16 38 9 34 4 24 Z M24 18 A6 6 0 1 0 24.01 18 Z',
    'corrente': 'M20 28 L28 20 M17 23 L12.5 27.5 C9.5 30.5 9.5 35.5 12.5 38.5 C15.5 41.5 20.5 41.5 23.5 38.5 L28 34 M31 25 L35.5 20.5 C38.5 17.5 38.5 12.5 35.5 9.5 C32.5 6.5 27.5 6.5 24.5 9.5 L20 14',
    'cadeado': 'M12 22 H36 V41 H12 Z M17 22 V15 C17 10.5 20 7.5 24 7.5 C28 7.5 31 10.5 31 15 V22 M24 29 V34',
    'servidor': 'M8 8 H40 V20 H8 Z M8 28 H40 V40 H8 Z M14 14 H15 M14 34 H15 M22 14 H34 M22 34 H34',
    'globo': 'M24 6 A18 18 0 1 0 24.01 6 Z M6 24 H42 M24 6 C29 11 31 17 31 24 C31 31 29 37 24 42 C19 37 17 31 17 24 C17 17 19 11 24 6',
    'terminal': 'M6 9 H42 V39 H6 Z M12 18 L18 24 L12 30 M22 31 H32',
    'chave': 'M17 17 A9 9 0 1 0 17.01 17 Z M23.5 23.5 L41 41 M33 33 L37 29 M37 37 L41 33',
    'alerta': 'M24 6 L43 39 H5 Z M24 18 V28 M24 33 V34',
    'check': 'M24 6 A18 18 0 1 0 24.01 6 Z M16 24.5 L21.5 30 L32.5 18.5',
}


def icone(nome, cx, cy, tam, cor, sw=3.0):
    k = tam / 48
    return (f'<g transform="translate({cx - tam / 2:.1f} {cy - tam / 2:.1f}) scale({k:.4f})"><path d="{ICONES[nome]}" fill="none" '
            f'stroke="{cor}" stroke-width="{sw / k:.2f}" stroke-linecap="round" stroke-linejoin="round"/></g>')
