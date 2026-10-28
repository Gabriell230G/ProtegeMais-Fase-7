# Protege+ · Visão de Futuro: slides e roteiro do vídeo

Material de apoio para a apresentação (até 10 slides, em PDF) e para o vídeo (até 5 minutos, pitch e navegação real, YouTube não listado). Os números citados vêm do documento e dos arquivos de resultado no repositório.

O mesmo vídeo e os mesmos slides servem ao relatório final do Enterprise Challenge, que os cita como material complementar.

---

## Parte A. Conteúdo de cada slide

Para o visual, use as cores do projeto: azul `#1A4DA0`, laranja `#F5A623`, verde `#4CAF50` e fundo claro `#EEF2F8`. Use pouco texto por slide: o detalhe fica na fala e no documento.

### Slide 1. Capa (obrigatório: nome, RM e foto)

- **Título:** Protege+ · Visão de Futuro
- **Subtítulo:** Segurança, redes, estatística e blockchain num canal de denúncia
- **Foto, nome e RM:** Gabriel Vasconcellos Gomes · RM 561601 · 2SIOA
- **Frase de rodapé:** "Um canal de denúncia é, antes de tudo, um problema de confiança."
- **Visual:** logo do Protege+ à esquerda e foto à direita.

### Slide 2. O problema e a pergunta

- **Número grande:** 1.571 feminicídios e 132.025 descumprimentos de medida protetiva em 2025 (Anuário 2026)
- **Frase:** "Aqui, um vazamento não é incidente de TI. É a localização de uma vítima nas mãos de quem a ameaça."
- **Pergunta da fase, em destaque:** O Protege+ merece a confiança de quem denuncia e de quem fiscaliza?
- **Visual:** quatro ícones pequenos com as quatro Partes (cadeado, rede, gráfico, bloco).

### Slide 3. Parte 1: o que a revisão encontrou

- **Título:** 26 falhas encontradas e corrigidas
- **Três exemplos, com "antes ➜ depois":**
  - A senha do ADMIN estava no JavaScript público ➜ nenhuma senha no cliente
  - O segredo dos tokens estava no repositório ➜ segredo sorteado; em produção, a API não sobe com segredo fraco
  - As fotos guardavam o GPS da vítima ➜ metadados removidos antes do hash
- **Rodapé com números:** testes 136 ➜ 218 · XSS: 44 pontos ➜ 0 · backup: não havia ➜ diário, verificado por hash

### Slide 4. Tríade CIA e políticas

Tabela 3 × 2:

| | O que protege | Principais controles |
|---|---|---|
| **Confidencialidade** | a vida de quem denuncia | perfis por rota, anonimato, EXIF removido, relato fora da IA, protocolo de 59 bits |
| **Integridade** | o valor de prova | relato imutável, máquina de estados, trilha SHA-256, blockchain |
| **Disponibilidade** | o momento da emergência | limites por origem, backup verificado, página de queda com 190 e 180 |

- **Rodapé:** Políticas de autenticação, criptografia, backup e acesso no documento, seção 2.4, cada regra com o arquivo que a implementa.

### Slide 5. Ataque simulado

- **Título:** "O agressor quer saber se foi denunciado, achar a vítima e apagar o rastro"
- **Número grande:** 11 ataques, 11 bloqueados, 0 falhas
- **Três exemplos curtos:**
  - Token falso de ADMIN ➜ 401
  - 40 protocolos chutados ➜ 0 achados
  - Ransomware no backup ➜ detectado e restaurado
- **Faixa de destaque, em laranja:** O exercício B achou um limite. Restaurar um backup corta o fim da trilha, e a verificação interna continua dizendo "intacta".
- **Visual:** print do relatório `seguranca/resultados/simulacao-*.md`.

### Slide 6. Parte 2: redes

