// Protege+ | Prova de que o front-end nao executa script injetado (XSS).
//
// O teste grava denuncias, equipe e respostas da API com codigo malicioso em
// TODOS os campos e percorre o site inteiro: consulta publica, canal seguro,
// chatbot, formulario, as 10 abas do painel, os botoes de cada linha e a ficha
// do caso. Cada payload, se executar, anota o nome do campo em window.__xss.
// No fim, conta quantos campos diferentes conseguiram executar script.
//
// Uso:
//   node xss.js                          (testa o JS atual do repositorio)
//   node xss.js --js-antigo <pasta>      (troca js/*.js pelos arquivos da pasta)
//
// Variaveis opcionais:
//   SITE_URL     endereco do site (padrao http://localhost:5500)
//   LIBS_LOCAIS  pasta com copias de Chart.js e Leaflet (ver comum.js)
//   DETALHE=1    imprime tambem o JSON completo de cada passo
//
// Saida: codigo 0 quando nenhum campo executou script, 1 quando algum executou,
// 2 quando o proprio teste nao conseguiu rodar (site fora do ar, tela quebrada).
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const { sleep, servirLibLocal } = require('./comum');

const BASE = (process.env.SITE_URL || 'http://localhost:5500').replace(/\/+$/, '');
const iArg = process.argv.indexOf('--js-antigo');
const JS_ANTIGO = iArg > 0 ? path.resolve(process.argv[iArg + 1] || '') : null;
if (JS_ANTIGO && !fs.existsSync(path.join(JS_ANTIGO, 'main.js'))) {
  console.error('A pasta ' + JS_ANTIGO + ' nao tem main.js. Informe a pasta js/ da versao antiga.');
  process.exit(2);
}

// ---------------------------------------------------------------- payloads ---
// Sentinela: qualquer execucao grava o nome do campo em window.__xss
const S = f => `window.__xss=(window.__xss||[]).concat('${f}')`;
const IMG = f => `<img src=x onerror="${S(f)}">`;                 // contexto de texto
const ATR = f => `"><svg onload="${S(f + '-attr')}">`;            // quebra de atributo
const JSQ = f => `X'-(${S(f + '-js')})-'`;                        // quebra de string JS em onclick
const ALL = f => `${f}:${IMG(f)}|${ATR(f)}`;                      // texto + atributo juntos

// Malha do IBGE (mapa do gestor) com nome de municipio malicioso
const MALHA = {
  type: 'FeatureCollection',
  features: [
    { type: 'Feature', properties: { nome: 'Campinas' }, geometry: { type: 'Polygon', coordinates: [[[-47.2, -22.8], [-46.9, -22.8], [-46.9, -23.0], [-47.2, -23.0], [-47.2, -22.8]]] } },
    { type: 'Feature', properties: { nome: IMG('ibge-nome') }, geometry: { type: 'Polygon', coordinates: [[[-48.2, -22.0], [-47.9, -22.0], [-47.9, -22.3], [-48.2, -22.3], [-48.2, -22.0]]] } },
  ],
};
const IBGE_ESTADOS = [{ id: 35, sigla: 'SP', nome: 'São Paulo' }, { id: 33, sigla: 'RJ', nome: 'Rio de Janeiro' }, { id: 31, sigla: 'MG', nome: 'Minas Gerais' }];
const IBGE_SP = [{ id: 1, nome: 'São Paulo' }, { id: 2, nome: 'Osasco' }, { id: 3, nome: 'Campinas' }];

