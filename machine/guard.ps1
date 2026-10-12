# =====================================================================
# sdd-kit | machine/guard.ps1  (hook PreToolUse de COMANDO, escopo da maquina)
# Pede confirmacao (ask/force_ask) antes de comando destrutivo ou reservado
# ao usuario. Claude Code (Bash|PowerShell) e Antigravity (run_command).
# Modelo de ameaca: agente cooperativo mas descuidado. NAO e fronteira de
# seguranca contra forja deliberada (script novo, subprocesso, alias): no
# Windows nativo nao ha sandbox. Falha FECHADA: erro interno pede confirmacao.
# Compativel com Windows PowerShell 5.1 e PowerShell 7. Fonte em ASCII.
# =====================================================================
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][ValidateSet('Antigravity', 'Claude')][string] $Platform,
  # So para testes: analisa este comando em vez de ler o payload do stdin.
  [string] $Comando
)
$ErrorActionPreference = 'Stop'

function Write-SddResposta([string]$Decisao, [string]$Motivo) {
  if ($Platform -eq 'Claude') {
    if ($Decisao -eq 'allow') { return }
    $o = @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = $Decisao; permissionDecisionReason = $Motivo } }
  } else {
    $map = @{ allow = 'allow'; ask = 'force_ask'; deny = 'deny' }
    $o = @{ decision = $map[$Decisao] }
    if ($Motivo) { $o['reason'] = $Motivo }
  }
  [Console]::Out.WriteLine(($o | ConvertTo-Json -Compress -Depth 6))
}

function Read-SddStdin {
  $r = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), (New-Object System.Text.UTF8Encoding $false), $true)
  try { return $r.ReadToEnd() } finally { $r.Dispose() }
}

# Divide em tokens respeitando aspas simples e duplas; remove as aspas.
function Split-SddTokens([string]$Texto) {
  $tokens = New-Object System.Collections.ArrayList
  $sb = New-Object System.Text.StringBuilder
  $aspa = [char]0
  $tem = $false
  foreach ($ch in $Texto.ToCharArray()) {
    if ($aspa -ne [char]0) {
      if ($ch -eq $aspa) { $aspa = [char]0 } else { [void]$sb.Append($ch) }
      continue
    }
    if ($ch -eq '"' -or $ch -eq "'") { $aspa = $ch; $tem = $true; continue }
    if ([char]::IsWhiteSpace($ch)) {
      if ($sb.Length -gt 0 -or $tem) { [void]$tokens.Add($sb.ToString()); [void]$sb.Clear(); $tem = $false }
      continue
    }
    [void]$sb.Append($ch)
  }
  if ($sb.Length -gt 0 -or $tem) { [void]$tokens.Add($sb.ToString()) }
  return @($tokens)
}

# Segmentos de comando: separa por ; && || | & e quebra de linha (fora de aspas, aproximado).
function Split-SddSegmentos([string]$Texto) {
  return @([regex]::Split($Texto, '\r?\n|;|&&|\|\||\||(?<![<>2*])&(?![>&])') | Where-Object { $_.Trim() -ne '' })
}

function Test-SddFlag([string[]]$Args2, [string[]]$Longas, [string]$Curtas) {
  foreach ($a in $Args2) {
    $l = $a.ToLowerInvariant()
    foreach ($f in $Longas) { if ($l -eq $f -or $l.StartsWith($f + '=')) { return $true } }
    if ($Curtas -and $a -match '^-[A-Za-z]+$' -and -not $a.StartsWith('--')) {
      foreach ($c in $Curtas.ToCharArray()) { if ($a.Substring(1).Contains([string]$c)) { return $true } }
    }
  }
  return $false
}

