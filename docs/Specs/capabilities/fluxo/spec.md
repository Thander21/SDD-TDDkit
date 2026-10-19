# fluxo

> **Domínio:** `FLUXO` · **Origem no código:** `SpecSimpleKit/kernel/.agents/`, `SpecSimpleKit/kernel/.claude/`, `SpecSimpleKit/docs/como-usar-fluxo.md`.
> Este arquivo descreve o comportamento **atual**. Só muda no archive de uma
> change, pelos deltas dela. Cabeçalhos no formato do OpenSpec (Purpose,
> Requirements, Requirement, Scenario) para a validação externa continuar possível.

## Purpose

Metodologia de desenvolvimento spec-driven guiada e conversacional pelo chat: ciclo dos 4 artefatos (Constitution, Specification, Technical Plan, Tasks), fluxo SDD + TDD com BDD e XP, loop autônomo com salvaguardas e portões humanos de controle.

## Requirements

### Requirement: SPEC-FLUXO-002 — Metodologia canônica e fluxo conversacional

O SpecSimpleKit DEVE documentar de forma canônica a metodologia SDD + TDD + BDD + XP com o ciclo dos 4 artefatos e o guia conversacional de chat para leigos e desenvolvedores.

#### Scenario: C1 — Documentação dos 4 artefatos e XP no guia do kit

- **DADO** o repositório do kit com a documentação em `SpecSimpleKit/docs/como-usar-fluxo.md`
- **QUANDO** o usuário ou a IA consulta a documentação
- **ENTÃO** encontra descritos explicitamente os 4 artefatos (Constitution, Specification, Technical Plan, Tasks), os princípios de XP (feedback rápido, TDD, refactoring contínuo) e o loop autônomo pós-P2 com salvaguardas.

#### Scenario: C2 — Guia de comandos conversacionais do chat para não-devs

- **DADO** um usuário não-desenvolvedor interagindo exclusivamente pelo chat da IA
- **QUANDO** ele precisa avançar entre as fases do ciclo de desenvolvimento
- **ENTÃO** encontra a tabela completa de frases de comando no chat ("refine o item NN", "aprovo P1 da change NN", "aprovo P2 da change NN", "verifique a change NN", "arquive a change NN") com a respectiva ação da IA e validação do motor.

#### Scenario: C3 — Referências e rastreabilidade no README e registro de capacidades

- **DADO** o arquivo `README.md` e o registro `capabilities/_index.md`
- **QUANDO** o usuário ou a IA busca a visão geral do kit
- **ENTÃO** encontra a tabela de fluxo atualizada com os links canônicos para `SpecSimpleKit/docs/como-usar-fluxo.md` e o ID `SPEC-FLUXO-002` registrado com rastreabilidade na spec viva `capabilities/fluxo/spec.md`.
