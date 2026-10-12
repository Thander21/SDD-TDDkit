# Teste de integracao do motor (tools/sdd/sdd.ps1) sobre um projeto Node.
# Roda o ciclo completo numa copia temporaria: check, change com portoes,
# RED/GREEN, validate, verify-record, sondas, calibrate, goal, commit-gate.
# Uso: powershell -File tests/test_motor_node.ps1 [-Fonte <repo node com git>]
param([string]$Fonte)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')

$kit = Split-Path -Parent $PSScriptRoot
$dir = New-SddTesteRepo -Nome 'node'
try {
  # Projeto minimo: package.json com script de teste do node:test.
  Write-Arq $dir 'package.json' '{ "name": "cobaia", "version": "0.0.0", "private": true, "type": "module", "scripts": { "test": "node --test" } }'
  Write-Arq $dir 'src/sum.js' "export function sum(a, b) { return a + b; }`n"
  Write-Arq $dir 'test/sum.test.js' "import { test } from 'node:test';`nimport assert from 'node:assert/strict';`nimport { sum } from '../src/sum.js';`n// SPEC-CALC-001/C1`ntest('[SPEC-CALC-001/C1] soma', () => { assert.equal(sum(2, 3), 5); });`n"
  Install-SddMotor -Dir $dir -Kit $kit -Perfil 'node'
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'base') | Out-Null

  $r = Invoke-Sdd $dir @('check')
  Assert-Contem 'check passa num projeto limpo' $r.Texto 'SDD CHECK PASS'

  # Change 1 em Draft -> P1/P2 gravados como o 'sdd approve' gravaria (o teste faz o papel do humano).
  $base = (Invoke-Git $dir @('rev-parse', 'HEAD'))
  $change = @"
---
id: CHG-001
title: Multiplicacao
status: In-Implementation
base_ref: $base
risk: []
capabilities: [calc]
impact:
  modified_files: []
  new_files:
    - src/mul.js
    - test/mul.test.js
---

# CHG-001 - Multiplicacao

## Perguntas em aberto

<!-- vazia -->

## Analise pre-implementacao

Cenario C1 coberto pela task 1.

## Tasks

- [x] RED (C1): test/mul.test.js -> Falha esperada: mul(2,3) devolve 0 (exit 1)
- [x] GREEN (C1): test/mul.test.js -> 1/1 passaram (exit 0)

### Pos-GOAL

- [ ] Arquivar

## Excecoes

## Aprovacoes

