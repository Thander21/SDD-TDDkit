# Assistente do instalador

> **Prontidão:** Pronto <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
> **Regra:** `.agents/rules/sdd-fluxo.md` §2. **Skill:** `backlog-refinement`.
> Arquivo: `<specs>/backlog/NN - Tema.md`; sem `NN` = provisório até o usuário numerar.

## Levantamento

Achados de 12/10/2026 (uso real do usuário + pesquisa, reproduzidos sem
alterar o repositório):

- O assistente (`install.ps1` sem parâmetros) perguntou e aplicou o guard
  da máquina antes de perguntar o projeto; o usuário cancelou no passo
  seguinte e ficou com `~/.claude/settings.json` e
  `~/.gemini/config/hooks.json` alterados (fala: "copiou os arquivos sem
  saber o projeto nem qual ia!").
- Com stdin redirecionado (chat da IA, CI) o `Read-Host` volta vazio e o
  assistente aceita todos os padrões: `git init`, árvore suja e perfil.
- Rodado de dentro da pasta do kit, o prompt "Pasta do projeto:" fica sem
  padrão; Enter dá `ERRO: informe -Destino`; no duplo clique a janela fecha.
- Arrastar a pasta para o `instalar.cmd` cai no `ValidateSet` de `$Acao`.
- `git init` com padrão "S" em qualquer pasta; o próprio kit não é recusado
  como destino; não há resumo do plano antes de gravar.
- O `ConvertTo-Json` do merge reformata o `~/.claude/settings.json` inteiro
  (não verificado).
- Pasta existente com outra caixa (`docs/` x `Docs/Specs`): o kit gravou
  dentro da existente e o perfil ficou com a caixa errada; corrigido à mão
  no `.sdd/profile.json` deste repositório.
- Outros frameworks: projeto primeiro, global por último e explícito;
  proteção por hash do manifesto em vez de exigir árvore limpa.

Tags prováveis: `config-global`, `arquivo-do-usuario`. Relação com o item
"Start pelo chat": se o início passar a ser pelo chat, parte disto muda de
forma.

## Requisitos

<!-- Preenchido pela skill backlog-refinement. -->

### Problema e valor

Quem sofre: o dev solo que usa o terminal para instalar (hoje o único
caminho, e depois do item "Start pelo chat" o caminho de reserva, RF7 de
lá). O assistente atual grava config global antes de saber o projeto, aborta
em vez de perguntar de novo e tem padrões perigosos; o passo `maquina`
reescreve arquivos do usuário sem mostrar o que muda e sem desfazer.

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|
| Guard da máquina perguntado e aplicado antes do projeto | sim (defeito) | `SpecSimpleKit/install.ps1:505-513` roda `Invoke-Maquina` antes de `Resolve-Destino` (`:514`) |
| Assistente aceita padrões com stdin redirecionado | sim (defeito) | `Read-Host` sem guarda (`install.ps1:61-75`); coberto pela RN1 do item "Start pelo chat" |
| Rodado da pasta do kit, prompt sem padrão e Enter = erro | sim | padrão zerado em `install.ps1:81`; `throw 'informe -Destino'` em `:84` |
| Janela fecha no duplo clique (sem pausa) | sim | `SpecSimpleKit/instalar.cmd:4-5` sem `pause` |
| Pasta arrastada para o `.cmd` cai no `ValidateSet` | sim | `%*` repassa como posicional (`instalar.cmd:4`); `ValidateSet` em `install.ps1:18`; reproduzido na pesquisa de 12/10/2026 |
| `git init` com padrão "S" | sim | `install.ps1:89` (`Read-SimNao ... $true`) |
| Kit recusado como destino | só o padrão | `install.ps1:81` filtra o padrão; caminho digitado não é conferido (hoje a pasta do kit resolve para a raiz deste repositório, que é um projeto legítimo) |
| Erro de entrada pergunta de novo | não | caminho inexistente e perfil inválido abortam (`install.ps1:86`, `:262-264`) |
| Resumo do plano antes de gravar | não | o plano é calculado (`install.ps1:285-296`) mas não mostrado nem confirmado |
| Arvore suja | aviso + confirmação no assistente; bloqueio com parâmetros | `install.ps1:125-136` |
| Merge reescreve o `~/.claude/settings.json` inteiro | sim | `ConvertFrom-Json` + `ConvertTo-Json -Depth 32` do arquivo todo (`install.ps1:443`, `:457`) |
| `~/.gemini/config/hooks.json` gravado mesmo sem Antigravity | sim | gravação incondicional dos dois arquivos (`install.ps1:491-497`) |
| Desfazer o passo `maquina` | não | só backup `.bak-<ts>` (`install.ps1:494`); nenhuma ação de restauração |
| Guard instalado detectado | só pela existência do arquivo | `install.ps1:505`; `maquina` sem `-Aplicar` nunca mais é oferecido; hook desatualizado não é detectado |
| Aviso de versão mínima do Claude Code | só sem `-Aplicar` | `install.ps1:484` |
| Pasta com outra caixa (`docs/` x `Docs/Specs`) | sim (defeito) | perfil copiado com `Docs/Specs` (`install.ps1:273-274`); NTFS grava dentro da pasta existente; corrigido à mão neste repositório em 12/10/2026 |
| Ctrl+C no `.cmd` | sim | pergunta "finalizar o arquivo em lotes" do cmd; sem solução limpa dentro de `.cmd` (pesquisa de 12/10/2026) |

### Requisitos funcionais

- **RF1:** O usuário não usa o terminal em nenhuma etapa da instalação: não
  há assistente interativo de terminal nem lançador `.cmd`; o instalador é
  chamado só pela IA, com parâmetros completos (R1).
- **RF2:** O passo de máquina (guard) acontece pelo chat, depois do projeto,
  como passo explícito: a IA mostra o que muda em cada arquivo do usuário
  (diff), só para as ferramentas instaladas na máquina, e grava só com
  confirmação (R1; risco `config-global`).
- **RF3:** O passo de máquina tem desfazer: restaura o estado anterior a
  partir do backup e diz o que restaurou.
- **RF4:** O merge na config do usuário preserva o resto do arquivo (só as
  chaves do kit mudam no diff).
- **RF5:** O kit sabe se o guard instalado está aplicado e atualizado
  (versão ou hash), e avisa quando não está.
- **RF6:** Pasta de specs que já existe com outra caixa é reconhecida: o
  perfil do projeto passa a usar a caixa existente.
- **RF7:** Antes de gravar no projeto, o plano (pasta, ferramentas, perfil,
  arquivos novos e alterados, arquivos pendentes no Git) é mostrado no chat e
  confirmado; `git init` só com confirmação explícita, padrão não.
- **RF8:** Toda resposta da IA termina indicando o próximo passo do fluxo em
  linguagem simples (ex.: "responder as perguntas X e Y", "ler o documento
  Z, alterar o que for necessário e aprovar", "pedir revisão", "criar a
  change", "ir para as tasks") (R2).
- **RF9:** Os portões P1 e P2 são aprovados por uma frase do usuário no chat
  (ex.: "aprovo P1 da change 01"); a IA indica o documento a ler antes e só
  registra a aprovação depois da frase, citando-a literalmente no registro
  (R2).

### Regras de negócio e restrições

- **RN1:** Público: quem não é desenvolvedor ou não conhece a metodologia;
  toda etapa é guiada pela IA no chat, em linguagem simples (R1).
- **RN2:** Nenhum arquivo fora do projeto muda sem plano mostrado e
  confirmação (risco `config-global`; incidente de 12/10/2026).
- **RN3:** Quem grava é o script do kit, nunca a IA à mão (RN3 do item
  "Start pelo chat").
- **RN4:** A aprovação por frase é honra, não imposto: a máquina não impede
  a IA de registrar sem a frase. Aceito pelo usuário para dar tempo de ler e
  editar o documento (R2). Mitigação: o registro cita a frase literal e a
  data, e o verificador confere se a frase existe na conversa quando houver
  transcrição (hipótese a conferir).

### Fora de escopo

- Skill de início, detecção, `-Plano`, `remover` e adaptadores de
  ferramenta: item 01 "Start pelo chat" (`changes/01-instalador-modo-agente/origem/`, U1 a U4). Este item depende da U1 de
  lá.
- Seletor de pasta, arrastar para o `.cmd`, menu de contexto, PATH:
  descartados pela R1 (sem terminal, sem lançador).
- Documentação da metodologia SDD + TDD + BDD + XP + loop: item novo
  "Metodologia documentada e guiada".

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|
| U1. Remover assistente interativo, `Read-Host` e `instalar.cmd`; instalador só por parâmetros (RF1) | feature | instalador (`INST`) | `start-chat` | U1 do "Start pelo chat" |
| U2. Passo de máquina pelo chat: diff, só ferramentas presentes, merge que preserva o arquivo, desfazer, detecção de guard desatualizado (RF2-RF5) | feature | guard (`GUARD`) + instalador (`INST`) | `config-global`, `portao-humano` | U1 |
| U3. Plano confirmado antes de gravar, `git init` padrão não, caixa da pasta de specs (RF6, RF7) | feature | instalador (`INST`) | `arquivo-do-usuario` | U1 do "Start pelo chat" |
| U4. Aprovação por frase no chat: `sdd approve` aceita a IA com a frase citada; guard e edit_guard ajustados (RF9, RN4) | feature | motor (`MOTOR`) + guard (`GUARD`) | `portao-humano`, `contrato-do-motor` | — |
| U5. Próximo passo sempre indicado (RF8) | pequeno | fluxo (`FLUXO`) | — | — |

### Perguntas para o usuário

### Respostas

| # | Resposta | Data |
|---|---|---|
| R1 | "sem terminal somente pelo assitente o projeto e para ser simples e facil sem codigos no terminal somente comandos no chat e texto para ia definir a skill e o passo correto, é um framework guiado para quem nao é desenvolvedor ou nao tem conhecimento exato da metodologia por isso deve sempre guiar e ter documentado a metodologia sdd + tdd + bdd + xp + loop + validações extras do escopo" | 12/10/2026 |
| R2 | "frase no chat, para dar tempo da pessoa ler o documento e editar o que for então sempre indique o proximo passo "responder peguntras xyz", "ler o documetno xy alterar o que necesario e aprovar", pedir revisao, criar change, ir para tasks, enfim sempre sugira o proximo passo orientando corretamente o fluxo." | 12/10/2026 |
| R3 | "no chat nada de terminal podemos aprovar o uso da ia no terminal mas os comandos todos no chat com texto ou /" (a IA roda os comandos, inclusive o `approve`, e o usuário só libera a permissão da ferramenta e escreve no chat) | 14/10/2026 |

## Tasks

## Encaminhamento

- 14/10/2026: Pronto pelo usuário (escolheu "Exceção única": abrir a CHG-002
  com a U4 à frente da CHG-001).
- U4 → `concluidas/02-aprovacao-pelo-chat/change.md` (arquivada em 16/10/2026) (CHG-002, Draft), primeira
  a ser implementada.
- U1, U2, U3 e U5: changes seguintes, que citam este caminho.
