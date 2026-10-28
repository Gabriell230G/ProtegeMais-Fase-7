-- =============================================================================
--  PROTEGE+ | Script 07 . CORRELACAO E REGRESSAO NO BANCO (Fase 7, Parte 3)
--
--  HackGov / FIAP . Fase 7 | Gabriel Vasconcellos Gomes . RM 561601
--
--  Executar depois de 01, 02, 04 e 06 (Oracle 19c).
--
--  A API calcula a mesma analise em Java (GET /api/stats/regressao), com
--  p-valor exato e regressao multipla. Este script mostra que as respostas
--  principais saem tambem direto do banco, com as funcoes estatisticas
--  nativas do Oracle: CORR (Pearson), CORR_S (Spearman, com p-valor),
--  REGR_SLOPE, REGR_INTERCEPT, REGR_R2, REGR_COUNT e as somas REGR_SXX,
--  REGR_SYY e REGR_SXY. Os resultados conferidos na base de demonstracao
--  estao em 07_resultados_fase7.txt.
--
--  Tempo de atendimento = dias entre criado_em e concluida_em. A subtracao
--  de dois DATE no Oracle devolve dias com fracao, por isso o CAST.
--  Gravidade = TIPO_DENUNCIA.peso_gravidade, o mesmo peso da fila do VigIA.
-- =============================================================================


-- =============================================================================
--  BASE COMUM: uma linha por caso concluido, com as variaveis numericas
-- =============================================================================
CREATE OR REPLACE VIEW VW_ANALISE_TEMPO AS
SELECT d.id,
       CAST(d.concluida_em AS DATE) - CAST(d.criado_em AS DATE)        AS tempo_dias,
       t.peso_gravidade                                                  AS gravidade,
       CASE d.urgencia_ia WHEN 'CRITICA' THEN 4 WHEN 'ALTA' THEN 3
                          WHEN 'MEDIA'   THEN 2 WHEN 'BAIXA' THEN 1 END  AS urgencia,
       d.score,
       d.anonimo,
       NVL(LENGTH(d.descricao), 0)                                       AS tamanho_relato
  FROM DENUNCIA d
  JOIN TIPO_DENUNCIA t ON t.tipo = d.tipo
 WHERE d.excluida = 0
   AND d.concluida_em IS NOT NULL
   AND d.concluida_em >= d.criado_em
   AND d.urgencia_ia IS NOT NULL;


-- =============================================================================
--  1. O QUE EXPLICA O TEMPO DE ATENDIMENTO?
--     Recursos: CORR, CORR_S com TWO_SIDED_SIG, UNION ALL
--
--  Pearson mede relacao linear; Spearman mede relacao monotona e o Oracle
--  ja devolve o p-valor bilateral dele. A estatistica t de Pearson
--  (t = r * raiz((n-2)/(1-r^2))) vai junto: com mais de 100 casos, |t| acima
--  de 1,98 corresponde a p < 0,05.
-- =============================================================================
WITH c AS (
    SELECT 'Gravidade do tipo'       AS fator, CORR(gravidade, tempo_dias)      AS pearson,
           CORR_S(gravidade, tempo_dias)      AS spearman,
           CORR_S(gravidade, tempo_dias, 'TWO_SIDED_SIG')      AS p_spearman, COUNT(*) AS n FROM VW_ANALISE_TEMPO
    UNION ALL
    SELECT 'Urgencia da triagem',     CORR(urgencia, tempo_dias),
           CORR_S(urgencia, tempo_dias),
           CORR_S(urgencia, tempo_dias, 'TWO_SIDED_SIG'), COUNT(*) FROM VW_ANALISE_TEMPO
    UNION ALL
    SELECT 'Score de confiabilidade', CORR(score, tempo_dias),
           CORR_S(score, tempo_dias),
           CORR_S(score, tempo_dias, 'TWO_SIDED_SIG'), COUNT(*) FROM VW_ANALISE_TEMPO
    UNION ALL
    SELECT 'Denuncia anonima',        CORR(anonimo, tempo_dias),
           CORR_S(anonimo, tempo_dias),
           CORR_S(anonimo, tempo_dias, 'TWO_SIDED_SIG'), COUNT(*) FROM VW_ANALISE_TEMPO
    UNION ALL
    SELECT 'Tamanho do relato',       CORR(tamanho_relato, tempo_dias),
           CORR_S(tamanho_relato, tempo_dias),
           CORR_S(tamanho_relato, tempo_dias, 'TWO_SIDED_SIG'), COUNT(*) FROM VW_ANALISE_TEMPO
)
SELECT fator,
       n,
       ROUND(pearson, 3)                                         AS r_pearson,
       ROUND(pearson * SQRT((n - 2) / (1 - pearson * pearson)), 2) AS t_pearson,
       ROUND(spearman, 3)                                        AS rho_spearman,
       ROUND(p_spearman, 4)                                      AS p_spearman,
       CASE WHEN ABS(pearson * SQRT((n - 2) / (1 - pearson * pearson))) > 1.98
            THEN 'SIGNIFICATIVO' ELSE 'sem evidencia' END        AS leitura
  FROM c
 ORDER BY ABS(pearson) DESC;


