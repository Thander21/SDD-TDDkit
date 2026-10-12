# sdd-kit

Mini-framework de desenvolvimento orientado a spec (SDD) para levar a
metodologia do ERP PDV D+ a projetos de qualquer stack, com Claude Code e
Antigravity. Versão em `VERSION`; histórico em `CHANGELOG.md`; decisão,
diagnóstico e protocolo de uso em `../Metodologia SDD.ai`.

> **Destino recomendado:** mova esta pasta para um repositório git próprio
> (ex.: `C:\_Projetos\sdd-kit`), com tags por versão. O `install.ps1` grava no
> lock de cada projeto o caminho e o commit do kit, e o `update` puxa daqui.

## Documentos

| Documento | Para quê |
|---|---|
| `../Metodologia SDD.ai` | decisão, mapa do que vai para cada projeto e protocolo de uso |
| `docs/diagnostico-comparativo.html` | diagnóstico do método e comparativo com os frameworks; publicado em https://claude.ai/artifact/GCit5SpAwkbphRnXVsp6sB |

## Camadas

| Camada | Onde | Dono | Atualiza como |
|---|---|---|---|
| Núcleo | `kernel/` → copiado para o projeto | kit | `install.ps1 update` (lock com sha256) |
| Perfil de stack | `profiles/<stack>.json` → `.sdd/profile.json` | projeto, depois da instalação | à mão + `sdd calibrate` |
| Projeto | `AGENTS.md` (fora dos marcadores), regras de domínio, specs | projeto | nunca tocado pelo kit |
| Máquina | `machine/` → `~/.sdd-kit/hooks` + settings do usuário | você | `install.ps1 maquina -Aplicar` |

## Instalar

```powershell
# 1. Uma vez por máquina: guard de comando e de edição + permissões do Claude
powershell -File install.ps1 maquina            # gera os fragmentos
powershell -File install.ps1 maquina -Aplicar   # mescla com backup

# 2. Em cada projeto (árvore git limpa)
powershell -File install.ps1 projeto -Destino C:\caminho\do\repo -Perfil node
#    perfis: node | python | dotnet | flutter | rust | unity | unreal

# 3. No projeto, peça à IA: "rode a skill sdd-bootstrap"
# 4. powershell -File tools/sdd/sdd.ps1 install-hook ; revise o diff ; commit
```

Conferir deriva: `install.ps1 check -Destino <repo>`. Atualizar:
`install.ps1 update -Destino <repo>` (recusa com change em implementação,
árvore suja ou executável do kit editado; texto editado recebe `.kitnew`).

## O que vai para cada projeto

| Arquivo | Para quê |
|---|---|
| `AGENTS.md` (bloco entre `sdd-kit:begin/end`) | ponteiros do kit; o resto do arquivo é do projeto |
| `.claude/CLAUDE.md` | adaptador do Claude: importa `AGENTS.md` e `sdd-core.md` |
| `.agents/rules/sdd-core.md` | núcleo sempre ativo (comportamento, portões, fecho, imposto × honra) |
| `.agents/rules/sdd-fluxo.md` | fluxo completo (sob demanda) |
| `.agents/rules/sdd-revisao.md` | anti-complacência e Verify Pass (sob demanda) |
| `.claude/rules/sdd-fluxo.md` | stub com `paths` para o Claude carregar o fluxo nos arquivos de specs |
| `.agents/skills/{backlog-refinement,sdd-verify,sdd-bootstrap}/` | skills canônicas (Antigravity lê direto) |
| `.claude/skills/*/SKILL.md` | wrappers gerados + `learn` (só Claude) |
| `.claude/agents/sdd-verifier.md` | verificador independente sem Write/Edit |
| `Docs/Specs/_templates/` e `capabilities/_index.md` | moldes e registro de IDs |
| `tools/sdd/sdd.ps1` | motor |
| `.sdd/profile.json`, `.sdd/kit.lock.json` | perfil (do projeto) e lock (do kit); `.sdd/state/` fica fora do Git |

## Motor (`tools/sdd/sdd.ps1`)

| Comando | Faz |
|---|---|
| `check` / `validate` | gates leves / completos do perfil + SpecLint; grava o resultado com o hash da árvore |
| `test <alvo> [--change NN]` | roda o alvo e grava a evidência (`falha`, `passou`, `carga`, `zero`, `erro`, `inconsistente`) |
| `goal <NN>` | condição de parada: perfil calibrado, portões P1/P2, fonte normativa, tasks, RED e GREEN por cenário, validate e verificador da árvore atual, impact do working tree, exceções |
| `approve <NN> P1\|P2` | portão humano: recusa stdin redirecionado e sessão do Claude Code (no Antigravity, depende de o terminal do agente não ser interativo; não confirmado). O P2 numa change já em implementação só re-ancora o `base_ref` depois de rebase |
| `verify-record <NN> APROVADO\|REPROVADO` | grava o `verify.md` carimbado |
| `commit-gate` / `install-hook` | pre-commit que só lê o último check/validate da mesma árvore |
| `calibrate` | confere as 3 sondas e marca o perfil como calibrado |

## Estado dos perfis (12/10/2026)

| Perfil | Testado nesta versão | Observação |
|---|---|---|
| node | sim (Node 24, `node:test` + JUnit) | arquivo sem `test()` virava "passou": tratado com `ignorar_casos` |
| python | sim (pytest + ruff em venv) | `{PY}` no `profile.local.json` |
| dotnet | sim (.NET 9 + xUnit + TRX) | `DOTNET_CLI_UI_LANGUAGE=en` |
| flutter | parcial (variante `dart test`) | o `flutter test` usa o mesmo reporter JSON; não rodado aqui |
| rust | não (sem cargo na máquina) | rascunho; sondas obrigatórias |
| unity | não | rascunho; decide pelo XML NUnit; editor fechado |
| unreal | não | rascunho; `index.json` com campos não documentados |

O `goal` recusa perfil com `calibrado: false`.

## Testes do kit

`powershell -File tests/run_all.ps1 -Py <python de um venv com pytest e ruff>`
roda guard, instalador e motor (Node, Python, .NET, Dart) no Windows
PowerShell 5.1 e no pwsh 7. Os testes do kit rodam só aqui, nunca no
`validate` dos projetos.

## Regras de manutenção

1. Lição de método chega pelo `INBOX.md`; release no máximo uma vez por mês,
   com teste para cada mudança no motor.
2. Orçamento de tamanho: `sdd-core.md` até 5 KB, `sdd-fluxo.md` até 14 KB,
   Markdown gerenciado total até 40 KB.
3. Peça nova só com gatilho de dor medido (lista em `../Metodologia SDD.ai`, §9).
4. Fonte dos scripts em ASCII e compatível com PowerShell 5.1 e 7.
5. Toda release atualiza `docs/diagnostico-comparativo.html`: versão e data
   no topo, as seções "O que o kit corrige", "Imposto ou honra",
   "Verificação" e "Limites", e uma linha no "Histórico". Depois, republica
   no mesmo link (o Artifact recebe o `url` acima, para não criar página nova).