# Regras do git, depois de normalizar opcoes globais (-C, -c, --git-dir...).
function Get-SddMotivoGit([string[]]$Tokens) {
  $i = 0
  $aliasInline = $false
  while ($i -lt $Tokens.Count) {
    $t = $Tokens[$i]
    $tl = $t.ToLowerInvariant()
    if ($t -ceq '-c') {
      if ($i + 1 -lt $Tokens.Count -and $Tokens[$i + 1].ToLowerInvariant().StartsWith('alias.')) { $aliasInline = $true }
      if ($i + 1 -lt $Tokens.Count -and $Tokens[$i + 1].ToLowerInvariant().StartsWith('core.hookspath')) { return 'git -c core.hooksPath desliga hooks: confirme.' }
      $i += 2; continue
    }
    if ($t -ceq '-C' -or $tl -eq '--git-dir' -or $tl -eq '--work-tree' -or $tl -eq '--namespace' -or $tl -eq '--exec-path') { $i += 2; continue }
    if ($tl.StartsWith('--git-dir=') -or $tl.StartsWith('--work-tree=') -or $tl.StartsWith('--namespace=') -or $tl.StartsWith('--exec-path=') -or $tl.StartsWith('--config-env')) { $i++; continue }
    if (@('--no-pager', '-p', '--paginate', '--bare', '--literal-pathspecs', '--no-replace-objects', '--no-optional-locks') -contains $tl) { $i++; continue }
    break
  }
  if ($aliasInline) { return 'git com alias inline (-c alias.*): confirme o comando real.' }
  if ($i -ge $Tokens.Count) { return $null }
  $sub = $Tokens[$i].ToLowerInvariant()
  $resto = @()
  if ($i + 1 -lt $Tokens.Count) { $resto = @($Tokens[($i + 1)..($Tokens.Count - 1)]) }
  $naoOpcoes = @($resto | Where-Object { -not $_.StartsWith('-') })
  switch ($sub) {
    'push' {
      $forca = (Test-SddFlag $resto @('--force', '--force-with-lease', '--force-if-includes', '--mirror', '--delete', '--prune') 'fd') -or (@($naoOpcoes | Where-Object { $_.StartsWith('+') -or $_.StartsWith(':') }).Count -gt 0)
      if ($forca) { return 'git push com force/delete/mirror: reescreve o remoto. Confirme.' }
      return 'git push: publicacao e do usuario. Confirme.'
    }
    'commit' {
      if (Test-SddFlag $resto @('--no-verify') 'n') { return 'git commit --no-verify pula o commit-gate. Confirme.' }
      return 'git commit: commit e do usuario. Confirme.'
    }
    'reset' { if (Test-SddFlag $resto @('--hard', '--merge', '--keep') '') { return 'git reset --hard/--merge/--keep descarta trabalho. Confirme.' } }
    'clean' { if (Test-SddFlag $resto @('--force') 'f') { return 'git clean -f apaga arquivos nao rastreados. Confirme.' } }
    'restore' { return 'git restore descarta alteracao do working tree/index. Confirme (prefira copia temporaria).' }
    'checkout' {
      if ($resto -contains '--' -or $resto -contains '.' -or (Test-SddFlag $resto @('--force', '--patch', '--ours', '--theirs') 'fp') -or $naoOpcoes.Count -ge 2) {
        return 'git checkout de arquivo descarta alteracao nao commitada. Confirme.'
      }
    }
    'switch' { if (Test-SddFlag $resto @('--force', '--discard-changes') 'f') { return 'git switch -f descarta alteracoes. Confirme.' } }
    'rebase' { return 'git rebase reescreve historico. Confirme.' }
    'branch' { if (($resto -ccontains '-D') -or (Test-SddFlag $resto @('--force') '') -or ((Test-SddFlag $resto @('--delete') 'd') -and (Test-SddFlag $resto @('--force') 'f'))) { return 'git branch -D apaga branch sem merge. Confirme.' } }
    'stash' { if ($naoOpcoes.Count -gt 0 -and @('drop', 'clear') -contains $naoOpcoes[0].ToLowerInvariant()) { return 'git stash drop/clear apaga trabalho guardado. Confirme.' } }
    'reflog' { if ($naoOpcoes.Count -gt 0 -and @('expire', 'delete') -contains $naoOpcoes[0].ToLowerInvariant()) { return 'git reflog expire/delete remove a rede de seguranca. Confirme.' } }
    'gc' { if (Test-SddFlag $resto @('--prune') '') { return 'git gc --prune remove objetos sem volta. Confirme.' } }
    'filter-branch' { return 'reescrita de historico: so em clone dedicado. Confirme.' }
    'filter-repo' { return 'reescrita de historico: so em clone dedicado. Confirme.' }
    'lfs' { if ($naoOpcoes.Count -gt 0 -and $naoOpcoes[0].ToLowerInvariant() -eq 'migrate') { return 'git lfs migrate reescreve historico. Confirme.' } }
    'worktree' { if ($naoOpcoes.Count -gt 0 -and (($naoOpcoes[0] -eq 'remove' -and (Test-SddFlag $resto @('--force') 'f')) -or $naoOpcoes[0] -eq 'prune')) { return 'git worktree remove --force/prune pode apagar trabalho. Confirme.' } }
    'update-ref' { return 'git update-ref altera refs direto. Confirme.' }
    'commit-tree' { return 'git commit-tree cria commit sem hooks. Confirme.' }
    'replace' { return 'git replace altera o historico visivel. Confirme.' }
    'config' { if (@($resto | Where-Object { $_.ToLowerInvariant().StartsWith('core.hookspath') -or $_.ToLowerInvariant().StartsWith('alias.') }).Count -gt 0) { return 'git config de hooksPath/alias: confirme.' } }
    'tag' { if (Test-SddFlag $resto @('--delete', '--force') 'df') { return 'git tag -d/-f altera tags publicadas. Confirme.' } }
    'rm' { if (-not (Test-SddFlag $resto @('--cached') '') -and (Test-SddFlag $resto @('--force') 'rf')) { return 'git rm -r/-f apaga arquivos. Confirme.' } }
  }
  return $null
}

