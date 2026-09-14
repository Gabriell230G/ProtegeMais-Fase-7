-- =============================================================================
--  PROTEGE+ | Script 05 . CONSULTAS DA FASE 6 (Parte 4)
--
--  HackGov / FIAP . Fase 6 | Gabriel Vasconcellos Gomes . RM 561601
--
--  Executar DEPOIS de 04_ddl_fase6.sql e da carga de demonstracao.
--
--  Todas as consultas rodam tanto no H2 embutido (perfil padrao da
--  aplicacao, console em http://localhost:8080/h2-console) quanto no
--  Oracle do modelo fisico. Onde os dois divergem, a diferenca esta
--  anotada no comentario da propria consulta.
--
--  O criterio de escolha destas seis consultas nao foi cobrir a lista de
--  recursos de SQL: foi responder a seis perguntas que a operacao faz e
--  que ninguem consegue responder olhando a tela. Os recursos exigidos
--  pela comanda (agrupamento, subconsulta, ROLLUP e funcoes de janela)
--  aparecem porque a pergunta pedia, e nao o contrario.
-- =============================================================================


-- =============================================================================
--  1. O BARRAMENTO EM UMA TABELA SO
--     Recursos: GROUP BY com ROLLUP (subtotais e total geral)
--
--  Pergunta: quanto cada origem de dispositivo produz, e o que o servidor
--  decidiu em cada caso?
--
--  O ROLLUP entrega, na mesma consulta, as tres granularidades que a
--  gestao pede em momentos diferentes: o detalhe por situacao, o subtotal
--  por origem e o total do parque. Sem ele seriam tres consultas, e tres
--  consultas separadas correm o risco classico de nao fecharem entre si
--  quando executadas em instantes diferentes.
--
--  Linhas de subtotal tem SITUACAO nula; a de total geral tem as duas
--  colunas nulas. GROUPING() distingue o nulo do subtotal do nulo que
--  porventura existisse no dado, que e uma armadilha comum de ROLLUP.
-- =============================================================================
SELECT
    CASE WHEN GROUPING(origem)   = 1 THEN '>> TOTAL GERAL' ELSE origem   END AS origem,
    CASE WHEN GROUPING(situacao) = 1 THEN '.. subtotal'    ELSE situacao END AS situacao,
    COUNT(*)                                          AS eventos,
    COUNT(protocolo_gerado)                           AS casos_abertos,
    ROUND(AVG(bateria), 1)                            AS bateria_media
FROM evento_iot
GROUP BY ROLLUP (origem, situacao)
ORDER BY GROUPING(origem), origem, GROUPING(situacao), situacao;


-- =============================================================================
--  2. QUAIS APARELHOS CONCENTRAM O VOLUME
--     Recursos: funcoes de janela (RANK, SUM OVER) e CTE
--
--  Pergunta: o volume esta distribuido pelo parque ou preso em poucos
--  aparelhos?
--
--  A resposta muda a acao. Volume espalhado e demanda real e pede equipe.
--  Volume concentrado em dois ou tres aparelhos costuma ser outra coisa:
--  defeito de hardware, bolso apertando o botao, ou uma pessoa em
--  situacao muito pior que a media. As duas leituras exigem operacoes
--  opostas, e por isso a pergunta precisa ser respondida antes de agir.
--
--  O percentual acumulado e o que responde de fato: se poucas linhas ja
--  passam de 50%, a concentracao existe.
-- =============================================================================
WITH por_aparelho AS (
    SELECT origem, dispositivo, COUNT(*) AS eventos
    FROM evento_iot
    WHERE situacao = 'ACEITO'
    GROUP BY origem, dispositivo
)
SELECT
    origem,
    dispositivo,
    eventos,
    RANK() OVER (PARTITION BY origem ORDER BY eventos DESC)          AS posicao,
    ROUND(100.0 * eventos
          / SUM(eventos) OVER (PARTITION BY origem), 1)              AS pct_da_origem,
    ROUND(100.0 * SUM(eventos) OVER (PARTITION BY origem
                                     ORDER BY eventos DESC
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(eventos) OVER (PARTITION BY origem), 1)              AS pct_acumulado
FROM por_aparelho
ORDER BY origem, eventos DESC;


-- =============================================================================
--  3. A JANELA DE REPIQUE DE 120 SEGUNDOS ESTA BEM CALIBRADA?
--     Recursos: funcao de janela LAG (valor da linha anterior)
--
--  Esta e a consulta mais importante do conjunto, porque ela audita uma
--  DECISAO DE PROJETO com o dado real em vez de com a intuicao de quem
--  escreveu o codigo.
--
--  O servico trata como repique qualquer acionamento do mesmo aparelho
--  dentro de 120 s. O numero foi escolhido por raciocinio: um botao
--  apertado tres vezes em dez segundos e uma pessoa com medo, nao tres
--  ocorrencias. Mas se existirem muitos intervalos logo ACIMA de 120 s,
--  a janela esta curta e casos duplicados estao passando; se nenhum
--  intervalo chegar perto de 120 s, ela esta larga e poderia engolir um
--  acionamento legitimo.
--
--  LAG traz o instante do evento anterior DO MESMO APARELHO, que e
--  exatamente a informacao que a regra usa em tempo de execucao. A
--  consulta e, portanto, a mesma pergunta do codigo feita ao banco.
-- =============================================================================
SELECT
    faixa,
    COUNT(*) AS ocorrencias
FROM (
    SELECT CASE
             WHEN seg <   20 THEN 'a) ate 20 s      . toque duplo'
             WHEN seg <  120 THEN 'b) 20 a 120 s    . dentro da janela'
             WHEN seg <  300 THEN 'c) 120 a 300 s   . logo acima da janela'
             ELSE                 'd) acima de 300 s . evento independente'
           END AS faixa
    FROM (
        SELECT
            (CAST(recebido_em AS DATE) - CAST(anterior AS DATE)) * 86400 AS seg
        FROM (
            SELECT
                dispositivo,
                recebido_em,
                LAG(recebido_em) OVER (PARTITION BY dispositivo
                                       ORDER BY recebido_em) AS anterior
            FROM evento_iot
            WHERE origem = 'SOS'
        ) x
        WHERE anterior IS NOT NULL
    ) y
) z
GROUP BY faixa
ORDER BY faixa;
--
--  NOTA DE PORTABILIDADE: a subtracao de datas acima e a forma do Oracle,
--  onde a diferenca sai em dias e o fator 86400 converte para segundos.
--  No H2, troque a expressao por:
--      DATEDIFF('SECOND', anterior, recebido_em) AS seg


-- =============================================================================
--  4. TOTENS ACIMA DA MEDIA
--     Recursos: SUBCONSULTA no HAVING, correlacionada com a consulta externa
--
--  Pergunta: quais pontos de instalacao recebem mais registros do que a
--  media dos pontos ativos?
--
--  A media nao e um numero digitado: ela e recalculada pela subconsulta a
--  cada execucao. Um limite fixo ("mais de 8 registros") envelheceria em
--  silencio conforme o parque crescesse, e continuaria devolvendo uma
--  resposta que parece certa. Este e o motivo de a subconsulta estar aqui,
--  e nao para cumprir um requisito.
--
--  O resultado orienta onde vale instalar o proximo totem, e tambem onde
--  a demanda ja justifica atendimento humano ao lado do equipamento.
-- =============================================================================
SELECT
    p.dispositivo,
    p.local_instalacao,
    p.cidade,
    COUNT(*)                                           AS registros,
    SUM(CASE WHEN e.situacao = 'ACEITO' THEN 1 ELSE 0 END) AS aceitos
FROM ponto_totem p
JOIN evento_iot  e ON e.dispositivo = p.dispositivo
WHERE p.ativo = TRUE
GROUP BY p.dispositivo, p.local_instalacao, p.cidade
HAVING COUNT(*) > (
    -- Media de registros por totem ativo, calculada no proprio banco.
    SELECT AVG(qtd)
    FROM (
        SELECT COUNT(*) AS qtd
        FROM evento_iot e2
        JOIN ponto_totem p2 ON p2.dispositivo = e2.dispositivo
        WHERE p2.ativo = TRUE
        GROUP BY e2.dispositivo
    ) media_por_totem
)
ORDER BY registros DESC;
--
--  NOTA DE PORTABILIDADE: no Oracle, 'ativo' e NUMBER(1); troque
--  "p.ativo = TRUE" por "p.ativo = 1" nas duas ocorrencias.


-- =============================================================================
--  5. O APARELHO NAO DECIDE A URGENCIA. O DADO CONFIRMA?
--     Recursos: agrupamento com JOIN entre o barramento e as denuncias
--
--  Esta consulta serve de PROVA de uma afirmacao feita no projeto: o
--  dispositivo relata, e quem classifica a urgencia e o VigIA lendo o
--  texto. Se a afirmacao fosse falsa, cada origem teria uma urgencia
--  unica e fixa, porque a origem e que estaria decidindo.
--
--  Uma afirmacao de arquitetura que pode ser conferida no banco vale mais
--  do que a mesma afirmacao escrita no documento.
-- =============================================================================
SELECT
    e.origem,
    d.urgencia_ia,
    COUNT(*)                                     AS casos,
    ROUND(AVG(d.score), 1)                       AS score_medio,
    MIN(d.protocolo)                             AS exemplo
FROM evento_iot e
JOIN denuncia   d ON d.protocolo = e.protocolo_gerado
WHERE e.situacao = 'ACEITO'
  AND e.protocolo_gerado IS NOT NULL
GROUP BY e.origem, d.urgencia_ia
ORDER BY e.origem, casos DESC;


-- =============================================================================
--  6. APROVEITAMENTO POR ORIGEM
--     Recursos: agrupamento com metricas derivadas e divisao protegida
--
--  Pergunta: de tudo que cada origem envia, quanto vira caso?
--
--  A leitura util NAO e "quanto maior, melhor". Cada origem tem um
--  aproveitamento esperado diferente, e fugir dele e que e sinal:
--
--    SOS      . deve ser alto. Ninguem aperta um botao de panico por
--               engano com frequencia; aproveitamento baixo aqui sugere
--               defeito de hardware ou acionamento no bolso.
--    GEOFENCE . deve ser BAIXO. A tornozeleira envia posicao o tempo
--               todo, e o normal e estar fora do perimetro. Um
--               aproveitamento alto aqui seria a noticia ruim.
--    TOTEM    . intermediario. O que reprova sao relatos curtos demais e
--               equipamento desativado, e as duas causas sao tratavais.
--
--  NULLIF evita divisao por zero numa origem ainda sem eventos, o que
--  aconteceria no primeiro dia de operacao de um equipamento novo.
-- =============================================================================
SELECT
    origem,
    COUNT(*)                                                       AS total,
    SUM(CASE WHEN protocolo_gerado IS NOT NULL THEN 1 ELSE 0 END)  AS geraram_caso,
    SUM(CASE WHEN situacao = 'DUPLICADO'  THEN 1 ELSE 0 END)       AS duplicados,
    SUM(CASE WHEN situacao = 'DESCARTADO' THEN 1 ELSE 0 END)       AS descartados,
    ROUND(100.0 * SUM(CASE WHEN protocolo_gerado IS NOT NULL THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                                AS aproveitamento_pct
FROM evento_iot
GROUP BY origem
ORDER BY total DESC;


-- =============================================================================
--  FIM DO SCRIPT 05
--
--  Resumo dos recursos exigidos pela comanda e onde cada um aparece:
--    Agrupamentos e metricas ....... consultas 1, 2, 4, 5 e 6
--    Subconsulta ................... consulta 4 (no HAVING) e consulta 3
--    Funcao avancada / janela ...... consulta 2 (RANK, SUM OVER) e 3 (LAG)
--    ROLLUP com GROUPING ........... consulta 1
-- =============================================================================
