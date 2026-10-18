---
id: CHG-006
title: Continuidade automatica do fluxo SDD
status: Draft
capabilities: [fluxo]
risk: [portao-humano, arquivo-do-usuario]
fonte_normativa:
base_ref:
impact:
  modified_files: [SpecSimpleKit/kernel/tools/sdd/sdd.ps1, SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md, SpecSimpleKit/kernel/.agents/rules/sdd-core.md, SpecSimpleKit/kernel/.agents/skills/backlog-refinement/SKILL.md, SpecSimpleKit/kernel/.agents/skills/sdd-verify/SKILL.md, SpecSimpleKit/kernel/.claude/skills/learn/SKILL.md, SpecSimpleKit/docs/como-usar-fluxo.md, SpecSimpleKit/tests/test_motor_regressao.ps1, SpecSimpleKit/tests/run_all.ps1, SpecSimpleKit/CHANGELOG.md]
  new_files: [SpecSimpleKit/tests/test_fluxo_continuidade.ps1]
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
| D3 | Pronto abre a change; P1 e P2 aprovam o documento e o plano da change inteira, sem aprovação por requisito ou task. | Instrução do usuário nesta conversa | 18/10/2026 |
| D4 | Limites normais por change: até 2 capacidades diretamente relacionadas, 4 requisitos, 12 cenários e cerca de 20 arquivos alterados ou criados no produto, incluindo regras, skills, motor, guia e testes. O `change.md` normalmente fica até 400 linhas, sem contar origem, ledger e relatórios. São limites de revisão, não cotas rígidas: exceder exige justificar coesão e validação no P1; dividir quando houver entregas independentes, risco isolável ou sequência que possa ser aprovada/implementada separadamente. Specs vivas não têm limite de extensão; artefatos gerados, cópias instaladas, lockfiles e índices não contam no número de arquivos, mas mudanças de contrato e IDs continuam documentadas. | Ajuste autorizado pelo usuário após discutir proporcionalidade para trabalho de agentes de IA | 18/10/2026 |
| D5 | RED/GREEN podem cobrir vários cenários numa única execução por suíte. A cobertura segue rastreável por tag; não há validate, revisão humana ou aprovação por item. Validate, verificação independente e goal rodam para a change completa. O motor exige cobertura RED/GREEN agregada para todas as tags. | Instrução do usuário; comportamento atual do goal em `sdd.ps1` | 18/10/2026 |
| D6 | Mudança de regra aceita revisão de código e segurança proporcional ao risco; quando faltar ferramenta nativa, aplica-se o procedimento manual e registram-se limites. | Levantamento da origem; `.agents/rules/sdd-revisao.md` | 18/10/2026 |
| D7 | Learn ao fechar encaminha pendências e apresenta propostas de regra/upstream; não aplica regra nem escreve memória fora da autorização/política do ambiente. | Instrução e decisão de fecho registradas na origem | 18/10/2026 |
| D8 | Reset manual único, autorizado pelo usuário, de `In-Implementation` para `Draft`, com `base_ref` e aprovações antigas removidos por obsolescência do escopo anterior. | Autorização explícita do usuário nesta conversa | 18/10/2026 |

## Contratos

- Item Pronto, sem perguntas e dentro dos limites: abrir change Draft automaticamente e seguir até apresentar P1. Os limites são presunção de revisão simples; excedentes são aceitos com justificativa no P1 quando a mudança for coesa e tiver um único resultado verificável.
- Um P1 aprova a especificação completa; depois a IA completa plano, tasks e análise e apresenta um P2 para o documento completo. O fluxo do projeto reserva IDs de requisitos no índice após P1 e antes de P2.
- Um P2 libera toda a implementação da change. O motor aceita uma RED e uma GREEN por alvo/suíte, cada execução listando todas as tags cobertas; cada assert/teste mantém `SPEC-.../Cn`. RED deve falhar por asserção.
- Fecho único: revisão de código e segurança proporcional, validate, verificação independente e goal. Archive via CHG-007 é dependência; learn é uma passagem única sobre a change completa no fecho.
- Depois do archive: validate da árvore final, texto de commit e parada. Learn ocorre uma vez para a change completa. A IA não executa commit, push ou merge.
- Falha, achado que muda código ou edição após veredito interrompe archive e exige corrigir a change e reexecutar os gates da árvore completa.

## Invariantes

- `portao-humano`: só o usuário aprova P1/P2 com frase que cita aprovação, portão e change; status, base_ref e aprovações são gravados pelo motor.
- `arquivo-do-usuario`: conteúdo do usuário e origem permanecem preservados; conflito interrompe a integração sem sobrescrever.

