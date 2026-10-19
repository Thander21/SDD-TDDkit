# =====================================================================
# sdd-kit | install.ps1
# Instala, confere e atualiza o kit SDD num projeto, e instala o guard da
# maquina. Compativel com Windows PowerShell 5.1 e PowerShell 7. ASCII.
#
#   install.ps1                (assistente: pergunta a pasta e o perfil)
#   install.ps1 projeto -Destino <repo> -Perfil <node|python|dotnet|flutter|rust|unity|unreal>
#   install.ps1 check   -Destino <repo>
#   install.ps1 update  -Destino <repo> [-Forcar]
#   install.ps1 maquina [-Aplicar] [-Casa <pasta; padrao = perfil do usuario>]
#
# Regras: arvore git limpa antes de instalar/atualizar (o diff e a revisao e
# o rollback; no assistente, arvore suja so pede confirmacao); plano completo antes de gravar (nunca sucesso parcial); a
# camada do projeto (AGENTS.md fora dos marcadores, profile.json, regras de
# dominio) nunca e sobrescrita; executavel editado no projeto = FAIL.
# =====================================================================
param(
  [Parameter(Position = 0)][ValidateSet('projeto', 'check', 'update', 'maquina', 'detectar', 'modo-pasta', 'remover')][string]$Acao,
  [string]$Destino,
  [string]$Perfil,
  [switch]$Forcar,
  [switch]$Aplicar,
  [switch]$SemArvoreLimpa,
  [switch]$ModoPasta,
  [string]$Casa
)
$ErrorActionPreference = 'Stop'
$Kit = $PSScriptRoot
$Kernel = Join-Path $Kit 'kernel'
$Utf8 = New-Object System.Text.UTF8Encoding $false
$MarcaIni = '<!-- sdd-kit:begin -->'
$MarcaFim = '<!-- sdd-kit:end -->'
# Sem acao = assistente: pergunta o que faltar e nao trava em arvore suja.
$Assistente = -not $Acao

function Write-L([string]$T) { [Console]::Out.WriteLine($T) }

function Get-KitVersao { ([System.IO.File]::ReadAllText((Join-Path $Kit 'VERSION'))).Trim() }

function Get-Sha([string]$Texto) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { $b = $sha.ComputeHash($Utf8.GetBytes(($Texto -replace "`r`n", "`n"))) } finally { $sha.Dispose() }
  return (-join ($b | ForEach-Object { $_.ToString('x2') }))
}

function Read-T([string]$P) { if (Test-Path -LiteralPath $P -PathType Leaf) { return [System.IO.File]::ReadAllText($P, [System.Text.Encoding]::UTF8) } return $null }

function Write-T([string]$P, [string]$T) {
  $d = Split-Path -Parent $P
  if ($d -and -not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  [System.IO.File]::WriteAllText($P, ($T -replace "`r`n", "`n"), $Utf8)
}

function Invoke-G([string]$Dir, [string[]]$A, [switch]$PermitirFalha) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $o = & git -C $Dir @A 2>&1; $c = $LASTEXITCODE } finally { $ErrorActionPreference = $old }
  $out = @($o | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
  if ($c -ne 0 -and -not $PermitirFalha) { throw ("git " + ($A -join ' ') + " falhou em $Dir") }
  return [pscustomobject]@{ Codigo = $c; Out = $out }
}

function Read-Resposta([string]$Pergunta, [string]$Padrao) {
  $txt = $Pergunta
  if ($Padrao) { $txt += " [$Padrao]" }
  $r = Read-Host $txt
  if ([string]::IsNullOrWhiteSpace($r)) { return $Padrao }
  return $r.Trim().Trim('"').Trim("'")
}

function Read-SimNao([string]$Pergunta, [bool]$Padrao) {
  $op = 's/N'
  if ($Padrao) { $op = 'S/n' }
  $r = Read-Host "$Pergunta [$op]"
  if ([string]::IsNullOrWhiteSpace($r)) { return $Padrao }
  return ($r.Trim() -match '^(s|sim|y|yes)$')
}

