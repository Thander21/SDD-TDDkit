# Start pelo chat

> **Prontidão:** Pronto <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
> **Regra:** `.agents/rules/sdd-fluxo.md` §2. **Skill:** `backlog-refinement`.
> Arquivo: `<specs>/backlog/NN - Tema.md`; sem `NN` = provisório até o usuário numerar.

## Levantamento

Fala do usuário, 12/10/2026:

> primeiro esse deve ser um sdd e usamos como base do proprio teste,
> segundo quero que o projeto seja simples e facil para ser guiado e de
> autoexecução ou dentro do chat da ide ou cli se dentro do chat tivermos
> problemas de permissao, entao o start inicial não deve ser comando e sim o
> chat inicia o projeto sdd-tddkit por exemplo e a ia ira guiar

> validação de start via chat sem instalador a ia deve fazer as perguntas
> iniciais se nao reconhecer nenhum projeto para iniciar ou ler o projeto
> atual para implementar a metodologia do miniframework

Contexto da sessão (pesquisa de 12/10/2026 sobre como outros frameworks
instalam, resumida na conversa):

- Hoje o início é por terminal: `SpecSimpleKit/install.ps1` ou
  `instalar.cmd`, depois a skill `sdd-bootstrap` no chat.
- Digitar o caminho do projeto no cmd foi difícil; o assistente interativo
  aplicou o guard da máquina antes de perguntar o projeto; Ctrl+C no `.cmd`
  gera "Deseja finalizar o arquivo em lotes".
- OpenSpec ("Fetch install.md and follow it"), BMAD v7 (`bmad setup` no
  chat, script devolve JSON e a IA pergunta) e superpowers (plugin) já
  iniciam pelo chat. Nenhum deles usa seletor de pasta: a pasta é a aberta
  na IDE.
- Dentro do chat do Claude Code o stdin é redirecionado e `CLAUDECODE` está
  definida; o assistente atual aceita todos os padrões em silêncio nesse
  modo (reproduzido na pesquisa).
- Tag de risco `start-chat` declarada no `AGENTS.md` (Riscos do projeto).

## Requisitos

<!-- Preenchido pela skill backlog-refinement. Fato do código cita
arquivo:linha; o que não foi conferido fica marcado como hipótese. -->

### Problema e valor

Quem sofre: o dev solo que quer usar o SpecSimpleKit num projeto novo ou
existente. Hoje ele precisa saber o caminho do kit, abrir um terminal,
escolher o perfil e só depois voltar ao chat para o `sdd-bootstrap`; no uso
real de 12/10/2026 isso falhou (caminho difícil de digitar, guard global
aplicado antes do projeto, Ctrl+C no `.cmd`). Melhora: o início e cada etapa
seguinte acontecem no chat da IDE ou da CLI da IA, guiados por skills, com o
script determinístico fazendo as gravações.

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|
| Início por comando no terminal | sim | `SpecSimpleKit/install.ps1:18` (ações `projeto`, `check`, `update`, `maquina`) |
| Bootstrap pressupõe instalador já rodado | sim | `SpecSimpleKit/kernel/.agents/skills/sdd-bootstrap/SKILL.md:8-9` |
| Instrução para a IA iniciar numa pasta sem o kit | não existe | o kernel só chega ao projeto depois da instalação; não há skill nem documento fora dele |
| Instalação rodada pela IA com parâmetros | sim | executada nesta sessão em 12/10/2026 (exit 0); exige pasta git e `-Perfil` (`install.ps1:84`, `:262`) |
| Instalador detecta agente (stdin redirecionado, `CLAUDECODE`) | não | sem `IsInputRedirected`/`CLAUDECODE` em `install.ps1`; o motor já detecta (`kernel/tools/sdd/sdd.ps1:964-969`); `CLAUDECODE=1` no chat do Claude Code (observado) |
| Assistente aceita padrões em silêncio quando chamado por agente | sim (defeito) | `Read-Host` sem guarda em `install.ps1:61-75`; reproduzido na pesquisa de 12/10/2026 |
| Detecção de kit já instalado | sim | `.sdd/kit.lock.json` (`install.ps1:265`) |
| Retomar: mostrar onde parou | parcial | `sdd status` mostra gates e changes, não backlog (`sdd.ps1:1196-1211`) |
| Guard impede a IA de rodar `install.ps1 maquina` | não | `machine/guard.ps1` sem regra para o instalador |
| Ferramentas atendidas | Claude Code e Antigravity | `kernel/.claude/`, `kernel/.agents/`; Gemini CLI, Cursor e Codex não têm adaptador |

