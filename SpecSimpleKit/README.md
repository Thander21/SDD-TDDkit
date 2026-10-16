# SpecSimpleKit

**Um jeito simples de programar com IA sem perder o controle.** Você conversa
com a IA no chat (Claude Code ou Antigravity). Ela não sai escrevendo código:
primeiro combina com você **o que** vai ser feito, escreve os testes que provam
isso, e só então implementa. Você decide nos pontos importantes; o kit confere
o resto.

Feito para quem está começando ou nunca usou desenvolvimento orientado a
especificação e quer algo fácil, guiado passo a passo, em projetos de qualquer
linguagem.

> **Versão 0.1.0, em desenvolvimento.** Já funciona: o fluxo completo e a
> aprovação pelo chat. Ainda em construção: começar sem rodar nenhum comando,
> e a proteção (guard) instalada só no projeto. Veja "Limitações" no fim.

## O que é SDD e TDD, em poucas palavras

Duas práticas antigas e conhecidas, que o kit combina e automatiza:

- **SDD — Spec-Driven Development** (desenvolvimento orientado a
  especificação). Antes do código existe uma **spec**: um texto curto que diz
  o que o sistema deve fazer, escrito como exemplos de uso. Cada exemplo é um
  **cenário** no formato *DADO / QUANDO / ENTÃO* (vem do **BDD — Behavior-Driven
  Development**):

  > **DADO** um carrinho com 2 itens · **QUANDO** o cliente remove 1 item ·
  > **ENTÃO** o total mostra só o item que ficou

  A spec é o acordo entre você e a IA. Se não está na spec, não é feito.

- **TDD — Test-Driven Development** (desenvolvimento orientado a teste). Para
  cada cenário, a IA escreve **primeiro o teste**, roda e vê o teste **falhar**
  (fase **RED**, vermelho). Só depois escreve o código e roda de novo até
  **passar** (fase **GREEN**, verde). Por fim melhora o código sem mudar o
  comportamento (**REFACTOR**). Isso prova que o teste testa algo de verdade e
  que o código faz o que a spec pede.

**Por que isso ajuda com IA:** a IA é rápida, mas pode inventar, esquecer um
caso ou dizer "pronto" sem estar pronto. Com spec e teste antes, você tem um
critério objetivo: o trabalho só fecha quando cada cenário tem teste que falhou
antes e passa depois — e o kit confere isso sozinho.

## O que o kit faz por você

| Você | A IA, guiada pelo kit | O motor do kit (`tools/sdd/sdd.ps1`) |
|---|---|---|
| conta a ideia no chat | organiza em requisitos, conferindo o código | — |
| responde perguntas | escreve a spec com os cenários | confere o formato |
| **aprova** a spec e o plano | escreve testes (RED) e código (GREEN) | grava cada resultado de teste |
| — | pede uma revisão independente | só aceita "pronto" com tudo provado |
| faz o commit | arquiva e documenta o que mudou | o pre-commit recusa commit sem validação |

Você só entra nas decisões; o resto anda sozinho.

## Instalar no seu projeto

**Precisa de:** Windows, [Git](https://git-scm.com/), PowerShell (já vem no
Windows) e o Claude Code ou o Antigravity. O projeto precisa estar no Git
(`git init`, se ainda não estiver).

### 1. Coloque a pasta `SpecSimpleKit` dentro do seu projeto

O mais fácil: abra o chat da IA no seu projeto e peça

> **"Baixe a pasta SpecSimpleKit de https://github.com/Thander21/SDD-TDDkit para dentro deste projeto, sem o .git"**

A IA vai rodar algo assim (você pode rodar também, no terminal da pasta do projeto):

```powershell
git clone --depth 1 --filter=blob:none --sparse https://github.com/Thander21/SDD-TDDkit.git ..\tmp-ssk
git -C ..\tmp-ssk sparse-checkout set SpecSimpleKit
Move-Item ..\tmp-ssk\SpecSimpleKit .\SpecSimpleKit
Remove-Item -Recurse -Force ..\tmp-ssk
```

Resultado: `MeuProjeto\SpecSimpleKit\` com o kit. (Também dá para baixar o ZIP
do repositório no GitHub e copiar só essa pasta.)

### 2. Peça à IA para instalar

> **"Instale o SpecSimpleKit neste projeto"**

A IA identifica a linguagem do projeto e roda:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File SpecSimpleKit\install.ps1 projeto -Destino . -Perfil node
```