function Resolve-Destino {
  if (-not $Destino -and $Assistente) {
    # Padrao: a pasta atual, se o assistente foi chamado de dentro do projeto.
    $aqui = (Get-Location).Path
    if ([System.IO.Path]::GetFullPath($aqui).TrimEnd('\', '/') -eq [System.IO.Path]::GetFullPath($Kit).TrimEnd('\', '/')) { $aqui = '' }
    $script:Destino = Read-Resposta 'Pasta do projeto' $aqui
  }
  if (-not $Destino) { throw 'informe -Destino <pasta do repositorio>' }
  $full = [System.IO.Path]::GetFullPath($Destino)
  if (-not (Test-Path -LiteralPath $full -PathType Container)) { throw "pasta nao encontrada: $full" }
  $r = Invoke-G $full @('rev-parse', '--show-toplevel') -PermitirFalha
  if ($r.Codigo -ne 0) {
    if (-not ($Assistente -and (Read-SimNao "$full nao e um repositorio git. Rodar git init?" $true))) { throw "$full nao e um repositorio git (rode git init antes)" }
    Invoke-G $full @('init') | Out-Null
    $r = Invoke-G $full @('rev-parse', '--show-toplevel')
  }
  return [System.IO.Path]::GetFullPath(($r.Out | Select-Object -Last 1))
}

# Sugere o perfil pelos arquivos da raiz; Unity antes de .NET (gera .sln/.csproj).
function Get-PerfilSugerido([string]$Raiz) {
  $tem = { param($Rel) Test-Path -LiteralPath (Join-Path $Raiz $Rel) }
  $ext = @(Get-ChildItem -LiteralPath $Raiz -File -ErrorAction SilentlyContinue | ForEach-Object { $_.Extension.ToLowerInvariant() })
  if (& $tem 'pubspec.yaml') { return 'flutter' }
  if (& $tem 'Cargo.toml') { return 'rust' }
  if (& $tem 'ProjectSettings/ProjectVersion.txt') { return 'unity' }
  if ($ext -contains '.uproject') { return 'unreal' }
  if ($ext -contains '.sln' -or $ext -contains '.slnx' -or $ext -contains '.csproj' -or $ext -contains '.fsproj') { return 'dotnet' }
  foreach ($f in @('pyproject.toml', 'requirements.txt', 'setup.py')) { if (& $tem $f) { return 'python' } }
  if (& $tem 'package.json') { return 'node' }
  return ''
}

function Resolve-Perfil([string]$Raiz) {
  if ($Perfil -or -not $Assistente) { return }
  $nomes = @(Get-ChildItem -LiteralPath (Join-Path $Kit 'profiles') -Filter '*.json' | ForEach-Object { $_.BaseName } | Sort-Object)
  $sug = Get-PerfilSugerido $Raiz
  Write-L 'Perfis de stack:'
  for ($i = 0; $i -lt $nomes.Count; $i++) {
    $marca = ''
    if ($nomes[$i] -eq $sug) { $marca = '  <- detectado' }
    Write-L ("  {0}. {1}{2}" -f ($i + 1), $nomes[$i], $marca)
  }
  $r = Read-Resposta 'Perfil (numero ou nome)' $sug
  if ($r -match '^\d+$' -and [int]$r -ge 1 -and [int]$r -le $nomes.Count) { $r = $nomes[[int]$r - 1] }
  $script:Perfil = $r
}

function Assert-ArvoreLimpa([string]$Raiz, [bool]$PadraoAssistente = $true) {
  if ($SemArvoreLimpa) { return }
  $s = Invoke-G $Raiz @('status', '--porcelain')
  $sujos = @($s.Out | Where-Object { $_.Trim() -ne '' })
  if ($sujos.Count -eq 0) { return }
  if ($Assistente) {
    Write-L ("  ! a arvore git tem {0} arquivo(s) pendente(s): o diff do kit vai se misturar com eles." -f $sujos.Count)
    if (Read-SimNao '  Continuar mesmo assim?' $PadraoAssistente) { return }
    throw 'cancelado: faca commit ou stash e rode de novo'
  }
  throw 'a arvore git do projeto nao esta limpa: faca commit ou stash antes (o diff do kit precisa ficar revisavel; para testar, use -SemArvoreLimpa ou o assistente sem parametros)'
}

# Arquivos do nucleo (relativos), sem o bloco do AGENTS.
function Get-ArquivosNucleo {
  $lista = New-Object System.Collections.ArrayList
  foreach ($f in Get-ChildItem -LiteralPath $Kernel -Recurse -File -Force) {
    $rel = $f.FullName.Substring($Kernel.Length).TrimStart('\', '/').Replace('\', '/')
    if ($rel -eq 'AGENTS.kit.md') { continue }
    [void]$lista.Add($rel)
  }
  return @($lista | Sort-Object)
}

# Wrapper do Claude para cada skill canonica de .agents/skills.
function Get-Wrappers {
  $res = [ordered]@{}
  $dir = Join-Path $Kernel '.agents/skills'
  foreach ($d in Get-ChildItem -LiteralPath $dir -Directory) {
    $txt = Read-T (Join-Path $d.FullName 'SKILL.md')
    $nome = [regex]::Match($txt, '(?m)^name:\s*(.+?)\s*$').Groups[1].Value.Trim('"', "'")
    $desc = [regex]::Match($txt, '(?m)^description:\s*(.+?)\s*$').Groups[1].Value
    if (-not $nome -or -not $desc) { throw "skill sem name/description: $($d.Name)" }
    if ($nome -cne $d.Name -or $nome -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "nome de skill fora do padrao Agent Skills (kebab-case igual a pasta): $($d.Name)" }
    $corpo = @(
      '---',
      "name: $nome",
      "description: $desc",
      '---',
      '',
      "Leia e siga integralmente ``.agents/skills/$nome/SKILL.md`` com `$ARGUMENTS.",
      'Wrapper gerado pelo sdd-kit: a skill canonica e a fonte; nao edite aqui.',
      ''
    ) -join "`n"
    $res[".claude/skills/$nome/SKILL.md"] = $corpo
  }
  return $res
}

# Conteudo desejado de cada arquivo gerenciado: { rel -> texto }.
function Get-ConteudoGerenciado {
  $m = [ordered]@{}
  foreach ($rel in Get-ArquivosNucleo) { $m[$rel] = Read-T (Join-Path $Kernel $rel) }
  $w = Get-Wrappers
  foreach ($k in $w.Keys) { $m[$k] = $w[$k] }
  return $m
}

function Get-BlocoAgents { return (Read-T (Join-Path $Kernel 'AGENTS.kit.md')).Trim() }

# Moldes do nucleo vivem em Docs/Specs/ no kit; no projeto vao para projeto.specs_root.
function Convert-RelSpecs([string]$Rel, [string]$Specs) {
  if ($Rel.StartsWith('Docs/Specs/') -and $Specs -cne 'Docs/Specs') { return $Specs + $Rel.Substring('Docs/Specs'.Length) }
  return $Rel
}

function Set-BlocoAgents([string]$Texto, [string]$Bloco) {
  $t = $Texto -replace "`r`n", "`n"
  $ini = ([regex]::Matches($t, [regex]::Escape($MarcaIni))).Count
  $fim = ([regex]::Matches($t, [regex]::Escape($MarcaFim))).Count
  $novo = $MarcaIni + "`n" + $Bloco + "`n" + $MarcaFim
  if ($ini -eq 0 -and $fim -eq 0) {
    # Bloco no topo, logo depois do primeiro titulo (se houver).
    $m = [regex]::Match($t, '^(#[^\n]*\n)')
    if ($m.Success) { return $m.Groups[1].Value + "`n" + $novo + "`n" + $t.Substring($m.Length) }
    return $novo + "`n`n" + $t
  }
  if ($ini -ne 1 -or $fim -ne 1) { throw 'AGENTS.md com marcadores do sdd-kit duplicados ou incompletos: corrija a mao' }
  $a = $t.IndexOf($MarcaIni); $b = $t.IndexOf($MarcaFim)
  if ($b -lt $a) { throw 'AGENTS.md com marcadores do sdd-kit fora de ordem' }
  return $t.Substring(0, $a) + $novo + $t.Substring($b + $MarcaFim.Length)
}

function Get-BlocoAtual([string]$Texto) {
  if ($null -eq $Texto) { return $null }
  $t = $Texto -replace "`r`n", "`n"
  $a = $t.IndexOf($MarcaIni); $b = $t.IndexOf($MarcaFim)
  if ($a -lt 0 -or $b -lt $a) { return $null }
  return $t.Substring($a + $MarcaIni.Length, $b - $a - $MarcaIni.Length).Trim()
}

function Test-Executavel([string]$Rel) { return ($Rel -match '\.(ps1|sh|json)$' -or $Rel -like '.claude/agents/*') }

function Add-Gitignore([string]$Raiz, [string[]]$Linhas) {
  $p = Join-Path $Raiz '.gitignore'
  $atual = Read-T $p
  if ($null -eq $atual) { $atual = '' }
  $existentes = @($atual -split "`r?`n" | ForEach-Object { $_.Trim() })
  $faltam = @($Linhas | Where-Object { $_ -and $existentes -notcontains $_ })
  if ($faltam.Count -eq 0) { return 0 }
  $sep = ''
  if ($atual -and -not $atual.EndsWith("`n")) { $sep = "`n" }
  Write-T $p ($atual + $sep + "# sdd-kit`n" + ($faltam -join "`n") + "`n")
  return $faltam.Count
}

function Get-ProjetoAtivo([string]$Raiz) {
  $perfilTxt = Read-T (Join-Path $Raiz '.sdd/profile.json')
  $specs = 'Docs/Specs'
  if ($perfilTxt) { try { $pp = $perfilTxt | ConvertFrom-Json; if ($pp.projeto.specs_root) { $specs = [string]$pp.projeto.specs_root } } catch { } }
  $dir = Join-Path $Raiz "$specs/changes"
  $ativas = @()
  if (Test-Path -LiteralPath $dir) {
    foreach ($f in Get-ChildItem -LiteralPath $dir -Recurse -Filter 'change.md' -File) {
      if ((Read-T $f.FullName) -match '(?m)^status:\s*In-Implementation') { $ativas += $f.Directory.Name }
    }
  }
  return $ativas
}

function Write-Lock([string]$Raiz, [hashtable]$Hashes, [string]$HashBloco, [string]$PerfilOrigem) {
  $commit = ''
  $r = Invoke-G $Kit @('rev-parse', 'HEAD') -PermitirFalha
  if ($r.Codigo -eq 0) { $commit = ($r.Out | Select-Object -Last 1) }
  $ord = [ordered]@{}
  foreach ($k in ($Hashes.Keys | Sort-Object)) { $ord[$k] = $Hashes[$k] }
  $lock = [ordered]@{
    kit_versao = (Get-KitVersao); fonte = $Kit; fonte_commit = $commit; perfil_origem = $PerfilOrigem
    gravado_em = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'); bloco_agents = $HashBloco; arquivos = $ord
  }
  Write-T (Join-Path $Raiz '.sdd/kit.lock.json') ($lock | ConvertTo-Json -Depth 5)
}

# ---------------------------------------------------------------------
function Invoke-Projeto {
  $raiz = Resolve-Destino
  Resolve-Perfil $raiz
  if (-not $Perfil) { throw 'informe -Perfil (veja a pasta profiles/)' }
  $arqPerfil = Join-Path $Kit "profiles/$Perfil.json"
  if (-not (Test-Path -LiteralPath $arqPerfil)) { throw "perfil desconhecido: $Perfil" }
  if (Test-Path -LiteralPath (Join-Path $raiz '.sdd/kit.lock.json')) { throw 'kit ja instalado neste projeto: use update' }
  Assert-ArvoreLimpa $raiz
  # Perfil e raiz de specs resolvidos ANTES de gravar: os moldes vao direto
  # para a raiz configurada (nada de copiar e mover, que no NTFS sem caixa apagaria).
  $perfilDest = Join-Path $raiz '.sdd/profile.json'
  $perfilTxt = Read-T $perfilDest
  if ($null -eq $perfilTxt) { $perfilTxt = Read-T $arqPerfil }
  $p = $perfilTxt | ConvertFrom-Json
  $specs = 'Docs/Specs'
  if ($p.projeto.specs_root) { $specs = ([string]$p.projeto.specs_root).Trim('/') }
  $desejado = [ordered]@{}
  $base0 = Get-ConteudoGerenciado
  foreach ($k in $base0.Keys) { $desejado[(Convert-RelSpecs $k $specs)] = $base0[$k] }
  # AGENTS.md calculado antes de gravar: marcador quebrado aborta sem gravacao parcial.
  $bloco = Get-BlocoAgents
  $agents = Join-Path $raiz 'AGENTS.md'
  $baseAgents = Read-T $agents
  if ($null -eq $baseAgents) { $baseAgents = Read-T (Join-Path $Kit 'project-templates/AGENTS.md') }
  $agentsNovo = Set-BlocoAgents $baseAgents $bloco
  # Plano: conflito = arquivo existente com conteudo diferente. Nada e gravado se houver conflito.
  $conflitos = @()
  foreach ($rel in $desejado.Keys) {
    $atual = Read-T (Join-Path $raiz $rel)
    if ($null -ne $atual -and (Get-Sha $atual) -ne (Get-Sha $desejado[$rel])) { $conflitos += $rel }
  }
  foreach ($proibido in @('CLAUDE.md', 'CLAUDE.local.md', 'GEMINI.md')) {
    if (Test-Path -LiteralPath (Join-Path $raiz $proibido)) { Write-L "  ! $proibido na raiz: o kit usa entrada unica (.claude/CLAUDE.md + AGENTS.md); avalie remover." }
  }
  if ($conflitos.Count) {
    Write-L 'CONFLITO: estes arquivos ja existem com outro conteudo (nada foi gravado):'
    foreach ($c in $conflitos) { Write-L "  - $c" }
    return 1
  }
  $hashes = @{}
  foreach ($rel in $desejado.Keys) { Write-T (Join-Path $raiz $rel) $desejado[$rel]; $hashes[$rel] = Get-Sha $desejado[$rel] }
  if (-not (Test-Path -LiteralPath $perfilDest)) { Write-T $perfilDest $perfilTxt }
  Write-T $agents $agentsNovo
  $claude = Join-Path $raiz '.claude/CLAUDE.md'
  $ct = Read-T $claude
  if ($null -eq $ct) { Write-T $claude (Read-T (Join-Path $Kit 'project-templates/CLAUDE.md')) }
  else {
    $faltam = @('@../AGENTS.md', '@../.agents/rules/sdd-core.md') | Where-Object { $ct -notmatch [regex]::Escape($_) }
    if ($faltam) { Write-T $claude ($ct.TrimEnd() + "`n`n" + (($faltam) -join "`n") + "`n"); Write-L '  .claude/CLAUDE.md existente: imports do kit acrescentados no fim.' }
  }
  $indice = Join-Path $raiz "$specs/capabilities/_index.md"
  if (-not (Test-Path -LiteralPath $indice)) { Write-T $indice (Read-T (Join-Path $Kit 'project-templates/_index.md')) }
  foreach ($pasta in @('backlog', 'changes', 'concluidas')) {
    $d = Join-Path $raiz "$specs/$pasta"
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null; Write-T (Join-Path $d '.gitkeep') '' }
  }
  $n = Add-Gitignore $raiz (@('.sdd/state/', '.sdd/profile.local.json') + @($p.paths.gerados))
  Write-Lock $raiz $hashes (Get-Sha $bloco) $Perfil
  Write-L ("INSTALADO sdd-kit {0} em {1} (perfil {2}; {3} arquivos gerenciados; {4} linhas no .gitignore)." -f (Get-KitVersao), $raiz, $Perfil, $hashes.Count, $n)
  Write-L 'Proximos passos (no projeto):'
  Write-L '  1. Abra o projeto na IDE e peca a IA: "rode a skill sdd-bootstrap" (descobre, pergunta, preenche o AGENTS.md, calibra o perfil e instala o pre-commit).'
  Write-L '  2. Revise o diff e faca o commit do bootstrap.'
  return 0
}

function Invoke-Check {
  $raiz = Resolve-Destino
  $lockTxt = Read-T (Join-Path $raiz '.sdd/kit.lock.json')
  if ($null -eq $lockTxt) { Write-L 'sdd-kit nao instalado (sem .sdd/kit.lock.json).'; return 1 }
  $lock = $lockTxt | ConvertFrom-Json
  $fail = 0; $warn = 0
  foreach ($pp in $lock.arquivos.PSObject.Properties) {
    $atual = Read-T (Join-Path $raiz $pp.Name)
    if ($null -eq $atual) { Write-L "  FAIL ausente: $($pp.Name)"; $fail++; continue }
    if ((Get-Sha $atual) -ne [string]$pp.Value) {
      if (Test-Executavel $pp.Name) { Write-L "  FAIL editado no projeto (executavel/config do kit): $($pp.Name)"; $fail++ }
      else { Write-L "  WARN editado no projeto: $($pp.Name) (licao de metodo vai para o INBOX do kit)"; $warn++ }
    }
  }
  $bloco = Get-BlocoAtual (Read-T (Join-Path $raiz 'AGENTS.md'))
  if ($null -eq $bloco) { Write-L '  FAIL AGENTS.md sem o bloco do sdd-kit'; $fail++ }
  elseif ((Get-Sha $bloco) -ne [string]$lock.bloco_agents) { Write-L '  WARN bloco do sdd-kit no AGENTS.md editado'; $warn++ }
  $versaoKit = Get-KitVersao
  if ([string]$lock.kit_versao -ne $versaoKit) { Write-L ("  INFO projeto em {0}; este kit esta em {1} (update disponivel)" -f $lock.kit_versao, $versaoKit) }
  $st = 'PASS'
  if ($fail) { $st = 'FAIL' } elseif ($warn) { $st = 'WARN' }
  Write-L "KIT CHECK $st ($fail falha(s), $warn aviso(s))"
  if ($fail) { return 1 }
  return 0
}

function Invoke-Update {
  $raiz = Resolve-Destino
  $lockTxt = Read-T (Join-Path $raiz '.sdd/kit.lock.json')
  if ($null -eq $lockTxt) { throw 'kit nao instalado: use projeto' }
  Assert-ArvoreLimpa $raiz $false
  $ativas = @(Get-ProjetoAtivo $raiz)
  if ($ativas.Count -and -not $Forcar) { throw ("ha change em implementacao (" + ($ativas -join ', ') + "): atualize depois do fecho ou use -Forcar") }
  $lock = $lockTxt | ConvertFrom-Json
  $antigos = @{}
  foreach ($pp in $lock.arquivos.PSObject.Properties) { $antigos[$pp.Name] = [string]$pp.Value }
  $desejado = Get-ConteudoGerenciado
  $p = (Read-T (Join-Path $raiz '.sdd/profile.json')) | ConvertFrom-Json
  $specs = 'Docs/Specs'
  if ($p.projeto.specs_root) { $specs = ([string]$p.projeto.specs_root).Trim('/') }
  $mapa = [ordered]@{}
  foreach ($k in $desejado.Keys) { $mapa[(Convert-RelSpecs $k $specs)] = $desejado[$k] }
  # Plano completo antes de gravar.
  $gravar = @(); $kitnew = @(); $bloqueios = @(); $remover = @()
  foreach ($rel in $mapa.Keys) {
    $atual = Read-T (Join-Path $raiz $rel)
    $novoSha = Get-Sha $mapa[$rel]
    if ($null -eq $atual) { $gravar += $rel; continue }
    $atualSha = Get-Sha $atual
    if ($atualSha -eq $novoSha) { continue }
    $editado = (-not $antigos.ContainsKey($rel)) -or ($atualSha -ne $antigos[$rel])
    if (-not $editado) { $gravar += $rel }
    elseif (Test-Executavel $rel) { $bloqueios += $rel }
    else { $kitnew += $rel }
  }
  foreach ($rel in $antigos.Keys) {
    if (-not $mapa.Contains($rel)) {
      $atual = Read-T (Join-Path $raiz $rel)
      if ($null -ne $atual -and (Get-Sha $atual) -eq $antigos[$rel]) { $remover += $rel }
      elseif ($null -ne $atual) { Write-L "  ! $rel saiu do kit mas foi editado no projeto: mantido" }
    }
  }
  if ($bloqueios.Count) {
    Write-L 'UPDATE RECUSADO: arquivos executaveis/config do kit editados no projeto (nada foi gravado):'
    foreach ($b in $bloqueios) { Write-L "  - $b" }
    Write-L 'Resolva a mao (devolva ao original ou leve a mudanca para o kit) e rode de novo.'
    return 1
  }
  $agentsP = Join-Path $raiz 'AGENTS.md'
  $agentsNovo = Set-BlocoAgents (Read-T $agentsP) (Get-BlocoAgents)
  $hashes = @{}
  foreach ($rel in $mapa.Keys) { $hashes[$rel] = Get-Sha $mapa[$rel] }
  foreach ($rel in $gravar) { Write-T (Join-Path $raiz $rel) $mapa[$rel]; Write-L "  atualizado: $rel" }
  foreach ($rel in $kitnew) {
    Write-T (Join-Path $raiz ($rel + '.kitnew')) $mapa[$rel]
    $hashes[$rel] = $antigos[$rel]
    Write-L "  editado no projeto, mantido; versao nova em $rel.kitnew"
  }
  foreach ($rel in $remover) { Remove-Item -LiteralPath (Join-Path $raiz $rel); Write-L "  removido (saiu do kit): $rel" }
  Write-T $agentsP $agentsNovo
  Write-Lock $raiz $hashes (Get-Sha (Get-BlocoAgents)) ([string]$lock.perfil_origem)
  Write-L ("UPDATE {0} -> {1}: {2} gravado(s), {3} .kitnew, {4} removido(s). Revise o diff e rode 'sdd check'." -f $lock.kit_versao, (Get-KitVersao), $gravar.Count, $kitnew.Count, $remover.Count)
  return 0
}

# ---------------------------------------------------------------------
function Get-Casa { if ($Casa) { return [System.IO.Path]::GetFullPath($Casa) } return [Environment]::GetFolderPath('UserProfile') }

function Get-FragmentoClaude([string]$Hooks) {
  $ps = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
  $segredos = @('.env', '.env.local', '.env.*.local', '.env.production*', '.env.staging*', '.env.development*', '.env.test*', '*.pfx', '*.p12', '*.key', '*.pem', '*.jks', '*.keystore', '*.snk', '*.p8', '*.mobileprovision', 'id_rsa*', 'id_ed25519*', '.npmrc', '.pypirc', '.netrc')
  $deny = @()
  foreach ($s in $segredos) { $deny += "Read(//**/$s)"; $deny += "Edit(//**/$s)" }
  $ask = @('Bash(git push *)', 'Bash(git commit *)', 'PowerShell(git push *)', 'PowerShell(git commit *)')
  $guard = [ordered]@{ type = 'command'; command = $ps; args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Hooks 'guard.ps1'), '-Platform', 'Claude'); timeout = 15; onFailure = 'block' }
  $edit = [ordered]@{ type = 'command'; command = $ps; args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Hooks 'edit_guard.ps1'), '-Platform', 'Claude'); timeout = 15; onFailure = 'block' }
  return [ordered]@{
    permissions = [ordered]@{ deny = $deny; ask = $ask }
    hooks = [ordered]@{ PreToolUse = @([ordered]@{ matcher = 'Bash|PowerShell'; hooks = @($guard) }, [ordered]@{ matcher = 'Write|Edit|NotebookEdit'; hooks = @($edit) }) }
  }
}

