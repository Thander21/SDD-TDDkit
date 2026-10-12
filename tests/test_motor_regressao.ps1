# Regressoes da verificacao independente de 12/10/2026 (A1-A6, M4, M6, sondas).
# Cada caso reproduz o cenario que dava PASS falso ou travava uso legitimo.
# Uso: powershell -File tests/test_motor_regressao.ps1
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')
$kit = Split-Path -Parent $PSScriptRoot

function New-Repo {
  $d = New-SddTesteRepo -Nome 'regr'
  Write-Arq $d 'package.json' '{ "name": "r", "private": true, "type": "module", "scripts": { "test": "node --test" } }'
  Write-Arq $d 'src/sum.js' "export function sum(a, b) { return a + b; }`n"
  Write-Arq $d 'test/sum.test.js' "import { test } from 'node:test';`nimport assert from 'node:assert/strict';`nimport { sum } from '../src/sum.js';`ntest('[SPEC-CALC-001/C1] soma', () => { assert.equal(sum(2, 3), 5); });`n"
  # Runner falso: grava o relatorio JUnit pedido e sai com o codigo pedido.
  Write-Arq $d 'tools/fake.js' "import { writeFileSync } from 'node:fs';`nconst [rel, modo] = [process.argv[2], process.argv[3]];`nconst caso = modo === 'erro' ? '<testcase name=`"x`"><error message=`"boom`"/></testcase>' : '<testcase name=`"x`"/>';`nwriteFileSync(rel, '<testsuites><testsuite>' + caso + '</testsuite></testsuites>');`nprocess.exit(modo === 'verde' ? 0 : 1);`n"
  Install-SddMotor -Dir $d -Kit $kit -Perfil 'node'
  $pf = Join-Path $d '.sdd/profile.json'
  $t = [System.IO.File]::ReadAllText($pf).Replace('"calibrado": false', '"calibrado": true').Replace('"riscos_com_fonte": []', '"riscos_com_fonte": ["dinheiro"]')
  [System.IO.File]::WriteAllText($pf, $t)
  Write-Arq $d 'Docs/Specs/capabilities/_index.md' "# Capacidades`n"
  Invoke-Git $d @('add', '-A') | Out-Null; Invoke-Git $d @('commit', '-qm', 'base') | Out-Null
  return $d
}

function Write-Change([string]$Dir, [string]$Nome, [string]$Id, [string]$Fm, [string]$Corpo, [switch]$SemP1) {
  $base = Invoke-Git $Dir @('rev-parse', 'HEAD')
  $p1 = '- P1: aprovado por teste em 2026-10-12 10:00 (sdd approve; change.md antes: 000000000000)'
  if ($SemP1) { $p1 = '' }
  $txt = "---`nid: $Id`ntitle: Teste`nstatus: In-Implementation`nbase_ref: $base`n$Fm---`n`n## Perguntas em aberto`n`n## Analise pre-implementacao`n`nok`n`n$Corpo`n`n## Excecoes`n`n## Aprovacoes`n`n$p1`n- P2: aprovado por teste em 2026-10-12 10:05 (sdd approve; change.md antes: 000000000000)`n"
  Write-Arq $Dir "Docs/Specs/changes/$Nome/change.md" $txt
}

