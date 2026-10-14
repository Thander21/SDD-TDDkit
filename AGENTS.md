# AGENTS.md

<!-- sdd-kit:begin -->
## Metodologia (sdd-kit)

- **Núcleo sempre ativo:** `.agents/rules/sdd-core.md` (no Claude, importado
  pelo `.claude/CLAUDE.md`; no Antigravity, `trigger: always_on`).
- **Fluxo spec-driven:** `.agents/rules/sdd-fluxo.md`, lido antes de trabalho
  não trivial. **Revisão:** `.agents/rules/sdd-revisao.md`.
- **Skills:** `backlog-refinement`, `sdd-verify` e `sdd-bootstrap` em
  `.agents/skills/` (wrappers do Claude em `.claude/skills/`); `learn` só no
  Claude. Subagente verificador: `.claude/agents/sdd-verifier.md`.
- **Motor:** `powershell -File tools/sdd/sdd.ps1 <check|validate|test|goal|status|ajuda>`;
  perfil de gates em `.sdd/profile.json`.
- **Onde registrar:** regras = invariantes; skills = processo;
  `.agents/usage/` = manual humano; `.agents/reports/` = relatório (nunca
  fonte de regra); specs em `projeto.specs_root` do perfil.
- Bloco reescrito pelo update do kit. O projeto pode endurecer o núcleo,
  nunca afrouxar; lição de método vai para o INBOX do kit (skill `learn`).
<!-- sdd-kit:end -->

## Projeto

> Seção do projeto, preenchida pela skill `sdd-bootstrap`. Fato cita a fonte
> (`arquivo:linha`, decisão ou doc com data); o que não foi conferido fica
> marcado como hipótese. O bloco acima é do kit e é reescrito no update.

### O que é

Repositório de desenvolvimento do **SpecSimpleKit**, mini-framework SDD + TDD
para Claude Code e Antigravity, usado por um dev solo em projetos de qualquer
stack (`README.md`). Este repositório usa o próprio kit (dogfooding): a raiz
é um projeto SDD com o SpecSimpleKit instalado (`.sdd/kit.lock.json`, campo
`fonte`).

### Stack, pastas e camadas

- PowerShell, compatível com Windows PowerShell 5.1 e pwsh 7; fonte dos
  scripts em ASCII (`README.md`, Regras de manutenção 4; gate `light`).
  Line endings LF, `.cmd` em CRLF (`.gitattributes`).
- `SpecSimpleKit/` = o produto, o que vai para os projetos:
  - `install.ps1` (instala, confere, atualiza; passo `maquina`) e
    `instalar.cmd`;
  - `kernel/` = arquivos gerenciados copiados para cada projeto (regras,
    skills, moldes, motor `tools/sdd/sdd.ps1`);
  - `profiles/` (perfis de stack), `machine/` (guards de comando e de
    edição), `project-templates/`, `tests/` (só rodam aqui);
  - `VERSION`, `CHANGELOG.md`, `INBOX.md`, `Metodologia SDD.ai`.
- Raiz = projeto de desenvolvimento: `AGENTS.md`, `.claude/`, `.agents/`,
  `tools/sdd/`, `.sdd/` (cópias instaladas pelo kit) e `docs/Specs/`
  (backlog, changes e specs do próprio kit). `docs/diagnostico-comparativo.html`
  é publicado como Artifact (`README.md`, Regras de manutenção 5).
- **Fonte e cópia:** a fonte é `SpecSimpleKit/kernel/`; os arquivos
  gerenciados da raiz são cópias e nunca se editam à mão (o `check` acusa
  pelo hash do lock). Fluxo: editar o kernel → provar com
  `SpecSimpleKit/tests/` → sincronizar com
  `powershell -File SpecSimpleKit/install.ps1 update -Destino .`. Com change
  em implementação o `update` recusa; aqui, e só aqui, usar `-Forcar` para
  dogfooding da regra nova, dizendo isso no relato.

### Comandos

