/**
 * estatistica.js — Relatorio estatistico do canal (Parte 4).
 *
 * Consome GET /api/stats/analitico e desenha cinco graficos. Cada um vem
 * acompanhado de uma LEITURA em texto, gerada a partir dos proprios numeros
 * recebidos - nao de frases fixas. Um grafico sem leitura transfere para o
 * gestor o trabalho de interpretar, e e justamente esse trabalho que o
 * painel deveria estar fazendo por ele.
 *
 * Nada aqui e calculado no navegador. Media, desvio, quartis e correlacao
 * vem prontos do servidor, pelo mesmo motivo que o score veio: dois lugares
 * calculando a mesma coisa e uma divergencia esperando para acontecer.
 */
const Estatistica = (() => {

  function T(chave, padrao) {
    return (typeof I18n !== 'undefined' && I18n.t) ? I18n.t(chave) : padrao;
  }

  const COR = {
    principal: '#1D4ED8', clara: 'rgba(29,78,216,.15)',
    critica: '#DC2626', alta: '#EA580C', media: '#D97706', baixa: '#0891B2',
    violencia: '#DC2626', abuso: '#EA580C', assedio: '#D97706',
    discriminacao: '#7C3AED', outros: '#64748B',
    aberto: '#B45309', neutra: '#94A3B8',
  };

  let dados = null;
  const graficos = {};

  // Delegado ao helper global (storage-guard.js). A versão anterior, via
  // textContent/innerHTML, não escapava aspas e deixava atributos vulneráveis.
  function esc(t) { return escHtml(t); }

  const num = (v, casas) => Number(v).toLocaleString(
    (typeof I18n !== 'undefined' && I18n.atual() === 'en') ? 'en-US' : 'pt-BR',
    { minimumFractionDigits: casas === undefined ? 2 : casas,
      maximumFractionDigits: casas === undefined ? 2 : casas });

  function _cor() {
    return (typeof coresDoGrafico === 'function')
      ? coresDoGrafico()
      : { grade: '#EEF2F7', texto: '#64748b', borda: '#e2e8f0' };
  }

  function desenhar(id, tipo, data, extra) {
    const canvas = document.getElementById(id);
    if (!canvas || typeof Chart === 'undefined') return;
    if (graficos[id]) graficos[id].destroy();
    graficos[id] = new Chart(canvas, {
      type: tipo,
      data,
      // A cor vem do tema, e nao do codigo: o canvas nao herda CSS, entao
      // grade e rotulos precisam ser perguntados a quem sabe se a pagina
      // esta clara ou escura. Ver coresDoGrafico() em main.js.
      options: Object.assign({
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false, labels: { color: _cor().texto } } },
        scales: {
          y: { beginAtZero: true, ticks: { color: _cor().texto },
               grid: { color: _cor().grade }, border: { color: _cor().borda } },
          x: { ticks: { color: _cor().texto }, grid: { display: false },
               border: { color: _cor().borda } },
        },
      }, extra || {}),
    });
  }

  function cartao(rotulo, valor, nota) {
    return `<div class="est-cartao">
      <div class="est-cartao-vlr">${esc(valor)}</div>
      <div class="est-cartao-rot">${esc(rotulo)}</div>
      ${nota ? `<div class="est-cartao-nota">${esc(nota)}</div>` : ''}
    </div>`;
  }

  // ── Cabecalho: universo e medidas de posicao e dispersao ──────
  function resumo() {
    const l = dados.leadTime, u = dados.universo;
    const alvo = document.getElementById('est-cartoes');
    if (!alvo) return;
    alvo.innerHTML =
      cartao(T('est.card.universo', 'denúncias na base'), u.total,
             `${u.concluidas} ${T('est.card.concluidas', 'concluídas')} · ${u.emAberto} ${T('est.card.abertas', 'em aberto')}`) +
      cartao(T('est.card.media', 'dias em média até concluir'), num(l.media),
             `${T('est.card.mediana', 'mediana')} ${num(l.mediana)}`) +
      cartao(T('est.card.desvio', 'desvio-padrão, em dias'), num(l.desvio),
             `CV ${num(l.cv, 1)}%`) +
      cartao(T('est.card.p90', 'dias no percentil 90'), num(dados.percentisLeadTime.p90),
             T('est.card.p90nota', '9 em cada 10 casos fecham até aqui')) +
      cartao(T('est.card.assimetria', 'assimetria de Pearson'), num(l.assimetria),
             l.assimetria > 0 ? T('est.card.cauda_dir', 'cauda à direita')
                              : T('est.card.cauda_esq', 'cauda à esquerda'));

    const ref = document.getElementById('est-referencia');
    if (ref) {
      ref.textContent = T('est.referencia', 'Data de referência da base:') + ' '
        + String(dados.dataReferencia || '').replace('T', ' ').slice(0, 16)
        + ' — ' + T('est.referencia_nota',
            'as esperas dos casos em aberto são contadas a partir daqui, e não do relógio de hoje, para que o painel e o relatório devolvam sempre o mesmo número.');
    }
  }

  function leitura(id, html) {
    const el = document.getElementById(id);
    if (el) el.innerHTML = html;
  }

  // ── 1. Histograma do tempo de conclusao ──────────────────────
  function histograma() {
    const h = dados.histogramaLeadTime;
    desenhar('est-histograma', 'bar', {
      labels: h.map(f => f.rotulo),
      datasets: [{ data: h.map(f => f.n), backgroundColor: COR.principal, borderRadius: 4 }],
    });

    const l = dados.leadTime;
    const dominante = h.reduce((a, b) => (b.n > a.n ? b : a), h[0]);
    leitura('est-leitura-histograma',
      `${T('est.hist.1', 'A distribuição não é simétrica: a maior parte dos casos se concentra na faixa de')}
       <b>${esc(dominante.rotulo)} ${T('est.dias', 'dias')}</b>,
       ${T('est.hist.2', 'mas uma cauda de casos lentos se estende até')}
       <b>${num(l.maximo)} ${T('est.dias', 'dias')}</b>.
       ${T('est.hist.3', 'É por isso que a média') } (<b>${num(l.media)}</b>)
       ${T('est.hist.4', 'fica acima da mediana')} (<b>${num(l.mediana)}</b>)
       — ${T('est.hist.5', 'assimetria de')} <b>${num(l.assimetria)}</b>.
       ${l.outliers.length
          ? `${T('est.hist.6', 'A regra de Tukey aponta')} <b>${l.outliers.length}</b>
             ${T('est.hist.7', 'caso(s) fora da cerca de')} <b>${num(l.cercaSup)} ${T('est.dias', 'dias')}</b>.`
          : T('est.hist.8', 'Nenhum caso ultrapassa a cerca de Tukey.')}`);
  }

  // ── 2. Tempo por tipo de denuncia ────────────────────────────
  function porTipo() {
    const r = dados.leadPorTipo;
    desenhar('est-tipo', 'bar', {
      labels: r.map(x => T('tipo.' + x.chave, x.chave)),
      datasets: [{ data: r.map(x => x.media),
                   backgroundColor: r.map(x => COR[x.chave] || COR.neutra), borderRadius: 4 }],
    }, { indexAxis: 'y', scales: { x: { beginAtZero: true }, y: { grid: { display: false } } } });

    if (!r.length) return;
    const rapido = r.reduce((a, b) => (b.media < a.media ? b : a));
    const lento = r.reduce((a, b) => (b.media > a.media ? b : a));
    leitura('est-leitura-tipo',
      `${T('est.tipo.1', 'A ordem acompanha a gravidade:')}
       <b>${esc(T('tipo.' + rapido.chave, rapido.chave))}</b> ${T('est.tipo.2', 'fecha em')}
       <b>${num(rapido.media)}</b> ${T('est.dias', 'dias')},
       ${T('est.tipo.3', 'enquanto')} <b>${esc(T('tipo.' + lento.chave, lento.chave))}</b>
       ${T('est.tipo.4', 'leva')} <b>${num(lento.media)}</b> —
       <b>${num(lento.media / rapido.media, 1)}×</b> ${T('est.tipo.5', 'mais tempo')}.
       ${T('est.tipo.6', 'A triagem por gravidade está funcionando nos casos que chegam ao fim.')}`);
  }

  // ── 3. Tempo por urgencia atribuida pela IA ──────────────────
  function porUrgencia() {
    const r = dados.leadPorUrgencia;
    desenhar('est-urgencia', 'bar', {
      labels: r.map(x => T('urg.' + x.chave.toLowerCase(), x.chave)),
      datasets: [{ data: r.map(x => x.media),
                   backgroundColor: r.map(x => COR[x.chave.toLowerCase()] || COR.neutra), borderRadius: 4 }],
    });

    if (r.length < 2) return;
    const crescente = r.every((x, i) => i === 0 || x.media >= r[i - 1].media);
    leitura('est-leitura-urgencia',
      crescente
        ? `${T('est.urg.1', 'O tempo cresce à medida que a urgência cai — de')}
           <b>${num(r[0].media)}</b> ${T('est.dias', 'dias')}
           ${T('est.urg.2', 'na urgência mais alta a')} <b>${num(r[r.length - 1].media)}</b>
           ${T('est.urg.3', 'na mais baixa. A classificação automática do VigIA está, na prática, orientando a ordem de atendimento.')}`
        : T('est.urg.4', 'O tempo de atendimento não acompanha a urgência atribuída pela IA — a classificação automática não está guiando a fila.'));
  }

  // ── 4. Espera dos casos AINDA em aberto ──────────────────────
  function esperaAberto() {
    const r = dados.esperaEmAbertoPorUrgencia;
    desenhar('est-aberto', 'bar', {
      labels: r.map(x => T('urg.' + x.chave.toLowerCase(), x.chave)),
      datasets: [{ data: r.map(x => x.media),
                   backgroundColor: r.map(x => COR[x.chave.toLowerCase()] || COR.aberto), borderRadius: 4 }],
    });

    if (!r.length) return;
    const pior = r.reduce((a, b) => (b.media > a.media ? b : a));
    const critica = r.find(x => x.chave === 'CRITICA');
    const alerta = critica && pior.chave === 'CRITICA';
    leitura('est-leitura-aberto',
      `${T('est.ab.1', 'Este gráfico contradiz o anterior, e a contradição é o achado.')}
       ${T('est.ab.2', 'Entre os casos ainda não concluídos, quem mais espera é a urgência')}
       <b>${esc(T('urg.' + pior.chave.toLowerCase(), pior.chave))}</b>:
       <b>${num(pior.media)}</b> ${T('est.dias', 'dias')} ${T('est.ab.3', 'em média, com um caso parado há')}
       <b>${num(pior.maximo, 0)}</b>.
       ${alerta
          ? `<span class="est-alerta">${T('est.ab.4', 'Olhar apenas para os casos concluídos é viés de sobrevivência: eles são justamente os que não ficaram presos. O backlog mostra o que a média esconde.')}</span>`
          : T('est.ab.5', 'A fila de priorização existe para que esta ordem acompanhe a urgência.')}`);
  }

  // ── 5. Dispersao score x tempo ───────────────────────────────
  function dispersao() {
    const p = dados.dispersaoScoreLead;
    desenhar('est-dispersao', 'scatter', {
      datasets: [{
        data: p.map(x => ({ x: x.score, y: x.dias })),
        backgroundColor: 'rgba(29,78,216,.55)',
        pointRadius: 4,
      }],
    }, {
      scales: {
        x: { title: { display: true, text: T('est.disp.x', 'score de confiabilidade') }, beginAtZero: true },
        y: { title: { display: true, text: T('est.disp.y', 'dias até concluir') }, beginAtZero: true },
      },
    });

    const c = dados.correlacaoScoreLead;
    leitura('est-leitura-dispersao',
      `${T('est.disp.1', 'A nuvem não tem direção:')} <b>r = ${num(c.r)}</b>
       (r² = ${num(c.r2)}) — ${esc(T(c.leitura, c.leitura))}.
       ${T('est.disp.2', 'O score de confiabilidade praticamente não influencia o tempo de conclusão: uma denúncia bem documentada não é atendida mais rápido por ser bem documentada.')}
       ${T('est.disp.3', 'Vale lembrar que correlação não é causalidade, e que ausência de correlação linear não exclui outras formas de relação.')}`);
  }

  // ── 6. Cumprimento de prazo (candidatos a SLA) ───────────────
  function prazos() {
    const r = dados.cumprimentoDePrazo;
    desenhar('est-prazo', 'bar', {
      labels: r.map(x => x.dias + ' ' + T('est.dias', 'dias')),
      datasets: [{ data: r.map(x => x.percentual), backgroundColor: COR.principal, borderRadius: 4 }],
    }, { scales: { y: { beginAtZero: true, max: 100, ticks: { callback: v => v + '%' } },
                   x: { grid: { display: false } } } });

    const media = dados.leadTime.media;
    const noPrazoDaMedia = r.find(x => x.dias >= media);
    leitura('est-leitura-prazo',
      `${T('est.prazo.1', 'Prometer o prazo da média seria promessa quebrada.')}
       ${T('est.prazo.2', 'A média é de')} <b>${num(media)}</b> ${T('est.dias', 'dias')},
       ${noPrazoDaMedia
          ? `${T('est.prazo.3', 'mas apenas')} <b>${num(noPrazoDaMedia.percentual, 1)}%</b>
             ${T('est.prazo.4', 'dos casos fecham em até')} <b>${esc(noPrazoDaMedia.dias)}</b> ${T('est.dias', 'dias')}.`
          : ''}
       ${T('est.prazo.5', 'Um SLA honesto se compromete com o percentil 90')}
       (<b>${num(dados.percentisLeadTime.p90)}</b> ${T('est.dias', 'dias')}),
       ${T('est.prazo.6', 'que descreve o que o cidadão de fato encontra, e não o caso médio que quase ninguém vive.')}`);
  }

  // ══════════════════════════════════════════════════════════════
  // Fase 7 | Correlacao e regressao (GET /api/stats/regressao)
  //
  // Mesma regra do relatorio descritivo: nada e calculado aqui. O servidor
  // entrega r, p, intervalos, coeficientes e a projecao; a tela so formata
  // e desenha. Todo texto vindo do servidor passa por esc() antes de ir
  // para o innerHTML, e a classe de cor dos cartoes sai de uma lista
  // fechada, nunca do valor recebido.
  // ══════════════════════════════════════════════════════════════

  let dadosReg = null;

  const ehEn = () => typeof I18n !== 'undefined' && I18n.atual && I18n.atual() === 'en';
  const LOCALE = () => (ehEn() ? 'en-US' : 'pt-BR');
  const MENOS = '−';

  const valido = v => v !== null && v !== undefined && v !== '' && Number.isFinite(Number(v));
  const indisp = () => `<span class="reg-indisp">${esc(T('reg.indisp', 'indisponível'))}</span>`;

  /** Numero no idioma da tela, com sinal de menos tipografico. Texto puro. */
  function fmtTxt(v, casas, sinal) {
    if (!valido(v)) return T('reg.indisp', 'indisponível');
    const c = casas === undefined ? 2 : casas;
    const n = Number(v);
    const t = Math.abs(n).toLocaleString(LOCALE(), { minimumFractionDigits: c, maximumFractionDigits: c });
    const zero = Number(t.replace(/[^0-9]/g, '')) === 0;
    if (n < 0 && !zero) return MENOS + t;
    return (sinal && n > 0 && !zero ? '+' : '') + t;
  }
  /** Mesmo numero, ja como HTML (indisponivel ganha estilo proprio). */
  const fmt = (v, casas, sinal) => (valido(v) ? esc(fmtTxt(v, casas, sinal)) : indisp());

  /** p-valor: "p < 0,001" abaixo do limite, senao tres casas. */
  function pTxt(p, prefixo) {
    if (!valido(p)) return T('reg.indisp', 'indisponível');
    const pre = prefixo === false ? '' : 'p ';
    return Number(p) < 0.001 ? `${pre}< ${fmtTxt(0.001, 3)}` : `${pre}${prefixo === false ? '' : '= '}${fmtTxt(p, 3)}`;
  }
  const pHtml = (p, prefixo) => (valido(p) ? esc(pTxt(p, prefixo)) : indisp());

  function icTxt(a, b, casas) {
    if (!valido(a) || !valido(b)) return T('reg.indisp', 'indisponível');
    return `[${fmtTxt(a, casas)}${ehEn() ? ', ' : '; '}${fmtTxt(b, casas)}]`;
  }
  const icHtml = (a, b, casas) => (valido(a) && valido(b) ? esc(icTxt(a, b, casas)) : indisp());

  /** "2026-03-02" -> 02/03 (pt) ou Mar 2 (en), sem fuso horario no meio. */
  function dataCurta(iso, ano) {
    const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(iso || ''));
    if (!m) return String(iso || '');
    const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
    const opc = ehEn()
      ? { month: 'short', day: 'numeric', timeZone: 'UTC' }
      : { day: '2-digit', month: '2-digit', timeZone: 'UTC' };
    if (ano) opc.year = 'numeric';
    return d.toLocaleDateString(LOCALE(), opc);
  }
  function dataHora(iso) {
    const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(String(iso || ''));
    return m ? `${dataCurta(iso, true)}, ${m[4]}:${m[5]}` : '';
  }

  const NIVEIS = ['destaque', 'alerta', 'atencao', 'positivo', 'info'];
  const nivelDe = n => (NIVEIS.includes(n) ? n : 'info');

  /** Rotulo curto da variavel (cabecalho da matriz); cai no nome do servidor. */
  function rotuloCurto(v) {
    const k = 'reg.var.' + v.chave;
    const t = T(k, null);
    return (t && t !== k) ? t : (v.nome || v.chave || '');
  }

  function corVar(nome, padrao) {
    const sec = document.getElementById('reg-secao');
    const v = sec ? getComputedStyle(sec).getPropertyValue(nome).trim() : '';
    return v || padrao;
  }

  function destruirReg() {
    ['reg-dispersao', 'reg-semanal'].forEach(id => {
      if (graficos[id]) { graficos[id].destroy(); delete graficos[id]; }
    });
  }

  function setHtml(id, html) {
    const el = document.getElementById(id);
    if (el) el.innerHTML = html;
  }

  // ── Cabecalho ────────────────────────────────────────────────
  function regMeta() {
    const d = dadosReg;
    const partes = [];
    partes.push(`<b>${esc(d.casosConcluidos)}</b> ${esc(T('reg.meta.casos', 'casos concluídos analisados'))}`);
    if (d.geradoEm) partes.push(`${esc(T('reg.meta.gerado', 'calculado em'))} ${esc(dataHora(d.geradoEm))}`);
    setHtml('reg-meta', partes.join('<span class="reg-ponto" aria-hidden="true">·</span>'));
  }

  // ── 1. Cartoes de conclusao (a camada de decisao) ────────────
  function regInsights() {
    const lista = Array.isArray(dadosReg.insights) ? dadosReg.insights : [];
    if (!lista.length) {
      setHtml('reg-insights', `<p class="reg-vazio">${esc(T('reg.sem_insights', 'O servidor não gerou conclusões para esta base.'))}</p>`);
      return;
    }
    setHtml('reg-insights', lista.map((i, idx) => {
      const nv = nivelDe(i.nivel);
      const heroi = idx === 0 && nv === 'destaque' ? ' heroi' : '';
      return `<article class="reg-insight nv-${nv}${heroi}">
        <span class="reg-nivel">${esc(T('reg.nivel.' + nv, nv))}</span>
        <h5>${esc(i.titulo)}</h5>
        ${i.texto ? `<p class="reg-insight-texto">${esc(i.texto)}</p>` : ''}
        ${i.evidencia ? `<div class="reg-evid"><span>${esc(T('reg.evidencia', 'Evidência'))}</span><code>${esc(i.evidencia)}</code></div>` : ''}
        ${i.decisao ? `<div class="reg-decisao"><span>➜ ${esc(T('reg.decisao', 'Decisão sugerida'))}</span><p>${esc(i.decisao)}</p></div>` : ''}
      </article>`;
    }).join(''));
  }

  // ── 2. Correlacao de cada fator com o tempo ──────────────────
  function regCorrelacoes() {
    const lista = Array.isArray(dadosReg.correlacoesComTempo) ? dadosReg.correlacoesComTempo : [];
    const pos = r => ((Math.max(-1, Math.min(1, r)) + 1) / 2) * 100;
    const descr = {};
    (dadosReg.variaveis || []).forEach(v => { descr[v.chave] = v.descricao; });

    const linhas = lista.map(c => {
      const temR = valido(c.pearson);
      const r = temR ? Number(c.pearson) : 0;
      const cls = !temR ? 'nd' : (c.significativa ? (r < 0 ? 'neg' : 'pos') : 'ns');
      const barra = temR
        ? `<span class="reg-corr-barra" style="left:${Math.min(50, pos(r)).toFixed(2)}%;width:${Math.abs(pos(r) - 50).toFixed(2)}%"></span>`
        : '';
      const ic = valido(c.icInferior) && valido(c.icSuperior)
        ? `<span class="reg-corr-ic" style="left:${pos(c.icInferior).toFixed(2)}%;width:${(pos(c.icSuperior) - pos(c.icInferior)).toFixed(2)}%"></span>`
        : '';
      const rotulo = `r = ${fmtTxt(c.pearson)}; ${T('reg.ic95', 'IC 95%')} ${icTxt(c.icInferior, c.icSuperior)}; ${pTxt(c.pValor)}`;
      return `<div class="reg-corr-linha ${cls}">
        <div class="reg-corr-topo">
          <span class="reg-corr-nome" title="${escAttr(descr[c.chave] || '')}">${esc(c.nome)}</span>
          <span class="reg-corr-r">r <b>${fmt(c.pearson)}</b></span>
        </div>
        <div class="reg-corr-trilho" role="img" aria-label="${escAttr(rotulo)}">
          <span class="reg-corr-guia" style="left:25%"></span><span class="reg-corr-guia" style="left:75%"></span>
          ${barra}${ic}<span class="reg-corr-zero"></span>
        </div>
        <div class="reg-corr-det">
          <span>${esc(T('reg.spearman', 'Spearman'))} <i class="reg-grego">ρ</i> = ${fmt(c.spearman)}</span>
          <span>${esc(T('reg.ic95', 'IC 95%'))} ${icHtml(c.icInferior, c.icSuperior)}</span>
          <span>${valido(c.pValor) ? pHtml(c.pValor) : 'p = ' + indisp()}</span>
          <span>${esc(T('reg.n', 'n'))} = ${esc(c.n)}</span>
          <span class="reg-sig ${c.significativa ? 'sim' : 'nao'}">${esc(T(c.significativa ? 'reg.corr.sig' : 'reg.corr.ns', ''))}</span>
        </div>
        ${c.leitura ? `<div class="reg-corr-leitura">${esc(c.leitura)}</div>` : ''}
      </div>`;
    }).join('');

    const eixo = `<div class="reg-corr-eixo" aria-hidden="true">
        <span style="left:0%">${MENOS}1</span><span style="left:25%">${esc(fmtTxt(-0.5, 1))}</span>
        <span style="left:50%">0</span><span style="left:75%">${esc(fmtTxt(0.5, 1, true))}</span><span style="left:100%">+1</span>
      </div>
      <div class="reg-corr-direcao" aria-hidden="true">
        <span>◀ ${esc(T('reg.corr.encurta', 'encurta o prazo'))}</span>
        <span>${esc(T('reg.corr.alonga', 'alonga o prazo'))} ▶</span>
      </div>`;
    setHtml('reg-corr', lista.length ? linhas + eixo : `<p class="reg-vazio">${indisp()}</p>`);
  }

  // ── 3. Matriz de Pearson ─────────────────────────────────────
  function regMatriz() {
    const vars = Array.isArray(dadosReg.variaveis) ? dadosReg.variaveis : [];
    const m = Array.isArray(dadosReg.matrizPearson) ? dadosReg.matrizPearson : [];
    if (!vars.length) { setHtml('reg-matriz', `<p class="reg-vazio">${indisp()}</p>`); return; }
    const cab = vars.map(v =>
      `<th scope="col" title="${escAttr(v.nome + (v.descricao ? ': ' + v.descricao : ''))}">${esc(rotuloCurto(v))}</th>`).join('');
    const corpo = vars.map((vi, i) => {
      const celulas = vars.map((vj, j) => {
        const r = (m[i] || [])[j];
        const dica = `${vi.nome} × ${vj.nome}: r = ${fmtTxt(r)}`;
        if (i === j) return `<td class="diag" title="${escAttr(dica)}">${esc(fmtTxt(1, 0))}</td>`;
        if (!valido(r)) return `<td class="nd" title="${escAttr(dica)}">${esc(T('reg.nd', 'n/d'))}</td>`;
        const a = Math.min(1, Math.abs(Number(r)));
        const cls = (Number(r) < 0 ? 'neg' : 'pos') + (a >= 0.45 ? ' forte' : '');
        return `<td class="${cls}" style="--a:${(a * 0.92).toFixed(3)}" title="${escAttr(dica)}">${esc(fmtTxt(r))}</td>`;
      }).join('');
      return `<tr><th scope="row" title="${escAttr(vi.nome + (vi.descricao ? ': ' + vi.descricao : ''))}">${esc(rotuloCurto(vi))}</th>${celulas}</tr>`;
    }).join('');
    // Leitura gerada dos proprios numeros: o par de fatores explicativos
    // mais correlacionado (fora o tempo), que e o que confunde a regressao
    // multipla. Nada fixo: outra base, outro par.
    let par = null;
    vars.forEach((vi, i) => vars.forEach((vj, j) => {
      if (j <= i || vi.chave === 'tempo' || vj.chave === 'tempo') return;
      const r = (m[i] || [])[j];
      if (valido(r) && (!par || Math.abs(r) > Math.abs(par.r))) par = { a: vi, b: vj, r: Number(r) };
    }));
    const leituraPar = par
      ? `<p class="reg-nota">${esc(T('reg.mat.par', 'Par de fatores mais correlacionado:'))}
         <b>${esc(par.a.nome)} × ${esc(par.b.nome)}</b> (r = ${esc(fmtTxt(par.r))}).
         ${esc(T(Math.abs(par.r) >= 0.5 ? 'reg.mat.par_forte' : 'reg.mat.par_fraco', ''))}</p>`
      : '';
    setHtml('reg-matriz-leitura', leituraPar);
    setHtml('reg-matriz', `<table class="reg-matriz"><thead><tr><th></th>${cab}</tr></thead><tbody>${corpo}</tbody></table>`);
  }

  function chip(rotulo, valorHtml, extraCls) {
    return `<span class="reg-chip${extraCls ? ' ' + extraCls : ''}"><span>${esc(rotulo)}</span><b>${valorHtml}</b></span>`;
  }

  // ── 4. Regressao simples: dispersao + reta ───────────────────
  function regSimples() {
    const rs = dadosReg.regressaoSimples || {};
    const coefs = Array.isArray(rs.coeficientes) ? rs.coeficientes : [];
    const b0 = coefs.find(c => c.chave === 'intercepto');
    const b1 = coefs.find(c => c.chave !== 'intercepto');
    const nomeX = b1 ? b1.nome : '';
    const varX = b1 ? (dadosReg.variaveis || []).find(v => v.chave === b1.chave) : null;

    setHtml('reg-simples-desc', esc(rs.descricao || ''));
    const pct = valido(rs.r2) ? `${fmtTxt(Number(rs.r2) * 100, 0)}% ${T('reg.explica', 'da variação explicada')}` : '';
    setHtml('reg-simples-chips',
      (rs.equacao ? `<code class="reg-eq">${esc(rs.equacao)}</code>` : '') +
      chip(T('reg.r2', 'R²'), fmt(rs.r2) + (pct ? ` <small>${esc(pct)}</small>` : '')) +
      chip('n', esc(rs.n)) +
      chip(T('reg.pf', 'p(F)'), pHtml(rs.pValorF, false)));

    const pontos = Array.isArray(rs.pontos) ? rs.pontos.filter(p => valido(p.x) && valido(p.y)) : [];
    const xs = pontos.map(p => Number(p.x));
    const minX = xs.length ? Math.min(...xs) : 0;
    const maxX = xs.length ? Math.max(...xs) : 1;
    const distintos = new Set(xs);
    // Espalhamento horizontal deterministico (sequencia de razao aurea):
    // x e discreto, e sem isso 123 casos virariam tres colunas de pontos
    // empilhados. Mesmo dado, mesmo desenho, a cada recarga.
    const jitter = i => ((((i + 1) * 0.6180339887) % 1) - 0.5) * 0.36;
    const dispersao = pontos.map((p, i) => ({ x: Number(p.x) + jitter(i), y: Number(p.y), xo: Number(p.x) }));

    const temReta = b0 && b1 && valido(b0.valor) && valido(b1.valor);
    const x0 = minX - 0.45, x1 = maxX + 0.45;
    const reta = temReta
      ? [{ x: x0, y: Number(b0.valor) + Number(b1.valor) * x0 }, { x: x1, y: Number(b0.valor) + Number(b1.valor) * x1 }]
      : [];

    const nota = [];
    if (varX && varX.descricao) nota.push(`<b>${esc(T('reg.escala', 'Escala:'))}</b> ${esc(varX.descricao)}.`);
    nota.push(esc(T('reg.jitter', '')));
    setHtml('reg-simples-nota', nota.join(' '));

    const canvas = document.getElementById('reg-dispersao');
    if (!canvas || typeof Chart === 'undefined') return;
    canvas.setAttribute('aria-label', `${T('reg.g.simples', 'Regressão linear simples')}: ${rs.descricao || ''}`);
    if (graficos['reg-dispersao']) graficos['reg-dispersao'].destroy();
    const c = _cor();
    const azul = corVar('--reg-ponto', 'rgba(29,78,216,.42)');
    const azulBorda = corVar('--reg-ponto-borda', '#1d4ed8');
    const linha = corVar('--reg-reta', '#0f172a');
    graficos['reg-dispersao'] = new Chart(canvas, {
      type: 'scatter',
      data: {
        datasets: [
          { label: T('reg.pontos', 'Casos concluídos'), data: dispersao, backgroundColor: azul,
            borderColor: azulBorda, borderWidth: 1, pointRadius: 4, pointHoverRadius: 6, order: 2 },
          { type: 'line', label: T('reg.reta', 'Reta ajustada'), data: reta, borderColor: linha,
            backgroundColor: linha, borderWidth: 2.5, pointRadius: 0, pointHoverRadius: 0, order: 1,
            pointStyle: 'line' },
        ],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: true, position: 'bottom',
                    labels: { color: c.texto, usePointStyle: true, boxWidth: 8, boxHeight: 8, padding: 14,
                              font: { size: 11.5 }, sort: (a, b) => a.datasetIndex - b.datasetIndex } },
          tooltip: {
            filter: it => it.datasetIndex === 0,
            callbacks: {
              title: () => '',
              label: it => `${nomeX}: ${fmtTxt(it.raw.xo, 0)} · ${fmtTxt(it.raw.y)} ${T('reg.dias', 'dias')}`,
            },
          },
        },
        scales: {
          x: { type: 'linear', min: minX - 0.7, max: maxX + 0.7,
               ticks: { color: c.texto, stepSize: 1, callback: v => (distintos.has(v) ? fmtTxt(v, 0) : '') },
               grid: { color: c.grade }, border: { color: c.borda },
               title: { display: !!nomeX, text: nomeX, color: c.texto } },
          y: { beginAtZero: true, ticks: { color: c.texto }, grid: { color: c.grade }, border: { color: c.borda },
               title: { display: true, text: T('reg.dias_ate', 'dias até concluir'), color: c.texto } },
        },
      },
    });
  }

  // ── 5. Regressao multipla: tabela de coeficientes ────────────
  function regMultipla() {
    const rm = dadosReg.regressaoMultipla || {};
    const coefs = Array.isArray(rm.coeficientes) ? rm.coeficientes : [];
    setHtml('reg-multipla-desc', esc(rm.descricao || ''));
    setHtml('reg-multipla-stats',
      chip(T('reg.r2', 'R²'), fmt(rm.r2)) +
      chip(T('reg.r2aj', 'R² ajustado'), fmt(rm.r2Ajustado)) +
      chip(T('reg.f', 'F'), fmt(rm.f)) +
      chip(T('reg.pf', 'p(F)'), pHtml(rm.pValorF, false)) +
      chip('n', esc(rm.n)) +
      chip(T('reg.epr', 'Erro-padrão residual'), valido(rm.erroPadraoResidual)
        ? `${fmt(rm.erroPadraoResidual)} <small>${esc(T('reg.dias', 'dias'))}</small>` : indisp()));

    const linhas = coefs.map(c => {
      const base = c.chave === 'intercepto';
      const sit = base
        ? `<span class="reg-badge base">${esc(T('reg.constante', 'constante do modelo'))}</span>`
        : `<span class="reg-badge ${c.significativo ? 'sim' : 'nao'}">${esc(T(c.significativo ? 'reg.sig' : 'reg.ns', ''))}</span>`;
      const beta = base && !valido(c.padronizado)
        ? `<span class="reg-indisp">${esc(T('reg.na', 'não se aplica'))}</span>`
        : fmt(c.padronizado);
      return `<tr class="${base ? 'base' : (c.significativo ? 'sig' : 'ns')}">
        <th scope="row"><span class="reg-var-nome">${esc(c.nome)}</span>${sit}</th>
        <td class="num" data-rot="${escAttr(T('reg.col.coef', 'Coeficiente (dias)'))}">${fmt(c.valor, 3)}</td>
        <td class="num ic" data-rot="${escAttr(T('reg.col.ic', 'IC 95%'))}">${icHtml(c.icInferior, c.icSuperior, 3)}</td>
        <td class="num" data-rot="${escAttr(T('reg.col.p', 'p-valor'))}">${pHtml(c.pValor, false)}</td>
        <td class="num" data-rot="${escAttr(T('reg.col.beta', 'β padronizado'))}">${beta}</td>
      </tr>`;
    }).join('');
    setHtml('reg-multipla-tabela', `<table class="reg-tabela">
      <thead><tr>
        <th scope="col">${esc(T('reg.col.variavel', 'Variável'))}</th>
        <th scope="col" class="num">${esc(T('reg.col.coef', 'Coeficiente (dias)'))}</th>
        <th scope="col" class="num">${esc(T('reg.col.ic', 'IC 95%'))}</th>
        <th scope="col" class="num">${esc(T('reg.col.p', 'p-valor'))}</th>
        <th scope="col" class="num">${esc(T('reg.col.beta', 'β padronizado'))}</th>
      </tr></thead><tbody>${linhas}</tbody></table>`);
    setHtml('reg-multipla-eq', esc(rm.equacao || T('reg.indisp', 'indisponível')));
  }

  // ── 6. Volume semanal, projecao e dimensionamento ────────────
  function regSemanal() {
    const t = dadosReg.tendenciaSemanal || {};
    const serie = Array.isArray(t.serie) ? t.serie : [];
    const sig = valido(t.pValor) && Number(t.pValor) < 0.05;

    setHtml('reg-semanal-chips',
      chip(T('reg.sem.media', 'Média'), valido(t.mediaSemanal)
        ? `${fmt(t.mediaSemanal, 1)}<small>${esc(T('reg.sem.por_semana', '/semana'))}</small>` : indisp()) +
      chip(T('reg.sem.inclinacao', 'Inclinação'), valido(t.inclinacao)
        ? `${fmt(t.inclinacao, 2, true)}<small>${esc(T('reg.sem.por_semana', '/semana'))}</small>` : indisp()) +
      chip('p', pHtml(t.pValor, false)) +
      chip(T('reg.r2', 'R²'), fmt(t.r2)) +
      chip(`${valido(t.semanas) ? t.semanas : ''} ${T('reg.sem.semanas', 'semanas analisadas')}`.trim(),
        t.de && t.ate ? esc(`${dataCurta(t.de, true)} ${T('reg.sem.a', 'a')} ${dataCurta(t.ate, true)}`) : indisp(), 'periodo') +
      (valido(t.pValor)
        ? `<span class="reg-tend ${sig ? 'sim' : 'nao'}">${esc(T(sig ? 'reg.sem.tendencia_sim' : 'reg.sem.tendencia_nao', ''))}</span>`
        : ''));

    setHtml('reg-semanal-obs', esc(t.observacao || ''));
    regEquipe(t);

    const canvas = document.getElementById('reg-semanal');
    if (!canvas || typeof Chart === 'undefined') return;
    canvas.setAttribute('aria-label', T('reg.g.semanal', 'Volume semanal'));
    if (graficos['reg-semanal']) graficos['reg-semanal'].destroy();
    const c = _cor();
    const primeiraProj = serie.findIndex(s => s.projecao);
    const temProj = primeiraProj >= 0;
    const num0 = v => (valido(v) ? Number(v) : null);
    // A faixa nasce no ultimo ponto observado (largura zero) e abre nas
    // semanas projetadas: o leque mostra que a incerteza cresce ao sair
    // do dado conhecido, sem buraco entre o observado e o projetado.
    const ancora = temProj && primeiraProj > 0 ? primeiraProj - 1 : -1;
    const faixa = (s, i, campo) => (s.projecao ? num0(s[campo]) : (i === ancora ? num0(s.previsto) : null));
    const corBarra = corVar('--reg-barra', '#1d4ed8');
    const corPrev = corVar('--reg-prev', '#0f172a');
    const corProj = corVar('--reg-proj', '#d97706');
    const corFaixa = corVar('--reg-proj-faixa', 'rgba(217,119,6,.18)');
    const corFundo = corVar('--reg-proj-fundo', 'rgba(217,119,6,.06)');
    const rotuloProj = T('reg.sem.projecao', 'Projeção');

    // Faixa de fundo atras das semanas projetadas, com o rotulo no topo.
    const fundoProjecao = {
      id: 'regFundoProjecao',
      beforeDatasetsDraw(chart) {
        if (!temProj) return;
        const { ctx, chartArea: a, scales: { x } } = chart;
        const passo = serie.length > 1 ? (x.getPixelForValue(1) - x.getPixelForValue(0)) : a.width;
        const ini = Math.max(a.left, x.getPixelForValue(primeiraProj) - passo / 2);
        ctx.save();
        ctx.fillStyle = corFundo;
        ctx.fillRect(ini, a.top, a.right - ini, a.bottom - a.top);
        ctx.strokeStyle = corProj;
        ctx.setLineDash([4, 4]);
        ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(ini, a.top); ctx.lineTo(ini, a.bottom); ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillStyle = corProj;
        ctx.font = '600 11px "DM Sans", sans-serif';
        ctx.textAlign = 'left';
        ctx.textBaseline = 'top';
        ctx.fillText(rotuloProj, ini + 6, a.top + 4);
        ctx.restore();
      },
    };

    graficos['reg-semanal'] = new Chart(canvas, {
      type: 'bar',
      data: {
        labels: serie.map(s => dataCurta(s.inicio)),
        datasets: [
          { type: 'line', label: '_min', data: serie.map((s, i) => faixa(s, i, 'previstoMin')),
            borderWidth: 0, pointRadius: 0, pointHoverRadius: 0, fill: false, order: 3 },
          { type: 'line', label: T('reg.sem.faixa', 'Faixa de 95% da projeção'),
            data: serie.map((s, i) => faixa(s, i, 'previstoMax')),
            borderWidth: 0, pointRadius: 0, pointHoverRadius: 0, backgroundColor: corFaixa, pointStyle: 'rect',
            borderColor: corFaixa, fill: '-1', order: 3 },
          { type: 'bar', label: T('reg.sem.obs', 'Denúncias registradas'),
            data: serie.map(s => (s.projecao ? null : num0(s.denuncias))),
            backgroundColor: corBarra, borderRadius: 4, maxBarThickness: 34, order: 2, pointStyle: 'rectRounded' },
          { type: 'line', label: T('reg.sem.prev', 'Previsto pelo modelo'), data: serie.map(s => num0(s.previsto)),
            borderColor: corPrev, backgroundColor: corPrev, borderWidth: 2, tension: 0, pointStyle: 'circle',
            pointRadius: serie.map(s => (s.projecao ? 4 : 0)), pointHoverRadius: 5,
            pointBackgroundColor: serie.map(s => (s.projecao ? corProj : corPrev)),
            pointBorderColor: serie.map(s => (s.projecao ? corProj : corPrev)),
            segment: {
              borderDash: ctx => (temProj && ctx.p1DataIndex >= primeiraProj ? [6, 4] : undefined),
              borderColor: ctx => (temProj && ctx.p1DataIndex >= primeiraProj ? corProj : corPrev),
            },
            order: 1 },
        ],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: { display: true, position: 'bottom',
                    labels: { color: c.texto, usePointStyle: true, boxWidth: 8, boxHeight: 8, padding: 14,
                              font: { size: 11.5 },
                              filter: it => it.text !== '_min',
                              generateLabels: ch => Chart.defaults.plugins.legend.labels.generateLabels(ch)
                                .map(l => (l.datasetIndex === 3 ? Object.assign(l, { pointStyle: 'line', lineWidth: 2, strokeStyle: corPrev }) : l)),
                              sort: (a, b) => [2, 3, 1].indexOf(a.datasetIndex) - [2, 3, 1].indexOf(b.datasetIndex) } },
          tooltip: {
            filter: it => it.dataset.label !== '_min' && it.raw !== null
              && !(it.datasetIndex === 1 && !serie[it.dataIndex].projecao),
            callbacks: {
              title: its => {
                const s = serie[its[0].dataIndex];
                return `${dataCurta(s.inicio, true)}${s.projecao ? ' · ' + rotuloProj : ''}`;
              },
              label: it => {
                const s = serie[it.dataIndex];
                if (it.datasetIndex === 1) return ` ${it.dataset.label}: ${fmtTxt(s.previstoMin, 1)} ${T('reg.sem.a', 'a')} ${fmtTxt(s.previstoMax, 1)}`;
                return ` ${it.dataset.label}: ${fmtTxt(it.raw, it.datasetIndex === 2 ? 0 : 1)}`;
              },
            },
          },
        },
        scales: {
          y: { beginAtZero: true, ticks: { color: c.texto, precision: 0 }, grid: { color: c.grade },
               border: { color: c.borda } },
          x: { ticks: { color: c.texto, maxRotation: 0, autoSkip: true, autoSkipPadding: 8 },
               grid: { display: false }, border: { color: c.borda } },
        },
      },
      plugins: [fundoProjecao],
    });
  }

  function regEquipe(t) {
    const atual = valido(t.equipe) ? Number(t.equipe) : null;
    const nec = valido(t.equipeNecessaria) ? Number(t.equipeNecessaria) : null;
    let pessoas = '';
    if (atual !== null && nec !== null && Math.max(atual, nec) <= 24) {
      const total = Math.max(atual, nec);
      const lista = [];
      for (let i = 0; i < total; i++) {
        const cls = i < Math.min(atual, nec) ? 'ok' : (i < atual ? 'sobra' : 'falta');
        lista.push(`<i class="${cls}"></i>`);
      }
      pessoas = `<div class="reg-pessoas" aria-hidden="true">${lista.join('')}</div>`;
    }
    let veredito = '';
    if (atual !== null && nec !== null) {
      veredito = nec > atual
        ? `<p class="reg-equipe-ver falta">${esc(T('reg.eq.faltam', '').replace('{n}', String(nec - atual)))}</p>`
        : `<p class="reg-equipe-ver ok">${esc(T('reg.eq.ok', ''))}</p>`;
    }
    const linha = (rot, v, un, casas) => `<div class="reg-equipe-lin"><dt>${esc(rot)}</dt>
      <dd>${valido(v) ? `<b>${fmt(v, casas)}</b> <small>${esc(un)}</small>` : indisp()}</dd></div>`;
    setHtml('reg-equipe', `<h5>${esc(T('reg.eq.titulo', 'Dimensionamento da equipe'))}</h5>
      <dl>
        ${linha(T('reg.eq.demanda', 'Demanda projetada'), t.demandaProjetada, T('reg.eq.demanda_u', ''), 1)}
        ${linha(T('reg.eq.capacidade', 'Capacidade por pessoa'), t.capacidadePorPessoa, T('reg.eq.capacidade_u', ''), 1)}
        ${linha(T('reg.eq.concluidas', 'Concluídas pela equipe'), t.concluidasPorSemana, T('reg.eq.concluidas_u', ''), 1)}
      </dl>
      <div class="reg-equipe-comp ${nec !== null && atual !== null && nec > atual ? 'falta' : ''}">
        <div><span>${esc(T('reg.eq.atual', 'Equipe atual'))}</span><b>${atual !== null ? esc(atual) : indisp()}</b></div>
        <span class="reg-seta" aria-hidden="true">➜</span>
        <div><span>${esc(T('reg.eq.necessaria', 'Necessária'))}</span><b>${nec !== null ? esc(nec) : indisp()}</b></div>
      </div>
      ${pessoas}${veredito}`);
  }

  // ── 7. Avisos de metodo ──────────────────────────────────────
  function regAvisos() {
    const av = Array.isArray(dadosReg.avisos) ? dadosReg.avisos.filter(Boolean) : [];
    setHtml('reg-avisos', av.length
      ? `<h5>${esc(T('reg.avisos', 'Cuidados na leitura'))}</h5><ul>${av.map(a => `<li>${esc(a)}</li>`).join('')}</ul>`
      : '');
    const el = document.getElementById('reg-avisos');
    if (el) el.hidden = !av.length;
  }

  function regEstado(classe, texto) {
    const aviso = document.getElementById('reg-aviso');
    const conteudo = document.getElementById('reg-conteudo');
    if (aviso) {
      aviso.className = 'est-aviso' + (classe ? ' ' + classe : '');
      aviso.textContent = texto || '';
    }
    if (conteudo) conteudo.hidden = classe !== 'oculto';
  }

  async function carregarRegressao(geracao) {
    regEstado('', T('reg.carregando', 'Calculando a análise no servidor…'));
    let r;
    try {
      r = await Backend.analisePreditiva();
    } catch (e) {
      if (geracao !== geracaoAtual) return;
      dadosReg = null; destruirReg();
      regEstado('erro', (e.status === 403 ? '🚫 ' : '❌ ') + (e.message || ''));
      setHtml('reg-meta', '');
      return;
    }
    if (geracao !== geracaoAtual) return;
    if (!r) {
      dadosReg = null; destruirReg();
      setHtml('reg-meta', '');
      regEstado('offline', T('reg.offline',
        'A análise de correlação e regressão é calculada no servidor. No modo demonstração ela não é exibida.'));
      return;
    }
    dadosReg = r;
    regEstado('oculto', '');
    try {
      regMeta();
      regInsights();
      regCorrelacoes();
      regMatriz();
      regSimples();
      regMultipla();
      regSemanal();
      regAvisos();
    } catch (e) {
      console.error('[Estatistica] falha ao montar a análise preditiva', e);
      destruirReg();
      regEstado('erro', `${T('reg.erro', 'Não foi possível montar a análise:')} ${e.message}`);
    }
  }

  // ── Carga ────────────────────────────────────────────────────
  // Cada carga ganha um numero. Respostas de uma carga antiga (troca rapida
  // de tema ou idioma, clique duplo em Atualizar) sao descartadas, para que
  // a tela nunca misture duas versoes nem crie graficos sobre canvas ja
  // reutilizado.
  let geracaoAtual = 0;

  async function carregarDescritivo(geracao) {
    const aviso = document.getElementById('est-aviso');
    if (aviso) {
      aviso.className = 'est-aviso';
      aviso.textContent = T('est.carregando', 'Calculando o relatório no servidor…');
    }
    let r;
    try {
      r = await Backend.relatorioAnalitico();
    } catch (e) {
      if (geracao !== geracaoAtual) return;
      if (aviso) {
        aviso.className = 'est-aviso erro';
        aviso.textContent = (e.status === 403 ? '🚫 ' : '❌ ') + e.message;
      }
      return;
    }
    if (geracao !== geracaoAtual) return;
    dados = r;
    if (!dados) {
      if (aviso) {
        aviso.className = 'est-aviso erro';
        aviso.textContent = T('est.offline',
          'O relatório estatístico é calculado no servidor. Sem a API no ar não há o que exibir — média e desvio das poucas denúncias guardadas neste navegador não descreveriam o canal.');
      }
      return;
    }
    if (aviso) aviso.className = 'est-aviso oculto';

    resumo();
    histograma();
    porTipo();
    porUrgencia();
    esperaAberto();
    dispersao();
    prazos();
  }

  async function carregar() {
    const g = ++geracaoAtual;
    await Promise.all([carregarRegressao(g), carregarDescritivo(g)]);
  }

  document.addEventListener('protege:idioma', () => {
    const painel = document.getElementById('tab-estatistica');
    if (painel && painel.style.display !== 'none') carregar();
  });

  return { carregar, abrir: carregar, dados: () => dados, dadosRegressao: () => dadosReg };
})();

window.Estatistica = Estatistica;
