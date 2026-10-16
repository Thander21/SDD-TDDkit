# Corpus do guard de comando e do edit_guard (machine/). Alimenta o payload
# JSON real de cada IDE pelo stdin e confere a decisao.
# Uso: powershell -File tests/test_guard.ps1   (interprete do hook: SDD_TESTE_PS)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')
$kit = Split-Path -Parent $PSScriptRoot
$guard = Join-Path $kit 'machine/guard.ps1'
$edit = Join-Path $kit 'machine/edit_guard.ps1'
$ps = $env:SDD_TESTE_PS
if (-not $ps) { $ps = 'powershell' }

function Invoke-Hook([string]$Script, [string]$Plataforma, [string]$Payload) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $out = $Payload | & $ps -NoProfile -ExecutionPolicy Bypass -File $Script -Platform $Plataforma 2>&1 } finally { $ErrorActionPreference = $old }
  return (($out | ForEach-Object { "$_" }) -join "`n")
}

function Get-Decisao([string]$Saida, [string]$Plataforma) {
  if ($Plataforma -eq 'Claude') {
    if ([string]::IsNullOrWhiteSpace($Saida)) { return 'allow' }
    $j = $Saida | ConvertFrom-Json
    return [string]$j.hookSpecificOutput.permissionDecision
  }
  $j = $Saida | ConvertFrom-Json
  $map = @{ allow = 'allow'; force_ask = 'ask'; deny = 'deny' }
  return $map[[string]$j.decision]
}

function Test-Comando([string]$Cmd, [string]$Esperado, [string]$Plataforma = 'Claude') {
  if ($Plataforma -eq 'Claude') { $payload = @{ tool_name = 'Bash'; tool_input = @{ command = $Cmd } } | ConvertTo-Json -Compress -Depth 5 }
  else { $payload = @{ toolCall = @{ name = 'run_command'; args = @{ CommandLine = $Cmd; Cwd = 'C:/x' } } } | ConvertTo-Json -Compress -Depth 5 }
  $saida = Invoke-Hook $guard $Plataforma $payload
  try { $d = Get-Decisao $saida $Plataforma } catch { $d = "saida-invalida: $saida" }
  Assert-Igual "guard[$Plataforma] '$Cmd'" $d $Esperado
}