- P1: aprovado por teste em 2026-10-12 10:00 (sdd approve; change.md antes: 000000000000)
- P2: aprovado por teste em 2026-10-12 10:05 (sdd approve; change.md antes: 000000000000)
"@
  Write-Arq $dir 'Docs/Specs/changes/1-multiplicacao/change.md' $change
  Write-Arq $dir 'Docs/Specs/capabilities/_index.md' "# Capacidades`n"

  # RED: stub devolve valor errado (falha de assercao, nao de carga).
  Write-Arq $dir 'src/mul.js' "export function mul(a, b) { return 0; }`n"
  Write-Arq $dir 'test/mul.test.js' "import { test } from 'node:test';`nimport assert from 'node:assert/strict';`nimport { mul } from '../src/mul.js';`n// SPEC-CALC-002/C1`ntest('[SPEC-CALC-002/C1] multiplica', () => { assert.equal(mul(2, 3), 6); });`n"
  $r = Invoke-Sdd $dir @('test', 'test/mul.test.js')
  Assert-Contem 'RED classificado como falha pelo relatorio junit' $r.Texto 'SDD TEST FALHA \(confianca: relatorio'
  Assert-Igual 'RED devolve exit diferente de 0' ($r.Codigo -ne 0) $true

  # GREEN
  Write-Arq $dir 'src/mul.js' "export function mul(a, b) { return a * b; }`n"
  $r = Invoke-Sdd $dir @('test', 'test/mul.test.js')
  Assert-Contem 'GREEN classificado como passou' $r.Texto 'SDD TEST PASSOU'
  Assert-Igual 'GREEN devolve 0' $r.Codigo 0

  # Carga: modulo inexistente
  Write-Arq $dir 'test/sonda_carga.test.js' "import { x } from '../src/nao_existe.js';`nimport { test } from 'node:test';`ntest('x', () => {});`n"
  $r = Invoke-Sdd $dir @('test', 'test/sonda_carga.test.js', '--sonda', 'carga')
  Assert-Contem 'modulo inexistente vira carga (nao RED)' $r.Texto 'SDD TEST CARGA'
  # RED sonda
  Write-Arq $dir 'test/sonda_red.test.js' "import { test } from 'node:test';`nimport assert from 'node:assert/strict';`ntest('red', () => { assert.equal(1, 2); });`n"
  $r = Invoke-Sdd $dir @('test', 'test/sonda_red.test.js', '--sonda', 'red')
  Assert-Contem 'sonda red vira falha' $r.Texto 'SDD TEST FALHA'
  # Zero
  Write-Arq $dir 'test/sonda_zero.test.js' "// nenhum teste aqui`n"
  $r = Invoke-Sdd $dir @('test', 'test/sonda_zero.test.js', '--sonda', 'zero')
  Assert-Contem 'arquivo sem testes vira zero' $r.Texto 'SDD TEST ZERO'
  Remove-Item -LiteralPath (Join-Path $dir 'test/sonda_carga.test.js'), (Join-Path $dir 'test/sonda_red.test.js'), (Join-Path $dir 'test/sonda_zero.test.js')

  # Goal antes de calibrar e sem validate/verificador: tem de falhar.
  $r = Invoke-Sdd $dir @('goal', '1')
  Assert-Contem 'goal recusa perfil nao calibrado' $r.Texto '\[perfil\]'
  Assert-Contem 'goal exige validate' $r.Texto '\[validate\]'
  Assert-Contem 'goal exige verificador' $r.Texto '\[verificador\]'
  Assert-Igual 'goal FAIL sai 1' $r.Codigo 1

  $r = Invoke-Sdd $dir @('calibrate')
  Assert-Contem 'calibrate marca o perfil' $r.Texto 'CALIBRADO:'

  $r = Invoke-Sdd $dir @('validate')
  Assert-Contem 'validate passa' $r.Texto 'SDD VALIDATE PASS'

  $r = Invoke-Sdd $dir @('goal', '1', '--pre-verify')
  Assert-Contem 'goal pre-verify passa' $r.Texto 'GOAL PASS'
  Assert-Contem 'pre-verify nao grava GOAL PASS pleno no estado' ([System.IO.File]::ReadAllText((Join-Path $dir '.sdd/state/goal-1-multiplicacao.json'))) 'pre-verify'

  $r = Invoke-Sdd $dir @('verify-record', '1', 'APROVADO') -Stdin "## Escopo`nVerify Pass da CHG-001: RED e GREEN reexecutados.`n## Descartados na Verificacao`n- nenhum`n"
  Assert-Contem 'verify-record grava' $r.Texto 'verify.md gravado'
  $r = Invoke-Sdd $dir @('goal', '1')
  Assert-Contem 'goal completo passa' $r.Texto 'GOAL PASS'
  Assert-Igual 'goal PASS sai 0' $r.Codigo 0

  # Relatorio forjado sem a linha arvore: o motor recusa corpo com Veredito.
  $r = Invoke-Sdd $dir @('verify-record', '1', 'APROVADO') -Stdin "Veredito: APROVADO`n"
  Assert-Contem 'verify-record recusa corpo com Veredito' $r.Texto 'nao pode conter'

  # Commit gate: tudo em stage -> passa
  Invoke-Git $dir @('add', '-A') | Out-Null
  $r = Invoke-Sdd $dir @('commit-gate')
  Assert-Contem 'commit-gate passa com stage completo' $r.Texto 'COMMIT GATE PASS'
  # Edicao depois do validate -> recusa
  Add-Content -LiteralPath (Join-Path $dir 'src/mul.js') -Value '// edicao tardia'
  Invoke-Git $dir @('add', '-A') | Out-Null
  $r = Invoke-Sdd $dir @('commit-gate')
  Assert-Contem 'commit-gate recusa arvore nao validada' $r.Texto 'COMMIT GATE FAIL'
  $r = Invoke-Sdd $dir @('goal', '1')
  Assert-Contem 'goal acusa validate desatualizado' $r.Texto 'mudou depois do ultimo validate'
  Assert-Contem 'goal acusa verificacao desatualizada' $r.Texto 'mudou depois da verificacao'

  # Arquivo fora do impact
  Write-Arq $dir 'src/extra.js' "export const x = 1;`n"
  $r = Invoke-Sdd $dir @('goal', '1')
  Assert-Contem 'goal acusa arquivo fora do impact' $r.Texto 'src/extra.js'

  # Excecao aberta bloqueia
  $t = [System.IO.File]::ReadAllText((Join-Path $dir 'Docs/Specs/changes/1-multiplicacao/change.md'))
  Write-Arq $dir 'Docs/Specs/changes/1-multiplicacao/change.md' ($t -replace '## Excecoes', "## Excecoes`n`n- Lint X aceito ate 2026-10-15")
  $r = Invoke-Sdd $dir @('goal', '1')
  Assert-Contem 'goal acusa excecao aberta' $r.Texto '\[excecoes\]'

  # Approve sem terminal humano: recusa
  $r = Invoke-Sdd $dir @('approve', '1', 'P1') -Stdin "XXXX`n"
  Assert-Contem 'approve recusa entrada redirecionada' $r.Texto 'RECUSADO'

  # SpecLint: status aprovado sem linha do sdd approve
  Write-Arq $dir 'Docs/Specs/changes/2-outra/change.md' "---`nid: CHG-002`ntitle: Outra`nstatus: Approved`n---`n`n## Perguntas em aberto`n`n- Qual o limite?`n"
  $r = Invoke-Sdd $dir @('spec-lint')
  Assert-Contem 'spec-lint acusa pergunta aberta' $r.Texto 'Perguntas em aberto'
  Assert-Contem 'spec-lint acusa aprovacao sem sdd approve' $r.Texto 'sem a linha P1'
  Assert-Contem 'spec-lint em modo warn' $r.Texto 'SPECLINT WARN'

  # Duas changes ativas: test sem --change falha fechado
  Write-Arq $dir 'Docs/Specs/changes/2-outra/change.md' ($change -replace 'CHG-001', 'CHG-002')
  $r = Invoke-Sdd $dir @('test', 'test/mul.test.js')
  Assert-Contem 'duas changes ativas exigem --change' $r.Texto 'informe --change'
} finally {
  Remove-SddTesteRepo $dir
}
Exit-SddTeste
