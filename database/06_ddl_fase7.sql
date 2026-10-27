-- =====================================================================
--  Protege+ | Fase 7 | Ajustes de modelo fisico (Oracle 19c)
--  Executar depois de 01_ddl_oracle.sql e 04_ddl_fase6.sql.
--
--  1. Protocolo: a Fase 7 troca o formato #AAAA-NNNNN (99.999 valores por
--     ano, adivinhavel por tentativa) por #AAAA-XXXX-XXXX-XXXX, com 12
--     simbolos sorteados por SecureRandom num alfabeto de 31 caracteres
--     sem ambiguos (cerca de 59 bits). A restricao aceita os dois formatos
--     para preservar os protocolos ja emitidos. Os 20 caracteres cabem na
--     coluna existente, sem migracao de dados. O 'c' torna a comparacao
--     sensivel a maiusculas independentemente do NLS da sessao.
--  2. Trilha de auditoria: duas acoes novas, BACKUP e TROCA_PERFIL_DEMO.
-- =====================================================================

ALTER TABLE DENUNCIA DROP CONSTRAINT ck_denuncia_protocolo;
ALTER TABLE DENUNCIA ADD CONSTRAINT ck_denuncia_protocolo CHECK (
    REGEXP_LIKE(protocolo,
      '^#[0-9]{4}-([0-9]{5}|[2-9A-HJKMNP-Z]{4}(-[2-9A-HJKMNP-Z]{4}){2})$', 'c'));

COMMENT ON COLUMN DENUNCIA.protocolo IS
  '#AAAA-NNNNN (carga ate a Fase 6) ou #AAAA-XXXX-XXXX-XXXX (Fase 7, SecureRandom, cerca de 59 bits)';

ALTER TABLE AUDITORIA_LOG DROP CONSTRAINT ck_auditoria_acao;
ALTER TABLE AUDITORIA_LOG ADD CONSTRAINT ck_auditoria_acao CHECK (acao IN (
  'LOGIN','LOGIN_NEGADO','CONSULTA_SENSIVEL','ALTERACAO_STATUS','ALTERACAO_DADOS',
  'ATRIBUICAO','EXCLUSAO','EXPORTACAO','REANALISE_IA','ALTERACAO_EQUIPE',
  'ACESSO_AUDITORIA','BACKUP','TROCA_PERFIL_DEMO'));

-- Conferencia rapida
SELECT constraint_name, search_condition_vc
  FROM user_constraints
 WHERE constraint_name IN ('CK_DENUNCIA_PROTOCOLO', 'CK_AUDITORIA_ACAO');
