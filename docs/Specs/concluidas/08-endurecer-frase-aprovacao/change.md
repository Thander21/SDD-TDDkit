---
id: CHG-008
title: Endurecer frase de aprovacao
status: Done
capabilities:
  - motor
risk:
  - portao-humano
fonte_normativa:
base_ref: ee7d6a4d285a639a6cd89842cbcaf9fedd5c1a46
impact:
  modified_files:
    - SpecSimpleKit/kernel/tools/sdd/sdd.ps1
    - tools/sdd/sdd.ps1
    - .sdd/kit.lock.json
    - tests/test_motor_aprovacao.ps1
  new_files: []
---

# CHG-008 — Endurecer frase de aprovação

> **Origem:** `origem/08 - Endurecer frase de aprovacao.md` (movido do backlog). **Regra:** `.agents/rules/sdd-fluxo.md`.
> Títulos lidos pelo motor (não renomeie): Perguntas em aberto, Análise
> pré-implementação, Tasks, Pós-GOAL, Exceções, Aprovações. `status`,
> `base_ref` e Aprovações são gravados só pelo `sdd approve` do usuário.

## Por quê

Na validação da frase de aprovação do usuário (`Test-SddFraseAprovacao`):
1. A regex atual ignora referências espúrias a outras changes caso contenham sufixos alfabéticos ou numerais não ASCII (ex.: "change 03x", "change ٣"), permitindo aprovação indevida se a change alvo também for citada.
2. A conversão `[int]` sobre `$NN` estoura com `System.OverflowException` quando chamado com número grande (ex.: `sdd approve 99999999999 P1`), saindo com exit 2 (ERRO não tratado) em vez de exit 1 (`RECUSADO`).

## Perguntas em aberto

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | Abrir como Feature com CHG-008 (promovido pela tag de risco `portao-humano` em `AGENTS.md`) e renomear item de origem para 08. | Usuário no chat | 2026-10-19 |

## Contratos

- `Test-SddFraseAprovacao([string]$Frase, [string]$Portao, [string]$NN)`: retorna `$true` se a frase cita a aprovação, o portão e estritamente a change `$NN`, e `$false` caso contrário.
- `Invoke-SddApprove`: `sdd approve <NN> P0|P1|P2 [--frase "<texto>"]` retorna 0 (`APROVADO`) ou 1 (`RECUSADO`). Não lança exceção não tratada para valores arbitrários de `$NN`.

## Invariantes

- `portao-humano`: A IA não aprova P0, P1 ou P2 sem a frase do usuário que cita aprovação, portão e change; citação de outra change, ambiguidade ou frase inválida resulta em `RECUSADO` (exit 1) e nada gravado.

## Deltas — capacidade motor

### MODIFIED Requirements

#### Requirement: SPEC-MOTOR-001 — Aprovação por frase do usuário

O sistema DEVE aceitar a aprovação de um portão pedida pela IA quando ela
traz a frase do usuário, e gravar a frase literal no registro. A frase vale
se contém "aprov", o portão (P0, P1 ou P2) e estritamente a change alvo colada a
"change" ou "CHG" ("change 02", "CHG-002"); número solto é ignorado, citar
outra change recusa, e tokens colados ou não numéricos pós-"change"/"CHG" recusam.
O `$NN` e as citações são comparados como texto normalizado sem zeros à esquerda,
sem estouro por coerção inteira.

##### Scenario: C1 — Frase válida pela IA

- **DADO** uma change 01 em `Draft` com perguntas em aberto vazias e a IA chamando
- **QUANDO** a IA roda `sdd approve 01 P1 --frase "aprovo P1 da change 01"` (ou "da CHG-001")
- **ENTÃO** o status vira `Approved` e a linha P1 tem `via chat: "<frase>"`

##### Scenario: C2 — IA sem frase

- **DADO** a mesma change
- **QUANDO** a IA roda `sdd approve 01 P1` sem `--frase`
- **ENTÃO** sai `RECUSADO`, exit 1, sugerindo `--frase`, e o arquivo não muda

##### Scenario: C3 — Frase que não cita a aprovação, o portão ou a change alvo

