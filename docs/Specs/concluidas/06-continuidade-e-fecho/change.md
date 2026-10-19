---
id: CHG-006
title: Continuidade automatica do fluxo SDD
status: Done
capabilities: [fluxo]
risk: [portao-humano, arquivo-do-usuario]
fonte_normativa:
base_ref: 8d1832f0cc937c93a48d8650b40788d972acbe96
impact:
  modified_files: [SpecSimpleKit/kernel/tools/sdd/sdd.ps1, SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md, SpecSimpleKit/kernel/.agents/rules/sdd-core.md, SpecSimpleKit/kernel/.agents/skills/backlog-refinement/SKILL.md, SpecSimpleKit/kernel/.agents/skills/sdd-verify/SKILL.md, SpecSimpleKit/kernel/.claude/skills/learn/SKILL.md, SpecSimpleKit/docs/como-usar-fluxo.md, SpecSimpleKit/tests/test_motor_regressao.ps1, SpecSimpleKit/tests/run_all.ps1, SpecSimpleKit/CHANGELOG.md, SpecSimpleKit/README.md, README.md, tools/sdd/sdd.ps1, .agents/rules/sdd-fluxo.md, spec_driven_development.md]
  new_files: [SpecSimpleKit/tests/test_fluxo_continuidade.ps1, tools/push-kit.ps1, docs/spec_driven_development.md]
---

# CHG-006 — Continuidade automatica do fluxo SDD

> **Origem:** `origem/06 - Ideias do fluxo do PDV D+.md`. **Regra:** `.agents/rules/sdd-fluxo.md`.
> `SPEC-FLUXO-001` permanece reservado para esta change.
> O archive pelo motor depende de CHG-007; concluir CHG-007 primeiro.

## Por quê

O fluxo deve seguir entre decisões já autorizadas e parar apenas nos portões,
perguntas que mudam o resultado, bloqueios reais e no commit. Uma change inteira
é aprovada e verificada como unidade; cenários e
tasks organizam cobertura e trabalho, sem portões de aprovação individuais.

## Perguntas em aberto

<!-- Vazia: as decisões abaixo fecham o escopo proposto para P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | Executar U1 primeiro; U2/U3 ficam para depois. Ideias 4, 7, 10 e 11 ficam fora desta change. | Resposta do usuário ao recorte do item 06 | 18/10/2026 |
| D2 | Depois de GOAL PASS final, solicitar archive pelo comando disponível, validar a árvore final e entregar texto de commit; parar antes de commit/push/merge.  | Fala do usuário no levantamento da origem | 16/10/2026 |
| D3 | Pronto abre a change; P0, P1 e P2 aprovam as fases da change inteira, sem aprovação por requisito individual ou task isolada. | Instrução do usuário nesta conversa | 18/10/2026 |
| D4 | Limites normais por change: até 2 capacidades diretamente relacionadas, 4 requisitos, 12 cenários e cerca de 20 arquivos alterados ou criados no produto, incluindo regras, skills, motor, guia e testes. O `change.md` normalmente fica até 400 linhas, sem contar origem, ledger e relatórios. São limites de revisão, não cotas rígidas: exceder exige justificar coesão e validação no P1; dividir quando houver entregas independentes, risco isolável ou sequência que possa ser aprovada/implementada separadamente. Specs vivas não têm limite de extensão; artefatos gerados, cópias instaladas, lockfiles e índices não contam no número de arquivos, mas mudanças de contrato e IDs continuam documentadas. | Ajuste autorizado pelo usuário após discutir proporcionalidade para trabalho de agentes de IA | 18/10/2026 |
| D5 | RED/GREEN podem cobrir vários cenários numa única execução por suíte. A cobertura segue rastreável por tag; não há validate, revisão humana ou aprovação por item. Validate, verificação independente e goal rodam para a change completa. O motor exige cobertura RED/GREEN agregada para todas as tags. | Instrução do usuário; comportamento atual do goal em `sdd.ps1` | 18/10/2026 |
| D6 | Mudança de regra aceita revisão de código e segurança proporcional ao risco; quando faltar ferramenta nativa, aplica-se o procedimento manual e registram-se limites. | Levantamento da origem; `.agents/rules/sdd-revisao.md` | 18/10/2026 |
| D7 | Learn ao fechar encaminha pendências e apresenta propostas de regra/upstream; não aplica regra nem escreve memória fora da autorização/política do ambiente. | Instrução e decisão de fecho registradas na origem | 18/10/2026 |
| D8 | Reset manual único, autorizado pelo usuário, de `In-Implementation` para `Draft`, com `base_ref` e aprovações antigas removidos por obsolescência do escopo anterior. | Autorização explícita do usuário nesta conversa | 18/10/2026 |
| D9 | A governança SDD adota a sequência de 3 portões: P0 (Tema do plano / intenção e limites), P1 (Clarificação / especificação funcional e cenários BDD) e P2 (Change técnica e tasks). O motor aceita P0 gravando a linha em Aprovacoes sem alterar o status Draft; P1 move para Approved (exige perguntas vazias); P2 move para In-Implementation com base_ref. | Instrução do usuário nesta conversa para alinhamento canônico ao SDD | 18/10/2026 |

