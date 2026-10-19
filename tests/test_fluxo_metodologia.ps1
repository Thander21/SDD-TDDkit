# Teste da capacidade fluxo: metodologia documentada, 4 artefatos e fluxo conversacional (CHG-003, SPEC-FLUXO-002). ASCII.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'helpers.ps1')

$kit = Get-SddKitPath
$workspace = Split-Path -Parent $kit
$guiaPath = Join-Path $kit 'docs/como-usar-fluxo.md'
$readmePath = Join-Path $workspace 'README.md'
$indexPath = Join-Path $workspace 'docs/Specs/capabilities/_index.md'
$specFluxoPath = Join-Path $workspace 'docs/Specs/capabilities/fluxo/spec.md'

$guia = if (Test-Path $guiaPath) { [IO.File]::ReadAllText($guiaPath, [System.Text.Encoding]::UTF8) } else { '' }
$readme = if (Test-Path $readmePath) { [IO.File]::ReadAllText($readmePath, [System.Text.Encoding]::UTF8) } else { '' }
$index = if (Test-Path $indexPath) { [IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8) } else { '' }
$specFluxo = if (Test-Path $specFluxoPath) { [IO.File]::ReadAllText($specFluxoPath, [System.Text.Encoding]::UTF8) } else { '' }

# C1: Os 4 artefatos, XP e loop autonomo no guia
Assert-Contem '[SPEC-FLUXO-002/C1] Guia descreve Constitution como regras permanentes' $guia '(?is)Constitution.{0,200}regras permanentes'
Assert-Contem '[SPEC-FLUXO-002/C1] Guia descreve Specification com cenarios BDD' $guia '(?is)Specification.{0,200}(cen.rios|BDD|DADO)'
Assert-Contem '[SPEC-FLUXO-002/C1] Guia descreve Technical Plan com arquitetura e riscos' $guia '(?is)Technical Plan.{0,200}(arquitetura|riscos|como)'
Assert-Contem '[SPEC-FLUXO-002/C1] Guia descreve Tasks atomicas e verificaveis' $guia '(?is)Tasks.{0,200}(at.micas|rastre.veis|verific.veis)'
Assert-Contem '[SPEC-FLUXO-002/C1] Guia cita principios de XP ou Extreme Programming' $guia '(?is)(XP|Extreme Programming).{0,200}(feedback|refatora|baby steps)'
Assert-Contem '[SPEC-FLUXO-002/C1] Guia explica loop autonomo pos-P2 com salvaguardas' $guia '(?is)loop aut.nomo.{0,200}(3 falhas|salvaguarda|verificador)'

# C2: Guia de conversacao no chat para nao-devs
Assert-Contem '[SPEC-FLUXO-002/C2] Guia afirma uso 100% pelo chat sem necessidade de terminal' $guia '(?i)(sem terminal|somente pelo chat|apenas pelo chat)'
Assert-Contem '[SPEC-FLUXO-002/C2] Guia contem tabela conversacional com comando refine' $guia '(?i)refine o item'
Assert-Contem '[SPEC-FLUXO-002/C2] Guia contem tabela conversacional com aprovacao P1' $guia '(?i)aprovo P1 da change'
Assert-Contem '[SPEC-FLUXO-002/C2] Guia contem tabela conversacional com aprovacao P2' $guia '(?i)aprovo P2 da change'
Assert-Contem '[SPEC-FLUXO-002/C2] Guia contem tabela conversacional com acoes de fecho e archive' $guia '(?i)(verifique a change|arquive a change)'

# C3: Referencias e rastreabilidade no README e registro de capacidades
Assert-Contem '[SPEC-FLUXO-002/C3] README referencia como-usar-fluxo.md' $readme '(?i)como-usar-fluxo\.md'
Assert-Contem '[SPEC-FLUXO-002/C3] README cita o ciclo dos 4 artefatos' $readme '(?i)4 artefatos'
Assert-Contem '[SPEC-FLUXO-002/C3] _index.md registra SPEC-FLUXO-002' $index 'SPEC-FLUXO-002'
Assert-Contem '[SPEC-FLUXO-002/C3] spec viva da capacidade fluxo contem SPEC-FLUXO-002' $specFluxo 'SPEC-FLUXO-002'

Exit-SddTeste