- **DADO** uma change 01 e a IA chamando com `--frase`
- **QUANDO** a frase não tem "aprov", não cita a change, cita outra change (mesmo com sufixo ou dígito não ASCII como "change 03x" ou "change ٣"), tem só número solto, ou traz número gigante na linha de comando / frase
- **ENTÃO** sai `RECUSADO`, exit 1 (sem ERRO/exceção), e o arquivo não muda

##### Scenario: C4 — P2 por frase grava base_ref

- **DADO** uma change 01 em `Approved` com a linha P1 e a Análise preenchida
- **QUANDO** a IA roda `sdd approve 01 P2 --frase "aprovo P2 da change 01"`
- **ENTÃO** o status vira `In-Implementation`, `base_ref` recebe o HEAD e a linha P2 cita a frase

## Comportamento que não muda

- Números soltos sem vínculo com "change" ou "chg" (como datas ou o próprio dígito do portão "P1") continuam ignorados como identificadores de change.
- A aprovação interativa no terminal humano (`Test-SddTerminalHumano`) continua inalterada.

## Critérios de aceite

- Testes de `SPEC-MOTOR-001/C1..C4` passando em PowerShell 5.1 e 7 (`SpecSimpleKit/tests/test_motor_aprovacao.ps1`).
- `sdd check` e `sdd validate` sem achados (`SDD CHECK PASS` / `SDD VALIDATE PASS`).
- `sdd goal 08` atinge `GOAL PASS` após implementação e verificação.

## Análise pré-implementação

- **Plano:** Ajustar `Test-SddFraseAprovacao` em `SpecSimpleKit/kernel/tools/sdd/sdd.ps1` para:
  1. Comparar `$NN` e as citações como string sem zeros à esquerda (`TrimStart('0')`), sem cast para `[int]`, eliminando `OverflowException` com NNs grandes.
  2. Capturar tokens vinculados a "change" ou "chg" garantindo que qualquer citação que não seja estritamente dígitos ASCII correspondentes à change alvo resulte em recusa (`RECUSADO`, exit 1).
  3. Adicionar asserções de regressão e robustez em `SpecSimpleKit/tests/test_motor_aprovacao.ps1`.
- **Rastreabilidade:** Todos os cenários (C1 a C4 de `SPEC-MOTOR-001`) são exercidos na suíte `SpecSimpleKit/tests/test_motor_aprovacao.ps1`, com foco no endurecimento de C3.
- **Tamanho:** 1 capacidade (`motor`), 1 requisito (`SPEC-MOTOR-001`), 4 cenários (C1..C4), 2 arquivos impactados (`SpecSimpleKit/kernel/tools/sdd/sdd.ps1` e `SpecSimpleKit/tests/test_motor_aprovacao.ps1`), ~110 linhas no `change.md` (abaixo do teto de 250).
- **Invariantes:** Invariante de `portao-humano` assegurada: nada é gravado sem aprovação válida do usuário e menção ambígua é rejeitada.
- **Dogfooding:** Alteração feita no kernel e sincronizada para a raiz via `powershell -File SpecSimpleKit/install.ps1 update -Destino . -Forcar` após validação da suíte.

## Tasks

- [x] RED (C1,C2,C3,C4): `tests/test_motor_aprovacao.ps1` -> Falha esperada: falha ou saída inesperada para NN gigante (overflow) e citação de change com sufixo ou caracteres não ASCII
- [x] GREEN (C1,C2,C3,C4): `tests/test_motor_aprovacao.ps1` -> passou
- [x] REFACTOR: Sincronizar kernel com a raiz via instalador (-Forcar), rodar `sdd check` e verificar ausência de efeitos colaterais

### Pós-GOAL

- [x] Atualizar spec viva `docs/Specs/capabilities/motor/spec.md` refletindo o endurecimento de SPEC-MOTOR-001 e histórico CHG-008.
- [ ] Arquivar change via `sdd archive 08`.

## Exceções

<!-- Nenhuma. -->

## Aprovações
- P1: aprovado por Thander em 2026-10-19 17:01 (sdd approve; via chat: "aprovo P1 da change 08"; change.md antes: 6b9d5fbd9d3c)
- P2: aprovado por Thander em 2026-10-19 17:14 (sdd approve; via chat: "aprovo P2 da change 08"; change.md antes: 358b2af7951f)