## Contratos

- Item Pronto, sem perguntas e dentro dos limites: abrir change Draft automaticamente e conduzir até P0/P1.
- P0 aprova o Tema do Plano (problema, objetivo e limites do que NÃO fazer). O motor aceita `sdd approve NN P0 --frase`, registrando a aprovação e mantendo o status em `Draft`.
- P1 aprova a Clarificação e Especificação (cenários BDD e `Perguntas em aberto` vazias). O motor aceita `sdd approve NN P1 --frase`, registrando a aprovação e movendo o status para `Approved`.
- P2 aprova a Change técnica, plano e tasks completas. O motor aceita `sdd approve NN P2 --frase`, registrando a aprovação, movendo o status para `In-Implementation` e fixando `base_ref`.
- Pós-P2: implementação contínua até o fecho. O motor aceita uma RED e uma GREEN por alvo/suíte, cada execução listando todas as tags cobertas; cada assert/teste mantém `SPEC-.../Cn`. RED deve falhar por asserção.
- Fecho único: revisão de código e segurança proporcional, validate, verificação independente e goal. Archive via CHG-007 é dependência; learn é uma passagem única sobre a change completa no fecho.
- Depois do archive: validate da árvore final, texto de commit e parada. Learn ocorre uma vez para a change completa. A IA não executa commit, push ou merge.
- Falha, achado que muda código ou edição após veredito interrompe archive e exige corrigir a change e reexecutar os gates da árvore completa.

## Invariantes

- `portao-humano`: só o usuário aprova P0/P1/P2 com frase que cita aprovação, portão e change; status, base_ref e aprovações são gravados pelo motor.
- `arquivo-do-usuario`: conteúdo do usuário e origem permanecem preservados; conflito interrompe a integração sem sobrescrever.

## Deltas — capacidade `fluxo`

### ADDED Requirements

#### Requirement: SPEC-FLUXO-001 — Continuidade e ciclo de portões P0, P1 e P2

O fluxo DEVE avançar entre passos autorizados, oferecer os portões P0 (Tema do plano), P1 (Clarificação) e P2 (Change e tasks), e validar a mudança como unidade depois do GOAL PASS e da verificação independente.

##### Scenario: C1 — P0 aprova o Tema do Plano

- **DADO** uma change Draft recém-aberta com tema, problema, objetivo e limites definidos
- **QUANDO** o usuário aprova P0 da change com a frase canônica
- **ENTÃO** o motor grava a linha de aprovação P0 e mantém o status Draft para a fase de clarificação

##### Scenario: C2 — P1 aprova a Clarificação e Especificação

- **DADO** uma change Draft com perguntas em aberto vazias e cenários BDD formulados
- **QUANDO** o usuário aprova P1 da change com a frase canônica
- **ENTÃO** o motor valida as perguntas vazias, grava a linha P1 e move o status para Approved