function Get-FragmentoAntigravity([string]$Hooks) {
  $ps = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
  $g = "$ps -NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $Hooks 'guard.ps1')`" -Platform Antigravity"
  $e = "$ps -NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $Hooks 'edit_guard.ps1')`" -Platform Antigravity"
  return [ordered]@{
    'sdd-kit-guard' = [ordered]@{ enabled = $true; PreToolUse = @([ordered]@{ matcher = 'run_command'; hooks = @([ordered]@{ type = 'command'; command = $g; timeout = 15 }) }) }
    'sdd-kit-edit-guard' = [ordered]@{ enabled = $true; PreToolUse = @([ordered]@{ matcher = 'write_to_file|replace_file_content|multi_replace_file_content'; hooks = @([ordered]@{ type = 'command'; command = $e; timeout = 15 }) }) }
  }
}

function Test-EhNosso($Entrada) {
  return (($Entrada | ConvertTo-Json -Depth 10 -Compress) -match 'sdd-kit[\\/]+hooks')
}

function Merge-ClaudeSettings([string]$Arq, $Frag) {
  $obj = $null
  $txt = Read-T $Arq
  if ($txt) { try { $obj = $txt | ConvertFrom-Json } catch { throw "$Arq nao e JSON valido: corrija antes (nada foi gravado)" } }
  if ($null -eq $obj) { $obj = New-Object PSObject }
  if (-not $obj.PSObject.Properties['permissions']) { $obj | Add-Member -NotePropertyName permissions -NotePropertyValue (New-Object PSObject) }
  foreach ($tipo in @('deny', 'ask')) {
    $atual = @()
    if ($obj.permissions.PSObject.Properties[$tipo]) { $atual = @($obj.permissions.$tipo) }
    $novo = @($atual + @($Frag.permissions[$tipo] | Where-Object { $atual -notcontains $_ }))
    if ($obj.permissions.PSObject.Properties[$tipo]) { $obj.permissions.$tipo = $novo } else { $obj.permissions | Add-Member -NotePropertyName $tipo -NotePropertyValue $novo }
  }
  if (-not $obj.PSObject.Properties['hooks']) { $obj | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object PSObject) }
  $pre = @()
  if ($obj.hooks.PSObject.Properties['PreToolUse']) { $pre = @($obj.hooks.PreToolUse | Where-Object { -not (Test-EhNosso $_) }) }
  $pre = @($pre + @($Frag.hooks.PreToolUse))
  if ($obj.hooks.PSObject.Properties['PreToolUse']) { $obj.hooks.PreToolUse = $pre } else { $obj.hooks | Add-Member -NotePropertyName PreToolUse -NotePropertyValue $pre }
  return ($obj | ConvertTo-Json -Depth 32)
}

