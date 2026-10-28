# Testes de navegador (Playwright)

Dois testes que abrem o Protege+ num navegador de verdade (Chromium) e conferem dois números citados no documento da Fase 7.

| Script | O que prova | Resultado esperado |
|---|---|---|
| `xss.js` | Nenhum código malicioso gravado nos dados consegue rodar no site | `pontos que executaram script: 0` (no código da Fase 6: `44`) |
| `painel.js` | O painel inteiro funciona por HTTPS atrás da borda nginx, sem quebrar a política de conteúdo (CSP) | 10 abas, todas as rotas da API com 200, 0 violações de CSP, 0 erros |

## Antes de começar

- Node.js 18 ou mais novo
- Dentro desta pasta, uma vez só:

```bash
cd testes-navegador
npm install
npx playwright install chromium
```

## 1. XSS: 44 pontos na Fase 6, 0 na Fase 7

### O que o teste faz

Grava denúncias, membros da equipe e respostas da API com código escondido em **todos** os campos (nome, local, relato, anexos, áudio, mensagens do canal seguro, nome de município do mapa e outros). Depois percorre o site como uma pessoa faria: consulta por protocolo, canal seguro, chatbot, envio de arquivo, as 10 abas do painel, os botões de cada linha, a ficha do caso, a troca de perfis e o modo seguro.

Cada código escondido, se rodar, anota o nome do campo. No fim, o teste conta quantos campos diferentes conseguiram rodar código.

Detalhes que deixam o resultado igual em qualquer máquina:

- A API fica de fora de propósito. O site entra no modo demonstração e as respostas da API são simuladas dentro da página, já com o código malicioso.
- As respostas do IBGE (estados, cidades e o contorno dos municípios) também são simuladas.
- Chart.js, Leaflet e as fontes vêm da internet (CDN), como no uso normal. O resto (VLibras, mapas de fundo) fica bloqueado.

### Como rodar (código atual)

Terminal 1, na raiz do repositório:

```bash
py -m http.server 5500
```

Terminal 2:

```bash
cd testes-navegador
npm run xss
```

Leva cerca de 1 minuto. Saída esperada (final):

```
Painel abriu no login demo: sim | abas percorridas: 10 de 10
Anexo valido continua aparecendo (controle): sim

pontos que executaram script: 0
```

O programa termina com código **0** quando nenhum campo rodou código, **1** quando algum rodou, e **2** quando o teste não conseguiu percorrer o site (por exemplo, site fora do ar). A linha "Anexo valido continua aparecendo" confere que a proteção não apagou anexos legítimos.

### Como reproduzir o 44 (código da Fase 6)

O teste aceita uma pasta `js/` antiga no lugar da atual (`--js-antigo`). A página HTML continua a da Fase 7, e só os scripts são trocados. Os arquivos `panico.js` e `emergencia.js` ficam na versão atual, porque o botão de pânico antigo tira a pessoa da página e interromperia o teste.

```bash
# na raiz do repositório: copia a pasta js/ do último commit da Fase 6 para fora do projeto
mkdir -p ../fase6
git archive e568627 js | tar -x -C ../fase6

# com o site ainda no ar na porta 5500
cd testes-navegador
npm run xss -- --js-antigo ../../fase6/js
```

Saída esperada (final), com código de saída **1**:

```
Campos que executaram script: anexo-erro anexo-nome anexo-src ... tipo tipo2

pontos que executaram script: 44
```

No Windows (PowerShell), troque o `tar` por: `git archive --format=zip -o ..\fase6.zip e568627 js` e depois `Expand-Archive ..\fase6.zip ..\fase6`.

## 2. Painel completo pela borda HTTPS

### O que o teste faz

Abre `https://localhost:8443` (o nginx da pasta [`infra/`](../infra/README.md) com a mesma configuração de produção), entra como administrador pela tela de login e abre cada uma das abas do painel. Enquanto isso, anota:

- cada violação da política de conteúdo (CSP) que o nginx manda para o navegador
- cada erro de JavaScript na página
- cada chamada a `/api` e o código de resposta

Sobre o certificado: o teste manda o navegador aceitar o certificado da borda (`ignoreHTTPSErrors`), porque ele é emitido pela autoridade de teste do projeto, que o Chromium não conhece. Quem confere o certificado de verdade é o `infra/testar-rede.sh`.

### Como rodar

Precisa de Linux ou WSL com `nginx`, `openssl` e `python3` (os mesmos requisitos do `infra/testar-rede.sh`).

Terminal 1, a API com as duas variáveis da borda:

```bash
cd backend
PROTEGE_PROXY_CONFIAVEL=true CORS_ORIGENS=https://localhost:8443 java -jar target/protege-backend-1.0.0.jar
```

Terminal 2, na raiz do repositório:

```bash
bash testes-navegador/subir-borda.sh      # sobe o nginx em 8088 e 8443 e deixa ligado
cd testes-navegador
npm run painel
cd ..
bash testes-navegador/subir-borda.sh parar
```

O `subir-borda.sh` monta o nginx do mesmo jeito que o `infra/testar-rede.sh` (que desliga o nginx no fim dos testes dele). Se os certificados ainda não existirem, ele roda o `infra/pki/gerar-certificados.sh` antes.

Saída esperada (resumida):

```
Protege+ | painel completo pela borda HTTPS
Endereco: https://localhost:8443 | protocolo da pagina: https | login: admin@protege.gov.br

Abas abertas: 10 (resumo, backlog, status-d, kanban, equipe, mapa, dispositivos, reincidencia, estatistica, auditoria)
Rotas da API chamadas: 16 | respondendo 200: 16
  200  GET /api/auditoria
  ...
  200  POST /api/auth/login
Violacoes da politica de conteudo (CSP): 0
Erros de JavaScript na pagina: 0

RESULTADO: OK (10 abas, 16 rotas da API com 200, 0 violacoes de CSP, 0 erros)
```

O programa termina com código **0** quando está tudo certo e **1** quando aparece qualquer violação de CSP, erro de JavaScript, resposta de erro da API, falha no login ou aba que não abriu.

O relatório gravado em [`infra/resultados/painel-pela-borda-20261027.txt`](../infra/resultados/painel-pela-borda-20261027.txt) mostra 15 rotas. A 16ª, `GET /api/backup`, entrou depois, com o card de backups da aba Auditoria.

## Variáveis opcionais

| Variável | Para que serve | Padrão |
|---|---|---|
| `SITE_URL` | Endereço do site no `xss.js` | `http://localhost:5500` |
| `BORDA_URL` | Endereço da borda no `painel.js` | `https://localhost:8443` |
| `ADMIN_EMAIL`, `ADMIN_SENHA` | Login usado no `painel.js` | `admin@protege.gov.br`, `admin123` |
| `DETALHE=1` | Mostra o JSON completo de cada passo do `xss.js` | desligado |
| `LIBS_LOCAIS` | Só para máquina sem internet: pasta com cópias de Chart.js 4.4.0 e Leaflet 1.9.4 (pacotes npm extraídos, ver `comum.js`) | usa a CDN |