# --- precisam pedir confirmacao (incluem os bypasses do guard do ERP) ---
$ask = @(
  'git reset --hard', 'git -C . reset --hard', 'git.exe reset --hard', 'git "reset" --hard', 'C:\Program Files\Git\cmd\git.exe reset --hard',
  '& "C:\Program Files\Git\cmd\git.exe" reset --hard', 'git -C "C:\repo com espaco" push origin main', 'cd src; git clean -fd',
  'git push', 'git push --force origin main', 'git push origin +main', 'git push --delete origin x',
  'git commit -m wip', 'git commit -anm wip', 'git commit --no-verify -m wip',
  'git checkout .', 'git checkout -- src/a.cs', 'git checkout HEAD src/a.cs', 'git switch -f main', 'git restore src/a.cs',
  'git clean -xdf', 'git rebase -i HEAD~3', 'git branch -D feature', 'git stash drop', 'git stash clear',
  'git reflog expire --expire=now --all; git gc --prune=now', 'git filter-repo --path x', 'git lfs migrate import --include="*.psd"',
  'git -c alias.x="reset --hard" x', 'git -c core.hooksPath=/dev/null commit -m x', 'git update-ref -d refs/heads/main',
  'rm -rf build', 'rm --recursive --force build', 'rm -r build', 'Remove-Item -Recurse build', 'ri -r build', 'rmdir /s /q build', 'del /s /q *.tmp',
  '& git @(''reset'',''--hard'')', 'Start-Process git -ArgumentList ''reset'',''--hard''',
  'iex (Get-Content x.txt -Raw)', 'powershell -EncodedCommand ZwBpAHQAIAByAGUAcwBlAHQAIAAtAC0AaABhAHIAZAA=',
  'psql -c "DROP TABLE vendas"', 'sqlite3 db.sqlite "DELETE FROM vendas;"', 'npx prisma migrate reset',
  'claude -p x --dangerously-skip-permissions', 'Add-Content Docs/Specs/changes/1-x/evidence.jsonl ''{}''', 'echo x > Docs/Specs/changes/1-x/verify.md',
  'powershell -File tools/sdd/sdd.ps1 approve 1 P1', 'docker system prune -af',
  '$r | powershell -File tools/sdd/sdd.ps1 verify-record 1 APROVADO'
)
# --- devem passar sem pergunta ---
$allow = @(
  'git status', 'git diff HEAD', 'git log --oneline -5', 'git checkout main', 'git switch -c feat/x', 'git add -A', 'git stash', 'git stash list',
  'git branch', 'git branch -d merged', 'git reset src/a.cs', 'git fetch origin', 'git rm --cached secrets.txt',
  'rm arquivo.txt', 'Remove-Item arquivo.txt', 'npm.cmd test', 'dotnet build -warnaserror', 'cargo test --lib',
  'powershell -File tools/sdd/sdd.ps1 check', 'powershell -File tools/sdd/sdd.ps1 test tests/x_test.py', 'Get-Content Docs/Specs/changes/1-x/evidence.jsonl',
  'docker ps', 'python -m pytest -q'
)
foreach ($c in $ask) { Test-Comando $c 'ask' }
foreach ($c in $allow) { Test-Comando $c 'allow' }
foreach ($c in @('git push --force origin main', 'git checkout .', 'Remove-Item -Recurse build')) { Test-Comando $c 'ask' 'Antigravity' }
foreach ($c in @('git status', 'npm.cmd test')) { Test-Comando $c 'allow' 'Antigravity' }

# Payload vazio ou invalido: falha fechada (pede confirmacao)
Assert-Igual 'guard sem payload pede confirmacao' (Get-Decisao (Invoke-Hook $guard 'Claude' '') 'Claude') 'ask'
Assert-Igual 'guard com JSON invalido pede confirmacao' (Get-Decisao (Invoke-Hook $guard 'Claude' '{nao json') 'Claude') 'ask'

