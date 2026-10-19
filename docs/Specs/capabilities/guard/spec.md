# guard

> **Domínio:** `GUARD` · **Origem no código:** `SpecSimpleKit/kernel/tools/sdd/guard.ps1`, `SpecSimpleKit/kernel/tools/sdd/edit_guard.ps1`, `SpecSimpleKit/kernel/tools/sdd/sdd.ps1`.
> Este arquivo descreve o comportamento **atual**. Só muda no archive de uma
> change, pelos deltas dela. Cabeçalhos no formato do OpenSpec (Purpose,
> Requirements, Requirement, Scenario) para a validação externa continuar possível.

## Purpose

Proteção operacional no escopo do projeto contra comandos destrutivos e edições não supervisionadas de arquivos sensíveis ou de governança do SDD, atuando como PreToolUse hooks no Antigravity e no Claude Code.

## Requirements

### Requirement: SPEC-GUARD-002 — Guard configurado exclusivamente no projeto

O sistema DEVE configurar o guard de comandos e de edição dentro do repositório, sem tocar em pastas globais da máquina (`~/.claude`, `~/.gemini`, `~/.sdd-kit`).

#### Scenario: C1 — Ativação em projeto sem settings prévios

- **DADO** um projeto que nunca teve o kit instalado nem arquivos de settings
- **QUANDO** a IA roda `sdd guard ativar`
- **ENTÃO** cria `.agents/hooks.json` (Antigravity-first) e `.claude/settings.json`, sem gravar nada fora da pasta do projeto

#### Scenario: C2 — Settings do usuário preservados e idempotência

- **DADO** um projeto com `.agents/hooks.json` e `.claude/settings.json` já existentes do usuário
- **QUANDO** a IA roda `sdd guard ativar` duas vezes
- **ENTÃO** as chaves preexistentes do usuário são preservadas e as entradas do kit aparecem uma vez só

#### Scenario: C3 — Settings inválido

- **DADO** um arquivo de settings com JSON inválido
- **QUANDO** a IA roda `sdd guard ativar`
- **ENTÃO** sai mensagem explicativa, exit 2, e nenhum arquivo é alterado

#### Scenario: C4 — Guard dispara no Antigravity

- **DADO** o Antigravity com `.agents/hooks.json` configurado com os guards do kit
- **QUANDO** o hook avalia `run_command` com comando destrutivo (ex.: `git push --force`) ou edição indevida em `change.md`
- **ENTÃO** o hook responde com `decision: "force_ask"` (para comando) ou `decision: "deny"` (para edição) e `reason` justificando a proteção, seguindo o contrato oficial do Antigravity

> Contrato: `sdd guard ativar` configura `.agents/hooks.json` e `.claude/settings.json`.
> Testes: `tests/test_guard_projeto.ps1` (tags `SPEC-GUARD-002/C1..C4`).

### Requirement: SPEC-GUARD-003 — Desativar remove só o que é do kit

O sistema DEVE remover apenas as entradas do kit e informar o estado do guard.

#### Scenario: C1 — Volta ao conteúdo do usuário

- **DADO** o guard ativado sobre settings do usuário
- **QUANDO** a IA roda `sdd guard desativar`
- **ENTÃO** o conteúdo do usuário fica igual ao de antes da ativação e o `.agents/hooks.json`, se só tinha entradas do kit, é apagado

#### Scenario: C2 — Status

- **DADO** um projeto com apenas um dos arquivos de guard do kit ou fragmentos parciais
- **QUANDO** a IA roda `sdd guard status`
- **ENTÃO** a saída relata `GUARD: ativo` (exit 0) quando completo, `GUARD: inativo` (exit 1) quando ausente, ou `GUARD: parcial` (exit 1) indicando o arquivo faltante

> Contrato: `sdd guard desativar` e `sdd guard status`.
> Testes: `tests/test_guard_projeto.ps1` (tags `SPEC-GUARD-003/C1..C2`).

### Requirement: SPEC-GUARD-004 — A IA não desliga o guard sozinha

O sistema DEVE pedir a confirmação do usuário antes de desligar o guard ou editar seus arquivos de configuração.

#### Scenario: C1 — Comando de desativar

- **DADO** o guard de comando
- **QUANDO** a IA pede `powershell -File tools/sdd/sdd.ps1 guard desativar`
- **ENTÃO** a decisão é `force_ask` / `ask`

#### Scenario: C2 — Edição dos settings

- **DADO** o guard de edição
- **QUANDO** a IA tenta editar `.claude/settings.json` ou `.agents/hooks.json` do projeto
- **ENTÃO** a decisão é `force_ask` / `ask`

> Contrato: Bloqueio anti-desativação autônoma.
> Testes: `tests/test_guard_projeto.ps1` (tags `SPEC-GUARD-004/C1..C2`).

## Requisitos removidos

| ID | Change | Motivo |
|---|---|---|

## Histórico

| Change | Data | Efeito |
|---|---|---|
| CHG-005 | 2026-10-19 | Criação da spec viva de guard com SPEC-GUARD-002, SPEC-GUARD-003 e SPEC-GUARD-004 (guard no projeto) |
