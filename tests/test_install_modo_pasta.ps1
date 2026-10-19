# Teste do Modo Pasta Autocontido e Zero Residuo (CHG-001, SPEC-INST-001..003). ASCII.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')

$kit = Get-SddKitPath
$install = Join-Path $kit 'install.ps1'

# Teste 1: install.ps1 detectar em repositorio sem kit
$dir = New-SddTesteRepo -Nome 'detectar_sem_kit'
try {
  Write-Arq $dir 'package.json' '{"name":"cobaia"}'
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $install detectar -Destino $dir 2>&1
  Assert-Igual '[SPEC-INST-001/C1] detectar sai com exit 0' $LASTEXITCODE 0
  $json = $out | ConvertFrom-Json
  Assert-Igual '[SPEC-INST-001/C1] kit_instalado e false' $json.kit_instalado $false
  Assert-Igual '[SPEC-INST-001/C1] git e true' $json.git $true
  Assert-Igual '[SPEC-INST-001/C1] perfil sugerido e node' $json.perfil_sugerido 'node'
} finally {
  Remove-SddTesteRepo $dir
}

# Teste 2: Modo Pasta Autocontido (Zero Residuo)
$dir2 = New-SddTesteRepo -Nome 'modo_pasta'
try {
  # Simula copia do SpecSimpleKit para dentro do projeto
  $destKit = Join-Path $dir2 'SpecSimpleKit'
  Copy-Item -LiteralPath $kit -Destination $destKit -Recurse -Force

  # Confere se tests/ nao esta dentro do produto
  Assert-Igual '[SPEC-INST-002/C2] tests nao existe dentro de SpecSimpleKit distribuido' (Test-Path -LiteralPath (Join-Path $destKit 'tests')) $false

  # Ativa modo pasta no projeto
  $out2 = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $destKit 'install.ps1') modo-pasta -Destino $dir2 -Perfil node 2>&1
  Assert-Igual '[SPEC-INST-002/C1] modo-pasta sai com exit 0' $LASTEXITCODE 0

  # Valida que AGENTS.md foi criado e nenhuma regra foi copiada para a raiz
  $agents = [IO.File]::ReadAllText((Join-Path $dir2 'AGENTS.md'))
  Assert-Contem '[SPEC-INST-002/C1] AGENTS.md referencia SpecSimpleKit' $agents 'SpecSimpleKit'
  Assert-Igual '[SPEC-INST-002/C1] .agents/rules nao existe na raiz' (Test-Path -LiteralPath (Join-Path $dir2 '.agents/rules')) $false
  Assert-Igual '[SPEC-INST-002/C1] tools/sdd nao existe na raiz' (Test-Path -LiteralPath (Join-Path $dir2 'tools/sdd')) $false

  # Cria uma spec de teste em Specs/
  Write-Arq $dir2 'Specs/capabilities/teste/spec.md' '# Spec Viva de Teste'

  # Teste 2.1: detectar em projeto com kit em modo pasta
  $outDet = & powershell -NoProfile -ExecutionPolicy Bypass -File $install detectar -Destino $dir2 2>&1
  Assert-Igual '[SPEC-INST-001/C2] detectar sai com exit 0' $LASTEXITCODE 0
  $jsonDet = $outDet | ConvertFrom-Json
  Assert-Igual '[SPEC-INST-001/C2] kit_instalado e true' $jsonDet.kit_instalado $true
  Assert-Igual '[SPEC-INST-001/C2] modo e pasta' $jsonDet.modo 'pasta'
  Assert-Igual '[SPEC-INST-001/C2] perfil e node' $jsonDet.perfil 'node'

  # Teste 3: Remocao limpa pelo chat
  $out3 = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $destKit 'install.ps1') remover -Destino $dir2 -ModoPasta 2>&1
  Assert-Igual '[SPEC-INST-003/C1] remocao sai com exit 0' $LASTEXITCODE 0

  $agentsApos = [IO.File]::ReadAllText((Join-Path $dir2 'AGENTS.md'))
  Assert-Igual '[SPEC-INST-003/C1] bloco sdd-kit removido do AGENTS.md' ($agentsApos -match 'sdd-kit:begin') $false
  Assert-Igual '[SPEC-INST-003/C1] pasta SpecSimpleKit deletada' (Test-Path -LiteralPath $destKit) $false
  Assert-Igual '[SPEC-INST-003/C2] pasta Specs preservada intacta' (Test-Path -LiteralPath (Join-Path $dir2 'Specs/capabilities/teste/spec.md')) $true
} finally {
  Remove-SddTesteRepo $dir2
}

# Teste 4: pasta sem git
$dirSemGit = Join-Path ([System.IO.Path]::GetTempPath()) ("sdd_sem_git_" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dirSemGit -Force | Out-Null
try {
  $outSemGit = & powershell -NoProfile -ExecutionPolicy Bypass -File $install detectar -Destino $dirSemGit 2>&1
  Assert-Igual '[SPEC-INST-001/C3] detectar sai com exit 0' $LASTEXITCODE 0
  $jsonSemGit = $outSemGit | ConvertFrom-Json
  Assert-Igual '[SPEC-INST-001/C3] git e false' $jsonSemGit.git $false
} finally {
  Remove-Item -LiteralPath $dirSemGit -Recurse -Force -ErrorAction SilentlyContinue
}

Exit-SddTeste
