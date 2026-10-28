# Protege+ · Visão de Futuro: slides e roteiro do vídeo

Material de apoio para a apresentação (até 10 slides, em PDF) e para o vídeo (até 5 minutos, pitch e navegação real, YouTube não listado). Os números citados vêm do documento e dos arquivos de resultado no repositório.

O mesmo vídeo e os mesmos slides servem ao relatório final do Enterprise Challenge, que os cita como material complementar.

---

## Parte A. Os 10 slides

Os slides estão prontos, com a fala de cada um nas notas do apresentador. Para a entrega, exporte em PDF.

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

## Parte B. Roteiro do vídeo, com rima (alvo: 4min45s)

**Como a rima funciona aqui.** Cada bloco é falado de forma natural, com os números, e termina num **fecho de duas linhas que rimam** (em negrito). A rima fica só no fecho porque é ali que a ideia precisa grudar; se o roteiro inteiro rimasse, os números iam soar forçados e quem avalia perderia a informação técnica.

**Como falar o fecho.** Faça uma pausa curta antes, fale um pouco mais devagar e olhe para a câmera. Não cante: é uma frase de efeito, não um rap.

**Legenda:** 🎤 fala · 🖥️ o que aparece na tela · ⏱️ tempo acumulado.

### ⏱️ 0:00 a 0:20 · Slide 1, capa

🎤 Oi, eu sou o Gabriel Vasconcellos Gomes, RM 561601, e este é o Protege+, um canal de denúncia de violência doméstica para o poder público. Nesta fase, a pergunta foi uma só: esse sistema merece confiança? Porque…

**Um canal que protege tem que provar o que faz:
não basta prometer, tem que mostrar que é capaz.**

### ⏱️ 0:20 a 0:45 · Slide 2, o ponto de partida

🎤 Em 2025, o Brasil registrou 1.571 feminicídios e mais de 132 mil descumprimentos de medida protetiva. Num canal assim, um vazamento não é só um erro de TI: é o endereço de uma vítima na mão de quem a ameaça.

**Aqui, cada dado que vaza pode custar uma vida,
por isso cada linha de código tem que deixar a vítima protegida.**

### ⏱️ 0:45 a 1:05 · Slide 3, 26 falhas corrigidas

🎤 Comecei olhando o sistema como um atacante olharia, e achei 26 falhas. A pior: a senha do administrador estava no JavaScript público, à vista de qualquer um. Outra: as fotos de evidência guardavam o GPS do lugar onde a vítima estava. Tudo foi corrigido, e cada correção ganhou um teste: de 136 fomos para 217.

**Cada porta que eu fechei ganhou um teste pra vigiar:
se alguém abrir de novo, o teste falha e vai avisar.**

### ⏱️ 1:05 a 1:25 · Slide 4, tríade CIA

🎤 Cada controle protege um pilar da tríade. Confidencialidade protege a vida de quem denuncia. Integridade protege a prova. Disponibilidade protege a hora da emergência: se tudo cair, os números 190 e 180 continuam na tela.

**Sigilo pra quem fala, prova que não se altera,
e socorro na tela mesmo quando o sistema não opera.**

### ⏱️ 1:25 a 1:55 · Slide 5 e demonstração 1, ataques reais

🖥️ Terminal com `py seguranca\simular_ataques.py` rodando (acelere na edição) e, no fim, o relatório. Volte para o Slide 5 no fecho.

🎤 Mas defesa só vale depois de atacada. Este roteiro faz onze ataques contra a API de verdade: token falso de administrador, chute de protocolo pra achar a vítima, ransomware no backup. Onze de onze, bloqueados. Só que um exercício mostrou um limite: quando eu restauro um backup antigo, os últimos registros da trilha somem, e a verificação interna continua dizendo que está tudo intacto.

**Onze ataques, onze barrados, mas eu achei um buraco no caminho:
quem guarda a trilha não pode atestar a trilha sozinho.**

### ⏱️ 1:55 a 2:25 · Slide 6, redes

🎤 Na rede, separei o sistema em zonas: só o proxy fica exposto à internet; a API e o banco ficam lá dentro. O proxy exige HTTPS, e cada botão de pânico e cada tornozeleira tem um certificado próprio: um certificado pirata é recusado. Se a API cair, a pessoa recebe em 16 milissegundos os números 190 e 180. São 39 verificações, todas passando, e o teste ainda achou cinco defeitos que só lendo a configuração eu não tinha achado.

**Uma porta só pra rua, e crachá pra cada aparelho:
quem chega com crachá falso já leva o sinal vermelho.**

### ⏱️ 2:25 a 3:05 · Slide 7 e demonstração 2, painel

🖥️ Navegador: login como ADMIN ➜ aba **Estatística** (role pelos cartões, pelas correlações, pela regressão e pela projeção da equipe) ➜ aba **Auditoria** (card de backups).

🎤 O relatório estatístico agora ajuda a decidir. A gravidade do caso explica o prazo: cada ponto de gravidade encurta o atendimento em um dia e meio, com p menor que 0,001. O score de confiabilidade não prevê nada, então a recomendação é trocar por um score de risco baseado no formulário oficial, o FONAR. E a demanda projetada pede cinco pessoas, onde hoje tem três. Aqui na auditoria, os backups aparecem com o hash conferido.

**Número que não decide é só desenho no painel:
aqui cada achado vira uma ordem no papel.**

### ⏱️ 3:05 a 3:35 · Slide 8, por que blockchain

🎤 Lembra do buraco? Quem guarda a trilha não pode ser quem atesta que ela está completa. Comparei log interno, Diário Oficial e carimbo de tempo: só a blockchain dá uma lista pública, em ordem, que nunca volta atrás. Então escrevi um contrato em Solidity que guarda a impressão digital da trilha fora do servidor. E a foto entra misturada com um segredo, pro agressor não descobrir que ela virou prova.

**Na blockchain não vai nome, nem relato, nem endereço:
vai só a impressão digital, e dela ninguém volta pro começo.**

### ⏱️ 3:35 a 4:20 · Demonstração 3 e Slide 9, exercício C

🖥️ Terminal:
1. `npm run ancorar` ➜ checkpoint ancorado
2. `npm run provar` com a foto original ➜ "é a evidência, sem alteração"; com a foto editada ➜ "NÃO é a evidência"
3. O trecho já gravado do exercício C: restaurar o backup ➜ `npm run verificar` ➜ alerta em vermelho

Termine no Slide 9.

🎤 Olha a foto: a original é provada. Troquei um pixel, e ela é recusada. Agora, o exercício de antes: gero um backup, uma atendente abre três casos, a rotina ancora, e eu restauro o backup. A verificação interna diz: intacta. A blockchain diz: o registro 13 não existe mais.

**As três consultas sumiram do servidor, mas não da memória:
o servidor esqueceu, a blockchain guardou a história.**

### ⏱️ 4:20 a 4:50 · Slide 10, visão de futuro

🎤 Pra frente, o Protege+ pode virar serviço: uma empresa pública como a PRODESP opera, e vários órgãos usam, dividindo o custo. Os próximos passos são testar com usuárias reais, login gov.br com segundo fator, o score de risco e a ancoragem na Rede Blockchain Brasil. Nas fases anteriores, o texto prometia mais do que o código entregava. Nesta, a ordem foi outra.

**Primeiro o ataque, depois o texto. Primeiro a prova, depois a promessa.
Proteger quem denuncia é a única meta que interessa.** Obrigado.

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