function Merge-AntigravityHooks([string]$Arq, $Frag) {
  $obj = $null
  $txt = Read-T $Arq
  if ($txt) { try { $obj = $txt | ConvertFrom-Json } catch { throw "$Arq nao e JSON valido: corrija antes (nada foi gravado)" } }
  if ($null -eq $obj) { $obj = New-Object PSObject }
  foreach ($k in $Frag.Keys) {
    if ($obj.PSObject.Properties[$k]) { $obj.$k = $Frag[$k] } else { $obj | Add-Member -NotePropertyName $k -NotePropertyValue $Frag[$k] }
  }
  return ($obj | ConvertTo-Json -Depth 32)
}

function Invoke-Maquina {
  $casa = Get-Casa
  $base = Join-Path $casa '.sdd-kit'
  $hooks = Join-Path $base 'hooks'
  foreach ($f in @('guard.ps1', 'edit_guard.ps1')) { Write-T (Join-Path $hooks $f) (Read-T (Join-Path $Kit "machine/$f")) }
  $fc = Get-FragmentoClaude $hooks
  $fa = Get-FragmentoAntigravity $hooks
  $frag = Join-Path $base 'fragmentos'
  Write-T (Join-Path $frag 'claude-settings.json') ($fc | ConvertTo-Json -Depth 32)
  Write-T (Join-Path $frag 'antigravity-hooks.json') ($fa | ConvertTo-Json -Depth 32)
  Write-L "Hooks copiados para $hooks; fragmentos em $frag."
  if (-not $Aplicar) {
    Write-L 'Para aplicar (com backup): install.ps1 maquina -Aplicar'
    Write-L '  Claude: mescla permissions (deny/ask) e hooks PreToolUse em ~/.claude/settings.json (exige Claude Code >= 2.1.295 por causa do onFailure).'
    Write-L '  Antigravity: acrescenta 2 hooks em ~/.gemini/config/hooks.json.'
    return 0
  }
  $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
  $cs = Join-Path $casa '.claude/settings.json'
  $novoC = Merge-ClaudeSettings $cs $fc
  $ah = Join-Path $casa '.gemini/config/hooks.json'
  $novoA = Merge-AntigravityHooks $ah $fa
  foreach ($par in @(@($cs, $novoC), @($ah, $novoA))) {
    if (Test-Path -LiteralPath $par[0]) { Copy-Item -LiteralPath $par[0] -Destination ($par[0] + ".bak-$ts") }
    Write-T $par[0] $par[1]
    Write-L "  aplicado: $($par[0])"
  }
  Write-L 'Teste de canario (nas duas IDEs): peca a IA para rodar "git push --force" num repositorio de teste; a IDE tem de pedir confirmacao.'
  return 0
}

