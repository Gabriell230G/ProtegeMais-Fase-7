# Protege+ · Visão de Futuro: slides e roteiro do vídeo

Material de apoio para a apresentação (até 10 slides, em PDF) e para o vídeo (até 5 minutos, pitch e navegação real, YouTube não listado). Os números citados vêm do documento e dos arquivos de resultado no repositório.

O mesmo vídeo e os mesmos slides servem ao relatório final do Enterprise Challenge, que os cita como material complementar.

---

## Parte A. Os 10 slides

Os slides estão prontos, com a fala de cada um nas notas do apresentador (a mesma da Parte B). Para a entrega, exporte em PDF.

| # | Slide | Mensagem |
|---|---|---|
| 1 | Capa | Nome, RM, turma, foto e logo |
| 2 | O ponto de partida | 1.571 feminicídios e 132.025 descumprimentos de medida protetiva; a pergunta da fase |
| 3 | 26 falhas corrigidas | Três exemplos "antes ➜ depois"; testes 136 ➜ 217; XSS 44 ➜ 0; backup diário |
| 4 | Tríade CIA | Confidencialidade (14 falhas), integridade (13), disponibilidade (7) e seus controles |
| 5 | Ataque simulado | 11 de 11 bloqueados; o limite do exercício B |
| 6 | Redes | Topologia em zonas; 39 de 39 verificações; 190 e 180 em 16 ms |
| 7 | Estatística | r = −0,50 (gravidade); r = −0,03 (score); 5 pessoas para 3 vagas |
| 8 | Por que blockchain | As alternativas e por que não bastam; o que vai e o que nunca vai para a cadeia |
| 9 | Exercício C | Verificação interna "intacta" e blockchain "registro 13 não existe mais" |
| 10 | Visão de futuro | Horizontes, modelo de serviço, links do vídeo, do código e do site |

---

## Parte B. Roteiro do vídeo (alvo: 4min45s, cerca de 650 palavras)

**Como o roteiro funciona.** Três ideias da pesquisa sobre grandes oradores e sobre atenção em vídeo:

- ➜ **Uma pessoa antes do número.** O vídeo abre com a Ana, uma personagem fictícia (a legenda deixa isso claro), e ela volta no meio e no fim. Sem cena de violência: o medo dela é o endereço vazar, que é exatamente o que o sistema resolve.
- ➜ **Rima só nas três viradas.** A pergunta (abertura), o buraco (meio) e a prova (clímax). Rima em todo bloco vira trilha sonora e rouba tempo das pausas.
- ➜ **Um limite dito por você, depois das provas e com o próximo passo.** Para um avaliador atento, isso aumenta a confiança.

**Como falar.** "[pausa]" é um silêncio de 1 segundo; "[pausa longa]", de 2. Nos fechos em negrito: pausa antes, fala mais lenta, olho na lente. Decore de verdade só três trechos: o gancho (0:00), o momento do registro 13 (3:30) e as duas últimas frases.

**Legenda:** 🎤 fala · 🖥️ o que aparece na tela.

### 0:00 a 0:15 · Slide 1 (capa)

🖥️ Rosto na câmera sobre a capa. Legenda fixa: "Ana é uma personagem fictícia".

🎤 Pense na Ana, uma personagem criada para este vídeo. Ela quer denunciar quem a ameaça, mas tem medo de uma coisa: que o endereço dela vaze. Aqui, um vazamento não é um erro de TI: é o endereço da Ana na mão de quem a ameaça.

### 0:15 a 0:50 · Slide 2 (problema)

🖥️ Slide 2, com destaque no número 1.571.

🎤 E ela não é exceção: em 2025, o Brasil registrou 1.571 feminicídios, mais de quatro por dia. [pausa] Eu sou o Gabriel, e este é o Protege+, um canal de denúncia para o poder público. A pergunta desta fase foi uma só: esse canal merece confiança? Vou responder com três provas: um ataque, os números e a blockchain. [pausa]

**Um canal que protege tem que provar o que faz:
não basta prometer, tem que mostrar que é capaz.**

### 0:50 a 1:08 · Slide 3 (26 falhas)

🎤 Comecei olhando o sistema como um atacante olharia, e achei 26 falhas. A pior: a senha do administrador estava no JavaScript público. Outra: as fotos de evidência guardavam o GPS de onde a Ana estava. Tudo foi corrigido, e cada correção ganhou um teste que avisa se a falha voltar.

### 1:08 a 1:18 · Slide 4 (tríade CIA)

🎤 A confidencialidade protege a vida de quem denuncia. A integridade protege a prova. A disponibilidade protege a hora da emergência.

### 1:18 a 1:55 · Slide 5 e demonstração 1 (ataques reais)

🖥️ Terminal com `py seguranca\simular_ataques.py`, selo "2x" no canto quando acelerar, zoom no "11/11". Volte ao Slide 5 no fecho.

🎤 Mas defesa só vale depois de atacada. Este roteiro faz onze ataques de verdade: token falso de administrador, chute de protocolo para achar quem denunciou, ransomware no backup. Onze de onze, bloqueados. [pausa] Só que um exercício mostrou um limite: quando eu restauro um backup antigo, os últimos registros da trilha somem, e a verificação interna continua dizendo que está tudo intacto. [pausa]

**Onze ataques, onze barrados, mas eu achei um buraco no caminho:
quem guarda a trilha não pode atestar a trilha sozinho.**

### 1:55 a 2:20 · Slide 6 (redes)

🖥️ Slide 6 e um clipe de 5 segundos do site com a API parada mostrando o 190 e o 180.

