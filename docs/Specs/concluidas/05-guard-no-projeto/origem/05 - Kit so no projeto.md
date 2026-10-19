# Kit só no projeto

> **Prontidão:** Pronto <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
> **Regra:** `.agents/rules/sdd-fluxo.md` §2. **Skill:** `backlog-refinement`.
> Arquivo: `<specs>/backlog/NN - Tema.md`; sem `NN` = provisório até o usuário numerar.

## Levantamento

Falas do usuário, 14/10/2026:

> temos no claude code o sdd-kit instalado foi somente um teste, porem afeta
> outros projetos, tem que remover, mas como podemos ajustar aqui para quando
> o specsimplekit for instalado configurar somente o projeto em que esta e
> aqui no sdd-tddkit so usar o specsimplekit nesse projeto para desenvolver o
> proprio specsimplkit

> [skill de início também só no projeto:] opção 1 porem tambem a
> specsimplekit cria o agents.md use o modelo criado para deixar a skills de
> criação de agents.md na raiz que aponta para uso da spec em specsimplekit

> como o specsimplekit deve ser independente então ao iniciar a ai deve
> validar qual o seu escopo de uso ide ou ia e saber onde criar as skills o
> inicio do specsimplekit deve sempre orientar o passo a passo para implantar
> no projeto com o iniciar a ia vai criar ou atualizar o agents.md na raiz e
> criar os atalhos que for necessário para usar a skills isso orientado
> corretamente no iniciar cada ia ou ide já vai saber onde e como criar esses
> atalhos mas usando de dentro do specsimplekit

Fatos do dia:

- Removido da máquina em 14/10/2026, a pedido: 42 `deny` e 4 `ask` que o
  passo `maquina` pôs em `~/.claude/settings.json` (os hooks já não estavam
  lá; o arquivo tinha sido alterado às 14:02), `~/.gemini/config/hooks.json`
  (criado pelo kit, só com as 2 entradas dele) e `~/.sdd-kit/`. Backup no
  scratchpad da sessão.
- Únicas gravações fora do projeto no instalador: passo `maquina`
  (`SpecSimpleKit/install.ps1:410`, `:472-497`) e a oferta dele no
  assistente (`:505-513`).
- Hoje este repositório está sem guard nenhum (nem global, nem do projeto).
- A decisão "Skill global 1x" do item 01 (R2, RF9, RN6, U4) fica substituída
  por este item (registrado lá como R4).

Proposta a conferir no refinamento (hipótese, não decisão):

- Guards movidos de `machine/` para o kernel (`tools/sdd/`), copiados para
  cada projeto e protegidos pelo lock; hooks e permissões em
  `.claude/settings.json` do projeto e `.agents/hooks.json` do projeto
  (Antigravity; caminho na doc, não verificado); fim do passo `maquina`.
- Entrada pelo `AGENTS.md`: o kit cria o `AGENTS.md` na raiz pelo molde
  `SpecSimpleKit/project-templates/AGENTS.md` (`install.ps1:280-282`), e ele
  aponta para o uso da spec no SpecSimpleKit; qualquer IA que abre a pasta lê
  esse arquivo. Interpretação da segunda fala, a confirmar.

Tags prováveis: `config-global`, `portao-humano`, `arquivo-do-usuario`.

## Requisitos

<!-- Preenchido pela skill backlog-refinement. -->

### Problema e valor