# Assistente: guard da maquina (se faltar) e depois instala ou atualiza o projeto.
function Invoke-Assistente {
  Write-L ("SpecSimpleKit {0} - assistente de instalacao (Enter aceita o padrao entre colchetes)" -f (Get-KitVersao))
  if (-not (Test-Path -LiteralPath (Join-Path (Get-Casa) '.sdd-kit/hooks/guard.ps1'))) {
    Write-L 'O guard da maquina (uma vez por maquina) ainda nao esta instalado: ele faz a IDE pedir confirmacao'
    Write-L 'antes de comandos perigosos e mescla permissoes em ~/.claude/settings.json (com backup).'
    if (Read-SimNao 'Instalar o guard da maquina agora?' $false) {
      $script:Aplicar = $true
      if ((Invoke-Maquina) -ne 0) { return 1 }
      Write-L ''
    }
  }
  $raiz = Resolve-Destino
  if (Test-Path -LiteralPath (Join-Path $raiz '.sdd/kit.lock.json')) {
    Write-L "O kit ja esta instalado em $raiz."
    if (-not (Read-SimNao 'Atualizar para a versao deste clone?' $true)) { return 0 }
    return (Invoke-Update)
  }
  return (Invoke-Projeto)
}

function Remove-BlocoAgents([string]$Texto) {
  $t = $Texto -replace "`r`n", "`n"
  $a = $t.IndexOf($MarcaIni); $b = $t.IndexOf($MarcaFim)
  if ($a -ge 0 -and $b -ge $a) {
    $antes = $t.Substring(0, $a).TrimEnd("`n")
    $depois = $t.Substring($b + $MarcaFim.Length).TrimStart("`n")
    if ($antes -and $depois) { return $antes + "`n`n" + $depois }
    if ($antes) { return $antes + "`n" }
    return $depois
  }
  return $t
}

