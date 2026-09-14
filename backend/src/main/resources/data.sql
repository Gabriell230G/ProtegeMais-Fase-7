-- =====================================================================
--  Dados de exemplo (idempotente - so insere se ainda nao existir).
--  Deixa o painel do gestor / Kanban populado para a demonstracao.
--
--  A coluna concluida_em e preenchida nos casos ja encerrados porque e
--  dela que sai o lead time analisado estatisticamente na Parte 4.
-- =====================================================================

INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-00451', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Rua Paulista, 100 - Jardim Paulista', 'Relato de violencia domestica no bairro Jardim Paulista, com ameacas frequentes.', 'recebida', TRUE, 65, 'medium', 'Media', 'ALTA', 'Violencia domestica recorrente. Priorizar contato com a rede de protecao.', 'REGRAS', TIMESTAMP '2026-04-20 14:32:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-00451');

INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-00452', 'assedio', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Av. Rio Branco, 500', 'Assedio no ambiente de trabalho relatado pelo denunciante identificado.', 'analise', FALSE, 80, 'high', 'Alta', 'MEDIA', 'Assedio laboral com denunciante identificado. Boa verificabilidade.', 'REGRAS', TIMESTAMP '2026-04-21 09:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-00452');

INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-00453', 'abuso', 'Salvador, BA', 'BA', 'Salvador', 'Rua da Bahia, 200', 'Abuso reportado na comunidade local envolvendo pessoa vulneravel.', 'encaminhada', TRUE, 45, 'medium', 'Media', 'ALTA', 'Abuso contra vulneravel. Encaminhar ao orgao de protecao competente.', 'REGRAS', TIMESTAMP '2026-04-22 08:05:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-00453');

INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-00454', 'discriminacao', 'Recife, PE', 'PE', 'Recife', 'Av. Boa Viagem, 1200', 'Discriminacao racial em estabelecimento comercial, com testemunhas.', 'concluida', FALSE, 90, 'high', 'Alta', 'MEDIA', 'Discriminacao com testemunhas. Caso concluido com encaminhamento.', 'REGRAS', TIMESTAMP '2026-04-22 10:00:00', TIMESTAMP '2026-04-27 16:20:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-00454');

INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-00455', 'violencia', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Rua Goias, 800', 'Denuncia de violencia fisica em via publica agora, pedido de socorro.', 'recebida', TRUE, 30, 'low', 'Baixa', 'CRITICA', 'Violencia em curso com termos de risco. Acionar resposta imediata.', 'REGRAS', TIMESTAMP '2026-04-23 17:55:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-00455');

-- Historico (linha do tempo) das denuncias acima
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '20/04/2026', '14:32' FROM denuncia d
WHERE d.protocolo = '#2026-00451' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id);

INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '21/04/2026', '09:10' FROM denuncia d
WHERE d.protocolo = '#2026-00452' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'analise', '22/04/2026', '11:45' FROM denuncia d
WHERE d.protocolo = '#2026-00452' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);

INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '22/04/2026', '08:05' FROM denuncia d
WHERE d.protocolo = '#2026-00453' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id);

INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '22/04/2026', '10:00' FROM denuncia d
WHERE d.protocolo = '#2026-00454' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '27/04/2026', '16:20' FROM denuncia d
WHERE d.protocolo = '#2026-00454' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);

-- Equipe do gestor
INSERT INTO membro_equipe (nome, cargo, email)
SELECT 'Ana Souza', 'Analista de denuncias', 'ana.souza@protege.gov.br'
WHERE NOT EXISTS (SELECT 1 FROM membro_equipe WHERE email = 'ana.souza@protege.gov.br');
INSERT INTO membro_equipe (nome, cargo, email)
SELECT 'Carlos Lima', 'Coordenador', 'carlos.lima@protege.gov.br'
WHERE NOT EXISTS (SELECT 1 FROM membro_equipe WHERE email = 'carlos.lima@protege.gov.br');
INSERT INTO membro_equipe (nome, cargo, email)
SELECT 'Marina Alves', 'Assistente social', 'marina.alves@protege.gov.br'
WHERE NOT EXISTS (SELECT 1 FROM membro_equipe WHERE email = 'marina.alves@protege.gov.br');

-- =====================================================================
--  MASSA ANALITICA - 120 denuncias entre 02/03/2026 e 04/07/2026.
--
--  Sao exatamente as mesmas linhas de database/02_dml_carga.sql, apenas
--  reescritas na sintaxe do H2. Nao ha duas massas: o painel, o script
--  Oracle e o relatorio da Parte 4 falam dos mesmos 125 registros, e
--  quem rodar 03_consultas.sql pode conferir numero a numero contra a
--  tela. A geracao e deterministica (semente 561601, o RM do autor).
--
--  Estas linhas nao tem endereco nem relato: sao insumo estatistico. As
--  cinco de demonstracao acima carregam o conteudo sensivel que o
--  mascaramento por perfil precisa ter o que esconder.
-- =====================================================================

INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10001', 'violencia', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de violencia em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'recebida', FALSE, 81, 'high', 'Alta', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-05-27 19:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10001');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10002', 'discriminacao', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de discriminacao em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 63, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-04-09 01:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10002');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10003', 'abuso', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de abuso em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 81, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-03-15 15:30:00', TIMESTAMP '2026-03-17 22:15:32', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10003');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10004', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'encaminhada', TRUE, 65, 'medium', 'Media', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-05-19 19:20:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10004');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10005', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 44, 'medium', 'Media', 'CRITICA', 'REGRAS', 1, TIMESTAMP '2026-03-14 11:10:00', TIMESTAMP '2026-03-14 18:22:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10005');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10006', 'abuso', 'Recife, PE', 'PE', 'Recife', 'Registro de abuso em Recife. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 52, 'medium', 'Media', 'CRITICA', 'REGRAS', NULL, TIMESTAMP '2026-05-24 00:40:00', TIMESTAMP '2026-05-26 08:12:52', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10006');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10007', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 53, 'medium', 'Media', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-06-26 07:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10007');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10008', 'outros', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de outros em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'recebida', FALSE, 72, 'high', 'Alta', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-06-27 20:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10008');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10009', 'outros', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de outros em Curitiba. Massa de teste deterministica para analise estatistica.', 'analise', TRUE, 44, 'medium', 'Media', 'BAIXA', 'REGRAS', 2, TIMESTAMP '2026-03-17 08:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10009');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10010', 'outros', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de outros em Fortaleza. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 50, 'medium', 'Media', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-05-31 06:40:00', TIMESTAMP '2026-06-14 10:58:53', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10010');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10011', 'discriminacao', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de discriminacao em Fortaleza. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 67, 'medium', 'Media', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-04-11 09:00:00', TIMESTAMP '2026-04-18 18:11:50', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10011');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10012', 'outros', 'Recife, PE', 'PE', 'Recife', 'Registro de outros em Recife. Massa de teste deterministica para analise estatistica.', 'analise', TRUE, 76, 'high', 'Alta', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-04-10 08:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10012');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10013', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 83, 'high', 'Alta', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-06-01 01:00:00', TIMESTAMP '2026-06-03 06:11:56', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10013');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10014', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 50, 'medium', 'Media', 'BAIXA', 'REGRAS', NULL, TIMESTAMP '2026-06-09 08:20:00', TIMESTAMP '2026-06-18 12:41:37', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10014');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10015', 'abuso', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de abuso em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 94, 'high', 'Alta', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-06-26 19:20:00', TIMESTAMP '2026-07-04 03:46:02', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10015');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10016', 'violencia', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de violencia em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 49, 'medium', 'Media', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-03-11 04:20:00', TIMESTAMP '2026-03-15 12:09:30', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10016');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10017', 'violencia', 'Recife, PE', 'PE', 'Recife', 'Registro de violencia em Recife. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 91, 'high', 'Alta', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-05-25 17:50:00', TIMESTAMP '2026-05-30 23:26:19', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10017');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10018', 'abuso', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de abuso em Fortaleza. Massa de teste deterministica para analise estatistica.', 'encaminhada', FALSE, 88, 'high', 'Alta', 'CRITICA', 'REGRAS', 1, TIMESTAMP '2026-04-23 12:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10018');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10019', 'violencia', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de violencia em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'encaminhada', TRUE, 85, 'high', 'Alta', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-05-01 00:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10019');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10020', 'assedio', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de assedio em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 44, 'medium', 'Media', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-04-02 15:20:00', TIMESTAMP '2026-04-02 22:32:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10020');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10021', 'violencia', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de violencia em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 100, 'high', 'Alta', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-06-13 16:20:00', TIMESTAMP '2026-06-17 04:22:50', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10021');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10022', 'abuso', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de abuso em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 81, 'high', 'Alta', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-04-17 06:40:00', TIMESTAMP '2026-04-22 22:11:42', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10022');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10023', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 90, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-05-08 20:10:00', TIMESTAMP '2026-05-17 02:31:35', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10023');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10024', 'outros', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de outros em Curitiba. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 65, 'medium', 'Media', 'BAIXA', 'REGRAS', 1, TIMESTAMP '2026-05-06 19:50:00', TIMESTAMP '2026-05-13 02:53:08', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10024');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10025', 'abuso', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de abuso em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 63, 'medium', 'Media', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-06-14 06:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10025');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10026', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 76, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-05-31 21:20:00', TIMESTAMP '2026-06-03 16:50:21', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10026');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10027', 'violencia', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de violencia em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 73, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-05-20 22:30:00', TIMESTAMP '2026-05-23 06:41:28', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10027');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10028', 'assedio', 'Salvador, BA', 'BA', 'Salvador', 'Registro de assedio em Salvador. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 53, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-06-19 20:50:00', TIMESTAMP '2026-06-28 12:52:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10028');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10029', 'outros', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de outros em Curitiba. Massa de teste deterministica para analise estatistica.', 'encaminhada', TRUE, 41, 'medium', 'Media', 'BAIXA', 'REGRAS', 1, TIMESTAMP '2026-06-09 16:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10029');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10030', 'discriminacao', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de discriminacao em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 46, 'medium', 'Media', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-04-19 04:40:00', TIMESTAMP '2026-04-27 08:51:29', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10030');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10031', 'discriminacao', 'Recife, PE', 'PE', 'Recife', 'Registro de discriminacao em Recife. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 49, 'medium', 'Media', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-03-15 23:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10031');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10032', 'assedio', 'Recife, PE', 'PE', 'Recife', 'Registro de assedio em Recife. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 41, 'medium', 'Media', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-03-27 23:20:00', TIMESTAMP '2026-04-04 20:40:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10032');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10033', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 51, 'medium', 'Media', 'CRITICA', 'REGRAS', NULL, TIMESTAMP '2026-05-25 07:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10033');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10034', 'abuso', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de abuso em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 99, 'high', 'Alta', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-04-14 01:00:00', TIMESTAMP '2026-04-20 04:43:26', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10034');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10035', 'discriminacao', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de discriminacao em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 46, 'medium', 'Media', 'BAIXA', 'REGRAS', 2, TIMESTAMP '2026-05-09 18:00:00', TIMESTAMP '2026-05-13 23:27:25', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10035');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10036', 'abuso', 'Salvador, BA', 'BA', 'Salvador', 'Registro de abuso em Salvador. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 27, 'low', 'Baixa', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-05-28 00:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10036');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10037', 'discriminacao', 'Salvador, BA', 'BA', 'Salvador', 'Registro de discriminacao em Salvador. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 72, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-03-27 12:50:00', TIMESTAMP '2026-03-30 06:28:56', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10037');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10038', 'violencia', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de violencia em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 46, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-03-20 09:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10038');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10039', 'violencia', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de violencia em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 53, 'medium', 'Media', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-03-03 23:40:00', TIMESTAMP '2026-03-04 13:32:13', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10039');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10040', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 44, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-06-28 01:30:00', TIMESTAMP '2026-06-30 10:38:15', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10040');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10041', 'violencia', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de violencia em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 60, 'medium', 'Media', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-05-24 13:50:00', TIMESTAMP '2026-05-29 23:44:07', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10041');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10042', 'abuso', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de abuso em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 61, 'medium', 'Media', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-03-03 19:30:00', TIMESTAMP '2026-03-05 18:23:01', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10042');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10043', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 55, 'medium', 'Media', 'BAIXA', 'REGRAS', NULL, TIMESTAMP '2026-03-25 09:40:00', TIMESTAMP '2026-04-03 18:43:35', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10043');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10044', 'abuso', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de abuso em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 45, 'medium', 'Media', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-05-26 15:10:00', TIMESTAMP '2026-05-30 15:40:55', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10044');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10045', 'abuso', 'Salvador, BA', 'BA', 'Salvador', 'Registro de abuso em Salvador. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 85, 'high', 'Alta', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-04-12 10:40:00', TIMESTAMP '2026-04-14 03:17:13', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10045');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10046', 'violencia', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de violencia em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 61, 'medium', 'Media', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-03-20 08:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10046');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10047', 'violencia', 'Salvador, BA', 'BA', 'Salvador', 'Registro de violencia em Salvador. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 83, 'high', 'Alta', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-05-20 15:10:00', TIMESTAMP '2026-05-24 16:44:09', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10047');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10048', 'outros', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de outros em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'encaminhada', FALSE, 58, 'medium', 'Media', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-06-18 05:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10048');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10049', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 71, 'high', 'Alta', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-05-11 12:20:00', TIMESTAMP '2026-05-16 06:07:57', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10049');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10050', 'violencia', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de violencia em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 79, 'high', 'Alta', 'CRITICA', 'REGRAS', 2, TIMESTAMP '2026-03-25 02:40:00', TIMESTAMP '2026-03-28 22:01:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10050');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10051', 'abuso', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de abuso em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'analise', TRUE, 66, 'medium', 'Media', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-03-02 08:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10051');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10052', 'assedio', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de assedio em Fortaleza. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 89, 'high', 'Alta', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-03-14 20:40:00', TIMESTAMP '2026-03-20 19:58:09', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10052');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10053', 'outros', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de outros em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 43, 'medium', 'Media', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-04-14 23:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10053');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10054', 'discriminacao', 'Recife, PE', 'PE', 'Recife', 'Registro de discriminacao em Recife. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 52, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-03-06 13:30:00', TIMESTAMP '2026-03-16 18:01:10', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10054');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10055', 'assedio', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de assedio em Fortaleza. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 64, 'medium', 'Media', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-04-21 05:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10055');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10056', 'violencia', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de violencia em Curitiba. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 77, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-05-05 18:00:00', TIMESTAMP '2026-05-06 22:05:10', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10056');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10057', 'abuso', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de abuso em Fortaleza. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 70, 'high', 'Alta', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-06-24 21:20:00', TIMESTAMP '2026-06-27 08:57:16', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10057');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10058', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 47, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-04-15 18:50:00', TIMESTAMP '2026-04-23 18:36:48', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10058');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10059', 'abuso', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de abuso em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 40, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-04-12 10:20:00', TIMESTAMP '2026-04-18 17:24:02', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10059');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10060', 'abuso', 'Recife, PE', 'PE', 'Recife', 'Registro de abuso em Recife. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 65, 'medium', 'Media', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-06-18 18:20:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10060');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10061', 'discriminacao', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de discriminacao em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'encaminhada', TRUE, 54, 'medium', 'Media', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-04-14 19:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10061');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10062', 'discriminacao', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de discriminacao em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'analise', FALSE, 59, 'medium', 'Media', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-04-17 17:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10062');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10063', 'abuso', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de abuso em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 40, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-06-26 00:00:00', TIMESTAMP '2026-06-30 04:27:53', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10063');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10064', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 68, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-03-22 00:10:00', TIMESTAMP '2026-03-31 16:08:34', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10064');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10065', 'violencia', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de violencia em Curitiba. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 88, 'high', 'Alta', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-04-18 22:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10065');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10066', 'discriminacao', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de discriminacao em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'analise', TRUE, 85, 'high', 'Alta', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-04-27 23:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10066');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10067', 'violencia', 'Salvador, BA', 'BA', 'Salvador', 'Registro de violencia em Salvador. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 73, 'high', 'Alta', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-04-09 18:40:00', TIMESTAMP '2026-04-10 12:33:17', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10067');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10068', 'assedio', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de assedio em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 26, 'low', 'Baixa', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-03-21 01:40:00', TIMESTAMP '2026-03-25 12:11:55', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10068');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10069', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 56, 'medium', 'Media', 'CRITICA', 'REGRAS', NULL, TIMESTAMP '2026-05-10 22:30:00', TIMESTAMP '2026-05-15 07:07:19', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10069');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10070', 'assedio', 'Salvador, BA', 'BA', 'Salvador', 'Registro de assedio em Salvador. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 71, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-06-26 22:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10070');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10071', 'abuso', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de abuso em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 42, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-06-15 10:00:00', TIMESTAMP '2026-06-17 14:52:27', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10071');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10072', 'outros', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de outros em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 59, 'medium', 'Media', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-03-28 11:10:00', TIMESTAMP '2026-04-12 19:13:34', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10072');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10073', 'discriminacao', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de discriminacao em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 66, 'medium', 'Media', 'BAIXA', 'REGRAS', 1, TIMESTAMP '2026-06-09 09:40:00', TIMESTAMP '2026-06-12 22:23:02', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10073');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10074', 'discriminacao', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de discriminacao em Fortaleza. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 82, 'high', 'Alta', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-04-28 05:40:00', TIMESTAMP '2026-05-10 18:34:45', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10074');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10075', 'discriminacao', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de discriminacao em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 29, 'low', 'Baixa', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-05-20 04:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10075');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10076', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'analise', FALSE, 71, 'high', 'Alta', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-05-15 23:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10076');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10077', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'analise', TRUE, 52, 'medium', 'Media', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-05-06 09:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10077');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10078', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 71, 'high', 'Alta', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-05-30 00:20:00', TIMESTAMP '2026-06-07 14:28:07', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10078');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10079', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'analise', TRUE, 44, 'medium', 'Media', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-04-11 08:00:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10079');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10080', 'abuso', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de abuso em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 62, 'medium', 'Media', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-03-05 21:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10080');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10081', 'assedio', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de assedio em Fortaleza. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 97, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-05-18 13:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10081');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10082', 'discriminacao', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de discriminacao em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 47, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-06-17 12:00:00', TIMESTAMP '2026-06-25 17:53:20', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10082');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10083', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 59, 'medium', 'Media', 'BAIXA', 'REGRAS', 1, TIMESTAMP '2026-03-03 02:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10083');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10084', 'outros', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de outros em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 78, 'high', 'Alta', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-06-10 18:40:00', TIMESTAMP '2026-06-21 01:15:58', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10084');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10085', 'abuso', 'Recife, PE', 'PE', 'Recife', 'Registro de abuso em Recife. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 42, 'medium', 'Media', 'CRITICA', 'REGRAS', NULL, TIMESTAMP '2026-06-27 09:20:00', TIMESTAMP '2026-07-02 20:44:37', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10085');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10086', 'assedio', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de assedio em Fortaleza. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 37, 'low', 'Baixa', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-06-21 22:40:00', TIMESTAMP '2026-06-28 17:35:33', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10086');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10087', 'violencia', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de violencia em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'encaminhada', FALSE, 83, 'high', 'Alta', 'ALTA', 'REGRAS', 3, TIMESTAMP '2026-04-08 16:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10087');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10088', 'violencia', 'Salvador, BA', 'BA', 'Salvador', 'Registro de violencia em Salvador. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 77, 'high', 'Alta', 'ALTA', 'REGRAS', 1, TIMESTAMP '2026-06-17 19:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10088');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10089', 'violencia', 'Salvador, BA', 'BA', 'Salvador', 'Registro de violencia em Salvador. Massa de teste deterministica para analise estatistica.', 'encaminhada', TRUE, 24, 'low', 'Baixa', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-05-27 05:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10089');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10090', 'violencia', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de violencia em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 81, 'high', 'Alta', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-05-23 18:20:00', TIMESTAMP '2026-05-27 04:03:15', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10090');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10091', 'violencia', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de violencia em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 74, 'high', 'Alta', 'CRITICA', 'REGRAS', 2, TIMESTAMP '2026-04-23 20:30:00', TIMESTAMP '2026-04-26 11:51:08', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10091');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10092', 'outros', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de outros em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 36, 'low', 'Baixa', 'BAIXA', 'REGRAS', NULL, TIMESTAMP '2026-06-16 17:00:00', TIMESTAMP '2026-06-26 00:36:48', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10092');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10093', 'assedio', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de assedio em Curitiba. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 45, 'medium', 'Media', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-03-04 17:50:00', TIMESTAMP '2026-03-06 08:18:13', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10093');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10094', 'assedio', 'Salvador, BA', 'BA', 'Salvador', 'Registro de assedio em Salvador. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 55, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-04-30 19:20:00', TIMESTAMP '2026-05-08 09:04:12', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10094');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10095', 'discriminacao', 'Recife, PE', 'PE', 'Recife', 'Registro de discriminacao em Recife. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 56, 'medium', 'Media', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-05-11 00:00:00', TIMESTAMP '2026-05-18 01:01:40', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10095');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10096', 'outros', 'Salvador, BA', 'BA', 'Salvador', 'Registro de outros em Salvador. Massa de teste deterministica para analise estatistica.', 'encaminhada', FALSE, 67, 'medium', 'Media', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-04-04 12:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10096');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10097', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 68, 'medium', 'Media', 'CRITICA', 'REGRAS', NULL, TIMESTAMP '2026-04-07 11:20:00', TIMESTAMP '2026-04-10 18:19:37', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10097');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10098', 'outros', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de outros em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 75, 'high', 'Alta', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-04-03 08:10:00', TIMESTAMP '2026-04-10 04:31:23', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10098');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10099', 'assedio', 'Recife, PE', 'PE', 'Recife', 'Registro de assedio em Recife. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 52, 'medium', 'Media', 'MEDIA', 'REGRAS', 3, TIMESTAMP '2026-03-20 20:40:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10099');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10100', 'abuso', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de abuso em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'encaminhada', TRUE, 58, 'medium', 'Media', 'CRITICA', 'REGRAS', 2, TIMESTAMP '2026-04-07 10:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10100');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10101', 'violencia', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de violencia em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'recebida', FALSE, 67, 'medium', 'Media', 'CRITICA', 'REGRAS', NULL, TIMESTAMP '2026-03-02 14:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10101');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10102', 'assedio', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de assedio em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'recebida', FALSE, 100, 'high', 'Alta', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-03-31 12:50:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10102');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10103', 'violencia', 'Recife, PE', 'PE', 'Recife', 'Registro de violencia em Recife. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 83, 'high', 'Alta', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-04-16 06:20:00', TIMESTAMP '2026-04-16 13:32:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10103');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10104', 'violencia', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de violencia em Curitiba. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 50, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-04-17 03:00:00', TIMESTAMP '2026-04-17 10:12:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10104');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10105', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 51, 'medium', 'Media', 'CRITICA', 'REGRAS', NULL, TIMESTAMP '2026-04-04 19:40:00', TIMESTAMP '2026-04-06 23:24:01', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10105');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10106', 'assedio', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de assedio em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 92, 'high', 'Alta', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-03-31 19:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10106');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10107', 'violencia', 'Curitiba, PR', 'PR', 'Curitiba', 'Registro de violencia em Curitiba. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 64, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-03-18 20:20:00', TIMESTAMP '2026-03-21 20:42:06', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10107');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10108', 'discriminacao', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de discriminacao em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 71, 'high', 'Alta', 'MEDIA', 'REGRAS', 2, TIMESTAMP '2026-03-19 12:20:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10108');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10109', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 89, 'high', 'Alta', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-05-16 20:20:00', TIMESTAMP '2026-05-19 06:43:37', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10109');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10110', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 64, 'medium', 'Media', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-03-06 21:20:00', TIMESTAMP '2026-03-07 12:01:29', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10110');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10111', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 65, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-06-22 17:00:00', TIMESTAMP '2026-06-24 14:43:17', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10111');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10112', 'abuso', 'Porto Alegre, RS', 'RS', 'Porto Alegre', 'Registro de abuso em Porto Alegre. Massa de teste deterministica para analise estatistica.', 'recebida', TRUE, 49, 'medium', 'Media', 'ALTA', 'REGRAS', 2, TIMESTAMP '2026-03-29 12:10:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10112');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10113', 'discriminacao', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de discriminacao em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'encaminhada', TRUE, 74, 'high', 'Alta', 'BAIXA', 'REGRAS', NULL, TIMESTAMP '2026-04-02 13:30:00', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10113');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10114', 'outros', 'Fortaleza, CE', 'CE', 'Fortaleza', 'Registro de outros em Fortaleza. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 67, 'medium', 'Media', 'BAIXA', 'REGRAS', 3, TIMESTAMP '2026-05-26 11:30:00', TIMESTAMP '2026-06-18 10:11:25', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10114');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10115', 'outros', 'Salvador, BA', 'BA', 'Salvador', 'Registro de outros em Salvador. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 60, 'medium', 'Media', 'BAIXA', 'REGRAS', 2, TIMESTAMP '2026-04-07 12:50:00', TIMESTAMP '2026-04-13 04:03:11', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10115');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10116', 'discriminacao', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de discriminacao em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 52, 'medium', 'Media', 'BAIXA', 'REGRAS', 1, TIMESTAMP '2026-03-03 07:10:00', TIMESTAMP '2026-03-16 04:48:30', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10116');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10117', 'violencia', 'Belo Horizonte, MG', 'MG', 'Belo Horizonte', 'Registro de violencia em Belo Horizonte. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 51, 'medium', 'Media', 'MEDIA', 'REGRAS', NULL, TIMESTAMP '2026-03-31 21:50:00', TIMESTAMP '2026-04-05 15:42:05', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10117');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10118', 'outros', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de outros em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 57, 'medium', 'Media', 'MEDIA', 'REGRAS', 1, TIMESTAMP '2026-03-28 09:10:00', TIMESTAMP '2026-04-06 23:18:24', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10118');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10119', 'violencia', 'Sao Paulo, SP', 'SP', 'Sao Paulo', 'Registro de violencia em Sao Paulo. Massa de teste deterministica para analise estatistica.', 'concluida', TRUE, 81, 'high', 'Alta', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-05-01 02:30:00', TIMESTAMP '2026-05-02 08:17:38', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10119');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, origem_analise, responsavel_id, criado_em, concluida_em, excluida)
SELECT '#2026-10120', 'assedio', 'Rio de Janeiro, RJ', 'RJ', 'Rio de Janeiro', 'Registro de assedio em Rio de Janeiro. Massa de teste deterministica para analise estatistica.', 'concluida', FALSE, 60, 'medium', 'Media', 'ALTA', 'REGRAS', NULL, TIMESTAMP '2026-04-13 06:30:00', TIMESTAMP '2026-04-23 19:47:42', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia WHERE protocolo = '#2026-10120');

