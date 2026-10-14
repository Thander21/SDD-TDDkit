---
id: CHG-002
title: Aprovação dos portões por frase no chat
status: Draft
capabilities: [motor]
risk: [portao-humano, contrato-do-motor]
fonte_normativa:
base_ref:
impact:
  modified_files: [SpecSimpleKit/kernel/tools/sdd/sdd.ps1, SpecSimpleKit/kernel/.agents/rules/sdd-core.md, SpecSimpleKit/tests/run_all.ps1, SpecSimpleKit/tests/test_guard.ps1, SpecSimpleKit/CHANGELOG.md, SpecSimpleKit/docs/como-usar-fluxo.md, tools/sdd/sdd.ps1, .agents/rules/sdd-core.md, .sdd/kit.lock.json, AGENTS.md]
  new_files: [SpecSimpleKit/tests/test_motor_aprovacao.ps1]
---

# CHG-002 — Aprovação dos portões por frase no chat

> **Origem:** `origem/02 - Assistente do instalador.md` (movido do backlog), unidade U4; U1, U2, U3 e U5 viram changes seguintes que citam este caminho. **Regra:** `.agents/rules/sdd-fluxo.md`.
> Títulos lidos pelo motor (não renomeie): Perguntas em aberto, Análise
> pré-implementação, Tasks, Pós-GOAL, Exceções, Aprovações. `status`,
> `base_ref` e Aprovações são gravados só pelo `sdd approve` do usuário.

## Por quê

O SpecSimpleKit é para quem não usa terminal: todos os comandos são pelo
chat, por texto ou `/`, e a IA roda os scripts com a permissão liberada pelo
usuário (origem, R1 e R3). Hoje o portão humano só abre no terminal: o
`sdd approve` recusa a IA (`kernel/tools/sdd/sdd.ps1:985-988`) e pede um
código digitado (`:1015-1017`). Sem esta change nenhuma outra change passa
do P1 sem terminal, inclusive a CHG-001. O usuário escolheu a aprovação por
frase no chat, para ter tempo de ler e editar o documento antes (origem, R2).

## Perguntas em aberto

<!-- Vazia = pode pedir o P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | Nova opção `sdd approve <NN> P1\|P2 --frase "<texto do usuário>"`. Com a frase, o motor aceita a chamada pela IA e não pede o código digitado. Sem a frase, o comportamento atual continua (humano no terminal com código). | origem R2 e R3 | 14/10/2026 |
| D2 | A frase só vale se citar a aprovação, o portão e o número da change: contém `aprov` (sem diferenciar maiúsculas), `P1` ou `P2` e o número (`01` ou `1`). Ex.: "aprovo P1 da change 01". | origem RF9 ("aprovo P1 da change 01") | 14/10/2026 |
| D3 | A linha gravada é a de hoje com um campo a mais: depois de `sdd approve;` entra `via chat: "<frase>";`, antes do hash. O trecho que o motor procura (`sdd.ps1:398`) não muda, então changes antigas e projetos instalados continuam válidos. | risco `contrato-do-motor` | 14/10/2026 |
| D4 | O `edit_guard` continua negando a escrita à mão de `status`, `base_ref` e linha de aprovação: o único caminho é o `sdd approve`. O guard de comando continua pedindo confirmação ao `sdd approve` (permissão da ferramenta). | risco `portao-humano`; `machine/edit_guard.ps1:122-133`, `machine/guard.ps1:217` | 14/10/2026 |
| D5 | É honra, não imposto: a máquina não prova que a frase veio do usuário. Aceito pelo usuário (origem RN4). O núcleo (`sdd-core.md`) passa a dizer isso na tabela "imposto e honra" e na regra dos portões. | origem R2, RN4 | 14/10/2026 |

## Contratos

- `sdd approve <NN> P1|P2 --frase "<texto>"`:
  - `APROVADO: <change> <portão> -> <status>` (exit 0) e a linha D3 em
    `## Aprovações`;
  - `RECUSADO: frase sem aprovacao, portao ou numero da change` (exit 1),
    nada gravado;
  - pré-condições de hoje continuam (status, perguntas em aberto, análise,
    fonte normativa).
- Sem `--frase` e sem humano no terminal: `RECUSADO: ...` como hoje, agora
  sugerindo `--frase`.

## Invariantes

- `portao-humano`: a IA não aprova P1/P2 sem a frase do usuário; não grava
  `status`, `base_ref` nem linha de aprovação à mão; não desliga guard.
- `contrato-do-motor`: o formato antigo da linha de aprovação continua
  aceito; projeto instalado na versão anterior continua passando `check` e
  `goal` depois do update.

## Deltas — capacidade `motor`

### ADDED Requirements

#### Requirement: SPEC-MOTOR-001 — Aprovação por frase do usuário

O sistema DEVE aceitar a aprovação de um portão pedida pela IA quando ela
traz a frase do usuário, e gravar a frase literal no registro.

##### Scenario: C1 — Frase válida pela IA

- **DADO** uma change 01 em `Draft` com perguntas em aberto vazias e
  `CLAUDECODE` definida
- **QUANDO** a IA roda `sdd approve 01 P1 --frase "aprovo P1 da change 01"`
- **ENTÃO** o status vira `Approved` e `## Aprovações` tem a linha com
  `via chat: "aprovo P1 da change 01"`

##### Scenario: C2 — IA sem frase

- **DADO** a mesma change e `CLAUDECODE` definida
- **QUANDO** a IA roda `sdd approve 01 P1` sem `--frase`
- **ENTÃO** sai `RECUSADO`, exit 1, sugerindo `--frase`, e o arquivo não muda