function registros() {
  const base = { status: 'recebida', data: '2026-10-20', criadoEm: '20/10/2026', score: 50, scoreLabel: 'medium', scoreTxt: 'Média', anonimo: false, nivelAnonimato: 3,
    historico: [{ status: 'recebida', data: '20/10/2026', hora: '10:00' }] };
  const lista = [];
  // G: amostra do painel LGPD le o 1o relato com prefixo enc::
  lista.push(Object.assign({}, base, { id: '#2026-LGPD1', tipo: 'outros', local: 'Recife, PE', desc: 'enc::' + IMG('lgpd-amostra') }));
  // A: payload de texto/atributo em todos os campos + anexos com nome e base64 maliciosos
  for (let i = 0; i < 3; i++) {
    lista.push(Object.assign({}, base, {
      id: '#2026-A' + i + IMG('id'), tipo: 'violencia',
      nome: ALL('nome'), local: ALL('local') + ', SP', desc: ALL('desc'), endereco: ALL('endereco'),
      data: ALL('data'), criadoEm: ALL('criadoEm'), scoreTxt: ALL('scoreTxt'), scoreLabel: '"><img src=x onerror="' + S('scoreLabel') + '">',
      score: IMG('score'),
      historico: [{ status: ALL('hist-status'), data: ALL('hist-data'), hora: ALL('hist-hora') }],
      temAnexos: true,
      anexos: [
        { nome: 'foto' + ALL('anexo-nome') + '.png', tipo: 'image/png', tamanho: 10, base64: 'data:image/png;base64,AA" onerror="' + S('anexo-src') },
        { nome: 'doc' + ALL('anexo2-nome') + '.pdf', tipo: 'application/pdf', tamanho: 10, base64: 'javascript:' + S('anexo-js-href') },
        { nome: 'svg.svg', tipo: 'image/svg+xml', tamanho: 10, base64: 'data:image/svg+xml;base64,PHN2ZyBvbmxvYWQ9YWxlcnQoMSk+' },
        { nome: 'grande' + ALL('anexo3-nome'), tipo: 'video/mp4', tamanho: 10, base64: null, erro: ALL('anexo-erro') },
      ],
      temAudio: true,
      audio: { duracao: 5, base64: 'data:audio/webm;base64,AA" onerror="' + S('audio-src') },
    }));
  }
  // B: tipo e status maliciosos
  lista.push(Object.assign({}, base, { id: '#2026-B1', tipo: ALL('tipo'), status: ALL('status'), local: 'Osasco, SP', desc: 'b' }));
  lista.push(Object.assign({}, base, { id: '#2026-B2', tipo: ALL('tipo2'), local: 'Osasco, SP', desc: 'b2' }));
  // C: quebra de string JS em onclick (id, e apiId do botao de anexos do Kanban)
  lista.push(Object.assign({}, base, { id: '#2026-C1' + JSQ('id'), tipo: 'abuso', local: 'Campinas, SP', desc: 'c' }));
  lista.push(Object.assign({}, base, { id: '#2026-C2', apiId: '1);' + S('apiId-js') + ';(1', tipo: 'abuso', local: 'Campinas, SP', desc: 'c2' }));
  // D: dado normal com aspa simples (tem de abrir sem SyntaxError)
  lista.push(Object.assign({}, base, { id: "#2026-O'Brien", tipo: 'assedio', local: 'Recife, PE', desc: 'quote test', endereco: "Rua D'Ávila, 10", nome: 'Ana' }));
  // E: canal seguro (nivel 2) com mensagens maliciosas; E2 com codigo malicioso
  lista.push(Object.assign({}, base, { id: '#2026-E1', tipo: 'violencia', local: 'Recife, PE', desc: 'e', nivelAnonimato: 2, anonimo: true,
    codigoAcompanhamento: 'PROT-ABCD-EFGH',
    mensagens: [
      { autor: 'cidadao', texto: ALL('msg-texto'), data: ALL('msg-data'), hora: ALL('msg-hora') },
      { autor: '" onmouseover="' + S('msg-autor') + '" x="', texto: 'oi', data: '1', hora: '2' },
    ] }));
  lista.push(Object.assign({}, base, { id: '#2026-E2', tipo: 'violencia', local: 'Recife, PE', desc: 'e2', nivelAnonimato: 2, anonimo: true,
    codigoAcompanhamento: 'PROT-' + JSQ('codigo'), mensagens: [] }));
  // H: controle positivo, anexos e audio VALIDOS precisam continuar aparecendo
  const PNG = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  lista.push(Object.assign({}, base, { id: '#2026-H1', tipo: 'violencia', local: 'Recife, PE', desc: 'controle', temAnexos: true,
    anexos: [{ nome: 'foto-ok.png', tipo: 'image/png', tamanho: 70, base64: PNG },
             { nome: 'laudo.pdf', tipo: 'application/pdf', tamanho: 2048, base64: 'data:application/pdf;base64,JVBERi0xLjQK' }],
    temAudio: true, audio: { duracao: 65, base64: 'data:audio/webm;codecs=opus;base64,GkXfo0AgQoaBAUL3gQFC8oEEQvOBCEKCQAR3ZWJtQoeBAkKFgQIYU4BnAQAAAAAAAAA=' } }));
  // F: responsavel = membro malicioso da equipe
  lista.push(Object.assign({}, base, { id: '#2026-F1', tipo: 'violencia', local: 'Recife, PE', desc: 'f', responsavelId: "M1'-(" + S('membro-id-js') + ")-'" }));
  return lista;
}

