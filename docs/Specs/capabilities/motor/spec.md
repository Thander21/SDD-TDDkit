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
se contém "aprov", o portão (P0, P1 ou P2) e estritamente a change alvo colada a
"change" ou "CHG" ("change 02", "CHG-002"); número solto é ignorado, citar
outra change recusa, e tokens colados ou não numéricos pós-"change"/"CHG" recusam.
O `$NN` e as citações são comparados como texto normalizado sem zeros à esquerda,
sem estouro por coerção inteira.

#### Scenario: C1 — Frase válida pela IA

- **DADO** uma change 01 em `Draft` com perguntas em aberto vazias e a IA chamando
- **QUANDO** a IA roda `sdd approve 01 P1 --frase "aprovo P1 da change 01"` (ou "da CHG-001")
- **ENTÃO** o status vira `Approved` e a linha P1 tem `via chat: "<frase>"`

#### Scenario: C2 — IA sem frase

- **DADO** a mesma change
- **QUANDO** a IA roda `sdd approve 01 P1` sem `--frase`
- **ENTÃO** sai `RECUSADO`, exit 1, sugerindo `--frase`, e o arquivo não muda

#### Scenario: C3 — Frase que não cita a aprovação, o portão ou a change

- **DADO** uma change 01 e a IA chamando com `--frase`
- **QUANDO** a frase não tem "aprov", não cita a change, cita outra change (mesmo com sufixo ou dígito não ASCII como "change 03x" ou "change ٣"), tem só número solto, ou traz número gigante na linha de comando / frase
- **ENTÃO** sai `RECUSADO`, exit 1 (sem ERRO/exceção), e o arquivo não muda

#### Scenario: C4 — P2 por frase grava base_ref

- **DADO** uma change 01 em `Approved` com a linha P1 (inclusive no formato antigo) e a Análise preenchida
- **QUANDO** a IA roda `sdd approve 01 P2 --frase "aprovo P2 da change 01"`
- **ENTÃO** o status vira `In-Implementation`, `base_ref` recebe o HEAD e a linha P2 cita a frase

> Contrato: `sdd approve <NN> P0|P1|P2 [--frase "<texto>"]` → `APROVADO` (exit 0) | `RECUSADO` (exit 1); função `Test-SddFraseAprovacao`.
> Testes: `tests/test_motor_aprovacao.ps1` (tags `SPEC-MOTOR-001/C1..C4`).

### Requirement: SPEC-MOTOR-002 — Archive guardado por goal, verify e árvore atual

O motor DEVE mover uma change para `concluidas/` e gravar `Done` somente se
houver GOAL PASS final e `verify.md` APROVADO para o mesmo valor `arvore`
retornado por `Get-SddArvore` na chamada. Recusa ou falha preserva os arquivos.

#### Scenario: C1 — Sem GOAL PASS final

- **DADO** change em implementação sem goal, com GOAL FAIL, só pre-verify ou verify ausente/reprovado
- **QUANDO** roda `sdd archive NN`
- **ENTÃO** recusa e mantém status e árvore da change inalterados

#### Scenario: C2 — GOAL PASS e verificação independentes na mesma árvore

- **DADO** change em implementação cujo último goal é GOAL PASS e cujo verify.md é APROVADO para o mesmo valor `arvore` calculado na chamada
- **QUANDO** roda `sdd archive NN` e o destino não existe
- **ENTÃO** o motor grava Done e move a pasta completa para `concluidas/`

#### Scenario: C3 — GOAL PASS desatualizado

- **DADO** GOAL PASS registrado e valor `arvore` diferente do valor calculado agora pelo motor
- **QUANDO** roda `sdd archive NN`
- **ENTÃO** recusa sem mover nem alterar a change

#### Scenario: C4 — Destino existente ou erro de preparação

- **DADO** uma change elegível e destino preexistente, ou falha ao preparar a movimentação
- **QUANDO** roda `sdd archive NN`
- **ENTÃO** recusa sem sobrescrever destino e, em caso de falha, restaura status e caminho originais

#### Scenario: C5 — Update mantém comandos existentes e acrescenta archive

- **DADO** um projeto instalado antes de existir o comando archive
- **QUANDO** roda `check` e `goal`, depois recebe update aditivo
- **ENTÃO** `check` e `goal` continuam reconhecidos e o comando `archive` fica disponível

## Requisitos removidos

| ID | Change | Motivo |
|---|---|---|

## Histórico

| Change | Data | Efeito |
|---|---|---|
| CHG-002 | 16/10/2026 | ADDED SPEC-MOTOR-001 (aprovação por frase no chat) |
| CHG-007 | 18/10/2026 | ADDED SPEC-MOTOR-002 (archive guardado por goal, verify e árvore atual) |
| CHG-008 | 19/10/2026 | MODIFIED SPEC-MOTOR-001 (endurecimento da frase de aprovação contra tokens espúrios e overflow) |
