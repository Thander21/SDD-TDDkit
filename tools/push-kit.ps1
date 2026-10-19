# =====================================================================
# tools/push-kit.ps1
# Envia as alteracoes da pasta SpecSimpleKit para o repositorio publico
# Thander21/SpecSimpleKit via git subtree.
# Compativel com Windows PowerShell 5.1 e PowerShell 7. ASCII.
# =====================================================================
param(
  [string]$Remote = 'specsimplekit',
  [string]$Branch = 'main',
  [string]$Url = 'https://github.com/Thander21/SpecSimpleKit.git'
)
$ErrorActionPreference = 'Stop'

function Write-L([string]$T) { [Console]::Out.WriteLine($T) }

# Confere se esta na raiz do repositorio
if (-not (Test-Path -LiteralPath 'SpecSimpleKit' -PathType Container)) {
  Write-Error "ERRO: execute a partir da raiz do repositorio SDD-TDDkit."
  exit 1
}

# Confere se ha mudancas nao commitadas dentro de SpecSimpleKit
$st = git status --porcelain SpecSimpleKit
if ($st) {
  Write-Warning "AVISO: existem mudancas nao commitadas em SpecSimpleKit/."
  Write-Warning "O git subtree envia apenas commits. Considere commitar antes."
  $conf = Read-Host "Deseja continuar mesmo assim enviando apenas os commits atuais? (s/N)"
  if ($conf -notmatch '^[sSyY]') {
    Write-L "Operacao cancelada."
    exit 0
  }
}

# Confere se o remote existe; se nao, adiciona
$remotes = git remote
if ($remotes -notcontains $Remote) {
  Write-L "Adicionando remote '$Remote' ($Url)..."
  git remote add $Remote $Url
}

Write-L "Enviando SpecSimpleKit para $Remote/$Branch..."
git subtree push --prefix=SpecSimpleKit $Remote $Branch
if ($LASTEXITCODE -eq 0) {
  Write-L "Sucesso: SpecSimpleKit sincronizado em $Remote/$Branch."
} else {
  Write-Error "ERRO: falha ao enviar subtree para $Remote/$Branch."
  exit $LASTEXITCODE
}
