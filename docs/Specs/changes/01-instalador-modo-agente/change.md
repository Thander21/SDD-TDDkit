---
id: CHG-001
title: Instalador em modo agente (detectar, plano, recusa e remover)
status: Draft
capabilities: [instalador]
risk: [start-chat, config-global, arquivo-do-usuario]
fonte_normativa:
base_ref:
impact:
  modified_files: [SpecSimpleKit/install.ps1, SpecSimpleKit/tests/test_install.ps1, SpecSimpleKit/CHANGELOG.md, README.md]
  new_files: [SpecSimpleKit/tests/test_install_agente.ps1]
---

# CHG-001 — Instalador em modo agente

> **Origem:** `origem/01 - Start pelo chat.md` (movido do backlog), unidade U1; U2 a U4 viram changes seguintes que citam este caminho. **Regra:** `.agents/rules/sdd-fluxo.md`.
> Títulos lidos pelo motor (não renomeie): Perguntas em aberto, Análise
> pré-implementação, Tasks, Pós-GOAL, Exceções, Aprovações. `status`,
> `base_ref` e Aprovações são gravados só pelo `sdd approve` do usuário.

## Por quê

O início do kit vai passar a ser pelo chat (item 01, R1 e R2): quem roda o
instalador é a IA, nunca o usuário no terminal. Hoje o instalador não serve
para isso: não informa o estado da pasta para a IA decidir o que perguntar,
não mostra o que vai gravar antes de gravar, aceita todos os padrões em
silêncio quando quem chama é um agente (`install.ps1:61-75`, reproduzido em
12/10/2026) e não tem como sair do projeto depois de instalado (R3). Esta
change dá ao instalador as quatro operações que as skills de início (U3)
vão usar.

## Perguntas em aberto

<!-- Vazia = pode pedir o P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | `-Ferramentas` fica para a U2 (adaptadores): hoje o Claude depende de `.agents/rules` e `.agents/skills`, então separar ferramentas só faz sentido junto com os adaptadores. Nesta change o comportamento continua "Claude + Antigravity". | `project-templates/CLAUDE.md` importa `.agents/rules/sdd-core.md`; recorte do item 01 | 12/10/2026 |
| D2 | `remover` preserva o que é do projeto: `.sdd/profile.json` (calibrado), specs, backlog, changes e a seção Projeto do `AGENTS.md`. Reinstalar depois reaproveita o perfil existente (`install.ps1:269-271`). Apagar também isso fica fora desta change. | RF10 do item 01 ("preserva o que é do projeto salvo pedido explícito") | 12/10/2026 |
| D3 | `detectar` devolve JSON numa linha, para a IA ler sem interpretar texto. | padrão BMAD v7 (`setup.py --status` devolve JSON), pesquisa de 12/10/2026 | 12/10/2026 |
| D4 | O hook de pre-commit é reconhecido pela marca `# sdd-kit pre-commit` que o motor já grava (`tools/sdd/sdd.ps1:1119`), sem mudar o formato do lock. | RN7 do item 01; risco `contrato-do-motor` (lock não muda) | 12/10/2026 |

## Contratos

- `install.ps1 detectar -Destino <pasta>`: só leitura; imprime uma linha
  JSON com `pasta`, `git` (bool), `pendentes` (int), `kit_instalado`
  (bool), `kit_versao`, `perfil`, `calibrado`, `perfil_sugerido`; exit 0.
- `install.ps1 projeto|update ... -Plano`: imprime o plano (arquivos novos,
  alterados, conflitos, linhas do `.gitignore`) e não grava nada; exit 0
  sem conflito, 1 com conflito.
- `install.ps1 remover -Destino <pasta> [-Plano]`: desfecho `REMOVIDO`
  (exit 0), `NADA A REMOVER` (sem kit, exit 1); arquivos gerenciados
  editados aparecem em `PRESERVADO:` junto do `REMOVIDO`.
- Sem ação e sem humano no terminal (stdin redirecionado, `CLAUDECODE` ou
  `SDD_AGENTE`): `ERRO: ...` com o comando completo sugerido, exit 2, nada
  gravado.

## Invariantes

- `start-chat`: o início pelo chat funciona sem rodar instalador à mão; a IA
  sabe o estado da pasta antes de perguntar.
- `config-global`: nada fora do projeto muda sem comando explícito do
  humano e plano mostrado antes.
- `arquivo-do-usuario`: instalador e remoção nunca sobrescrevem nem apagam
  arquivo do projeto fora dos gerenciados; arquivo gerenciado editado é
  preservado e listado.

## Deltas — capacidade `instalador`

### ADDED Requirements

#### Requirement: SPEC-INST-001 — Detectar o estado da pasta

O sistema DEVE informar, sem gravar nada, o estado da pasta do projeto em
uma linha JSON.

##### Scenario: C1 — Pasta sem o kit