function Invoke-Detectar {
  $dir = if ($Destino) { [System.IO.Path]::GetFullPath($Destino) } else { (Get-Location).Path }
  $temKit = (Test-Path -LiteralPath (Join-Path $dir 'SpecSimpleKit')) -or (Test-Path -LiteralPath (Join-Path $dir '.sdd/kit.lock.json')) -or (Test-Path -LiteralPath (Join-Path $dir '.sdd/profile.json'))
  $isGit = $false
  try {
    $r = Invoke-G $dir @('rev-parse', '--is-inside-work-tree') -PermitirFalha
    if ($r.Codigo -eq 0 -and ($r.Out -join '').Trim() -eq 'true') { $isGit = $true }
  } catch { }

  $sug = Get-PerfilSugerido $dir
  $modo = if (Test-Path -LiteralPath (Join-Path $dir 'SpecSimpleKit')) { 'pasta' } elseif ($temKit) { 'legado' } else { $null }
  $v = Get-KitVersao

  $obj = [ordered]@{
    kit_instalado = [bool]$temKit
    git = [bool]$isGit
    perfil_sugerido = if ($sug) { $sug } else { $null }
  }
  if ($temKit) {
    if ($modo) { $obj['modo'] = $modo }
    $pAtual = $sug
    if (Test-Path -LiteralPath (Join-Path $dir '.sdd/profile.json')) {
      try {
        $pj = (Read-T (Join-Path $dir '.sdd/profile.json')) | ConvertFrom-Json
        if ($pj.perfil -is [string]) { $pAtual = [string]$pj.perfil }
        elseif ($pj.perfil.nome) { $pAtual = [string]$pj.perfil.nome }
      } catch { }
    }
    if ($pAtual) { $obj['perfil'] = $pAtual }
    $obj['kit_versao'] = $v
  }
  $json = $obj | ConvertTo-Json -Compress
  Write-L $json
  return 0
}

