---
id: CHG-005
title: Guard só no projeto (fim do passo maquina)
status: Draft
capabilities: [guard, instalador]
risk: [config-global, portao-humano, arquivo-do-usuario]
fonte_normativa:
base_ref:
impact:
  modified_files: [SpecSimpleKit/install.ps1, SpecSimpleKit/kernel/tools/sdd/sdd.ps1, SpecSimpleKit/machine/guard.ps1, SpecSimpleKit/machine/edit_guard.ps1, SpecSimpleKit/tests/test_guard.ps1, SpecSimpleKit/tests/test_install.ps1, SpecSimpleKit/tests/run_all.ps1, SpecSimpleKit/kernel/.agents/rules/sdd-core.md, SpecSimpleKit/CHANGELOG.md, README.md, AGENTS.md, tools/sdd/sdd.ps1, .agents/rules/sdd-core.md, .sdd/kit.lock.json]
  new_files: [SpecSimpleKit/kernel/tools/sdd/guard.ps1, SpecSimpleKit/kernel/tools/sdd/edit_guard.ps1, SpecSimpleKit/tests/test_guard_projeto.ps1, tools/sdd/guard.ps1, tools/sdd/edit_guard.ps1, .claude/settings.json, .agents/hooks.json]
---

# CHG-005 — Guard só no projeto

> **Origem:** `origem/05 - Kit so no projeto.md` (movido do backlog), unidade U1; U2 e U3 viram changes seguintes que citam este caminho. **Regra:** `.agents/rules/sdd-fluxo.md`.
> Títulos lidos pelo motor (não renomeie): Perguntas em aberto, Análise
> pré-implementação, Tasks, Pós-GOAL, Exceções, Aprovações. `status`,
> `base_ref` e Aprovações são gravados só pelo `sdd approve`.

## Por quê

O guard do kit (confirmação de comando perigoso e bloqueio de aprovação
escrita à mão) só existia no nível da máquina: o passo `maquina` gravava
hooks e permissões em `~/.claude/settings.json` e `~/.gemini/config/hooks.json`
(`SpecSimpleKit/install.ps1:472-497`), que valiam em qualquer pasta. O teste
de 12/10/2026 afetou outros projetos e foi removido em 14/10/2026 (origem,
Levantamento). Hoje nenhum projeto tem guard, nem este. O usuário decidiu
que o kit configura só o projeto onde está (origem, R1 e R5).

## Perguntas em aberto

<!-- Vazia = pode pedir o P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | Claude Code: hooks e permissões em `.claude/settings.json` do projeto. Hook em formato `command` + `args` (`powershell.exe` direto, sem shell), script por `${CLAUDE_PROJECT_DIR}/tools/sdd/guard.ps1` e `.../edit_guard.ps1`, `onFailure: "block"`. Nunca caminho relativo: a pasta de trabalho do hook não é garantida. | code.claude.com/docs/en/hooks ("`${CLAUDE_PROJECT_DIR}`: the project root"; exec form substitui o placeholder em `args`; `onFailure` desde a v2.1.295), consultado em 14/10/2026 | 14/10/2026 |
| D2 | Antigravity: entradas `sdd-kit-guard` e `sdd-kit-edit-guard` em `.agents/hooks.json` do projeto, mesmo formato de antes, script por caminho relativo `tools/sdd/...`. É tentativa: a doc não diz a pasta de trabalho do hook, e relatos de terceiros dizem que hooks não disparam na IDE nem no app (só no CLI `agy`). Fica marcado como não verificado no núcleo. | antigravity.google/docs/hooks ("Workspace level: `.agents/hooks.json`"); discuss.ai.google.dev, tópicos 176814 e 178288 (terceiros), consultados em 14/10/2026 | 14/10/2026 |
| D3 | A lógica fica no motor: `sdd guard ativar \| desativar \| status`. O instalador chama o motor depois de copiar os arquivos; o início guiado (U2) vai chamar o mesmo comando. Uma implementação só. | origem, RN7 (a máquina confere) | 14/10/2026 |
| D4 | Entradas do kit reconhecidas assim: hooks do Claude cujo `args` termina em `tools/sdd/guard.ps1` ou `tools/sdd/edit_guard.ps1`; permissões pela lista fixa do kit (as mesmas 42 `deny` e 4 `ask` de antes); Antigravity pelas chaves `sdd-kit-guard` e `sdd-kit-edit-guard`. Nada mais do arquivo é tocado. | origem, RN2; identificadores `sdd-kit` mantidos (CHANGELOG) | 14/10/2026 |
| D5 | Conteúdo do usuário nos settings é preservado; a formatação do JSON pode mudar (o PowerShell reescreve o arquivo). O `status` e a saída do `ativar` dizem quais arquivos mudaram. | risco `arquivo-do-usuario` | 14/10/2026 |
| D6 | Hooks nos settings do projeto rodam sem a tela de confiança da pasta, e `deny`/`ask` valem na hora: quem clona o projeto recebe o guard ativo. Aceito, porque é o guard do próprio projeto. | code.claude.com/docs/en/permissions ("What runs before you trust a folder"), 14/10/2026 | 14/10/2026 |
| D8 | As mensagens dos guards que mandam aprovar "no terminal" (`edit_guard.ps1:124`, `guard.ps1:217`) passam a orientar a frase no chat (`sdd approve NN P1\|P2 --frase`). | achado A2 da verificação da CHG-002; decisão do usuário "Dividir", 14/10/2026 | 14/10/2026 |
| D7 | Os guards saem de `machine/` e entram no kernel (`tools/sdd/`), viram arquivos gerenciados com hash no lock; o `edit_guard` já pede confirmação para editar `tools/sdd/`. A pasta `machine/`, a ação `maquina` e os parâmetros `-Aplicar` e `-Casa` saem do instalador. | origem, RN1 | 14/10/2026 |

