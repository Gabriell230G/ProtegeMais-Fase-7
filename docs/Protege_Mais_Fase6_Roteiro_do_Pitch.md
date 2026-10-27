# Protege+ · Fase 6 · roteiro do pitch

Gabriel Vasconcellos Gomes · RM 561601 · 2SIOA · FIAP, Enterprise Challenge, HackGov.

Vídeo publicado: https://youtu.be/FHOxDr-g8I8 (não listado).

Duração alvo: 4 min 40 s, dentro do limite de 5 minutos. O vídeo pede pitch **e** demonstração
da aplicação em funcionamento, com navegação real.

O mesmo roteiro está dentro da apresentação: abra o arquivo HTML e pressione **N** para ver as
notas do slide atual. **O** abre a visão geral, **P** imprime, setas navegam.

## Preparação antes de gravar

1. Subir o back-end: `.\build.cmd spring-boot:run` na pasta `backend`.
2. Subir o site: `python -m http.server 5500` na raiz do site.
3. Recarregar as páginas com Ctrl+Shift+R, para não demonstrar uma versão em cache.
4. Deixar o simulador e o painel em janelas lado a lado.
5. Abrir a apresentação em tela cheia numa terceira janela.

---

## Slide 01 · Capa

`0:00 · 0:25`

Tom baixo, sem pressa.

"Meu nome é Gabriel Vasconcellos Gomes, RM 561601, turma 2SIOA."

"Nas fases anteriores eu construí um canal de denúncias. Nesta fase eu descobri um pressuposto que ele nunca tinha examinado."

Pausa curta. Avançar.

---

## Slide 02 · O pressuposto não examinado

`0:25 · 0:55`

"O sistema inteiro repousava numa frase que eu nunca tinha examinado: alguém abre o canal, escolhe o tipo, escreve o relato e envia."

"Essa frase exclui três pessoas."

"Quem não pode digitar, porque está em risco agora. Quem não deveria precisar denunciar, porque já existe uma medida judicial que fixa distância e um equipamento que informa posição, e mesmo assim a tarefa de vigiar o agressor estava com a vítima. E quem não tem aparelho, ou tem um aparelho vigiado."

**Frase-chave:** "Não é um problema de tecnologia. É um problema de porta de entrada."

---

## Slide 03 · Um barramento, três origens

`0:55 · 1:20`

"A resposta foram três portas novas: um botão de pânico, uma tornozeleira com geofencing e um totem público."

"Mas as três desembocam no mesmo lugar. Uma tabela só, com um discriminador de origem. Um controlador só. Uma tela só."

"Isso é Single Table Inheritance, do Fowler. Eu pago colunas nulas por origem e compro duas coisas: a pergunta do gestor não precisa de união, e uma quarta origem amanhã é uma linha, não uma migração."

**Frase-chave:** "O aparelho relata, o servidor decide."

---

## Slide 04 · As regras do servidor

`1:20 · 2:00`

"Cada origem tem uma regra, e nenhuma delas é arbitrária."

"No botão de pânico, 120 segundos. Dois toques dentro disso são a mesma pessoa apertando de novo, não dois casos."

"Na tornozeleira, o perímetro é do servidor. O aparelho manda posição, e só. Ele nunca recebe o raio de volta, porque devolver a distância seria entregar um mapa do perímetro para quem está sendo monitorado."

"No totem, 20 segundos, seis vezes menos. A premissa inverte: numa fila, duas pessoas seguidas são duas pessoas."

Se perguntarem da chave: "comparação em tempo constante, e está declarado que ela não substitui certificado por aparelho."

---

## Slide 05 · Demonstração: o painel de campo

`2:00 · 3:00`

Aqui entra a demonstração ao vivo. Simulador e painel lado a lado.

Pânico: acionar duas vezes, mostrar o repique reconhecido.

Tornozeleira: 750 m, enviar. Sul, enviar. Sul de novo, violação. Dizer em voz alta que a resposta não traz distância nem raio, e por quê.