-- =============================================================================
--  2. REGRESSAO SIMPLES: TEMPO = a + b x GRAVIDADE
--     Recursos: REGR_SLOPE, REGR_INTERCEPT, REGR_R2, REGR_COUNT, REGR_SXX,
--               REGR_SYY, REGR_SXY
--
--  O erro-padrao da inclinacao sai das somas que o proprio Oracle expoe:
--  ep(b) = raiz( (SYY - b*SXY) / (n-2) / SXX ). Com ele, o intervalo de 95%
--  da inclinacao (t critico 1,98 para n perto de 120).
-- =============================================================================
SELECT ROUND(REGR_INTERCEPT(tempo_dias, gravidade), 3)                       AS intercepto_a,
       ROUND(REGR_SLOPE(tempo_dias, gravidade), 3)                           AS inclinacao_b,
       ROUND(REGR_R2(tempo_dias, gravidade), 3)                              AS r2,
       REGR_COUNT(tempo_dias, gravidade)                                     AS n,
       ROUND(SQRT((REGR_SYY(tempo_dias, gravidade)
                   - REGR_SLOPE(tempo_dias, gravidade) * REGR_SXY(tempo_dias, gravidade))
                  / (REGR_COUNT(tempo_dias, gravidade) - 2)
                  / REGR_SXX(tempo_dias, gravidade)), 4)                     AS erro_padrao_b,
       ROUND(REGR_SLOPE(tempo_dias, gravidade)
             - 1.98 * SQRT((REGR_SYY(tempo_dias, gravidade)
                   - REGR_SLOPE(tempo_dias, gravidade) * REGR_SXY(tempo_dias, gravidade))
                  / (REGR_COUNT(tempo_dias, gravidade) - 2)
                  / REGR_SXX(tempo_dias, gravidade)), 3)                     AS ic95_b_inferior,
       ROUND(REGR_SLOPE(tempo_dias, gravidade)
             + 1.98 * SQRT((REGR_SYY(tempo_dias, gravidade)
                   - REGR_SLOPE(tempo_dias, gravidade) * REGR_SXY(tempo_dias, gravidade))
                  / (REGR_COUNT(tempo_dias, gravidade) - 2)
                  / REGR_SXX(tempo_dias, gravidade)), 3)                     AS ic95_b_superior
  FROM VW_ANALISE_TEMPO;


-- =============================================================================
--  3. DA RETA PARA O SLA: PRAZO ESPERADO POR TIPO
--     Recursos: funcao analitica REGR_* OVER (), GROUP BY, subconsulta
--
--  Aplica a reta da consulta 2 a cada tipo e compara com o observado. A
--  coluna folga_p90 diz quantos dias de margem dar ao SLA de cada tipo
--  para que 90% dos casos o cumpram, que e a decisao pratica da analise.
-- =============================================================================
SELECT t.tipo,
       t.peso_gravidade                                                AS gravidade,
       COUNT(*)                                                        AS casos,
       ROUND(MAX(r.a) + MAX(r.b) * t.peso_gravidade, 2)                AS tempo_previsto_reta,
       ROUND(AVG(v.tempo_dias), 2)                                     AS tempo_medio_observado,
       ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY v.tempo_dias), 2) AS p90_observado,
       CEIL(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY v.tempo_dias)) AS sla_sugerido_dias
  FROM VW_ANALISE_TEMPO v
  JOIN DENUNCIA d       ON d.id = v.id
  JOIN TIPO_DENUNCIA t  ON t.tipo = d.tipo
 CROSS JOIN (SELECT REGR_INTERCEPT(tempo_dias, gravidade) AS a,
                    REGR_SLOPE(tempo_dias, gravidade)     AS b
               FROM VW_ANALISE_TEMPO) r
 GROUP BY t.tipo, t.peso_gravidade
 ORDER BY t.peso_gravidade DESC, t.tipo;