function Test-SddEhGit([string]$Nome) {
  if (-not $Nome) { return $false }
  $n = $Nome.Trim('"', "'").Replace('\', '/')
  $base = ($n -split '/')[-1].ToLowerInvariant()
  return ($base -eq 'git' -or $base -eq 'git.exe')
}

# Analise por tokens de cada segmento (bash, cmd e PowerShell simples).
function Get-SddMotivoTexto([string]$Texto) {
  foreach ($seg in (Split-SddSegmentos $Texto)) {
    $tk = @(Split-SddTokens $seg)
    if ($tk.Count -eq 0) { continue }
    # pula prefixos: '&', 'sudo', 'env', atribuicoes VAR=x, 'command', 'exec'
    $i = 0
    while ($i -lt $tk.Count -and (@('&', '.', 'sudo', 'env', 'command', 'exec', 'nohup', 'time') -contains $tk[$i].ToLowerInvariant() -or $tk[$i] -match '^[A-Za-z_][A-Za-z0-9_]*=')) { $i++ }
    if ($i -ge $tk.Count) { continue }
    $cmd = $tk[$i]
    $args2 = @()
    if ($i + 1 -lt $tk.Count) { $args2 = @($tk[($i + 1)..($tk.Count - 1)]) }
    $cl = $cmd.Trim('"', "'").ToLowerInvariant()
    # Executavel do git nos primeiros tokens (cobre caminho com espaco sem aspas).
    $gitIdx = -1
    for ($k = $i; $k -lt [Math]::Min($tk.Count, $i + 4); $k++) { if (Test-SddEhGit $tk[$k]) { $gitIdx = $k; break } }
    if ($gitIdx -ge 0) {
      $argsGit = @()
      if ($gitIdx + 1 -lt $tk.Count) { $argsGit = @($tk[($gitIdx + 1)..($tk.Count - 1)]) }
      $m = Get-SddMotivoGit $argsGit
      if ($m) { return $m }
    }
    if ($cl -eq 'rm' -and (Test-SddFlag $args2 @('--recursive') 'rR')) { return 'rm recursivo apaga arvore de arquivos. Confirme.' }
    if (@('rmdir', 'rd') -contains $cl -and @($args2 | Where-Object { $_ -ieq '/s' }).Count -gt 0) { return 'rmdir /s apaga arvore de arquivos. Confirme.' }
    if (@('del', 'erase') -contains $cl -and @($args2 | Where-Object { $_ -ieq '/s' }).Count -gt 0) { return 'del /s apaga arquivos em lote. Confirme.' }
    if (@('iex', 'invoke-expression') -contains $cl) { return 'Invoke-Expression esconde o comando real do guard. Confirme.' }
    if (@('powershell', 'powershell.exe', 'pwsh', 'pwsh.exe') -contains $cl -and @($args2 | Where-Object { $_ -match '^-(e|ec|enc|encodedcommand)$' }).Count -gt 0) { return 'comando codificado (-EncodedCommand) esconde o comando real. Confirme.' }
    if ($cl -eq 'start-process' -and (@($args2 | Where-Object { Test-SddEhGit $_ }).Count -gt 0)) { return 'git via Start-Process: confirme o comando real.' }
    if ($cl -eq 'docker' -and $args2.Count -ge 2 -and @('system', 'volume', 'image', 'builder', 'container') -contains $args2[0].ToLowerInvariant() -and $args2[1].ToLowerInvariant() -eq 'prune') { return 'docker prune apaga recursos. Confirme.' }
  }
  return $null
}

# Remove-Item -Recurse e invocacoes nao estaticas via AST do PowerShell.
function Get-SddMotivoAst([string]$Texto) {
  $tokens = $null; $erros = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($Texto, [ref]$tokens, [ref]$erros)
  if ($null -eq $ast) { return $null }
  foreach ($c in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)) {
    $nome = $c.GetCommandName()
    if (-not $nome) {
      # & $var ... : comando dinamico
      if ($c.InvocationOperator -ne [System.Management.Automation.Language.TokenKind]::Unknown -and $c.CommandElements.Count -gt 0 -and $c.CommandElements[0] -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) { return 'comando dinamico (& $variavel): o guard nao ve o executavel. Confirme.' }
      continue
    }
    $n = $nome.ToLowerInvariant()
    if (@('remove-item', 'rm', 'rmdir', 'rd', 'del', 'erase', 'ri') -contains $n) {
      foreach ($el in $c.CommandElements) {
        if ($el -is [System.Management.Automation.Language.CommandParameterAst] -and 'recurse'.StartsWith($el.ParameterName.ToLowerInvariant())) { return 'Remove-Item -Recurse apaga arvore de arquivos. Confirme.' }
      }
    }
    if (Test-SddEhGit $nome) {
      $vals = New-Object System.Collections.ArrayList
      $dinamico = $false
      for ($k = 1; $k -lt $c.CommandElements.Count; $k++) {
        $el = $c.CommandElements[$k]
        if ($el -is [System.Management.Automation.Language.StringConstantExpressionAst]) { [void]$vals.Add($el.Value) }
        elseif ($el -is [System.Management.Automation.Language.CommandParameterAst]) { [void]$vals.Add($el.Extent.Text) }
        elseif ($el -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) { [void]$vals.Add($el.Value) }
        else { $dinamico = $true }
      }
      if ($dinamico) { return 'git com argumentos dinamicos (splatting/variavel): confirme o comando real.' }
      $m = Get-SddMotivoGit @($vals)
      if ($m) { return $m }
    }
  }
  return $null
}

