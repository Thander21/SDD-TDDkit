# =====================================================================
# sdd-kit | tools/sdd/edit_guard.ps1 (hook PreToolUse de EDICAO no projeto)
# Claude Code (Write|Edit|NotebookEdit) e Antigravity (write_to_file |
# replace_file_content | multi_replace_file_content).
# - NEGA a IA gravar status Approved/In-Implementation, base_ref ou linha de
#   aprovacao '(sdd approve' num change.md: portao e do usuario (sdd approve).
# - NEGA editar evidence.jsonl e verify.md: so o motor grava.
# - PERGUNTA ao gravar status Done (archive pedido pelo usuario), ao editar
#   .sdd/profile.json (gates do projeto), .agents/hooks.json, settings do Claude
#   e arquivo gerenciado pelo kit.
# Edicao via shell nao passa por aqui (o guard de comando cobre parte disso).
# Compativel com Windows PowerShell 5.1 e PowerShell 7. Fonte em ASCII.
# =====================================================================
[CmdletBinding()]
param([Parameter(Mandatory = $true)][ValidateSet('Antigravity', 'Claude')][string] $Platform)
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

function Get-SddStatusFm([string]$Texto) {
  if ($null -eq $Texto) { return '' }
  $m = [regex]::Match(($Texto -replace "`r`n", "`n"), '^---\n(.*?)\n---', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { return '' }
  $s = [regex]::Match($m.Groups[1].Value, '(?m)^status:\s*["'']?([A-Za-z-]+)')
  if ($s.Success) { return $s.Groups[1].Value }
  return ''
}

function Get-SddContextoProjeto([string]$Arquivo) {
  $d = Split-Path -Parent $Arquivo
  for ($i = 0; $i -lt 25 -and $d; $i++) {
    $perfil = Join-Path $d '.sdd/profile.json'
    if (Test-Path -LiteralPath $perfil) {
      $specs = 'Docs/Specs'
      try { $j = [System.IO.File]::ReadAllText($perfil) | ConvertFrom-Json; if ($j.projeto.specs_root) { $specs = [string]$j.projeto.specs_root } } catch { }
      return [pscustomobject]@{ Raiz = $d.Replace('\', '/').TrimEnd('/'); Specs = $specs.Trim('/') }
    }
    $pai = Split-Path -Parent $d
    if ($pai -eq $d) { break }
    $d = $pai
  }
  return $null
}

function Get-SddCampoFm([string]$Texto, [string]$Campo) {
  if ($null -eq $Texto) { return '' }
  $m = [regex]::Match(($Texto -replace "`r`n", "`n"), '^---\n(.*?)\n---', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { return '' }
  $s = [regex]::Match($m.Groups[1].Value, ('(?m)^' + [regex]::Escape($Campo) + ':\s*(.*)$'))
  if ($s.Success) { return ($s.Groups[1].Value -replace '\s+#.*$', '').Trim().Trim('"', "'") }
  return ''
}

function Get-SddContagem([string]$Texto, [string]$Padrao) {
  if ($null -eq $Texto) { return 0 }
  return ([regex]::Matches($Texto, $Padrao)).Count
}

try {
  $r = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), (New-Object System.Text.UTF8Encoding $false), $true)
  try { $raw = $r.ReadToEnd() } finally { $r.Dispose() }
  if ([string]::IsNullOrWhiteSpace($raw)) { Write-SddResposta 'ask' '[sdd-kit] edit_guard sem payload: revise a edicao.'; exit 0 }
  $in = $raw | ConvertFrom-Json
  $multi = $false
  if ($Platform -eq 'Claude') {
    $ferr = [string]$in.tool_name
    $a = $in.tool_input
    $arq = [string]$a.file_path
    if (-not $arq) { $arq = [string]$a.notebook_path }
    $inteiro = $a.content
    $velho = [string]$a.old_string
    $novo = [string]$a.new_string
    $todas = ($a.replace_all -eq $true)
  } else {
    $ferr = [string]$in.toolCall.name
    $a = $in.toolCall.args
    $arq = [string]$a.TargetFile
    $inteiro = $a.CodeContent
    $velho = [string]$a.TargetContent
    $novo = [string]$a.ReplacementContent
    $todas = ($a.AllowMultiple -eq $true)
    if ($ferr -eq 'multi_replace_file_content') { $multi = $true }
  }
  if (-not $arq) { Write-SddResposta 'allow' ''; exit 0 }
  $p = $arq.Replace('\', '/')
  $pl = $p.ToLowerInvariant()
  $ctx = Get-SddContextoProjeto $arq
  $reSpecs = '/specs/'
  if ($ctx) { $reSpecs = '^' + [regex]::Escape(($ctx.Raiz + '/' + $ctx.Specs + '/').ToLowerInvariant()) }

  if ($pl -match '/\.sdd/state/') { Write-SddResposta 'deny' '[sdd-kit] .sdd/state/ e estado do motor (validacoes, goal, sondas): so o sdd grava.'; exit 0 }
  if ($pl -match ($reSpecs + '.*(evidence\.jsonl|verify\.md)$') -or $pl -match '/specs/.+/(evidence\.jsonl|verify\.md)$') { Write-SddResposta 'deny' '[sdd-kit] evidence.jsonl e verify.md so sao gravados pelo motor (sdd test / sdd verify-record).'; exit 0 }
  if ($pl.EndsWith('/.sdd/profile.json')) { Write-SddResposta 'ask' '[sdd-kit] .sdd/profile.json define os gates: confirme que a edicao nao afrouxa nenhum.'; exit 0 }
  if ($pl.EndsWith('/.agents/hooks.json') -or $pl -match '/\.claude/settings(\.local)?\.json$') { Write-SddResposta 'ask' '[sdd-kit] configuracao de guard do projeto: a IA nao pode editar settings/hooks de guard sem confirmacao. Confirme.'; exit 0 }
  if ($pl -match '/tools/sdd/|/\.agents/rules/sdd-[^/]+\.md$|/\.sdd/kit\.lock\.json$') { Write-SddResposta 'ask' '[sdd-kit] arquivo gerenciado pelo kit: mudanca de metodo vai para o repositorio do kit. Confirme.'; exit 0 }
  if ($pl -notmatch ($reSpecs + '.*change\.md$') -and $pl -notmatch '/specs/.+/change\.md$') { Write-SddResposta 'allow' ''; exit 0 }

  $antes = $null
  if (Test-Path -LiteralPath $arq) { $antes = [System.IO.File]::ReadAllText($arq) }
  if ($multi) { Write-SddResposta 'ask' '[sdd-kit] edicao multipla num change.md: confira se nao muda status nem aprovacoes.'; exit 0 }
  if ($null -ne $inteiro) { $depois = [string]$inteiro }
  elseif ($null -ne $antes -and $velho) {
    if ($todas) { $depois = $antes.Replace($velho, $novo) }
    else {
      $idx = $antes.IndexOf($velho)
      if ($idx -lt 0) { $depois = $antes } else { $depois = $antes.Substring(0, $idx) + $novo + $antes.Substring($idx + $velho.Length) }
    }
  } else { $depois = $novo }

  $stAntes = Get-SddStatusFm $antes
  $stDepois = Get-SddStatusFm $depois
  if ($stDepois -ne $stAntes -and @('Approved', 'In-Implementation') -contains $stDepois) {
    Write-SddResposta 'deny' ("[sdd-kit] status $stDepois e portao humano: peca ao usuario para rodar 'sdd approve <NN> P1|P2' no terminal dele ou fornecer a frase de aprovacao no chat.")
    exit 0
  }
  if ((Get-SddCampoFm $depois 'base_ref') -ne (Get-SddCampoFm $antes 'base_ref') -and (Get-SddCampoFm $depois 'base_ref')) {
    Write-SddResposta 'deny' '[sdd-kit] base_ref e gravado pelo sdd approve P2.'
    exit 0
  }
  if ((Get-SddContagem $depois '\(sdd approve') -gt (Get-SddContagem $antes '\(sdd approve')) {
    Write-SddResposta 'deny' '[sdd-kit] linha de aprovacao so e gravada pelo sdd approve.'
    exit 0
  }
  if ($stDepois -ne $stAntes -and $stDepois -eq 'Done') { Write-SddResposta 'ask' '[sdd-kit] status Done: so no archive pedido pelo usuario, depois do GOAL PASS. Confirme.'; exit 0 }
  Write-SddResposta 'allow' ''
  exit 0
} catch {
  $tipo = $_.Exception.GetType().Name
  Write-SddResposta 'ask' ("[sdd-kit] edit_guard falhou ($tipo): revise a edicao manualmente.")
  exit 0
}