🎤 Na rede, separei o sistema em zonas: só o proxy fica exposto à internet; a API e o banco ficam lá dentro. Cada botão de pânico e cada tornozeleira tem um crachá digital próprio, e crachá falso é barrado na porta. Se a API cair, em 16 milissegundos a tela mostra o 190 e o 180. São 39 verificações, todas passando.

### 2:20 a 2:47 · Slide 7 e demonstração 2 (painel)

🖥️ Navegador, login como ADMIN ➜ aba **Estatística**. Rosto pequeno no canto. Zoom nos cartões de conclusão.

🎤 No painel, a estatística vira decisão. A gravidade do caso explica o prazo: cada ponto de gravidade encurta o atendimento em um dia e meio. Já o score de confiabilidade não prevê nada, então a recomendação é trocar por um score de risco baseado no formulário oficial, o FONAR. E a demanda projetada pede cinco pessoas, onde hoje tem três.

### 2:47 a 3:17 · Slide 8 (por que blockchain)

🎤 Lembra do buraco? Quem guarda a trilha não pode ser quem atesta que ela está completa. Comparei log interno, Diário Oficial e carimbo de tempo: só a blockchain dá uma lista pública, em ordem, que nunca volta atrás. Então escrevi um contrato em Solidity que guarda a impressão digital da trilha fora do servidor. Na blockchain não vai nome, nem relato, nem endereço: só essa impressão digital, e dela ninguém volta para o dado.

### 3:17 a 4:00 · Demonstração 3 e Slide 9 (exercício C)

🖥️ Terminal: `npm run provar` com a foto original e depois com a editada. Depois, o trecho gravado do exercício C. No fim, "intacta" e "registro 13 não existe mais" lado a lado. Sem o rosto no canto.

🎤 Olha a foto: a original é provada. Troquei um pixel, e ela é recusada. [pausa] Agora, o exercício de antes: gero um backup, uma atendente abre três casos, a rotina ancora, e eu restauro o backup. A verificação interna diz: intacta. [pausa] A blockchain diz: o registro 13 não existe mais. [pausa longa]

**As três consultas sumiram do servidor, mas não da memória:
o servidor esqueceu, a blockchain guardou a história.**

### 4:00 a 4:12 · O limite

🖥️ Rosto na câmera, Slide 9 ao fundo.

🎤 Um limite, para ser honesto: hoje essa blockchain roda na minha máquina, em ambiente de teste. Levar a ancoragem para a Rede Blockchain Brasil é o próximo passo.

### 4:12 a 4:45 · Slide 10 (visão de futuro)

🎤 Pra frente, o Protege+ pode virar serviço: uma empresa pública como a PRODESP opera, e vários órgãos dividem o custo. Antes, vem o teste com usuárias reais. Com isso, quando a Ana denunciar, o endereço dela não vaza, a foto dela vira prova que ninguém altera e, se tudo cair, o 180 continua na tela.

🖥️ Rosto na câmera, olhando para a lente.

🎤 Nas fases anteriores, o texto prometia mais do que o código entregava. Nesta, a ordem foi outra. [pausa] **Primeiro o ataque, depois o texto. Primeiro a prova, depois a promessa.** [pausa] Obrigado.

### 4:45 a 4:52 · Cartão final, em silêncio

🖥️ "Precisa de ajuda? Ligue 180. Emergência: 190." e os links do código e do site. Repita o mesmo texto na descrição do vídeo no YouTube.

**Se passar de 4min45s**, corte nesta ordem: "a API e o banco ficam lá dentro" (redes), "Comparei log interno, Diário Oficial e carimbo de tempo" (blockchain) e "uma empresa pública como a PRODESP opera" (futuro). Nunca corte o gancho, o momento do registro 13 nem as duas últimas frases.

---

## Parte C. Preparação para gravar (Windows)

Faça um ensaio completo antes, porque o limite de login da API bloqueia novos logins por 1 minuto depois do ataque de força bruta.

**Terminal 1: a API**
```powershell
cd backend
.\build.cmd run
```

**Terminal 2: o site**
```powershell
py -m http.server 5500
```
Abra `http://localhost:5500` e atualize com Ctrl+Shift+R.

**Terminal 3: a blockchain local**
```powershell
cd blockchain
npm install      # só na primeira vez
npm run no
```

**Terminal 4: os comandos da gravação**
```powershell
# Demonstração 1: rode logo depois de subir a API e espere 1 minuto antes de logar no site
py seguranca\simular_ataques.py

# Demonstração 3
cd blockchain
npm run implantar
npm run ancorar
$env:ARQUIVO="C:\caminho\foto-baixada-do-sistema.jpg"; npm run provar
$env:ARQUIVO="C:\caminho\foto-editada.jpg"; $env:EVIDENCIA_ID="1"; npm run provar
```

**Foto para a demonstração.** Envie uma imagem qualquer (sem pessoa real) como evidência de uma denúncia de teste. Depois, baixe-a pelo painel como ADMIN e rode `npm run ancorar`. Para a versão "editada", abra a foto baixada no Paint, pinte um pixel e salve com outro nome.

**Exercício C (grave separado e corte na edição).**
1. Como ADMIN, gere um backup na aba Auditoria.
2. Abra três casos e rode `npm run ancorar`.
3. Pare a API (Ctrl+C) e, na pasta backend, rode `.\restaurar-backup.cmd data\backups\<nome do backup>.zip`.
4. Suba a API de novo e rode `npm run verificar`.

**Na edição:** acelere os trechos de terminal (2x a 4x), mantenha a fala em velocidade normal e confira se o total ficou abaixo de 5:00. Suba no YouTube como **não listado** e cole o link no documento, nos slides, no README e no site (botão **Assistir** e rodapé do `index.html`). Eu faço essa troca em todos os lugares de uma vez quando você me mandar o link.