## Contratos

- `sdd guard ativar`: grava ou completa as entradas do kit em
  `.claude/settings.json` e `.agents/hooks.json` do projeto; imprime
  `GUARD ATIVO: <arquivos alterados>`; exit 0. JSON inválido num deles:
  `ERRO: <arquivo> nao e JSON valido (nada foi gravado)`, exit 2.
- `sdd guard desativar`: remove só as entradas do kit; arquivo que ficar
  vazio e que só tinha entradas do kit é apagado; `GUARD INATIVO`; exit 0.
- `sdd guard status`: `GUARD: ativo | inativo | parcial (<o que falta>)`;
  exit 0 em ativo, 1 nos outros.
- `install.ps1 projeto` e `update`: depois de gravar, rodam
  `sdd guard ativar` no projeto. Nenhuma gravação fora do projeto.

## Invariantes

- `config-global`: nada fora do projeto muda (nem `~/.claude`, `~/.gemini`,
  `~/.sdd-kit`), em nenhuma ação do instalador ou do motor.
- `portao-humano`: a IA não desliga o guard sem você: `sdd guard desativar`
  e edição dos arquivos de settings pedem confirmação.
- `arquivo-do-usuario`: o que não é do kit nos settings fica igual.

## Deltas — capacidade `guard`

### ADDED Requirements

#### Requirement: SPEC-GUARD-002 — Ativar o guard só no projeto

O sistema DEVE configurar o guard de comando e de edição apenas nos
arquivos de settings do projeto.

##### Scenario: C1 — Projeto sem settings

- **DADO** um projeto sem `.claude/settings.json` e sem `.agents/hooks.json`,
  e uma pasta de usuário falsa (`USERPROFILE` e `HOME` apontando para ela)
- **QUANDO** a IA roda `sdd guard ativar`
- **ENTÃO** os dois arquivos são criados com os 2 hooks e as permissões do
  kit (D1, D2, D4) e a pasta de usuário falsa continua vazia

##### Scenario: C2 — Settings do usuário já existentes

- **DADO** um `.claude/settings.json` do projeto com um `allow` e um hook
  do usuário
- **QUANDO** a IA roda `sdd guard ativar` duas vezes
- **ENTÃO** o `allow` e o hook do usuário continuam, e as entradas do kit
  aparecem uma vez só

##### Scenario: C3 — Settings inválido

- **DADO** um `.claude/settings.json` com JSON inválido
- **QUANDO** a IA roda `sdd guard ativar`
- **ENTÃO** sai `ERRO`, exit 2, e nenhum dos dois arquivos muda

