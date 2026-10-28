// Ajudantes usados pelos dois testes de navegador.
const fs = require('fs');
const path = require('path');

const sleep = ms => new Promise(r => setTimeout(r, ms));

// Uso offline (opcional): LIBS_LOCAIS=/pasta faz o navegador ler Chart.js e
// Leaflet de copias locais em vez da CDN. A pasta precisa ter os pacotes npm
// extraidos assim:
//   /pasta/chart.js-4.4.0/package/dist/chart.umd.js
//   /pasta/leaflet-1.9.4/package/dist/leaflet.js e leaflet.css
// Sem a variavel, o navegador busca as bibliotecas na CDN de verdade.
const LIBS = [
  [/cdnjs\.cloudflare\.com\/ajax\/libs\/Chart\.js\/4\.4\.0\/chart\.umd\.min\.js/, 'chart.js-4.4.0/package/dist/chart.umd.js', 'application/javascript'],
  [/unpkg\.com\/leaflet@1\.9\.4\/dist\/leaflet\.js/, 'leaflet-1.9.4/package/dist/leaflet.js', 'application/javascript'],
  [/unpkg\.com\/leaflet@1\.9\.4\/dist\/leaflet\.css/, 'leaflet-1.9.4/package/dist/leaflet.css', 'text/css'],
];

// Devolve true se a requisicao foi atendida por uma copia local.
async function servirLibLocal(route) {
  const pasta = process.env.LIBS_LOCAIS;
  if (!pasta) return false;
  const url = route.request().url();
  for (const [re, arq, tipo] of LIBS) {
    if (re.test(url)) {
      await route.fulfill({ status: 200, contentType: tipo, body: fs.readFileSync(path.join(pasta, arq)) });
      return true;
    }
  }
  return false;
}

module.exports = { sleep, servirLibLocal };
