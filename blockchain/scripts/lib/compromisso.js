// Protege+ | Compromisso de evidencia e arvore Merkle do lote.
//
// O hash puro de um arquivo nunca vai para a blockchain: quem tivesse uma
// copia da foto poderia calcular o hash e descobrir que ela foi entregue como
// prova. Cada evidencia entra como sha256(hashArquivo || sal), com um sal
// aleatorio de 32 bytes que fica so com o orgao.
const crypto = require("crypto");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

const HEX64 = /^[0-9a-fA-F]{64}$/;

function semPrefixo(h) {
  const s = String(h).replace(/^0x/, "");
  if (!HEX64.test(s)) throw new Error(`hash invalido: ${h}`);
  return s.toLowerCase();
}

function novoSal() {
  return crypto.randomBytes(32).toString("hex");
}

function compromisso(hashArquivo, sal) {
  const dados = Buffer.concat([Buffer.from(semPrefixo(hashArquivo), "hex"),
                               Buffer.from(semPrefixo(sal), "hex")]);
  return "0x" + crypto.createHash("sha256").update(dados).digest("hex");
}

function sha256Arquivo(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

/** Arvore no padrao do OpenZeppelin (folha com hash duplo), uma folha por compromisso. */
function arvore(compromissos) {
  return StandardMerkleTree.of(compromissos.map((c) => [c]), ["bytes32"]);
}

/** "0x" + 64 hex, como o Solidity espera um bytes32. */
function bytes32(h) {
  return "0x" + semPrefixo(h);
}

module.exports = { novoSal, compromisso, sha256Arquivo, arvore, bytes32, semPrefixo };