-- =============================================================================
--  4. DEMANDA: O VOLUME SEMANAL ESTA SUBINDO?
--     Recursos: TRUNC(..., 'IW') (semana ISO), ROW_NUMBER, REGR_* sobre
--               agregado, CONNECT BY LEVEL para gerar as semanas futuras
--
--  Regressao do numero de denuncias por semana contra o indice da semana.
--  Inclinacao positiva e significativa (|t| > 2,1 com 17 semanas) indica
--  demanda crescente. Sem significancia, a projecao honesta e a media.
--  Semanas sem nenhum registro entram com zero (calendario gerado).
-- =============================================================================
WITH limites AS (
    SELECT TRUNC(MIN(criado_em), 'IW') AS ini, TRUNC(MAX(criado_em), 'IW') AS fim
      FROM DENUNCIA
     WHERE excluida = 0
       AND criado_em < TIMESTAMP '2026-07-01 00:00:00'   -- periodo continuo da carga
),
calendario AS (
    SELECT ini + 7 * (LEVEL - 1) AS semana, LEVEL - 1 AS idx
      FROM limites
    CONNECT BY ini + 7 * (LEVEL - 1) <= fim
),
volume AS (
    SELECT c.semana, c.idx, COUNT(d.id) AS denuncias
      FROM calendario c
      LEFT JOIN DENUNCIA d
        ON TRUNC(d.criado_em, 'IW') = c.semana AND d.excluida = 0
     GROUP BY c.semana, c.idx
),
modelo AS (
    SELECT REGR_SLOPE(denuncias, idx)     AS b,
           REGR_INTERCEPT(denuncias, idx) AS a,
           REGR_R2(denuncias, idx)        AS r2,
           REGR_COUNT(denuncias, idx)     AS n,
           AVG(denuncias)                 AS media,
           SQRT((REGR_SYY(denuncias, idx) - REGR_SLOPE(denuncias, idx) * REGR_SXY(denuncias, idx))
                / (REGR_COUNT(denuncias, idx) - 2) / REGR_SXX(denuncias, idx)) AS ep_b
      FROM volume
)
SELECT ROUND(b, 3)          AS inclinacao_por_semana,
       ROUND(b / ep_b, 2)   AS t_inclinacao,
       CASE WHEN ABS(b / ep_b) > 2.13 THEN 'tendencia significativa'
            ELSE 'sem tendencia: projetar pela media' END AS leitura,
       ROUND(r2, 3)         AS r2,
       n                    AS semanas,
       ROUND(media, 2)      AS media_semanal,
       ROUND(CASE WHEN ABS(b / ep_b) > 2.13 THEN a + b * (n + 1.5) ELSE media END, 1)
                            AS projecao_proximas_4_semanas_por_semana
  FROM modelo;


-- =============================================================================
--  5. QUANTAS PESSOAS A EQUIPE PRECISA?
--     Recursos: subconsultas escalares, CEIL
--
--  Capacidade = casos concluidos por semana no periodo / pessoas na equipe.
--  Equipe necessaria = demanda semanal / capacidade por pessoa. Se a demanda
--  supera o que a equipe conclui, a fila cresce toda semana.
-- =============================================================================
WITH periodo AS (
    SELECT TRUNC(MIN(criado_em), 'IW') AS ini, TRUNC(MAX(criado_em), 'IW') + 7 AS fim
      FROM DENUNCIA
     WHERE excluida = 0 AND criado_em < TIMESTAMP '2026-07-01 00:00:00'
),
numeros AS (
    SELECT (SELECT COUNT(*) FROM DENUNCIA d, periodo p
             WHERE d.excluida = 0 AND d.criado_em >= p.ini AND d.criado_em < p.fim)   AS registradas,
           (SELECT COUNT(*) FROM DENUNCIA d, periodo p
             WHERE d.excluida = 0 AND d.concluida_em >= p.ini AND d.concluida_em < p.fim) AS concluidas,
           (SELECT (CAST(p.fim AS DATE) - CAST(p.ini AS DATE)) / 7 FROM periodo p)   AS semanas,
           (SELECT COUNT(*) FROM MEMBRO_EQUIPE)                                       AS equipe
      FROM dual
)
SELECT semanas,
       equipe,
       ROUND(registradas / semanas, 2)                         AS demanda_semanal,
       ROUND(concluidas / semanas, 2)                          AS concluidas_por_semana,
       ROUND(concluidas / semanas / equipe, 2)                 AS capacidade_por_pessoa,
       CEIL((registradas / semanas) / (concluidas / semanas / equipe)) AS equipe_necessaria,
       ROUND((registradas - concluidas) / semanas, 2)          AS fila_cresce_por_semana
  FROM numeros;


-- =============================================================================
--  6. MATRIZ DE CORRELACAO ENTRE OS FATORES
--     Recursos: CORR em pares, UNPIVOT
--
--  Gravidade e urgencia andam juntas porque a urgencia das regras parte do
--  tipo. Quando dois fatores se correlacionam forte, a regressao multipla
--  divide o efeito entre eles, e por isso a API mostra os coeficientes
--  padronizados (beta) ao lado dos brutos.
-- =============================================================================
SELECT *
  FROM (SELECT ROUND(CORR(gravidade, urgencia), 3)       AS gravidade_x_urgencia,
               ROUND(CORR(gravidade, score), 3)          AS gravidade_x_score,
               ROUND(CORR(urgencia, score), 3)           AS urgencia_x_score,
               ROUND(CORR(anonimo, score), 3)            AS anonimo_x_score,
               ROUND(CORR(tamanho_relato, score), 3)     AS relato_x_score,
               ROUND(CORR(gravidade, tempo_dias), 3)     AS gravidade_x_tempo
          FROM VW_ANALISE_TEMPO)
UNPIVOT (correlacao FOR par IN (gravidade_x_urgencia, gravidade_x_score, urgencia_x_score,
                                anonimo_x_score, relato_x_score, gravidade_x_tempo))
ORDER BY ABS(correlacao) DESC;
