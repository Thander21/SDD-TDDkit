# Roda toda a suite do kit nos dois interpretadores (Windows PowerShell 5.1 e pwsh 7).
# Uso: powershell -File tests/run_all.ps1 [-Py <python de um venv com pytest e ruff>] [-SemDotnet] [-SemDart]
param([string]$Py, [switch]$SemDotnet, [switch]$SemDart)
$ErrorActionPreference = 'Stop'
$t = $PSScriptRoot
$falhou = @()
foreach ($ps in @('powershell', 'pwsh')) {
  if (-not (Get-Command $ps -ErrorAction SilentlyContinue)) { Write-Host "pulado: $ps ausente"; continue }
  $env:SDD_TESTE_PS = $ps
  $casos = @(@('test_guard.ps1'), @('test_install.ps1'), @('test_motor_node.ps1'), @('test_motor_regressao.ps1'))
  if ($Py) { $casos += , @('test_motor_stacks.ps1', '-Stack', 'python', '-Py', $Py) }
  if (-not $SemDotnet) { $casos += , @('test_motor_stacks.ps1', '-Stack', 'dotnet') }
  if (-not $SemDart) { $casos += , @('test_motor_dart.ps1') }
  foreach ($c in $casos) {
    $script = Join-Path $t $c[0]
    $resto = @()
    if ($c.Count -gt 1) { $resto = @($c[1..($c.Count - 1)]) }
    $out = & $ps -NoProfile -ExecutionPolicy Bypass -File $script @resto 2>&1
    $ultima = ($out | Select-Object -Last 1)
    Write-Host ("[{0}] {1} {2}: {3}" -f $ps, $c[0], ($resto -join ' '), $ultima)
    if ($LASTEXITCODE -ne 0) { $falhou += "$ps $($c[0]) $($resto -join ' ')"; $out | Where-Object { "$_" -match '^FAIL' } | ForEach-Object { Write-Host "    $_" } }
  }
}
if ($falhou.Count) { Write-Host "SUITE FAIL: $($falhou -join '; ')"; exit 1 }
Write-Host 'SUITE PASS'
exit 0