##### Scenario: C3 — P2 aprova a Change técnica e Tasks

- **DADO** uma change Approved com análise pré-implementação preenchida e tasks agrupadas
- **QUANDO** o usuário aprova P2 da change com a frase canônica
- **ENTÃO** o motor grava a linha P2, fixa o base_ref e move o status para In-Implementation

##### Scenario: C4 — Trabalho contínuo em loop pós-P2

- **DADO** a change inteira aprovada em P2
- **QUANDO** a IA executa as tasks
- **ENTÃO** implementa em loop contínuo agrupando testes por suíte e fase, mantendo tags de cenário e executando revisão de código e segurança proporcional

##### Scenario: C5 — Uma verificação fecha a change

- **DADO** todas as tasks concluídas
- **QUANDO** validate, verificação independente e goal passam para a árvore integral da change
- **ENTÃO** apresenta archive como próxima ação, depois da execução valida a árvore final e entrega texto de commit; learn da change inteira ocorre uma vez no fecho

##### Scenario: C6 — Falha impede o fecho integral

- **DADO** falha em gate ou edição após o veredito
- **QUANDO** o fluxo tenta arquivar
- **ENTÃO** não arquiva; corrige a change completa e repete validação, verificação independente e goal

### MODIFIED Requirements

<!-- Nenhum requisito vivo anterior para fluxo. -->

### REMOVED Requirements

<!-- Nenhum. -->

## Critérios de aceite

- O motor aceita P0, P1 e P2 via `sdd approve <NN> P0|P1|P2 --frase "..."`.
- Uma única execução RED e GREEN pode cobrir C1..C6; o goal confirma a união das tags de cada execução.
- P0, P1 e P2 ocorrem uma vez cada por change, nunca por micro-requisito ou task isolada.
- Change segue os limites normais ou justifica excedentes por coesão, risco e validação integral. Archive segue a dependência CHG-007; learn considera a change inteira uma vez.
- `sdd validate`, verificador independente e `sdd goal 06` passam para a árvore integral.

## Análise pré-implementação

- **Unidade:** capacidade `fluxo`; seis cenários, um requisito e onze caminhos de produto no impacto (dez alterados e um teste novo), abaixo dos limites normais. Cópias gerenciadas ficam fora da contagem.
- **Dependência:** CHG-007 (`sdd archive`) concluída. Motor atualizado para suportar `P0` além de `P1` e `P2` em `Invoke-SddApprove` e `Test-SddFraseAprovacao`.
- **Cobertura:** o goal exige RED/GREEN agregados cobrindo C1..C6. Suporte a P0 no motor validado por testes de aprovação e regressão.
- **Segurança:** P0, P1 e P2 exigem frase do usuário; status e base_ref são protegidos; verificador segue independente.
- **Impacto:** os arquivos listados no `impact`, com atualização do kernel e propagação para as cópias locais.

## Tasks

- [x] RED (C1,C2,C3,C4,C5,C6): `SpecSimpleKit/tests/test_fluxo_continuidade.ps1` -> Testar suporte a P0, P1, P2 e cobertura agregada no motor
- [x] GREEN (C1,C2,C3,C4,C5,C6): `SpecSimpleKit/tests/test_fluxo_continuidade.ps1` -> Implementar P0 em approve, ajustar sdd-fluxo.md e validar suíte
- [x] REFACTOR: Alinhar mensagens de ajuda e documentação do fluxo | fluxo consistente

### Pós-GOAL

- [ ] Após archive, execute validate final, faça uma passagem learn da change completa e apresente texto de commit.

## Exceções

<!-- Nenhuma. -->

## Aprovações

<!-- Reset manual autorizado. Nova aprovação P0/P1/P2 será registrada pelo motor para o escopo revisto. -->
- P1: aprovado por Thander em 2026-10-19 00:02 (sdd approve; via chat: "aprovo P1 da change 06"; change.md antes: 481e71f5d237)
- P2: aprovado por Thander em 2026-10-19 00:05 (sdd approve; via chat: "aprovo P2 da change 06"; change.md antes: 11afd9f2f45b)
