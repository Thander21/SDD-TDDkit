---
id: CHG-007
title: Archive seguro pelo motor
status: Done
capabilities: [motor]
risk: [contrato-do-motor, portao-humano, arquivo-do-usuario]
fonte_normativa:
base_ref: cf9dd71d0527c8239fcd6652745210f91e9c09a5
impact:
  modified_files: [SpecSimpleKit/kernel/tools/sdd/sdd.ps1, SpecSimpleKit/tests/run_all.ps1, SpecSimpleKit/CHANGELOG.md, docs/Specs/capabilities/motor/spec.md, docs/Specs/capabilities/_index.md, tools/sdd/sdd.ps1, .sdd/kit.lock.json, SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md, SpecSimpleKit/kernel/.claude/skills/learn/SKILL.md, SpecSimpleKit/kernel/.agents/skills/sdd-verify/SKILL.md, SpecSimpleKit/kernel/.agents/rules/sdd-core.md, SpecSimpleKit/kernel/.agents/skills/backlog-refinement/SKILL.md, SpecSimpleKit/docs/como-usar-fluxo.md, SpecSimpleKit/tests/test_motor_regressao.ps1, .agents/rules/sdd-core.md, .agents/skills/backlog-refinement/SKILL.md, .agents/skills/sdd-verify/SKILL.md, spec_driven_development.md, .agents/rules/sdd-fluxo.md, .claude/skills/learn/SKILL.md, docs/Specs/changes/06-continuidade-e-fecho/change.md, docs/Specs/changes/06-continuidade-e-fecho/evidence.jsonl, docs/Specs/changes/06-continuidade-e-fecho/origem/06 - Ideias do fluxo do PDV D+.md, docs/Specs/backlog/06 - Ideias do fluxo do PDV D+.md]
  new_files: [SpecSimpleKit/tests/test_motor_archive.ps1, SpecSimpleKit/tests/test_fluxo_continuidade.ps1]
---

# CHG-007 — Archive seguro pelo motor

> **Origem:** `../06-continuidade-e-fecho/origem/06 - Ideias do fluxo do PDV D+.md`.
> **Regra:** `.agents/rules/sdd-fluxo.md`. Change de uma capacidade. As alterações
> compartilhadas com CHG-006 permanecem rastreadas no impact para que o goal
> avalie a árvore integral em sequência, sem duplicar aprovação da CHG-006.

## Por quê

O fluxo autoriza archive depois de GOAL PASS, mas o motor não tem comando para
mover a change e gravar `Done`. A edição manual de status conflita com a regra
de gravação protegida. Um comando do motor fecha essa lacuna sem enfraquecer os
portões humanos nem modificar arquivos fora da change.

## Perguntas em aberto

<!-- Vazia: comportamento proposto definido abaixo para revisão integral em P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | `sdd archive <NN>` só conclui a change quando há GOAL PASS final e verify.md APROVADO para o mesmo valor `arvore` calculado pelo motor. Goal ausente, falha, pre-verify ou valor divergente recusam sem mutação. | Necessidade identificada nesta conversa; regra de fecho SDD | 18/10/2026 |
| D2 | O motor grava `status: Done` e move a pasta para `concluidas/` como operação do working tree, sem alterar o índice ou criar commit. | Contrato de archive existente e fluxo de trabalho sem commit até o fim | 18/10/2026 |
| D3 | Destino existente ou erro de movimentação recusa e restaura o estado original; usa rename atômico de diretório para não sobrescrever destino concorrente; nenhum commit/push/merge. | Riscos `arquivo-do-usuario` e `portao-humano` | 18/10/2026 |
| D4 | O comando é aditivo: projeto legado mantém `check` e `goal` antes e depois do update, e passa a reconhecer `archive`. | Risco `contrato-do-motor` em `AGENTS.md` | 18/10/2026 |

## Contratos

- `sdd archive <NN>` aceita somente change em `In-Implementation` com último goal `GOAL PASS` (não pre-verify) e `verify.md` APROVADO. Ambos devem registrar o mesmo valor `arvore` retornado por `Get-SddArvore` na chamada.
- Com destino ausente, define `status: Done` pelo motor e move a pasta completa de `changes/NN-slug/` para `concluidas/NN-slug/`; reporte `ARCHIVED: <caminho>`, exit 0.
- Sem goal válido/atual, status incompatível, número ausente ou destino existente: `ERRO: ...`, exit 1 (uso inválido conforme motor); arquivos ficam byte a byte iguais.
- Se a preparação ou movimentação falhar, restaure status e caminho originais; não deixe cópia parcial. Conteúdo versionado, staged e não versionado permanece preservado sem sobrescrita.
- Não executa validate, verify, commit ou push: exige evidência já gravada pelo goal e pelo verificador; validate final vem depois do archive.

## Invariantes

- `contrato-do-motor`: projetos instalados anteriormente continuam passando `check` e `goal`; a capacidade nova chega pelo `update`, sem migração dos formatos existentes.
- `portao-humano`: archive não aprova P1/P2 e só consome GOAL PASS final produzido após portões e verificação independente.
- `arquivo-do-usuario`: arquivo/caminho de destino preexistente nunca é sobrescrito; erro não deixa alteração parcial.

## Deltas — capacidade `motor`

### ADDED Requirements

#### Requirement: SPEC-MOTOR-002 — Archive guardado por goal, verify e árvore atual

O motor DEVE mover uma change para `concluidas/` e gravar `Done` somente se
houver GOAL PASS final e `verify.md` APROVADO para o mesmo valor `arvore`
retornado por `Get-SddArvore` na chamada. Recusa ou falha preserva os arquivos.