### Requisitos funcionais

- **RF1:** O início é uma skill: o usuário digita `/<skill>` ou descreve o
  pedido em texto e a IA reconhece a skill (R1).
- **RF2:** Em cada etapa (iniciar, bootstrap, refinar, implementar,
  verificar, retomar) a IA escolhe a skill adequada à etapa e diz qual está
  usando (R1).
- **RF3:** Pasta sem o kit: a IA diz qual pasta vai usar (a aberta na IDE ou
  o cwd da CLI) e faz as perguntas iniciais; pasta sem projeto reconhecível:
  pergunta o que o projeto será antes de iniciar (levantamento).
- **RF4:** Na instalação, a primeira pergunta é para quais ferramentas
  configurar, com múltipla escolha: Antigravity, Gemini, Claude, Cursor e
  Codex; a escolha define as pastas de destino (R1).
- **RF5:** A IA mostra o plano (pasta, ferramentas, perfil, arquivos que
  serão gravados) e só grava depois da confirmação do usuário no chat.
- **RF6:** Pasta com o kit: a IA lê o estado (perfil calibrado, gates,
  backlog com Prontidão, changes ativas) e diz onde parou e o próximo passo.
- **RF7:** Se o chat não puder executar comandos (permissão negada ou sem
  shell), a IA explica em linguagem simples qual permissão liberar na
  ferramenta e retoma depois; não pede para o usuário usar o terminal
  (R1 do item "Assistente do instalador", 12/10/2026).
- **RF8:** Ao fim da instalação, o bootstrap segue no mesmo chat.
- **RF9:** Na primeira vez numa máquina, uma frase no chat (apontando o
  documento de início do kit) instala a skill de início no nível do usuário,
  em cada ferramenta escolhida; depois disso a skill funciona em qualquer
  pasta sem caminho (R2).
- **RF10:** O kit sai do projeto como entrou: um comando (ou a skill) remove
  só o que o kit instalou e o que o lock registra (arquivos gerenciados,
  bloco do `AGENTS.md`, linhas do `.gitignore`, hook de pre-commit),
  mostrando o plano antes; preserva o que é do projeto (specs, backlog,
  changes, seção Projeto do `AGENTS.md`) salvo pedido explícito; depois disso
  a instalação pode recomeçar do zero (R3).

### Regras de negócio e restrições

- **RN1:** Instalador chamado por agente sem os parâmetros necessários falha
  com o comando completo que resolveria; nunca usa padrão silencioso. Fonte:
  defeito reproduzido em 12/10/2026; riscos `start-chat`, `config-global`.
- **RN2:** A IA nunca roda o passo `maquina` nem `sdd approve`; no máximo
  sugere ao usuário rodar no terminal dele. Fonte: riscos `portao-humano`,
  `config-global` (`AGENTS.md`, Riscos do projeto).
- **RN3:** Quem grava arquivos é o script do kit (lock com sha256), nunca a
  IA à mão. Fonte: risco `contrato-do-motor`; `install.ps1:245` (Write-Lock).
- **RN4:** Comportamento equivalente nas ferramentas escolhidas; o que uma
  delas não suportar fica dito na resposta. Fonte: R1.
- **RN5:** Pasta de destino de cada ferramenta segue a documentação oficial
  dela, citada com data. Hipótese até conferir: Claude `.claude/skills/`,
  Antigravity `.agents/skills/`, Gemini CLI `.gemini/`, Cursor
  `.cursor/rules/`, Codex `AGENTS.md` + `.agents/skills/`.