function Invoke-ModoPasta {
  $dir = if ($Destino) { [System.IO.Path]::GetFullPath($Destino) } else { (Get-Location).Path }
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { throw "pasta nao encontrada: $dir" }
  $pNome = if ($Perfil) { $Perfil } else { Get-PerfilSugerido $dir }
  if (-not $pNome) { $pNome = 'node' }

  $profOrigem = Join-Path $Kit "profiles/$pNome.json"
  $sddDir = Join-Path $dir '.sdd'
  if (-not (Test-Path -LiteralPath $sddDir)) { New-Item -ItemType Directory -Path $sddDir -Force | Out-Null }

  if (Test-Path -LiteralPath $profOrigem) {
    $profJson = Read-T $profOrigem
    Write-T (Join-Path $sddDir 'profile.json') $profJson
  } else {
    $profJson = @{
      perfil = @{ nome = $pNome; versao = (Get-KitVersao) }
      projeto = @{ specs_root = 'Specs' }
    } | ConvertTo-Json -Depth 5
    Write-T (Join-Path $sddDir 'profile.json') $profJson
  }

  $agentsPath = Join-Path $dir 'AGENTS.md'
  $agentsAtual = Read-T $agentsPath
  if ($null -eq $agentsAtual) {
    $agentsAtual = "# AGENTS.md`n"
  }

  $blocoModoPasta = @(
    '## Metodologia (sdd-kit: modo-pasta)',
    '',
    '- **Nucleo sempre ativo:** `SpecSimpleKit/kernel/.agents/rules/sdd-core.md`.',
    '- **Fluxo spec-driven:** `SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md`, lido antes de trabalho nao trivial.',
    '- **Revisao:** `SpecSimpleKit/kernel/.agents/rules/sdd-revisao.md`.',
    '- **Skills:** `SpecSimpleKit/kernel/.agents/skills/`.',
    '- **Motor:** `powershell -File SpecSimpleKit/kernel/tools/sdd/sdd.ps1 <check|validate|test|goal|status|ajuda>`.',
    '- **Perfil:** `.sdd/profile.json`.',
    '- **Remocao:** para desinstalar o kit mantendo suas specs intactas, rode:',
    '  `powershell -File SpecSimpleKit/install.ps1 remover -Destino . -ModoPasta`'
  ) -join "`n"

  $novoAgents = Set-BlocoAgents $agentsAtual $blocoModoPasta
  Write-T $agentsPath $novoAgents

  Write-L "Modo pasta configurado em $dir (perfil $pNome)."
  return 0
}