const EQUIPE = [{ id: "M1'-(" + S('membro-id-js') + ")-'", nome: ALL('membro-nome'), cargo: ALL('membro-cargo'), email: ALL('membro-email') }];

// Respostas falsas da API (com payload em todos os campos) para os modulos que
// so funcionam online. Roda dentro da pagina, depois do login demo.
function instalarStubs() {
  const X = f => `${f}:<img src=x onerror="window.__xss=(window.__xss||[]).concat('${f}')">|"><svg onload="window.__xss=(window.__xss||[]).concat('${f}-attr')">`;
  const B = Backend;
  B.consultarFila = async () => ({ totalNaFila: X('fila-total'), diasDeEsperaDoMaisAntigo: X('fila-dias'), estrutura: X('fila-estr'),
    proximos: [{ protocolo: X('fila-proto'), urgenciaIa: X('fila-urg'), tipo: X('fila-tipo'), local: X('fila-local'), score: X('fila-score') }] });
  B.consultarPilha = async () => ({ tamanho: X('pilha-tam'), profundidadeMaxima: X('pilha-prof'), estrutura: X('pilha-estr'),
    acoes: [{ descricao: X('pilha-desc'), quando: X('pilha-quando') }] });
  B.consultarAuditoria = async () => ({ totalItens: 1, pagina: 0, totalPaginas: 1, temProxima: false,
    conteudo: [{ dataHora: X('aud-dh'), usuario: X('aud-usuario'), perfil: X('aud-perfil'), acao: X('aud-acao'), recurso: X('aud-recurso'),
      recursoId: X('aud-recid'), resultado: X('aud-result'), origemIp: X('aud-ip'), hashAnterior: X('aud-hashant'), hash: X('aud-hash') }] });
  B.acoesAuditadas = async () => ({ LOGIN: X('aud-acoes') });
  B.verificarIntegridade = async () => ({ integra: false, rompidoNoRegistro: X('aud-rompido'), motivo: X('aud-motivo'), totalDeRegistros: X('aud-total') });
  B.relatorioAnalitico = async () => ({
    universo: { total: X('est-total'), concluidas: X('est-concl'), emAberto: X('est-aberto') },
    leadTime: { media: 3, mediana: 2, desvio: 1, cv: 10, assimetria: 0.5, maximo: 9, outliers: [], cercaSup: 8 },
    percentisLeadTime: { p90: 7 }, dataReferencia: X('est-ref'),
    histogramaLeadTime: [{ rotulo: X('est-rotulo'), n: 3 }],
    leadPorTipo: [{ chave: X('est-chave'), media: 2 }, { chave: 'violencia', media: 4 }],
    leadPorUrgencia: [{ chave: 'ALTA', media: 1 }, { chave: 'BAIXA', media: 2 }],
    esperaEmAbertoPorUrgencia: [{ chave: X('est-urg'), media: 3, maximo: 4 }],
    dispersaoScoreLead: [{ score: 1, dias: 2 }], correlacaoScoreLead: { r: 0.1, r2: 0.01, leitura: X('est-leitura') },
    cumprimentoDePrazo: [{ dias: 2, percentual: 50 }, { dias: 5, percentual: 90 }],
  });
  B.parametrosReincidencia = async () => ({ janelaEloDias: X('rei-janela'), minimoParaFoco: X('rei-minimo') });
  B.listarFocos = async () => ([
    { tipo: X('rei-tipo'), cidade: X('rei-cidade'), quantidade: X('rei-qtd'), continuo: true, cobertura: 0.9, duracaoDias: 0,
      primeiro: X('rei-primeiro'), ultimo: X('rei-ultimo'), scoreMedio: X('rei-smed'), scoreMaximo: X('rei-smax'), protocolos: [X('rei-proto')] },
    { tipo: 'violencia', cidade: 'Campinas', quantidade: 4, continuo: false, cobertura: 0.5, duracaoDias: 3,
      primeiro: '2026-10-01', ultimo: '2026-10-04', scoreMedio: 50, scoreMaximo: 80, protocolos: ['#2026-1'] },
  ]);
  B.listarEventosIot = async () => ([{ origem: X('iot-origem'), situacao: X('iot-sit'), recebidoEm: X('iot-hora'), dispositivo: X('iot-disp'),
    protocoloGerado: X('iot-proto'), detalhe: X('iot-det') }]);
  B.resumoIot = async () => ({});
  B.statusIa = async () => ({ modo: X('ia-modo') });
  B.perguntarVigia = async () => X('vigia-resposta');
  B.detalharDenuncia = async (id) => ({ id, protocolo: X('det-proto'), tipo: X('det-tipo'), local: X('det-local'), status: X('det-status'),
    score: X('det-score'), scoreTxt: X('det-scoretxt'), urgenciaIa: X('det-urg'), anonimo: false, descricao: X('det-desc'),
    endereco: X('det-end'), criadoEm: X('det-criado'), concluidaEm: X('det-concl'), resumoIa: X('det-resumo'), origemAnalise: X('det-origem'),
    historico: [{ status: X('det-hist-st'), data: X('det-hist-dt'), hora: X('det-hist-hr') }] });
  B.listarEvidencias = async () => ([{ id: "1);window.__xss=(window.__xss||[]).concat('evid-id-js');(1", nomeOriginal: X('evid-nome'), tipoConteudo: X('evid-tipo'),
    tamanhoBytes: 2048, enviadoEm: X('evid-envio'), hashSha256: X('evid-hash') }]);
  window.__baixados = [];
  B.baixarEvidencia = async (id, nome) => { window.__baixados.push([id, nome]); };
  B.estaOnline = async () => false;
}

