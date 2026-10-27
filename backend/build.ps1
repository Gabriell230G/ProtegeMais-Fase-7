<#
    build.ps1 - Bootstrap de build do Protege+ (Windows)

    Objetivo: permitir compilar e executar o backend SEM exigir a instalacao
    previa do Maven. A comanda pede que o projeto funcione ao ser
    descompactado e aberto localmente - este script cumpre essa parte.

    Ordem de resolucao:
      1. Usa o Maven do PATH, se existir.
      2. Usa uma copia local ja baixada em %USERPROFILE%\.protege-maven.
      3. Baixa a distribuicao oficial do Apache e extrai (uma unica vez).

    Uso:
        .\build.ps1 clean test
        .\build.ps1 spring-boot:run
#>

$ErrorActionPreference = 'Stop'

$MavenVersao = '3.9.9'
$PastaLocal  = Join-Path $env:USERPROFILE '.protege-maven'
$PastaMaven  = Join-Path $PastaLocal "apache-maven-$MavenVersao"
$UrlMaven    = "https://archive.apache.org/dist/maven/maven-3/$MavenVersao/binaries/apache-maven-$MavenVersao-bin.zip"

function Escrever($msg, $cor = 'Cyan') { Write-Host "[Protege+] $msg" -ForegroundColor $cor }

# --- Java -------------------------------------------------------------
$java = Get-Command java -ErrorAction SilentlyContinue
if (-not $java) {
    Escrever 'JDK nao encontrado no PATH. Instale um JDK 17 ou 21.' 'Red'
    exit 1
}

# Fase 7 | Confere a versao. O "java -version" escreve no erro padrao; pelo
# cmd /c a saida volta como texto comum, sem virar erro no PowerShell 5.1.
# Filtra a linha com 'version "' porque JAVA_TOOL_OPTIONS acrescenta uma
# linha "Picked up..." antes dela.
$linhaVersao = cmd /c "java -version 2>&1" | Where-Object { $_ -match 'version "' } | Select-Object -First 1
$major = 0
if ($linhaVersao -match 'version "(\d+)(\.(\d+))?') {
    $major = [int]$Matches[1]
    if ($major -eq 1 -and $Matches[3]) { $major = [int]$Matches[3] }   # formato antigo 1.8
}
if ($major -gt 0 -and $major -lt 17) {
    Escrever "JDK $major encontrado. O Protege+ precisa do JDK 17 ou 21." 'Red'
    exit 1
}
if ($major -gt 21) {
    Escrever "JDK $major detectado. O projeto foi validado com JDK 17 e 21; com versoes mais novas pode haver avisos." 'Yellow'
}
if ($env:JAVA_HOME) {
    Escrever "Observacao: o Maven usa o JDK de JAVA_HOME ($env:JAVA_HOME)." 'Yellow'
}

# --- Maven ------------------------------------------------------------
$mvnPath = $null

$mvnNoPath = Get-Command mvn -ErrorAction SilentlyContinue
if ($mvnNoPath) {
    $mvnPath = $mvnNoPath.Source
    Escrever "Usando o Maven do PATH: $mvnPath"
}
elseif (Test-Path (Join-Path $PastaMaven 'bin\mvn.cmd')) {
    $mvnPath = Join-Path $PastaMaven 'bin\mvn.cmd'
    Escrever "Usando o Maven local: $mvnPath"
}
else {
    Escrever "Maven nao encontrado. Baixando a versao $MavenVersao (uma unica vez)..."
    New-Item -ItemType Directory -Force -Path $PastaLocal | Out-Null
    $zip = Join-Path $PastaLocal "maven-$MavenVersao.zip"

    try {
        $ProgressPreference = 'SilentlyContinue'
        # Windows antigo com .NET padrao em TLS 1.0 nao consegue baixar do Apache.
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $UrlMaven -OutFile $zip -UseBasicParsing
    } catch {
        Escrever "Falha ao baixar o Maven: $($_.Exception.Message)" 'Red'
        Escrever 'Alternativa: instale com  winget install Apache.Maven' 'Yellow'
        exit 1
    }

    Escrever 'Extraindo...'
    Expand-Archive -Path $zip -DestinationPath $PastaLocal -Force
    Remove-Item $zip -Force

    $mvnPath = Join-Path $PastaMaven 'bin\mvn.cmd'
    if (-not (Test-Path $mvnPath)) {
        Escrever 'Extracao concluida, mas o executavel do Maven nao foi localizado.' 'Red'
        exit 1
    }
    Escrever 'Maven pronto.' 'Green'
}

# --- Atalhos ----------------------------------------------------------
# O prefixo curto 'spring-boot:run' depende da resolucao de metadados do
# plugin no repositorio, que pode falhar com NoSuchElementException.
# Usamos sempre o goal com coordenada completa, que dispensa essa etapa.
$GoalRun = 'org.springframework.boot:spring-boot-maven-plugin:run'

$argumentos = if ($args.Count -gt 0) { @($args) } else { @('clean', 'test') }
$argumentos = @($argumentos | ForEach-Object {
    if ($_ -eq 'run' -or $_ -eq 'spring-boot:run') { $GoalRun } else { $_ }
})

# --- Execucao ---------------------------------------------------------
Escrever "Executando: mvn $($argumentos -join ' ')"
Write-Host ''

& $mvnPath @argumentos
exit $LASTEXITCODE
