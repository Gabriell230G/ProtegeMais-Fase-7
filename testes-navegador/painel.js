// Protege+ | Painel completo aberto por HTTPS atraves da borda nginx.
//
// Entra como administrador pela tela de login em https://localhost:8443,
// abre cada aba do painel e anota:
//   - violacoes da politica de conteudo (CSP) mandada pelo nginx
//   - erros de JavaScript na pagina
//   - cada chamada a /api e o codigo de resposta
//
// Uso:  node painel.js
// Variaveis opcionais:
//   BORDA_URL     endereco da borda (padrao https://localhost:8443)
//   ADMIN_EMAIL / ADMIN_SENHA   (padrao admin@protege.gov.br / admin123)
//   LIBS_LOCAIS   pasta com copias de Chart.js e Leaflet (ver comum.js)
//
// Sobre o certificado: o navegador do teste usa ignoreHTTPSErrors, porque o
// certificado da borda e emitido pela AC de teste do projeto
// (infra/pki/saida/ac-servidor.crt), que o Chromium nao conhece. A validacao do
// certificado em si ja e conferida pelo infra/testar-rede.sh.
//
// Saida: codigo 0 quando login, abas, CSP, erros e API estao todos certos; 1
// quando algo falhou.
const { chromium } = require('playwright');
const { sleep, servirLibLocal } = require('./comum');

const URL_BORDA = (process.env.BORDA_URL || 'https://localhost:8443').replace(/\/+$/, '');
const EMAIL = process.env.ADMIN_EMAIL || 'admin@protege.gov.br';
const SENHA = process.env.ADMIN_SENHA || 'admin123';
const ABAS_ESPERADAS = 10;

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: 1366, height: 860 } });
  const page = await ctx.newPage();
  page.setDefaultTimeout(10000);

  const csp = [];        // violacoes vistas pelo evento securitypolicyviolation
  const cspConsole = []; // as mesmas, vistas pelo console do navegador
  const erros = [];
  const api = new Map(); // "GET /api/stats" -> Set de codigos
  const falhasApi = [];

  await page.exposeFunction('__violacaoCsp', v => csp.push(v));
  await page.addInitScript(() => {
    document.addEventListener('securitypolicyviolation', e =>
      window.__violacaoCsp(e.violatedDirective + ' bloqueou ' + (e.blockedURI || '(inline)')));
  });
  page.on('console', m => { const t = m.text(); if (/Content Security Policy|Refused to/i.test(t)) cspConsole.push(t.slice(0, 220)); });
  page.on('pageerror', e => erros.push(String(e && e.message || e).split('\n')[0].slice(0, 200)));
  page.on('response', r => {
    const u = new URL(r.url());
    if (!u.pathname.startsWith('/api/')) return;
    const k = r.request().method() + ' ' + u.pathname.replace(/\/\d+(?=\/|$)/g, '/{id}');
    if (!api.has(k)) api.set(k, new Set());
    api.get(k).add(r.status());
    if (r.status() >= 400) falhasApi.push(r.status() + ' ' + k);
  });
  if (process.env.LIBS_LOCAIS) {
    await ctx.route(/^https:\/\/(cdnjs\.cloudflare\.com|unpkg\.com)\//, async route => { if (!(await servirLibLocal(route))) await route.continue(); });
  }

  const falhar = async (msg) => {
    console.log('FALHOU: ' + msg);
    if (erros.length) console.log('Erros na pagina: ' + erros.join(' | '));
    if (falhasApi.length) console.log('API: ' + falhasApi.join(' | '));
    await browser.close();
    process.exit(1);
  };

  try {
    await page.goto(URL_BORDA + '/', { waitUntil: 'load', timeout: 30000 });
  } catch (e) {
    return falhar('nao abriu ' + URL_BORDA + '. A borda esta no ar? (bash testes-navegador/subir-borda.sh)\n' + String(e).split('\n')[0]);
  }
  await sleep(1500);
  const protocolo = await page.evaluate(() => location.protocol);

  // Login pela tela, como uma pessoa faria
  await page.evaluate(() => navigate('login'));
  await page.fill('#login-user', EMAIL);
  await page.fill('#login-pass', SENHA);
  await page.click('#page-login .btn-primary');
  const entrou = await page.waitForFunction(() => document.getElementById('page-dashboard').classList.contains('active'), null, { timeout: 10000 })
    .then(() => true, () => false);
  if (!entrou) {
    const toast = await page.$eval('#toast', el => el.textContent).catch(() => '');
    return falhar('login de administrador nao abriu o painel. Aviso na tela: ' + toast);
  }
  await sleep(1500);

  // Abre cada aba visivel para o perfil
  const abas = await page.$$eval('.sidebar-item', els => els.filter(e => e.style.display !== 'none')
    .map(e => ((e.getAttribute('onclick') || '').match(/showDashTab\('([^']+)'/) || [])[1]).filter(Boolean));
  const abertas = [];
  for (const aba of abas) {
    await page.evaluate(a => showDashTab(a), aba);
    await sleep(aba === 'estatistica' || aba === 'mapa' ? 2500 : 1200);
    const ativa = await page.evaluate(a => { const t = document.getElementById('tab-' + a); return !!t && t.style.display === 'block' && t.offsetHeight > 0; }, aba);
    if (ativa) abertas.push(aba);
  }
  await sleep(1000);
  await browser.close();

  // ---------------------------------------------------------------- resumo ---
  const rotas200 = [...api].filter(([, cods]) => [...cods].every(c => c === 200)).map(([k]) => k).sort();
  // Conta pelo evento (1 por violacao); o console so entra se o evento nao pegou nada
  const violacoes = csp.length || cspConsole.length;
  console.log('Protege+ | painel completo pela borda HTTPS');
  console.log('Endereco: ' + URL_BORDA + ' | protocolo da pagina: ' + protocolo.replace(':', '') + ' | login: ' + EMAIL);
  console.log('');
  console.log('Abas abertas: ' + abertas.length + ' (' + abertas.join(', ') + ')');
  console.log('Rotas da API chamadas: ' + api.size + ' | respondendo 200: ' + rotas200.length);
  for (const [k, cods] of [...api].sort()) console.log('  ' + [...cods].join('/') + '  ' + k);
  console.log('Violacoes da politica de conteudo (CSP): ' + violacoes);
  for (const v of csp.length ? csp : cspConsole) console.log('  ' + v);
  console.log('Erros de JavaScript na pagina: ' + erros.length);
  for (const e of erros) console.log('  ' + e);
  console.log('');

  const problemas = [];
  if (protocolo !== 'https:') problemas.push('a pagina nao abriu em HTTPS');
  if (abertas.length !== ABAS_ESPERADAS || abertas.length !== abas.length) problemas.push('esperava ' + ABAS_ESPERADAS + ' abas abertas, abriram ' + abertas.length);
  if (violacoes) problemas.push(violacoes + ' violacao(oes) de CSP');
  if (erros.length) problemas.push(erros.length + ' erro(s) de JavaScript');
  if (falhasApi.length) problemas.push('API com erro: ' + [...new Set(falhasApi)].join(', '));
  if (problemas.length) { console.log('RESULTADO: FALHOU (' + problemas.join('; ') + ')'); process.exit(1); }
  console.log('RESULTADO: OK (' + abertas.length + ' abas, ' + rotas200.length + ' rotas da API com 200, 0 violacoes de CSP, 0 erros)');
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