| Momento | Comando |
|---|---|
| Depois de alterar (sintaxe + ASCII, ~5 s) | `powershell -File tools/sdd/sdd.ps1 check` |
| Antes de commit e no fecho da change (+ suíte completa, minutos) | `powershell -File tools/sdd/sdd.ps1 validate` |
| RED e GREEN de uma task | `powershell -File tools/sdd/sdd.ps1 test SpecSimpleKit/tests/<arquivo>.ps1` |
| Parada da change | `powershell -File tools/sdd/sdd.ps1 goal <NN>` |
| Portão (só o usuário, no terminal dele) | `powershell -File tools/sdd/sdd.ps1 approve <NN> P1\|P2` |
| Suíte do kit direto | `powershell -File SpecSimpleKit/tests/run_all.ps1 [-Py <python do venv>]` |
| Sincronizar a raiz com o kernel | `powershell -File SpecSimpleKit/install.ps1 update -Destino .` |

### Convenções

- Identificadores, mensagens e comentários em português sem acento nos
  scripts (ASCII); documentação em pt-BR com acento.
- Funções `Verbo-Substantivo` com prefixo no motor (`Invoke-SddGoal`,
  `Test-SddTerminalHumano`: `SpecSimpleKit/kernel/tools/sdd/sdd.ps1:801`,
  `:964`); `$ErrorActionPreference = 'Stop'` no topo
  (`SpecSimpleKit/install.ps1:26`, `sdd.ps1:11`); mensagens de erro
  `ERRO: ...` com exit 2 no instalador.
- Testes: um script por área em `SpecSimpleKit/tests/test_*.ps1`, com
  `Assert-Igual`/`Assert-Contem` de `tests/helpers.ps1:64-77`, saída
  `N/M asserts ok` e exit 1 em falha; repositórios temporários com espaço e
  `+` no nome (`tests/helpers.ps1:7`). Todo teste roda em 5.1 e 7
  (`tests/run_all.ps1`).
- Cenário rastreado: tag `SPEC-<DOM>-NNN/Cn` no nome do assert (perfil,
  `rastreio.molde`).

### Riscos do projeto

| Tag | Promove a feature? | Invariantes | Cenário obrigatório | Exige fonte normativa? |
|---|---|---|---|---|
| `config-global` | sim | nada fora do projeto do usuário (`~/.claude`, `~/.gemini`, PATH, registro) muda sem comando explícito do humano, plano mostrado antes e backup; nunca antes de o projeto ser confirmado (incidente 12/10/2026: assistente aplicou o guard antes de perguntar o projeto) | gravação global recusada sem confirmação e sem humano no terminal; backup criado; desfazer restaura | não |
| `portao-humano` | sim | a IA não aprova P1/P2, não grava `status`/`base_ref`/Aprovações nem desliga guard (`sdd.ps1:964-983`, `machine/guard.ps1:217`) | o comando recusa quando chamado por agente (`CLAUDECODE`, stdin redirecionado) | não |
| `arquivo-do-usuario` | sim | instalador e update nunca sobrescrevem nem apagam arquivo do projeto fora dos gerenciados; conflito aborta sem gravação parcial (`install.ps1:285-295`); texto editado vira `.kitnew` | arquivo do usuário com conteúdo diferente → nada gravado e conflito listado | não |
| `contrato-do-motor` | sim | formato de `change.md`, `evidence.jsonl`, `kit.lock.json`, marcadores `sdd-kit:begin/end` e última linha do `goal` só muda com migração para projetos já instalados | projeto instalado na versão anterior continua passando `check` e `goal` depois do update | não |
| `start-chat` | sim | o início pode ser só pelo chat, sem rodar instalador: a IA reconhece se a pasta já tem o kit, faz as perguntas iniciais quando não reconhece projeto, ou lê o projeto atual e aplica a metodologia (decisão do usuário, 12/10/2026) | pasta sem kit → a IA pergunta e instala/inicia; pasta com kit → a IA lê o estado e retoma | não |

### Regras de domínio

<Índice: uma linha por arquivo em `.agents/rules/` do projeto, criado pelo
`learn` quando houver 3 armadilhas do mesmo território.>