$dirs = @()
try {
  # A1: change sem nenhuma evidencia de teste nao passa.
  $d = New-Repo; $dirs += $d
  Write-Change $d '1-sem-teste' 'CHG-001' "impact:`n  modified_files: []`n  new_files: []`n" "## Tasks`n`n- [x] Implementar o pagamento`n"
  $r = Invoke-Sdd $d @('goal', '1', '--pre-verify')
  Assert-Contem 'A1 goal reprova change sem evidencia' $r.Texto 'change sem evidencia de teste'

  # A1b: cenario declarado sem RED/GREEN reprova; com RED/GREEN com lastro, passa nesse criterio.
  Write-Arq $d 'src/mul.js' "export function mul(a, b) { return 0; }`n"
  Write-Arq $d 'test/mul.test.js' "import { test } from 'node:test';`nimport assert from 'node:assert/strict';`nimport { mul } from '../src/mul.js';`ntest('[SPEC-CALC-002/C1] mul', () => { assert.equal(mul(2, 3), 6); });`n"
  $deltas = "## Deltas`n`n#### Requirement: SPEC-CALC-002 x`n`n##### Scenario: C1 - multiplica`n`n##### Scenario: C2 - zero`n`n## Tasks`n`n- [x] RED (C1): test/mul.test.js -> Falha esperada: 6`n- [x] GREEN (C1): test/mul.test.js -> passou`n"
  Write-Change $d '2-cenarios' 'CHG-002' "impact:`n  modified_files: []`n  new_files: [src/mul.js, test/mul.test.js]`n" $deltas
  Remove-Item -LiteralPath (Join-Path $d 'Docs/Specs/changes/1-sem-teste') -Recurse -Force
  $null = Invoke-Sdd $d @('test', 'test/mul.test.js')
  Write-Arq $d 'src/mul.js' "export function mul(a, b) { return a * b; }`n"
  $null = Invoke-Sdd $d @('test', 'test/mul.test.js')
  $r = Invoke-Sdd $d @('goal', '2', '--pre-verify')
  Assert-Contem 'A1b cenario C2 sem RED/GREEN reprova' $r.Texto 'cenario C2 sem RED e GREEN'
  Assert-Igual 'A1b cenario C1 com lastro nao reprova' ($r.Texto -match 'cenario C1 sem') $false

  # A2: arquivo que entrou por commit depois do base_ref vira aviso, nao FAIL.
  Invoke-Git $d @('add', '-A') | Out-Null; Invoke-Git $d @('commit', '-qm', 'trabalho') | Out-Null
  Write-Arq $d 'lib/outra_frente.txt' 'merge da main'
  Invoke-Git $d @('add', '-A') | Out-Null; Invoke-Git $d @('commit', '-qm', 'outra frente') | Out-Null
  $r = Invoke-Sdd $d @('goal', '2', '--pre-verify')
  Assert-Contem 'A2 commit de outra frente vira aviso' $r.Texto 'outra_frente\.txt \(entrou por commit'
  Assert-Igual 'A2 sem FAIL de impact por commit' ($r.Texto -match '\[fora do impact\]') $false

  # A3: caminho com acento no impact e na pasta de specs.
  $t = [System.IO.File]::ReadAllText((Join-Path $d 'Docs/Specs/changes/2-cenarios/change.md'), [System.Text.Encoding]::UTF8)
  $t = $t.Replace('new_files: [src/mul.js, test/mul.test.js]', "new_files: [src/mul.js, test/mul.test.js, src/configuracao" + [char]0x00E7 + [char]0x00E3 + "o.txt]")
  Write-Arq $d 'Docs/Specs/changes/2-cenarios/change.md' $t
  Write-Arq $d ("src/configuracao" + [char]0x00E7 + [char]0x00E3 + "o.txt") 'x'
  Write-Arq $d ("Docs/Specs/backlog/07 - Relat" + [char]0x00F3 + "rio.md") 'x'
  $r = Invoke-Sdd $d @('goal', '2', '--pre-verify')
  Assert-Igual 'A3 caminho acentuado no impact nao reprova' ($r.Texto -match '\[fora do impact\]') $false
  Assert-Contem 'A3 backlog acentuado vira aviso' $r.Texto 'Docs/Specs/backlog/07 - Relat.rio\.md \(pasta de specs'

  # A4 e A5: sem P1, e risco que exige fonte sem fonte_normativa.
  Write-Change $d '2-cenarios' 'CHG-002' "risk: [dinheiro]`nimpact:`n  modified_files: []`n  new_files: [src/mul.js, test/mul.test.js]`n" $deltas -SemP1
  $r = Invoke-Sdd $d @('goal', '2', '--pre-verify')
  Assert-Contem 'A4 goal exige P1' $r.Texto 'sem aprovacao P1'
  Assert-Contem 'A5 goal exige fonte_normativa' $r.Texto "risk 'dinheiro' exige fonte_normativa"

  # A6 e M4: classificacao com runner falso.
  $d2 = New-Repo; $dirs += $d2
  $pf = Join-Path $d2 '.sdd/profile.json'
  $t = [System.IO.File]::ReadAllText($pf)
  $t = $t.Replace('"build": ["node", "--check", "{alvo}"],', '').Replace('"run": ["node", "--test", "--test-reporter=spec", "--test-reporter-destination=stdout", "--test-reporter=junit", "--test-reporter-destination={relatorio}", "{alvo}"]', '"run": ["node", "tools/fake.js", "{relatorio}", "{alvo}"]')
  [System.IO.File]::WriteAllText($pf, $t)
  $r = Invoke-Sdd $d2 @('test', 'exit1')
  Assert-Contem 'A6 relatorio verde com exit 1 = inconsistente' $r.Texto 'SDD TEST INCONSISTENTE'
  $r = Invoke-Sdd $d2 @('test', 'erro')
  Assert-Contem 'M4 excecao (error) nao vale como RED' $r.Texto 'SDD TEST ERRO'
  $r = Invoke-Sdd $d2 @('test', 'verde')
  Assert-Contem 'controle: verde com exit 0 = passou' $r.Texto 'SDD TEST PASSOU'
  $r = Invoke-Sdd $d2 @('test', '^Jogo\.Teste$')
  Assert-Igual 'M6 alvo com ^ e $ aceito' ($r.Texto -match 'caractere proibido') $false

  # M6: {raiz} resolvido nos gates.
  $t = [System.IO.File]::ReadAllText($pf).Replace('"light": [', '"light": [ { "nome": "Raiz", "cmd": ["node", "-e", "process.exit(0)", "{raiz}"] },')
  [System.IO.File]::WriteAllText($pf, $t)
  $r = Invoke-Sdd $d2 @('check')
  Assert-Igual 'M6 {raiz} resolvido no gate' ($r.Texto -match 'sem valor') $false

  # Sondas: so valem com o perfil atual (perfil alterado depois = sondas pendentes).
  $d3 = New-Repo; $dirs += $d3
  Write-Arq $d3 'test/s1.test.js' "import { x } from '../src/nao_existe.js';`nimport { test } from 'node:test';`ntest('x', () => {});`n"
  $null = Invoke-Sdd $d3 @('test', 'test/s1.test.js', '--sonda', 'carga')
  Write-Arq $d3 'test/s1.test.js' "import { test } from 'node:test';`nimport assert from 'node:assert/strict';`ntest('red', () => { assert.equal(1, 2); });`n"
  $null = Invoke-Sdd $d3 @('test', 'test/s1.test.js', '--sonda', 'red')
  Write-Arq $d3 'test/s1.test.js' "// vazio`n"
  $null = Invoke-Sdd $d3 @('test', 'test/s1.test.js', '--sonda', 'zero')
  Remove-Item -LiteralPath (Join-Path $d3 'test/s1.test.js')
  $pf3 = Join-Path $d3 '.sdd/profile.json'
  [System.IO.File]::WriteAllText($pf3, [System.IO.File]::ReadAllText($pf3).Replace('"NO_COLOR": "1"', '"NO_COLOR": "1", "X_PERFIL_NOVO": "1"'))
  $r = Invoke-Sdd $d3 @('calibrate')
  Assert-Contem 'sondas de perfil antigo nao calibram' $r.Texto 'Sondas pendentes'
} finally {
  foreach ($x in $dirs) { Remove-SddTesteRepo $x }
}
Exit-SddTeste
