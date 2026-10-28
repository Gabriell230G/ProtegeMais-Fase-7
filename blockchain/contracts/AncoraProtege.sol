// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title  AncoraProtege
 * @author Gabriel Vasconcellos Gomes (RM 561601), Protege+ Fase 7
 * @notice Cartorio digital do Protege+. Guarda fora do servidor a "impressao
 *         digital" da trilha de auditoria e das evidencias, para que nem quem
 *         administra o servidor consiga apagar ou trocar o passado sem deixar
 *         prova.
 *
 * Por que existe
 * --------------
 * A trilha de auditoria do Protege+ e encadeada por SHA-256: cada registro
 * carrega o hash do anterior, e alterar ou remover um registro do meio quebra
 * a cadeia. O exercicio B da Parte 1 mostrou o limite disso: restaurar um
 * backup antigo CORTA o fim da trilha, e o que sobra continua coerente
 * consigo mesmo. Quem guarda a cadeia (o servidor) nao pode ser quem atesta
 * que ela esta completa. Este contrato e a testemunha externa.
 *
 * O que vai para a blockchain (e o que nunca vai)
 * ----------------------------------------------
 * Vai: o hash do ultimo registro da trilha (que resume todos os anteriores),
 * contadores e a raiz Merkle de um lote de evidencias.
 * Nunca vai: nome, protocolo, relato, endereco, e-mail, IP ou o hash puro de
 * um arquivo. Cada evidencia entra como compromisso sha256(hashArquivo || sal),
 * com um sal aleatorio guardado fora da cadeia. Sem o sal, quem tem uma copia
 * da foto nao consegue confirmar que ela foi entregue como prova. Isso
 * importa porque um registro em blockchain nao pode ser apagado: o contrato
 * nao pode guardar nada que a LGPD mandaria eliminar depois.
 *
 * Papeis (separacao de funcoes)
 * -----------------------------
 * DEFAULT_ADMIN_ROLE (orgao gestor): autoriza e revoga ancoradores e pode
 *   CONTESTAR uma ancoragem. Nao ancora.
 * ANCORADOR (servidor ou rotina de ancoragem): so acrescenta checkpoints.
 *   Ninguem altera nem apaga um checkpoint: contestar marca, nao remove.
 */