function Get-SddMotivoRegex([string]$Texto) {
  $regras = @(
    @{ P = '\bDROP\s+(DATABASE|SCHEMA|TABLE)\b'; M = 'DROP de banco/esquema/tabela. Confirme.' },
    @{ P = '\bTRUNCATE(\s+TABLE)?\b'; M = 'TRUNCATE apaga dados. Confirme.' },
    @{ P = '\bDELETE\s+FROM\s+[\w."\[\]]+\s*(;|$|\)|")'; M = 'DELETE sem WHERE. Confirme.' },
    @{ P = '\b(db\s+reset|migrate\s+reset|db:drop|dropdb)\b'; M = 'reset/drop de banco. Confirme.' },
    @{ P = '--dangerously-skip-permissions|bypassPermissions|disableAllHooks'; M = 'tentativa de desligar permissoes ou hooks. Confirme.' },
    @{ P = '\bsdd(\.ps1)?["'']?\s+approve\b'; M = 'aprovar portao e do usuario, no terminal dele (sdd approve recusa a IA).' },
    @{ P = '\bverify-record\b'; M = 'gravar o veredito do verificador: confirme que quem verificou nao foi quem implementou.' },
    @{ P = '(evidence\.jsonl|verify\.md|\.sdd[\\/]state)'; M = $null }
  )
  foreach ($r in $regras) {
    if ($Texto -match ('(?i)' + $r.P)) {
      if ($r.M) { return $r.M }
      if ($Texto -match '(?i)(>>?|\bSet-Content\b|\bAdd-Content\b|\bOut-File\b|\btee\b|\bCopy-Item\b|\bMove-Item\b|\bRemove-Item\b|\bcp\s|\bmv\s|\brm\s|\bdel\s|\bNew-Item\b|WriteAll)') { return 'escrita direta em ledger/relatorio do motor (so o sdd grava). Confirme.' }
    }
  }
  return $null
}

function Get-SddMotivo([string]$Texto) {
  $m = Get-SddMotivoRegex $Texto
  if (-not $m) { $m = Get-SddMotivoAst $Texto }
  if (-not $m) { $m = Get-SddMotivoTexto $Texto }
  return $m
}

try {
  if ($PSBoundParameters.ContainsKey('Comando')) { $texto = $Comando }
  else {
    $raw = Read-SddStdin
    if ([string]::IsNullOrWhiteSpace($raw)) { Write-SddResposta 'ask' 'Guard sem payload: revise o comando manualmente.'; exit 0 }
    $in = $raw | ConvertFrom-Json
    if ($Platform -eq 'Claude') { $texto = [string]$in.tool_input.command } else { $texto = [string]$in.toolCall.args.CommandLine }
  }
  if ([string]::IsNullOrWhiteSpace($texto)) { Write-SddResposta 'ask' 'Guard nao achou o comando no payload: revise manualmente.'; exit 0 }
  $motivo = Get-SddMotivo $texto
  if ($motivo) { Write-SddResposta 'ask' ("[sdd-kit] " + $motivo) } else { Write-SddResposta 'allow' '' }
  exit 0
} catch {
  $tipo = $_.Exception.GetType().Name
  $det = ([string]$_.Exception.Message -split "`r?`n")[0]
  if ($det.Length -gt 160) { $det = $det.Substring(0, 160) }
  Write-SddResposta 'ask' ("[sdd-kit] guard falhou ($tipo`: $det): revise o comando manualmente.")
  exit 0
}