##### Scenario: C3 — Frase que não cita portão ou change

- **DADO** a mesma change
- **QUANDO** a IA roda `sdd approve 01 P1 --frase "ok pode seguir"`
- **ENTÃO** sai `RECUSADO`, exit 1, e o arquivo não muda

##### Scenario: C4 — P2 por frase grava base_ref

- **DADO** uma change 01 em `Approved` com a linha P1 e a Análise preenchida
- **QUANDO** a IA roda `sdd approve 01 P2 --frase "aprovo P2 da change 01"`
- **ENTÃO** o status vira `In-Implementation`, `base_ref` recebe o HEAD e a
  linha P2 cita a frase

### MODIFIED Requirements

### REMOVED Requirements

## Comportamento que não muda

<!-- Já funciona hoje; cada item tem teste de regressão (sem RED, porque não
há código novo que o faça passar). Movidos dos deltas antes do P1. -->

- **R-1:** linha de aprovação no formato antigo (sem `via chat`) continua
  reconhecida pelo `spec-lint` e pelo P2 (`sdd.ps1:398`). Regressão em
  `SpecSimpleKit/tests/test_motor_aprovacao.ps1`.
- **R-2:** o guard de comando responde `ask` para
  `sdd approve 01 P1 --frase "..."` (`machine/guard.ps1:217`). Regressão em
  `SpecSimpleKit/tests/test_guard.ps1`.
- **R-3:** o `edit_guard` nega escrever à mão uma linha de aprovação no
  formato D3, com `via chat` (`machine/edit_guard.ps1:131-133`). Regressão
  em `SpecSimpleKit/tests/test_guard.ps1`.

## Critérios de aceite

- Todos os cenários com teste rastreado (tag `SPEC-MOTOR-001/Cn`) e as
  regressões R-1 a R-3 passando, em 5.1 e 7.
- `sdd validate` verde; `sdd goal 02` = `GOAL PASS`.
- Depois do archive, o P1 da CHG-001 é aprovado pelo chat com o motor novo.

## Análise pré-implementação

- Cenários C1-C4 → tasks 2-5 (RED e GREEN cada); R-1 a R-3 → task 1
  (regressão, antes de mexer no código). Nenhuma task sem cenário, exceto
  6-8 (documentação exigida por D5 e pela regra da raiz), todas no `impact`.
- Arquivos do `impact` sem task: nenhum. `.sdd/kit.lock.json`,
  `tools/sdd/sdd.ps1` e `.agents/rules/sdd-core.md` mudam pela task 7
  (`update -Destino . -Forcar`, exceção da raiz documentada no `AGENTS.md`).
- Invariantes: `portao-humano` coberto por C2, C3 e R-3; `contrato-do-motor`
  por R-1.
- Variantes do desfecho (`APROVADO`, `RECUSADO` sem frase, `RECUSADO` frase
  inválida): C1/C4, C2, C3.
- Alvo único `SpecSimpleKit/tests/test_motor_aprovacao.ps1` para C1-C4: o
  perfil `powershell` roda o script inteiro e classifica pelo exit code
  (sem relatório estruturado; item 04). Por isso o RED de cada cenário é a
  mesma execução, e o goal anota "RED classificado só pelo exit code".
- Pré-requisito do RED: suíte verde (validate de 12/10/2026, árvore mudou
  desde então; roda de novo na task 1).

## Tasks

- [ ] REGRESSÃO (R-1, R-2, R-3): testes em `test_motor_aprovacao.ps1` (R-1) e `test_guard.ps1` (R-2, R-3) passando antes de qualquer mudança no motor
- [ ] RED (C1): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: approve com --frase pela IA devolve uso/RECUSADO e o status continua Draft
- [ ] RED (C2): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: mensagem de recusa sem a sugestão de --frase
- [ ] RED (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: frase inválida devolve erro de uso (exit 2) em vez de RECUSADO (exit 1)
- [ ] RED (C4): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: P2 com --frase não grava base_ref nem a frase
- [ ] GREEN (C1): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [ ] GREEN (C2): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [ ] GREEN (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [ ] GREEN (C4): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [ ] REFACTOR: extrair a validação da frase numa função `Test-SddFraseAprovacao` (alvo re-rodado)
- [ ] DOC: `sdd-core.md` (regra dos portões e tabela imposto/honra), `AGENTS.md` (linha `portao-humano` e comando do portão), `como-usar-fluxo.md` (tira o "hoje"), `CHANGELOG.md`
- [ ] SYNC: `install.ps1 update -Destino . -Forcar` e `install.ps1 check -Destino .` sem desvio
- [ ] E1: registrar P1 e P2 desta change com o motor novo, citando as frases do usuário; esvaziar `## Exceções`

### Pós-GOAL

- [ ] Archive (a pedido do usuário): deltas na spec viva, `git mv` para `concluidas/`, `status: Done`

## Exceções

- **E1 (aceita pelo usuário em 14/10/2026, opção "Exceção única"; prazo:
  até o archive desta change):** esta é a change que cria a aprovação pelo
  chat, então o motor ainda não aceita a frase quando o P1 dela é pedido.
  Procedimento: o usuário escreve no chat a frase do P1 (e depois a do P2);
  a implementação segue com TDD e, assim que o `--frase` estiver GREEN, a IA
  registra P1 e P2 com o próprio motor novo, citando as frases dadas antes.
  A exceção sai daqui quando as duas linhas estiverem gravadas.
  Frase dada pelo usuário em 14/10/2026 (opção escolhida no chat):
  "aprovo P1 e P2 da change 02".

## Aprovações

<!-- Gravado só pelo 'sdd approve NN P1|P2' no terminal do usuário. -->
