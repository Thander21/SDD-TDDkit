---
id: CHG-NNN
title: <título curto>
status: Draft
capabilities: []
risk: []
fonte_normativa:
base_ref:
impact:
  modified_files: []
  new_files: []
---

# CHG-NNN — <título>

> **Origem:** `origem/<item do backlog>.md` (movido do backlog). **Regra:** `.agents/rules/sdd-fluxo.md`.
> Títulos lidos pelo motor (não renomeie): Perguntas em aberto, Análise
> pré-implementação, Tasks, Pós-GOAL, Exceções, Aprovações. `status`,
> `base_ref` e Aprovações são gravados só pelo `sdd approve` do usuário.

## Por quê

<Valor e problema: o que dá errado hoje, para quem.>

## Perguntas em aberto

<!-- Só o que muda o resultado: regra, contrato, fonte normativa, escopo.
Cada resposta sai daqui e vira linha D<n>. Vazia = pode pedir o P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|

## Contratos

<Tipos e interfaces reais; desfecho tipado da operação com todas as variantes
(idioma em `erro_idioma` do perfil); o que fica exposto.>

## Invariantes

<!-- Só as linhas das tags de risk declaradas, vindas da seção Riscos do
AGENTS.md. Faltou tag? Acrescente a tag. -->

## Deltas — capacidade `<capacidade>`

### ADDED Requirements

#### Requirement: SPEC-<DOM>-NNN — <nome>

O sistema DEVE <comportamento observável>.

##### Scenario: C1 — <nome>

- **DADO** <pré-condição>
- **QUANDO** <ação>
- **ENTÃO** <resultado observável>

<!-- Um cenário por variante do desfecho e os cenários obrigatórios das tags
de risco. ID reservado no _index.md. -->

### MODIFIED Requirements

<!-- Reescreva o bloco inteiro do requisito existente, com todos os cenários. -->

### REMOVED Requirements

<!-- ID e motivo, em uma linha. -->

## Comportamento que não muda

<!-- Só em bugfix: cada item com um cenário de regressão. Remova nas demais. -->

## Critérios de aceite

- Todos os cenários com teste rastreado (tag `SPEC-<DOM>-NNN/Cn`) passando.
- `sdd validate` verde; `sdd goal NN` = `GOAL PASS`.
- <aceite de negócio testável; manual só se não for automatizável, até 4 passos>

## Análise pré-implementação

<!-- Etapa 5, só feature, até 10 linhas: cenário sem task, task sem cenário,
task fora do impact, arquivo do impact sem task, invariante sem cenário,
variante sem cenário, caminho inexistente, fonte normativa. Preenchida =
pode pedir o P2. -->

## Tasks

<!-- Uma task por vez. RED e GREEN só depois de rodar 'sdd test <alvo>'; o alvo
é a string exata passada ao sdd test. O goal exige RED e GREEN com lastro para
cada 'Scenario: Cn' dos deltas. Cenário que só se prova à mão (hardware,
sensação de jogo): '- [x] MANUAL (Cn): <roteiro de até 4 passos> -> verificado
por <quem>' (fica listado como não verificado por máquina). -->

- [ ] RED (C1): <alvo> -> Falha esperada: <asserção>
- [ ] GREEN (C1): <alvo> -> passou
- [ ] REFACTOR: <o que mudou> | nada: <motivo> (alvo re-rodado)

### Pós-GOAL

<!-- O goal ignora esta subseção. Fecho = sdd validate verde -> sdd-verify
(verify.md APROVADO) -> sdd goal NN = GOAL PASS; só então o archive. -->

- [ ] Archive (a pedido do usuário): deltas na spec viva, `git mv` para `concluidas/`, `status: Done`

## Exceções

<!-- Só o usuário aceita, com prazo. Não vazia = a change não fecha. -->

## Aprovações

<!-- Gravado só pelo 'sdd approve NN P1|P2' (frase do usuário ou terminal dele). -->
