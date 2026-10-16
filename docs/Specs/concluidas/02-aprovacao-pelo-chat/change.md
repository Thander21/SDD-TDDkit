---
id: CHG-002
title: Aprovação dos portões por frase no chat
status: Done
capabilities: [motor]
risk: [portao-humano, contrato-do-motor]
fonte_normativa:
base_ref: e24ea4eb219191231d3667de2be677ffb8dfdb61
impact:
  modified_files: [README.md, SpecSimpleKit/Metodologia SDD.ai, SpecSimpleKit/kernel/tools/sdd/sdd.ps1, SpecSimpleKit/kernel/.agents/rules/sdd-core.md, SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md, SpecSimpleKit/kernel/.agents/skills/backlog-refinement/SKILL.md, SpecSimpleKit/project-templates/AGENTS.md, SpecSimpleKit/kernel/Docs/Specs/_templates/change.md, docs/Specs/_templates/change.md, SpecSimpleKit/tests/run_all.ps1, SpecSimpleKit/tests/test_guard.ps1, SpecSimpleKit/CHANGELOG.md, SpecSimpleKit/docs/como-usar-fluxo.md, tools/sdd/sdd.ps1, .agents/rules/sdd-core.md, .agents/rules/sdd-fluxo.md, .agents/skills/backlog-refinement/SKILL.md, .sdd/kit.lock.json, AGENTS.md]
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
| D6 | Exceção E1 (aceita em 14/10/2026, opção "Exceção única") cumprida: o usuário deu a frase "aprovo P1 e P2 da change 02" antes da implementação; P1 e P2 foram registrados pelo motor novo com essa frase assim que o `--frase` ficou GREEN. | E1; linhas em `## Aprovações` | 14/10/2026 |
| D10 | O número da change só vale colado a "change" ou "CHG" ("change 02", "change 2", "CHG-002"); número solto (data, "os 2 portões") é ignorado, e frase que cita assim outra change é recusada. Ajusta a letra da D2 (achado A1-R da 2ª verificação). | usuário, 14/10/2026 (opção "Junto de change") | 14/10/2026 |
| D7 | Aceito o `impact` ampliado depois do P1/P2 com 7 arquivos de documentação da mesma regra (sdd-fluxo, skill de refinamento, molde do `AGENTS.md`, moldes da change e cópias da raiz) e, pelo achado A2, `README.md` e `SpecSimpleKit/Metodologia SDD.ai`. Mensagens dos guards vão para a CHG-005; o diagnóstico HTML, para a release. | usuário, 14/10/2026 (B3 "Aceito"; A2 "Dividir") | 14/10/2026 |
| D8 | Frase negativa ("não aprovo P1 da change 01") passa pela letra da D2 e fica assim: quem escreve a frase é o usuário. | usuário, 14/10/2026 (B1 "Deixar como está") | 14/10/2026 |
| D9 | Orçamento "40 KB" do Markdown do kernel = 40.960 bytes; a unidade passa a constar no README. | usuário, 14/10/2026 (B4) | 14/10/2026 |
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
- **QUANDO** a IA roda `sdd approve 01 P1 --frase "ok pode seguir"`, ou
  com uma frase que cita outra change ("aprovo P1 da change 03") ou nenhuma
  ("aprovo P1"), ou com número solto ("aprovo P1 da change 03 em 01/10");
  o número só vale junto de "change" ou "CHG" (D10; achados A1 e A1-R
  dos verificadores, 14/10/2026)
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

- [x] REGRESSÃO (R-1, R-2, R-3): testes em `test_motor_aprovacao.ps1` (R-1) e `test_guard.ps1` (R-2, R-3) passando antes de qualquer mudança no motor
- [x] RED (C1): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: approve com --frase pela IA devolve uso/RECUSADO e o status continua Draft
- [x] RED (C2): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: mensagem de recusa sem a sugestão de --frase
- [x] RED (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: frase inválida devolve erro de uso (exit 2) em vez de RECUSADO (exit 1)
- [x] RED (C4): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: P2 com --frase não grava base_ref nem a frase
- [x] GREEN (C1): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [x] GREEN (C2): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [x] GREEN (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [x] GREEN (C4): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [x] RED (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: "aprovo P1 da change 03" e "aprovo P1" aprovam a change 01 (achado A1 do verificador)
- [x] GREEN (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou
- [x] RED (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: "aprovo P1 da change 03 em 01/10" aprova a change 01 e "aprovo P1 e P2 da change 05, os 2 portoes" aprova o P2 da 02 (achado A1-R)
- [x] GREEN (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou (D10)
- [x] RED (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> Falha esperada: "aprovo P1 da change 99999999999" sai com ERRO exit 2 em vez de RECUSADO exit 1 (achado A3); "change 01 e change 03" ja recusa, coberto por prova de mutacao: com `return ($citadas -contains $num)` o teste falha, 25/28 (achado A4)
- [x] GREEN (C3): SpecSimpleKit/tests/test_motor_aprovacao.ps1 -> passou (A3, A4)
- [x] DOC (A2): `README.md` (comando `approve` e unidade do orçamento), `Metodologia SDD.ai` (portões e tabela), `AGENTS.md` (referência de linha)
- [x] REFACTOR: extrair a validação da frase numa função `Test-SddFraseAprovacao` (alvo re-rodado)
- [x] DOC: `sdd-core.md` (regra dos portões e tabela imposto/honra), `sdd-fluxo.md` e `backlog-refinement` (mesma regra, acrescentados ao `impact` em 14/10/2026 para não ficarem contraditórios), molde e `AGENTS.md` (linha `portao-humano` e comando do portão), `como-usar-fluxo.md` (tira o "hoje"), `CHANGELOG.md`
- [x] SYNC: `install.ps1 update -Destino . -SemArvoreLimpa` e `install.ps1 check -Destino .` sem desvio; a primeira sem `-Forcar` (antes do P2), as seguintes com `-Forcar` (change já em implementação; exceção da raiz no `AGENTS.md`; achado B2 do verificador)
- [x] E1: registrar P1 e P2 desta change com o motor novo, citando as frases do usuário; esvaziar `## Exceções`

### Pós-GOAL

- [x] Archive (automático depois do GOAL PASS, decisão do usuário de 16/10/2026): deltas na spec viva, `git mv` para `concluidas/`, `status: Done`

## Exceções

## Aprovações

<!-- Gravado só pelo 'sdd approve NN P1|P2' (frase do usuário ou terminal dele). -->
- P1: aprovado por Thander em 2026-10-14 16:48 (sdd approve; via chat: "aprovo P1 e P2 da change 02"; change.md antes: 4fadd7895f32)
- P2: aprovado por Thander em 2026-10-14 16:48 (sdd approve; via chat: "aprovo P1 e P2 da change 02"; change.md antes: fd08e3caa527)
