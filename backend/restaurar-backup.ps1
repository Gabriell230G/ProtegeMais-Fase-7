<#
    restaurar-backup.ps1 - Restaura o banco H2 do Protege+ a partir de um backup (Fase 7)

    Uso (com o servidor PARADO), a partir da pasta backend:
        .\restaurar-backup.cmd data\backups\protege-20261027-023000-000.zip

    Antes de restaurar, com a API ainda no ar, confira em GET /api/backup
    (perfil ADMIN ou AUDITOR) que o arquivo aparece com situacao = "integro".
    "ALTERADO" significa que o arquivo mudou depois de gerado: NAO restaure.

    O que o script faz:
      1. Confere que o zip existe e contem protege.mv.db. Se nao, nada muda.
      2. Recusa rodar com a API no ar (porta 8080 em uso).
      3. Mostra o SHA-256 do arquivo e o compara com o manifesto.sha256
         gravado pelo sistema no momento do backup.
      4. Guarda o banco atual como protege.mv.db.antes-da-restauracao-<data>,
         sem apagar nada (permite desfazer).
      5. Extrai o backup. Se a extracao falhar, devolve o banco original.
#>
param(
    [Parameter(Mandatory = $true)][string]$Arquivo,
    [string]$PastaDados = (Join-Path $PSScriptRoot 'data')
)

$ErrorActionPreference = 'Stop'
function Escrever($msg, $cor = 'Cyan') { Write-Host "[Protege+] $msg" -ForegroundColor $cor }

if (-not (Test-Path -LiteralPath $Arquivo)) { Escrever "Backup nao encontrado: $Arquivo" 'Red'; exit 1 }
$Arquivo = (Resolve-Path -LiteralPath $Arquivo).Path

# 1. O zip precisa conter o banco
Add-Type -AssemblyName System.IO.Compression.FileSystem
$temBanco = $false
try {
    $zip = [IO.Compression.ZipFile]::OpenRead($Arquivo)
    try { $temBanco = @($zip.Entries | Where-Object { $_.FullName -eq 'protege.mv.db' }).Count -gt 0 }
    finally { $zip.Dispose() }
} catch {
    Escrever "O arquivo nao e um zip valido: $($_.Exception.Message). Nada foi alterado." 'Red'; exit 1
}
if (-not $temBanco) { Escrever 'O zip nao contem protege.mv.db. Nada foi alterado.' 'Red'; exit 1 }

# 2. A API precisa estar parada (o banco em uso nao pode ser trocado)
$emUso = $false
try {
    $emUso = [bool](Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue)
} catch { $emUso = $false }
if ($emUso) { Escrever 'A API ainda esta no ar (porta 8080). Pare o servidor antes de restaurar.' 'Red'; exit 1 }

# 3. Hash do arquivo contra o manifesto gravado no momento do backup
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Arquivo).Hash.ToLower()
$nome = Split-Path $Arquivo -Leaf
$manifesto = Join-Path (Split-Path $Arquivo -Parent) 'manifesto.sha256'
$registrado = $null
if (Test-Path -LiteralPath $manifesto) {
    foreach ($linha in Get-Content -LiteralPath $manifesto -Encoding UTF8) {
        $partes = $linha.Trim() -split '\s+', 2
        if ($partes.Count -eq 2 -and $partes[1] -eq $nome) { $registrado = $partes[0].ToLower() }
    }
}
Escrever "Arquivo : $nome"
Escrever "SHA-256 : $hash"
Escrever "Destino : $PastaDados"
if ($registrado -and $registrado -ne $hash) {
    Escrever "ALTERADO: o manifesto registrou $registrado no momento do backup. Restauracao recusada." 'Red'
    exit 1
}
if ($registrado) {
    Escrever 'Confere com o manifesto gravado no momento do backup.' 'Green'
} else {
    Escrever 'Este arquivo nao consta no manifesto. Confirme em GET /api/backup antes de continuar.' 'Yellow'
}
$ok = Read-Host 'Restaurar este backup? (s/n)'
if ($ok -ne 's') { Escrever 'Restauracao cancelada. Nada foi alterado.' 'Yellow'; exit 1 }

# 4. Guarda o banco atual
New-Item -ItemType Directory -Force -Path $PastaDados | Out-Null
$banco = Join-Path $PastaDados 'protege.mv.db'
$guardado = $null
if (Test-Path -LiteralPath $banco) {
    $carimbo = Get-Date -Format 'yyyyMMdd-HHmmss'
    $guardado = "$banco.antes-da-restauracao-$carimbo"
    Move-Item -LiteralPath $banco -Destination $guardado
    Escrever "Banco atual guardado em $guardado"
}

# 5. Extrai; em caso de falha, devolve o banco original
try {
    Expand-Archive -LiteralPath $Arquivo -DestinationPath $PastaDados -Force
} catch {
    if ($guardado) { Move-Item -LiteralPath $guardado -Destination $banco -Force }
    Escrever "Falha ao extrair: $($_.Exception.Message). O banco original foi devolvido." 'Red'
    exit 1
}
Escrever 'Backup restaurado. Suba a API e confira a trilha em GET /api/auditoria/integridade.' 'Green'
Escrever 'Lembrete: a trilha volta ao ponto do backup; o que foi feito depois dele nao consta mais.' 'Yellow'
