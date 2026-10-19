# Teste da capacidade fluxo: portoes P0, P1, P2 e continuidade automatica (CHG-006, SPEC-FLUXO-001). ASCII.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')

$kit = Get-SddKitPath
$kernel = Join-Path $kit 'kernel'
$core = [IO.File]::ReadAllText((Join-Path $kernel '.agents/rules/sdd-core.md'))
$flow = [IO.File]::ReadAllText((Join-Path $kernel '.agents/rules/sdd-fluxo.md'))
$workspace = Split-Path -Parent $kit
$changePath = Join-Path $workspace 'docs/Specs/concluidas/06-continuidade-e-fecho/change.md'
$change = [IO.File]::ReadAllText($changePath, [System.Text.Encoding]::UTF8)
$backlog = [IO.File]::ReadAllText((Join-Path $kernel '.agents/skills/backlog-refinement/SKILL.md'))
$verify = [IO.File]::ReadAllText((Join-Path $kernel '.agents/skills/sdd-verify/SKILL.md'))
$learn = [IO.File]::ReadAllText((Join-Path $kernel '.claude/skills/learn/SKILL.md'))
$guia = [IO.File]::ReadAllText((Join-Path $kit 'docs/como-usar-fluxo.md'))

# Asserts de contrato documental
Assert-Contem '[SPEC-FLUXO-001/C1] P0 documentado no fluxo como Tema do Plano' ($flow + $guia) '(?is)P0.*Tema do Plano'
Assert-Contem '[SPEC-FLUXO-001/C2] P1 aprova a Clarificacao e Especificacao' ($flow + $guia) '(?is)P1.*Clarifica'
Assert-Contem '[SPEC-FLUXO-001/C3] P2 aprova a Change e Tasks' ($flow + $guia) '(?is)P2.*Change'
Assert-Contem '[SPEC-FLUXO-001/C4] tasks agrupam suites sem gates por item' $change 'alvo'
Assert-Contem '[SPEC-FLUXO-001/C5] fecho valida a change inteira e deixa archive como proxima acao' ($flow + $verify) '(?is)validate.{0,300}verificador.{0,300}goal da change inteira'
Assert-Contem '[SPEC-FLUXO-001/C6] falha impede fecho integral' $flow '(?is)Falha.*interrompe archive'

# Teste funcional do motor com P0, P1 e P2
$rel = 'Docs/Specs/changes/01-x/change.md'
function Get-ChangeModel([string]$Status, [string]$Aprovacoes) {
  return "---`nid: CHG-001`ntitle: Teste`nstatus: $Status`nrisk: []`ncapabilities: [fluxo]`nimpact:`n  modified_files: []`n  new_files: []`n---`n`n# CHG-001 - Teste`n`n## Perguntas em aberto`n`n## Analise pre-implementacao`n`nAnalise feita.`n`n## Tasks`n`n## Excecoes`n`n## Aprovacoes`n`n$Aprovacoes`n"
}

$dir = New-SddTesteRepo -Nome 'fluxo_continuidade'
try {
  Install-SddMotor -Dir $dir -Kit $kit -Perfil 'node'
  Write-Arq $dir $rel (Get-ChangeModel 'Draft' '')
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'base') | Out-Null

  $env:CLAUDECODE = '1'
  try {
    # C1: P0 aprova o Tema do Plano e mantem status Draft
    $r = Invoke-Sdd $dir @('approve', '01', 'P0', '--frase', 'aprovo P0 da change 01')
    $t = [IO.File]::ReadAllText((Join-Path $dir $rel))
    Assert-Igual '[SPEC-FLUXO-001/C1] approve P0 sai com exit 0' $r.Codigo 0
    Assert-Contem '[SPEC-FLUXO-001/C1] status permanece Draft apos P0' $t '(?m)^status: Draft$'
    Assert-Contem '[SPEC-FLUXO-001/C1] linha P0 gravada em Aprovacoes' $t '(?m)^- P0: aprovado por .*via chat: "aprovo P0 da change 01"'

    # C2: P1 aprova a clarificacao e move para Approved
    $r = Invoke-Sdd $dir @('approve', '01', 'P1', '--frase', 'aprovo P1 da change 01')
    $t = [IO.File]::ReadAllText((Join-Path $dir $rel))
    Assert-Igual '[SPEC-FLUXO-001/C2] approve P1 sai com exit 0' $r.Codigo 0
    Assert-Contem '[SPEC-FLUXO-001/C2] status vira Approved apos P1' $t '(?m)^status: Approved$'
    Assert-Contem '[SPEC-FLUXO-001/C2] linha P1 gravada em Aprovacoes' $t '(?m)^- P1: aprovado por .*via chat: "aprovo P1 da change 01"'

    # C3: P2 aprova change tecnica e tasks e move para In-Implementation
    $r = Invoke-Sdd $dir @('approve', '01', 'P2', '--frase', 'aprovo P2 da change 01')
    $t = [IO.File]::ReadAllText((Join-Path $dir $rel))
    Assert-Igual '[SPEC-FLUXO-001/C3] approve P2 sai com exit 0' $r.Codigo 0
    Assert-Contem '[SPEC-FLUXO-001/C3] status vira In-Implementation apos P2' $t '(?m)^status: In-Implementation$'
    Assert-Contem '[SPEC-FLUXO-001/C3] linha P2 gravada em Aprovacoes' $t '(?m)^- P2: aprovado por .*via chat: "aprovo P2 da change 01"'
  } finally {
    Remove-Item env:CLAUDECODE -ErrorAction SilentlyContinue
  }
} finally {
  Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
}

Exit-SddTeste