- **RN6:** A instalação da skill global é a única gravação fora do projeto
  no start: mostra o plano (arquivos e pastas do usuário), pede confirmação,
  faz backup do que já existir e tem como desfazer. Fonte: R2; risco
  `config-global`.
- **RN7:** A instalação não grava nada fora do que o lock vai registrar
  (exceto o hook em `.git/hooks`, também registrado), para a remoção da RF10
  ser completa. Fonte: R3; risco `arquivo-do-usuario`.

### Fora de escopo

- Plugin do Claude Code e `agy plugin` (distribuição por marketplace).
- Seletor de pasta do Explorer, arrastar para o `.cmd`, menu de contexto,
  comando curto no PATH.
- Defeitos do assistente de terminal além da RN1 (item "Assistente do
  instalador").
- Perfil `powershell` e relatório JUnit (item "Perfil powershell").

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|
| U1. Instalador em modo agente: `detectar` (estado da pasta, perfil sugerido, kit instalado), `-Plano` (lista sem gravar), `-Ferramentas`, recusa sem parâmetros (RN1), `remover` com plano (RF10, RN7) | feature | instalador (`INST`) | `start-chat`, `config-global`, `arquivo-do-usuario` | — |
| U2. Adaptadores de ferramenta: Gemini CLI, Cursor e Codex além de Claude e Antigravity (RF4, RN5) | feature | instalador (`INST`) + fluxo (`FLUXO`) | `contrato-do-motor`, `arquivo-do-usuario` | U1 |
| U3. Skills de entrada e roteamento: iniciar/retomar pelo chat, escolha da skill por etapa, fallback de comando colável (RF1-3, RF5-8) | feature | fluxo (`FLUXO`) | `start-chat`, `portao-humano` | U1 |
| U4. Primeira vez: documento de início + instalação da skill global por ferramenta, com plano, backup e desfazer (RF9, RN6) | feature | instalador (`INST`) | `start-chat`, `config-global` | U1, U2, U3 |

### Perguntas para o usuário


### Respostas

| # | Resposta | Data |
|---|---|---|
| R1 | "skills para utilizar /nomedaskil ou texto que ja reconhece a skill a ser utilizada, sempre deve buscar uma melhor skill para a etapa correta, inclusive a etapa da instalação deve perguntar qual ide e ai para saber em qual pasta deve ser instalado deixando a configuração para as principais do mercado antigravit gemini, claude, cursor e codex podem marcar mais de uma no inicio da pergunta." | 12/10/2026 |
| R2 | Primeira vez: skill global instalada uma vez por uma frase no chat (opção "Skill global 1x"); depois `/sdd-iniciar` em qualquer pasta. | 12/10/2026 |
| R3 | "vou iniciar ele vai estar na configuração sem sujar o projeto podendo deletar depois a pasta, na implantação vai perguntar sobre a ide e a ai e ler sobre o projeto ou iniciar a fase de pergunta do que se trata orientando corretamente a instalação inicial para depois iniciarmos o alinhamento do backlog, specs, plan, task" | 12/10/2026 |
| R4 | Substitui R2, RF9, RN6 e U4: nada global, nem a skill de início; ver `backlog/05 - Kit so no projeto.md`. | 14/10/2026 |

## Tasks

<!-- Só no nível pequeno: mesmas regras de evidência da change (sdd test). -->

## Encaminhamento

<!-- Quando a Prontidão vira Pronto, Adiado ou Descartado: change aberta,
tasks neste item, commit trivial, ou motivo e data. -->

- 12/10/2026: Pronto pelo usuário ("sim abra a chg 001", em resposta à
  proposta de numeração e de "item 01 Pronto").
- U1 → `changes/01-instalador-modo-agente/change.md` (CHG-001, Draft).
- U2, U3 e U4: changes seguintes, abertas depois da CHG-001.
