// Protege+ | Fase 7, Parte 4: configuracao do Hardhat.
//
// O compilador Solidity vem do pacote npm "solc" (instalado junto com o
// projeto), em vez de ser baixado na primeira compilacao. Assim o projeto
// compila em rede corporativa ou sem internet, sempre com a mesma versao.
require("@nomicfoundation/hardhat-toolbox");

const path = require("path");
const { subtask } = require("hardhat/config");
const { TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD } = require("hardhat/builtin-tasks/task-names");

const VERSAO_SOLC = "0.8.28";

subtask(TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD, async (args, hre, runSuper) => {
  if (args.solcVersion !== VERSAO_SOLC) return runSuper();
  const solc = require("solc");
  return {
    compilerPath: path.join(path.dirname(require.resolve("solc/package.json")), "soljson.js"),
    isSolcJs: true,
    version: VERSAO_SOLC,
    longVersion: solc.version(),
  };
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: VERSAO_SOLC,
    settings: {
      optimizer: { enabled: true, runs: 200 },
      // "paris" (sem PUSH0/MCOPY) roda tambem em redes permissionadas mais
      // conservadoras, como as baseadas em Hyperledger Besu.
      evmVersion: "paris",
    },
  },
  networks: {
    hardhat: { chainId: 31337 },
    localhost: { url: "http://127.0.0.1:8545", chainId: 31337 },
    // Rede publica de teste ou rede permissionada (ex.: Besu da RBB):
    // defina RPC_URL e CHAVE_ANCORADOR no ambiente. Nada disso fica no codigo.
    ...(process.env.RPC_URL && process.env.CHAVE_GESTOR && process.env.CHAVE_ANCORADOR
      ? { remota: { url: process.env.RPC_URL,
                    accounts: [process.env.CHAVE_GESTOR, process.env.CHAVE_ANCORADOR] } }
      : {}),
  },
  gasReporter: { enabled: process.env.RELATORIO_GAS === "1", currency: "BRL" },
};