(perfis: `node`, `python`, `dotnet`, `flutter`, `rust`, `unity`, `unreal`,
`powershell`). **Não use o passo `maquina`** desta versão: ele mexe na
configuração global da IDE.

### 3. Peça o bootstrap

> **"Rode a skill sdd-bootstrap"**

A IA lê o seu projeto, faz até 5 perguntas (o que é, quais riscos importam,
idioma…), preenche o `AGENTS.md` e calibra os testes. Revise o que mudou e faça
o commit. Pronto: a partir daqui é só conversar.

## Seu primeiro uso

```text
Você: quero que o carrinho permita remover um item
IA:   registrei no backlog como item 01. Refino agora?
Você: refine o item 01
IA:   (lê o código, escreve requisitos, pergunta o que falta)
Você: item 01 Pronto
IA:   abri a change 01 com 3 cenários. Leia e aprove.
Você: aprovo P1 da change 01
IA:   (plano, tarefas e análise) Leia e aprove o plano.
Você: aprovo P2 da change 01
IA:   (teste falha → código → teste passa, cenário por cenário;
       revisão independente; tudo provado) GOAL PASS. Faço o commit?
```

O guia completo, com cada etapa e o que dizer, está em
[`docs/como-usar-fluxo.md`](docs/como-usar-fluxo.md).

## Os portões: só você aprova

| Portão | O que você confere | O que você escreve |
|---|---|---|
| **Pronto** | os requisitos do item estão certos | "item NN Pronto" |
| **P1** | a spec (os cenários) está certa | "aprovo P1 da change NN" |
| **P2** | o plano e as tarefas estão certos | "aprovo P2 da change NN" |
| **Commit** | o trabalho fechou | você faz (ou pede) |

A frase precisa dizer **aprovo**, o **portão** e a **change** (“change 01” ou
“CHG-001”). “Ok” ou “pode seguir” **não** aprovam — de propósito, para nada
passar sem você ler. A frase fica registrada na change.

## Palavras que você vai ver

| Termo | Significado |
|---|---|
| **backlog** | lista de ideias e pedidos (`Docs/Specs/backlog/`) |
| **change** | uma mudança aprovada, com spec, plano e tarefas (`Docs/Specs/changes/NN-nome/`) |
| **cenário** | um exemplo DADO/QUANDO/ENTÃO; cada um vira teste |
| **RED / GREEN** | teste falhando antes do código / passando depois |
| **spec viva** | o comportamento atual do sistema, atualizado a cada change concluída (`Docs/Specs/capabilities/`) |
| **verificador** | uma segunda IA, que não escreveu o código, confere tudo antes de fechar |
| **GOAL PASS** | o motor confirmou que a change está completa e provada |

## Atualizar e remover

- **Atualizar:** troque a pasta `SpecSimpleKit` pela versão nova (passo 1) e
  peça à IA "atualize o SpecSimpleKit" (`install.ps1 update -Destino .`).
- **Remover:** ainda manual nesta versão: apague os arquivos listados em
  `.sdd/kit.lock.json`, o próprio lock, o bloco `sdd-kit:begin/end` do
  `AGENTS.md` e a pasta `SpecSimpleKit`. Suas specs (`Docs/Specs/`) e o
  `.sdd/profile.json` ficam. Um comando de remoção está em desenvolvimento.

## Limitações desta versão

- Só Windows (PowerShell). Testado com Node, Python e .NET; Flutter parcial;
  Rust, Unity e Unreal são rascunhos.
- A instalação ainda copia arquivos para a raiz do projeto (`.agents/`,
  `.claude/`, `tools/sdd/`). A próxima versão lê tudo direto da pasta
  `SpecSimpleKit/`.
- A aprovação por frase é confiança, não trava: a máquina não prova que a
  frase veio de você.
- Cursor, Codex e Gemini CLI ainda não recebem atalhos próprios.

## Para quem quer ir fundo

- Referência técnica (arquivos no projeto, comandos do motor, perfis):
  [`docs/como-usar-fluxo.md`](docs/como-usar-fluxo.md) e
  [`Metodologia SDD.ai`](Metodologia%20SDD.ai) (texto Markdown).
- Comparação com Spec Kit, OpenSpec, Kiro, BMAD e outros:
  [diagnóstico comparativo](https://claude.ai/artifact/GCit5SpAwkbphRnXVsp6sB).
- O kit é desenvolvido com ele mesmo no repositório
  [SDD-TDDkit](https://github.com/Thander21/SDD-TDDkit). Histórico em
  [`CHANGELOG.md`](CHANGELOG.md).