-- Linha do tempo das 120 acima (195 eventos)
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '27/05/2026', '19:50' FROM denuncia d
WHERE d.protocolo = '#2026-10001' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '09/04/2026', '01:50' FROM denuncia d
WHERE d.protocolo = '#2026-10002' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '15/03/2026', '15:30' FROM denuncia d
WHERE d.protocolo = '#2026-10003' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '17/03/2026', '22:15' FROM denuncia d
WHERE d.protocolo = '#2026-10003' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '19/05/2026', '19:20' FROM denuncia d
WHERE d.protocolo = '#2026-10004' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '14/03/2026', '11:10' FROM denuncia d
WHERE d.protocolo = '#2026-10005' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '14/03/2026', '18:22' FROM denuncia d
WHERE d.protocolo = '#2026-10005' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '24/05/2026', '00:40' FROM denuncia d
WHERE d.protocolo = '#2026-10006' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '26/05/2026', '08:12' FROM denuncia d
WHERE d.protocolo = '#2026-10006' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '26/06/2026', '07:40' FROM denuncia d
WHERE d.protocolo = '#2026-10007' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '27/06/2026', '20:50' FROM denuncia d
WHERE d.protocolo = '#2026-10008' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '17/03/2026', '08:00' FROM denuncia d
WHERE d.protocolo = '#2026-10009' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '31/05/2026', '06:40' FROM denuncia d
WHERE d.protocolo = '#2026-10010' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '14/06/2026', '10:58' FROM denuncia d
WHERE d.protocolo = '#2026-10010' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '11/04/2026', '09:00' FROM denuncia d
WHERE d.protocolo = '#2026-10011' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '18/04/2026', '18:11' FROM denuncia d
WHERE d.protocolo = '#2026-10011' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '10/04/2026', '08:50' FROM denuncia d
WHERE d.protocolo = '#2026-10012' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '01/06/2026', '01:00' FROM denuncia d
WHERE d.protocolo = '#2026-10013' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '03/06/2026', '06:11' FROM denuncia d
WHERE d.protocolo = '#2026-10013' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '09/06/2026', '08:20' FROM denuncia d
WHERE d.protocolo = '#2026-10014' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '18/06/2026', '12:41' FROM denuncia d
WHERE d.protocolo = '#2026-10014' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '26/06/2026', '19:20' FROM denuncia d
WHERE d.protocolo = '#2026-10015' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '04/07/2026', '03:46' FROM denuncia d
WHERE d.protocolo = '#2026-10015' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '11/03/2026', '04:20' FROM denuncia d
WHERE d.protocolo = '#2026-10016' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '15/03/2026', '12:09' FROM denuncia d
WHERE d.protocolo = '#2026-10016' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '25/05/2026', '17:50' FROM denuncia d
WHERE d.protocolo = '#2026-10017' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '30/05/2026', '23:26' FROM denuncia d
WHERE d.protocolo = '#2026-10017' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '23/04/2026', '12:40' FROM denuncia d
WHERE d.protocolo = '#2026-10018' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '01/05/2026', '00:00' FROM denuncia d
WHERE d.protocolo = '#2026-10019' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '02/04/2026', '15:20' FROM denuncia d
WHERE d.protocolo = '#2026-10020' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '02/04/2026', '22:32' FROM denuncia d
WHERE d.protocolo = '#2026-10020' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '13/06/2026', '16:20' FROM denuncia d
WHERE d.protocolo = '#2026-10021' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '17/06/2026', '04:22' FROM denuncia d
WHERE d.protocolo = '#2026-10021' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '17/04/2026', '06:40' FROM denuncia d
WHERE d.protocolo = '#2026-10022' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '22/04/2026', '22:11' FROM denuncia d
WHERE d.protocolo = '#2026-10022' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '08/05/2026', '20:10' FROM denuncia d
WHERE d.protocolo = '#2026-10023' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '17/05/2026', '02:31' FROM denuncia d
WHERE d.protocolo = '#2026-10023' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '06/05/2026', '19:50' FROM denuncia d
WHERE d.protocolo = '#2026-10024' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '13/05/2026', '02:53' FROM denuncia d
WHERE d.protocolo = '#2026-10024' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '14/06/2026', '06:40' FROM denuncia d
WHERE d.protocolo = '#2026-10025' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '31/05/2026', '21:20' FROM denuncia d
WHERE d.protocolo = '#2026-10026' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '03/06/2026', '16:50' FROM denuncia d
WHERE d.protocolo = '#2026-10026' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '20/05/2026', '22:30' FROM denuncia d
WHERE d.protocolo = '#2026-10027' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '23/05/2026', '06:41' FROM denuncia d
WHERE d.protocolo = '#2026-10027' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '19/06/2026', '20:50' FROM denuncia d
WHERE d.protocolo = '#2026-10028' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '28/06/2026', '12:52' FROM denuncia d
WHERE d.protocolo = '#2026-10028' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '09/06/2026', '16:00' FROM denuncia d
WHERE d.protocolo = '#2026-10029' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '19/04/2026', '04:40' FROM denuncia d
WHERE d.protocolo = '#2026-10030' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '27/04/2026', '08:51' FROM denuncia d
WHERE d.protocolo = '#2026-10030' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '15/03/2026', '23:40' FROM denuncia d
WHERE d.protocolo = '#2026-10031' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '27/03/2026', '23:20' FROM denuncia d
WHERE d.protocolo = '#2026-10032' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '04/04/2026', '20:40' FROM denuncia d
WHERE d.protocolo = '#2026-10032' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '25/05/2026', '07:00' FROM denuncia d
WHERE d.protocolo = '#2026-10033' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '14/04/2026', '01:00' FROM denuncia d
WHERE d.protocolo = '#2026-10034' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '20/04/2026', '04:43' FROM denuncia d
WHERE d.protocolo = '#2026-10034' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '09/05/2026', '18:00' FROM denuncia d
WHERE d.protocolo = '#2026-10035' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '13/05/2026', '23:27' FROM denuncia d
WHERE d.protocolo = '#2026-10035' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '28/05/2026', '00:40' FROM denuncia d
WHERE d.protocolo = '#2026-10036' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '27/03/2026', '12:50' FROM denuncia d
WHERE d.protocolo = '#2026-10037' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '30/03/2026', '06:28' FROM denuncia d
WHERE d.protocolo = '#2026-10037' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '20/03/2026', '09:40' FROM denuncia d
WHERE d.protocolo = '#2026-10038' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '03/03/2026', '23:40' FROM denuncia d
WHERE d.protocolo = '#2026-10039' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '04/03/2026', '13:32' FROM denuncia d
WHERE d.protocolo = '#2026-10039' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '28/06/2026', '01:30' FROM denuncia d
WHERE d.protocolo = '#2026-10040' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '30/06/2026', '10:38' FROM denuncia d
WHERE d.protocolo = '#2026-10040' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '24/05/2026', '13:50' FROM denuncia d
WHERE d.protocolo = '#2026-10041' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '29/05/2026', '23:44' FROM denuncia d
WHERE d.protocolo = '#2026-10041' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '03/03/2026', '19:30' FROM denuncia d
WHERE d.protocolo = '#2026-10042' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '05/03/2026', '18:23' FROM denuncia d
WHERE d.protocolo = '#2026-10042' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '25/03/2026', '09:40' FROM denuncia d
WHERE d.protocolo = '#2026-10043' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '03/04/2026', '18:43' FROM denuncia d
WHERE d.protocolo = '#2026-10043' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '26/05/2026', '15:10' FROM denuncia d
WHERE d.protocolo = '#2026-10044' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '30/05/2026', '15:40' FROM denuncia d
WHERE d.protocolo = '#2026-10044' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '12/04/2026', '10:40' FROM denuncia d
WHERE d.protocolo = '#2026-10045' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '14/04/2026', '03:17' FROM denuncia d
WHERE d.protocolo = '#2026-10045' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '20/03/2026', '08:00' FROM denuncia d
WHERE d.protocolo = '#2026-10046' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '20/05/2026', '15:10' FROM denuncia d
WHERE d.protocolo = '#2026-10047' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '24/05/2026', '16:44' FROM denuncia d
WHERE d.protocolo = '#2026-10047' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '18/06/2026', '05:10' FROM denuncia d
WHERE d.protocolo = '#2026-10048' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '11/05/2026', '12:20' FROM denuncia d
WHERE d.protocolo = '#2026-10049' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '16/05/2026', '06:07' FROM denuncia d
WHERE d.protocolo = '#2026-10049' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '25/03/2026', '02:40' FROM denuncia d
WHERE d.protocolo = '#2026-10050' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '28/03/2026', '22:01' FROM denuncia d
WHERE d.protocolo = '#2026-10050' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '02/03/2026', '08:30' FROM denuncia d
WHERE d.protocolo = '#2026-10051' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '14/03/2026', '20:40' FROM denuncia d
WHERE d.protocolo = '#2026-10052' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '20/03/2026', '19:58' FROM denuncia d
WHERE d.protocolo = '#2026-10052' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '14/04/2026', '23:40' FROM denuncia d
WHERE d.protocolo = '#2026-10053' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '06/03/2026', '13:30' FROM denuncia d
WHERE d.protocolo = '#2026-10054' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '16/03/2026', '18:01' FROM denuncia d
WHERE d.protocolo = '#2026-10054' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '21/04/2026', '05:50' FROM denuncia d
WHERE d.protocolo = '#2026-10055' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '05/05/2026', '18:00' FROM denuncia d
WHERE d.protocolo = '#2026-10056' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '06/05/2026', '22:05' FROM denuncia d
WHERE d.protocolo = '#2026-10056' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '24/06/2026', '21:20' FROM denuncia d
WHERE d.protocolo = '#2026-10057' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '27/06/2026', '08:57' FROM denuncia d
WHERE d.protocolo = '#2026-10057' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '15/04/2026', '18:50' FROM denuncia d
WHERE d.protocolo = '#2026-10058' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '23/04/2026', '18:36' FROM denuncia d
WHERE d.protocolo = '#2026-10058' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '12/04/2026', '10:20' FROM denuncia d
WHERE d.protocolo = '#2026-10059' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '18/04/2026', '17:24' FROM denuncia d
WHERE d.protocolo = '#2026-10059' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '18/06/2026', '18:20' FROM denuncia d
WHERE d.protocolo = '#2026-10060' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '14/04/2026', '19:00' FROM denuncia d
WHERE d.protocolo = '#2026-10061' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '17/04/2026', '17:40' FROM denuncia d
WHERE d.protocolo = '#2026-10062' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '26/06/2026', '00:00' FROM denuncia d
WHERE d.protocolo = '#2026-10063' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '30/06/2026', '04:27' FROM denuncia d
WHERE d.protocolo = '#2026-10063' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '22/03/2026', '00:10' FROM denuncia d
WHERE d.protocolo = '#2026-10064' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '31/03/2026', '16:08' FROM denuncia d
WHERE d.protocolo = '#2026-10064' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '18/04/2026', '22:30' FROM denuncia d
WHERE d.protocolo = '#2026-10065' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '27/04/2026', '23:10' FROM denuncia d
WHERE d.protocolo = '#2026-10066' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '09/04/2026', '18:40' FROM denuncia d
WHERE d.protocolo = '#2026-10067' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '10/04/2026', '12:33' FROM denuncia d
WHERE d.protocolo = '#2026-10067' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '21/03/2026', '01:40' FROM denuncia d
WHERE d.protocolo = '#2026-10068' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '25/03/2026', '12:11' FROM denuncia d
WHERE d.protocolo = '#2026-10068' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '10/05/2026', '22:30' FROM denuncia d
WHERE d.protocolo = '#2026-10069' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '15/05/2026', '07:07' FROM denuncia d
WHERE d.protocolo = '#2026-10069' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '26/06/2026', '22:30' FROM denuncia d
WHERE d.protocolo = '#2026-10070' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '15/06/2026', '10:00' FROM denuncia d
WHERE d.protocolo = '#2026-10071' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '17/06/2026', '14:52' FROM denuncia d
WHERE d.protocolo = '#2026-10071' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '28/03/2026', '11:10' FROM denuncia d
WHERE d.protocolo = '#2026-10072' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '12/04/2026', '19:13' FROM denuncia d
WHERE d.protocolo = '#2026-10072' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '09/06/2026', '09:40' FROM denuncia d
WHERE d.protocolo = '#2026-10073' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '12/06/2026', '22:23' FROM denuncia d
WHERE d.protocolo = '#2026-10073' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '28/04/2026', '05:40' FROM denuncia d
WHERE d.protocolo = '#2026-10074' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '10/05/2026', '18:34' FROM denuncia d
WHERE d.protocolo = '#2026-10074' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '20/05/2026', '04:00' FROM denuncia d
WHERE d.protocolo = '#2026-10075' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '15/05/2026', '23:30' FROM denuncia d
WHERE d.protocolo = '#2026-10076' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '06/05/2026', '09:50' FROM denuncia d
WHERE d.protocolo = '#2026-10077' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '30/05/2026', '00:20' FROM denuncia d
WHERE d.protocolo = '#2026-10078' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '07/06/2026', '14:28' FROM denuncia d
WHERE d.protocolo = '#2026-10078' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '11/04/2026', '08:00' FROM denuncia d
WHERE d.protocolo = '#2026-10079' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '05/03/2026', '21:40' FROM denuncia d
WHERE d.protocolo = '#2026-10080' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '18/05/2026', '13:10' FROM denuncia d
WHERE d.protocolo = '#2026-10081' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '17/06/2026', '12:00' FROM denuncia d
WHERE d.protocolo = '#2026-10082' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '25/06/2026', '17:53' FROM denuncia d
WHERE d.protocolo = '#2026-10082' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '03/03/2026', '02:50' FROM denuncia d
WHERE d.protocolo = '#2026-10083' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '10/06/2026', '18:40' FROM denuncia d
WHERE d.protocolo = '#2026-10084' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '21/06/2026', '01:15' FROM denuncia d
WHERE d.protocolo = '#2026-10084' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '27/06/2026', '09:20' FROM denuncia d
WHERE d.protocolo = '#2026-10085' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '02/07/2026', '20:44' FROM denuncia d
WHERE d.protocolo = '#2026-10085' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '21/06/2026', '22:40' FROM denuncia d
WHERE d.protocolo = '#2026-10086' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '28/06/2026', '17:35' FROM denuncia d
WHERE d.protocolo = '#2026-10086' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '08/04/2026', '16:10' FROM denuncia d
WHERE d.protocolo = '#2026-10087' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '17/06/2026', '19:30' FROM denuncia d
WHERE d.protocolo = '#2026-10088' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '27/05/2026', '05:30' FROM denuncia d
WHERE d.protocolo = '#2026-10089' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '23/05/2026', '18:20' FROM denuncia d
WHERE d.protocolo = '#2026-10090' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '27/05/2026', '04:03' FROM denuncia d
WHERE d.protocolo = '#2026-10090' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '23/04/2026', '20:30' FROM denuncia d
WHERE d.protocolo = '#2026-10091' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '26/04/2026', '11:51' FROM denuncia d
WHERE d.protocolo = '#2026-10091' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '16/06/2026', '17:00' FROM denuncia d
WHERE d.protocolo = '#2026-10092' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '26/06/2026', '00:36' FROM denuncia d
WHERE d.protocolo = '#2026-10092' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '04/03/2026', '17:50' FROM denuncia d
WHERE d.protocolo = '#2026-10093' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '06/03/2026', '08:18' FROM denuncia d
WHERE d.protocolo = '#2026-10093' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '30/04/2026', '19:20' FROM denuncia d
WHERE d.protocolo = '#2026-10094' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '08/05/2026', '09:04' FROM denuncia d
WHERE d.protocolo = '#2026-10094' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '11/05/2026', '00:00' FROM denuncia d
WHERE d.protocolo = '#2026-10095' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '18/05/2026', '01:01' FROM denuncia d
WHERE d.protocolo = '#2026-10095' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '04/04/2026', '12:10' FROM denuncia d
WHERE d.protocolo = '#2026-10096' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '07/04/2026', '11:20' FROM denuncia d
WHERE d.protocolo = '#2026-10097' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '10/04/2026', '18:19' FROM denuncia d
WHERE d.protocolo = '#2026-10097' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '03/04/2026', '08:10' FROM denuncia d
WHERE d.protocolo = '#2026-10098' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '10/04/2026', '04:31' FROM denuncia d
WHERE d.protocolo = '#2026-10098' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '20/03/2026', '20:40' FROM denuncia d
WHERE d.protocolo = '#2026-10099' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '07/04/2026', '10:30' FROM denuncia d
WHERE d.protocolo = '#2026-10100' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '02/03/2026', '14:30' FROM denuncia d
WHERE d.protocolo = '#2026-10101' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '31/03/2026', '12:50' FROM denuncia d
WHERE d.protocolo = '#2026-10102' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '16/04/2026', '06:20' FROM denuncia d
WHERE d.protocolo = '#2026-10103' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '16/04/2026', '13:32' FROM denuncia d
WHERE d.protocolo = '#2026-10103' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '17/04/2026', '03:00' FROM denuncia d
WHERE d.protocolo = '#2026-10104' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '17/04/2026', '10:12' FROM denuncia d
WHERE d.protocolo = '#2026-10104' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '04/04/2026', '19:40' FROM denuncia d
WHERE d.protocolo = '#2026-10105' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '06/04/2026', '23:24' FROM denuncia d
WHERE d.protocolo = '#2026-10105' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '31/03/2026', '19:10' FROM denuncia d
WHERE d.protocolo = '#2026-10106' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '18/03/2026', '20:20' FROM denuncia d
WHERE d.protocolo = '#2026-10107' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '21/03/2026', '20:42' FROM denuncia d
WHERE d.protocolo = '#2026-10107' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '19/03/2026', '12:20' FROM denuncia d
WHERE d.protocolo = '#2026-10108' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '16/05/2026', '20:20' FROM denuncia d
WHERE d.protocolo = '#2026-10109' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '19/05/2026', '06:43' FROM denuncia d
WHERE d.protocolo = '#2026-10109' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '06/03/2026', '21:20' FROM denuncia d
WHERE d.protocolo = '#2026-10110' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '07/03/2026', '12:01' FROM denuncia d
WHERE d.protocolo = '#2026-10110' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '22/06/2026', '17:00' FROM denuncia d
WHERE d.protocolo = '#2026-10111' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '24/06/2026', '14:43' FROM denuncia d
WHERE d.protocolo = '#2026-10111' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '29/03/2026', '12:10' FROM denuncia d
WHERE d.protocolo = '#2026-10112' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '02/04/2026', '13:30' FROM denuncia d
WHERE d.protocolo = '#2026-10113' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '26/05/2026', '11:30' FROM denuncia d
WHERE d.protocolo = '#2026-10114' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '18/06/2026', '10:11' FROM denuncia d
WHERE d.protocolo = '#2026-10114' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '07/04/2026', '12:50' FROM denuncia d
WHERE d.protocolo = '#2026-10115' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '13/04/2026', '04:03' FROM denuncia d
WHERE d.protocolo = '#2026-10115' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '03/03/2026', '07:10' FROM denuncia d
WHERE d.protocolo = '#2026-10116' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '16/03/2026', '04:48' FROM denuncia d
WHERE d.protocolo = '#2026-10116' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '31/03/2026', '21:50' FROM denuncia d
WHERE d.protocolo = '#2026-10117' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '05/04/2026', '15:42' FROM denuncia d
WHERE d.protocolo = '#2026-10117' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '28/03/2026', '09:10' FROM denuncia d
WHERE d.protocolo = '#2026-10118' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '06/04/2026', '23:18' FROM denuncia d
WHERE d.protocolo = '#2026-10118' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '01/05/2026', '02:30' FROM denuncia d
WHERE d.protocolo = '#2026-10119' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '02/05/2026', '08:17' FROM denuncia d
WHERE d.protocolo = '#2026-10119' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 0, 'recebida', '13/04/2026', '06:30' FROM denuncia d
WHERE d.protocolo = '#2026-10120' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 0);
INSERT INTO denuncia_historico (denuncia_id, ordem, status, data, hora)
SELECT d.id, 1, 'concluida', '23/04/2026', '19:47' FROM denuncia d
WHERE d.protocolo = '#2026-10120' AND NOT EXISTS (SELECT 1 FROM denuncia_historico h WHERE h.denuncia_id = d.id AND h.ordem = 1);

