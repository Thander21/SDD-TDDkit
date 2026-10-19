# Teste da aprovacao dos portoes (sdd approve), incluindo a aprovacao por
# frase do usuario no chat (CHG-002, SPEC-MOTOR-001).
# Uso: powershell -File tests/test_motor_aprovacao.ps1   (interprete: SDD_TESTE_PS)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')

$kit = Get-SddKitPath
$rel = 'Docs/Specs/changes/01-x/change.md'
$linhaP1Antiga = '- P1: aprovado por teste em 2026-10-12 10:00 (sdd approve; change.md antes: 000000000000)'

function Get-Change([string]$Status, [string]$Aprovacoes) {
  return "---`nid: CHG-001`ntitle: Teste`nstatus: $Status`nrisk: []`ncapabilities: [x]`nimpact:`n  modified_files: []`n  new_files: []`n---`n`n# CHG-001 - Teste`n`n## Perguntas em aberto`n`n## Analise pre-implementacao`n`nAnalise feita.`n`n## Tasks`n`n## Excecoes`n`n## Aprovacoes`n`n$Aprovacoes`n"
}

function Get-Txt([string]$Dir) { return [System.IO.File]::ReadAllText((Join-Path $Dir $rel)) }

$dir = New-SddTesteRepo -Nome 'aprovacao'
try {
  Install-SddMotor -Dir $dir -Kit $kit -Perfil 'node'
  Write-Arq $dir $rel (Get-Change 'Draft' '')
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'base') | Out-Null

  # R-1: linha de aprovacao no formato antigo continua reconhecida pelo spec-lint.
  Write-Arq $dir $rel (Get-Change 'Approved' $linhaP1Antiga)
  $r = Invoke-Sdd $dir @('spec-lint')
  Assert-Igual 'R-1 spec-lint aceita a linha P1 no formato antigo' ($r.Texto -match 'sem a linha P1') $false

  # Chamadas abaixo sao da IA: CLAUDECODE definida (Test-SddTerminalHumano = false).
  $antes = $env:CLAUDECODE
  $env:CLAUDECODE = '1'
  try {
    # C1: frase valida aprova o P1.
    Write-Arq $dir $rel (Get-Change 'Draft' '')
    $r = Invoke-Sdd $dir @('approve', '01', 'P1', '--frase', 'aprovo P1 da change 01')
    $t = Get-Txt $dir
    Assert-Igual '[SPEC-MOTOR-001/C1] approve por frase sai com exit 0' $r.Codigo 0
    Assert-Contem '[SPEC-MOTOR-001/C1] status vira Approved' $t '(?m)^status: Approved$'
    Assert-Contem '[SPEC-MOTOR-001/C1] linha P1 cita a frase' $t '(?m)^- P1: aprovado por .*via chat: "aprovo P1 da change 01"'
    # C1 (D10): a forma CHG-NNN tambem cita a change.
    Write-Arq $dir $rel (Get-Change 'Draft' '')
    $r = Invoke-Sdd $dir @('approve', '01', 'P1', '--frase', 'aprovo P1 da CHG-001')
    Assert-Igual '[SPEC-MOTOR-001/C1] frase com CHG-001 aprova' $r.Codigo 0

    # C2: sem frase continua recusado e sugere --frase.
    Write-Arq $dir $rel (Get-Change 'Draft' '')
    $t0 = Get-Txt $dir
    $r = Invoke-Sdd $dir @('approve', '01', 'P1')
    Assert-Igual '[SPEC-MOTOR-001/C2] sem frase sai com exit 1' $r.Codigo 1
    Assert-Contem '[SPEC-MOTOR-001/C2] recusa sugere --frase' $r.Texto 'RECUSADO.*--frase'
    Assert-Igual '[SPEC-MOTOR-001/C2] arquivo nao muda' (Get-Txt $dir) $t0

    # C3: frase sem portao nem numero e recusada.
    $r = Invoke-Sdd $dir @('approve', '01', 'P1', '--frase', 'ok pode seguir')
    Assert-Igual '[SPEC-MOTOR-001/C3] frase invalida sai com exit 1' $r.Codigo 1
    Assert-Contem '[SPEC-MOTOR-001/C3] frase invalida e RECUSADO' $r.Texto 'RECUSADO'
    Assert-Igual '[SPEC-MOTOR-001/C3] arquivo nao muda' (Get-Txt $dir) $t0
    # C3 (achado A1 do verificador): o "1" de "P1" nao conta como numero da change.
    # C3 (achado A1-R, D10): numero solto (data, "os 2 portoes") nao cita a change.
    # C3 (A3, A4 da 3a verificacao): numero gigante recusa (nao ERRO); citar a change certa e outra recusa.
    foreach ($f in @('aprovo P1 da change 03', 'aprovo P1', 'aprovo P1 da change 03 em 01/10', 'aprovo P1 da change 99999999999', 'aprovo P1 da change 01 e change 03')) {
      $r = Invoke-Sdd $dir @('approve', '01', 'P1', '--frase', $f)
      Assert-Igual "[SPEC-MOTOR-001/C3] '$f' para a change 01 sai com exit 1" $r.Codigo 1
      Assert-Igual "[SPEC-MOTOR-001/C3] '$f' nao muda o arquivo" (Get-Txt $dir) $t0
    }
    $rel2 = 'Docs/Specs/changes/02-y/change.md'
    Write-Arq $dir $rel2 ((Get-Change 'Approved' $linhaP1Antiga) -replace 'CHG-001', 'CHG-002')
    foreach ($f in @('aprovo P2 da change 07', 'aprovo P1 e P2 da change 05, os 2 portoes')) {
      $r = Invoke-Sdd $dir @('approve', '02', 'P2', '--frase', $f)
      Assert-Igual "[SPEC-MOTOR-001/C3] '$f' para a change 02 sai com exit 1" $r.Codigo 1
    }
    Assert-Contem '[SPEC-MOTOR-001/C3] change 02 continua Approved' ([System.IO.File]::ReadAllText((Join-Path $dir $rel2))) '(?m)^status: Approved$'
    Remove-Item -LiteralPath (Join-Path $dir 'Docs/Specs/changes/02-y') -Recurse -Force

    # C4: P2 por frase sobre P1 no formato antigo grava base_ref e a frase.
    Write-Arq $dir $rel (Get-Change 'Approved' $linhaP1Antiga)
    $head = Invoke-Git $dir @('rev-parse', 'HEAD')
    $r = Invoke-Sdd $dir @('approve', '01', 'P2', '--frase', 'aprovo P2 da change 01')
    $t = Get-Txt $dir
    Assert-Igual '[SPEC-MOTOR-001/C4] P2 por frase sai com exit 0' $r.Codigo 0
    Assert-Contem '[SPEC-MOTOR-001/C4] status vira In-Implementation' $t '(?m)^status: In-Implementation$'
    Assert-Contem '[SPEC-MOTOR-001/C4] base_ref recebe o HEAD' $t ('(?m)^base_ref: ' + $head + '$')
    Assert-Contem '[SPEC-MOTOR-001/C4] linha P2 cita a frase' $t '(?m)^- P2: aprovado por .*via chat: "aprovo P2 da change 01"'
  } finally {
    if ($null -eq $antes) { Remove-Item Env:CLAUDECODE -ErrorAction SilentlyContinue } else { $env:CLAUDECODE = $antes }
  }
} finally {
  Remove-SddTesteRepo $dir
}
Exit-SddTeste