## Deltas — capacidade `fluxo`

### ADDED Requirements

#### Requirement: SPEC-FLUXO-001 — Continuidade e aprovação da change inteira

O fluxo DEVE avançar entre passos autorizados, apresentar um portão para cada
change completa e validar a mudança como unidade depois do GOAL PASS e da verificação independente.

##### Scenario: C1 — Pronto abre a change

- **DADO** um item refinado, sem perguntas e marcado Pronto pelo usuário
- **QUANDO** a IA recebe o item para continuar
- **ENTÃO** abre uma change Draft dentro dos limites e conduz o documento inteiro até P1 sem pedir comando separado para abrir

##### Scenario: C2 — P1 aprova o documento inteiro

- **DADO** uma change Draft com perguntas vazias
- **QUANDO** o usuário aprova P1 da change
- **ENTÃO** a IA registra uma aprovação para o documento completo, prepara plano, tasks e análise e para em P2, sem solicitar aprovação por requisito ou task

##### Scenario: C3 — P2 libera trabalho agrupado

- **DADO** a change inteira aprovada em P2
- **QUANDO** a IA executa as tasks
- **ENTÃO** agrupa testes por suíte e fase, mantém tags de cenário e executa revisão de código e segurança proporcional, com fallback manual documentado

##### Scenario: C4 — Uma verificação fecha a change

- **DADO** todas as tasks concluídas
- **QUANDO** validate, verificação independente e goal passam para a árvore integral da change
- **ENTÃO** apresenta archive como próxima ação, depois da execução valida a árvore final e entrega texto de commit; learn da change inteira ocorre uma vez no fecho

##### Scenario: C5 — Falha impede o fecho integral

- **DADO** falha em gate ou edição após o veredito
- **QUANDO** o fluxo tenta arquivar
- **ENTÃO** não arquiva; corrige a change completa e repete validação, verificação independente e goal

### MODIFIED Requirements

<!-- Nenhum requisito vivo anterior para fluxo. -->

### REMOVED Requirements

<!-- Nenhum. -->

## Critérios de aceite

- Uma única execução RED e GREEN pode cobrir C1..C5; o goal confirma a união das tags de cada execução.
- P1 e P2 ocorrem uma vez cada por change, nunca por requisito, cenário ou task.
- Change segue os limites normais ou justifica excedentes por coesão, risco e validação integral. Archive segue a dependência CHG-007; learn considera a change inteira uma vez.
- `sdd validate`, verificador independente e `sdd goal 06` passam para a árvore integral.

## Análise pré-implementação

- **Unidade:** capacidade `fluxo`; cinco cenários, um requisito e onze caminhos de produto no impacto (dez alterados e um teste novo), abaixo dos limites normais. Cópias gerenciadas ficam fora da contagem.
- **Dependência:** CHG-007 (`sdd archive`) deve estar concluída e instalada antes da implementação deste fluxo. Learn faz uma passagem única sobre a change completa no fechamento.
- **Cobertura:** o parser já aceita várias tags `Cn` numa linha, mas o goal atual requer RED/GREEN com lastro individual por cenário (`SpecSimpleKit/kernel/tools/sdd/sdd.ps1`, `Invoke-SddGoal`). Esta change altera o contrato para cobertura agregada por execução, mantendo tag por teste.
- **Segurança:** P1/P2 continuam com frase do usuário; verificador segue independente; learn não grava regra/memória sem base autorizada.
- **Impacto:** os dez caminhos listados no `impact`; cópias gerenciadas atualizadas após suíte verde com `install.ps1 update -Destino . -Forcar`.
- **Limites:** experiência real de cada IDE e obediência de modelos não são testadas por asserts de texto; o Verify Pass revisa o contrato completo e relata limitações.

## Tasks

- [ ] RED (C1,C2,C3,C4,C5): `SpecSimpleKit/tests/test_motor_regressao.ps1` -> Falha esperada: suíte marcada C1,C2 é rejeitada por falta de evidência separada para C2
- [ ] GREEN (C1,C2,C3,C4,C5): `SpecSimpleKit/tests/test_motor_regressao.ps1` -> suíte agregada passa e cobertura parcial continua reprovada
- [ ] REFACTOR: remover contradições na regra do projeto e no motor; conferir uma vez o conjunto completo | nada: fluxo consistente

### Pós-GOAL

- [ ] Após archive, execute validate final, faça uma passagem learn da change completa e apresente texto de commit.

## Exceções

<!-- Nenhuma. -->

## Aprovações

<!-- Reset manual autorizado. Nova aprovação P1/P2 será registrada pelo motor para o escopo revisto. -->
