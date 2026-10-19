# Teste de classificacao RED/GREEN/carga/zero e de check/validate/calibrate
# nos perfis python e dotnet, numa copia temporaria de um projeto minimo.
# Uso: powershell -File tests/test_motor_stacks.ps1 -Stack python|dotnet [-Py <python do venv com pytest e ruff>]
param([Parameter(Mandatory = $true)][ValidateSet('python', 'dotnet')][string]$Stack, [string]$Py)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')

$kit = Get-SddKitPath
$dir = New-SddTesteRepo -Nome $Stack
try {
  if ($Stack -eq 'python') {
    if (-not $Py) { throw 'informe -Py com o python de um venv que tenha pytest e ruff' }
    Write-Arq $dir 'src/__init__.py' ''
    Write-Arq $dir 'src/calc.py' "def mul(a, b):`n    return 0`n"
    Write-Arq $dir 'tests/__init__.py' ''
    Write-Arq $dir 'tests/test_calc.py' "from src.calc import mul`n`n`n# SPEC-CALC-002/C1`ndef test_spec_calc_002_c1_multiplica():`n    assert mul(2, 3) == 6`n"
    Write-Arq $dir 'pyproject.toml' "[tool.pytest.ini_options]`ntestpaths = [`"tests`"]`n"
    Install-SddMotor -Dir $dir -Kit $kit -Perfil 'python' -Vars @{ PY = $Py }
    $alvo = 'tests/test_calc.py'
    $verde = { Write-Arq $dir 'src/calc.py' "def mul(a, b):`n    return a * b`n" }
    $sondaCarga = { Write-Arq $dir 'tests/test_sonda.py' "import nao_existe_modulo`n`n`ndef test_x():`n    assert True`n"; 'tests/test_sonda.py' }
    $sondaRed = { Write-Arq $dir 'tests/test_sonda.py' "def test_red():`n    assert 1 == 2`n"; 'tests/test_sonda.py' }
    $sondaZero = { Write-Arq $dir 'tests/test_sonda.py' "def ajuda():`n    return 1`n"; 'tests/test_sonda.py' }
    $limpar = { Remove-Item -LiteralPath (Join-Path $dir 'tests/test_sonda.py') -ErrorAction SilentlyContinue }
  } else {
    $src = Join-Path $dir 'src/Calc'
    $tst = Join-Path $dir 'tests/Calc.Tests'
    Write-Arq $dir 'Calc.sln' ''
    Remove-Item -LiteralPath (Join-Path $dir 'Calc.sln')
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
      Push-Location -LiteralPath $dir
      & dotnet new sln -n Calc -o . 2>&1 | Out-Null
      & dotnet new classlib -n Calc -o $src 2>&1 | Out-Null
      & dotnet new xunit -n Calc.Tests -o $tst 2>&1 | Out-Null
      & dotnet sln add (Join-Path $src 'Calc.csproj') (Join-Path $tst 'Calc.Tests.csproj') 2>&1 | Out-Null
      & dotnet add (Join-Path $tst 'Calc.Tests.csproj') reference (Join-Path $src 'Calc.csproj') 2>&1 | Out-Null
    } finally { Pop-Location; $ErrorActionPreference = $old }
    Remove-Item -LiteralPath (Join-Path $src 'Class1.cs'), (Join-Path $tst 'UnitTest1.cs') -ErrorAction SilentlyContinue
    Write-Arq $dir 'src/Calc/Calculator.cs' "namespace Calc;`n`npublic static class Calculator`n{`n    public static int Mul(int a, int b) => 0;`n}`n"
    Write-Arq $dir 'tests/Calc.Tests/MulTests.cs' "using Calc;`n`nnamespace Calc.Tests;`n`npublic class MulTests`n{`n    // SPEC-CALC-002/C1`n    [Fact]`n    [Trait(`"Spec`", `"SPEC-CALC-002/C1`")]`n    public void Mul_MultiplicaDoisInteiros()`n    {`n        Assert.Equal(6, Calculator.Mul(2, 3));`n    }`n}`n"
    Write-Arq $dir '.gitignore' "bin/`nobj/`nTestResults/`n"
    Install-SddMotor -Dir $dir -Kit $kit -Perfil 'dotnet'
    $alvo = 'FullyQualifiedName~Calc.Tests.MulTests'
    $verde = { Write-Arq $dir 'src/Calc/Calculator.cs' "namespace Calc;`n`npublic static class Calculator`n{`n    public static int Mul(int a, int b) => a * b;`n}`n" }
    $sondaCarga = { Write-Arq $dir 'tests/Calc.Tests/SondaTests.cs' "namespace Calc.Tests;`npublic class SondaTests { [Fact] public void X() { Calc.Calculator.NaoExiste(); } }`n"; 'FullyQualifiedName~Calc.Tests.SondaTests' }
    $sondaRed = { Write-Arq $dir 'tests/Calc.Tests/SondaTests.cs' "namespace Calc.Tests;`npublic class SondaTests { [Fact] public void X() { Assert.Equal(1, 2); } }`n"; 'FullyQualifiedName~Calc.Tests.SondaTests' }
    $sondaZero = { Remove-Item -LiteralPath (Join-Path $dir 'tests/Calc.Tests/SondaTests.cs') -ErrorAction SilentlyContinue; 'FullyQualifiedName~Calc.Tests.NaoExiste' }
    $limpar = { Remove-Item -LiteralPath (Join-Path $dir 'tests/Calc.Tests/SondaTests.cs') -ErrorAction SilentlyContinue }
  }
  Invoke-Git $dir @('add', '-A') | Out-Null
  Invoke-Git $dir @('commit', '-qm', 'base') | Out-Null

  $r = Invoke-Sdd $dir @('check')
  Assert-Contem "[$Stack] check passa" $r.Texto 'SDD CHECK PASS'

  $r = Invoke-Sdd $dir @('test', $alvo)
  Assert-Contem "[$Stack] RED = falha pelo relatorio" $r.Texto 'SDD TEST FALHA \(confianca: relatorio'
  & $verde
  $r = Invoke-Sdd $dir @('test', $alvo)
  Assert-Contem "[$Stack] GREEN = passou" $r.Texto 'SDD TEST PASSOU'

  $a = & $sondaCarga
  $r = Invoke-Sdd $dir @('test', $a, '--sonda', 'carga')
  Assert-Contem "[$Stack] erro de compilacao/import = carga" $r.Texto 'SDD TEST CARGA'
  $a = & $sondaRed
  $r = Invoke-Sdd $dir @('test', $a, '--sonda', 'red')
  Assert-Contem "[$Stack] assercao falsa = falha" $r.Texto 'SDD TEST FALHA'
  $a = & $sondaZero
  $r = Invoke-Sdd $dir @('test', $a, '--sonda', 'zero')
  Assert-Contem "[$Stack] filtro sem testes = zero" $r.Texto 'SDD TEST ZERO'
  & $limpar

  $r = Invoke-Sdd $dir @('calibrate')
  Assert-Contem "[$Stack] calibrate" $r.Texto 'CALIBRADO:'
  $r = Invoke-Sdd $dir @('status')
  Assert-Contem "[$Stack] status mostra calibrado" $r.Texto 'calibrado: True'
  Assert-Contem "[$Stack] status mostra full na arvore atual" $r.Texto 'full: PASS .*arvore atual'
} finally {
  Remove-SddTesteRepo $dir
}
Exit-SddTeste