-- =====================================================================
--  FASE 6  .  Zona de exclusao de demonstracao
--  Uma medida protetiva ficticia em Barueri, raio de 500 m. O simulador
--  de telemetria usa esta tornozeleira. O INSERT e idempotente: a
--  aplicacao reexecuta este script a cada subida, e sem o NOT EXISTS a
--  restricao de unicidade derrubaria o contexto no segundo start.
-- =====================================================================
INSERT INTO zona_exclusao (processo, tornozeleira, lat_protegida, lng_protegida, raio_metros, ativa, dentro_do_perimetro)
SELECT '0007441-88.2026', 'TZ-4471', -23.5108, -46.8760, 500, TRUE, FALSE
WHERE NOT EXISTS (SELECT 1 FROM zona_exclusao z WHERE z.tornozeleira = 'TZ-4471');

-- =====================================================================
--  FASE 6  .  Totens de demonstracao
--  Tres pontos: dois ativos e um retirado para manutencao. O desativado
--  existe de proposito, para que a demonstracao mostre um equipamento
--  sendo recusado pela mesma porta por onde um equipamento desconhecido
--  e recusado.
-- =====================================================================
INSERT INTO ponto_totem (dispositivo, local_instalacao, estado, cidade, latitude, longitude, ativo)
SELECT 'TT-001', 'UBS Central de Barueri', 'SP', 'Barueri', -23.5106, -46.8761, TRUE
WHERE NOT EXISTS (SELECT 1 FROM ponto_totem p WHERE p.dispositivo = 'TT-001');

