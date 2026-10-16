# SpecSimpleKit

Mini-framework para desenvolver com IA de forma guiada: **spec antes do
código (SDD), teste antes da implementação (TDD)** e portões em que só você
aprova. Funciona no chat do Claude Code e do Antigravity, em projetos de
qualquer stack. Você conversa; a IA conduz cada etapa e roda os comandos; o
motor do kit confere e grava a evidência.

Versão em [`VERSION`](VERSION) · histórico em [`CHANGELOG.md`](CHANGELOG.md) ·
desenvolvido no repositório [SDD-TDDkit](../README.md).

> **Estado (0.1.0, em desenvolvimento):** a aprovação pelo chat já funciona.
> O início só pelo chat, o guard só no projeto e o kit como pasta dentro do
> projeto estão em andamento (changes 01 e 05 e backlog no repositório de
> desenvolvimento). Até lá, a instalação é pelo instalador abaixo, e o passo
> `maquina` grava configuração global: **não use** esse passo por enquanto.

## Como funciona, em uma figura

```text
 você (chat)                     IA                            motor (tools/sdd/sdd.ps1)
 ideia ─────────────────► item no backlog
 "refine o item NN" ────► requisitos conferidos no código + perguntas
 "item NN Pronto" ──────► change em Draft (cenários DADO/QUANDO/ENTÃO)
 "aprovo P1 da change NN" ───────────────────────────────► sdd approve NN P1 --frase
                          plano, tasks RED → GREEN, análise
 "aprovo P2 da change NN" ───────────────────────────────► sdd approve NN P2 --frase
                          teste falha (RED) → código → passa (GREEN) ──► sdd test (grava evidência)
                          validate, verificador independente, goal ────► GOAL PASS
                          revisão, learn, archive na spec viva
 commit (seu)
```

O passo a passo completo, com o que dizer em cada etapa, está em
[`docs/como-usar-fluxo.md`](docs/como-usar-fluxo.md).

## Instalar num projeto (versão atual)

Pré-requisitos: Windows, Git e PowerShell 5.1 ou 7. O projeto precisa ser um
repositório Git.

1. Clone uma vez, fora dos seus projetos:

   ```powershell
   git clone https://github.com/Thander21/SDD-TDDkit.git C:\_Projetos\SDD-TDDkit
   ```

2. No chat da IA, aberto no seu projeto, peça para ela rodar o instalador com
   parâmetros (a IA não deve usar o assistente interativo):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\_Projetos\SDD-TDDkit\SpecSimpleKit\install.ps1 projeto -Destino . -Perfil node
   ```

   Perfis: `node`, `python`, `dotnet`, `flutter`, `rust`, `unity`, `unreal`,
   `powershell`.

3. Peça à IA: **"rode a skill sdd-bootstrap"**. Ela lê o projeto, faz até 5
   perguntas, preenche a seção Projeto do `AGENTS.md`, calibra o perfil e
   instala o pre-commit.

4. Revise o diff e faça o commit.

Atualizar: `git -C C:\_Projetos\SDD-TDDkit pull` e peça à IA
`install.ps1 update -Destino .`. Conferir se algo do kit foi editado no
projeto: `install.ps1 check -Destino .`.

## Portões: só você aprova

| Portão | Quando | Você escreve no chat |
|---|---|---|
| Pronto | o item do backlog está refinado | "item NN Pronto" |
| P1 | a spec (cenários) está certa | "aprovo P1 da change NN" |
| P2 | plano, tasks e análise estão certos | "aprovo P2 da change NN" |
| Commit | a change fechou com `GOAL PASS` | você faz o commit (ou pede) |

A frase precisa citar a aprovação, o portão e a change ("change 02" ou
"CHG-002"); "ok" ou "segue" não aprovam. A frase fica registrada na change.
É confiança, não trava: a máquina não prova que a frase veio de você.

## O que vai para o projeto

| Arquivo | Para quê |
|---|---|
| `AGENTS.md` (bloco `sdd-kit:begin/end`) | ponteiros do kit; o resto do arquivo é do projeto |
| `.claude/CLAUDE.md` | entrada do Claude: importa `AGENTS.md` e o núcleo |
| `.agents/rules/sdd-core.md`, `sdd-fluxo.md`, `sdd-revisao.md` | núcleo sempre ativo, fluxo completo e revisão |
| `.agents/skills/` e `.claude/skills/` | `backlog-refinement`, `sdd-verify`, `sdd-bootstrap` e `learn` |
| `.claude/agents/sdd-verifier.md` | verificador independente (sem Write/Edit) |
| `Docs/Specs/` (`_templates/`, `capabilities/_index.md`) | moldes e registro de IDs `SPEC-<DOM>-NNN` |
| `tools/sdd/sdd.ps1` | motor |
| `.sdd/profile.json`, `.sdd/kit.lock.json` | perfil de gates (do projeto) e lock com hash (do kit) |

Arquivos do kit no projeto não se editam à mão: o `check` acusa pelo hash.
Lição de método vai para o [`INBOX.md`](INBOX.md) do kit (skill `learn`).

## Motor (`tools/sdd/sdd.ps1`)

| Comando | Faz |
|---|---|
| `check` / `validate` | gates leves / completos do perfil + SpecLint |
| `test <alvo> [--change NN]` | roda o teste e grava a evidência (`falha`, `passou`, `carga`, `zero`, `erro`) |
| `approve <NN> P1\|P2 --frase "..."` | registra o portão com a sua frase |
| `goal <NN>` | condição de parada: portões, tasks, RED e GREEN por cenário, validate, verificador, `impact` |
| `verify-record <NN> APROVADO\|REPROVADO` | grava o veredito do verificador |
| `calibrate`, `commit-gate`, `install-hook`, `status`, `ajuda` | calibração do perfil, pre-commit e estado |

## Perfis de stack

| Perfil | Testado | Observação |
|---|---|---|
| node | sim (Node 24, `node:test` + JUnit) | |
| python | sim (pytest + ruff em venv) | `{PY}` no `profile.local.json` |
| dotnet | sim (.NET 9 + xUnit + TRX) | |
| powershell | sim, no próprio repositório do kit | sem relatório estruturado (decide pelo exit code) |
| flutter | parcial (`dart test`) | |
| rust, unity, unreal | não | rascunhos; sondas obrigatórias |

O `goal` recusa perfil não calibrado.

## Documentos

- [`docs/como-usar-fluxo.md`](docs/como-usar-fluxo.md): guia do fluxo pelo chat.
- [`Metodologia SDD.ai`](Metodologia%20SDD.ai): decisão e protocolo (Markdown; extensão `.ai` por histórico).
- [Diagnóstico comparativo](https://claude.ai/artifact/GCit5SpAwkbphRnXVsp6sB) com Spec Kit, OpenSpec, Kiro, BMAD e outros.
