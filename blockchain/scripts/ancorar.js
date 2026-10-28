// Protege+ | Ancora o estado atual da trilha e as evidencias novas.
//
// Antes de ancorar, confere se o ultimo checkpoint ainda bate com a trilha.
// Se nao bater, NAO ancora: ancorar por cima de uma trilha cortada seria dar
// o carimbo de autenticidade justamente para a versao adulterada.
const fs = require("fs");
const path = require("path");
const { ethers } = require("hardhat");
const { contrato, contas, api, pastaDaRede, gravarJson, ok, alerta, info, dataDoBloco } = require("./lib/comum");
const { novoSal, compromisso, arvore, bytes32 } = require("./lib/compromisso");

async function ultimoValido(ancora) {
  if ((await ancora.totalCheckpoints()) === 0n) return null;
  try {
    const [indice, c] = await ancora.ultimoValido();
    return { indice, c };
  } catch {
    return null; // todos contestados
  }
}

async function main() {
  const ancora = await contrato();
  const { ancorador } = await contas();
  const get = await api();

  console.log("\nAncoragem da trilha de auditoria do Protege+\n");

  let anterior = await ultimoValido(ancora);
  if (anterior) {
    const { indice, c } = anterior;
    const atual = await get(`/api/auditoria/ancoragem/registro/${c.ultimoRegistro}`);
    if (!atual.existe || bytes32(atual.hash) !== c.hashTrilha) {
      alerta(`O checkpoint #${indice} (registro ${c.ultimoRegistro}, ${dataDoBloco(c.ancoradoEm)}) nao confere mais.`);
      info("A trilha foi cortada ou alterada desde a ultima ancoragem. Nada foi ancorado.");
      info("Rode npm run verificar para o diagnostico completo.\n");
      process.exitCode = 2;
      return;
    }
    ok(`Checkpoint #${indice} anterior confere com a trilha (registro ${c.ultimoRegistro}).`);
  }

  let rodadas = 0;
  for (;;) {
    const evidenciasApos = anterior ? anterior.c.ultimaEvidencia : 0n;
    const e = await get(`/api/auditoria/ancoragem/estado?evidenciasApos=${evidenciasApos}`);

    if (!e.trilhaIntegra) {
      alerta(`A trilha esta rompida no registro ${e.rompidoNoRegistro}: ${e.motivo}. Nada foi ancorado.\n`);
      process.exitCode = 2;
      return;
    }
    if (e.ultimoRegistro == null) { info("Trilha vazia: nada a ancorar.\n"); return; }
    if (anterior && BigInt(e.ultimoRegistro) <= anterior.c.ultimoRegistro && e.evidencias.length === 0) {
      info("Nada novo desde a ultima ancoragem.\n");
      return;
    }

    const itens = e.evidencias.map((ev) => {
      const sal = novoSal();
      return { id: ev.id, hashArquivo: ev.hashSha256, sal, compromisso: compromisso(ev.hashSha256, sal) };
    });
    const t = itens.length ? arvore(itens.map((x) => x.compromisso)) : null;

    const tx = await ancora.connect(ancorador).ancorar(
      bytes32(e.hashUltimoRegistro), e.ultimoRegistro, e.totalRegistros,
      t ? t.root : ethers.ZeroHash, e.ultimaEvidencia, itens.length);
    const recibo = await tx.wait();
    const evento = recibo.logs.map((l) => ancora.interface.parseLog(l)).find((l) => l && l.name === "CheckpointAncorado");
    const indice = Number(evento.args.indice);
    const c = await ancora.checkpoint(indice);

    // O sal de cada evidencia fica so aqui, com o orgao. Sem ele nao ha prova.
    gravarJson(path.join(pastaDaRede(), `checkpoint-${String(indice).padStart(4, "0")}.json`), {
      indice, transacao: tx.hash, bloco: recibo.blockNumber,
      ancoradoEm: new Date(Number(c.ancoradoEm) * 1000).toISOString(),
      ultimoRegistro: e.ultimoRegistro, totalRegistros: e.totalRegistros,
      hashTrilha: bytes32(e.hashUltimoRegistro), ultimaEvidencia: e.ultimaEvidencia,
      evidencias: itens, arvore: t ? t.dump() : null,
    });

    ok(`Checkpoint #${indice} ancorado no bloco ${recibo.blockNumber} (${dataDoBloco(c.ancoradoEm)})`);
    info(`trilha: ${e.totalRegistros} registros, ultimo #${e.ultimoRegistro}, hash ${e.hashUltimoRegistro.slice(0, 16)}...`);
    info(`evidencias: ${itens.length} no lote${t ? `, raiz Merkle ${t.root.slice(0, 18)}...` : ""}`);
    info(`gas: ${recibo.gasUsed}  transacao: ${tx.hash}`);

    anterior = { indice: BigInt(indice), c };
    if (!e.haMaisEvidencias || ++rodadas >= 50) break;
  }
  console.log("");
}

main().catch((e) => { console.error(`\nERRO: ${e.message}\n`); process.exitCode = 1; });