Totem: TT-001 aceito, TT-003 recusado.

Depois o painel. "Repara na última coluna. Ela não mostra um estado, mostra a decisão: abriu caso, foi repique, caiu fora do perímetro, totem desconhecido."

"E repara que evento fora do perímetro é aceito e não vira caso. O silêncio também é dado."

---

## Slide 06 · SQL: auditar a própria decisão

`3:00 · 3:35`

"Eu escolhi 120 segundos. E escolha minha é exatamente o tipo de coisa que precisa ser auditada."

"Essa consulta usa LAG para trazer o instante do acionamento anterior do mesmo aparelho. É a mesma pergunta que o código faz em tempo de execução, feita ao banco."

"Dos 35 intervalos, oito caem dentro da janela. Mas seis caem logo acima, entre 120 e 300 segundos. Seis contra oito é proporção alta demais para ignorar."

"Ou são ocorrências distintas de verdade, ou a janela está curta e a mesma pessoa está abrindo dois casos. Com este volume eu não consigo decidir, e eu prefiro dizer isso a inventar uma conclusão."

"O que a consulta entrega não é a resposta. É o instrumento que passa a medir a janela continuamente."

---

## Slide 07 · Estruturas de dados: o problema

`3:35 · 4:05`

"A última parte é estrutura de dados, e ela nasce de uma pergunta que o SQL não responde bem."

"Um GROUP BY me diz quantas denúncias Barueri teve. Ele não me diz se essas denúncias formam uma cadeia ou se estão espalhadas pelo ano."

"A regra que eu escrevi: duas denúncias se ligam quando são do mesmo tipo, do mesmo município e estão a no máximo 14 dias uma da outra. E a cadeia só conta a partir de três."

"Isso é um grafo. Então são quatro estruturas: árvore para recortar a janela, ordenação para pôr cada grupo em bloco, busca binária para achar o bloco e busca em largura para fechar os componentes."

---

## Slide 08 · O detalhe que muda o custo

`4:05 · 4:20`

Se houver tempo, este slide vale 15 segundos.

"Tem um detalhe que muda o custo. Dentro de um grupo já ordenado por data, eu só preciso ligar vizinhos. Se A liga com B e B liga com C, os três já estão juntos. A aresta de A para C é redundante."

"Isso derruba o grafo de k ao quadrado para k. Para 160 denúncias é a diferença entre 12 mil comparações e 159."

"E eu sou honesto no documento: com 160 as duas respondem em milissegundos. A razão da escolha não é velocidade hoje, é que a versão quadrática para de funcionar num volume que uma operação real alcança."

---

## Slide 09 · Foco não é volume

`4:20 · 4:45`

"Esse é o achado da fase, e ele só apareceu depois da tela pronta."

"O maior agrupamento era Barueri, violência, 49 denúncias. E o algoritmo estava certo, elas formam mesmo uma cadeia. O problema é que aquilo não era um surto. Era tudo que Barueri produz naquele tipo. Era a demanda normal do lugar."

"Um foco pede operação pontual. Demanda constante pede equipe permanente. São respostas diferentes, e a tela estava chamando as duas de foco."

"A correção foi nomear: cobertura acima de 70% e grupo com pelo menos 10 vira fluxo contínuo."

"O maior foco caiu de 49 para 7. E é esse 7 que é acionável."

---

## Slide 10 · Entrega, limites e links

`4:45 · 5:00`

Pausa. Olhar pra câmera.

"O canal deixou de esperar que a vítima digitasse. Agora ele também escuta o campo."

"São 136 testes, 38 endpoints, seis consultas e quatro estruturas de dados. E o que ficou de fora está escrito com o mesmo cuidado do que ficou dentro: não tem modo offline, a chave é por integração e não por aparelho, e o protocolo é texto e não chave estrangeira."

"Repositório e site estão no QR. Obrigado."

---
