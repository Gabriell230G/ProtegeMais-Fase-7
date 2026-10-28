// Protege+ | Testes do contrato de ancoragem (Fase 7, Parte 4).
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { compromisso, novoSal, sha256Arquivo, arvore, bytes32 } = require("../scripts/lib/compromisso");

const h = (texto) => ethers.sha256(ethers.toUtf8Bytes(texto)); // hash de um registro "da trilha"
const ZERO = ethers.ZeroHash;

describe("AncoraProtege", function () {
  async function implantado() {
    const [gestor, ancorador, intruso] = await ethers.getSigners();
    const Ancora = await ethers.getContractFactory("AncoraProtege");
    const ancora = await Ancora.deploy(gestor.address, ancorador.address);
    return { ancora, gestor, ancorador, intruso, Ancora };
  }

  /** Lote de evidencias com sal, como o roteiro de ancoragem monta. */
  function lote(qtd) {
    const itens = Array.from({ length: qtd }, (_, i) => {
      const hashArquivo = sha256Arquivo(Buffer.from(`foto-${i}-${Math.random()}`));
      const sal = novoSal();
      return { id: i + 1, hashArquivo, sal, compromisso: compromisso(hashArquivo, sal) };
    });
    return { itens, arvore: arvore(itens.map((x) => x.compromisso)) };
  }

  describe("implantacao e papeis", function () {
    it("gestor administra, ancorador ancora, e um nao faz o papel do outro", async function () {
      const { ancora, gestor, ancorador } = await loadFixture(implantado);
      const ANCORADOR = await ancora.ANCORADOR();
      expect(await ancora.hasRole(await ancora.DEFAULT_ADMIN_ROLE(), gestor.address)).to.equal(true);
      expect(await ancora.hasRole(ANCORADOR, ancorador.address)).to.equal(true);
      expect(await ancora.hasRole(ANCORADOR, gestor.address)).to.equal(false);
      await expect(ancora.connect(gestor).ancorar(h("r1"), 1, 1, ZERO, 0, 0))
        .to.be.revertedWithCustomError(ancora, "AccessControlUnauthorizedAccount");
    });

    it("recusa gestor nulo", async function () {
      const { Ancora } = await loadFixture(implantado);
      await expect(Ancora.deploy(ethers.ZeroAddress, ethers.ZeroAddress))
        .to.be.revertedWithCustomError(Ancora, "EnderecoInvalido");
    });

    it("conta estranha nao ancora nem contesta", async function () {
      const { ancora, ancorador, intruso } = await loadFixture(implantado);
      await expect(ancora.connect(intruso).ancorar(h("r1"), 1, 1, ZERO, 0, 0))
        .to.be.revertedWithCustomError(ancora, "AccessControlUnauthorizedAccount");
      await ancora.connect(ancorador).ancorar(h("r1"), 1, 1, ZERO, 0, 0);
      await expect(ancora.connect(intruso).contestar(0, "x"))
        .to.be.revertedWithCustomError(ancora, "AccessControlUnauthorizedAccount");
    });

    it("ancorador revogado (chave do servidor vazou) para de ancorar na hora", async function () {
      const { ancora, gestor, ancorador } = await loadFixture(implantado);
      await ancora.connect(gestor).revokeRole(await ancora.ANCORADOR(), ancorador.address);
      await expect(ancora.connect(ancorador).ancorar(h("r1"), 1, 1, ZERO, 0, 0))
        .to.be.revertedWithCustomError(ancora, "AccessControlUnauthorizedAccount");
    });

    it("nao aceita dinheiro: o contrato so guarda hashes", async function () {
      const { ancora, gestor } = await loadFixture(implantado);
      await expect(gestor.sendTransaction({ to: await ancora.getAddress(), value: 1n })).to.be.reverted;
    });
  });

  describe("ancoragem da trilha", function () {
    it("grava o checkpoint, com data do bloco e quem ancorou, e emite evento", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      await expect(ancora.connect(ancorador).ancorar(h("r30"), 30, 30, ZERO, 0, 0))
        .to.emit(ancora, "CheckpointAncorado")
        .withArgs(0, 30, 30, h("r30"), ZERO, 0, ancorador.address);

      const c = await ancora.checkpoint(0);
      expect(c.hashTrilha).to.equal(h("r30"));
      expect(c.ultimoRegistro).to.equal(30n);
      expect(c.ancorador).to.equal(ancorador.address);
      expect(c.ancoradoEm).to.equal(BigInt(await time.latest()));
      expect(await ancora.totalCheckpoints()).to.equal(1n);
      expect(await ancora.conferirTrilha(0, 30, h("r30"))).to.equal(true);
      expect(await ancora.conferirTrilha(0, 30, h("outro"))).to.equal(false);
    });

    it("recusa dado incoerente", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const a = ancora.connect(ancorador);
      await expect(a.ancorar(ZERO, 1, 1, ZERO, 0, 0)).to.be.revertedWithCustomError(ancora, "HashVazio");
      await expect(a.ancorar(h("r"), 0, 0, ZERO, 0, 0)).to.be.revertedWithCustomError(ancora, "DadosIncoerentes");
      await expect(a.ancorar(h("r"), 5, 6, ZERO, 0, 0)).to.be.revertedWithCustomError(ancora, "DadosIncoerentes");
      await expect(a.ancorar(h("r"), 5, 5, h("raiz"), 3, 0)).to.be.revertedWithCustomError(ancora, "LoteIncoerente");
      await expect(a.ancorar(h("r"), 5, 5, ZERO, 3, 2)).to.be.revertedWithCustomError(ancora, "LoteIncoerente");
      await expect(a.ancorar(h("r"), 5, 5, h("raiz"), 0, 2)).to.be.revertedWithCustomError(ancora, "LoteIncoerente");
    });

    it("servidor restaurado de backup antigo nao reancora o passado (exercicio B)", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const a = ancora.connect(ancorador);
      await a.ancorar(h("r30"), 30, 30, ZERO, 0, 0);
      // Depois do restore a trilha voltou para 12 registros, e o id 13 foi reutilizado.
      await expect(a.ancorar(h("r13-novo"), 13, 13, ZERO, 0, 0))
        .to.be.revertedWithCustomError(ancora, "RegistroNaoAvancou").withArgs(30, 13);
      await expect(a.ancorar(h("r30-outro"), 30, 30, ZERO, 0, 0))
        .to.be.revertedWithCustomError(ancora, "RegistroNaoAvancou");
      await expect(a.ancorar(h("r40"), 40, 30, ZERO, 0, 0))
        .to.be.revertedWithCustomError(ancora, "TotalNaoAvancou");
      expect(await ancora.conferirTrilha(0, 30, h("r30"))).to.equal(true);
    });

    it("checkpoints sao so acrescentados: a historia inteira continua consultavel", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const a = ancora.connect(ancorador);
      for (let i = 1; i <= 5; i++) await a.ancorar(h(`r${i * 10}`), i * 10, i * 10, ZERO, 0, 0);
      expect(await ancora.totalCheckpoints()).to.equal(5n);
      for (let i = 0; i < 5; i++) {
        expect(await ancora.conferirTrilha(i, (i + 1) * 10, h(`r${(i + 1) * 10}`))).to.equal(true);
      }
      const [indice] = await ancora.ultimoValido();
      expect(indice).to.equal(4n);
      await expect(ancora.checkpoint(5)).to.be.revertedWithCustomError(ancora, "IndiceInexistente");
    });

    it("sem nenhum checkpoint, ultimoValido avisa em vez de inventar", async function () {
      const { ancora } = await loadFixture(implantado);
      await expect(ancora.ultimoValido()).to.be.revertedWithCustomError(ancora, "NenhumCheckpoint");
    });
  });

  describe("evidencias", function () {
    it("prova que cada foto do lote existia, intacta, na data do bloco", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const { itens, arvore: t } = lote(7);
      await ancora.connect(ancorador).ancorar(h("r50"), 50, 50, t.root, 7, 7);

      for (const [i, v] of t.entries()) {
        expect(await ancora.provarEvidencia(0, v[0], t.getProof(i))).to.equal(true);
      }
      expect(itens.length).to.equal(7);
    });

    it("um pixel alterado na foto muda o hash e a prova falha", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const { itens, arvore: t } = lote(4);
      await ancora.connect(ancorador).ancorar(h("r50"), 50, 50, t.root, 4, 4);

      const adulterada = compromisso(sha256Arquivo(Buffer.from("foto editada")), itens[2].sal);
      expect(await ancora.provarEvidencia(0, adulterada, t.getProof(2))).to.equal(false);
      // Mesmo arquivo com outro sal tambem nao passa: o sal e parte da prova.
      const outroSal = compromisso(itens[2].hashArquivo, novoSal());
      expect(await ancora.provarEvidencia(0, outroSal, t.getProof(2))).to.equal(false);
    });

    it("prova de um lote nao vale em outro checkpoint", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const l1 = lote(3);
      const l2 = lote(3);
      const a = ancora.connect(ancorador);
      await a.ancorar(h("r10"), 10, 10, l1.arvore.root, 3, 3);
      await a.ancorar(h("r20"), 20, 20, l2.arvore.root, 6, 3);
      const c = l1.arvore.at(0)[0];
      expect(await ancora.provarEvidencia(0, c, l1.arvore.getProof(0))).to.equal(true);
      expect(await ancora.provarEvidencia(1, c, l1.arvore.getProof(0))).to.equal(false);
    });

    it("lote de evidencias nao pode voltar nem repetir o ultimo id", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const a = ancora.connect(ancorador);
      const l = lote(2);
      await a.ancorar(h("r10"), 10, 10, l.arvore.root, 8, 2);
      await expect(a.ancorar(h("r20"), 20, 20, ZERO, 5, 0))
        .to.be.revertedWithCustomError(ancora, "EvidenciaRetrocedeu");
      await expect(a.ancorar(h("r20"), 20, 20, lote(1).arvore.root, 8, 1))
        .to.be.revertedWithCustomError(ancora, "EvidenciaRetrocedeu");
      await a.ancorar(h("r20"), 20, 20, ZERO, 8, 0); // so a trilha, sem fotos novas
    });

    it("checkpoint sem evidencias nao prova nada", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      await ancora.connect(ancorador).ancorar(h("r10"), 10, 10, ZERO, 0, 0);
      expect(await ancora.provarEvidencia(0, h("qualquer"), [])).to.equal(false);
    });

    it("privacidade: o hash puro da foto nao aparece em nenhum lugar da cadeia", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const { itens, arvore: t } = lote(5);
      const tx = await ancora.connect(ancorador).ancorar(h("r10"), 10, 10, t.root, 5, 5);
      const recibo = await tx.wait();

      const visivel = (tx.data + recibo.logs.map((l) => l.data + l.topics.join("")).join("")).toLowerCase();
      for (const it of itens) {
        expect(visivel).to.not.include(it.hashArquivo);           // quem tem a foto nao acha
        expect(visivel).to.not.include(it.compromisso.slice(2));   // nem a folha individual
      }
      expect(visivel).to.include(t.root.slice(2).toLowerCase());   // so a raiz do lote
    });
  });

  describe("contestacao (resiliencia a chave comprometida)", function () {
    it("ancoragem forjada com numero gigante nao trava as proximas depois de contestada", async function () {
      const { ancora, gestor, ancorador } = await loadFixture(implantado);
      const a = ancora.connect(ancorador);
      await a.ancorar(h("r10"), 10, 10, ZERO, 0, 0);
      // Invasor com a chave do servidor tenta travar a ancoragem com um id absurdo.
      await a.ancorar(h("falso"), 2n ** 63n, 2n ** 63n, ZERO, 0, 0);
      await expect(a.ancorar(h("r20"), 20, 20, ZERO, 0, 0))
        .to.be.revertedWithCustomError(ancora, "RegistroNaoAvancou");

      await expect(ancora.connect(gestor).contestar(1, "chave do servidor comprometida"))
        .to.emit(ancora, "CheckpointContestado").withArgs(1, gestor.address, "chave do servidor comprometida");

      expect(await ancora.conferirTrilha(1, 2n ** 63n, h("falso"))).to.equal(false);
      const [indice] = await ancora.ultimoValido();
      expect(indice).to.equal(0n);
      await a.ancorar(h("r20"), 20, 20, ZERO, 0, 0); // volta a funcionar
      expect((await ancora.checkpoint(1)).contestado).to.equal(true); // o registro da fraude fica
      expect(await ancora.totalCheckpoints()).to.equal(3n);
    });

    it("contestar duas vezes ou um indice inexistente e recusado", async function () {
      const { ancora, gestor, ancorador } = await loadFixture(implantado);
      await ancora.connect(ancorador).ancorar(h("r10"), 10, 10, ZERO, 0, 0);
      await ancora.connect(gestor).contestar(0, "teste");
      await expect(ancora.connect(gestor).contestar(0, "de novo"))
        .to.be.revertedWithCustomError(ancora, "JaContestado");
      await expect(ancora.connect(gestor).contestar(9, "x"))
        .to.be.revertedWithCustomError(ancora, "IndiceInexistente");
      await expect(ancora.ultimoValido()).to.be.revertedWithCustomError(ancora, "NenhumCheckpoint");
    });

    it("contestar um checkpoint antigo nao mexe na referencia atual", async function () {
      const { ancora, gestor, ancorador } = await loadFixture(implantado);
      const a = ancora.connect(ancorador);
      await a.ancorar(h("r10"), 10, 10, ZERO, 0, 0);
      await a.ancorar(h("r20"), 20, 20, ZERO, 0, 0);
      await ancora.connect(gestor).contestar(0, "teste");
      const [indice] = await ancora.ultimoValido();
      expect(indice).to.equal(1n);
    });
  });

  describe("contestacao em sequencia", function () {
    it("contestar o mais recente pula os ja contestados e volta ao ultimo valido", async function () {
      const { ancora, gestor, ancorador } = await loadFixture(implantado);
      const a = ancora.connect(ancorador);
      await a.ancorar(h("r10"), 10, 10, ZERO, 0, 0);
      await a.ancorar(h("r20"), 20, 20, ZERO, 0, 0);
      await a.ancorar(h("r30"), 30, 30, ZERO, 0, 0);
      await ancora.connect(gestor).contestar(1, "lote suspeito");
      await ancora.connect(gestor).contestar(2, "lote suspeito");
      const [indice, c] = await ancora.ultimoValido();
      expect(indice).to.equal(0n);
      expect(c.ultimoRegistro).to.equal(10n);
      await a.ancorar(h("r15"), 15, 15, ZERO, 0, 0); // a referencia agora e o #0
    });
  });

  describe("custo", function () {
    it("ancorar um lote de 100 evidencias custa menos de 200 mil de gas", async function () {
      const { ancora, ancorador } = await loadFixture(implantado);
      const { arvore: t } = lote(100);
      const tx = await ancora.connect(ancorador).ancorar(h("r500"), 500, 500, t.root, 100, 100);
      const { gasUsed } = await tx.wait();
      console.log(`      gas da ancoragem (trilha + 100 evidencias): ${gasUsed}`);
      expect(gasUsed).to.be.lessThan(200000n);
      // O custo nao cresce com o tamanho do lote: so a raiz vai para a cadeia.
      const prova = t.getProof(57);
      console.log(`      tamanho da prova de 1 evidencia em 100: ${prova.length} hashes`);
      expect(prova.length).to.be.lessThanOrEqual(7);
    });
  });
});
