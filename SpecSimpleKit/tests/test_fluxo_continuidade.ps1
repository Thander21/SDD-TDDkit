# Teste de contrato documental do fluxo de fecho (CHG-006). ASCII.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')
$kit = Split-Path -Parent $PSScriptRoot
$kernel = Join-Path $kit 'kernel'
$core = [IO.File]::ReadAllText((Join-Path $kernel '.agents/rules/sdd-core.md'))
$flow = [IO.File]::ReadAllText((Join-Path $kernel '.agents/rules/sdd-fluxo.md'))
$workspace = Split-Path -Parent $kit
$changePath = Join-Path $workspace 'docs/Specs/changes/06-continuidade-e-fecho/change.md'
$change = [IO.File]::ReadAllText($changePath, [System.Text.Encoding]::UTF8)
$backlog = [IO.File]::ReadAllText((Join-Path $kernel '.agents/skills/backlog-refinement/SKILL.md'))
$verify = [IO.File]::ReadAllText((Join-Path $kernel '.agents/skills/sdd-verify/SKILL.md'))
$learn = [IO.File]::ReadAllText((Join-Path $kernel '.claude/skills/learn/SKILL.md'))
$guia = [IO.File]::ReadAllText((Join-Path $kit 'docs/como-usar-fluxo.md'))

Assert-Contem '[SPEC-FLUXO-001/C2] P1 e P2 aprovam a change inteira' $change 'documento completo'
Assert-Contem '[SPEC-FLUXO-001/C3] tasks agrupam suites sem gates por item' $change 'alvo'
Assert-Contem '[SPEC-FLUXO-001/C3] fecho exige seguranca proporcional com fallback' $change 'proporcional'
Assert-Contem '[SPEC-FLUXO-001/C3] verificador cobre a change completa' $verify '(?is)verifica a change completa'
Assert-Contem '[SPEC-FLUXO-001/C4] fecho valida a change inteira e deixa archive como proxima acao' ($flow + $verify) '(?is)validate.{0,300}verificador.{0,300}goal da change inteira'
Assert-Contem '[SPEC-FLUXO-001/C4] aprendizado considera a change inteira' $learn '(?is)fecho de change.{0,120}change completa.{0,120}requisito ou task'
Assert-Contem '[SPEC-FLUXO-001/C1] guia documenta limite de change' $guia '(?is)Limites por change.{0,150}250 linhas'
Exit-SddTeste