- **DADO** um repositório git com `package.json` e sem `.sdd/kit.lock.json`
- **QUANDO** a IA roda `install.ps1 detectar -Destino <pasta>`
- **ENTÃO** a saída tem `kit_instalado: false`, `git: true` e
  `perfil_sugerido: "node"`, e a árvore git continua igual

##### Scenario: C2 — Pasta com o kit

- **DADO** um repositório com o kit instalado no perfil `node`
- **QUANDO** a IA roda `detectar`
- **ENTÃO** a saída tem `kit_instalado: true`, `perfil: "node"`,
  `kit_versao` e `calibrado`

##### Scenario: C3 — Pasta sem git

- **DADO** uma pasta que não é repositório git
- **QUANDO** a IA roda `detectar`
- **ENTÃO** a saída tem `git: false`, exit 0, e nenhum `git init` é feito

#### Requirement: SPEC-INST-002 — Plano antes de gravar

O sistema DEVE mostrar o que vai gravar sem gravar, quando pedido.

##### Scenario: C1 — Plano da instalação

- **DADO** um repositório sem o kit
- **QUANDO** a IA roda `install.ps1 projeto -Destino <pasta> -Perfil node -Plano`
- **ENTÃO** a saída lista os arquivos que seriam criados e a árvore git
  continua igual

##### Scenario: C2 — Plano com conflito

- **DADO** um repositório com `.agents/rules/sdd-core.md` de conteúdo diferente
- **QUANDO** a IA roda o mesmo comando com `-Plano`
- **ENTÃO** o conflito aparece no plano, exit 1, e nada é gravado

#### Requirement: SPEC-INST-003 — Recusa quando não há humano no terminal

O sistema DEVE recusar o modo sem parâmetros quando não houver humano no
terminal, em vez de aceitar padrões.

##### Scenario: C1 — Stdin redirecionado

- **DADO** o instalador chamado sem ação e com stdin redirecionado
- **QUANDO** ele roda
- **ENTÃO** sai com exit 2, a mensagem traz o comando completo sugerido e
  nenhum arquivo é gravado, nem no projeto nem fora dele

##### Scenario: C2 — Chamado pelo Claude Code

- **DADO** a variável `CLAUDECODE` definida
- **QUANDO** o instalador roda sem ação
- **ENTÃO** o mesmo desfecho do C1

#### Requirement: SPEC-INST-004 — Remover o kit do projeto

O sistema DEVE remover do projeto só o que o kit instalou, preservando o
que é do projeto, e permitir reinstalar depois.

##### Scenario: C1 — Remoção completa

- **DADO** um projeto com o kit instalado e o pre-commit do kit
- **QUANDO** a IA roda `install.ps1 remover -Destino <pasta>`
- **ENTÃO** somem os arquivos gerenciados do lock, o bloco
  `sdd-kit:begin/end` do `AGENTS.md`, as linhas `# sdd-kit` do `.gitignore`,
  o hook e o lock; ficam `.sdd/profile.json`, a pasta de specs e a seção
  Projeto do `AGENTS.md`

##### Scenario: C2 — Arquivo gerenciado editado

- **DADO** um arquivo gerenciado com conteúdo diferente do hash do lock
- **QUANDO** a IA roda `remover`
- **ENTÃO** esse arquivo continua no lugar e aparece em `PRESERVADO:`

##### Scenario: C3 — Plano da remoção

- **DADO** um projeto com o kit
- **QUANDO** a IA roda `remover -Plano`
- **ENTÃO** a saída lista o que seria removido e a árvore git continua igual

##### Scenario: C4 — Reinstalar depois de remover

- **DADO** um projeto de onde o kit foi removido
- **QUANDO** a IA roda `projeto` de novo com o mesmo perfil
- **ENTÃO** instala sem conflito e reaproveita o `.sdd/profile.json`

##### Scenario: C5 — Pasta sem o kit

- **DADO** uma pasta sem `.sdd/kit.lock.json`
- **QUANDO** a IA roda `remover`
- **ENTÃO** sai com `NADA A REMOVER`, exit 1, e nada muda

### MODIFIED Requirements

### REMOVED Requirements

## Critérios de aceite

- Todos os cenários com teste rastreado (tag `SPEC-INST-NNN/Cn`) passando.
- `sdd validate` verde; `sdd goal 01` = `GOAL PASS`.
- A suíte existente (`test_install.ps1`) continua verde em 5.1 e 7.

## Análise pré-implementação

<!-- Etapa 5, depois do P1. -->

## Tasks

<!-- Etapa 4, depois do P1: RED → GREEN → REFACTOR por cenário. -->

### Pós-GOAL

- [ ] Archive (a pedido do usuário): deltas na spec viva, `git mv` para `concluidas/`, `status: Done`

## Exceções

## Aprovações

<!-- Gravado só pelo 'sdd approve NN P1|P2' no terminal do usuário. -->