- **Visual principal:** a topologia em zonas (Figura 1 do documento): Internet ➜ DMZ (proxy) ➜ aplicação ➜ dados, mais a rede de gestão por VPN.
- **À direita:** 39 verificações reais, 0 falhas.
  - HTTPS obrigatório, TLS 1.1 recusado
  - Cada aparelho com certificado próprio; um certificado "pirata" é recusado
  - API fora do ar ➜ resposta em 30 ms com 190 e 180
- **Rodapé:** O teste achou 5 defeitos que a leitura da configuração não achou.

### Slide 7. Parte 3: estatística para decidir

- **Visual:** print dos cartões de conclusão da aba Estatística.
- **Três achados grandes:**
  - A gravidade explica o prazo: r = −0,50, p < 0,001; cada ponto encurta 1,6 dia
  - O score de confiabilidade não prevê nada: r = −0,03, p = 0,76 ➜ trocar por score de risco (FONAR)
  - A demanda pede 5 pessoas; a equipe tem 3
- **Rodapé:** Toda conclusão vem com p-valor e intervalo de confiança. O cálculo foi conferido contra o quarteto de Anscombe.

### Slide 8. Parte 4: por que blockchain

- **Frase:** "Quem guarda a trilha não pode ser quem atesta que ela está completa."
- **Comparação em uma linha:** log interno, WORM, Diário Oficial, carimbo de tempo ➜ só a blockchain dá uma lista pública e ordenada que nunca volta atrás.
- **O que vai para a cadeia:** hashes e contadores. **O que nunca vai:** nome, relato, endereço, nem o hash puro da foto (que entra misturado a um sal).
- **Rodapé:** Rede indicada: RBB, a Rede Blockchain Brasil (BNDES e TCU).

### Slide 9. Exercício C: a blockchain pega o corte

- **Duas colunas, lado a lado:**
  - **Verificação interna:** "Cadeia intacta" ✅
  - **Verificação na blockchain:** "O registro 13 NÃO EXISTE MAIS" 🚨
- **Abaixo:** A foto original é provada; a mesma foto com 1 pixel trocado é recusada.
- **Rodapé:** contrato `AncoraProtege.sol`, 21 testes, 100% das linhas cobertas.

### Slide 10. Entrega e próximos passos

- **Números:** 93 classes · 44 endpoints · 218 + 21 testes · 11 ataques · 39 verificações de rede · 1 smart contract
- **Próximos passos:** score de risco FONAR · login gov.br com segundo fator · ancoragem horária na RBB · avaliação com usuárias reais
- **Links:** repositório, site e vídeo (QR code do repositório)
- **Frase final:** "Primeiro o ataque, depois o texto."

---

## Parte B. Roteiro do vídeo (alvo: 4min45s)

**Legenda:** 🎤 fala · 🖥️ o que aparece na tela · ⏱️ tempo acumulado.

### 0:00 a 0:20 · Slide 1

🎤 "Oi, eu sou o Gabriel Vasconcellos Gomes, RM 561601. Este é o Protege+, um canal de denúncia de violência doméstica para o poder público. Nesta fase, a pergunta foi uma só: esse sistema merece confiança?"

### 0:20 a 0:45 · Slide 2

🎤 "Em 2025, foram mais de 132 mil descumprimentos de medida protetiva. Num canal assim, um vazamento não é incidente de TI: é a localização de uma vítima nas mãos de quem a ameaça. Por isso eu tratei segurança, redes, estatística e blockchain como uma pergunta só."

### 0:45 a 1:15 · Slides 3 e 4

🎤 "Comecei olhando o sistema como um atacante olharia. Achei 26 falhas. A pior: a senha do administrador estava no JavaScript público. Outra: as fotos de evidência guardavam o GPS de onde a vítima estava. Tudo foi corrigido, e cada correção ganhou um teste: passamos de 136 para 218. Cada controle está ligado a um pilar da tríade: confidencialidade protege a vida, integridade protege a prova, disponibilidade protege a emergência."