function Invoke-Remover {
  $dir = if ($Destino) { [System.IO.Path]::GetFullPath($Destino) } else { (Get-Location).Path }
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { throw "pasta nao encontrada: $dir" }

  $agentsPath = Join-Path $dir 'AGENTS.md'
  if (Test-Path -LiteralPath $agentsPath) {
    $txt = Read-T $agentsPath
    $novoTxt = Remove-BlocoAgents $txt
    Write-T $agentsPath $novoTxt
    Write-L "Bloco do sdd-kit removido de $agentsPath."
  }

  $sddDir = Join-Path $dir '.sdd'
  if (Test-Path -LiteralPath $sddDir) {
    Remove-Item -LiteralPath $sddDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-L "Pasta .sdd removida."
  }

  $kitPasta = Join-Path $dir 'SpecSimpleKit'
  if (Test-Path -LiteralPath $kitPasta) {
    try {
      Remove-Item -LiteralPath $kitPasta -Recurse -Force -ErrorAction Stop
    } catch {
      cmd /c "rmdir /s /q `"$kitPasta`"" 2>$null
    }
    Write-L "Pasta SpecSimpleKit removida."
  }

  Write-L "Remocao concluida com sucesso. Suas specs permanecem preservadas."
  return 0
}

try {
  if ($Assistente) { exit (Invoke-Assistente) }
  switch ($Acao) {
    'projeto' { $c = Invoke-Projeto }
    'check' { $c = Invoke-Check }
    'update' { $c = Invoke-Update }
    'maquina' { $c = Invoke-Maquina }
    'detectar' { $c = Invoke-Detectar }
    'modo-pasta' { $c = Invoke-ModoPasta }
    'remover' { $c = Invoke-Remover }
  }
  exit $c
} catch {
  Write-L ('ERRO: ' + $_.Exception.Message)
  exit 2
}
