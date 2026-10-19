# Teste do install.ps1: projeto, check, update e maquina (numa casa falsa).
# Uso: powershell -File tests/test_install.ps1   (interprete: SDD_TESTE_PS)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')
$kit = Get-SddKitPath
$ps = $env:SDD_TESTE_PS
if (-not $ps) { $ps = 'powershell' }

function Invoke-Install([string]$KitDir, [string[]]$A) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $out = & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $KitDir 'install.ps1') @A 2>&1; $code = $LASTEXITCODE } finally { $ErrorActionPreference = $old }
  return [pscustomobject]@{ Codigo = $code; Texto = (($out | ForEach-Object { "$_" }) -join "`n") }
}
function Test-Arq([string]$Dir, [string]$Rel) { return (Test-Path -LiteralPath (Join-Path $Dir $Rel)) }
function Get-Txt([string]$Dir, [string]$Rel) { return [System.IO.File]::ReadAllText((Join-Path $Dir $Rel)) }

$dir = New-SddTesteRepo -Nome 'install'
$dir2 = New-SddTesteRepo -Nome 'conflito'
$kit2 = Join-Path ([System.IO.Path]::GetTempPath()) ('sdd-kit-copia-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
$casa = Join-Path ([System.IO.Path]::GetTempPath()) ('sdd-casa-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
try {
  Write-Arq $dir 'package.json' '{ "name": "x", "private": true, "type": "module", "scripts": { "test": "node --test" } }'
  Write-Arq $dir 'test/a.test.js' "import { test } from 'node:test';`ntest('a', () => {});`n"
  Write-Arq $dir 'AGENTS.md' "# Projeto X`n`nTexto do projeto que o kit nao pode apagar.`n"
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'base') | Out-Null

  # Arvore suja: recusa
  Write-Arq $dir 'sujo.txt' 'x'
  $r = Invoke-Install $kit @('projeto', '-Destino', $dir, '-Perfil', 'node')
  Assert-Contem 'projeto recusa arvore suja' $r.Texto 'nao esta limpa'
  Remove-Item -LiteralPath (Join-Path $dir 'sujo.txt')

  $r = Invoke-Install $kit @('projeto', '-Destino', $dir, '-Perfil', 'node')
  Assert-Contem 'projeto instala' $r.Texto 'INSTALADO sdd-kit'
  Assert-Igual 'projeto sai 0' $r.Codigo 0
  foreach ($rel in @('tools/sdd/sdd.ps1', '.agents/rules/sdd-core.md', '.agents/rules/sdd-fluxo.md', '.agents/skills/sdd-verify/SKILL.md', '.claude/skills/sdd-verify/SKILL.md', '.claude/skills/learn/SKILL.md', '.claude/agents/sdd-verifier.md', '.claude/CLAUDE.md', '.sdd/profile.json', '.sdd/kit.lock.json', 'Docs/Specs/_templates/change.md', 'Docs/Specs/capabilities/_index.md')) {
    Assert-Igual "arquivo instalado: $rel" (Test-Arq $dir $rel) $true
  }
  $ag = Get-Txt $dir 'AGENTS.md'
  Assert-Contem 'AGENTS.md preserva o texto do projeto' $ag 'Texto do projeto que o kit nao pode apagar'
  Assert-Igual 'AGENTS.md com um bloco do kit' ([regex]::Matches($ag, 'sdd-kit:begin')).Count 1
  Assert-Contem 'wrapper aponta para a canonica' (Get-Txt $dir '.claude/skills/sdd-verify/SKILL.md') '\.agents/skills/sdd-verify/SKILL\.md'
  Assert-Contem 'wrapper repete a description' (Get-Txt $dir '.claude/skills/sdd-verify/SKILL.md') 'description: "Verificador independente'
  Assert-Contem 'CLAUDE.md importa o nucleo' (Get-Txt $dir '.claude/CLAUDE.md') '@\.\./\.agents/rules/sdd-core\.md'
  Assert-Contem '.gitignore com estado do kit' (Get-Txt $dir '.gitignore') '\.sdd/state/'
  Assert-Contem '.gitignore com pastas geradas do perfil' (Get-Txt $dir '.gitignore') 'node_modules/'
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'kit') | Out-Null

  $r = Invoke-Install $kit @('projeto', '-Destino', $dir, '-Perfil', 'node')
  Assert-Contem 'segunda instalacao manda usar update' $r.Texto 'use update'

  $r = Invoke-Install $kit @('check', '-Destino', $dir)
  Assert-Contem 'check limpo passa' $r.Texto 'KIT CHECK PASS'
  $r = Invoke-Sdd $dir @('check')
  Assert-Contem 'motor instalado roda check' $r.Texto 'SDD CHECK PASS'

  Add-Content -LiteralPath (Join-Path $dir '.agents/rules/sdd-core.md') -Value '- regra local'
  $r = Invoke-Install $kit @('check', '-Destino', $dir)
  Assert-Contem 'regra do kit editada = WARN' $r.Texto 'KIT CHECK WARN'
  Assert-Igual 'WARN sai 0' $r.Codigo 0
  Add-Content -LiteralPath (Join-Path $dir 'tools/sdd/sdd.ps1') -Value '# mexida'
  $r = Invoke-Install $kit @('check', '-Destino', $dir)
  Assert-Contem 'motor editado = FAIL' $r.Texto 'KIT CHECK FAIL'
  Assert-Igual 'FAIL sai 1' $r.Codigo 1
  Invoke-Git $dir @('checkout', '--', '.') | Out-Null

  # Update a partir de uma copia do kit com versao nova.
  New-Item -ItemType Directory -Path $kit2 -Force | Out-Null
  foreach ($item in @('install.ps1', 'VERSION', 'kernel', 'profiles', 'project-templates')) { Copy-Item -LiteralPath (Join-Path $kit $item) -Destination $kit2 -Recurse -Force }
  [System.IO.File]::WriteAllText((Join-Path $kit2 'VERSION'), "0.1.1`n")
  Add-Content -LiteralPath (Join-Path $kit2 'kernel/.agents/rules/sdd-revisao.md') -Value "`n- linha nova do kit"
  Add-Content -LiteralPath (Join-Path $kit2 'kernel/.agents/rules/sdd-fluxo.md') -Value "`n- linha nova do kit no fluxo"
  Add-Content -LiteralPath (Join-Path $dir '.agents/rules/sdd-fluxo.md') -Value "`n- edicao local"
  Invoke-Git $dir @('commit', '-qam', 'edicao local') | Out-Null

  # Change ativa bloqueia o update
  Write-Arq $dir 'Docs/Specs/changes/1-x/change.md' "---`nid: CHG-001`ntitle: X`nstatus: In-Implementation`n---`n"
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'change') | Out-Null
  $r = Invoke-Install $kit2 @('update', '-Destino', $dir)
  Assert-Contem 'update recusa com change em implementacao' $r.Texto 'change em implementacao'
  Invoke-Git $dir @('rm', '-q', '-r', 'Docs/Specs/changes/1-x') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'fecha') | Out-Null

  $r = Invoke-Install $kit2 @('update', '-Destino', $dir)
  Assert-Contem 'update grava' $r.Texto 'UPDATE 0\.1\.0 -> 0\.1\.1'
  Assert-Contem 'arquivo intacto atualizado' (Get-Txt $dir '.agents/rules/sdd-revisao.md') 'linha nova do kit'
  Assert-Contem 'arquivo editado preservado' (Get-Txt $dir '.agents/rules/sdd-fluxo.md') 'edicao local'
  Assert-Igual 'versao nova em .kitnew' (Test-Arq $dir '.agents/rules/sdd-fluxo.md.kitnew') $true
  Assert-Contem 'lock com versao nova' (Get-Txt $dir '.sdd/kit.lock.json') '"kit_versao":\s*"0\.1\.1"'
  Remove-Item -LiteralPath (Join-Path $dir '.agents/rules/sdd-fluxo.md.kitnew')
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'update') | Out-Null

  # Executavel editado bloqueia o update inteiro (nada gravado)
  Add-Content -LiteralPath (Join-Path $kit2 'kernel/.agents/rules/sdd-core.md') -Value "`n- mais uma do kit"
  Add-Content -LiteralPath (Join-Path $dir 'tools/sdd/sdd.ps1') -Value '# mexida local'
  Invoke-Git $dir @('commit', '-qam', 'motor mexido') | Out-Null
  $antes = Get-Txt $dir '.agents/rules/sdd-core.md'
  $r = Invoke-Install $kit2 @('update', '-Destino', $dir)
  Assert-Contem 'update recusa motor editado' $r.Texto 'UPDATE RECUSADO'
  Assert-Igual 'nada gravado no update recusado' (Get-Txt $dir '.agents/rules/sdd-core.md') $antes

  # specs_root em minusculo (perfil ja versionado no projeto): moldes direto la, frescor estavel.
  $dir3 = New-SddTesteRepo -Nome 'minusculo'
  try {
    Write-Arq $dir3 'package.json' '{ "name": "y", "private": true, "type": "module", "scripts": { "test": "node --test" } }'
    Write-Arq $dir3 'test/a.test.js' "import { test } from 'node:test';`ntest('a', () => {});`n"
    Write-Arq $dir3 '.sdd/profile.json' ((Get-Txt $kit 'profiles/node.json').Replace('"specs_root": "Docs/Specs"', '"specs_root": "docs/specs"'))
    Invoke-Git $dir3 @('add', '-A') | Out-Null; Invoke-Git $dir3 @('commit', '-qm', 'base') | Out-Null
    $r = Invoke-Install $kit @('projeto', '-Destino', $dir3, '-Perfil', 'node')
    Assert-Contem 'A7 instala com specs_root minusculo' $r.Texto 'INSTALADO'
    Assert-Contem 'A7 lock aponta docs/specs' (Get-Txt $dir3 '.sdd/kit.lock.json') '"docs/specs/_templates/change\.md"'
    Assert-Igual 'A7 molde existe em docs/specs' (Test-Arq $dir3 'docs/specs/_templates/change.md') $true
    Invoke-Git $dir3 @('add', '-A') | Out-Null; Invoke-Git $dir3 @('commit', '-qm', 'kit') | Out-Null
    $base = Invoke-Git $dir3 @('rev-parse', 'HEAD')
    Write-Arq $dir3 'docs/specs/changes/1-x/change.md' "---`nid: CHG-001`ntitle: X`nstatus: In-Implementation`nbase_ref: $base`n---`n"
    $null = Invoke-Sdd $dir3 @('validate')
    $null = Invoke-Sdd $dir3 @('test', 'test/a.test.js')
    $r = Invoke-Sdd $dir3 @('status')
    Assert-Contem 'A7 evidencia em docs/specs nao desatualiza o validate' $r.Texto 'full: \S+ .*arvore atual'
  } finally { Remove-SddTesteRepo $dir3 }

  # AGENTS.md com marcador quebrado: aborta sem gravacao parcial.
  $dir4 = New-SddTesteRepo -Nome 'marcador'
  try {
    Write-Arq $dir4 'AGENTS.md' "# X`n<!-- sdd-kit:begin -->`nsem fim`n"
    Invoke-Git $dir4 @('add', '-A') | Out-Null; Invoke-Git $dir4 @('commit', '-qm', 'base') | Out-Null
    $r = Invoke-Install $kit @('projeto', '-Destino', $dir4, '-Perfil', 'node')
    Assert-Contem 'marcador quebrado aborta' $r.Texto 'marcadores do sdd-kit'
    Assert-Igual 'nada gravado com marcador quebrado' (Test-Arq $dir4 'tools/sdd/sdd.ps1') $false
  } finally { Remove-SddTesteRepo $dir4 }

  # Conflito na instalacao: nada gravado
  Write-Arq $dir2 '.agents/rules/sdd-core.md' 'regra antiga com o mesmo nome'
  Invoke-Git $dir2 @('add', '-A') | Out-Null; Invoke-Git $dir2 @('commit', '-qm', 'base') | Out-Null
  $r = Invoke-Install $kit @('projeto', '-Destino', $dir2, '-Perfil', 'python')
  Assert-Contem 'conflito na instalacao' $r.Texto 'CONFLITO'
  Assert-Igual 'nada gravado no conflito' (Test-Arq $dir2 'tools/sdd/sdd.ps1') $false

  # Acao maquina descontinuada: rejeitada com exit 2
  $r = Invoke-Install $kit @('maquina')
  Assert-Igual 'maquina rejeitada com exit 2' $r.Codigo 2
  Assert-Contem 'mensagem cita descontinuada' $r.Texto 'descontinuada'

  # Instalacao do projeto ativa o guard no projeto
  Assert-Igual 'guard ativo no projeto instalado' (Test-Arq $dir '.agents/hooks.json') $true
  Assert-Igual 'settings do claude ativo no projeto instalado' (Test-Arq $dir '.claude/settings.json') $true
} finally {
  Remove-SddTesteRepo $dir; Remove-SddTesteRepo $dir2; Remove-SddTesteRepo $kit2; Remove-SddTesteRepo $casa
}
Exit-SddTeste