### 1:15 a 1:50 · Demonstração 1: ataques reais (Slide 5 antes ou depois)

🖥️ Terminal com `py seguranca\simular_ataques.py` rodando (acelere na edição) e, no fim, o relatório em Markdown.

🎤 "Defesa só conta depois de atacada. Este roteiro faz onze ataques contra a API de verdade: token falso de administrador, força bruta com IP forjado, chute de protocolo para achar a vítima, ransomware no backup. Onze bloqueados. Mas um exercício revelou um limite: quando restauro um backup antigo, os últimos registros da trilha somem, e a verificação interna continua dizendo que está tudo intacto. Guarde isso."

### 1:50 a 2:20 · Slide 6: redes

🎤 "Na rede, separei o sistema em zonas: só o proxy fica exposto à internet. Montei esse proxy de verdade, com HTTPS obrigatório e certificado próprio para cada botão de pânico e tornozeleira. Um certificado pirata, copiando o nome de um aparelho real, é recusado. Se a API cair, a pessoa recebe em milissegundos os números 190 e 180, em vez de uma página travada. São 39 verificações, todas passando, e o teste ainda achou cinco defeitos que a leitura não tinha achado."

### 2:20 a 3:05 · Demonstração 2: painel (Slide 7 de apoio)

🖥️ Navegador: login como ADMIN ➜ aba **Estatística** ➜ role pelos cartões, pelas barras de correlação, pela regressão e pela projeção da equipe. Depois, aba **Auditoria** ➜ card de backups.

🎤 "O relatório estatístico agora decide. A gravidade do caso explica o prazo: cada ponto encurta um dia e meio, com p menor que 0,001. O score de confiabilidade, que existe desde a Fase 2, não prevê nada, e por isso a recomendação é trocá-lo por um score de risco baseado no formulário oficial, o FONAR. E a demanda projetada pede cinco pessoas onde hoje há três. Cada conclusão vem com a evidência e a decisão sugerida. Aqui na auditoria, os backups aparecem com o hash conferido."

### 3:05 a 4:20 · Slides 8 e 9 com a demonstração 3: blockchain

🖥️ Slide 8 por uns 15 segundos e, depois, o terminal:
1. `npm run ancorar` ➜ checkpoint ancorado
2. `npm run provar` com a foto original ➜ "é a evidência, sem alteração"; com a foto editada ➜ "NÃO é a evidência"
3. O trecho já gravado do exercício C: restaurar o backup ➜ `npm run verificar` ➜ alerta em vermelho

Por fim, o Slide 9.

🎤 "Lembra do limite? Quem guarda a trilha não pode ser quem atesta que ela está completa. Então escrevi um contrato em Solidity que guarda a impressão digital da trilha fora do servidor. Nada pessoal vai para a cadeia: só hashes, e a foto entra misturada a um segredo, para o agressor não conseguir descobrir que ela virou prova. Olha a foto: a original é provada. Mudei um pixel, e ela é recusada. Agora, o exercício de antes: gero um backup, uma atendente abre três casos, a rotina ancora, e eu restauro o backup. A verificação interna diz 'intacta'. A blockchain diz: o registro 13 não existe mais. As três consultas sumiram do servidor, mas não da história."

### 4:20 a 4:45 · Slide 10

🎤 "Foram 26 falhas corrigidas, 11 ataques, 39 verificações de rede, estatística que decide e um contrato inteligente com 21 testes. Os próximos passos são o score de risco, login gov.br e a ancoragem na Rede Blockchain Brasil. O padrão das fases anteriores era o documento prometer mais do que o código. Nesta fase, a ordem foi outra: primeiro o ataque, depois o texto. Obrigado."

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

**Na edição:** acelere os trechos de terminal (2x a 4x), mantenha a fala em velocidade normal e confira se o total ficou abaixo de 5:00. Suba no YouTube como **não listado** e cole o link no documento, nos slides e no README.
