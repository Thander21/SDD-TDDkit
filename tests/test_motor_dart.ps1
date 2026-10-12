# Teste do parser dart-json (perfil flutter, variante dart puro) numa copia
# temporaria de um pacote Dart. Exige dart no PATH e acesso ao pub (pub get).
# Uso: powershell -File tests/test_motor_dart.ps1
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')
$kit = Split-Path -Parent $PSScriptRoot
$dir = New-SddTesteRepo -Nome 'dart'
try {
  Write-Arq $dir 'pubspec.yaml' "name: cobaia`nenvironment:`n  sdk: ^3.5.0`ndev_dependencies:`n  test: ^1.25.0`n"
  Write-Arq $dir 'lib/calc.dart' "int mul(int a, int b) => 0;`n"
  Write-Arq $dir 'test/calc_test.dart' "import 'package:test/test.dart';`nimport 'package:cobaia/calc.dart';`n`nvoid main() {`n  group('[SPEC-CALC-002] Multiplicacao', () {`n    test('[SPEC-CALC-002/C1] multiplica', () {`n      expect(mul(2, 3), 6);`n    });`n  });`n}`n"
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { Push-Location -LiteralPath $dir; & dart pub get 2>&1 | Out-Null; $pub = $LASTEXITCODE } finally { Pop-Location; $ErrorActionPreference = $old }
  Assert-Igual 'dart pub get' $pub 0
  Install-SddMotor -Dir $dir -Kit $kit -Perfil 'flutter'
  # Variante dart puro: troca flutter por dart no perfil instalado.
  $pf = Join-Path $dir '.sdd/profile.json'
  $txt = [System.IO.File]::ReadAllText($pf)
  $txt = $txt.Replace('"run": ["flutter", "test"', '"run": ["dart", "test"').Replace('["flutter", "analyze", "--fatal-infos"]', '["dart", "analyze", "--fatal-infos"]').Replace('{ "nome": "Testes", "cmd": ["flutter", "test"] }', '{ "nome": "Testes", "cmd": ["dart", "test"] }')
  [System.IO.File]::WriteAllText($pf, $txt)
  Invoke-Git $dir @('add', '-A') | Out-Null; Invoke-Git $dir @('commit', '-qm', 'base') | Out-Null

  $r = Invoke-Sdd $dir @('test', 'test/calc_test.dart')
  Assert-Contem 'RED dart = falha pelo relatorio' $r.Texto 'SDD TEST FALHA \(confianca: relatorio'
  Write-Arq $dir 'lib/calc.dart' "int mul(int a, int b) => a * b;`n"
  $r = Invoke-Sdd $dir @('test', 'test/calc_test.dart')
  Assert-Contem 'GREEN dart = passou' $r.Texto 'SDD TEST PASSOU'
  Write-Arq $dir 'test/sonda_test.dart' "import 'package:cobaia/nao_existe.dart';`nimport 'package:test/test.dart';`nvoid main() { test('x', () {}); }`n"
  $r = Invoke-Sdd $dir @('test', 'test/sonda_test.dart', '--sonda', 'carga')
  Assert-Contem 'import inexistente = carga (teste loading)' $r.Texto 'SDD TEST CARGA'
  Write-Arq $dir 'test/sonda_test.dart' "import 'package:test/test.dart';`nvoid main() { test('red', () { expect(1, 2); }); }`n"
  $r = Invoke-Sdd $dir @('test', 'test/sonda_test.dart', '--sonda', 'red')
  Assert-Contem 'expect falso = falha' $r.Texto 'SDD TEST FALHA'
  Write-Arq $dir 'test/sonda_test.dart' "import 'package:test/test.dart';`nvoid main() { test('erro', () { throw StateError('boom'); }); }`n"
  $r = Invoke-Sdd $dir @('test', 'test/sonda_test.dart')
  Assert-Contem 'excecao no corpo do teste = erro (nao RED)' $r.Texto 'SDD TEST ERRO'
  Write-Arq $dir 'test/sonda_test.dart' "void main() {}`n"
  $r = Invoke-Sdd $dir @('test', 'test/sonda_test.dart', '--sonda', 'zero')
  Assert-Contem 'main vazio = zero' $r.Texto 'SDD TEST ZERO'
  Remove-Item -LiteralPath (Join-Path $dir 'test/sonda_test.dart')
  $r = Invoke-Sdd $dir @('calibrate')
  Assert-Contem 'calibrate dart' $r.Texto 'CALIBRADO:'
} finally {
  Remove-SddTesteRepo $dir
}
Exit-SddTeste
