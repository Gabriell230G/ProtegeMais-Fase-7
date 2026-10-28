// Protege+ | Implanta o contrato AncoraProtege.
//
// Conta 0 = orgao gestor (administra papeis, contesta).
// Conta 1 = rotina de ancoragem (so acrescenta checkpoints).
const fs = require("fs");
const path = require("path");
const hre = require("hardhat");
const { pastaDaRede, gravarJson, contas } = require("./lib/comum");

// Um contrato novo comeca do zero: os checkpoints do anterior (e os sais das
// evidencias) sao guardados de lado, nunca apagados.
function arquivarAnterior() {
  const pasta = pastaDaRede();
  const antigos = fs.readdirSync(pasta).filter((f) => f.endsWith(".json"));
  if (!antigos.length) return null;
  const destino = path.join(pasta, `anterior-${new Date().toISOString().replace(/[:.]/g, "-")}`);
  fs.mkdirSync(destino);
  for (const f of antigos) fs.renameSync(path.join(pasta, f), path.join(destino, f));
  return destino;
}

async function main() {
  const { gestor, ancorador } = await contas();
  const arquivado = arquivarAnterior();
  const Ancora = await hre.ethers.getContractFactory("AncoraProtege");
  const ancora = await Ancora.connect(gestor).deploy(gestor.address, ancorador.address);
  const recibo = await ancora.deploymentTransaction().wait();
  const endereco = await ancora.getAddress();

  gravarJson(path.join(pastaDaRede(), "implantacao.json"), {
    rede: hre.network.name,
    chainId: Number((await hre.ethers.provider.getNetwork()).chainId),
    endereco,
    gestor: gestor.address,
    ancorador: ancorador.address,
    bloco: recibo.blockNumber,
    implantadoEm: new Date().toISOString(),
  });

  console.log("\nAncoraProtege implantado");
  console.log(`  rede       ${hre.network.name}`);
  console.log(`  contrato   ${endereco}`);
  console.log(`  gestor     ${gestor.address}`);
  console.log(`  ancorador  ${ancorador.address}`);
  console.log(`  gas        ${recibo.gasUsed}`);
  if (arquivado) console.log(`  registros do contrato anterior guardados em ${path.relative(process.cwd(), arquivado)}`);
  console.log("");
}

main().catch((e) => { console.error(`\nERRO: ${e.message}\n`); process.exitCode = 1; });