contract AncoraProtege is AccessControl {
    bytes32 public constant ANCORADOR = keccak256("ANCORADOR");

    /// @dev Quatro slots de armazenamento. A ordem dos campos e a do empacotamento.
    struct Checkpoint {
        bytes32 hashTrilha;           // SHA-256 do ultimo registro coberto
        bytes32 raizEvidencias;       // raiz Merkle dos compromissos do lote (0 = sem evidencias)
        uint64 ultimoRegistro;        // id do ultimo registro da trilha coberto
        uint64 totalRegistros;        // quantos registros a trilha tinha naquele momento
        uint64 ultimaEvidencia;       // maior id de evidencia ja coberto
        uint32 quantidadeEvidencias;  // tamanho do lote
        uint40 ancoradoEm;            // carimbo de tempo do bloco
        address ancorador;
        bool contestado;
    }

    Checkpoint[] private _checkpoints;

    /// @dev Indice + 1 do checkpoint valido mais recente (0 = nenhum).
    uint256 private _ultimoValido;

    event CheckpointAncorado(
        uint256 indexed indice,
        uint64 ultimoRegistro,
        uint64 totalRegistros,
        bytes32 hashTrilha,
        bytes32 raizEvidencias,
        uint32 quantidadeEvidencias,
        address indexed ancorador
    );

    event CheckpointContestado(uint256 indexed indice, address indexed gestor, string motivo);

    error EnderecoInvalido();
    error HashVazio();
    error DadosIncoerentes();
    error LoteIncoerente();
    error RegistroNaoAvancou(uint64 ultimoAncorado, uint64 informado);
    error TotalNaoAvancou(uint64 ultimoAncorado, uint64 informado);
    error EvidenciaRetrocedeu(uint64 ultimaAncorada, uint64 informada);
    error IndiceInexistente(uint256 indice);
    error JaContestado(uint256 indice);
    error NenhumCheckpoint();

    /**
     * @param gestor            conta do orgao gestor (administra os papeis)
     * @param ancoradorInicial  conta da rotina de ancoragem; address(0) para autorizar depois
     */
    constructor(address gestor, address ancoradorInicial) {
        if (gestor == address(0)) revert EnderecoInvalido();
        _grantRole(DEFAULT_ADMIN_ROLE, gestor);
        if (ancoradorInicial != address(0)) _grantRole(ANCORADOR, ancoradorInicial);
    }

    // ------------------------------------------------------------------
    // Escrita
    // ------------------------------------------------------------------

    /**
     * @notice Registra um checkpoint da trilha e, opcionalmente, um lote de evidencias.
     * @dev    So avanca: o registro, o total e a ultima evidencia nunca podem
     *         voltar em relacao ao ultimo checkpoint valido. Um servidor
     *         restaurado de um backup antigo nao consegue "reancorar" o
     *         passado por cima do que ja foi ancorado.
     * @return indice posicao do novo checkpoint
     */
    function ancorar(
        bytes32 hashTrilha,
        uint64 ultimoRegistro,
        uint64 totalRegistros,
        bytes32 raizEvidencias,
        uint64 ultimaEvidencia,
        uint32 quantidadeEvidencias
    ) external onlyRole(ANCORADOR) returns (uint256 indice) {
        if (hashTrilha == bytes32(0)) revert HashVazio();
        // Ids da trilha sao positivos e unicos: o total nunca passa do maior id.
        if (ultimoRegistro == 0 || totalRegistros == 0 || totalRegistros > ultimoRegistro) {
            revert DadosIncoerentes();
        }
        if ((quantidadeEvidencias == 0) != (raizEvidencias == bytes32(0))) revert LoteIncoerente();
        if (quantidadeEvidencias > 0 && ultimaEvidencia == 0) revert LoteIncoerente();

        if (_ultimoValido != 0) {
            Checkpoint storage ant = _checkpoints[_ultimoValido - 1];
            if (ultimoRegistro <= ant.ultimoRegistro) {
                revert RegistroNaoAvancou(ant.ultimoRegistro, ultimoRegistro);
            }
            if (totalRegistros <= ant.totalRegistros) {
                revert TotalNaoAvancou(ant.totalRegistros, totalRegistros);
            }
            if (ultimaEvidencia < ant.ultimaEvidencia ||
                (quantidadeEvidencias > 0 && ultimaEvidencia == ant.ultimaEvidencia)) {
                revert EvidenciaRetrocedeu(ant.ultimaEvidencia, ultimaEvidencia);
            }
        }

        indice = _checkpoints.length;
        _checkpoints.push(Checkpoint({
            hashTrilha: hashTrilha,
            raizEvidencias: raizEvidencias,
            ultimoRegistro: ultimoRegistro,
            totalRegistros: totalRegistros,
            ultimaEvidencia: ultimaEvidencia,
            quantidadeEvidencias: quantidadeEvidencias,
            ancoradoEm: uint40(block.timestamp),
            ancorador: msg.sender,
            contestado: false
        }));
        _ultimoValido = indice + 1;

        emit CheckpointAncorado(indice, ultimoRegistro, totalRegistros, hashTrilha,
                                raizEvidencias, quantidadeEvidencias, msg.sender);
    }

    /**
     * @notice O orgao gestor marca uma ancoragem como contestada (por exemplo,
     *         feita com a chave de um servidor comprometido). O checkpoint
     *         continua visivel para sempre, mas deixa de provar qualquer coisa
     *         e deixa de servir de referencia para os proximos.
     */
    function contestar(uint256 indice, string calldata motivo) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (indice >= _checkpoints.length) revert IndiceInexistente(indice);
        Checkpoint storage c = _checkpoints[indice];
        if (c.contestado) revert JaContestado(indice);
        c.contestado = true;

        if (_ultimoValido == indice + 1) {
            uint256 i = indice;
            while (i > 0 && _checkpoints[i - 1].contestado) {
                unchecked { --i; }
            }
            _ultimoValido = i; // indice + 1 do anterior valido, ou 0
        }
        emit CheckpointContestado(indice, msg.sender, motivo);
    }

    // ------------------------------------------------------------------
    // Leitura (gratuita: nao gera transacao)
    // ------------------------------------------------------------------

    function totalCheckpoints() external view returns (uint256) {
        return _checkpoints.length;
    }

    function checkpoint(uint256 indice) public view returns (Checkpoint memory) {
        if (indice >= _checkpoints.length) revert IndiceInexistente(indice);
        return _checkpoints[indice];
    }

    /// @notice O checkpoint valido mais recente e o indice dele.
    function ultimoValido() external view returns (uint256 indice, Checkpoint memory c) {
        if (_ultimoValido == 0) revert NenhumCheckpoint();
        indice = _ultimoValido - 1;
        c = _checkpoints[indice];
    }

    /**
     * @notice O registro `ultimoRegistro` da trilha de hoje ainda tem o hash ancorado?
     * @dev    Falso se o checkpoint foi contestado ou se o registro nao confere.
     */
    function conferirTrilha(uint256 indice, uint64 ultimoRegistro, bytes32 hashTrilha)
        external view returns (bool)
    {
        Checkpoint memory c = checkpoint(indice);
        return !c.contestado && c.ultimoRegistro == ultimoRegistro && c.hashTrilha == hashTrilha;
    }

    /**
     * @notice Prova que uma evidencia (o compromisso dela) estava no lote do checkpoint.
     * @dev    Folha no padrao da biblioteca @openzeppelin/merkle-tree (hash duplo,
     *         que impede passar um no interno da arvore por folha).
     */
    function provarEvidencia(uint256 indice, bytes32 compromisso, bytes32[] calldata prova)
        external view returns (bool)
    {
        Checkpoint memory c = checkpoint(indice);
        if (c.contestado || c.raizEvidencias == bytes32(0)) return false;
        bytes32 folha = keccak256(bytes.concat(keccak256(abi.encode(compromisso))));
        return MerkleProof.verifyCalldata(prova, c.raizEvidencias, folha);
    }
}