Quem sofre: o usuário que testa o kit num projeto e vê o efeito em todos os
outros (12 e 14/10/2026: o passo `maquina` gravou hooks e permissões em
`~/.claude/settings.json` e `~/.gemini/config/hooks.json`, que valiam em
qualquer pasta). Melhora: o kit vive numa pasta `SpecSimpleKit/` dentro do
projeto, configura só aquele projeto e sai inteiro apagando a pasta e os
ponteiros da raiz (item 01, R3: "sem sujar o projeto podendo deletar depois a
pasta").

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|
| Gravação fora do projeto | sim, só no passo `maquina` | `SpecSimpleKit/install.ps1:410` (`Get-Casa`), `:472-497`; oferecido no assistente em `:505-513` |
| Guards fora do kernel | sim | `SpecSimpleKit/machine/guard.ps1`, `machine/edit_guard.ps1`; copiados para `~/.sdd-kit/hooks` (`install.ps1:472-476`) |
| Hooks e permissões do Claude só no projeto | não existe | o kit não grava `.claude/settings.json` do projeto (não há no repositório; conferido em 14/10/2026) |
| Hooks do Antigravity no workspace | não existe | sem `.agents/hooks.json`; caminho citado na doc do Antigravity (pesquisa de 12/10/2026, confiança média, não verificado) |
| Kit copiado para a raiz do projeto | sim | `.claude/`, `.agents/`, `tools/sdd/`, moldes em `<specs>/_templates/` (16 arquivos, `.sdd/kit.lock.json`) |
| Motor acha a raiz do projeto de qualquer pasta | sim | `kernel/tools/sdd/sdd.ps1:109-115` (`git rev-parse --show-toplevel`); quebra se a pasta do kit tiver `.git` próprio (hipótese pela mesma linha) |
| Skill em pasta aninhada | só com escopo da pasta | Claude Code listou `SpecSimpleKit/kernel:learn` "applies when working on files under SpecSimpleKit/kernel/" (observado nesta sessão, 14/10/2026); na raiz precisa de wrapper em `.claude/skills/` |
| Hooks do Claude lidos de subpasta | não verificado | hipótese: só `.claude/settings*.json` da raiz do projeto |
| Molde do `AGENTS.md` | sim | `SpecSimpleKit/project-templates/AGENTS.md`; usado quando a raiz não tem `AGENTS.md` (`install.ps1:280-282`) |
| Skill de dentro da pasta do kit já aparece no Claude Code | sim, com escopo | `SpecSimpleKit/kernel/.claude/skills/learn` foi listada como `SpecSimpleKit/kernel:learn` (observado em 14/10/2026); serve de porta de entrada antes de existir atalho na raiz |
| IA sabe em qual ferramenta está | só o Claude Code por variável | `CLAUDECODE=1` no shell do Claude Code (observado); demais ferramentas: não verificado |
| Onde cada ferramenta lê skills/atalhos | conferido só no Claude Code | `.claude/skills/<nome>/SKILL.md` funciona neste repositório; Antigravity `.agents/skills/`, Cursor, Codex e Gemini CLI: hipótese, a conferir na doc oficial de cada uma |
| Tamanho da pasta do kit sem testes | 34 arquivos, 225 KB | medido em 14/10/2026; só kernel, perfis, moldes e instalador: 27 arquivos, 165 KB |

### Requisitos funcionais

- **RF1:** Instalar não grava nada fora da pasta do projeto (R1).
- **RF2:** O kit fica numa pasta `SpecSimpleKit/` dentro do projeto; regras,
  skills, motor e guards são lidos de lá, sem cópia para a raiz (R2).
- **RF3:** Na raiz ficam só ponteiros: o bloco do kit no `AGENTS.md` (criado
  pelo molde quando não existir, atualizado quando existir), os atalhos de
  skill de cada ferramenta escolhida, apontando para a pasta do kit, e as
  entradas de hook e permissão do kit nos settings do projeto (R2, R4).
- **RF4:** Guard de comando e de edição ativos só no projeto onde o kit está:
  Claude por `.claude/settings.json` do projeto, Antigravity pelo
  `.agents/hooks.json` do projeto.
- **RF5:** Remover o kit = apagar a pasta `SpecSimpleKit/` e os ponteiros;
  ficam `<specs>/`, `.sdd/profile.json` e a seção Projeto do `AGENTS.md`
  (item 01, RF10).
- **RF7:** No início, a IA diz em qual ferramenta está rodando (IDE ou CLI
  de IA), pede confirmação e pergunta se o projeto usa outras, com mais de
  uma marcável (R4; item 01, R1).
- **RF8:** O início é um passo a passo dentro do kit (`SpecSimpleKit/`):
  ler ou perguntar sobre o projeto, mostrar o plano (o que será criado ou
  atualizado na raiz), criar após a confirmação e indicar o próximo passo
  (R4).
- **RF9:** Cada ferramenta tem no kit o seu destino e o seu molde de atalho;
  a IA não decide sozinha onde nem como criar (R4).
- **RF6:** Neste repositório, o kit roda direto de `SpecSimpleKit/`: editar
  o kernel já vale, sem `update` para sincronizar cópias (pedido de
  14/10/2026).

### Regras de negócio e restrições

- **RN1:** O passo `maquina` deixa de existir. Fonte: R1; risco `config-global`.
- **RN2:** Nos settings do projeto que já existirem, o kit só acrescenta e
  só remove as entradas dele, registradas no lock; o resto do arquivo é do
  usuário. Fonte: risco `arquivo-do-usuario`.
- **RN3:** O lock e os hashes continuam valendo para os arquivos da pasta do
  kit; arquivo do kit editado no projeto é acusado pelo `check`. Fonte:
  risco `contrato-do-motor`.
- **RN4:** A pasta do kit dentro do projeto não pode ter `.git` próprio (o
  motor acharia a raiz errada). Fonte: `sdd.ps1:109-115`.
- **RN7:** Atalhos e bloco do `AGENTS.md` são cópia literal dos moldes do
  kit (só o caminho da pasta é substituído); o `sdd check` confere cada um
  contra o molde. Assim a IA cria (R4) e a máquina confere, em vez de a IA
  improvisar. Substitui a RN3 do item 01 ("quem grava é o script").
- **RN8:** Ferramenta sem destino conferido na documentação oficial (fonte e
  data na tabela do kit) não recebe atalho: a IA diz isso e segue com as
  outras. Fonte: `sdd-core.md`, "Sem invenção".
- **RN6:** A pasta `SpecSimpleKit/` entra no Git do projeto: quem clona
  recebe o kit e o guard funcionando; a versão do kit fica presa ao commit.
  Fonte: R3.
- **RN5:** Projetos já instalados no modo antigo (cópias na raiz) migram por
  um `update` que remove as cópias e grava os ponteiros. Fonte: risco
  `contrato-do-motor`.

### Fora de escopo

- Distribuição por plugin ou marketplace.
- Adaptadores Gemini CLI, Cursor e Codex (item 01, U2): seguem depois, já
  no modo pasta.
- A aprovação por frase (CHG-002): muda só o caminho dos guards que ela
  testa.

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|
| U1. Guard no projeto: guards no kernel, hooks e permissões nos settings do projeto (Claude e Antigravity) com merge só das entradas do kit, fim do passo `maquina` (RF1, RF4, RN1, RN2) | feature | guard (`GUARD`) + instalador (`INST`) | `config-global`, `portao-humano`, `arquivo-do-usuario` | — |
| U2. Kit como pasta dentro do projeto + início guiado: passo a passo dentro do kit, identificação da ferramenta, `AGENTS.md` e atalhos por molde para Claude Code e Antigravity, remoção pela pasta, migração do modo antigo, este repositório no modo pasta (RF2, RF3, RF5-RF9, RN3-RN8) | feature | instalador (`INST`) + fluxo (`FLUXO`) | `contrato-do-motor`, `arquivo-do-usuario`, `start-chat` | U1 |
| U3. Moldes de atalho para Cursor, Codex e Gemini CLI, depois de conferir a doc oficial de cada um (RF9, RN8) | feature | fluxo (`FLUXO`) | `start-chat` | U2 |

Efeito no que já está aberto (para o usuário decidir): este item absorve as
unidades U2 (adaptadores) e U3 (skills de entrada) do item 01. A CHG-001
(`detectar`, `-Plano`, `remover` no `install.ps1`) perde a razão de ser se
quem cria é a IA pelo passo a passo: deve ser revista ou substituída depois
da U2. A CHG-002 testa os guards em `machine/`, que a U1 move.

### Perguntas para o usuário

### Respostas

| # | Resposta | Data |
|---|---|---|
| R1 | Skill de início também só no projeto (opção "Sim, nada global"), com a ressalva da segunda fala do Levantamento. | 14/10/2026 |
| R2 | Ligação do `AGENTS.md` com o kit: opção "Pasta dentro do projeto" (a pasta `SpecSimpleKit/` é a única coisa do kit no projeto; o `AGENTS.md` da raiz aponta para ela; apagar a pasta e o bloco desliga o kit). | 14/10/2026 |
| R3 | A pasta `SpecSimpleKit/` entra no Git do projeto (opção "Entra no Git"). | 14/10/2026 |
| R4 | Kit independente; no início a IA valida em qual IDE/IA está e onde criar as skills; o início orienta o passo a passo; a IA cria ou atualiza o `AGENTS.md` na raiz e os atalhos necessários, cada ferramenta sabendo onde e como, sempre usando de dentro do SpecSimpleKit (terceira fala do Levantamento). | 14/10/2026 |
| R5 | "sim concordo vamos seguir esse caminho auto criado na ai com orientação do speckit desacoplando o specsimplekit do projeto e sendo limpo ou reutilizado quando necessário" (item Pronto) | 14/10/2026 |

## Tasks

## Encaminhamento

- 14/10/2026: U1 → `changes/05-guard-no-projeto/` (CHG-005, Draft). U2 e U3
  viram as changes seguintes e citam `changes/05-guard-no-projeto/origem/`.
