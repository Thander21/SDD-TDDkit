# =====================================================================
# test_guard_projeto.ps1
# Testes do guard no escopo do projeto (SPEC-GUARD-002..004, SPEC-INST-005)
# Compativel com Windows PowerShell 5.1 e PowerShell 7. Fonte em ASCII.
# =====================================================================
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')
$kit = Get-SddKitPath
$ps = $env:SDD_TESTE_PS
if (-not $ps) { $ps = 'powershell' }

function Invoke-HookDirect([string]$ScriptPath, [string]$Plataforma, [string]$Payload) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try {
    $out = $Payload | & $ps -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -Platform $Plataforma 2>&1
    $code = $LASTEXITCODE
  } finally { $ErrorActionPreference = $old }
  return [pscustomobject]@{ Codigo = $code; Saida = (($out | ForEach-Object { "$_" }) -join "`n") }
}

function Invoke-InstallCmd([string]$KitDir, [string[]]$A) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try {
    $out = & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $KitDir 'install.ps1') @A 2>&1
    $code = $LASTEXITCODE
  } finally { $ErrorActionPreference = $old }
  return [pscustomobject]@{ Codigo = $code; Texto = (($out | ForEach-Object { "$_" }) -join "`n") }
}

$repo = New-SddTesteRepo -Nome 'guard-proj'
$casaFalsa = Join-Path ([System.IO.Path]::GetTempPath()) ('sdd-casa-falsa-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $casaFalsa -Force | Out-Null
$env:USERPROFILE = $casaFalsa
$env:HOME = $casaFalsa

try {
  # Instala o motor no repositorio de teste
  Install-SddMotor $repo $kit 'node' $null
  Write-Arq $repo 'package.json' '{"name":"test-proj"}'
  Invoke-Git $repo @('add', '-A') | Out-Null
  Invoke-Git $repo @('commit', '-qm', 'base') | Out-Null

  # SPEC-GUARD-002/C1: Ativar guard em projeto sem settings
  $rAtivar = Invoke-Sdd $repo @('guard', 'ativar')
  Assert-Igual '[SPEC-GUARD-002/C1] sdd guard ativar sai com exit 0' $rAtivar.Codigo 0
  Assert-Contem '[SPEC-GUARD-002/C1] sdd guard ativar relata GUARD ATIVO' $rAtivar.Texto 'GUARD ATIVO'
  Assert-Igual '[SPEC-GUARD-002/C1] .agents/hooks.json criado' (Test-Path -LiteralPath (Join-Path $repo '.agents/hooks.json')) $true
  Assert-Igual '[SPEC-GUARD-002/C1] .claude/settings.json criado' (Test-Path -LiteralPath (Join-Path $repo '.claude/settings.json')) $true
  $temGlobal = (Test-Path -LiteralPath (Join-Path $casaFalsa '.claude')) -or (Test-Path -LiteralPath (Join-Path $casaFalsa '.gemini')) -or (Test-Path -LiteralPath (Join-Path $casaFalsa '.sdd-kit'))
  Assert-Igual '[SPEC-GUARD-002/C1] nenhuma gravacao global (.claude, .gemini, .sdd-kit)' $temGlobal $false

  # SPEC-GUARD-003/C2: Status do guard
  $rStatus = Invoke-Sdd $repo @('guard', 'status')
  Assert-Igual '[SPEC-GUARD-003/C2] sdd guard status sai com exit 0' $rStatus.Codigo 0
  Assert-Contem '[SPEC-GUARD-003/C2] sdd guard status relata ativo' $rStatus.Texto 'GUARD:\s*ativo'

  # SPEC-GUARD-002/C2: Settings do usuario ja existentes preservados e idempotencia
  Remove-Item -LiteralPath (Join-Path $repo '.agents/hooks.json') -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath (Join-Path $repo '.claude/settings.json') -Force -ErrorAction SilentlyContinue
  $userAgents = '{"meu-hook":{"PreToolUse":[{"matcher":"run_command","hooks":[{"type":"command","command":"echo user"}]}]}}'
  $userClaude = '{"permissions":{"allow":["Bash(npm test)"]},"theme":"dark"}'
  Write-Arq $repo '.agents/hooks.json' $userAgents
  Write-Arq $repo '.claude/settings.json' $userClaude

  [void](Invoke-Sdd $repo @('guard', 'ativar'))
  [void](Invoke-Sdd $repo @('guard', 'ativar'))

  $ahTxt = [System.IO.File]::ReadAllText((Join-Path $repo '.agents/hooks.json'))
  $csTxt = [System.IO.File]::ReadAllText((Join-Path $repo '.claude/settings.json'))
  $ahJson = $ahTxt | ConvertFrom-Json
  $csJson = $csTxt | ConvertFrom-Json

  Assert-Igual '[SPEC-GUARD-002/C2] hook do usuario preservado em .agents/hooks.json' ($null -ne $ahJson.'meu-hook') $true
  Assert-Igual '[SPEC-GUARD-002/C2] hook sdd-kit-guard presente em .agents/hooks.json' ($null -ne $ahJson.'sdd-kit-guard') $true
  Assert-Igual '[SPEC-GUARD-002/C2] allow do usuario preservado em .claude/settings.json' (@($csJson.permissions.allow) -contains 'Bash(npm test)') $true
  Assert-Igual '[SPEC-GUARD-002/C2] theme do usuario preservado em .claude/settings.json' $csJson.theme 'dark'

  # SPEC-GUARD-002/C3: Settings invalido aborta com exit 2 sem alteracoes
  Write-Arq $repo '.agents/hooks.json' '{ json invalido ...'
  $rInvalido = Invoke-Sdd $repo @('guard', 'ativar')
  Assert-Igual '[SPEC-GUARD-002/C3] settings invalido sai com exit 2' $rInvalido.Codigo 2
  Assert-Contem '[SPEC-GUARD-002/C3] mensagem de erro cita JSON valido' $rInvalido.Texto 'nao e JSON valido'

  # Restaura hooks para os proximos testes
  Write-Arq $repo '.agents/hooks.json' $userAgents
  [void](Invoke-Sdd $repo @('guard', 'ativar'))

  # SPEC-GUARD-003/C1: Desativar remove so o kit
  $rDesativar = Invoke-Sdd $repo @('guard', 'desativar')
  Assert-Igual '[SPEC-GUARD-003/C1] sdd guard desativar sai com exit 0' $rDesativar.Codigo 0
  Assert-Contem '[SPEC-GUARD-003/C1] relata GUARD INATIVO' $rDesativar.Texto 'GUARD INATIVO'
  $ahPos = [System.IO.File]::ReadAllText((Join-Path $repo '.agents/hooks.json')) | ConvertFrom-Json
  Assert-Igual '[SPEC-GUARD-003/C1] meu-hook preservado apos desativar' ($null -ne $ahPos.'meu-hook') $true
  Assert-Igual '[SPEC-GUARD-003/C1] sdd-kit-guard removido apos desativar' ($null -eq $ahPos.'sdd-kit-guard') $true

  # Se o arquivo so tinha o kit, ao desativar ele e removido
  Remove-Item -LiteralPath (Join-Path $repo '.agents/hooks.json') -Force -ErrorAction SilentlyContinue
  [void](Invoke-Sdd $repo @('guard', 'ativar'))
  [void](Invoke-Sdd $repo @('guard', 'desativar'))
  Assert-Igual '[SPEC-GUARD-003/C1] .agents/hooks.json apagado quando so tinha kit' (Test-Path -LiteralPath (Join-Path $repo '.agents/hooks.json')) $false

  # SPEC-GUARD-003/C2: Status parcial
  Write-Arq $repo '.claude/settings.json' '{"permissions":{"deny":["Read(//**/.env)"]}}'
  $rParcial = Invoke-Sdd $repo @('guard', 'status')
  Assert-Igual '[SPEC-GUARD-003/C2] status parcial sai com exit 1' $rParcial.Codigo 1
  Assert-Contem '[SPEC-GUARD-003/C2] relata parcial' $rParcial.Texto 'GUARD:\s*parcial'

  # SPEC-GUARD-002/C4 e SPEC-GUARD-004/C1..C2: Validacao dos scripts de guarda
  $guardScript = Join-Path $kit 'kernel/tools/sdd/guard.ps1'
  if (-not (Test-Path -LiteralPath $guardScript)) { $guardScript = Join-Path $kit 'machine/guard.ps1' }
  $editScript = Join-Path $kit 'kernel/tools/sdd/edit_guard.ps1'
  if (-not (Test-Path -LiteralPath $editScript)) { $editScript = Join-Path $kit 'machine/edit_guard.ps1' }

  # SPEC-GUARD-002/C4: Antigravity PreToolUse payload
  $cmdPush = @{ toolCall = @{ name = 'run_command'; args = @{ CommandLine = 'git push --force origin main' } } } | ConvertTo-Json -Compress
  $resPush = Invoke-HookDirect $guardScript 'Antigravity' $cmdPush
  $decPush = ($resPush.Saida | ConvertFrom-Json).decision
  Assert-Igual '[SPEC-GUARD-002/C4] git push --force retorna force_ask no Antigravity' $decPush 'force_ask'

  # SPEC-GUARD-004/C1: Comando guard desativar deve pedir ask
  $cmdDesat = @{ toolCall = @{ name = 'run_command'; args = @{ CommandLine = 'powershell -File tools/sdd/sdd.ps1 guard desativar' } } } | ConvertTo-Json -Compress
  $resDesat = Invoke-HookDirect $guardScript 'Antigravity' $cmdDesat
  $decDesat = ($resDesat.Saida | ConvertFrom-Json).decision
  Assert-Igual '[SPEC-GUARD-004/C1] sdd guard desativar retorna force_ask no guard' $decDesat 'force_ask'

  # SPEC-GUARD-004/C2: Edicao de settings protegidos deve pedir ask
  $editHooks = @{ toolCall = @{ name = 'replace_file_content'; args = @{ TargetFile = (Join-Path $repo '.agents/hooks.json'); ReplacementContent = '{}' } } } | ConvertTo-Json -Compress
  $resEditH = Invoke-HookDirect $editScript 'Antigravity' $editHooks
  $decEditH = ($resEditH.Saida | ConvertFrom-Json).decision
  Assert-Igual '[SPEC-GUARD-004/C2] edicao de .agents/hooks.json retorna force_ask no edit_guard' $decEditH 'force_ask'

  # SPEC-INST-005/C2: Acao maquina nao existe mais no instalador
  $rMaq = Invoke-InstallCmd $kit @('maquina')
  Assert-Igual '[SPEC-INST-005/C2] install.ps1 maquina rejeitado com exit != 0' ($rMaq.Codigo -ne 0) $true

  # SPEC-INST-005/C1: Instalar projeto ativa o guard e nao grava global
  $repoInst = New-SddTesteRepo -Nome 'inst-guard'
  try {
    Write-Arq $repoInst 'package.json' '{"name":"inst-test"}'
    Invoke-Git $repoInst @('add', '-A') | Out-Null
    Invoke-Git $repoInst @('commit', '-qm', 'base') | Out-Null
    $rInst = Invoke-InstallCmd $kit @('projeto', '-Destino', $repoInst, '-Perfil', 'node')
    Assert-Igual '[SPEC-INST-005/C1] install.ps1 projeto sai 0' $rInst.Codigo 0
    $rStInst = Invoke-Sdd $repoInst @('guard', 'status')
    Assert-Igual '[SPEC-INST-005/C1] guard ativo apos install.ps1 projeto' $rStInst.Codigo 0
    $temGlobalInst = (Test-Path -LiteralPath (Join-Path $casaFalsa '.claude')) -or (Test-Path -LiteralPath (Join-Path $casaFalsa '.gemini')) -or (Test-Path -LiteralPath (Join-Path $casaFalsa '.sdd-kit'))
    Assert-Igual '[SPEC-INST-005/C1] pasta de usuario falsa sem gravacoes globais' $temGlobalInst $false
  } finally {
    Remove-SddTesteRepo $repoInst
  }

  # SPEC-INST-005/C3: Update ativa o guard
  $repoUpd = New-SddTesteRepo -Nome 'upd-guard'
  try {
    Write-Arq $repoUpd 'package.json' '{"name":"upd-test"}'
    Invoke-Git $repoUpd @('add', '-A') | Out-Null
    Invoke-Git $repoUpd @('commit', '-qm', 'base') | Out-Null
    [void](Invoke-InstallCmd $kit @('projeto', '-Destino', $repoUpd, '-Perfil', 'node'))
    # Remove guard para simular versao anterior
    [void](Invoke-Sdd $repoUpd @('guard', 'desativar'))
    Invoke-Git $repoUpd @('add', '-A') | Out-Null
    Invoke-Git $repoUpd @('commit', '-qm', 'versao anterior sem guard') | Out-Null
    $rUpd = Invoke-InstallCmd $kit @('update', '-Destino', $repoUpd)
    Assert-Igual '[SPEC-INST-005/C3] install.ps1 update sai 0' $rUpd.Codigo 0
    $rStUpd = Invoke-Sdd $repoUpd @('guard', 'status')
    Assert-Igual '[SPEC-INST-005/C3] guard ativo apos update' $rStUpd.Codigo 0
    Assert-Igual '[SPEC-INST-005/C3] guard.ps1 existe no kernel do projeto' (Test-Path -LiteralPath (Join-Path $repoUpd 'tools/sdd/guard.ps1')) $true
  } finally {
    Remove-SddTesteRepo $repoUpd
  }

} finally {
  Remove-SddTesteRepo $repo
  if (Test-Path -LiteralPath $casaFalsa) { Remove-Item -LiteralPath $casaFalsa -Recurse -Force -ErrorAction SilentlyContinue }
}

Exit-SddTeste
