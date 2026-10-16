# motor

> **Domínio:** `MOTOR` · **Origem no código:** `SpecSimpleKit/kernel/tools/sdd/sdd.ps1`.
> Este arquivo descreve o comportamento **atual**. Só muda no archive de uma
> change, pelos deltas dela. Cabeçalhos no formato do OpenSpec (Purpose,
> Requirements, Requirement, Scenario) para a validação externa continuar possível.

## Purpose

Motor do fluxo SDD: gates, evidência de teste, portões humanos, verificador e
condição de parada das changes, rodado pela IA ou pelo usuário.

## Requirements

### Requirement: SPEC-MOTOR-001 — Aprovação por frase do usuário

O sistema DEVE aceitar a aprovação de um portão pedida pela IA quando ela
traz a frase do usuário, e gravar a frase literal no registro. A frase vale
se contém "aprov", o portão (P1 ou P2) e a change colada a "change" ou
"CHG" ("change 02", "CHG-002"); número solto é ignorado e citar outra change
recusa.

#### Scenario: C1 — Frase válida pela IA

- **DADO** uma change 01 em `Draft` com perguntas em aberto vazias e a IA chamando
- **QUANDO** a IA roda `sdd approve 01 P1 --frase "aprovo P1 da change 01"` (ou "da CHG-001")
- **ENTÃO** o status vira `Approved` e a linha P1 tem `via chat: "<frase>"`

#### Scenario: C2 — IA sem frase

- **DADO** a mesma change
- **QUANDO** a IA roda `sdd approve 01 P1` sem `--frase`
- **ENTÃO** sai `RECUSADO`, exit 1, sugerindo `--frase`, e o arquivo não muda

#### Scenario: C3 — Frase que não cita a aprovação, o portão ou a change

- **DADO** a mesma change
- **QUANDO** a frase não tem "aprov", não cita a change, cita outra change, tem só número solto ou número gigante
- **ENTÃO** sai `RECUSADO`, exit 1, e o arquivo não muda

#### Scenario: C4 — P2 por frase grava base_ref

- **DADO** uma change 01 em `Approved` com a linha P1 (inclusive no formato antigo) e a Análise preenchida
- **QUANDO** a IA roda `sdd approve 01 P2 --frase "aprovo P2 da change 01"`
- **ENTÃO** o status vira `In-Implementation`, `base_ref` recebe o HEAD e a linha P2 cita a frase

> Contrato: `sdd approve <NN> P1|P2 [--frase "<texto>"]` → `APROVADO` (exit 0) | `RECUSADO` (exit 1); função `Test-SddFraseAprovacao`.
> Testes: `SpecSimpleKit/tests/test_motor_aprovacao.ps1` (tags `SPEC-MOTOR-001/C1..C4`).

## Requisitos removidos

| ID | Change | Motivo |
|---|---|---|

## Histórico

| Change | Data | Efeito |
|---|---|---|
| CHG-002 | 16/10/2026 | ADDED SPEC-MOTOR-001 (aprovação por frase no chat) |
