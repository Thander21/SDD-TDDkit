$script:Falhas = 0
$script:Total = 0

function Get-SddKitPath {
  $raiz = Split-Path -Parent $PSScriptRoot
  $tentativas = @((Join-Path $raiz 'SpecSimpleKit'), $raiz)
  foreach ($t in $tentativas) {
    if (Test-Path -LiteralPath (Join-Path $t 'kernel')) { return $t }
  }
  return (Join-Path $raiz 'SpecSimpleKit')
}

function New-SddTesteRepo([string]$Nome) {
  $base = [System.IO.Path]::GetTempPath()
  $dir = Join-Path $base ("sdd-kit-teste-$Nome-" + [guid]::NewGuid().ToString('N').Substring(0, 8) + ' com espaco+mais')
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  Invoke-Git $dir @('init', '-q') | Out-Null
  Invoke-Git $dir @('config', 'user.email', 'teste@exemplo.invalid') | Out-Null
  Invoke-Git $dir @('config', 'user.name', 'teste') | Out-Null
  Invoke-Git $dir @('config', 'core.autocrlf', 'false') | Out-Null
  return $dir
}

function Remove-SddTesteRepo([string]$Dir) {
  if ($Dir -and (Test-Path -LiteralPath $Dir)) { Remove-Item -LiteralPath $Dir -Recurse -Force -ErrorAction SilentlyContinue }
}

function Invoke-Git([string]$Dir, [string[]]$GitArgs) {
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { $out = & git -C $Dir @GitArgs 2>&1; $code = $LASTEXITCODE } finally { $ErrorActionPreference = $old }
  if ($code -ne 0) { throw ("git " + ($GitArgs -join ' ') + " falhou: " + (($out | ForEach-Object { "$_" }) -join ' | ')) }
  return (($out | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" }) -join "`n")
}

function Write-Arq([string]$Dir, [string]$Rel, [string]$Texto) {
  $p = Join-Path $Dir $Rel
  $d = Split-Path -Parent $p
  if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  [System.IO.File]::WriteAllText($p, ($Texto -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding $false))
}

function Install-SddMotor([string]$Dir, [string]$Kit, [string]$Perfil, [hashtable]$Vars) {
  Write-Arq $Dir 'tools/sdd/sdd.ps1' ([System.IO.File]::ReadAllText((Join-Path $Kit 'kernel/tools/sdd/sdd.ps1')))
  Write-Arq $Dir '.sdd/profile.json' ([System.IO.File]::ReadAllText((Join-Path $Kit "profiles/$Perfil.json")))
  if ($Vars) { Write-Arq $Dir '.sdd/profile.local.json' (@{ vars = $Vars } | ConvertTo-Json) }
  # Mesmo comportamento do install.ps1: estado do kit e pastas geradas do perfil no .gitignore.
  $gi = Join-Path $Dir '.gitignore'
  $atual = ''
  if (Test-Path -LiteralPath $gi) { $atual = [System.IO.File]::ReadAllText($gi) }
  $perfilObj = [System.IO.File]::ReadAllText((Join-Path $Kit "profiles/$Perfil.json")) | ConvertFrom-Json
  $linhas = @('.sdd/state/', '.sdd/profile.local.json') + @($perfilObj.paths.gerados)
  Write-Arq $Dir '.gitignore' ($atual + "`n" + ($linhas -join "`n") + "`n")
}

# Roda o motor no interpretador escolhido por SDD_TESTE_PS (powershell|pwsh).
function Invoke-Sdd([string]$Dir, [string[]]$SddArgs, [string]$Stdin) {
  $ps = $env:SDD_TESTE_PS
  if (-not $ps) { $ps = 'powershell' }
  $script = Join-Path $Dir 'tools/sdd/sdd.ps1'
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    if ($PSBoundParameters.ContainsKey('Stdin')) { $out = $Stdin | & $ps -NoProfile -ExecutionPolicy Bypass -File $script @SddArgs 2>&1 }
    else { $out = & $ps -NoProfile -ExecutionPolicy Bypass -File $script @SddArgs 2>&1 }
    $code = $LASTEXITCODE
  } finally { $ErrorActionPreference = $old }
  $texto = ($out | ForEach-Object { "$_" }) -join "`n"
  return [pscustomobject]@{ Codigo = $code; Texto = $texto }
}

function Assert-Contem([string]$Nome, [string]$Texto, [string]$Padrao) {
  $script:Total++
  if ($Texto -match $Padrao) { Write-Host "ok   $Nome" }
  else {
    $script:Falhas++
    Write-Host "FAIL $Nome (esperava /$Padrao/)"
    foreach ($l in (($Texto -split "`n") | Select-Object -Last 25)) { Write-Host "     | $l" }
  }
}

function Assert-Igual([string]$Nome, $Obtido, $Esperado) {
  $script:Total++
  if ($Obtido -eq $Esperado) { Write-Host "ok   $Nome" }
  else { $script:Falhas++; Write-Host "FAIL $Nome (obtido: $Obtido; esperado: $Esperado)" }
}

function Exit-SddTeste {
  Write-Host ("{0}/{1} asserts ok ({2})" -f ($script:Total - $script:Falhas), $script:Total, $PSVersionTable.PSVersion)
  if ($script:Falhas -gt 0) { exit 1 }
  exit 0
}
