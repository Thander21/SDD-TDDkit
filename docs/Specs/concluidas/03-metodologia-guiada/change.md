---
id: CHG-003
title: Metodologia documentada e guiada
status: Done
capabilities: [fluxo]
risk: [contrato-do-motor]
fonte_normativa:
base_ref: df162c68d8bca18f2c9343ce013e4740ba3e3dd7
impact:
  modified_files: [README.md, SpecSimpleKit/docs/como-usar-fluxo.md, docs/Specs/capabilities/_index.md, tests/run_all.ps1]
  new_files: [docs/Specs/capabilities/fluxo/spec.md, tests/test_fluxo_metodologia.ps1]
---

# CHG-003 — Metodologia documentada e guiada

> **Origem:** `origem/03 - Metodologia documentada e guiada.md` (movido do backlog). **Regra:** `.agents/rules/sdd-fluxo.md`.
> Títulos lidos pelo motor (não renomeie): Perguntas em aberto, Análise
> pré-implementação, Tasks, Pós-GOAL, Exceções, Aprovações. `status`,
> `base_ref` e Aprovações são gravados só pelo `sdd approve` do usuário.

## Por quê

O SpecSimpleKit foi desenhado para ser acessível tanto a desenvolvedores quanto a leigos e pessoas sem conhecimento aprofundado de desenvolvimento ou metodologias ágeis (origem, fala de 12/10/2026). O fluxo de trabalho deve ser 100% conversacional pelo chat da IA, sem exigência de rodar comandos de terminal.

Para isso, o kit precisa de documentação canônica, didática e viva da sua metodologia:
1. Formalizar a união de SDD (Spec-Driven Development) + TDD (Test-Driven Development) com cenários BDD (`DADO/QUANDO/ENTÃO`) e práticas de Extreme Programming (XP: feedback rápido, passos atômicos, refatoração contínua);
2. Estruturar formalmente o **Ciclo dos 4 Artefatos**:
   - **Constitution:** regras invariantes permanentes e anti-padrões (`AGENTS.md` e `.agents/rules/`);
   - **Specification:** o que e por quê, sem stack, critérios mensuráveis e cenários BDD no `change.md`;
   - **Technical Plan:** como, arquitetura, modelo de dados, riscos e dependências no `change.md`;
   - **Tasks:** atômicas, rastreáveis e verificáveis no `change.md`.
3. Detalhar o loop de execução autônoma da IA pós-P2 até o fecho com salvaguardas (parada em 3 falhas, verificação independente);
4. Oferecer um guia conversacional de chat claro ("O que você escreve no chat" ➔ "Ação da IA" ➔ "Validação do motor").

## Perguntas em aberto

<!-- Vazia = pode pedir o P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | Documentação canônica centralizada no repositório do kit em `SpecSimpleKit/docs/como-usar-fluxo.md` e referenciada no `README.md`, sem copiar arquivos adicionais para cada projeto instalado. | usuário, 19/10/2026 (resposta 1) | 19/10/2026 |
| D2 | O ciclo dos 4 artefatos fica documentado explicitamente: Constitution (`AGENTS.md` e `.agents/rules/`), Specification, Technical Plan e Tasks integrados em `change.md` sob aprovação de P1 e P2. | usuário, 18/10/2026 | 19/10/2026 |
| D3 | Guia de conversação para não-desenvolvedores: mapeamento canônico de todas as etapas do fluxo para comandos no chat, garantindo que o usuário só precise conversar. | usuário, 12/10/2026 e 14/10/2026 | 19/10/2026 |
| D4 | Preservação do orçamento de regras gerenciadas: a documentação para humanos fica fora de `.agents/rules/`, sem inflar o contexto da IA nem estourar os 40 KB (D9 da CHG-002 e Regras de Manutenção 2). | D9 da CHG-002; README.md:110-112 | 19/10/2026 |

## Contratos

- **Estrutura dos 4 Artefatos:**
  1. *Constitution*: Define limites permanentes. Não pode ser modificada por iniciativa da IA.
  2. *Specification*: Define o escopo funcional e comportamental através de cenários BDD (`DADO/QUANDO/ENTÃO`). Aprovada no Portão P1.
  3. *Technical Plan*: Define a arquitetura técnica, impact, riscos e decisões. Aprovado no Portão P2.
  4. *Tasks*: Decomposição atômica do trabalho com rastreabilidade `SPEC-<DOM>-NNN/Cn`. Aprovada no Portão P2.
- **Loop Autônomo Pós-P2:**
  - A IA avança de forma contínua no TDD (RED ➔ GREEN ➔ REFACTOR) para cada task/suíte.
  - Salvaguardas: 3 falhas consecutivas no mesmo critério interrompem o loop e devolvem a decisão ao usuário; fecho exige verificação independente (`sdd-verify`).

## Invariantes

- `contrato-do-motor`: formato de `change.md`, `evidence.jsonl`, `kit.lock.json`, marcadores `sdd-kit:begin/end` e saída do `goal` permanecem 100% compatíveis; nenhuma alteração quebra projetos existentes.

## Deltas — capacidade fluxo

### ADDED Requirements

#### Requirement: SPEC-FLUXO-002 — Metodologia canônica e fluxo conversacional

