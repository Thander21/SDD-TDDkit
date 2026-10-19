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

## Simples no uso, poderoso na engenharia

Apesar de ser extremamente simples de usar (você apenas conversa no chat), o **SpecSimpleKit** é guiado por uma engenharia de ponta que unifica:

- **SDD (Spec-Driven Development):** nenhuma linha de código nasce sem uma especificação clara de negócio combinada previamente.
- **BDD (Behavior-Driven Development):** cenários em formato *DADO / QUANDO / ENTÃO*, transformando regras abstratas em critérios de aceite concretos e rastreáveis.
- **TDD (Test-Driven Development):** testes automatizados direcionados que comprovadamente falham antes (**RED**), passam com o código (**GREEN**) e são lapidados (**REFACTOR**).
- **Extreme Programming (XP / Agile Extreme):** programação em par com a IA (pair-programming), ciclos ultra-curtos de feedback, testes em primeiro lugar e refatoração contínua com portões estritos.

## Fluxo da IA: Quando ela para e quando roda em loop

O kit equilibra autonomia e controle total: você decide os rumos nas portas de entrada e saída; a IA cuida de toda a execução mecânica em loop autônomo.

| Etapa | O que a IA executa | Comportamento da IA | Ação do Humano |
|---|---|---|---|
| **1. Especificação da Change** | Audita o código existente, clarifica dúvidas e escreve a especificação com cenários BDD (`SPEC-.../Cn`). | 🛑 **Para e espera permissão** | Confere as regras e diz: `"aprovo P1 da change NN"` |
| **2. Plano Técnico & Tasks** | Detalha a arquitetura técnica, contratos, riscos e decompõe todas as tarefas da change inteira. | 🛑 **Para e espera permissão** | Revisa o plano e diz: `"aprovo P2 da change NN"` |
| **3. Implementação TDD** | Entra em loop contínuo: escreve teste que falha (**RED**), codifica até passar (**GREEN**) e refatora (**REFACTOR**), cenário por cenário. | ⚡ **Continua em loop até terminar** | Nenhuma (a IA implementa autonomamente) |
| **4. Verificação Independente** | Roda a suíte completa (`sdd validate`) e aciona um verificador independente anti-complacência (`sdd verify-record`). | ⚡ **Continua em loop até terminar** | Nenhuma (o motor audita a integridade) |
| **5. Fecho e Commit** | Consolida a spec viva, atualiza o histórico e entrega o resumo pronto do commit. | 🛑 **Para e entrega** | Você confere o diff e faz (ou pede) o commit |

## Instalar no seu projeto

**Precisa de:** Windows, [Git](https://git-scm.com/), PowerShell (já vem no
Windows) e o Claude Code ou o Antigravity. O projeto precisa estar no Git
(`git init`, se ainda não estiver).

### 1. Coloque o `SpecSimpleKit` dentro do seu projeto

No terminal da raiz do seu projeto (ou pedindo à IA no chat: *"Clone o SpecSimpleKit de https://github.com/Thander21/SpecSimpleKit.git"*):

```powershell
git clone --depth 1 https://github.com/Thander21/SpecSimpleKit.git SpecSimpleKit
```

> **Dica:** Para desvincular a pasta do Git interno dela dentro do seu repositório, basta remover a pasta `.git` de dentro dela:
> ```powershell
> Remove-Item -Recurse -Force .\SpecSimpleKit\.git
> ```

Resultado: `MeuProjeto\SpecSimpleKit\` pronto com o kit. (Também dá para baixar o ZIP do repositório no GitHub e extrair a pasta aqui).

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
IA:   criei a change 01 com a especificação e 3 cenários de negócio (DADO/QUANDO/ENTÃO). Leia e aprove.
Você: aprovo P1 da change 01
IA:   especificação aprovada! Elaborei o plano técnico, análise e as tarefas da change inteira. Leia e aprove.
Você: aprovo P2 da change 01
IA:   plano aprovado! Implementando via TDD (teste falha → código → teste passa), executando verificação independente... GOAL PASS da change 01. Posso fazer o commit?
```

O guia completo, com cada etapa e o que dizer, está em
[`docs/como-usar-fluxo.md`](docs/como-usar-fluxo.md).

## O ciclo de vida e as skills: quem faz o quê

Você não precisa aprovar micro-itens nem tarefas soltas: você aprova os portões fundamentais da change completa, enquanto a IA executa o trabalho com as skills especializadas:

| Fase / Portão | O que acontece | Qual Skill / Ferramenta roda | Ação do Usuário |
|---|---|---|---|
| **0. Setup Inicial** | Detecta a stack, cria `.sdd/profile.json` e configura `AGENTS.md` | `sdd-bootstrap` | Pede no chat: "Instale o SpecSimpleKit" |
| **1. Backlog & Ideação** | Levanta requisitos no código, cria cenários e refina o item | `backlog-refinement` | Conversa, responde dúvidas e diz "Pronto" |
| **Portão P0 (Tema)** | Valida o tema macro e abre a change em `Draft` | `backlog-refinement` (modo abrir) | Escreve: "aprovo P0 da change NN" |
| **Portão P1 (Especificação)** | Formaliza os cenários BDD (`DADO/QUANDO/ENTÃO`) no `change.md` | IA autônoma (regras `sdd-fluxo`) | Escreve: "aprovo P1 da change NN" |
| **Plano & Decomposição** | Elabora a análise técnica e gera o arquivo separado `tasks.md` | IA autônoma (regras `sdd-fluxo`) | Revisa `change.md` e `tasks.md` |
| **Portão P2 (Change + Tasks)** | Homologa a arquitetura, impact e a lista de tarefas técnicas | Motor SDD (`sdd approve NN P2`) | Escreve: "aprovo P2 da change NN" |
| **Implementação Contínua** | Loop autônomo TDD contínuo: RED (falha) ➔ GREEN (passa) ➔ REFACTOR | Motor SDD (`sdd test <alvo> --change NN`) | Acompanha a execução contínua sem travas |
| **Verificação Independente** | Reexecuta testes, audita mutações e emite `verify.md` formal | `sdd-verify` (subagente auditor) | 100% autônomo (quem codificou não aprova) |
| **Fecho (GOAL PASS)** | Motor audita gates, integridade, árvore e evidências | Motor SDD (`sdd goal NN`) | Confirma o veredito |
| **Arquivamento & Commit** | Promove deltas para `capabilities/` e arquiva em `concluidas/` | Motor SDD (`sdd archive NN`) | Diz: "faça o commit" |

A frase precisa dizer **aprovo**, o **portão** e a **change** (“change 01” ou
“CHG-001”). “Ok” ou “pode seguir” **não** aprovam — de propósito, para nada
passar sem você ler. Aprovado o P2, a IA implementa todas as tarefas de forma contínua até o fecho.

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

- **Atualizar:** atualize a pasta `SpecSimpleKit` (se manteve o clone com `.git`, basta rodar `git -C SpecSimpleKit pull`, ou clone a versão mais nova) e peça à IA "atualize o SpecSimpleKit" (`install.ps1 update -Destino .`).
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