ID `SPEC-MOTOR-002` reservado em `capabilities/_index.md` após P1.

##### Scenario: C1 — Sem GOAL PASS final

- **DADO** change em implementação sem goal, com GOAL FAIL, só pre-verify ou verify ausente/reprovado
- **QUANDO** roda `sdd archive NN`
- **ENTÃO** recusa e mantém status e árvore da change inalterados

##### Scenario: C2 — GOAL PASS e verificação independentes na mesma árvore

- **DADO** change em implementação cujo último goal é GOAL PASS e cujo verify.md é APROVADO para o mesmo valor `arvore` calculado na chamada
- **QUANDO** roda `sdd archive NN` e o destino não existe
- **ENTÃO** o motor grava Done e move a pasta completa para `concluidas/`

##### Scenario: C3 — GOAL PASS desatualizado

- **DADO** GOAL PASS registrado e valor `arvore` diferente do valor calculado agora pelo motor
- **QUANDO** roda `sdd archive NN`
- **ENTÃO** recusa sem mover nem alterar a change

##### Scenario: C4 — Destino já existe

- **DADO** uma change elegível e uma pasta `concluidas/NN-slug` preexistente
- **QUANDO** roda `sdd archive NN`
- **ENTÃO** recusa e preserva source e destination byte a byte

##### Scenario: C5 — Update mantém comandos existentes e acrescenta archive

- **DADO** um projeto instalado antes de existir o comando archive
- **QUANDO** roda `check` e `goal`, depois recebe update aditivo
- **ENTÃO** `check` e `goal` continuam reconhecidos e o comando `archive` fica disponível

### MODIFIED Requirements

<!-- Nenhum requisito MOTOR vigente alterado. -->

### REMOVED Requirements

<!-- Nenhum. -->

## Critérios de aceite

- Uma execução da suíte `test_motor_archive.ps1` cobre C1..C5 e gera RED/GREEN rastreados.
- Arquivamento não ocorre com goal ausente, FAIL, pre-verify, verify ausente/reprovado ou valor `arvore` divergente.
- Sucesso grava `Done`, move todo o diretório e não faz commit; recusa e erro não causam perda ou sobrescrita.
- A suíte completa do kit passa nos motores suportados; spec viva do motor é atualizada no archive conforme o delta.

## Análise pré-implementação

- **Plano:** implementar `sdd archive <NN>` no motor do kernel, com helpers pequenos para validar evidência da change e executar movimento com rollback. Atualizar runner e changelog; atualizar o motor dogfooding pela instalação forçada autorizada para este repositório.
- **Escopo encadeado:** CHG-006 e CHG-007 avançam em sequência na mesma árvore. Os documentos/specs/origem/evidência da CHG-006 são listados para tornar visível o diff integral; continuam pertencendo à change 06 e não são reespecificados por CHG-007.
- **Tamanho:** uma capacidade, um requisito, cinco cenários e mais de 20 caminhos no impact por causa do diff sequenciado compartilhado com CHG-006. Excedente justificado: uma única árvore de trabalho e revisão integrada dos gates completos; documentos da CHG-006 continuam identificados como pertencentes à change 06. A contagem supera a referência normal definida por CHG-006.
- **Teste:** suíte de integração em repositório temporário cobre recusa, sucesso, stale tree, colisão, rollback por falha de preparação, índice inalterado e update legado; cada bloco C1-C5 leva sua tag literal. O RED/GREEN e o Verify Pass cobrem a change inteira.
- **Goal atual:** grava `goal-<change>.json` com `resultado` e `arvore` em `.sdd/state`; o comando deve comparar ambos antes de alterar a árvore.
- **Integridade:** preparar status novo em memória, checar destino antes de escrever, mover sem sobrescrever e reverter caminho/status se a gravação ou move falhar; o comando não altera o índice Git.
- **Compatibilidade:** comando aditivo, sem mudar formatos; teste de update legado e execução nos dois PowerShell.
- **Dogfooding:** testar kernel, então `install.ps1 update -Destino . -Forcar -SemArvoreLimpa`, exigido pelo guard porque a change está ativa e a árvore está suja; não editar `tools/sdd/sdd.ps1` manualmente.

## Tasks

- [x] RED (C1,C2,C3,C4,C5): `SpecSimpleKit/tests/test_motor_archive.ps1` -> primeiro RED válido registrado como exit 1 porque `archive` era desconhecido
- [x] GREEN (C1,C2,C3,C4,C5): `SpecSimpleKit/tests/test_motor_archive.ps1` -> 27/27 asserts em Windows PowerShell 5.1 e pwsh 7.6.7
- [x] REFACTOR: tags C1-C5 conferidas, rollback coberto, cópia raiz sincronizada pelo instalador; `sdd check` e `git diff --check` passaram | nada: fluxo legível e sem stage/commit

### Pós-GOAL

- [x] Atualizar spec viva `capabilities/motor/spec.md` com SPEC-MOTOR-002 e histórico CHG-007 antes do archive.
- [x] Arquivar pelo motor.
- [x] Executar `validate` pós-archive: `SDD VALIDATE PASS` (suíte completa e SpecLint).

## Exceções

<!-- Nenhuma. -->

## Aprovações

<!-- Uma aprovação P1/P2 da change inteira, registrada somente pelo motor. -->
- P1: aprovado por Thander em 2026-10-18 21:03 (sdd approve; via chat: "aprovo P1 da change 07"; change.md antes: 2dd397b74169)
- P2: aprovado por Thander em 2026-10-18 21:07 (sdd approve; via chat: "aprovo P2 da change 07"; change.md antes: 98a94a834164)
