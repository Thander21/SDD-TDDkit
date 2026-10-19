# Contrato de archive pela change inteira em repositorios temporarios.
# C1-C5 are covered in one target; each contract block carries its trace tag.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')
$kit = Get-SddKitPath
function Get-SddTreeForTest([string]$Dir, [string]$Kit) {
  $git = Join-Path (Split-Path $Dir -Parent) '.test-tree-index'
  $env:GIT_INDEX_FILE = $git
  try {
    Invoke-Git $Dir @('read-tree', 'HEAD') | Out-Null
    Invoke-Git $Dir @('add', '-A', '--', '.') | Out-Null
    Invoke-Git $Dir @('rm', '-r', '--cached', '-q', '--ignore-unmatch', '--', 'Docs/Specs/**', '.sdd/state/**') | Out-Null
    return Invoke-Git $Dir @('write-tree')
  } finally { Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue; Remove-Item $git -Force -ErrorAction SilentlyContinue }
}
$dir = New-SddTesteRepo -Nome 'archive'
try {
  Write-Arq $dir 'package.json' '{ "name": "archive-test", "private": true, "type": "module", "scripts": { "test": "node --test" } }'
  Write-Arq $dir 'src/x.js' "export const x = 1;`n"
  Write-Arq $dir 'test/x.test.js' "import { test } from 'node:test';`nimport assert from 'node:assert/strict';`ntest('[SPEC-MOTOR-002/C1] basic',()=>assert.equal(1,1));`n"
  Install-SddMotor -Dir $dir -Kit $kit -Perfil 'node'
  $pf = Join-Path $dir '.sdd/profile.json'
  $profileText = [System.IO.File]::ReadAllText($pf).Replace('"calibrado": false', '"calibrado": true').Replace('"isentos_frescor": [],', '"isentos_frescor": ["Docs/Specs/changes/*/verify.md"],')
  [System.IO.File]::WriteAllText($pf, $profileText)
  Write-Arq $dir 'Docs/Specs/capabilities/_index.md' "# Capabilities`n"
  $changeRel = 'Docs/Specs/changes/1-archive/change.md'
  $base = '0000000000000000000000000000000000000000'
  $txt = @"
---
id: CHG-001
title: Archive
status: In-Implementation
base_ref: $base
risk: []
capabilities: [motor]
impact:
  modified_files: []
  new_files: []
---

# Change

## Deltas

#### Requirement: SPEC-MOTOR-002 Archive

##### Scenario: C1 - Missing goal
##### Scenario: C2 - Valid evidence
##### Scenario: C3 - Stale tree
##### Scenario: C4 - Existing destination
##### Scenario: C5 - Commands remain available

## Tasks

- [x] RED (C1,C2,C3,C4,C5): test/archive.test.js -> Falha esperada: assertion
- [x] GREEN (C1,C2,C3,C4,C5): test/archive.test.js -> passou

## Excecoes

## Aprovacoes
- P1: aprovado por teste em 2026-10-18 10:00 (sdd approve; change.md antes: aaaaaaaaaaaa)
- P2: aprovado por teste em 2026-10-18 10:01 (sdd approve; change.md antes: bbbbbbbbbbbb)
"@
  Write-Arq $dir $changeRel $txt
  Write-Arq $dir '.gitignore' "`.sdd/state/`n"
  Invoke-Git $dir @('add', '-A') | Out-Null
  Invoke-Git $dir @('commit', '-qm', 'base') | Out-Null
  $base = Invoke-Git $dir @('rev-parse', 'HEAD')
  $changeText = [System.IO.File]::ReadAllText((Join-Path $dir $changeRel))
  $changeText = [regex]::Replace($changeText, '(?m)^base_ref: .*$', "base_ref: $base")
  Write-Arq $dir $changeRel $changeText
  Write-Arq $dir 'Docs/Specs/changes/1-archive/extra.txt' 'nao versionado, preservar'
  $changeDir = Join-Path $dir 'Docs/Specs/changes/1-archive'
  $dest = Join-Path $dir 'Docs/Specs/concluidas/1-archive'

  # [SPEC-MOTOR-002/C1] Missing/failed/pre-verify goals and invalid verify refuse.
  $snap = [System.IO.File]::ReadAllText((Join-Path $changeDir 'change.md'))
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C1 archive ausente recusa' $r.Texto 'GOAL PASS'
  Assert-Igual 'C1 status preservado' (([System.IO.File]::ReadAllText((Join-Path $changeDir 'change.md'))) -eq $snap) $true
  $invalid = '.sdd/state/goal-1-archive.json'
  Write-Arq $dir $invalid (@{ resultado='GOAL FAIL: validate'; arvore='0'; pre_verify=$false } | ConvertTo-Json)
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C1 GOAL FAIL recusa' $r.Texto 'GOAL PASS final'
  Write-Arq $dir $invalid (@{ resultado='GOAL PASS (pre-verify)'; arvore='0'; pre_verify=$true } | ConvertTo-Json)
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C1 pre-verify recusa' $r.Texto 'GOAL PASS final'
  Remove-Item -LiteralPath (Join-Path $dir $invalid) -Force
  $treeInvalid = Get-SddTreeForTest $dir $kit
  Write-Arq $dir $invalid (@{ resultado='GOAL PASS'; arvore=$treeInvalid; pre_verify=$false } | ConvertTo-Json)
  Write-Arq $dir (Join-Path 'Docs/Specs/changes/1-archive' 'verify.md') "Veredito: REPROVADO`narvore: $treeInvalid`n"
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C1 verify reprovado recusa' $r.Texto 'Veredito: APROVADO'
  Write-Arq $dir (Join-Path 'Docs/Specs/changes/1-archive' 'verify.md') "Veredito: APROVADO`narvore: 0000000000000000000000000000000000000000`n"
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C1 verify ausente ou stale recusa' $r.Texto 'verify.md ausente ou desatualizado'
  Remove-Item -LiteralPath (Join-Path $dir $invalid) -Force

  # [SPEC-MOTOR-002/C3] Stale goal tree refuses without moving the change.
  $tree = Get-SddTreeForTest $dir $kit
  $state = Join-Path $dir '.sdd/state'; New-Item -ItemType Directory -Path $state -Force | Out-Null
  Write-Arq $dir '.sdd/state/goal-1-archive.json' (@{ resultado='GOAL PASS'; arvore=$tree; pre_verify=$false } | ConvertTo-Json)
  Write-Arq $dir (Join-Path 'Docs/Specs/changes/1-archive' 'verify.md') "Veredito: APROVADO`narvore: $tree`n"
  Write-Arq $dir 'src/x.js' "export const x = 2;`n"
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C3 arvore desatualizada recusa' $r.Texto 'desatualizado'
  Assert-Igual 'C3 change continua na origem' (Test-Path -LiteralPath $changeDir) $true

  # [SPEC-MOTOR-002/C4] Existing destination refuses without touching either side.
  Write-Arq $dir 'src/x.js' "export const x = 1;`n"
  $tree = Get-SddTreeForTest $dir $kit
  Write-Arq $dir '.sdd/state/goal-1-archive.json' (@{ resultado='GOAL PASS'; arvore=$tree; pre_verify=$false } | ConvertTo-Json)
  Write-Arq $dir (Join-Path 'Docs/Specs/changes/1-archive' 'verify.md') "Veredito: APROVADO`narvore: $tree`n"
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Write-Arq $dir 'Docs/Specs/concluidas/1-archive/sentinela.txt' 'preservar'
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C4 destino existente recusa' $r.Texto 'destino|existe'
  Assert-Igual 'C4 origem preservada' (Test-Path -LiteralPath $changeDir) $true
  Assert-Igual 'C4 destino preservado' ([System.IO.File]::ReadAllText((Join-Path $dest 'sentinela.txt'))) 'preservar'
  Remove-Item -LiteralPath $dest -Recurse -Force

  # [SPEC-MOTOR-002/C4] A move setup failure restores status and source path.
  $destParent = Join-Path $dir 'Docs/Specs/concluidas'
  Remove-Item -LiteralPath $destParent -Recurse -Force
  Write-Arq $dir 'Docs/Specs/concluidas' 'arquivo que impede criar a pasta destino'
  $tree = Get-SddTreeForTest $dir $kit
  Write-Arq $dir '.sdd/state/goal-1-archive.json' (@{ resultado='GOAL PASS'; arvore=$tree; pre_verify=$false } | ConvertTo-Json)
  Write-Arq $dir (Join-Path 'Docs/Specs/changes/1-archive' 'verify.md') "Veredito: APROVADO`narvore: $tree`n"
  $beforeFailure = [System.IO.File]::ReadAllText((Join-Path $changeDir 'change.md'))
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C4 falha de movimento reportada' $r.Texto 'archive falhou'
  Assert-Igual 'C4 rollback preserva origem' (Test-Path -LiteralPath $changeDir) $true
  Assert-Igual 'C4 rollback restaura status' (([System.IO.File]::ReadAllText((Join-Path $changeDir 'change.md')) -eq $beforeFailure)) $true
  Assert-Igual 'C4 rollback preserva bloqueador' ([System.IO.File]::ReadAllText($destParent)) 'arquivo que impede criar a pasta destino'
  Remove-Item -LiteralPath $destParent -Force

  # [SPEC-MOTOR-002/C2] Current GOAL PASS and verify archive the full change.
  Write-Arq $dir 'src/x.js' "export const x = 1;`n"
  $tree = Get-SddTreeForTest $dir $kit
  # O proprio estado gerado pelo goal e ignorado na arvore; a arvore e estavel.
  Write-Arq $dir '.sdd/state/goal-1-archive.json' (@{ resultado='GOAL PASS'; arvore=$tree; pre_verify=$false } | ConvertTo-Json)
  Write-Arq $dir (Join-Path 'Docs/Specs/changes/1-archive' 'verify.md') "Veredito: APROVADO`narvore: $tree`n"
  $r = Invoke-Sdd $dir @('archive', '1')
  Assert-Contem 'C2 archive confirma movimento' $r.Texto 'ARCHIVED'
  Assert-Igual 'C2 destino criado' (Test-Path -LiteralPath $dest) $true
  Assert-Igual 'C2 origem removida' (Test-Path -LiteralPath $changeDir) $false
  Assert-Contem 'C2 status Done' ([System.IO.File]::ReadAllText((Join-Path $dest 'change.md'))) '(?m)^status: Done$'
  Assert-Igual 'C2 arquivo nao versionado preservado' ([System.IO.File]::ReadAllText((Join-Path $dest 'extra.txt'))) 'nao versionado, preservar'
  Assert-Igual 'C2 indice Git nao alterado' (Invoke-Git $dir @('write-tree')) (Invoke-Git $dir @('rev-parse', 'HEAD^{tree}'))

  # [SPEC-MOTOR-002/C5] Update adds archive and preserves check/goal commands.
  $legacy = New-SddTesteRepo -Nome 'archive-legacy'
  try {
    Install-SddMotor -Dir $legacy -Kit $kit -Perfil 'node'
    $oldMotor = Join-Path $legacy 'tools/sdd/sdd.ps1'
    $body = [System.IO.File]::ReadAllText($oldMotor)
    $body = $body.Replace("      'archive' { return (Invoke-SddArchive `$resto) }`n", '')
    [System.IO.File]::WriteAllText($oldMotor, $body)
    $r = Invoke-Sdd $legacy @('check')
    Assert-Igual 'C5 check continua disponivel sem archive' ($r.Codigo -eq 2) $false
    Assert-Contem 'C5 comandos anteriores continuam' $r.Texto 'SDD CHECK'
    Write-Arq $legacy 'Docs/Specs/changes/1-legado/change.md' "---`nid: CHG-001`ntitle: Legado`nstatus: Draft`ncapabilities: [calc]`nrisk: []`nimpact:`n  modified_files: []`n  new_files: []`n---`n`n## Perguntas em aberto`n`n## Deltas`n`n## Tasks`n"
    $r = Invoke-Sdd $legacy @('goal', '1', '--pre-verify')
    Assert-Igual 'C5 goal reconhecido pelo motor legado' ($r.Texto -match 'comando desconhecido') $false
    Assert-Contem 'C5 goal devolve resultado tipado' $r.Texto 'GOAL (PASS|FAIL)'
    Install-SddMotor -Dir $legacy -Kit $kit -Perfil 'node'
    $r = Invoke-Sdd $legacy @('ajuda')
    Assert-Contem 'C5 update acrescenta archive' $r.Texto 'archive <NN>'
    $r = Invoke-Sdd $legacy @('check')
    Assert-Igual 'C5 check continua depois do update' ($r.Codigo -eq 2) $false
  } finally { Remove-SddTesteRepo $legacy }
} finally { Remove-SddTesteRepo $dir }
Exit-SddTeste