// ------------------------------------------------------------- navegador ---
async function rotear(route) {
  const req = route.request();
  const url = req.url();
  if (url.startsWith(BASE)) {
    // Modo "codigo antigo": troca js/*.js pela versao antiga. panico.js e
    // emergencia.js ficam na versao atual (a medicao original fez assim: a
    // versao antiga do panico redireciona a pagina e interromperia o teste).
    const m = JS_ANTIGO && url.split('?')[0].match(/\/js\/([a-z-]+\.js)$/);
    if (m && m[1] !== 'panico.js' && m[1] !== 'emergencia.js' && fs.existsSync(path.join(JS_ANTIGO, m[1]))) {
      return route.fulfill({ status: 200, contentType: 'application/javascript', body: fs.readFileSync(path.join(JS_ANTIGO, m[1])) });
    }
    return route.continue();
  }
  // IBGE sempre simulado: deixa o resultado igual em qualquer maquina e injeta o municipio malicioso
  if (/servicodados\.ibge\.gov\.br\/api\/v3\/malhas/.test(url)) return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(MALHA) });
  if (url.includes('servicodados.ibge.gov.br/api/v1/localidades/estados')) {
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(/municipios/.test(url) ? IBGE_SP : IBGE_ESTADOS) });
  }
  // A API real fica de fora: o site cai no modo demonstracao e os modulos
  // online recebem as respostas falsas de instalarStubs().
  if (/^https?:\/\/(localhost|127\.0\.0\.1):8080\//.test(url)) return route.abort('connectionrefused');
  // Botao de panico abre o Google: responde com uma pagina vazia
  if (/^https:\/\/www\.google\.com\//.test(url)) return route.fulfill({ status: 200, contentType: 'text/html', body: '<html><body>stub</body></html>' });
  // Bibliotecas e fontes vem da CDN (ou de LIBS_LOCAIS)
  if (/^https:\/\/(cdnjs\.cloudflare\.com|unpkg\.com|fonts\.googleapis\.com|fonts\.gstatic\.com)\//.test(url)) {
    if (await servirLibLocal(route)) return;
    return route.continue();
  }
  // Resto (VLibras, mapas de fundo, QR code) fica bloqueado para o teste ser repetivel
  return route.abort('blockedbyclient');
}

(async () => {
  const res = { siteUrl: BASE, jsAntigo: JS_ANTIGO, passos: {} };
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1366, height: 900 } });
  const page = await context.newPage();
  page.setDefaultTimeout(5000); // elemento que nao existe nesta versao nao trava o teste por 30 s
  const pageErrors = [];
  page.on('pageerror', e => pageErrors.push(String(e && e.message || e).split('\n')[0]));
  await context.route('**/*', rotear);

  try {
    await page.goto(BASE + '/index.html');
  } catch (e) {
    console.error('Nao foi possivel abrir ' + BASE + '/index.html. O site esta no ar? (py -m http.server 5500 na raiz do repositorio)');
    console.error(String(e).split('\n')[0]);
    await browser.close();
    process.exit(2);
  }

  const xss = () => page.evaluate(() => (window.__xss || []).slice());
  const passo = async (nome, fn) => {
    const e0 = pageErrors.length;
    let erro = null;
    try { await fn(); } catch (e) { erro = String(e).split('\n')[0]; }
    res.passos[nome] = { xss: [...new Set(await xss())], errosPagina: pageErrors.slice(e0), ...(erro ? { erroTeste: erro } : {}) };
  };

  await sleep(800);
  await page.evaluate(([lista, eq]) => {
    localStorage.clear();
    localStorage.setItem('denuncias', JSON.stringify(lista));
    localStorage.setItem('protege_equipe', JSON.stringify(eq));
  }, [registros(), EQUIPE]);
  await page.goto(BASE + '/index.html');
  await sleep(1500);

  await passo('01-landing-lgpd', async () => {
    // index.html nao tem #lgpd-body; cria o conteiner para exercitar LGPD.render()
    await page.evaluate(() => { const d = document.createElement('div'); d.id = 'lgpd-body'; document.body.appendChild(d); LGPD.render(); });
  });

  // Consulta publica por protocolo
  await passo('02-protocolo', async () => {
    await page.evaluate(() => navigate('status'));
    for (const id of ['#2026-A0', "#2026-O'Brien", '#2026-B1', '#2026-C1', '#2026-H1']) {
      await page.evaluate((id) => {
        const real = (getAllDenuncias().find(d => d.id.startsWith(id)) || {}).id || id;
        document.getElementById('protocolo-input').value = real;
        return buscarProtocolo();
      }, id);
      await sleep(400);
      if (id === '#2026-H1') {
        res.anexoValido = await page.evaluate(() => ({
          imagensCarregadas: [...document.querySelectorAll('#status-result img')].filter(i => i.complete && i.naturalWidth > 0).length,
          audio: !!document.querySelector('#status-result audio'),
        }));
      }
      if (id === "#2026-O'Brien") {
        await page.click('#status-result button'); // compartilhar
        await sleep(300);
      }
    }
  });

  await passo('03-hash-url', async () => {
    await page.evaluate(() => { location.hash = '#status:' + encodeURIComponent('<img src=x onerror="window.__xss=(window.__xss||[]).concat(\'hash\')">'); verificarProtocoloURL(); });
    await sleep(600);
  });

  await passo('04-codigo-seguro', async () => {
    await page.evaluate(() => { trocarAbaConsulta('codigo'); document.getElementById('consulta-codigo-input').value = 'PROT-ABCD-EFGH'; consultarCodigoSeguro(); });
    await sleep(500);
    for (const m of await page.$$('#consulta-resultado .elo-msg')) await m.hover().catch(() => {});
  });

  await passo('05-chatbot', async () => {
    await page.evaluate(() => navigate('landing'));
    await page.evaluate(() => Chatbot.open());
    await sleep(1200);
    for (const t of ['<img src=x onerror="window.__xss=(window.__xss||[]).concat(\'chat\')">', '"><svg onload="window.__xss=(window.__xss||[]).concat(\'chat-attr\')">', "'-alert(1)-'"]) {
      await page.fill('#chat-input', t);
      await page.press('#chat-input', 'Enter');
      await sleep(900);
    }
    await page.click('#chatbot-messages .chat-menu-btn >> nth=0').catch(() => {});
    await sleep(900);
    await page.evaluate(() => Chatbot.close());
  });

  await passo('06-form-arquivo', async () => {
    await page.setInputFiles('#fileInput', [{ name: 'a<img src=x onerror="window.__xss=(window.__xss||[]).concat(\'file\')">.png', mimeType: 'image/png', buffer: Buffer.from('x') }]);
    await sleep(300);
  });

  await passo('07-login-demo', async () => {
    await page.evaluate(() => navigate('login'));
    await page.click('button[onclick="entrarModoDemo()"]');
    await sleep(2000);
    res.painelAbriu = await page.$eval('#page-dashboard', el => el.classList.contains('active'));
    await page.evaluate(instalarStubs);
  });

  const abas = ['resumo', 'backlog', 'status-d', 'kanban', 'equipe', 'mapa', 'dispositivos', 'reincidencia', 'estatistica', 'auditoria'];
  res.abasAbertas = 0;
  for (const aba of abas) {
    await passo('10-aba-' + aba, async () => {
      await page.evaluate((aba) => {
        const el = [...document.querySelectorAll('.sidebar-item')].find(s => (s.getAttribute('onclick') || '').includes(`'${aba}'`));
        el.click();
      }, aba);
      await sleep(aba === 'mapa' ? 2500 : 1500);
      if (aba === 'mapa') {
        // abre os popups de todos os municipios
        await page.evaluate(() => { document.querySelectorAll('#mapa-gestor path.leaflet-interactive').forEach(p => p.dispatchEvent(new MouseEvent('click', { bubbles: true }))); });
        await sleep(500);
      }
      if (aba === 'auditoria') { await page.evaluate(() => Auditoria.verificarIntegridade()); await sleep(400); }
      if (aba === 'resumo') {
        await page.fill('#vigia-input', 'o que priorizar?').catch(() => {});
        await page.evaluate(() => VigIA.perguntar());
        await sleep(400);
      }
      res.abasAbertas++;
    });
  }

  // Cliques nos botoes montados com dado (backlog, status, canal, kanban, equipe)
  await passo('20-clique-backlog', async () => {
    await page.evaluate(() => showDashTab('backlog', document.querySelector('.sidebar-item:nth-child(2)')));
    await sleep(300);
    for (const alvo of ["O'Brien", 'C1']) {
      await page.evaluate((alvo) => {
        const tr = [...document.querySelectorAll('#backlog-tbody tr')].find(t => t.cells[0].textContent.includes(alvo));
        tr.querySelector('button').click();
      }, alvo);
      await sleep(400);
      await page.evaluate(() => Detalhe.fechar());
    }
  });

  await passo('21-clique-status-canal', async () => {
    await page.evaluate(() => showDashTab('status-d', document.querySelector('.sidebar-item:nth-child(3)')));
    await sleep(300);
    for (const alvo of ["O'Brien", 'C1']) {
      await page.evaluate((alvo) => {
        const tr = [...document.querySelectorAll('#status-tbody tr')].find(t => t.cells[0].textContent.includes(alvo));
        tr.querySelector('select').value = 'analise';
        tr.querySelector('button.btn-primary').click();
      }, alvo);
      await sleep(300);
      await page.click('.btn-confirm-sim').catch(() => {});
      await sleep(300);
    }
    for (const alvo of ['E1', 'E2']) {
      await page.evaluate((alvo) => {
        const tr = [...document.querySelectorAll('#status-tbody tr')].find(t => t.cells[0].textContent.includes('#2026-' + alvo));
        tr.querySelector('.btn-elo-gestor').click();
      }, alvo);
      await sleep(400);
      for (const m of await page.$$('#elo-msgs-gestor .elo-msg')) await m.hover().catch(() => {});
      await page.evaluate(() => EloGestor.fechar());
    }
  });

  await passo('22-clique-kanban', async () => {
    await page.evaluate(() => showDashTab('kanban', document.querySelector('.sidebar-item:nth-child(4)')));
    await sleep(500);
    for (const alvo of ["O'Brien", 'C1']) {
      await page.evaluate((alvo) => {
        const c = [...document.querySelectorAll('.kanban-card')].find(k => k.querySelector('.kc-proto').textContent.includes(alvo));
        c.click();
      }, alvo);
      await sleep(400);
      await page.evaluate(() => Detalhe.fechar());
    }
    // select de responsavel + confirmar no card F1
    await page.evaluate(() => {
      const c = [...document.querySelectorAll('.kanban-card')].find(k => k.querySelector('.kc-proto').textContent.includes('F1'));
      const sel = c.querySelector('select.kc-resp');
      sel.value = '';
      sel.dispatchEvent(new Event('change'));
      c.querySelector('.kc-confirm-resp').click();
    });
    await sleep(400);
    // botao de anexos do card C2 (apiId malicioso)
    await page.evaluate(() => {
      const c = [...document.querySelectorAll('.kanban-card')].find(k => k.querySelector('.kc-proto').textContent.includes('C2'));
      c?.querySelector('.kc-anexos')?.click();
    });
    await sleep(500);
    await page.evaluate(() => document.querySelector('#evid-lista .evid-item button')?.click());
    await sleep(300);
    await page.evaluate(() => Evidencias.fechar());
  });

  // Ficha do caso (API) com payload em todos os campos, leitura e edicao
  await passo('23-detalhe', async () => {
    await page.evaluate(() => Detalhe.abrir(7, '#x'));
    await sleep(600);
    await page.evaluate(() => Detalhe.editar());
    await sleep(300);
    for (const s of ['#det-endereco', '#det-descricao', '.det-anexos button']) await page.hover(s).catch(() => {});
    await page.evaluate(() => document.querySelector('#det-anexos .evid-item button')?.click());
    await sleep(300);
    await page.evaluate(() => Detalhe.fechar());
  });

  await passo('24-equipe-remover', async () => {
    await page.evaluate(() => showDashTab('equipe', document.querySelector('.sidebar-item:nth-child(5)')));
    await sleep(500);
    await page.click('#equipe-lista .eq-remover').catch(() => {});
    await sleep(500);
  });

  await passo('25-perfis', async () => {
    for (const p of ['gestor', 'analista', 'auditor', 'master']) {
      await page.click('#papel-' + p);
      await sleep(900);
      await page.evaluate(() => { renderStatusTable(); renderBacklog(); if (typeof Kanban !== 'undefined') Kanban.render(); });
    }
  });

  await passo('26-modo-seguro', async () => {
    await page.evaluate(() => { navigate('landing'); SafeMode.activate(); });
    await page.focus('#safe-search-input').catch(() => {});
    await sleep(300);
    await page.evaluate(() => SafeMode.deactivate());
  });

  const executaram = [...new Set(await xss())].sort();
  await browser.close();

  // ---------------------------------------------------------------- resumo ---
  if (process.env.DETALHE) console.log(JSON.stringify(res, null, 2));
  console.log('Protege+ | teste de XSS no navegador');
  console.log('Site: ' + BASE + (JS_ANTIGO ? '   (js/ trocado por ' + JS_ANTIGO + ')' : ''));
  console.log('');
  for (const [nome, p] of Object.entries(res.passos)) {
    const marca = p.erroTeste ? '  (passo nao completou: ' + p.erroTeste.slice(0, 90) + ')' : '';
    console.log('  ' + nome.padEnd(26) + ' campos que executaram ate aqui: ' + String(p.xss.length).padStart(2) + marca);
  }
  console.log('');
  console.log('Painel abriu no login demo: ' + (res.painelAbriu ? 'sim' : 'NAO') + ' | abas percorridas: ' + res.abasAbertas + ' de ' + abas.length);
  console.log('Anexo valido continua aparecendo (controle): ' + (res.anexoValido && res.anexoValido.imagensCarregadas === 1 && res.anexoValido.audio ? 'sim' : 'NAO'));
  if (executaram.length) console.log('Campos que executaram script: ' + executaram.join(' '));
  console.log('');
  console.log('pontos que executaram script: ' + executaram.length);

  // O teste so vale se percorreu tudo: sem isso, um 0 poderia ser falso.
  const incompleto = !res.painelAbriu || res.abasAbertas !== abas.length;
  if (incompleto) {
    console.log('ATENCAO: o teste nao percorreu o painel inteiro; o resultado nao vale.');
    process.exit(2);
  }
  process.exit(executaram.length === 0 ? 0 : 1);
})().catch(e => { console.error(e); process.exit(2); });
