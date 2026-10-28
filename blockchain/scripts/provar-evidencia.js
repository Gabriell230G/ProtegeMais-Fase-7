// Protege+ | Prova que um arquivo e exatamente a evidencia entregue, e desde quando.
//
// Uso (PowerShell):  $env:ARQUIVO="C:\caminho\foto.jpg"; npm run provar
// Uso (bash):        ARQUIVO=foto.jpg npm run provar
// Opcional: EVIDENCIA_ID=7 para dizer qual evidencia o arquivo deveria ser.
const fs = require("fs");
const path = require("path");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { contrato, pastaDaRede, lerJson, ok, alerta, info, dataDoBloco } = require("./lib/comum");
const { sha256Arquivo } = require("./lib/compromisso");

async function main() {
  const arquivo = process.env.ARQUIVO;
  if (!arquivo || !fs.existsSync(arquivo)) {
    throw new Error("Informe o arquivo na variavel ARQUIVO (ex.: ARQUIVO=foto.jpg npm run provar).");
  }
  const idEsperado = process.env.EVIDENCIA_ID ? Number(process.env.EVIDENCIA_ID) : null;
  const hash = sha256Arquivo(fs.readFileSync(arquivo));
  const ancora = await contrato();

  console.log(`\nProva de evidencia: ${path.basename(arquivo)}`);
  info(`SHA-256 do arquivo: ${hash}\n`);

  const checkpoints = fs.readdirSync(pastaDaRede()).filter((f) => /^checkpoint-\d+\.json$/.test(f)).sort();
  let porId = null;
  const iguais = [];
  for (const nome of checkpoints) {
    const cp = lerJson(path.join(pastaDaRede(), nome));
    for (const ev of cp.evidencias) {
      if (idEsperado !== null && ev.id === idEsperado) porId = { cp, ev };
      if (ev.hashArquivo.toLowerCase() !== hash) continue;
      if (idEsperado !== null && ev.id !== idEsperado) continue;
      iguais.push({ cp, ev });
    }
  }

  // O mesmo arquivo pode ter sido entregue mais de uma vez: prova o primeiro.
  if (iguais.length) {
    const { cp, ev } = iguais[0];
    const arvore = StandardMerkleTree.load(cp.arvore);
    let prova = null;
    for (const [i, v] of arvore.entries()) if (v[0] === ev.compromisso) prova = arvore.getProof(i);
    const valida = prova !== null && await ancora.provarEvidencia(cp.indice, ev.compromisso, prova);
    if (!valida) {
      alerta(`A evidencia #${ev.id} esta no registro local, mas a blockchain nao confirma (checkpoint contestado?).\n`);
      process.exitCode = 1;
      return;
    }
    const c = await ancora.checkpoint(cp.indice);
    ok(`E a evidencia #${ev.id}, sem nenhuma alteracao.`);
    ok(`Ancorada no checkpoint #${cp.indice}, bloco ${cp.bloco}, em ${dataDoBloco(c.ancoradoEm)}.`);
    info("O contrato conferiu a prova Merkle. Para apresentar a terceiros (juizo, MP):");
    info(`  sal          ${ev.sal}`);
    info(`  compromisso  ${ev.compromisso}`);
    info(`  prova        ${prova.length} hashes   transacao ${cp.transacao}`);
    if (iguais.length > 1) {
      info(`O mesmo arquivo tambem foi entregue como evidencia ${iguais.slice(1).map((x) => "#" + x.ev.id).join(", ")}.`);
    }
    console.log("");
    return;
  }

  if (porId) {
    alerta(`O arquivo NAO e a evidencia #${idEsperado} ancorada em ${dataDoBloco(Date.parse(porId.cp.ancoradoEm) / 1000)}.`);
    info(`entregue:     ${porId.ev.hashArquivo}`);
    info(`apresentado:  ${hash}`);
    info("Qualquer alteracao, ate um pixel ou um metadado, muda o hash.\n");
  } else {
    alerta("Nenhuma evidencia ancorada tem este conteudo (arquivo alterado, ou ainda nao ancorado).\n");
  }
  process.exitCode = 1;
}

main().catch((e) => { console.error(`\nERRO: ${e.message}\n`); process.exitCode = 1; });
