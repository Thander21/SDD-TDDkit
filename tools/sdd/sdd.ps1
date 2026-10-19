# =====================================================================
# sdd-kit | tools/sdd/sdd.ps1
# Motor de gates, evidencia, portoes e condicao de parada do fluxo SDD.
# Arquivo GERENCIADO PELO KIT: nao edite dentro do projeto. Mudanca de
# metodo vai para o INBOX.md do repositorio do kit e volta pelo update.
# Compativel com Windows PowerShell 5.1 e PowerShell 7. Fonte em ASCII
# (o 5.1 sem BOM quebra com caractere nao ASCII em string).
# Ajuda: powershell -File tools/sdd/sdd.ps1 ajuda
# =====================================================================

$ErrorActionPreference = 'Stop'
$script:SddVersao = '0.1.0'
$script:Utf8 = New-Object System.Text.UTF8Encoding $false

# ---------------------------------------------------------------------
# Utilitarios gerais
# ---------------------------------------------------------------------

function Write-SddLinha([string]$Texto) { [Console]::Out.WriteLine($Texto) }

function Get-SddEpochMs { [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }

function Get-SddIsoAgora { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }

function Read-SddTexto([string]$Caminho) {
  if (-not (Test-Path -LiteralPath $Caminho -PathType Leaf)) { return $null }
  return [System.IO.File]::ReadAllText($Caminho, [System.Text.Encoding]::UTF8)
}

function Write-SddTextoAtomico([string]$Caminho, [string]$Texto) {
  $dir = Split-Path -Parent $Caminho
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $tmp = "$Caminho.tmp$PID"
  [System.IO.File]::WriteAllText($tmp, $Texto, $script:Utf8)
  Move-Item -LiteralPath $tmp -Destination $Caminho -Force
}

# Acrescenta uma linha com trava exclusiva e nova tentativa: duas sessoes
# paralelas gravando o mesmo ledger nao perdem linhas.
function Add-SddLinhaComTrava([string]$Caminho, [string]$Linha) {
  $dir = Split-Path -Parent $Caminho
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $bytes = $script:Utf8.GetBytes($Linha + "`n")
  for ($i = 0; $i -lt 50; $i++) {
    try {
      $fs = New-Object System.IO.FileStream($Caminho, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
      try { $fs.Write($bytes, 0, $bytes.Length) } finally { $fs.Dispose() }
      return
    } catch [System.IO.IOException] { Start-Sleep -Milliseconds 100 }
  }
  throw "nao foi possivel gravar em $Caminho (arquivo travado)"
}

function Get-SddProp($Obj, [string]$Caminho, $Padrao = $null) {
  $atual = $Obj
  foreach ($parte in $Caminho.Split('.')) {
    if ($null -eq $atual) { return $Padrao }
    if ($atual -is [System.Collections.IDictionary]) {
      if (-not $atual.Contains($parte)) { return $Padrao }
      $atual = $atual[$parte]
    } else {
      $p = $atual.PSObject.Properties[$parte]
      if ($null -eq $p) { return $Padrao }
      $atual = $p.Value
    }
  }
  if ($null -eq $atual) { return $Padrao }
  return $atual
}

# Chave de comparacao de titulos: minusculas, sem acento, sem espacos extras.
function ConvertTo-SddChave([string]$Texto) {
  if ($null -eq $Texto) { return '' }
  $d = $Texto.Normalize([System.Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $d.ToCharArray()) {
    if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($ch) }
  }
  return (($sb.ToString().ToLowerInvariant()) -replace '[^a-z0-9]+', ' ').Trim()
}

function Get-SddSha256Texto([string]$Texto) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { $b = $sha.ComputeHash($script:Utf8.GetBytes(($Texto -replace "`r`n", "`n"))) } finally { $sha.Dispose() }
  return (-join ($b | ForEach-Object { $_.ToString('x2') }))
}

# ---------------------------------------------------------------------
# Raiz, git e perfil
# ---------------------------------------------------------------------

function Invoke-SddGit {
  param([string[]]$GitArgs, [switch]$PermitirFalha)
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    # quotepath=false: caminho com acento sai literal, sem aspas e escapes octais.
    $saida = & git -c core.quotepath=false -C $script:Raiz @GitArgs 2>&1
    $codigo = $LASTEXITCODE
  } finally { $ErrorActionPreference = $old }
  $out = @($saida | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
  $err = @($saida | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
  if ($codigo -ne 0 -and -not $PermitirFalha) {
    throw ("git " + ($GitArgs -join ' ') + " falhou (exit $codigo): " + ($err -join ' | '))
  }
  return [pscustomobject]@{ Codigo = $codigo; Out = $out; Err = $err }
}

function Initialize-SddRaiz {
  $base = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  $script:Raiz = $base
  $r = Invoke-SddGit -GitArgs @('rev-parse', '--show-toplevel') -PermitirFalha
  if ($r.Codigo -ne 0) { throw "a pasta $base nao esta num repositorio git (o kit exige git)" }
  $script:Raiz = [System.IO.Path]::GetFullPath(($r.Out | Select-Object -Last 1))
  $script:Estado = Join-Path $script:Raiz '.sdd/state'
}

function Get-SddPerfil {
  if ($script:Perfil) { return $script:Perfil }
  $arq = Join-Path $script:Raiz '.sdd/profile.json'
  $txt = Read-SddTexto $arq
  if ($null -eq $txt) { throw '.sdd/profile.json ausente: rode o install.ps1 do kit neste projeto' }
  try { $p = $txt | ConvertFrom-Json } catch { throw ".sdd/profile.json invalido: $($_.Exception.Message)" }
  $local = Read-SddTexto (Join-Path $script:Raiz '.sdd/profile.local.json')
  $vars = @{}
  $pv = Get-SddProp $p 'vars'
  if ($pv) { foreach ($pp in $pv.PSObject.Properties) { $vars[$pp.Name] = [string]$pp.Value } }
  if ($local) {
    try { $l = $local | ConvertFrom-Json } catch { throw ".sdd/profile.local.json invalido: $($_.Exception.Message)" }
    $lv = Get-SddProp $l 'vars'
    if ($lv) { foreach ($pp in $lv.PSObject.Properties) { $vars[$pp.Name] = [string]$pp.Value } }
  }
  $script:Vars = $vars
  $script:Perfil = $p
  return $p
}

function Get-SddSpecsRoot {
  $p = Get-SddPerfil
  return ([string](Get-SddProp $p 'projeto.specs_root' 'Docs/Specs')).TrimEnd('/')
}

function Expand-SddArg([string]$Arg, [hashtable]$Extra) {
  $res = $Arg.Replace('{raiz}', $script:Raiz)
  if ($Extra) { foreach ($k in $Extra.Keys) { $res = $res.Replace('{' + $k + '}', [string]$Extra[$k]) } }
  foreach ($k in $script:Vars.Keys) { $res = $res.Replace('{' + $k + '}', $script:Vars[$k]) }
  $m = [regex]::Match($res, '\{([A-Za-z_][A-Za-z0-9_]*)\}')
  if ($m.Success) { throw "variavel {$($m.Groups[1].Value)} sem valor: defina em .sdd/profile.local.json (vars)" }
  return $res
}

# Comando do perfil = lista [executavel, arg1, arg2...]. Nunca Invoke-Expression.
function Invoke-SddComando {
  param([object[]]$Cmd, [string]$Log, [hashtable]$Extra)
  if (-not $Cmd -or $Cmd.Count -eq 0) { throw 'comando vazio no perfil' }
  $partes = @($Cmd | ForEach-Object { Expand-SddArg ([string]$_) $Extra })
  $exe = $partes[0]
  $argv = @()
  if ($partes.Count -gt 1) { $argv = @($partes[1..($partes.Count - 1)]) }
  $envSalvo = @{}
  $envPerfil = Get-SddProp (Get-SddPerfil) 'env'
  if ($envPerfil) {
    foreach ($pp in $envPerfil.PSObject.Properties) {
      $envSalvo[$pp.Name] = [Environment]::GetEnvironmentVariable($pp.Name, 'Process')
      [Environment]::SetEnvironmentVariable($pp.Name, [string]$pp.Value, 'Process')
    }
  }
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  Push-Location -LiteralPath $script:Raiz
  try {
    $global:LASTEXITCODE = 0
    $saida = & $exe @argv 2>&1
    $codigo = $LASTEXITCODE
    if ($null -eq $codigo) { $codigo = 0 }
  } catch {
    $saida = @("nao foi possivel executar '$exe': $($_.Exception.Message)")
    $codigo = 9009
  } finally {
    Pop-Location
    $ErrorActionPreference = $old
    foreach ($k in $envSalvo.Keys) { [Environment]::SetEnvironmentVariable($k, $envSalvo[$k], 'Process') }
  }
  $sw.Stop()
  $linhas = @($saida | ForEach-Object { "$_" })
  if ($Log) {
    $dir = Split-Path -Parent $Log
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllLines($Log, [string[]]$linhas, $script:Utf8)
  }
  return [pscustomobject]@{ Exit = [int]$codigo; Ms = $sw.ElapsedMilliseconds; Linhas = $linhas }
}

# ---------------------------------------------------------------------
# Arvore (frescor por conteudo, nao por mtime)
# ---------------------------------------------------------------------

function Get-SddIsentos {
  $lista = New-Object System.Collections.ArrayList
  # icase: no Windows 'docs/specs' e 'Docs/Specs' sao a mesma pasta.
  [void]$lista.Add(':(glob,icase)' + (Get-SddSpecsRoot) + '/**')
  [void]$lista.Add(':(glob).sdd/state/**')
  foreach ($g in @(Get-SddProp (Get-SddPerfil) 'paths.isentos_frescor' @())) { [void]$lista.Add(':(glob,icase)' + [string]$g) }
  return @($lista)
}

# Hash da arvore do projeto, sem a pasta de specs e sem o estado do kit.
# -DoIndice: usa o indice (o que vai ser commitado) em vez do working tree.
function Get-SddArvore {
  param([switch]$DoIndice)
  $gitDir = (Invoke-SddGit -GitArgs @('rev-parse', '--absolute-git-dir')).Out | Select-Object -Last 1
  $origem = $env:GIT_INDEX_FILE
  if (-not $origem) { $origem = (Invoke-SddGit -GitArgs @('rev-parse', '--git-path', 'index')).Out | Select-Object -Last 1 }
  if (-not [System.IO.Path]::IsPathRooted($origem)) { $origem = Join-Path $script:Raiz $origem }
  $tmp = Join-Path $gitDir ("sdd-index-$PID.tmp")
  if (Test-Path -LiteralPath $origem) { Copy-Item -LiteralPath $origem -Destination $tmp -Force }
  $anterior = $env:GIT_INDEX_FILE
  $env:GIT_INDEX_FILE = $tmp
  try {
    if (-not $DoIndice) { Invoke-SddGit -GitArgs @('add', '-A', '--', '.') | Out-Null }
    Invoke-SddGit -GitArgs (@('rm', '-r', '--cached', '-q', '--ignore-unmatch', '--') + (Get-SddIsentos)) | Out-Null
    $arvore = (Invoke-SddGit -GitArgs @('write-tree')).Out | Select-Object -Last 1
  } finally {
    if ($null -eq $anterior) { Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue } else { $env:GIT_INDEX_FILE = $anterior }
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
  if ($arvore -notmatch '^[0-9a-f]{40,64}$') { throw "write-tree devolveu valor inesperado: $arvore" }
  return $arvore
}

function Get-SddHead {
  $r = Invoke-SddGit -GitArgs @('rev-parse', 'HEAD') -PermitirFalha
  if ($r.Codigo -ne 0) { return '' }
  return ($r.Out | Select-Object -Last 1)
}

# ---------------------------------------------------------------------
# Frontmatter estrito (subconjunto de YAML), falha FECHADA
# Aceita: chave: valor | chave: [a, b] | lista em bloco "  - item" |
# mapa de 1 nivel (indentacao 2). Qualquer outra forma = erro com linha.
# ---------------------------------------------------------------------

function ConvertFrom-SddFrontmatter([string]$Texto) {
  $linhas = ($Texto -replace "`r`n", "`n") -split "`n"
  if ($linhas.Count -lt 2 -or $linhas[0].Trim() -ne '---') { throw 'frontmatter ausente: a primeira linha deve ser ---' }
  $fim = -1
  for ($i = 1; $i -lt $linhas.Count; $i++) { if ($linhas[$i].Trim() -eq '---') { $fim = $i; break } }
  if ($fim -lt 0) { throw 'frontmatter sem --- de fechamento' }
  $raiz = [ordered]@{}
  $mapa = $null
  $lista = $null
  for ($i = 1; $i -lt $fim; $i++) {
    $n = $i + 1
    $bruta = $linhas[$i]
    if ($bruta.Trim() -eq '' -or $bruta.TrimStart().StartsWith('#')) { continue }
    if ($bruta.Contains("`t")) { throw "frontmatter linha ${n}: TAB nao permitido" }
    $ind = $bruta.Length - $bruta.TrimStart(' ').Length
    $corpo = $bruta.Trim()
    if ($corpo.StartsWith('- ') -or $corpo -eq '-') {
      if ($null -eq $lista) { throw "frontmatter linha ${n}: item de lista sem chave de lista acima" }
      [void]$lista.Add((Get-SddEscalar ($corpo.Substring(1).Trim()) $n))
      continue
    }
    $m = [regex]::Match($corpo, '^([A-Za-z_][A-Za-z0-9_-]*):(?:\s+(.*))?$')
    if (-not $m.Success) { throw "frontmatter linha ${n}: forma nao suportada: '$corpo'" }
    $chave = $m.Groups[1].Value
    $valor = Remove-SddComentario ([string]$m.Groups[2].Value)
    if ($ind -eq 0) { $alvo = $raiz; $mapa = $null }
    elseif ($ind -eq 2 -and $null -ne $mapa) { $alvo = $mapa }
    else { throw "frontmatter linha ${n}: indentacao $ind nao suportada (use 0, ou 2 dentro de um mapa)" }
    if ($alvo.Contains($chave)) { throw "frontmatter linha ${n}: chave duplicada '$chave'" }
    $lista = $null
    if ($valor -eq '') {
      $prox = $null
      for ($j = $i + 1; $j -lt $fim; $j++) {
        if ($linhas[$j].Trim() -ne '' -and -not $linhas[$j].TrimStart().StartsWith('#')) { $prox = $linhas[$j]; break }
      }
      $proxCorpo = ''
      $proxInd = 0
      if ($prox) { $proxCorpo = $prox.Trim(); $proxInd = $prox.Length - $prox.TrimStart(' ').Length }
      if ($prox -and $proxCorpo.StartsWith('-') -and $proxInd -gt $ind) {
        $lista = New-Object System.Collections.ArrayList
        $alvo[$chave] = $lista
      } elseif ($prox -and $proxInd -gt $ind -and $ind -eq 0) {
        $mapa = [ordered]@{}
        $alvo[$chave] = $mapa
      } else { $alvo[$chave] = $null }
      continue
    }
    if ($valor.StartsWith('[')) {
      if (-not $valor.EndsWith(']')) { throw "frontmatter linha ${n}: lista em linha sem ]" }
      $dentro = $valor.Substring(1, $valor.Length - 2).Trim()
      $l = New-Object System.Collections.ArrayList
      if ($dentro -ne '') { foreach ($parte in $dentro.Split(',')) { [void]$l.Add((Get-SddEscalar $parte.Trim() $n)) } }
      $alvo[$chave] = $l
      continue
    }
    $alvo[$chave] = Get-SddEscalar $valor $n
  }
  return $raiz
}

function Remove-SddComentario([string]$V) {
  if ($V.StartsWith('"') -or $V.StartsWith("'")) { return $V.Trim() }
  $idx = $V.IndexOf(' #')
  if ($idx -ge 0) { $V = $V.Substring(0, $idx) }
  return $V.Trim()
}

function Get-SddEscalar([string]$V, [int]$N) {
  if ($V -eq '') { throw "frontmatter linha ${N}: valor vazio em lista" }
  if (($V.StartsWith('"') -and $V.EndsWith('"') -and $V.Length -ge 2) -or ($V.StartsWith("'") -and $V.EndsWith("'") -and $V.Length -ge 2)) { return $V.Substring(1, $V.Length - 2) }
  if ($V.StartsWith('"') -or $V.StartsWith("'")) { throw "frontmatter linha ${N}: aspas sem fechamento" }
  if ($V -match '^[\[\]{}&*!|>%@`]') { throw "frontmatter linha ${N}: sintaxe YAML avancada nao suportada: '$V'" }
  return $V
}

function Get-SddCorpo([string]$Texto) {
  $t = $Texto -replace "`r`n", "`n"
  $m = [regex]::Match($t, '^---\n.*?\n---[ \t]*(\n|$)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if ($m.Success) { return $t.Substring($m.Length) }
  return $t
}

function Remove-SddComentariosHtml([string]$Texto) {
  return [regex]::Replace($Texto, '<!--.*?-->', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
}

# Corpo de uma secao "## Titulo" (comparacao sem acento e sem caixa).
function Get-SddSecao([string]$Corpo, [string]$Titulo) {
  $alvo = ConvertTo-SddChave $Titulo
  $linhas = $Corpo -split "`n"
  $dentro = $false
  $sb = New-Object System.Text.StringBuilder
  $achou = $false
  foreach ($l in $linhas) {
    if ($l -match '^##\s+(.+?)\s*$' -and $l -notmatch '^###') {
      if ($dentro) { break }
      if ((ConvertTo-SddChave $Matches[1]) -eq $alvo) { $dentro = $true; $achou = $true; continue }
    }
    if ($dentro) { [void]$sb.AppendLine($l) }
  }
  if (-not $achou) { return $null }
  return $sb.ToString()
}

function Test-SddSecaoVazia([string]$Secao) {
  if ($null -eq $Secao) { return $true }
  $limpa = Remove-SddComentariosHtml $Secao
  foreach ($l in ($limpa -split "`n")) { if ($l.Trim() -ne '') { return $false } }
  return $true
}

# ---------------------------------------------------------------------
# Changes
# ---------------------------------------------------------------------

function Get-SddChanges {
  $root = Join-Path $script:Raiz (Get-SddSpecsRoot)
  $res = New-Object System.Collections.ArrayList
  foreach ($pasta in @('changes', 'concluidas')) {
    $dir = Join-Path $root $pasta
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    foreach ($d in @(Get-ChildItem -LiteralPath $dir -Directory)) {
      $arq = Join-Path $d.FullName 'change.md'
      if (-not (Test-Path -LiteralPath $arq)) { continue }
      $txt = Read-SddTexto $arq
      $fm = $null
      $erro = $null
      try { $fm = ConvertFrom-SddFrontmatter $txt } catch { $erro = $_.Exception.Message }
      [void]$res.Add([pscustomobject]@{
          Pasta = $pasta; Dir = $d.FullName; Nome = $d.Name; Arquivo = $arq; Texto = $txt
          Fm = $fm; Erro = $erro; Corpo = (Get-SddCorpo $txt)
          Rel = ((Get-SddSpecsRoot) + '/' + $pasta + '/' + $d.Name)
        })
    }
  }
  return @($res)
}

function Get-SddStatus($Change) { if ($null -eq $Change.Fm) { return '' } return [string](Get-SddProp $Change.Fm 'status' '') }

function Find-SddChange([string]$NN) {
  if ($NN -notmatch '^\d{1,4}$') { throw "numero de change invalido: '$NN' (use so digitos)" }
  $num = [int]$NN
  $cands = @(Get-SddChanges | Where-Object { $_.Pasta -eq 'changes' -and $_.Nome -match '^(\d+)-' -and [int]$Matches[1] -eq $num })
  if ($cands.Count -eq 0) { throw "change $NN nao encontrada em $(Get-SddSpecsRoot)/changes" }
  if ($cands.Count -gt 1) { throw "mais de uma pasta para a change $NN" }
  return $cands[0]
}

function Get-SddAtivas { return @(Get-SddChanges | Where-Object { $_.Pasta -eq 'changes' -and (Get-SddStatus $_) -eq 'In-Implementation' }) }

# Archive consumes only final, current evidence. File moves do not stage the
# archive or commit it; a later commit records the path changes.
function Invoke-SddArchive([string[]]$Argv) {
  if ($Argv.Count -ne 1) { throw 'uso: sdd archive <NN>' }
  $c = Find-SddChange ([string]$Argv[0])
  if ((Get-SddStatus $c) -ne 'In-Implementation') { throw 'archive exige change em In-Implementation' }
  $goalPath = Join-Path $script:Estado ("goal-" + $c.Nome + '.json')
  $goalTxt = Read-SddTexto $goalPath
  if (-not $goalTxt) { throw 'archive exige GOAL PASS final registrado pelo motor' }
  try { $goal = $goalTxt | ConvertFrom-Json } catch { throw 'registro de goal invalido' }
  if ($goal.resultado -ne 'GOAL PASS' -or (Get-SddProp $goal 'pre_verify' $false)) { throw 'archive exige ultimo GOAL PASS final (nao pre-verify)' }
  $arvore = Get-SddArvore
  if ($goal.arvore -ne $arvore) { throw 'GOAL PASS desatualizado: a arvore atual mudou' }
  $verifyPath = Join-Path $c.Dir 'verify.md'
  $verify = Read-SddTexto $verifyPath
  if (-not $verify -or $verify -notmatch '(?m)^Veredito:\s*APROVADO\s*$') { throw 'archive exige verify.md com Veredito: APROVADO' }
  $mv = [regex]::Match($verify, '(?m)^arvore:\s*([0-9a-f]+)\s*$')
  if (-not $mv.Success -or $mv.Groups[1].Value -ne $arvore) { throw 'verify.md ausente ou desatualizado para a arvore atual' }
  $root = Join-Path $script:Raiz (Get-SddSpecsRoot)
  $dest = Join-Path (Join-Path $root 'concluidas') $c.Nome
  if (Test-Path -LiteralPath $dest) { throw "destino ja existe: $($c.Rel.Replace('/changes/', '/concluidas/'))" }
  $source = $c.Dir
  $changeTxt = Read-SddTexto $c.Arquivo
  $novo = [regex]::Replace($changeTxt, '(?m)^status:\s*In-Implementation\s*$', 'status: Done', 1)
  if ($novo -eq $changeTxt) { throw 'nao foi possivel preparar status Done' }
  try {
    $destParent = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
    Write-SddTextoAtomico $c.Arquivo $novo
    if (Test-Path -LiteralPath $dest) { throw 'destino apareceu durante archive; nenhuma sobrescrita feita' }
    [System.IO.Directory]::Move($source, $dest)
  } catch {
    if ((Test-Path -LiteralPath $dest -PathType Container) -and -not (Test-Path -LiteralPath $source)) {
      try { [System.IO.Directory]::Move($dest, $source) } catch { throw ("archive falhou e rollback do caminho tambem falhou; confira '$dest' e '$source': " + $_.Exception.Message) }
    }
    if (Test-Path -LiteralPath $source -PathType Container) {
      try { Write-SddTextoAtomico (Join-Path $source 'change.md') $changeTxt } catch { throw ("archive falhou e rollback do status tambem falhou; confira '$source': " + $_.Exception.Message) }
    }
    throw ("archive falhou; origem restaurada: " + $_.Exception.Message)
  }
  Write-SddLinha ("ARCHIVED: " + $c.Rel.Replace('/changes/', '/concluidas/'))
  return 0
}

function Test-SddAprovacao([string]$Corpo, [string]$Portao) {
  $sec = Get-SddSecao $Corpo 'Aprovacoes'
  if ($null -eq $sec) { return $false }
  return ($sec -match ('(?m)^\s*-\s*' + $Portao + '( \(rebase\))?:.*\(sdd approve'))
}

# Tags de risco que exigem fonte_normativa e estao sem ela (vale no approve e no
# goal, independente do modo do SpecLint).
function Get-SddRiscosSemFonte($Change) {
  if ($null -eq $Change.Fm) { return @() }
  $exige = @(Get-SddProp (Get-SddPerfil) 'projeto.riscos_com_fonte' @())
  if ($exige.Count -eq 0 -or (Get-SddProp $Change.Fm 'fonte_normativa')) { return @() }
  return @(@(Get-SddProp $Change.Fm 'risk' @()) | Where-Object { $exige -contains $_ })
}

# Hash do perfil sem o campo 'calibrado' (o proprio calibrate o regrava).
function Get-SddPerfilSha {
  $txt = Read-SddTexto (Join-Path $script:Raiz '.sdd/profile.json')
  if ($null -eq $txt) { return '' }
  return (Get-SddSha256Texto ([regex]::Replace($txt, '"calibrado"\s*:\s*(true|false)', '"calibrado": false'))).Substring(0, 16)
}

# ---------------------------------------------------------------------
# Spec-lint
# ---------------------------------------------------------------------

function Invoke-SddSpecLint {
  $achados = New-Object System.Collections.ArrayList
  $p = Get-SddPerfil
  $riscosValidos = @(Get-SddProp $p 'projeto.riscos' @())
  $riscosComFonte = @(Get-SddProp $p 'projeto.riscos_com_fonte' @())
  $root = Get-SddSpecsRoot
  $indice = Read-SddTexto (Join-Path $script:Raiz "$root/capabilities/_index.md")
  foreach ($c in Get-SddChanges) {
    $onde = $c.Rel + '/change.md'
    if ($c.Erro) { [void]$achados.Add("${onde}: $($c.Erro)"); continue }
    foreach ($k in @('id', 'title', 'status')) {
      if (-not (Get-SddProp $c.Fm $k)) { [void]$achados.Add("${onde}: campo obrigatorio '$k' vazio") }
    }
    $id = [string](Get-SddProp $c.Fm 'id' '')
    if ($id -notmatch '^CHG-(\d+)$') { [void]$achados.Add("${onde}: id deve ser CHG-<numero>") }
    elseif ($c.Nome -notmatch '^(\d+)-' -or [int]$Matches[1] -ne [int]($id.Substring(4))) { [void]$achados.Add("${onde}: numero da pasta difere do id $id") }
    $st = Get-SddStatus $c
    if ($c.Pasta -eq 'changes' -and @('Draft', 'Approved', 'In-Implementation') -notcontains $st) { [void]$achados.Add("${onde}: status '$st' invalido em changes/ (Draft|Approved|In-Implementation)") }
    if ($c.Pasta -eq 'concluidas' -and $st -ne 'Done') { [void]$achados.Add("${onde}: change arquivada precisa de status Done") }
    if (@('Approved', 'In-Implementation', 'Done') -contains $st) {
      if (-not (Test-SddSecaoVazia (Get-SddSecao $c.Corpo 'Perguntas em aberto'))) { [void]$achados.Add("${onde}: status $st com 'Perguntas em aberto' nao vazia") }
      if (-not (Test-SddAprovacao $c.Corpo 'P1')) { [void]$achados.Add("${onde}: status $st sem a linha P1 gravada pelo 'sdd approve' em ## Aprovacoes") }
    }
    if (@('In-Implementation', 'Done') -contains $st) {
      if (-not (Test-SddAprovacao $c.Corpo 'P2')) { [void]$achados.Add("${onde}: status $st sem a linha P2 gravada pelo 'sdd approve'") }
      if (Test-SddSecaoVazia (Get-SddSecao $c.Corpo 'Analise pre-implementacao')) { [void]$achados.Add("${onde}: status $st sem Analise pre-implementacao") }
      $base = [string](Get-SddProp $c.Fm 'base_ref' '')
      if (-not $base) { [void]$achados.Add("${onde}: status $st sem base_ref") }
      elseif ($st -eq 'In-Implementation') {
        $ok = (Invoke-SddGit -GitArgs @('cat-file', '-e', ($base + '^{commit}')) -PermitirFalha).Codigo -eq 0
        if (-not $ok) { [void]$achados.Add("${onde}: base_ref $base nao existe") }
        elseif ((Invoke-SddGit -GitArgs @('merge-base', '--is-ancestor', $base, 'HEAD') -PermitirFalha).Codigo -ne 0) { [void]$achados.Add("${onde}: base_ref $base nao e ancestral do HEAD") }
      }
    }
    if ($st -ne 'Draft') {
      $imp = Get-SddProp $c.Fm 'impact'
      if ($null -eq $imp -or -not ($imp -is [System.Collections.IDictionary])) { [void]$achados.Add("${onde}: impact ausente (modified_files/new_files)") }
    }
    $riscos = @(Get-SddProp $c.Fm 'risk' @())
    foreach ($r in $riscos) {
      if ($riscosValidos.Count -gt 0 -and $riscosValidos -notcontains $r) { [void]$achados.Add("${onde}: risk '$r' fora da lista do projeto (.sdd/profile.json projeto.riscos)") }
      if ($riscosComFonte -contains $r -and -not (Get-SddProp $c.Fm 'fonte_normativa')) { [void]$achados.Add("${onde}: risk '$r' exige fonte_normativa") }
    }
    $ids = @([regex]::Matches($c.Corpo, 'SPEC-[A-Z]{2,8}-\d{3}') | ForEach-Object { $_.Value } | Select-Object -Unique)
    foreach ($sid in $ids) {
      if ($null -eq $indice -or $indice -notmatch [regex]::Escape($sid)) { [void]$achados.Add("${onde}: $sid nao esta reservado em $root/capabilities/_index.md") }
    }
  }
  $modo = [string](Get-SddProp $p 'projeto.spec_lint' 'warn')
  $status = 'PASS'
  if ($achados.Count -gt 0) { if ($modo -eq 'fail') { $status = 'FAIL' } else { $status = 'WARN' } }
  return [pscustomobject]@{ Status = $status; Achados = @($achados) }
}

# ---------------------------------------------------------------------
# check / validate / fix
# ---------------------------------------------------------------------

function Get-SddGates([string]$Nivel) {
  $p = Get-SddPerfil
  $lista = @(Get-SddProp $p $Nivel @())
  $res = New-Object System.Collections.ArrayList
  foreach ($g in $lista) {
    if ($g -is [string] -and $g.StartsWith('@')) {
      foreach ($h in (Get-SddGates $g.Substring(1))) { [void]$res.Add($h) }
    } else { [void]$res.Add($g) }
  }
  return @($res)
}

function Invoke-SddValidacao([string]$Nivel) {
  $nomeNivel = if ($Nivel -eq 'full') { 'validate' } else { 'check' }
  $inicioIso = Get-SddIsoAgora
  $arv0 = Get-SddArvore
  $gates = New-Object System.Collections.ArrayList
  $falhou = $false
  Write-SddLinha "sdd $nomeNivel - perfil $(Get-SddProp (Get-SddPerfil) 'perfil' '?')"
  $i = 0
  foreach ($g in (Get-SddGates $Nivel)) {
    $i++
    $nome = [string](Get-SddProp $g 'nome' "gate$i")
    $log = Join-Path $script:Estado ("logs/" + ($nome -replace '[^A-Za-z0-9_-]', '_') + '.log')
    $r = Invoke-SddComando -Cmd @(Get-SddProp $g 'cmd' @()) -Log $log
    $st = 'PASS'
    if ($r.Exit -ne 0) { $st = 'FAIL' }
    $padrao = [string](Get-SddProp $g 'falha_se' '')
    if ($st -eq 'PASS' -and $padrao -and (($r.Linhas -join "`n") -match $padrao)) { $st = 'FAIL' }
    if ($st -eq 'FAIL') { $falhou = $true }
    Write-SddLinha ("  [{0}] {1} ({2:N1}s)" -f $st, $nome, ($r.Ms / 1000.0))
    if ($st -eq 'FAIL') {
      $tail = @($r.Linhas | Select-Object -Last 25)
      foreach ($t in $tail) { Write-SddLinha ("      | " + $t) }
      Write-SddLinha "      log completo: $log"
    }
    [void]$gates.Add([ordered]@{ nome = $nome; status = $st; ms = $r.Ms; exit = $r.Exit })
  }
  $lint = Invoke-SddSpecLint
  Write-SddLinha ("  [{0}] SpecLint" -f $lint.Status)
  foreach ($a in ($lint.Achados | Select-Object -First 20)) { Write-SddLinha "      - $a" }
  if ($lint.Status -eq 'FAIL') { $falhou = $true }
  [void]$gates.Add([ordered]@{ nome = 'SpecLint'; status = $lint.Status; ms = 0; exit = 0 })
  $arv1 = Get-SddArvore
  $status = 'PASS'
  if ($falhou) { $status = 'FAIL' }
  elseif ($arv0 -ne $arv1) { $status = 'INSTAVEL' }
  $reg = [ordered]@{
    nivel = $Nivel; status = $status; inicio = $inicioIso; fim = (Get-SddIsoAgora); t = (Get-SddEpochMs)
    arvore = $arv1; head = (Get-SddHead); perfil_sha = (Get-SddSha256Texto (Read-SddTexto (Join-Path $script:Raiz '.sdd/profile.json'))); gates = @($gates)
  }
  Write-SddTextoAtomico (Join-Path $script:Estado "last-$Nivel.json") ($reg | ConvertTo-Json -Depth 6)
  if ($status -eq 'INSTAVEL') { Write-SddLinha '  A arvore mudou durante a validacao (gate gravou arquivo ou houve edicao): resultado descartado.' }
  Write-SddLinha ("SDD {0} {1}" -f $nomeNivel.ToUpperInvariant(), $status)
  if ($status -eq 'PASS') { return 0 }
  return 1
}

function Invoke-SddFix {
  $codigo = 0
  foreach ($g in (Get-SddGates 'fix')) {
    $nome = [string](Get-SddProp $g 'nome' 'fix')
    $r = Invoke-SddComando -Cmd @(Get-SddProp $g 'cmd' @()) -Log (Join-Path $script:Estado ("logs/fix_" + ($nome -replace '[^A-Za-z0-9_-]', '_') + '.log'))
    $st = 'OK'
    if ($r.Exit -ne 0) { $st = 'FALHOU'; $codigo = 1 }
    Write-SddLinha ("  [{0}] {1}" -f $st, $nome)
  }
  return $codigo
}

# ---------------------------------------------------------------------
# test <alvo>: o proprio motor grava a evidencia (sem hook, sem pipe)
# ---------------------------------------------------------------------

# Soma as contagens de varios arquivos de relatorio (ex.: um TRX por projeto de teste).
function Get-SddContagensSoma([string]$Formato, [string[]]$Arquivos, [string]$IgnorarCasos) {
  $soma = $null
  foreach ($a in $Arquivos) {
    $c = Get-SddContagens $Formato $a $IgnorarCasos
    if ($null -eq $c) { continue }
    if ($null -eq $soma) { $soma = $c; continue }
    $soma = [pscustomobject]@{ Tests = $soma.Tests + $c.Tests; Falhas = $soma.Falhas + $c.Falhas; Erros = $soma.Erros + $c.Erros; Puladas = $soma.Puladas + $c.Puladas; Carga = ($soma.Carga -or $c.Carga) }
  }
  return $soma
}

# Falhas = assercao; Erros = excecao/timeout/erro de execucao (nao vale como RED).
function Get-SddContagens([string]$Formato, [string]$Arquivo, [string]$IgnorarCasos) {
  if (-not (Test-Path -LiteralPath $Arquivo)) { return $null }
  $tests = 0; $falhas = 0; $erros = 0; $puladas = 0; $carga = $false
  if ($Formato -eq 'dart-json') {
    # Eventos do --file-reporter json do flutter/dart test: testStart traz o
    # nome; testDone traz result (success|failure|error), hidden e skipped.
    # Arquivo que nao compila vira o teste virtual 'loading <arquivo>'.
    $nomes = @{}
    foreach ($l in [System.IO.File]::ReadAllLines($Arquivo, [System.Text.Encoding]::UTF8)) {
      if ($l.Trim() -eq '') { continue }
      try { $e = $l | ConvertFrom-Json } catch { continue }
      $tipo = [string](Get-SddProp $e 'type' '')
      if ($tipo -eq 'testStart') { $nomes[[string]$e.test.id] = [string]$e.test.name }
      elseif ($tipo -eq 'testDone') {
        $nome = [string]$nomes[[string]$e.testID]
        $res = [string]$e.result
        if ($nome.StartsWith('loading ')) { if ($res -ne 'success') { $carga = $true }; continue }
        if ((Get-SddProp $e 'hidden' $false) -eq $true) { continue }
        if ((Get-SddProp $e 'skipped' $false) -eq $true) { $puladas++; continue }
        $tests++
        if ($res -eq 'failure') { $falhas++ } elseif ($res -ne 'success') { $erros++ }
      }
    }
    return [pscustomobject]@{ Tests = $tests; Falhas = $falhas; Erros = $erros; Puladas = $puladas; Carga = $carga }
  }
  if ($Formato -eq 'unreal-json') {
    # index.json do -ReportExportPath (campos observados, NAO documentados pela Epic).
    try { $j = [System.IO.File]::ReadAllText($Arquivo, [System.Text.Encoding]::UTF8) | ConvertFrom-Json } catch { return $null }
    $ok = [int](Get-SddProp $j 'succeeded' 0) + [int](Get-SddProp $j 'succeededWithWarnings' 0)
    $falhas = [int](Get-SddProp $j 'failed' 0)
    return [pscustomobject]@{ Tests = $ok + $falhas; Falhas = $falhas; Erros = 0; Puladas = [int](Get-SddProp $j 'notRun' 0); Carga = $false }
  }
  try { [xml]$x = [System.IO.File]::ReadAllText($Arquivo) } catch { return $null }
  switch ($Formato) {
    'junit' {
      # Conta pelos testcase (robusto a suites aninhadas e a testes de topo);
      # so cai nos atributos da suite se o relatorio nao listar casos.
      # IgnorarCasos: casos que nao sao teste de verdade (ex.: o node:test
      # reporta o proprio arquivo como caso quando ele nao tem nenhum test()).
      $casos = @($x.SelectNodes('//testcase'))
      if ($IgnorarCasos) {
        $ignorados = @($casos | Where-Object { $_.GetAttribute('name') -match $IgnorarCasos })
        # Caso-arquivo que falhou = o arquivo nem carregou: e carga, nao zero.
        if (@($ignorados | Where-Object { $_.SelectSingleNode('failure') -or $_.SelectSingleNode('error') }).Count -gt 0) { $carga = $true }
        $casos = @($casos | Where-Object { $_.GetAttribute('name') -notmatch $IgnorarCasos })
      }
      if ($casos.Count -gt 0 -or $IgnorarCasos) {
        $falhas = @($casos | Where-Object { $_.SelectSingleNode('failure') }).Count
        $erros = @($casos | Where-Object { -not $_.SelectSingleNode('failure') -and $_.SelectSingleNode('error') }).Count
        $puladas = @($casos | Where-Object { $_.SelectSingleNode('skipped') }).Count
        $tests = $casos.Count - $puladas
      } else {
        foreach ($s in @($x.SelectNodes('//testsuite') | Where-Object { @($_.SelectNodes('testsuite')).Count -eq 0 })) {
          $tests += [int]('0' + $s.GetAttribute('tests'))
          $falhas += [int]('0' + $s.GetAttribute('failures'))
          $erros += [int]('0' + $s.GetAttribute('errors'))
          $puladas += [int]('0' + $s.GetAttribute('skipped'))
        }
        $tests = $tests - $puladas
      }
    }
    'trx' {
      $ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
      $ns.AddNamespace('t', 'http://microsoft.com/schemas/VisualStudio/TeamTest/2010')
      $c = $x.SelectSingleNode('//t:ResultSummary/t:Counters', $ns)
      if ($null -eq $c) { return $null }
      $tests = [int]('0' + $c.GetAttribute('executed'))
      $falhas = [int]('0' + $c.GetAttribute('failed'))
      $erros = [int]('0' + $c.GetAttribute('error')) + [int]('0' + $c.GetAttribute('timeout')) + [int]('0' + $c.GetAttribute('aborted'))
      $puladas = [int]('0' + $c.GetAttribute('notExecuted'))
    }
    'nunit3' {
      $r = $x.SelectSingleNode('/test-run')
      if ($null -eq $r) { return $null }
      $tests = [int]('0' + $r.GetAttribute('total'))
      $puladas = [int]('0' + $r.GetAttribute('skipped'))
      $erros = @($x.SelectNodes("//test-case[@result='Failed' and (@label='Error' or @label='Invalid')]")).Count
      $falhas = [int]('0' + $r.GetAttribute('failed')) - $erros
      if ($falhas -lt 0) { $falhas = 0 }
      $tests = $tests - $puladas
    }
    default { return $null }
  }
  return [pscustomobject]@{ Tests = $tests; Falhas = $falhas; Erros = $erros; Puladas = $puladas; Carga = $carga }
}

function Test-SddPadroes([string[]]$Linhas, [object[]]$Padroes) {
  $texto = $Linhas -join "`n"
  foreach ($pad in @($Padroes)) { if ($pad -and $texto -match [string]$pad) { return $true } }
  return $false
}

function Resolve-SddLedger([string]$ChangeNN) {
  if ($ChangeNN) { return (Join-Path (Find-SddChange $ChangeNN).Dir 'evidence.jsonl') }
  $ativas = @(Get-SddAtivas)
  if ($ativas.Count -eq 1) { return (Join-Path $ativas[0].Dir 'evidence.jsonl') }
  if ($ativas.Count -gt 1) { throw ("ha " + $ativas.Count + " changes In-Implementation: informe --change <NN>") }
  return (Join-Path $script:Estado 'evidencia-avulsa.jsonl')
}

function Invoke-SddTest([string[]]$Argv) {
  $alvo = $null; $changeNN = $null; $sonda = $null
  for ($i = 0; $i -lt $Argv.Count; $i++) {
    $a = $Argv[$i]
    if ($a -eq '--change') { $i++; $changeNN = $Argv[$i] }
    elseif ($a -eq '--sonda') { $i++; $sonda = $Argv[$i] }
    elseif ($null -eq $alvo) { $alvo = $a }
    else { throw "argumento inesperado: $a" }
  }
  if (-not $alvo) { throw 'uso: sdd test <alvo> [--change NN] [--sonda carga|red|zero]' }
  # Sem aspas, & | < > % nem crase: runners .cmd/.bat (npm, flutter) passam o alvo pelo cmd.exe.
  if ($alvo -match '["&|<>%`\r\n]') { throw "alvo com caractere proibido: $alvo" }
  if ($sonda -and @('carga', 'red', 'zero') -notcontains $sonda) { throw "sonda invalida: $sonda" }
  $p = Get-SddPerfil
  $ledger = Resolve-SddLedger $changeNN
  $t0 = Get-SddEpochMs
  $relDir = Join-Path $script:Estado 'relatorios'
  if (-not (Test-Path -LiteralPath $relDir)) { New-Item -ItemType Directory -Path $relDir -Force | Out-Null }
  $relatorio = Join-Path $relDir ("teste-$t0.xml")
  # Ferramentas que gravam uma pasta de relatorio (Unreal: index.json) usam {relatorio_dir}.
  $relatorioDir = Join-Path $relDir ("teste-$t0.d")
  $extra = @{ alvo = $alvo; relatorio = $relatorio; relatorio_dir = $relatorioDir; raiz = $script:Raiz }
  $kind = $null; $exitRun = 0; $cont = $null; $confianca = 'exit'
  $padCarga = @(Get-SddProp $p 'test.padroes_carga' @())
  $padZero = @(Get-SddProp $p 'test.padroes_zero' @())
  $build = Get-SddProp $p 'test.build'
  if ($build) {
    $rb = Invoke-SddComando -Cmd @($build) -Log (Join-Path $script:Estado 'logs/test_build.log') -Extra $extra
    if ($rb.Exit -ne 0) {
      $exitRun = $rb.Exit; $confianca = 'build'
      if (@(Get-SddProp $p 'test.build_exit_zero' @()) -contains $rb.Exit) { $kind = 'zero' } else { $kind = 'carga' }
      foreach ($t in ($rb.Linhas | Select-Object -Last 20)) { Write-SddLinha ("  | " + $t) }
    }
  }
  if (-not $kind) {
    $run = Get-SddProp $p 'test.run'
    if (-not $run) { throw 'perfil sem test.run' }
    $r = Invoke-SddComando -Cmd @($run) -Log (Join-Path $script:Estado 'logs/test_run.log') -Extra $extra
    $exitRun = $r.Exit
    foreach ($t in ($r.Linhas | Select-Object -Last 30)) { Write-SddLinha ("  | " + $t) }
    $formato = [string](Get-SddProp $p 'test.relatorio' '')
    if ($formato) {
      # Relatorio num arquivo ({relatorio}) ou numa pasta ({relatorio_dir}: um
      # arquivo por projeto de teste, somados; index.json no Unreal).
      $arquivos = @($relatorio)
      if ($formato -eq 'unreal-json') { $arquivos = @(Join-Path $relatorioDir 'index.json') }
      elseif (-not (Test-Path -LiteralPath $relatorio) -and (Test-Path -LiteralPath $relatorioDir)) {
        $arquivos = @(Get-ChildItem -LiteralPath $relatorioDir -Recurse -File | Where-Object { $_.Extension -in @('.trx', '.xml', '.json') } | ForEach-Object { $_.FullName })
      }
      $cont = Get-SddContagensSoma $formato $arquivos ([string](Get-SddProp $p 'test.ignorar_casos' ''))
      if ($null -eq $cont) { $kind = 'carga'; $confianca = 'relatorio-ausente' }
      else {
        $confianca = 'relatorio'
        if ($cont.Carga) { $kind = 'carga' }
        elseif ($cont.Tests -le 0) { $kind = 'zero' }
        elseif ($cont.Falhas -gt 0) {
          # Falha de carga pode aparecer no relatorio como teste falho
          # (node --test, flutter test): o padrao de carga desempata.
          if ($r.Exit -ne 0 -and (Test-SddPadroes $r.Linhas $padCarga)) { $kind = 'carga'; $confianca = 'relatorio+padrao' }
          else { $kind = 'falha' }
        }
        elseif ($cont.Erros -gt 0) { $kind = 'erro' }
        elseif ($r.Exit -ne 0 -and (Get-SddProp $p 'test.ignorar_exit' $false) -ne $true) {
          # Relatorio verde com exit de falha: outro projeto falhou, o relatorio
          # foi sobrescrito ou o runner quebrou depois. Nunca vale como GREEN.
          $kind = 'inconsistente'
        }
        else { $kind = 'passou' }
      }
    } else {
      if ($r.Exit -eq 0) {
        if (Test-SddPadroes $r.Linhas $padZero) { $kind = 'zero' } else { $kind = 'passou' }
      } else {
        $kind = 'falha'
        if (Test-SddPadroes $r.Linhas $padCarga) { $kind = 'carga' }
        elseif (Test-SddPadroes $r.Linhas $padZero) { $kind = 'zero' }
      }
    }
  }
  $reg = [ordered]@{
    t = $t0; ts = (Get-SddIsoAgora); alvo = $alvo; resultado = $kind; exit = $exitRun; confianca = $confianca
    tests = $(if ($cont) { $cont.Tests } else { $null }); falhas = $(if ($cont) { $cont.Falhas } else { $null }); erros = $(if ($cont) { $cont.Erros } else { $null })
    arvore = (Get-SddArvore); head = (Get-SddHead); perfil = (Get-SddPerfilSha)
  }
  if ($sonda) { $reg['sonda'] = $sonda }
  Add-SddLinhaComTrava $ledger ($reg | ConvertTo-Json -Compress)
  $relLedger = $ledger.Substring($script:Raiz.Length).TrimStart('\', '/').Replace('\', '/')
  Write-SddLinha ("SDD TEST {0} (confianca: {1}{2}) -> {3}" -f $kind.ToUpperInvariant(), $confianca, $(if ($cont) { ", testes=$($cont.Tests), falhas=$($cont.Falhas)" } else { '' }), $relLedger)
  if ($kind -eq 'passou') { return 0 }
  if ($exitRun -ne 0) { return $exitRun }
  return 1
}

# ---------------------------------------------------------------------
# goal <NN>: condicao de parada verificavel por maquina
# ---------------------------------------------------------------------

function ConvertTo-SddRegexGlob([string]$Glob) {
  $g = $Glob.Replace('\', '/').Trim()
  if ($g.EndsWith('/')) { $g = $g + '**' }
  $sb = New-Object System.Text.StringBuilder
  $i = 0
  while ($i -lt $g.Length) {
    $ch = $g[$i]
    if ($ch -eq '*') {
      if ($i + 1 -lt $g.Length -and $g[$i + 1] -eq '*') { [void]$sb.Append('.*'); $i += 2; if ($i -lt $g.Length -and $g[$i] -eq '/') { $i++ }; continue }
      [void]$sb.Append('[^/]*')
    } elseif ($ch -eq '?') { [void]$sb.Append('[^/]') }
    else { [void]$sb.Append([regex]::Escape([string]$ch)) }
    $i++
  }
  return '^' + $sb.ToString() + '$'
}

function Test-SddCaminhoNoImpact([string]$Caminho, [string[]]$Globs) {
  foreach ($g in $Globs) {
    if ([string]::IsNullOrWhiteSpace($g)) { continue }
    if ($Caminho -match ('(?i)' + (ConvertTo-SddRegexGlob $g))) { return $true }
  }
  return $false
}

function Get-SddLedgerLinhas([string]$Arquivo) {
  $res = New-Object System.Collections.ArrayList
  $txt = Read-SddTexto $Arquivo
  if ($null -eq $txt) { return @() }
  $n = 0
  foreach ($l in ($txt -split "`n")) {
    $n++
    if ($l.Trim() -eq '') { continue }
    try { [void]$res.Add(($l | ConvertFrom-Json)) } catch { throw "linha $n invalida em $Arquivo" }
  }
  return @($res)
}

function Invoke-SddGoal([string[]]$Argv) {
  $nn = $null; $preVerify = $false
  foreach ($a in $Argv) { if ($a -eq '--pre-verify') { $preVerify = $true } elseif (-not $nn) { $nn = $a } else { throw "argumento inesperado: $a" } }
  if (-not $nn) { throw 'uso: sdd goal <NN> [--pre-verify]' }
  $c = Find-SddChange $nn
  $p = Get-SddPerfil
  $falhas = New-Object System.Collections.ArrayList
  $naoVerif = New-Object System.Collections.ArrayList
  [void]$naoVerif.Add('a ordem teste -> codigo (nenhum gate prova test-first; vale a evidencia + Verify Pass)')
  [void]$naoVerif.Add('forja deliberada de ledger/relatorio (o kit protege contra descuido, nao contra fraude)')
  function Add-Falha([string]$Crit, [string[]]$Det) { [void]$falhas.Add([pscustomobject]@{ Crit = $Crit; Det = @($Det) }) }

  if ((Get-SddProp $p 'calibrado' $false) -ne $true) { Add-Falha 'perfil' @('perfil de stack nao calibrado: rode sdd calibrate (sondas carga/red/zero)') }
  if ($c.Erro) { Add-Falha 'frontmatter' @($c.Erro) }
  $st = Get-SddStatus $c
  $base = [string](Get-SddProp $c.Fm 'base_ref' '')
  $det = New-Object System.Collections.ArrayList
  if ($st -ne 'In-Implementation') { [void]$det.Add("status '$st': goal so vale em In-Implementation") }
  if (-not (Test-SddAprovacao $c.Corpo 'P1')) { [void]$det.Add('sem aprovacao P1 registrada pelo sdd approve') }
  if (-not (Test-SddAprovacao $c.Corpo 'P2')) { [void]$det.Add('sem aprovacao P2 registrada pelo sdd approve') }
  foreach ($r in (Get-SddRiscosSemFonte $c)) { [void]$det.Add("risk '$r' exige fonte_normativa") }
  if (-not (Test-SddSecaoVazia (Get-SddSecao $c.Corpo 'Perguntas em aberto'))) { [void]$det.Add("'Perguntas em aberto' nao vazia") }
  if (-not $base) { [void]$det.Add('base_ref ausente (gravado pelo sdd approve P2)') }
  elseif ((Invoke-SddGit -GitArgs @('merge-base', '--is-ancestor', $base, 'HEAD') -PermitirFalha).Codigo -ne 0) { [void]$det.Add("base_ref $base invalido ou nao ancestral do HEAD") }
  if ($det.Count) { Add-Falha 'status' @($det) }

  $tasks = Get-SddSecao $c.Corpo 'Tasks'
  $tasksFile = Join-Path $c.Dir 'tasks.md'
  if (Test-Path -LiteralPath $tasksFile) {
    $tasksTxt = Read-SddTexto $tasksFile
    if ($tasksTxt) { $tasks = $tasksTxt }
  }
  if ($null -eq $tasks) { Add-Falha 'tasks' @('secao ## Tasks ou arquivo tasks.md ausente') }
  else {
    $ativa = ($tasks -split '(?m)^###\s+P\S{1,3}s-GOAL.*$')[0]
    $abertas = @([regex]::Matches($ativa, '(?m)^\s*-\s*\[ \]\s*(.*)$') | ForEach-Object { $_.Groups[1].Value.Trim() })
    if ($abertas.Count) { Add-Falha 'tasks abertas' $abertas }
    $ledgerArq = Join-Path $c.Dir 'evidence.jsonl'
    $ev = @()
    try { $ev = @(Get-SddLedgerLinhas $ledgerArq) } catch { Add-Falha 'evidencia' @($_.Exception.Message) }
    $semLastro = New-Object System.Collections.ArrayList
    # Cenario -> fases cobertas. Cada execucao pode listar varias tags; o goal
    # agrega a cobertura da change inteira sem exigir uma chamada por cenario.
    $cobertura = @{}
    $pares = 0
    foreach ($m in [regex]::Matches($ativa, '(?m)^\s*-\s*\[[xX]\]\s*(RED|GREEN|MANUAL)\b([^:\r\n]*):\s*(.+?)\s*(->|$)')) {
      $fase = $m.Groups[1].Value
      $cns = @([regex]::Matches($m.Groups[2].Value, 'C\d+[a-z]?') | ForEach-Object { $_.Value })
      $alvo = $m.Groups[3].Value.Trim().Trim('`').Trim()
      $ok = $false
      if ($fase -eq 'MANUAL') {
        $ok = $true
        [void]$naoVerif.Add("evidencia MANUAL de $($cns -join ',') (sem lastro de maquina): '$alvo'")
      } else {
        $doAlvo = @($ev | Where-Object { [string]$_.alvo -eq $alvo } | Sort-Object { [long]$_.t })
        if ($fase -eq 'RED') {
          $red = @($doAlvo | Where-Object { $_.resultado -eq 'falha' })
          if ($red.Count -eq 0) { [void]$semLastro.Add("RED de '$alvo' sem execucao com resultado 'falha' (carga, zero, erro e inconsistente nao contam)") }
          else {
            $ok = $true
            if (@($red | Where-Object { $_.confianca -eq 'relatorio' }).Count -eq 0) { [void]$naoVerif.Add("RED de '$alvo' classificado so pelo exit code (perfil sem relatorio estruturado)") }
          }
        } else {
          if ($doAlvo.Count -eq 0 -or $doAlvo[-1].resultado -ne 'passou') { [void]$semLastro.Add("GREEN de '$alvo': a ultima execucao registrada nao passou") }
          elseif (@($doAlvo | Where-Object { $_.resultado -eq 'falha' }).Count -eq 0) { [void]$semLastro.Add("GREEN de '$alvo' sem RED anterior registrado") }
          else { $ok = $true }
        }
      }
      if ($ok) {
        if ($fase -ne 'GREEN') { $pares = $pares -bor 1 }
        if ($fase -ne 'RED') { $pares = $pares -bor 2 }
        foreach ($cn in $cns) {
          if (-not $cobertura.ContainsKey($cn)) { $cobertura[$cn] = 0 }
          if ($fase -ne 'GREEN') { $cobertura[$cn] = $cobertura[$cn] -bor 1 }
          if ($fase -ne 'RED') { $cobertura[$cn] = $cobertura[$cn] -bor 2 }
        }
      }
    }
    $cenarios = @([regex]::Matches($c.Corpo, '(?m)^#{2,6}\s*Scenario:\s*(C\d+[a-z]?)\b') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    if ($cenarios.Count -gt 0) {
      foreach ($cn in $cenarios) {
        $v = 0
        if ($cobertura.ContainsKey($cn)) { $v = $cobertura[$cn] }
        if ($v -ne 3) { [void]$semLastro.Add("cenario $cn sem RED e GREEN agregados com lastro (inclua a tag $cn nas linhas da suite)") }
      }
    } elseif ($pares -ne 3) { [void]$semLastro.Add('change sem evidencia de teste: nenhum cenario nos deltas e nenhum par RED/GREEN com lastro') }
    if ($semLastro.Count) { Add-Falha 'evidencia sem lastro' @($semLastro) }
  }

  $arvAtual = Get-SddArvore
  $full = $null
  $fullTxt = Read-SddTexto (Join-Path $script:Estado 'last-full.json')
  if ($fullTxt) { $full = $fullTxt | ConvertFrom-Json }
  if ($null -eq $full) { Add-Falha 'validate' @('nenhum sdd validate completo registrado nesta copia de trabalho') }
  elseif ($full.status -ne 'PASS') { Add-Falha 'validate' @("ultimo validate: $($full.status)") }
  elseif ($full.arvore -ne $arvAtual) { Add-Falha 'validate' @('o codigo mudou depois do ultimo validate completo: rode sdd validate de novo') }

  if ($base) {
    # FAIL so para o que esta no working tree (o que esta change vai commitar).
    # O que entrou por commit depois do base_ref (merge de outra frente) ou e do
    # impact de outra change ativa vira aviso.
    $noWt = @{}
    foreach ($x in (Invoke-SddGit -GitArgs @('diff', '--name-only', 'HEAD') -PermitirFalha).Out) { if ($x) { $noWt[$x.Replace('\', '/')] = $true } }
    foreach ($x in (Invoke-SddGit -GitArgs @('ls-files', '--others', '--exclude-standard')).Out) { if ($x) { $noWt[$x.Replace('\', '/')] = $true } }
    $commitado = @((Invoke-SddGit -GitArgs @('diff', '--name-only', $base, 'HEAD') -PermitirFalha).Out | Where-Object { $_ } | ForEach-Object { $_.Replace('\', '/') })
    $imp = Get-SddProp $c.Fm 'impact'
    $globs = @()
    if ($imp) { $globs = @(@(Get-SddProp $imp 'modified_files' @()) + @(Get-SddProp $imp 'new_files' @()) | ForEach-Object { [string]$_ }) }
    $outras = @()
    foreach ($o in (Get-SddAtivas)) {
      if ($o.Nome -eq $c.Nome) { continue }
      $oi = Get-SddProp $o.Fm 'impact'
      if ($oi) { $outras += @(@(Get-SddProp $oi 'modified_files' @()) + @(Get-SddProp $oi 'new_files' @()) | ForEach-Object { [string]$_ }) }
    }
    $root = Get-SddSpecsRoot
    $ic = [System.StringComparison]::OrdinalIgnoreCase
    $fora = New-Object System.Collections.ArrayList
    $avisos = New-Object System.Collections.ArrayList
    foreach ($a in (@($noWt.Keys) + $commitado | Select-Object -Unique)) {
      if ($a.StartsWith($c.Rel + '/', $ic)) { continue }
      if ($a.StartsWith('.sdd/state/', $ic)) { continue }
      if ($a -eq '.sdd/profile.json') { [void]$avisos.Add('.sdd/profile.json mudou desde o base_ref: confira se nenhum gate foi afrouxado'); continue }
      if ($a.StartsWith($root + '/', $ic)) { [void]$avisos.Add("$a (pasta de specs, fora da change)"); continue }
      if ($a.StartsWith('.agents/reports/', $ic)) { [void]$avisos.Add("$a (relatorio)"); continue }
      if (Test-SddCaminhoNoImpact $a $globs) { continue }
      if (-not $noWt.ContainsKey($a)) { [void]$avisos.Add("$a (entrou por commit depois do base_ref, fora do impact)"); continue }
      if (Test-SddCaminhoNoImpact $a $outras) { [void]$avisos.Add("$a (impact de outra change ativa)"); continue }
      [void]$fora.Add($a)
    }
    if ($fora.Count) { Add-Falha 'fora do impact' @($fora) }
    foreach ($w in $avisos) { [void]$naoVerif.Add("revisar: $w") }
  }

  if (-not (Test-SddSecaoVazia (Get-SddSecao $c.Corpo 'Excecoes'))) { Add-Falha 'excecoes' @('## Excecoes nao vazia: resolva ou leve o residuo para o backlog antes de fechar') }

  if (-not $preVerify) {
    $vtxt = Read-SddTexto (Join-Path $c.Dir 'verify.md')
    if ($null -eq $vtxt) { Add-Falha 'verificador' @('verify.md ausente: rode o verificador independente (sdd-verify) e grave com sdd verify-record') }
    else {
      $vd = New-Object System.Collections.ArrayList
      if ($vtxt -notmatch '(?m)^Veredito:\s*APROVADO\s*$') { [void]$vd.Add('verify.md sem Veredito: APROVADO') }
      $mv = [regex]::Match($vtxt, '(?m)^arvore:\s*([0-9a-f]+)\s*$')
      if (-not $mv.Success) { [void]$vd.Add('verify.md sem a linha arvore: (grave pelo sdd verify-record)') }
      elseif ($mv.Groups[1].Value -ne $arvAtual) { [void]$vd.Add('o codigo mudou depois da verificacao: verifique de novo') }
      if ($vd.Count) { Add-Falha 'verificador' @($vd) }
    }
  } else { [void]$naoVerif.Add('verificador (modo --pre-verify)') }

  foreach ($f in $falhas) {
    Write-SddLinha "[$($f.Crit)]"
    foreach ($d in ($f.Det | Select-Object -First 12)) { Write-SddLinha "  - $d" }
  }
  Write-SddLinha 'Nao verificado por maquina:'
  foreach ($n in $naoVerif) { Write-SddLinha "  - $n" }
  $resultado = 'GOAL PASS'
  if ($falhas.Count) { $resultado = 'GOAL FAIL: ' + (($falhas | ForEach-Object { $_.Crit }) -join '; ') }
  elseif ($preVerify) { $resultado = 'GOAL PASS (pre-verify)' }
  $estadoGoal = [ordered]@{ t = (Get-SddEpochMs); ts = (Get-SddIsoAgora); change = $c.Nome; resultado = $resultado; arvore = $arvAtual }
  Write-SddTextoAtomico (Join-Path $script:Estado ("goal-" + $c.Nome + ".json")) ($estadoGoal | ConvertTo-Json)
  Write-SddLinha $resultado
  if ($falhas.Count) { return 1 }
  return 0
}

# ---------------------------------------------------------------------
# Frase do usuario vale como aprovacao se citar a aprovacao, o portao e o
# numero da change (CHG-002, D2). Ex.: "aprovo P1 da change 01".
function Test-SddFraseAprovacao([string]$Frase, [string]$Portao, [string]$NN) {
  $num = [int]($NN -replace '\D', '')
  if ($Frase -notmatch '(?i)aprov') { return $false }
  if ($Frase -notmatch ('(?i)\b' + $Portao + '\b')) { return $false }
  # O numero so vale colado a "change" ou "CHG" (D10): numero solto, como uma
  # data ou o "1" de "P1", nao cita a change; citar outra change recusa.
  # Compara como texto sem zeros a esquerda: numero gigante nao vira excecao (achado A3).
  $alvo = ([string]$num).TrimStart('0')
  $citadas = @([regex]::Matches($Frase, '(?i)\b(?:change|chg)[\s\-_:#]*([0-9]+)\b') | ForEach-Object { $_.Groups[1].Value.TrimStart('0') })
  if ($citadas.Count -eq 0) { return $false }
  return (@($citadas | Where-Object { $_ -ne $alvo }).Count -eq 0)
}

# approve <NN> P1|P2 [--frase "<texto>"]: no terminal humano (codigo digitado)
# ou pela IA com a frase do usuario no chat (registrada na linha).
# ---------------------------------------------------------------------

function Test-SddTerminalHumano {
  if ([Console]::IsInputRedirected) { return $false }
  if ($env:CLAUDECODE) { return $false }
  if ($env:SDD_AGENTE) { return $false }
  return $true
}

function Set-SddCampoFrontmatter([string]$Texto, [string]$Campo, [string]$Valor) {
  $t = $Texto -replace "`r`n", "`n"
  $fim = $t.IndexOf("`n---", 3)
  if (-not $t.StartsWith('---') -or $fim -lt 0) { throw 'frontmatter ausente' }
  $cab = $t.Substring(0, $fim)
  $resto = $t.Substring($fim)
  $re = '(?m)^' + [regex]::Escape($Campo) + ':.*$'
  if ($cab -match $re) { $cab = [regex]::Replace($cab, $re, ($Campo + ': ' + $Valor)) }
  else { $cab = $cab + "`n" + $Campo + ': ' + $Valor }
  return $cab + $resto
}

function Invoke-SddApprove([string[]]$Argv) {
  $frase = $null
  $pos = @()
  for ($i = 0; $i -lt $Argv.Count; $i++) {
    if ($Argv[$i] -eq '--frase') {
      if ($i + 1 -ge $Argv.Count) { throw 'uso: --frase "<frase do usuario>"' }
      $frase = $Argv[$i + 1]; $i++
    } else { $pos += $Argv[$i] }
  }
  if ($pos.Count -ne 2 -or @('P0', 'P1', 'P2') -notcontains $pos[1].ToUpperInvariant()) { throw 'uso: sdd approve <NN> P0|P1|P2 [--frase "<frase do usuario>"]' }
  $portao = $pos[1].ToUpperInvariant()
  if ($null -ne $frase) {
    $frase = (($frase -replace '\s+', ' ') -replace '"', "'").Trim()
    if (-not (Test-SddFraseAprovacao $frase $portao $pos[0])) {
      Write-SddLinha ("RECUSADO: frase sem aprovacao, portao ou numero da change (ex.: 'aprovo {0} da change {1}')." -f $portao, $pos[0])
      return 1
    }
  } elseif (-not (Test-SddTerminalHumano)) {
    Write-SddLinha ("RECUSADO: o portao so pode ser aprovado por voce: no seu terminal, ou pela IA com a sua frase (--frase `"aprovo {0} da change {1}`")." -f $portao, $pos[0])
    return 1
  }
  $Argv = $pos
  $c = Find-SddChange $Argv[0]
  if ($c.Erro) { throw "frontmatter invalido: $($c.Erro)" }
  $st = Get-SddStatus $c
  $rotulo = $portao
  $semFonte = @(Get-SddRiscosSemFonte $c)
  if ($semFonte.Count) { throw ("risk " + ($semFonte -join ', ') + " exige fonte_normativa antes do portao") }
  if ($portao -eq 'P0') {
    if ($st -ne 'Draft') { throw "P0 exige status Draft (atual: $st)" }
    $novo = 'Draft'
  } elseif ($portao -eq 'P1') {
    if ($st -ne 'Draft') { throw "P1 exige status Draft (atual: $st)" }
    if (-not (Test-SddSecaoVazia (Get-SddSecao $c.Corpo 'Perguntas em aberto'))) { throw "'Perguntas em aberto' nao esta vazia" }
    $novo = 'Approved'
  } else {
    if (-not (Test-SddAprovacao $c.Corpo 'P1')) { throw 'P2 exige a linha P1 gravada pelo sdd approve (o status foi mudado por fora?)' }
    if (Test-SddSecaoVazia (Get-SddSecao $c.Corpo 'Analise pre-implementacao')) { throw 'Analise pre-implementacao vazia' }
    if ($st -eq 'Approved') { $novo = 'In-Implementation' }
    elseif ($st -eq 'In-Implementation') {
      # Rebase/squash tirou o base_ref da historia: o usuario re-ancora no HEAD atual.
      $novo = 'In-Implementation'; $rotulo = 'P2 (rebase)'
      Write-SddLinha '  Change ja em In-Implementation: este P2 so re-ancora o base_ref no HEAD atual (depois de rebase/squash).'
    }
    else { throw "P2 exige status Approved (atual: $st)" }
  }
  Write-SddLinha ''
  Write-SddLinha ("  {0} - {1}" -f [string](Get-SddProp $c.Fm 'id'), [string](Get-SddProp $c.Fm 'title'))
  Write-SddLinha ("  risk: {0}" -f ((@(Get-SddProp $c.Fm 'risk' @())) -join ', '))
  Write-SddLinha ("  portao {0}: {1} -> {2}" -f $portao, $st, $novo)
  $token = -join ((1..4) | ForEach-Object { 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[(Get-Random -Maximum 32)] })
  if ($null -eq $frase) {
    Write-SddLinha "  Para aprovar, digite o codigo $token e Enter (qualquer outra coisa cancela):"
    $resp = [Console]::ReadLine()
    if ($resp -ne $token) { Write-SddLinha 'Cancelado.'; return 1 }
  }
  $nome = ((Invoke-SddGit -GitArgs @('config', 'user.name') -PermitirFalha).Out | Select-Object -Last 1)
  if (-not $nome) { $nome = $env:USERNAME }
  $hashAntes = (Get-SddSha256Texto $c.Texto).Substring(0, 12)
  $texto = Set-SddCampoFrontmatter $c.Texto 'status' $novo
  if ($portao -eq 'P2') { $texto = Set-SddCampoFrontmatter $texto 'base_ref' (Get-SddHead) }
  $via = ''
  if ($null -ne $frase) { $via = ('via chat: "' + $frase + '"; ') }
  $linha = ("- {0}: aprovado por {1} em {2} (sdd approve; {3}change.md antes: {4})" -f $rotulo, $nome, (Get-Date).ToString('yyyy-MM-dd HH:mm'), $via, $hashAntes)
  $t = $texto -replace "`r`n", "`n"
  $m = [regex]::Match($t, '(?m)^##\s+Aprova\S*\s*$')
  if ($m.Success) {
    $ini = $m.Index + $m.Length
    $prox = [regex]::Match($t.Substring($ini), '(?m)^##\s')
    $pos = if ($prox.Success) { $ini + $prox.Index } else { $t.Length }
    $antes = $t.Substring(0, $pos).TrimEnd("`n")
    $t = $antes + "`n" + $linha + "`n" + $(if ($prox.Success) { "`n" + $t.Substring($pos) } else { '' })
  } else {
    $t = $t.TrimEnd("`n") + "`n`n## Aprovacoes`n`n" + $linha + "`n"
  }
  Write-SddTextoAtomico $c.Arquivo $t
  Write-SddLinha "APROVADO: $($c.Nome) $portao -> $novo"
  return 0
}

# ---------------------------------------------------------------------
# verify-record <NN> APROVADO|REPROVADO: grava o relatorio do verificador
# ---------------------------------------------------------------------

function Invoke-SddVerifyRecord([string[]]$Argv) {
  $nn = $null; $veredito = $null; $arquivo = $null
  for ($i = 0; $i -lt $Argv.Count; $i++) {
    if ($Argv[$i] -eq '--arquivo') { $i++; $arquivo = $Argv[$i] }
    elseif (-not $nn) { $nn = $Argv[$i] }
    elseif (-not $veredito) { $veredito = $Argv[$i].ToUpperInvariant() }
    else { throw "argumento inesperado: $($Argv[$i])" }
  }
  if (-not $nn -or @('APROVADO', 'REPROVADO') -notcontains $veredito) { throw 'uso: sdd verify-record <NN> APROVADO|REPROVADO [--arquivo relatorio.md] (ou relatorio via stdin)' }
  $c = Find-SddChange $nn
  if ($arquivo) { $corpo = Read-SddTexto $arquivo; if ($null -eq $corpo) { throw "arquivo nao encontrado: $arquivo" } }
  elseif ([Console]::IsInputRedirected) {
    $leitor = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $script:Utf8, $true)
    try { $corpo = $leitor.ReadToEnd() } finally { $leitor.Dispose() }
  }
  else { throw 'envie o relatorio por --arquivo ou stdin' }
  if ([string]::IsNullOrWhiteSpace($corpo)) { throw 'relatorio vazio' }
  if ($corpo -match '(?m)^(Veredito|arvore):') { throw "o corpo do relatorio nao pode conter linhas 'Veredito:' ou 'arvore:' (o motor as grava)" }
  $cab = @(
    "Veredito: $veredito",
    "arvore: $(Get-SddArvore)",
    "head: $(Get-SddHead)",
    "data: $(Get-SddIsoAgora)",
    'registrado-por: sdd verify-record',
    '---',
    ''
  ) -join "`n"
  Write-SddTextoAtomico (Join-Path $c.Dir 'verify.md') ($cab + ($corpo -replace "`r`n", "`n"))
  Write-SddLinha "verify.md gravado em $($c.Rel) (Veredito: $veredito)"
  return 0
}

# ---------------------------------------------------------------------
# commit-gate (pre-commit) e instalacao do hook
# ---------------------------------------------------------------------

function Invoke-SddCommitGate {
  $p = Get-SddPerfil
  $nivel = [string](Get-SddProp $p 'commit_gate' 'full')
  $aceitos = @('full')
  if ($nivel -eq 'light') { $aceitos = @('light', 'full') }
  $arvIndice = Get-SddArvore -DoIndice
  $ok = $false
  $motivos = New-Object System.Collections.ArrayList
  foreach ($nv in $aceitos) {
    $txt = Read-SddTexto (Join-Path $script:Estado "last-$nv.json")
    if ($null -eq $txt) { continue }
    $reg = $txt | ConvertFrom-Json
    if ($reg.status -eq 'PASS' -and $reg.arvore -eq $arvIndice) { $ok = $true; break }
    if ($reg.status -ne 'PASS') { [void]$motivos.Add("ultimo $nv : $($reg.status)") }
    else { [void]$motivos.Add("ultimo $nv validou outra arvore (houve edicao depois, ou o stage nao contem tudo o que foi validado)") }
  }
  if (-not $ok -and $motivos.Count -eq 0) { [void]$motivos.Add("nenhum '$nivel' registrado nesta copia de trabalho") }
  $lint = Invoke-SddSpecLint
  if ($lint.Status -eq 'FAIL') { $ok = $false; [void]$motivos.Add('SpecLint em FAIL') }
  foreach ($c in (Get-SddAtivas)) {
    $g = Read-SddTexto (Join-Path $script:Estado ("goal-" + $c.Nome + ".json"))
    $passou = $false
    if ($g) { $gj = $g | ConvertFrom-Json; $passou = ($gj.resultado -eq 'GOAL PASS') }
    if (-not $passou) { Write-SddLinha "  ! commit parcial da $($c.Nome): o ultimo goal nao passou" }
  }
  if ($ok) { Write-SddLinha 'COMMIT GATE PASS'; return 0 }
  foreach ($m in $motivos) { Write-SddLinha "  - $m" }
  $cmd = 'validate'
  if ($nivel -eq 'light') { $cmd = 'check' }
  Write-SddLinha "COMMIT GATE FAIL: coloque em stage tudo o que vai no commit e rode 'sdd $cmd' antes (o hook so le o resultado, nao roda gates)."
  return 1
}

function Invoke-SddInstallHook {
  $dirHooks = (Invoke-SddGit -GitArgs @('rev-parse', '--git-path', 'hooks')).Out | Select-Object -Last 1
  if (-not [System.IO.Path]::IsPathRooted($dirHooks)) { $dirHooks = Join-Path $script:Raiz $dirHooks }
  if (-not (Test-Path -LiteralPath $dirHooks)) { New-Item -ItemType Directory -Path $dirHooks -Force | Out-Null }
  $alvo = Join-Path $dirHooks 'pre-commit'
  $marca = '# sdd-kit pre-commit'
  if (Test-Path -LiteralPath $alvo) {
    $atual = Read-SddTexto $alvo
    if ($atual -match [regex]::Escape($marca)) { Write-SddLinha 'pre-commit do sdd-kit ja instalado.'; return 0 }
    Move-Item -LiteralPath $alvo -Destination (Join-Path $dirHooks 'pre-commit.local') -Force
    Write-SddLinha 'pre-commit existente preservado como pre-commit.local (sera chamado antes).'
  }
  $sh = @(
    '#!/bin/sh',
    $marca,
    '# Le o resultado do ultimo sdd check/validate; nao roda gates. Burlavel com --no-verify:',
    '# e lembrete para o humano, nao trava para a IA (essa e a regra ask/deny de git commit).',
    'HOOKS_DIR=$(dirname "$0")',
    'if [ -x "$HOOKS_DIR/pre-commit.local" ]; then "$HOOKS_DIR/pre-commit.local" || exit 1; fi',
    'ROOT=$(git rev-parse --show-toplevel)',
    'exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ROOT/tools/sdd/sdd.ps1" commit-gate'
  ) -join "`n"
  [System.IO.File]::WriteAllText($alvo, $sh + "`n", $script:Utf8)
  Write-SddLinha "pre-commit instalado em $alvo"
  return 0
}

# ---------------------------------------------------------------------
# calibrate e status
# ---------------------------------------------------------------------

function Invoke-SddCalibrate {
  [void](Get-SddPerfil)
  $arq = Join-Path $script:Raiz '.sdd/profile.json'
  $sondas = @{}
  try { $av = @(Get-SddLedgerLinhas (Join-Path $script:Estado 'evidencia-avulsa.jsonl')) } catch { $av = @() }
  foreach ($c in (Get-SddChanges)) { try { $av += @(Get-SddLedgerLinhas (Join-Path $c.Dir 'evidence.jsonl')) } catch { } }
  # Vale a sonda mais recente (por t) feita com o perfil atual (perfil sem 'calibrado').
  $shaAtual = Get-SddPerfilSha
  foreach ($e in ($av | Sort-Object { [long]$_.t })) {
    $s = Get-SddProp $e 'sonda'
    if ($s -and [string](Get-SddProp $e 'perfil' '') -eq $shaAtual) { $sondas[[string]$s] = [string]$e.resultado }
  }
  $esperado = @{ carga = 'carga'; red = 'falha'; zero = 'zero' }
  $ok = $true
  foreach ($k in @('carga', 'red', 'zero')) {
    $obtido = '(nao rodada)'
    if ($sondas.ContainsKey($k)) { $obtido = $sondas[$k] }
    $bate = ($obtido -eq $esperado[$k])
    if (-not $bate) { $ok = $false }
    Write-SddLinha ("  sonda {0,-5} esperado={1,-6} obtido={2} {3}" -f $k, $esperado[$k], $obtido, $(if ($bate) { 'OK' } else { 'X' }))
  }
  if (-not $ok) {
    Write-SddLinha 'Sondas pendentes. Siga a secao calibracao do perfil e rode, por exemplo:'
    Write-SddLinha '  sdd test <alvo-com-erro-de-compilacao> --sonda carga'
    Write-SddLinha '  sdd test <alvo-com-assercao-falsa> --sonda red'
    Write-SddLinha '  sdd test <filtro-que-nao-casa-nada> --sonda zero'
    return 1
  }
  # Marca antes de validar: o profile.json faz parte da arvore validada.
  $original = Read-SddTexto $arq
  $txt = [regex]::Replace($original, '"calibrado"\s*:\s*(true|false)', '"calibrado": true')
  if ($txt -notmatch '"calibrado"\s*:\s*true') { throw 'nao achei o campo "calibrado" no profile.json' }
  Write-SddTextoAtomico $arq $txt
  $script:Perfil = $null
  $c1 = Invoke-SddValidacao 'light'
  $c2 = Invoke-SddValidacao 'full'
  if ($c1 -ne 0 -or $c2 -ne 0) {
    Write-SddTextoAtomico $arq $original
    Write-SddLinha 'Calibracao incompleta: check e validate precisam passar numa arvore limpa (ou com quarentena documentada). Perfil continua calibrado: false.'
    return 1
  }
  $l = Read-SddTexto (Join-Path $script:Estado 'last-light.json') | ConvertFrom-Json
  $f = Read-SddTexto (Join-Path $script:Estado 'last-full.json') | ConvertFrom-Json
  $msL = 0; foreach ($g in $l.gates) { $msL += [long]$g.ms }
  $msF = 0; foreach ($g in $f.gates) { $msF += [long]$g.ms }
  $info = [ordered]@{ data = (Get-SddIsoAgora); light_s = [math]::Round($msL / 1000.0, 1); full_s = [math]::Round($msF / 1000.0, 1) }
  Write-SddTextoAtomico (Join-Path $script:Estado 'calibracao.json') ($info | ConvertTo-Json)
  Write-SddLinha ("CALIBRADO: light {0}s, full {1}s. Ajuste commit_gate no perfil se o full for caro demais." -f $info.light_s, $info.full_s)
  return 0
}

function Invoke-SddStatus {
  $p = Get-SddPerfil
  Write-SddLinha ("sdd-kit {0} | perfil {1} | calibrado: {2} | commit_gate: {3}" -f $script:SddVersao, (Get-SddProp $p 'perfil' '?'), (Get-SddProp $p 'calibrado' $false), (Get-SddProp $p 'commit_gate' 'full'))
  $arv = Get-SddArvore
  foreach ($nv in @('light', 'full')) {
    $t = Read-SddTexto (Join-Path $script:Estado "last-$nv.json")
    if ($null -eq $t) { Write-SddLinha "  $nv : nunca rodou"; continue }
    $r = $t | ConvertFrom-Json
    $fresco = if ($r.arvore -eq $arv) { 'arvore atual' } else { 'DESATUALIZADO' }
    Write-SddLinha ("  {0}: {1} em {2} ({3})" -f $nv, $r.status, $r.fim, $fresco)
  }
  foreach ($c in (Get-SddChanges | Where-Object { $_.Pasta -eq 'changes' })) {
    Write-SddLinha ("  change {0}: {1}" -f $c.Nome, (Get-SddStatus $c))
  }
  return 0
}

function Show-SddAjuda {
  @(
    "sdd-kit $($script:SddVersao) - motor do fluxo SDD",
    'Uso: powershell -File tools/sdd/sdd.ps1 <comando> [args]',
    '  check                  gates leves do perfil + SpecLint (grava .sdd/state/last-light.json)',
    '  validate               gates completos + SpecLint (grava .sdd/state/last-full.json)',
    '  fix                    auto-correcoes do perfil (formatador etc.)',
    '  test <alvo> [--change NN] [--sonda carga|red|zero]   roda um alvo e grava a evidencia',
    '  spec-lint              confere frontmatter, portoes e IDs das changes',
    '  goal <NN> [--pre-verify]   condicao de parada da change (GOAL PASS|FAIL)',
    '  archive <NN>             arquiva change com GOAL PASS e verify da arvore atual',
    '  approve <NN> P0|P1|P2 [--frase "..."]  aprova portao: no seu terminal, ou pela IA com a sua frase do chat',
    '  verify-record <NN> APROVADO|REPROVADO [--arquivo f]   grava o relatorio do verificador',
    '  commit-gate            usado pelo pre-commit: exige check/validate verde da mesma arvore',
    '  install-hook           instala o pre-commit (encadeia o que ja existir)',
    '  calibrate              confere as sondas e mede light/full; marca o perfil como calibrado',
    '  status                 resumo: perfil, ultimas validacoes, changes'
  ) | ForEach-Object { Write-SddLinha $_ }
  return 0
}

# ---------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------

function Invoke-SddMain([string[]]$Argv) {
  try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
  $OutputEncoding = [System.Text.Encoding]::UTF8
  $cmd = 'ajuda'
  $resto = @()
  if ($Argv.Count -gt 0) { $cmd = $Argv[0]; if ($Argv.Count -gt 1) { $resto = @($Argv[1..($Argv.Count - 1)]) } }
  try {
    if (@('ajuda', 'help', '-h', '--help') -contains $cmd) { return (Show-SddAjuda) }
    Initialize-SddRaiz
    switch ($cmd) {
      'check' { return (Invoke-SddValidacao 'light') }
      'validate' { return (Invoke-SddValidacao 'full') }
      'fix' { return (Invoke-SddFix) }
      'test' { return (Invoke-SddTest $resto) }
      'spec-lint' {
        $l = Invoke-SddSpecLint
        foreach ($a in $l.Achados) { Write-SddLinha "  - $a" }
        Write-SddLinha "SPECLINT $($l.Status)"
        if ($l.Status -eq 'FAIL') { return 1 } else { return 0 }
      }
      'goal' { return (Invoke-SddGoal $resto) }
      'archive' { return (Invoke-SddArchive $resto) }
      'approve' { return (Invoke-SddApprove $resto) }
      'verify-record' { return (Invoke-SddVerifyRecord $resto) }
      'commit-gate' { return (Invoke-SddCommitGate) }
      'install-hook' { return (Invoke-SddInstallHook) }
      'calibrate' { return (Invoke-SddCalibrate) }
      'status' { return (Invoke-SddStatus) }
      default { Write-SddLinha "comando desconhecido: $cmd"; [void](Show-SddAjuda); return 2 }
    }
  } catch {
    Write-SddLinha ("ERRO: " + $_.Exception.Message)
    return 2
  }
}

# So executa quando chamado como script (os testes carregam as funcoes com dot-source).
if ($MyInvocation.InvocationName -ne '.') {
  $codigoSaida = Invoke-SddMain -Argv ([string[]]$args)
  exit $codigoSaida
}