# --- edit_guard ---
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('sdd-edit-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
$chg = Join-Path $tmp 'Docs/Specs/changes/1-x/change.md'
New-Item -ItemType Directory -Path (Split-Path -Parent $chg) -Force | Out-Null
[System.IO.File]::WriteAllText($chg, "---`nid: CHG-001`ntitle: X`nstatus: Draft`n---`n`n## Aprovacoes`n", (New-Object System.Text.UTF8Encoding $false))
function Test-Edicao([string]$Nome, [hashtable]$Entrada, [string]$Esperado, [string]$Ferr = 'Edit') {
  $payload = @{ tool_name = $Ferr; tool_input = $Entrada } | ConvertTo-Json -Compress -Depth 5
  $d = Get-Decisao (Invoke-Hook $edit 'Claude' $payload) 'Claude'
  Assert-Igual "edit_guard: $Nome" $d $Esperado
}
Test-Edicao 'Edit Draft->Approved nega' @{ file_path = $chg; old_string = 'status: Draft'; new_string = 'status: Approved' } 'deny'
Test-Edicao 'Edit so troca a palavra Draft->In-Implementation nega' @{ file_path = $chg; old_string = 'Draft'; new_string = 'In-Implementation' } 'deny'
Test-Edicao 'Write com status Approved nega' @{ file_path = $chg; content = "---`nid: CHG-001`ntitle: X`nstatus: Approved`n---`n" } 'deny' 'Write'
Test-Edicao 'forjar linha de aprovacao nega' @{ file_path = $chg; old_string = '## Aprovacoes'; new_string = "## Aprovacoes`n- P1: aprovado por x (sdd approve; y)" } 'deny'
# CHG-002: aprovacao por frase passa pelo guard de comando (ask) e a linha nova, com "via chat", continua so do motor.
Test-Comando 'powershell -File tools/sdd/sdd.ps1 approve 01 P1 --frase "aprovo P1 da change 01"' 'ask'
Test-Edicao 'R-3 forjar linha de aprovacao com via chat nega' @{ file_path = $chg; old_string = '## Aprovacoes'; new_string = "## Aprovacoes`n- P1: aprovado por x em 2026-10-14 10:00 (sdd approve; via chat: `"aprovo P1 da change 01`"; change.md antes: y)" } 'deny'
Test-Edicao 'gravar base_ref nega' @{ file_path = $chg; old_string = 'status: Draft'; new_string = "status: Draft`nbase_ref: abc123" } 'deny'
Test-Edicao 'status Done pede confirmacao' @{ file_path = $chg; old_string = 'status: Draft'; new_string = 'status: Done' } 'ask'
Test-Edicao 'edicao comum no change.md passa' @{ file_path = $chg; old_string = 'title: X'; new_string = 'title: Y' } 'allow'
Test-Edicao 'evidence.jsonl nega' @{ file_path = (Join-Path $tmp 'Docs/Specs/changes/1-x/evidence.jsonl'); content = '{}' } 'deny' 'Write'
Test-Edicao 'verify.md nega' @{ file_path = (Join-Path $tmp 'Docs/Specs/changes/1-x/verify.md'); content = 'Veredito: APROVADO' } 'deny' 'Write'
Test-Edicao 'profile.json pede confirmacao' @{ file_path = (Join-Path $tmp '.sdd/profile.json'); content = '{}' } 'ask' 'Write'
Test-Edicao 'motor do kit pede confirmacao' @{ file_path = (Join-Path $tmp 'tools/sdd/sdd.ps1'); content = '#' } 'ask' 'Write'
Test-Edicao 'codigo comum passa' @{ file_path = (Join-Path $tmp 'src/a.cs'); content = 'class A {}' } 'allow' 'Write'
Test-Edicao 'status entre aspas Draft->"Approved" nega' @{ file_path = $chg; old_string = 'status: Draft'; new_string = 'status: "Approved"' } 'deny'
Test-Edicao '.sdd/state/last-full.json nega' @{ file_path = (Join-Path $tmp '.sdd/state/last-full.json'); content = '{}' } 'deny' 'Write'
# Projeto com specs_root proprio: verify.md e change.md protegidos fora de uma pasta 'specs'.
$proj = Join-Path $tmp 'proj2'
New-Item -ItemType Directory -Path (Join-Path $proj '.sdd') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $proj '.sdd/profile.json'), '{ "projeto": { "specs_root": "docs/sdd" } }')
$chg2 = Join-Path $proj 'docs/sdd/changes/1-x/change.md'
New-Item -ItemType Directory -Path (Split-Path -Parent $chg2) -Force | Out-Null
[System.IO.File]::WriteAllText($chg2, "---`nid: CHG-001`ntitle: X`nstatus: Approved`n---`n", (New-Object System.Text.UTF8Encoding $false))
Test-Edicao 'specs_root proprio: verify.md nega' @{ file_path = (Join-Path $proj 'docs/sdd/changes/1-x/verify.md'); content = 'x' } 'deny' 'Write'
Test-Edicao 'specs_root proprio: Approved->In-Implementation nega' @{ file_path = $chg2; old_string = 'status: Approved'; new_string = 'status: In-Implementation' } 'deny'
$payloadAg = @{ toolCall = @{ name = 'replace_file_content'; args = @{ TargetFile = $chg; TargetContent = 'status: Draft'; ReplacementContent = 'status: Approved' } } } | ConvertTo-Json -Compress -Depth 5
Assert-Igual 'edit_guard[Antigravity] Draft->Approved nega' (Get-Decisao (Invoke-Hook $edit 'Antigravity' $payloadAg) 'Antigravity') 'deny'
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Exit-SddTeste
