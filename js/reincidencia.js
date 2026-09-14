/**
 * reincidencia.js  .  Focos de reincidencia (Fase 6, Parte 4)
 *
 * Mostra grupos de denuncias que, embora anonimas e separadas, descrevem
 * uma mesma situacao em curso.
 *
 * A tela existe para responder uma pergunta que a lista plana nao responde:
 * seis relatos do mesmo bairro sao seis ocorrencias ou uma so? A resposta
 * muda a acao, e por isso o agrupamento aparece aqui como informacao de
 * primeira classe, e nao como um filtro escondido.
 *
 * Como o modulo de dispositivos, este NAO tem modo offline com exemplos.
 * Um foco inventado seria uma acusacao inventada sobre um lugar real.
 */
const Reincidencia = (() => {

  const TIPOS = {
    violencia:     { rotulo: 'Violência',     cor: '#dc2626' },
    abuso:         { rotulo: 'Abuso',         cor: '#ea580c' },
    assedio:       { rotulo: 'Assédio',       cor: '#d97706' },
    discriminacao: { rotulo: 'Discriminação', cor: '#7c3aed' },
    outros:        { rotulo: 'Outros',        cor: '#64748b' },
  };

  let janela = 90;
  let params = { janelaEloDias: 14, minimoParaFoco: 3 };

  function _esc(t) {
    return String(t ?? '').replace(/[&<>"']/g, c =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  function _data(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    return isNaN(d) ? _esc(iso)
                    : d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  function mudarJanela(dias, el) {
    janela = Number(dias) || 90;
    document.querySelectorAll('.rei-janela').forEach(b => b.classList.remove('active'));
    if (el) el.classList.add('active');
    atualizar();
  }

  async function abrir() {
    const p = await Backend.parametrosReincidencia();
    if (p) params = p;
    atualizar();
  }

  async function atualizar() {
    const alvo = document.getElementById('rei-lista');
    if (!alvo) return;
    alvo.innerHTML = '<div class="rei-vazio"><div class="rei-vazio-ic">⏳</div>'
                   + '<p>Analisando a janela...</p></div>';

    let focos = null;
    try { focos = await Backend.listarFocos(janela); }
    catch (e) { console.warn('[Reincidencia] falha ao consultar:', e); }

    const criterio = document.getElementById('rei-criterio');
    if (criterio) {
      criterio.innerHTML = `Duas denúncias entram na mesma cadeia quando são do mesmo tipo
        e do mesmo município e estão a no máximo <b>${params.janelaEloDias} dias</b> uma da outra,
        e a cadeia só é considerada a partir de <b>${params.minimoParaFoco}</b> denúncias.
        Quando uma cadeia reúne quase tudo o que aquele município produziu naquele tipo, ela
        deixa de ser um <b>foco</b> e passa a ser marcada como <b>fluxo contínuo</b>: não é um
        surto que se destaca, é a demanda normal do lugar.`;
    }

    if (focos === null) {
      alvo.innerHTML = `
        <div class="rei-vazio">
          <div class="rei-vazio-ic">🔌</div>
          <p><strong>Sem conexão com a API.</strong></p>
          <p>Esta análise roda no servidor e não tem versão offline: um foco
             inventado seria uma acusação inventada sobre um lugar real.</p>
        </div>`;
      _kpis(null);
      return;
    }

    if (!focos.length) {
      alvo.innerHTML = `
        <div class="rei-vazio">
          <div class="rei-vazio-ic">✅</div>
          <p><strong>Nenhum foco nesta janela.</strong></p>
          <p>Nenhuma cadeia de ${params.minimoParaFoco} ou mais denúncias encadeadas
             foi encontrada nos últimos ${janela} dias. Isso não significa ausência
             de casos: significa que os casos não se encadearam.</p>
        </div>`;
      _kpis([]);
      return;
    }

    _kpis(focos);
    alvo.innerHTML = focos.map(_cartao).join('');
  }

  function _kpis(focos) {
    const n   = document.getElementById('rei-kpi-focos');
    const d   = document.getElementById('rei-kpi-denuncias');
    const mai = document.getElementById('rei-kpi-maior');
    if (!focos) { [n, d, mai].forEach(e => { if (e) e.textContent = '.'; }); return; }
    const reais = focos.filter(f => !f.continuo);
    const total = focos.reduce((s, f) => s + f.quantidade, 0);
    if (n)   n.textContent = reais.length;
    if (d)   d.textContent = total;
    if (mai) mai.textContent = reais.length ? Math.max(...reais.map(f => f.quantidade)) : 0;
  }

  function _cartao(f) {
    const t = TIPOS[f.tipo] || { rotulo: f.tipo, cor: '#64748b' };
    // Duracao zero acontece quando o foco inteiro cabe num dia. Escrever
    // "0 dias" parece dado faltando; "no mesmo dia" e o que aconteceu.
    const dur = f.duracaoDias > 0 ? `${f.duracaoDias} dias` : 'no mesmo dia';
    const pct = Math.round((f.cobertura || 0) * 100);

    // Um agrupamento que reune quase todo o grupo nao destaca nada: ele E o
    // volume daquele lugar. Os dois pedem acoes diferentes, e por isso
    // recebem nomes diferentes em vez de aparecerem como a mesma coisa.
    const selo = f.continuo
      ? `<div class="rei-selo continuo">
           <b>Fluxo contínuo</b>
           <span>Este agrupamento reúne ${pct}% de tudo que ${_esc(f.cidade)} produziu
           neste tipo na janela. Não é um surto que começa e termina: é a demanda
           constante do lugar. Pede equipe permanente, não operação pontual.</span>
         </div>`
      : `<div class="rei-selo foco">
           <b>Foco</b>
           <span>${pct}% das denúncias deste tipo no município, concentradas em ${dur}.</span>
         </div>`;

    return `
      <div class="rei-card${f.continuo ? ' e-continuo' : ''}" style="--c:${t.cor}">
        <div class="rei-card-topo">
          <div>
            <div class="rei-card-tit">${_esc(f.cidade)}</div>
            <span class="rei-tipo" style="--c:${t.cor}">${_esc(t.rotulo)}</span>
          </div>
          <div class="rei-qtd">
            <span class="rei-qtd-num">${f.quantidade}</span>
            <span class="rei-qtd-rot">denúncias</span>
          </div>
        </div>

        <div class="rei-linha-tempo">
          <span>${_data(f.primeiro)}</span>
          <span class="rei-barra"></span>
          <span>${_data(f.ultimo)}</span>
          <span class="rei-dur">${dur}</span>
        </div>

        <div class="rei-metricas">
          <div><b>${f.scoreMedio}</b><span>score médio</span></div>
          <div><b>${f.scoreMaximo}</b><span>pior caso</span></div>
          <div><b>${(f.quantidade / Math.max(1, f.duracaoDias || 1)).toFixed(1)}</b><span>por dia</span></div>
        </div>

        ${selo}

        <div class="rei-protos">
          ${f.protocolos.map(p => `<code>${_esc(p)}</code>`).join('')}
        </div>
      </div>`;
  }

  return { abrir, atualizar, mudarJanela };
})();

window.Reincidencia = Reincidencia;
