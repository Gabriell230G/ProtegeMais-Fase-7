// Protege+ | Funcoes comuns dos roteiros de ancoragem.
const fs = require("fs");
const path = require("path");
const hre = require("hardhat");

const API = (process.env.PROTEGE_API || "http://localhost:8080").replace(/\/+$/, "");

// A rotina de ancoragem so le: por isso usa a conta de AUDITOR, nao a de ADMIN.
// Em producao as contas de demonstracao nao existem: informe as variaveis.
const EMAIL = process.env.PROTEGE_EMAIL || "auditor@protege.gov.br";
const SENHA = process.env.PROTEGE_SENHA || "auditor123";

function pastaDaRede() {
  const p = path.join(__dirname, "..", "..", "ancoragens", hre.network.name);
  fs.mkdirSync(p, { recursive: true });
  return p;
}

function lerJson(arquivo) {
  return JSON.parse(fs.readFileSync(arquivo, "utf8"));
}

function gravarJson(arquivo, dados) {
  fs.writeFileSync(arquivo, JSON.stringify(dados, null, 2) + "\n", { mode: 0o600 });
}

async function contrato() {
  const arq = path.join(pastaDaRede(), "implantacao.json");
  if (!fs.existsSync(arq)) {
    throw new Error(`Contrato nao implantado na rede "${hre.network.name}". Rode antes: npm run implantar`);
  }
  const { endereco } = lerJson(arq);
  const codigo = await hre.ethers.provider.getCode(endereco);
  if (codigo === "0x") {
    throw new Error(`Nao ha contrato em ${endereco}. O no local foi reiniciado? Rode npm run implantar de novo.`);
  }
  return hre.ethers.getContractAt("AncoraProtege", endereco);
}

async function contas() {
  const [gestor, ancorador] = await hre.ethers.getSigners();
  return { gestor, ancorador };
}

/** Cliente minimo da API do Protege+, com o token da conta de leitura. */
async function api() {
  let resp;
  try {
    resp = await fetch(`${API}/api/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: EMAIL, senha: SENHA }),
    });
  } catch (e) {
    throw new Error(`API fora do ar em ${API}. Suba o backend (build.cmd run) ou ajuste PROTEGE_API.`);
  }
  if (resp.status === 429) throw new Error("Muitas tentativas de login: espere um minuto.");
  if (!resp.ok) throw new Error(`Login recusado para ${EMAIL} (HTTP ${resp.status}). Ajuste PROTEGE_EMAIL e PROTEGE_SENHA.`);
  const { token } = await resp.json();

  return async function get(caminho) {
    const r = await fetch(`${API}${caminho}`, { headers: { Authorization: `Bearer ${token}` } });
    if (!r.ok) throw new Error(`GET ${caminho}: HTTP ${r.status}`);
    return r.json();
  };
}

const ok = (t) => console.log(`  [OK]     ${t}`);
const alerta = (t) => console.log(`  [ALERTA] ${t}`);
const info = (t) => console.log(`           ${t}`);

function dataDoBloco(segundos) {
  return new Date(Number(segundos) * 1000).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" });
}

module.exports = { API, pastaDaRede, lerJson, gravarJson, contrato, contas, api, ok, alerta, info, dataDoBloco };