INSERT INTO ponto_totem (dispositivo, local_instalacao, estado, cidade, latitude, longitude, ativo)
SELECT 'TT-002', 'Terminal Rodoviario de Barueri', 'SP', 'Barueri', -23.5147, -46.8792, TRUE
WHERE NOT EXISTS (SELECT 1 FROM ponto_totem p WHERE p.dispositivo = 'TT-002');

INSERT INTO ponto_totem (dispositivo, local_instalacao, estado, cidade, latitude, longitude, ativo)
SELECT 'TT-003', 'CRAS Jardim Belval (em manutencao)', 'SP', 'Barueri', -23.5231, -46.8654, FALSE
WHERE NOT EXISTS (SELECT 1 FROM ponto_totem p WHERE p.dispositivo = 'TT-003');

INSERT INTO ponto_totem (dispositivo, local_instalacao, estado, cidade, latitude, longitude, ativo)
SELECT 'TT-004', 'CRAS Vila Boa Vista', 'SP', 'Barueri', -23.5052, -46.8703, TRUE
WHERE NOT EXISTS (SELECT 1 FROM ponto_totem p WHERE p.dispositivo = 'TT-004');

-- =====================================================================
--  FASE 6 . Carga de demonstracao do barramento de dispositivos
--
--  106 eventos entre 01/04 e 15/05/2026 nas tres origens, e as
--  65 denuncias que os eventos aceitos abriram. Os dois lados sao
--  emitidos juntos de proposito: um evento que aponta para um protocolo
--  inexistente quebraria a consulta que cruza barramento e denuncia, e e
--  justamente ela que prova que a urgencia sai do VigIA lendo o texto, e
--  nao do aparelho que enviou.
--
--  Esta e carga de EXEMPLO, no mesmo regime do restante deste arquivo. A
--  semente do gerador e o RM 561601, de modo que a carga e identica em
--  qualquer maquina: os numeros do relatorio podem ser conferidos na
--  origem por quem corrige.
--
--  Idempotente: sem isto, cada subida da aplicacao somaria outra carga e
--  as metricas mudariam sozinhas a cada reinicio.
-- =====================================================================
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90034', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Entrada no perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4471. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'concluida', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-03 00:18:09', TIMESTAMP '2026-04-08 11:27:45', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90034');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90052', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: meu vizinho bate na esposa toda semana e ontem ouvi ela gritando por socorro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-03 17:06:43', TIMESTAMP '2026-04-12 06:08:38', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90052');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90059', 'discriminacao', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: meu filho e o unico negro da turma e o professor o trata diferente todo dia Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-04 17:30:51', TIMESTAMP '2026-04-11 05:03:29', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90059');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90055', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: ele me empurrou na frente das criancas e disse que ia voltar hoje a noite Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'ALTA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-04 17:50:09', TIMESTAMP '2026-04-14 03:10:18', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90055');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90041', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Permanencia dentro do perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4488. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'analise', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-06 11:36:37', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90041');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90031', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.493490, -46.872952', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.493490, -46.872952. Bateria do aparelho em 68%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-06 18:57:29', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90031');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90023', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.506058, -46.856359', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8823. Coordenada informada pelo aparelho: -23.506058, -46.856359. Bateria do aparelho em 78%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-07 19:05:06', TIMESTAMP '2026-04-17 19:59:49', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90023');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90001', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.515158, -46.866988', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8817. Coordenada informada pelo aparelho: -23.515158, -46.866988. Bateria do aparelho em 41%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-08 16:32:43', TIMESTAMP '2026-04-11 04:08:14', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90001');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90002', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.515158, -46.866988', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8817. Coordenada informada pelo aparelho: -23.515158, -46.866988. Bateria do aparelho em 41%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-08 16:34:59', TIMESTAMP '2026-04-12 17:39:47', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90002');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90020', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.512566, -46.870659', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8817. Coordenada informada pelo aparelho: -23.512566, -46.870659. Bateria do aparelho em 53%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-09 15:24:49', TIMESTAMP '2026-04-14 18:08:58', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90020');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90039', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Entrada no perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4471. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'analise', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-10 18:25:50', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90039');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90028', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.494225, -46.870920', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.494225, -46.870920. Bateria do aparelho em 43%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-11 10:44:32', TIMESTAMP '2026-04-16 00:21:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90028');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90033', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Entrada no perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4502. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'concluida', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-11 20:34:57', TIMESTAMP '2026-04-17 18:35:25', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90033');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90057', 'discriminacao', 'Barueri, SP', 'SP', 'Barueri', 'UBS Central de Barueri', 'Registro feito em totem de atendimento publico, em UBS Central de Barueri. Relato da pessoa: meu filho e o unico negro da turma e o professor o trata diferente todo dia Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'analise', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-12 17:23:57', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90057');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90051', 'outros', 'Barueri, SP', 'SP', 'Barueri', 'CRAS Vila Boa Vista', 'Registro feito em totem de atendimento publico, em CRAS Vila Boa Vista. Relato da pessoa: o posto cobra por senha de atendimento e quem nao paga espera o dia inteiro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'analise', TRUE, 80, 'high', 'Alta', 'BAIXA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-14 23:14:25', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90051');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90026', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.529138, -46.873435', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8817. Coordenada informada pelo aparelho: -23.529138, -46.873435. Bateria do aparelho em 78%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-16 00:43:37', TIMESTAMP '2026-04-21 13:45:32', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90026');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90027', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.529138, -46.873435', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8817. Coordenada informada pelo aparelho: -23.529138, -46.873435. Bateria do aparelho em 78%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-16 00:46:17', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90027');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90032', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.502191, -46.893715', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8812. Coordenada informada pelo aparelho: -23.502191, -46.893715. Bateria do aparelho em 14%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-16 23:26:16', TIMESTAMP '2026-04-24 10:01:18', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90032');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90007', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.505891, -46.891161', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8823. Coordenada informada pelo aparelho: -23.505891, -46.891161. Bateria do aparelho em 30%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-19 13:14:09', TIMESTAMP '2026-04-25 19:29:59', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90007');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90064', 'discriminacao', 'Barueri, SP', 'SP', 'Barueri', 'UBS Central de Barueri', 'Registro feito em totem de atendimento publico, em UBS Central de Barueri. Relato da pessoa: meu filho e o unico negro da turma e o professor o trata diferente todo dia Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'recebida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-19 18:46:20', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90064');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90022', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.514919, -46.856703', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.514919, -46.856703. Bateria do aparelho em 64%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-20 08:36:11', TIMESTAMP '2026-05-03 23:05:56', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90022');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90015', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.519861, -46.866587', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.519861, -46.866587. Bateria do aparelho em 74%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-21 10:50:49', TIMESTAMP '2026-04-25 10:52:15', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90015');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90010', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.493224, -46.867712', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8817. Coordenada informada pelo aparelho: -23.493224, -46.867712. Bateria do aparelho em 45%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-21 14:06:15', TIMESTAMP '2026-04-25 13:31:41', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90010');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90012', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.502003, -46.873422', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.502003, -46.873422. Bateria do aparelho em 56%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-22 11:44:18', TIMESTAMP '2026-04-26 18:28:56', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90012');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90025', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.510507, -46.863805', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8831. Coordenada informada pelo aparelho: -23.510507, -46.863805. Bateria do aparelho em 58%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-22 16:18:39', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90025');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90044', 'discriminacao', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: meu filho e o unico negro da turma e o professor o trata diferente todo dia Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-22 20:42:23', TIMESTAMP '2026-04-28 00:15:30', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90044');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90017', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.522242, -46.888176', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8823. Coordenada informada pelo aparelho: -23.522242, -46.888176. Bateria do aparelho em 78%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-23 07:55:07', TIMESTAMP '2026-04-28 10:33:31', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90017');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90018', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.522242, -46.888176', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8823. Coordenada informada pelo aparelho: -23.522242, -46.888176. Bateria do aparelho em 78%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-23 07:57:20', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90018');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90040', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Permanencia dentro do perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4502. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'analise', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-24 07:49:11', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90040');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90003', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.509459, -46.884370', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8831. Coordenada informada pelo aparelho: -23.509459, -46.884370. Bateria do aparelho em 40%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-24 09:48:18', TIMESTAMP '2026-05-05 00:03:39', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90003');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90004', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.520811, -46.877979', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8817. Coordenada informada pelo aparelho: -23.520811, -46.877979. Bateria do aparelho em 78%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-25 19:14:06', TIMESTAMP '2026-04-30 14:01:37', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90004');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90062', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'UBS Central de Barueri', 'Registro feito em totem de atendimento publico, em UBS Central de Barueri. Relato da pessoa: meu vizinho bate na esposa toda semana e ontem ouvi ela gritando por socorro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-25 22:29:58', TIMESTAMP '2026-04-29 08:29:00', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90062');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90013', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.527121, -46.859377', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8831. Coordenada informada pelo aparelho: -23.527121, -46.859377. Bateria do aparelho em 34%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-26 16:02:07', TIMESTAMP '2026-04-29 19:04:59', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90013');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90014', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.527121, -46.859377', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8831. Coordenada informada pelo aparelho: -23.527121, -46.859377. Bateria do aparelho em 34%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-26 16:05:04', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90014');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90016', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.506090, -46.886147', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8823. Coordenada informada pelo aparelho: -23.506090, -46.886147. Bateria do aparelho em 61%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-26 21:01:01', TIMESTAMP '2026-04-28 10:04:22', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90016');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90011', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.496800, -46.869264', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.496800, -46.869264. Bateria do aparelho em 56%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'recebida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-27 10:26:22', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90011');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90009', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.524786, -46.859830', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8823. Coordenada informada pelo aparelho: -23.524786, -46.859830. Bateria do aparelho em 82%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-27 19:33:52', TIMESTAMP '2026-05-01 14:42:59', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90009');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90045', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: meu vizinho bate na esposa toda semana e ontem ouvi ela gritando por socorro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-27 22:07:05', TIMESTAMP '2026-05-09 12:26:45', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90045');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90035', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Permanencia dentro do perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4488. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'concluida', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-30 08:24:28', TIMESTAMP '2026-05-07 17:44:37', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90035');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90008', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.504321, -46.861554', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8812. Coordenada informada pelo aparelho: -23.504321, -46.861554. Bateria do aparelho em 59%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-30 18:44:12', TIMESTAMP '2026-05-03 00:48:31', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90008');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90050', 'discriminacao', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: fui recusada no atendimento por causa da minha religiao e ninguem explicou Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-30 19:05:18', TIMESTAMP '2026-05-06 16:54:15', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90050');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90043', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Permanencia dentro do perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4502. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'concluida', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-04-30 21:51:52', TIMESTAMP '2026-05-08 19:48:01', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90043');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90024', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.521747, -46.887235', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.521747, -46.887235. Bateria do aparelho em 30%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-01 01:58:33', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90024');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90056', 'assedio', 'Barueri, SP', 'SP', 'Barueri', 'UBS Central de Barueri', 'Registro feito em totem de atendimento publico, em UBS Central de Barueri. Relato da pessoa: um homem me segue na saida do turno da noite ha duas semanas Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-01 18:18:32', TIMESTAMP '2026-05-03 21:38:41', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90056');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90029', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.525971, -46.893956', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8812. Coordenada informada pelo aparelho: -23.525971, -46.893956. Bateria do aparelho em 46%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-02 00:12:12', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90029');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90030', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.525971, -46.893956', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8812. Coordenada informada pelo aparelho: -23.525971, -46.893956. Bateria do aparelho em 46%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-02 00:14:33', TIMESTAMP '2026-05-06 08:08:18', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90030');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90021', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.499492, -46.883989', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8812. Coordenada informada pelo aparelho: -23.499492, -46.883989. Bateria do aparelho em 37%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-02 11:26:44', TIMESTAMP '2026-05-05 08:54:05', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90021');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90049', 'assedio', 'Barueri, SP', 'SP', 'Barueri', 'CRAS Vila Boa Vista', 'Registro feito em totem de atendimento publico, em CRAS Vila Boa Vista. Relato da pessoa: um homem me segue na saida do turno da noite ha duas semanas Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-03 17:31:05', TIMESTAMP '2026-05-14 17:15:14', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90049');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90042', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Permanencia dentro do perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4488. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'concluida', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-03 18:07:13', TIMESTAMP '2026-05-08 17:41:17', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90042');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90037', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Entrada no perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4502. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'concluida', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-05 00:37:28', TIMESTAMP '2026-05-10 11:06:44', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90037');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90053', 'outros', 'Barueri, SP', 'SP', 'Barueri', 'CRAS Vila Boa Vista', 'Registro feito em totem de atendimento publico, em CRAS Vila Boa Vista. Relato da pessoa: o posto cobra por senha de atendimento e quem nao paga espera o dia inteiro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'BAIXA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-06 14:53:53', TIMESTAMP '2026-05-12 10:17:24', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90053');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90047', 'discriminacao', 'Barueri, SP', 'SP', 'Barueri', 'CRAS Vila Boa Vista', 'Registro feito em totem de atendimento publico, em CRAS Vila Boa Vista. Relato da pessoa: fui recusada no atendimento por causa da minha religiao e ninguem explicou Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-06 22:52:20', TIMESTAMP '2026-05-17 18:41:46', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90047');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90019', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.510358, -46.868280', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.510358, -46.868280. Bateria do aparelho em 27%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'analise', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-07 00:31:48', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90019');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90061', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'CRAS Vila Boa Vista', 'Registro feito em totem de atendimento publico, em CRAS Vila Boa Vista. Relato da pessoa: meu vizinho bate na esposa toda semana e ontem ouvi ela gritando por socorro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-07 17:30:12', TIMESTAMP '2026-05-11 16:55:38', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90061');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90058', 'outros', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: o posto cobra por senha de atendimento e quem nao paga espera o dia inteiro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'BAIXA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-08 15:51:32', TIMESTAMP '2026-05-17 01:05:56', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90058');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90065', 'outros', 'Barueri, SP', 'SP', 'Barueri', 'UBS Central de Barueri', 'Registro feito em totem de atendimento publico, em UBS Central de Barueri. Relato da pessoa: o posto cobra por senha de atendimento e quem nao paga espera o dia inteiro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'BAIXA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-08 18:40:37', TIMESTAMP '2026-05-17 07:05:05', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90065');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90063', 'outros', 'Barueri, SP', 'SP', 'Barueri', 'UBS Central de Barueri', 'Registro feito em totem de atendimento publico, em UBS Central de Barueri. Relato da pessoa: o posto cobra por senha de atendimento e quem nao paga espera o dia inteiro Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'BAIXA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-09 20:17:29', TIMESTAMP '2026-05-15 17:08:50', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90063');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90048', 'assedio', 'Barueri, SP', 'SP', 'Barueri', 'CRAS Vila Boa Vista', 'Registro feito em totem de atendimento publico, em CRAS Vila Boa Vista. Relato da pessoa: meu chefe faz comentarios sobre meu corpo toda vez que passa pela minha mesa Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'analise', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-09 22:27:11', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90048');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90060', 'assedio', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: meu chefe faz comentarios sobre meu corpo toda vez que passa pela minha mesa Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'analise', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-11 18:44:53', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90060');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90036', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Entrada no perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4471. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'concluida', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-12 07:43:16', TIMESTAMP '2026-05-16 21:24:04', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90036');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90038', 'violencia', 'Barueri, SP', 'SP', 'Barueri', NULL, 'Descumprimento de medida protetiva detectado agora por monitoracao eletronica. Permanencia dentro do perimetro de exclusao. Processo 0007441-88.2026, equipamento TZ-4471. Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.', 'analise', TRUE, 70, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-13 12:09:54', NULL, FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90038');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90054', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: ele me empurrou na frente das criancas e disse que ia voltar hoje a noite Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'ALTA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-13 15:22:18', TIMESTAMP '2026-05-25 06:05:01', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90054');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90046', 'discriminacao', 'Barueri, SP', 'SP', 'Barueri', 'Terminal Rodoviario de Barueri', 'Registro feito em totem de atendimento publico, em Terminal Rodoviario de Barueri. Relato da pessoa: meu filho e o unico negro da turma e o professor o trata diferente todo dia Registro anonimo por natureza do equipamento: o totem nao pede identificacao.', 'concluida', TRUE, 80, 'high', 'Alta', 'MEDIA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-13 23:38:24', TIMESTAMP '2026-05-17 02:44:09', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90046');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90005', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.517290, -46.888411', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.517290, -46.888411. Bateria do aparelho em 74%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-14 15:34:34', TIMESTAMP '2026-05-23 20:45:36', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90005');
INSERT INTO denuncia (protocolo, tipo, localidade, estado, cidade, endereco, descricao, status, anonimo, score, score_label, score_txt, urgencia_ia, resumo_ia, origem_analise, criado_em, concluida_em, excluida)
SELECT '#2026-90006', 'violencia', 'Barueri, SP', 'SP', 'Barueri', 'Coordenada aproximada -23.517290, -46.888411', 'Pedido de socorro enviado agora por botao de panico fisico. Dispositivo SOS-8840. Coordenada informada pelo aparelho: -23.517290, -46.888411. Bateria do aparelho em 74%. Acionamento sem texto: a pessoa nao teve condicao de escrever.', 'concluida', TRUE, 80, 'high', 'Alta', 'CRITICA', 'Caso aberto por dispositivo de campo; classificacao por regras explicaveis.', 'REGRAS', TIMESTAMP '2026-05-14 15:37:00', TIMESTAMP '2026-05-18 18:11:04', FALSE
WHERE NOT EXISTS (SELECT 1 FROM denuncia x WHERE x.protocolo = '#2026-90006');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.488524, -46.853527, 69, TIMESTAMP '2026-04-02 16:35:03', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-02 16:35:03');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.497262, -46.89986, 35, TIMESTAMP '2026-04-03 00:18:09', 'ACEITO', '#2026-90034', 'Entrada no perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-03 00:18:09');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-03 17:06:43', 'ACEITO', '#2026-90052', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-03 17:06:43');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-04 17:30:51', 'ACEITO', '#2026-90059', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-04 17:30:51');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-04 17:50:09', 'ACEITO', '#2026-90055', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia ALTA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-04 17:50:09');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.480623, -46.852899, 52, TIMESTAMP '2026-04-05 03:47:15', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-05 03:47:15');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.493361, -46.903242, 28, TIMESTAMP '2026-04-06 11:36:37', 'ACEITO', '#2026-90041', 'Permanencia dentro do perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-06 11:36:37');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.49349, -46.872952, 68, TIMESTAMP '2026-04-06 18:57:29', 'ACEITO', '#2026-90031', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-06 18:57:29');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.506058, -46.856359, 78, TIMESTAMP '2026-04-07 19:05:06', 'ACEITO', '#2026-90023', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-07 19:05:06');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.506058, -46.856359, 78, TIMESTAMP '2026-04-07 19:05:11', 'DUPLICADO', '#2026-90023', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-07 19:05:11');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.482235, -46.882788, 60, TIMESTAMP '2026-04-08 13:57:08', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-08 13:57:08');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.515158, -46.866988, 41, TIMESTAMP '2026-04-08 16:32:43', 'ACEITO', '#2026-90001', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-08 16:32:43');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.515158, -46.866988, 39, TIMESTAMP '2026-04-08 16:34:59', 'ACEITO', '#2026-90002', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-08 16:34:59');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.512566, -46.870659, 53, TIMESTAMP '2026-04-09 15:24:49', 'ACEITO', '#2026-90020', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-09 15:24:49');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.512566, -46.870659, 51, TIMESTAMP '2026-04-09 15:24:57', 'DUPLICADO', '#2026-90020', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-09 15:24:57');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.500453, -46.894581, 92, TIMESTAMP '2026-04-09 20:26:08', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-09 20:26:08');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.516429, -46.899413, 56, TIMESTAMP '2026-04-10 06:00:04', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-10 06:00:04');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.492024, -46.890611, 36, TIMESTAMP '2026-04-10 17:13:00', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-10 17:13:00');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.531445, -46.880341, 21, TIMESTAMP '2026-04-10 18:25:50', 'ACEITO', '#2026-90039', 'Entrada no perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-10 18:25:50');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.502886, -46.896386, 66, TIMESTAMP '2026-04-11 00:41:09', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-11 00:41:09');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.494225, -46.87092, 43, TIMESTAMP '2026-04-11 10:44:32', 'ACEITO', '#2026-90028', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-11 10:44:32');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.493182, -46.854011, 27, TIMESTAMP '2026-04-11 20:34:57', 'ACEITO', '#2026-90033', 'Entrada no perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-04-11 20:34:57');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-001', -23.5106, -46.8761, NULL, TIMESTAMP '2026-04-12 17:23:57', 'ACEITO', '#2026-90057', 'Registro em totem UBS Central de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-001' AND y.recebido_em = TIMESTAMP '2026-04-12 17:23:57');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-004', -23.5052, -46.8703, NULL, TIMESTAMP '2026-04-14 23:14:25', 'ACEITO', '#2026-90051', 'Registro em totem CRAS Vila Boa Vista; caso aberto com urgencia BAIXA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-004' AND y.recebido_em = TIMESTAMP '2026-04-14 23:14:25');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.521584, -46.884813, 60, TIMESTAMP '2026-04-15 18:33:29', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-04-15 18:33:29');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.529138, -46.873435, 78, TIMESTAMP '2026-04-16 00:43:37', 'ACEITO', '#2026-90026', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-16 00:43:37');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.529138, -46.873435, 76, TIMESTAMP '2026-04-16 00:46:17', 'ACEITO', '#2026-90027', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-16 00:46:17');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.484305, -46.849832, 33, TIMESTAMP '2026-04-16 01:08:54', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-04-16 01:08:54');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8812', -23.502191, -46.893715, 14, TIMESTAMP '2026-04-16 23:26:16', 'ACEITO', '#2026-90032', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8812' AND y.recebido_em = TIMESTAMP '2026-04-16 23:26:16');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8812', -23.502191, -46.893715, 14, TIMESTAMP '2026-04-16 23:26:27', 'DUPLICADO', '#2026-90032', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8812' AND y.recebido_em = TIMESTAMP '2026-04-16 23:26:27');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.507891, -46.879121, 66, TIMESTAMP '2026-04-18 11:44:00', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-18 11:44:00');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.505891, -46.891161, 30, TIMESTAMP '2026-04-19 13:14:09', 'ACEITO', '#2026-90007', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-19 13:14:09');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.505891, -46.891161, 30, TIMESTAMP '2026-04-19 13:14:19', 'DUPLICADO', '#2026-90007', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-19 13:14:19');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-001', -23.5106, -46.8761, NULL, TIMESTAMP '2026-04-19 18:46:20', 'ACEITO', '#2026-90064', 'Registro em totem UBS Central de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-001' AND y.recebido_em = TIMESTAMP '2026-04-19 18:46:20');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-003', NULL, NULL, NULL, TIMESTAMP '2026-04-19 18:46:55', 'DESCARTADO', NULL, 'Totem desconhecido ou desativado'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-003' AND y.recebido_em = TIMESTAMP '2026-04-19 18:46:55');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.514919, -46.856703, 64, TIMESTAMP '2026-04-20 08:36:11', 'ACEITO', '#2026-90022', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-20 08:36:11');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.514919, -46.856703, 62, TIMESTAMP '2026-04-20 08:37:53', 'DUPLICADO', '#2026-90022', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-20 08:37:53');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.519861, -46.866587, 74, TIMESTAMP '2026-04-21 10:50:49', 'ACEITO', '#2026-90015', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-21 10:50:49');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.519861, -46.866587, 74, TIMESTAMP '2026-04-21 10:51:56', 'DUPLICADO', '#2026-90015', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-21 10:51:56');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.493224, -46.867712, 45, TIMESTAMP '2026-04-21 14:06:15', 'ACEITO', '#2026-90010', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-21 14:06:15');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.502003, -46.873422, 56, TIMESTAMP '2026-04-22 11:44:18', 'ACEITO', '#2026-90012', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-22 11:44:18');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8831', -23.510507, -46.863805, 58, TIMESTAMP '2026-04-22 16:18:39', 'ACEITO', '#2026-90025', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8831' AND y.recebido_em = TIMESTAMP '2026-04-22 16:18:39');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-22 19:06:02', 'DESCARTADO', NULL, 'Relato com menos de 15 caracteres'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-22 19:06:02');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-22 20:42:23', 'ACEITO', '#2026-90044', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-22 20:42:23');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-22 23:26:23', 'DESCARTADO', NULL, 'Relato com menos de 15 caracteres'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-22 23:26:23');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.493123, -46.846897, 27, TIMESTAMP '2026-04-23 06:22:28', 'DUPLICADO', NULL, 'Violacao ja alertada ha menos de 600s'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-23 06:22:28');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.522242, -46.888176, 78, TIMESTAMP '2026-04-23 07:55:07', 'ACEITO', '#2026-90017', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-23 07:55:07');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.522242, -46.888176, 78, TIMESTAMP '2026-04-23 07:57:20', 'ACEITO', '#2026-90018', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-23 07:57:20');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.53655, -46.877277, 32, TIMESTAMP '2026-04-24 07:49:11', 'ACEITO', '#2026-90040', 'Permanencia dentro do perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-04-24 07:49:11');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8831', -23.509459, -46.88437, 40, TIMESTAMP '2026-04-24 09:48:18', 'ACEITO', '#2026-90003', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8831' AND y.recebido_em = TIMESTAMP '2026-04-24 09:48:18');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.523187, -46.87583, 57, TIMESTAMP '2026-04-24 18:21:57', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-24 18:21:57');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-003', NULL, NULL, NULL, TIMESTAMP '2026-04-24 18:57:39', 'DESCARTADO', NULL, 'Totem desconhecido ou desativado'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-003' AND y.recebido_em = TIMESTAMP '2026-04-24 18:57:39');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.506218, -46.901994, 94, TIMESTAMP '2026-04-25 13:09:02', 'DUPLICADO', NULL, 'Violacao ja alertada ha menos de 600s'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-04-25 13:09:02');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.513667, -46.887298, 60, TIMESTAMP '2026-04-25 18:46:06', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-04-25 18:46:06');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8817', -23.520811, -46.877979, 78, TIMESTAMP '2026-04-25 19:14:06', 'ACEITO', '#2026-90004', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8817' AND y.recebido_em = TIMESTAMP '2026-04-25 19:14:06');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-001', -23.5106, -46.8761, NULL, TIMESTAMP '2026-04-25 22:29:58', 'ACEITO', '#2026-90062', 'Registro em totem UBS Central de Barueri; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-001' AND y.recebido_em = TIMESTAMP '2026-04-25 22:29:58');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.493175, -46.891065, 58, TIMESTAMP '2026-04-26 13:42:14', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-26 13:42:14');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8831', -23.527121, -46.859377, 34, TIMESTAMP '2026-04-26 16:02:07', 'ACEITO', '#2026-90013', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8831' AND y.recebido_em = TIMESTAMP '2026-04-26 16:02:07');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8831', -23.527121, -46.859377, 34, TIMESTAMP '2026-04-26 16:05:04', 'ACEITO', '#2026-90014', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8831' AND y.recebido_em = TIMESTAMP '2026-04-26 16:05:04');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.50609, -46.886147, 61, TIMESTAMP '2026-04-26 21:01:01', 'ACEITO', '#2026-90016', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-26 21:01:01');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.4968, -46.869264, 56, TIMESTAMP '2026-04-27 10:26:22', 'ACEITO', '#2026-90011', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-27 10:26:22');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.4968, -46.869264, 54, TIMESTAMP '2026-04-27 10:27:16', 'DUPLICADO', '#2026-90011', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-04-27 10:27:16');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8823', -23.524786, -46.85983, 82, TIMESTAMP '2026-04-27 19:33:52', 'ACEITO', '#2026-90009', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8823' AND y.recebido_em = TIMESTAMP '2026-04-27 19:33:52');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-27 22:07:05', 'ACEITO', '#2026-90045', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-27 22:07:05');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.486513, -46.867665, 39, TIMESTAMP '2026-04-29 20:01:52', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-04-29 20:01:52');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.48734, -46.891276, 98, TIMESTAMP '2026-04-30 08:24:28', 'ACEITO', '#2026-90035', 'Permanencia dentro do perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-04-30 08:24:28');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8812', -23.504321, -46.861554, 59, TIMESTAMP '2026-04-30 18:44:12', 'ACEITO', '#2026-90008', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8812' AND y.recebido_em = TIMESTAMP '2026-04-30 18:44:12');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-04-30 19:05:18', 'ACEITO', '#2026-90050', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-04-30 19:05:18');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.483825, -46.861754, 91, TIMESTAMP '2026-04-30 21:51:52', 'ACEITO', '#2026-90043', 'Permanencia dentro do perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-04-30 21:51:52');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.521747, -46.887235, 30, TIMESTAMP '2026-05-01 01:58:33', 'ACEITO', '#2026-90024', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-05-01 01:58:33');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-001', -23.5106, -46.8761, NULL, TIMESTAMP '2026-05-01 18:18:32', 'ACEITO', '#2026-90056', 'Registro em totem UBS Central de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-001' AND y.recebido_em = TIMESTAMP '2026-05-01 18:18:32');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8812', -23.525971, -46.893956, 46, TIMESTAMP '2026-05-02 00:12:12', 'ACEITO', '#2026-90029', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8812' AND y.recebido_em = TIMESTAMP '2026-05-02 00:12:12');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8812', -23.525971, -46.893956, 45, TIMESTAMP '2026-05-02 00:14:33', 'ACEITO', '#2026-90030', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8812' AND y.recebido_em = TIMESTAMP '2026-05-02 00:14:33');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.535587, -46.873559, 22, TIMESTAMP '2026-05-02 07:53:17', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-02 07:53:17');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.504002, -46.902336, 43, TIMESTAMP '2026-05-02 11:21:31', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-05-02 11:21:31');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8812', -23.499492, -46.883989, 37, TIMESTAMP '2026-05-02 11:26:44', 'ACEITO', '#2026-90021', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8812' AND y.recebido_em = TIMESTAMP '2026-05-02 11:26:44');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8812', -23.499492, -46.883989, 35, TIMESTAMP '2026-05-02 11:27:45', 'DUPLICADO', '#2026-90021', 'Repique dentro de 120s do acionamento anterior; vinculado ao mesmo caso'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8812' AND y.recebido_em = TIMESTAMP '2026-05-02 11:27:45');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.504979, -46.864236, 22, TIMESTAMP '2026-05-03 01:38:04', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-03 01:38:04');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-004', -23.5052, -46.8703, NULL, TIMESTAMP '2026-05-03 17:31:05', 'ACEITO', '#2026-90049', 'Registro em totem CRAS Vila Boa Vista; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-004' AND y.recebido_em = TIMESTAMP '2026-05-03 17:31:05');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.516753, -46.900584, 20, TIMESTAMP '2026-05-03 18:07:13', 'ACEITO', '#2026-90042', 'Permanencia dentro do perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-03 18:07:13');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.486957, -46.88272, 67, TIMESTAMP '2026-05-04 04:02:28', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-05-04 04:02:28');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.519156, -46.892206, 39, TIMESTAMP '2026-05-05 00:37:28', 'ACEITO', '#2026-90037', 'Entrada no perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-05-05 00:37:28');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.494232, -46.905935, 26, TIMESTAMP '2026-05-05 03:16:30', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-05 03:16:30');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-003', NULL, NULL, NULL, TIMESTAMP '2026-05-05 23:41:05', 'DESCARTADO', NULL, 'Totem desconhecido ou desativado'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-003' AND y.recebido_em = TIMESTAMP '2026-05-05 23:41:05');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.490797, -46.904774, 28, TIMESTAMP '2026-05-06 09:53:35', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-06 09:53:35');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-004', -23.5052, -46.8703, NULL, TIMESTAMP '2026-05-06 14:53:53', 'ACEITO', '#2026-90053', 'Registro em totem CRAS Vila Boa Vista; caso aberto com urgencia BAIXA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-004' AND y.recebido_em = TIMESTAMP '2026-05-06 14:53:53');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-004', -23.5052, -46.8703, NULL, TIMESTAMP '2026-05-06 22:52:20', 'ACEITO', '#2026-90047', 'Registro em totem CRAS Vila Boa Vista; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-004' AND y.recebido_em = TIMESTAMP '2026-05-06 22:52:20');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.510358, -46.86828, 27, TIMESTAMP '2026-05-07 00:31:48', 'ACEITO', '#2026-90019', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-05-07 00:31:48');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4502', -23.535526, -46.871638, 41, TIMESTAMP '2026-05-07 01:28:38', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4502' AND y.recebido_em = TIMESTAMP '2026-05-07 01:28:38');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-004', -23.5052, -46.8703, NULL, TIMESTAMP '2026-05-07 17:30:12', 'ACEITO', '#2026-90061', 'Registro em totem CRAS Vila Boa Vista; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-004' AND y.recebido_em = TIMESTAMP '2026-05-07 17:30:12');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.507931, -46.883256, 65, TIMESTAMP '2026-05-08 09:26:11', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-08 09:26:11');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-05-08 15:51:32', 'ACEITO', '#2026-90058', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia BAIXA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-05-08 15:51:32');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-001', -23.5106, -46.8761, NULL, TIMESTAMP '2026-05-08 18:40:37', 'ACEITO', '#2026-90065', 'Registro em totem UBS Central de Barueri; caso aberto com urgencia BAIXA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-001' AND y.recebido_em = TIMESTAMP '2026-05-08 18:40:37');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.491626, -46.855905, 30, TIMESTAMP '2026-05-09 11:36:12', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-09 11:36:12');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-001', -23.5106, -46.8761, NULL, TIMESTAMP '2026-05-09 20:17:29', 'ACEITO', '#2026-90063', 'Registro em totem UBS Central de Barueri; caso aberto com urgencia BAIXA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-001' AND y.recebido_em = TIMESTAMP '2026-05-09 20:17:29');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-004', -23.5052, -46.8703, NULL, TIMESTAMP '2026-05-09 22:27:11', 'ACEITO', '#2026-90048', 'Registro em totem CRAS Vila Boa Vista; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-004' AND y.recebido_em = TIMESTAMP '2026-05-09 22:27:11');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.524941, -46.883922, 94, TIMESTAMP '2026-05-10 03:29:55', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-05-10 03:29:55');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-05-11 18:44:53', 'ACEITO', '#2026-90060', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-05-11 18:44:53');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.522635, -46.866685, 20, TIMESTAMP '2026-05-12 07:43:16', 'ACEITO', '#2026-90036', 'Entrada no perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-05-12 07:43:16');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-003', NULL, NULL, NULL, TIMESTAMP '2026-05-12 21:25:47', 'DESCARTADO', NULL, 'Totem desconhecido ou desativado'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-003' AND y.recebido_em = TIMESTAMP '2026-05-12 21:25:47');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4471', -23.496665, -46.860223, 93, TIMESTAMP '2026-05-13 12:09:54', 'ACEITO', '#2026-90038', 'Permanencia dentro do perimetro de exclusao; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4471' AND y.recebido_em = TIMESTAMP '2026-05-13 12:09:54');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-05-13 15:22:18', 'ACEITO', '#2026-90054', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia ALTA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-05-13 15:22:18');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'TOTEM', 'TT-002', -23.5147, -46.8792, NULL, TIMESTAMP '2026-05-13 23:38:24', 'ACEITO', '#2026-90046', 'Registro em totem Terminal Rodoviario de Barueri; caso aberto com urgencia MEDIA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TT-002' AND y.recebido_em = TIMESTAMP '2026-05-13 23:38:24');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.51729, -46.888411, 74, TIMESTAMP '2026-05-14 15:34:34', 'ACEITO', '#2026-90005', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-05-14 15:34:34');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'SOS', 'SOS-8840', -23.51729, -46.888411, 72, TIMESTAMP '2026-05-14 15:37:00', 'ACEITO', '#2026-90006', 'Acionamento de botao de panico; caso aberto com urgencia CRITICA'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'SOS-8840' AND y.recebido_em = TIMESTAMP '2026-05-14 15:37:00');
INSERT INTO evento_iot (origem, dispositivo, latitude, longitude, bateria, recebido_em, situacao, protocolo_gerado, detalhe)
SELECT 'GEOFENCE', 'TZ-4488', -23.491309, -46.854131, 28, TIMESTAMP '2026-05-14 20:30:29', 'ACEITO', NULL, 'Fora do perimetro'
WHERE NOT EXISTS (SELECT 1 FROM evento_iot y WHERE y.dispositivo = 'TZ-4488' AND y.recebido_em = TIMESTAMP '2026-05-14 20:30:29');
