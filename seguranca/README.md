# Segurança: simulação de ataques e exercícios de recuperação

Parte 1.3 da Atividade Visão de Futuro: *simular um cenário de ataque e descrever como o sistema responderia e se manteria resiliente*.

Aqui o ataque não fica só descrito: ele roda contra a API real e cada defesa responde com um código HTTP, que é gravado como evidência em `resultados/`.

## Resultado da execução registrada (27/10/2026)

**11 ataques bloqueados, 0 falhas.** Relatório completo em [`resultados/simulacao-20261027-203427.md`](resultados/simulacao-20261027-203427.md).

| # | Ataque | Resposta do sistema | Pilar CIA |
|---|---|---|---|
| C01 | Token de ADMIN assinado com o segredo que era público até a Fase 6, token sem assinatura e token com assinatura alterada | 401, 401, 401 | Confidencialidade, Integridade |
| C02 | Atendente lendo a auditoria, excluindo caso e reatribuindo; Auditor lendo relato e evidência; Gestor gerando backup | 403 nos seis | Confidencialidade |
| C03 | 25 senhas erradas, cada uma com um IP falso no cabeçalho `X-Forwarded-For` | 16 × 401 e depois 429 | Confidencialidade, Disponibilidade |
| C04 | 40 protocolos sorteados tentando achar o caso de uma vítima | 0 encontrados; 429 após 30 tentativas | Confidencialidade |
| C05 | Denúncia anônima com `<img onerror>` e `<script>` | Guardado como texto, nunca executado; consulta pública sem o relato | Integridade |
| C06 | 8 denúncias falsas seguidas para lotar a fila | 4 aceitas, 4 × 429 | Disponibilidade |
| C07 | Programa do Windows renomeado para `.jpg` e arquivo de 7 MB | 415 e 413 | Integridade, Disponibilidade |
| C08 | Corpo JSON de 400 KB sem login | 413 antes de ler o corpo | Disponibilidade |
| C09 | Aparelho IoT sem chave, com a chave antiga e tentando descobrir o perímetro da vítima | 401, 401 e resposta sem dado de localização | Confidencialidade |
| C10 | Ransomware altera o arquivo de backup | Backup marcado como ALTERADO; íntegro de novo após restaurar | Integridade, Disponibilidade |
| C11 | Os ataques deixaram rastro? | 22 recusas na trilha, cadeia SHA-256 intacta | Integridade |

### Exercícios com a API parada ([`resultados/exercicios-20261027-203427.txt`](resultados/exercicios-20261027-203427.txt))

- **A. Funcionário com acesso ao servidor altera o banco direto.** Ele troca o usuário do registro 3 da trilha e apaga o registro 5. Ao religar, a verificação de integridade responde: *"registro 3: o conteúdo foi alterado após a gravação"*. A adulteração não impede a fraude de ser escrita, mas impede que ela passe despercebida.
- **B. Perda total do banco (disco queimado ou sequestrado).** O banco é removido. Antes de restaurar, o hash do backup é conferido contra o manifesto gravado no momento da cópia. Restaurado: 195 denúncias de volta e cadeia íntegra.
- **O que o exercício B revelou:** a trilha volta ao ponto do backup, e os 18 registros feitos depois dele somem sem deixar marca. Esse é o limite de uma cadeia de hash guardada no mesmo banco que ela protege, e é o motivo da **ancoragem em blockchain da Parte 4**: com a "impressão digital" da trilha registrada fora do servidor, um corte no fim da cadeia também passa a ser detectado.

## Como reproduzir no Windows

São dois terminais do PowerShell.

**Terminal 1, a API:**

```powershell
cd backend
.\build.cmd run
```

**Terminal 2, os ataques** (Python 3.8 ou mais novo, só biblioteca padrão):

```powershell
py seguranca\simular_ataques.py
```

O roteiro lê a chave IoT da execução em `backend\data\iot-chave.txt` e grava o relatório em `seguranca\resultados\`. Rode logo depois de subir a API: o próprio teste de força bruta bloqueia novos logins da sua máquina por um minuto.

**Exercícios A e B** (Git Bash, que vem com o Git para Windows). Antes, **pare a API do Terminal 1 com Ctrl+C**: o roteiro sobe e derruba a própria instância, porque precisa abrir o arquivo do banco com o servidor parado.

```bash
cd backend
bash ../seguranca/exercicios_insider_e_recuperacao.sh target/protege-backend-1.0.0.jar
```

Antes, gere o pacote com `.\build.cmd package -DskipTests`. O roteiro usa o H2 do repositório local do Maven (`~/.m2`) para abrir o banco como faria um invasor.

> ⚠️ Rode só contra a sua instância de demonstração. Os roteiros criam denúncias de teste, geram backup, alteram a trilha de propósito e restauram o banco.
