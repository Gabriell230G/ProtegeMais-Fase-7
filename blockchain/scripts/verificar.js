// Protege+ | Verificacao independente: a trilha de hoje ainda contem tudo o
// que foi ancorado?
//
// A cadeia de hash interna detecta registro alterado ou removido no meio.
// Esta verificacao pega o que a interna nao ve: o corte no fim da trilha
// (restauracao de backup antigo, ou alguem apagando os ultimos registros).
const { contrato, api, ok, alerta, info, dataDoBloco } = require("./lib/comum");
const { bytes32 } = require("./lib/compromisso");

async function main() {
  const ancora = await contrato();
  const get = await api();
  const total = Number(await ancora.totalCheckpoints());

  console.log("\nVerificacao da trilha contra a blockchain\n");
  if (total === 0) { info("Nenhum checkpoint ancorado ainda. Rode npm run ancorar.\n"); return; }

  let falhas = 0;
  let integra = true;
  let registrosHoje = null;
  for (let i = 0; i < total; i++) {
    const c = await ancora.checkpoint(i);
    const quando = dataDoBloco(c.ancoradoEm);
    if (c.contestado) { info(`#${i}  contestado pelo orgao gestor: ignorado`); continue; }

    const r = await get(`/api/auditoria/ancoragem/registro/${c.ultimoRegistro}`);
    integra = r.trilhaIntegra;
    registrosHoje = r.totalRegistros;
    // A comparacao final e feita pelo proprio contrato, nao por este roteiro.
    const confere = r.existe && await ancora.conferirTrilha(i, c.ultimoRegistro, bytes32(r.hash));

    if (confere) {
      ok(`#${i}  ${quando}  registro ${c.ultimoRegistro} presente, hash confere`);
    } else if (!r.existe) {
      falhas++;
      alerta(`#${i}  ${quando}  o registro ${c.ultimoRegistro} NAO EXISTE MAIS na trilha`);
      info(`    Ancorado com ${c.totalRegistros} registros; hoje a trilha tem ${r.totalRegistros}.`);
      info("    A trilha foi cortada depois da ancoragem (backup antigo restaurado ou registros apagados).");
    } else {
      falhas++;
      alerta(`#${i}  ${quando}  o registro ${c.ultimoRegistro} existe, mas com OUTRO conteudo`);
      info(`    ancorado: ${c.hashTrilha.slice(2, 18)}...   hoje: ${r.hash.slice(0, 16)}...`);
      info("    O registro foi substituido: tipico de restauracao seguida de novos registros, que reutilizam os ids.");
    }
  }

  console.log("");
  if (!integra) alerta("A cadeia interna tambem esta rompida: veja GET /api/auditoria/integridade.");
  if (falhas === 0) {
    ok(`Trilha completa: tudo o que foi ancorado continua la (${registrosHoje} registros hoje).\n`);
  } else {
    alerta(`${falhas} checkpoint(s) nao conferem. A trilha atual NAO e a mesma que foi ancorada.\n`);
    process.exitCode = 1;
  }
}

main().catch((e) => { console.error(`\nERRO: ${e.message}\n`); process.exitCode = 1; });