##### Scenario: C4 — Guard dispara no Claude Code

- **DADO** o Claude Code aberto num projeto com o guard ativo
- **QUANDO** a IA pede para rodar `git push --force`
- **ENTÃO** a ferramenta pede a confirmação do usuário (evidência MANUAL)

#### Requirement: SPEC-GUARD-003 — Desativar remove só o que é do kit

O sistema DEVE remover apenas as entradas do kit e informar o estado do guard.

##### Scenario: C1 — Volta ao conteúdo do usuário

- **DADO** o guard ativado sobre settings do usuário (como em GUARD-002/C2)
- **QUANDO** a IA roda `sdd guard desativar`
- **ENTÃO** o conteúdo do usuário fica igual ao de antes da ativação e o
  `.agents/hooks.json`, que só tinha entradas do kit, é apagado

##### Scenario: C2 — Status

- **DADO** um projeto com só o `.claude/settings.json` do kit (sem o
  `.agents/hooks.json`)
- **QUANDO** a IA roda `sdd guard status`
- **ENTÃO** a saída é `GUARD: parcial` citando o arquivo que falta, exit 1

#### Requirement: SPEC-GUARD-004 — A IA não desliga o guard sozinha

O sistema DEVE pedir a confirmação do usuário antes de desligar o guard.

##### Scenario: C1 — Comando de desativar

- **DADO** o guard de comando
- **QUANDO** a IA pede `powershell -File tools/sdd/sdd.ps1 guard desativar`
- **ENTÃO** a decisão é `ask`

##### Scenario: C2 — Edição dos settings

- **DADO** o guard de edição
- **QUANDO** a IA tenta editar `.claude/settings.json`, `.claude/settings.local.json` ou `.agents/hooks.json` do projeto
- **ENTÃO** a decisão é `ask`

## Deltas — capacidade `instalador`

### ADDED Requirements

#### Requirement: SPEC-INST-005 — Instalação sem gravação global

O sistema DEVE instalar e atualizar o kit sem gravar fora do projeto,
deixando o guard ativo no projeto.

##### Scenario: C1 — Instalar

- **DADO** um repositório sem o kit e uma pasta de usuário falsa
- **QUANDO** a IA roda `install.ps1 projeto -Destino <repo> -Perfil node`
- **ENTÃO** `sdd guard status` no projeto dá `ativo` e a pasta de usuário
  falsa continua vazia

##### Scenario: C2 — Ação `maquina` não existe mais

- **DADO** o instalador desta versão
- **QUANDO** alguém roda `install.ps1 maquina`
- **ENTÃO** a ação é recusada (exit diferente de 0) e nada é gravado

##### Scenario: C3 — Update ativa o guard

- **DADO** um projeto instalado na versão anterior (sem guard no projeto)
- **QUANDO** a IA roda `install.ps1 update -Destino <repo>`
- **ENTÃO** os guards entram em `tools/sdd/` e `sdd guard status` dá `ativo`

### MODIFIED Requirements

### REMOVED Requirements

## Comportamento que não muda

- R-1: as decisões do guard de comando e do guard de edição (corpus de
  `tests/test_guard.ps1`: 98 asserts em 12/10/2026) continuam iguais depois
  da mudança de pasta.

## Critérios de aceite

- Cenários com teste rastreado (`SPEC-GUARD-00N/Cn`, `SPEC-INST-005/Cn`)
  passando em 5.1 e 7; GUARD-002/C4 com evidência MANUAL.
- `sdd validate` verde; `sdd goal 05` = `GOAL PASS`.
- Este repositório com o guard ativo (`sdd guard status` = `ativo`).

## Análise pré-implementação

<!-- Etapa 5, depois do P1. -->

## Tasks

<!-- Etapa 4, depois do P1: RED → GREEN → REFACTOR por cenário. -->

### Pós-GOAL

- [ ] Archive (a pedido do usuário): deltas na spec viva, `git mv` para `concluidas/`, `status: Done`

## Exceções

## Aprovações

<!-- Gravado só pelo 'sdd approve NN P1|P2'. -->
