<#
    restaurar-backup.ps1 - Restaura o banco H2 do Protege+ a partir de um backup (Fase 7)

    Uso (com o servidor PARADO):
        .\restaurar-backup.ps1 -Arquivo .\data\backups\protege-20261027-023000.zip

    O que faz:
      1. Mostra o SHA-256 do backup escolhido. Compare com o valor que a rota
         GET /api/backup (ou a trilha de auditoria) registrou. Se for diferente,
         o arquivo foi alterado depois de gerado: NAO restaure.
      2. Guarda o banco atual como protege.mv.db.antes-da-restauracao-<data>,
         sem apagar nada (permite desfazer).
      3. Extrai o backup para a pasta data\.
#>
param([Parameter(Mandatory = $true)][string]$Arquivo)

$ErrorActionPreference = 'Stop'
function Escrever($msg, $cor = 'Cyan') { Write-Host "[Protege+] $msg" -ForegroundColor $cor }

if (-not (Test-Path $Arquivo)) { Escrever "Backup nao encontrado: $Arquivo" 'Red'; exit 1 }

$hash = (Get-FileHash -Algorithm SHA256 -Path $Arquivo).Hash.ToLower()
Escrever "SHA-256 do backup: $hash"
$ok = Read-Host "Esse hash confere com o registrado na trilha de auditoria? (s/n)"
if ($ok -ne 's') { Escrever 'Restauracao cancelada.' 'Yellow'; exit 1 }

$pastaDados = Join-Path $PSScriptRoot 'data'
$banco = Join-Path $pastaDados 'protege.mv.db'
if (Test-Path $banco) {
    $carimbo = Get-Date -Format 'yyyyMMdd-HHmmss'
    $guardado = "$banco.antes-da-restauracao-$carimbo"
    Move-Item $banco $guardado
    Escrever "Banco atual guardado em $guardado"
}

Expand-Archive -Path $Arquivo -DestinationPath $pastaDados -Force
Escrever 'Backup restaurado. Suba o servidor e confira a trilha em GET /api/auditoria/integridade.' 'Green'