O SpecSimpleKit DEVE documentar de forma canônica a metodologia SDD + TDD + BDD + XP com o ciclo dos 4 artefatos e o guia conversacional de chat para leigos e desenvolvedores.

##### Scenario: C1 — Documentação dos 4 artefatos e XP no guia do kit

- **DADO** o repositório do kit com a documentação em `SpecSimpleKit/docs/como-usar-fluxo.md`
- **QUANDO** o usuário ou a IA consulta a documentação
- **ENTÃO** encontra descritos explicitamente os 4 artefatos (Constitution, Specification, Technical Plan, Tasks), os princípios de XP (feedback rápido, TDD, refactoring contínuo) e o loop autônomo pós-P2 com salvaguardas.

##### Scenario: C2 — Guia de comandos conversacionais do chat para não-devs

- **DADO** um usuário não-desenvolvedor interagindo exclusivamente pelo chat da IA
- **QUANDO** ele precisa avançar entre as fases do ciclo de desenvolvimento
- **ENTÃO** encontra a tabela completa de frases de comando no chat ("refine o item NN", "aprovo P1 da change NN", "aprovo P2 da change NN", "verifique a change NN", "arquive a change NN") com a respectiva ação da IA e validação do motor.

##### Scenario: C3 — Referências e rastreabilidade no README e registro de capacidades

- **DADO** o arquivo `README.md` e o registro `capabilities/_index.md`
- **QUANDO** o usuário ou a IA busca a visão geral do kit
- **ENTÃO** encontra a tabela de fluxo atualizada com os links canônicos para `SpecSimpleKit/docs/como-usar-fluxo.md` e o ID `SPEC-FLUXO-002` registrado com rastreabilidade na spec viva `capabilities/fluxo/spec.md`.

### MODIFIED Requirements

### REMOVED Requirements

## Critérios de aceite

- Todos os cenários com teste rastreado (tag `SPEC-FLUXO-002/Cn`) passando.
- Guia `SpecSimpleKit/docs/como-usar-fluxo.md` expandido e consolidado com os 4 artefatos, XP, BDD e tabela conversacional.
- `README.md` atualizado com referências diretas à documentação e ao ciclo dos 4 artefatos.
- `docs/Specs/capabilities/fluxo/spec.md` criada com a spec viva da capacidade `fluxo` cobrindo `SPEC-FLUXO-002`.
- `sdd check` verde; `sdd validate` verde; `sdd goal 03` = `GOAL PASS`.

## Análise pré-implementação

- **Rastreabilidade de Cenários:**
  - `SPEC-FLUXO-002/C1` (4 artefatos e XP) ➔ coberto por teste em `tests/test_fluxo_metodologia.ps1` e documentação em `SpecSimpleKit/docs/como-usar-fluxo.md`.
  - `SPEC-FLUXO-002/C2` (comandos conversacionais de chat) ➔ coberto por teste em `tests/test_fluxo_metodologia.ps1` e tabela em `SpecSimpleKit/docs/como-usar-fluxo.md`.
  - `SPEC-FLUXO-002/C3` (links no README e spec viva de fluxo) ➔ coberto por teste em `tests/test_fluxo_metodologia.ps1`, `README.md` e `docs/Specs/capabilities/fluxo/spec.md`.
- **Cerca de Impacto:** Todos os 4 arquivos modificados e 2 arquivos novos estão declarados no `impact`. Nenhum arquivo fora do escopo será tocado.
- **Invariantes e Riscos:** `contrato-do-motor` preservado; nenhum gate, formato de lock ou marcador foi alterado. Regras de manutenção 2 (orçamento <= 40 KB) respeitadas integralmente ao manter o manual em `SpecSimpleKit/docs/`.

## Tasks

- [x] RED (C1): tests/test_fluxo_metodologia.ps1 -> Falha esperada: assercoes de conteudo dos 4 artefatos e XP falham em como-usar-fluxo.md
- [x] GREEN (C1): tests/test_fluxo_metodologia.ps1 -> passou
- [x] RED (C2): tests/test_fluxo_metodologia.ps1 -> Falha esperada: tabela de comandos conversacionais do chat incompleta
- [x] GREEN (C2): tests/test_fluxo_metodologia.ps1 -> passou
- [x] RED (C3): tests/test_fluxo_metodologia.ps1 -> Falha esperada: falta referencia no README e spec viva da capacidade fluxo
- [x] GREEN (C3): tests/test_fluxo_metodologia.ps1 -> passou
- [x] REFACTOR: revisao ortografica e alinhamento visual da documentacao sem alterar regras gerenciadas

### Pós-GOAL

- [ ] Archive (a pedido do usuário): deltas na spec viva em `capabilities/fluxo/spec.md`, `git mv` para `concluidas/`, `status: Done`

## Exceções

<!-- Só o usuário aceita, com prazo. Não vazia = a change não fecha. -->

## Aprovações

<!-- Gravado só pelo 'sdd approve NN P1|P2' (frase do usuário ou terminal dele). -->
- P1: aprovado por Thander em 2026-10-19 12:57 (sdd approve; via chat: "aprovo P1 da change 03"; change.md antes: 33e46c9ee0ac)
- P2: aprovado por Thander em 2026-10-19 13:01 (sdd approve; via chat: "aprovo P2 da change 03"; change.md antes: eab687957439)
