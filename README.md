# SDD-TDDkit

Repositório de desenvolvimento do **SpecSimpleKit**: mini-framework de
desenvolvimento orientado a spec (SDD) e a teste (TDD) para levar a
metodologia do ERP PDV D+ a projetos de qualquer stack, com Claude Code e
Antigravity.

- `SpecSimpleKit/` é a ferramenta: o que vai para os projetos. Versão em
  `SpecSimpleKit/VERSION`; histórico em `SpecSimpleKit/CHANGELOG.md`.
- A raiz é o projeto de desenvolvimento da ferramenta, com o próprio método
  (specs, changes e regras de IA ficam aqui). Decisão, diagnóstico e
  protocolo de uso em `SpecSimpleKit/Metodologia SDD.ai`.

> Os identificadores técnicos continuam `sdd-kit` (marcadores
> `sdd-kit:begin/end` no `AGENTS.md`, pasta `~/.sdd-kit/hooks`, hooks
> `sdd-kit-guard`): mudá-los quebraria os projetos já instalados.

## Início rápido

Pré-requisitos: Windows, Git e PowerShell 5.1 ou 7.

O kit fica clonado numa pasta só dele, **fora** dos seus projetos. Você não
clona o kit dentro do projeto nem copia pastas à mão: o instalador copia para
o projeto só os arquivos que ele usa (lista em "O que vai para cada
projeto"). O mesmo clone serve a todos os projetos.

```text
C:\_Projetos\SDD-TDDkit\                 <- clone (uma vez só)
C:\_Projetos\SDD-TDDkit\SpecSimpleKit\   <- a ferramenta: instalador, kernel, perfis
C:\_Projetos\MeuApp\                     <- seu projeto: recebe os arquivos do kit
C:\_Projetos\OutroApp\                   <- outro projeto: mesmo kit
```

**1. Clone o kit (uma vez):**

```powershell
git clone https://github.com/Thander21/SDD-TDDkit.git C:\_Projetos\SDD-TDDkit
```

**2. Instale num projeto:** abra o terminal na pasta do projeto e rode

```powershell
C:\_Projetos\SDD-TDDkit\SpecSimpleKit\instalar.cmd
```

(ou dê dois cliques no `instalar.cmd` e informe a pasta). O assistente:

- pergunta a pasta do projeto (Enter = a pasta atual) e roda `git init` se
  ela ainda não for um repositório;
- detecta a stack e sugere o perfil (Enter aceita);
- com arquivos pendentes no Git, só avisa e pergunta se continua: não
  precisa de commit para testar;
- na primeira vez, oferece instalar o guard da máquina (que faz a IDE pedir
  confirmação antes de comandos perigosos);
- se o kit já estiver no projeto, oferece atualizar.

**3. No projeto:** abra na IDE e peça à IA "rode a skill sdd-bootstrap". Ela
preenche o `AGENTS.md` e o `.sdd/profile.json`, calibra o perfil e instala o
pre-commit. Depois, revise o diff e faça o commit.

Para trazer uma versão nova do kit: `git -C C:\_Projetos\SDD-TDDkit pull` e
rode o `instalar.cmd` de novo no projeto.

<details>
<summary>Modo com parâmetros (scripts e CI)</summary>

Sem perguntas e com árvore limpa obrigatória (use `-SemArvoreLimpa` para
pular):

```powershell
instalar.cmd projeto -Destino C:\caminho\do\repo -Perfil node   # node | python | dotnet | flutter | rust | unity | unreal
instalar.cmd maquina [-Aplicar]
instalar.cmd check   -Destino C:\caminho\do\repo
instalar.cmd update  -Destino C:\caminho\do\repo
```

</details>

## Documentos

| Documento                           | Para quê                                                                                                              |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `SpecSimpleKit/Metodologia SDD.ai`                | decisão, mapa do que vai para cada projeto e protocolo de uso                                                         |
| `SpecSimpleKit/docs/como-usar-fluxo.md`           | como usar pelo chat: fluxo do pedido ao código pronto, onde cada coisa fica, portões e o que dizer em cada etapa |
| `docs/diagnostico-comparativo.html` | diagnóstico do método e comparativo com os frameworks; publicado em https://claude.ai/artifact/GCit5SpAwkbphRnXVsp6sB |

## Camadas

| Camada          | Onde                                                        | Dono                          | Atualiza como                          |
| --------------- | ----------------------------------------------------------- | ----------------------------- | -------------------------------------- |
| Núcleo          | `SpecSimpleKit/kernel/` → copiado para o projeto            | kit                           | `install.ps1 update` (lock com sha256) |
| Perfil de stack | `SpecSimpleKit/profiles/<stack>.json` → `.sdd/profile.json` | projeto, depois da instalação | à mão + `sdd calibrate`                |
| Projeto         | `AGENTS.md` (fora dos marcadores), regras de domínio, specs | projeto                       | nunca tocado pelo kit                  |
| Máquina         | `SpecSimpleKit/machine/` → `~/.sdd-kit/hooks` + settings   | você                          | `install.ps1 maquina -Aplicar`         |

## Conferir e atualizar

Conferir deriva: `install.ps1 check -Destino <repo>`. Atualizar:
`install.ps1 update -Destino <repo>` (recusa com change em implementação,
árvore suja ou executável do kit editado; texto editado recebe `.kitnew`).

## O que vai para cada projeto

| Arquivo                                                         | Para quê                                                              |
| --------------------------------------------------------------- | --------------------------------------------------------------------- |
| `AGENTS.md` (bloco entre `sdd-kit:begin/end`)                   | ponteiros do kit; o resto do arquivo é do projeto                     |
| `.claude/CLAUDE.md`                                             | adaptador do Claude: importa `AGENTS.md` e `sdd-core.md`              |
| `.agents/rules/sdd-core.md`                                     | núcleo sempre ativo (comportamento, portões, fecho, imposto × honra)  |
| `.agents/rules/sdd-fluxo.md`                                    | fluxo completo (sob demanda)                                          |
| `.agents/rules/sdd-revisao.md`                                  | anti-complacência e Verify Pass (sob demanda)                         |
| `.claude/rules/sdd-fluxo.md`                                    | stub com `paths` para o Claude carregar o fluxo nos arquivos de specs |
| `.agents/skills/{backlog-refinement,sdd-verify,sdd-bootstrap}/` | skills canônicas (Antigravity lê direto)                              |
| `.claude/skills/*/SKILL.md`                                     | wrappers gerados + `learn` (só Claude)                                |
| `.claude/agents/sdd-verifier.md`                                | verificador independente sem Write/Edit                               |
| `Docs/Specs/_templates/` e `capabilities/_index.md`             | moldes e registro de IDs                                              |
| `tools/sdd/sdd.ps1`                                             | motor                                                                 |
| `.sdd/profile.json`, `.sdd/kit.lock.json`                       | perfil (do projeto) e lock (do kit); `.sdd/state/` fica fora do Git   |

## Motor (`tools/sdd/sdd.ps1`)

| Comando                                  | Faz                                                                                                                                                                                                                                     |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `check` / `validate`                     | gates leves / completos do perfil + SpecLint; grava o resultado com o hash da árvore                                                                                                                                                    |
| `test <alvo> [--change NN]`              | roda o alvo e grava a evidência (`falha`, `passou`, `carga`, `zero`, `erro`, `inconsistente`)                                                                                                                                           |
| `goal <NN>`                              | condição de parada: perfil calibrado, portões P1/P2, fonte normativa, tasks, RED e GREEN por cenário, validate e verificador da árvore atual, impact do working tree, exceções                                                          |
| `approve <NN> P1\|P2`                    | portão humano: recusa stdin redirecionado e sessão do Claude Code (no Antigravity, depende de o terminal do agente não ser interativo; não confirmado). O P2 numa change já em implementação só re-ancora o `base_ref` depois de rebase |
| `verify-record <NN> APROVADO\|REPROVADO` | grava o `verify.md` carimbado                                                                                                                                                                                                           |
| `commit-gate` / `install-hook`           | pre-commit que só lê o último check/validate da mesma árvore                                                                                                                                                                            |
| `calibrate`                              | confere as 3 sondas e marca o perfil como calibrado                                                                                                                                                                                     |

## Estado dos perfis (12/10/2026)

| Perfil  | Testado nesta versão               | Observação                                                        |
| ------- | ---------------------------------- | ----------------------------------------------------------------- |
| node    | sim (Node 24, `node:test` + JUnit) | arquivo sem `test()` virava "passou": tratado com `ignorar_casos` |
| python  | sim (pytest + ruff em venv)        | `{PY}` no `profile.local.json`                                    |
| dotnet  | sim (.NET 9 + xUnit + TRX)         | `DOTNET_CLI_UI_LANGUAGE=en`                                       |
| flutter | parcial (variante `dart test`)     | o `flutter test` usa o mesmo reporter JSON; não rodado aqui       |
| rust    | não (sem cargo na máquina)         | rascunho; sondas obrigatórias                                     |
| unity   | não                                | rascunho; decide pelo XML NUnit; editor fechado                   |
| unreal  | não                                | rascunho; `index.json` com campos não documentados                |

O `goal` recusa perfil com `calibrado: false`.

## Testes do kit

`powershell -File SpecSimpleKit/tests/run_all.ps1 -Py <python de um venv com pytest e ruff>`
roda guard, instalador e motor (Node, Python, .NET, Dart) no Windows
PowerShell 5.1 e no pwsh 7. Os testes do kit rodam só aqui, nunca no
`validate` dos projetos.

## Regras de manutenção

1. Lição de método chega pelo `SpecSimpleKit/INBOX.md`; release no máximo uma vez por mês,
   com teste para cada mudança no motor.
2. Orçamento de tamanho: `sdd-core.md` até 5 KB, `sdd-fluxo.md` até 14 KB,
   Markdown gerenciado total até 40 KB.
3. Peça nova só com gatilho de dor medido (lista em `SpecSimpleKit/Metodologia SDD.ai`, §9).
4. Fonte dos scripts em ASCII e compatível com PowerShell 5.1 e 7.
5. Toda release atualiza `docs/diagnostico-comparativo.html`: versão e data
   no topo, as seções "O que o kit corrige", "Imposto ou honra",
   "Verificação" e "Limites", e uma linha no "Histórico". Depois, republica
   no mesmo link (o Artifact recebe o `url` acima, para não criar página nova).
