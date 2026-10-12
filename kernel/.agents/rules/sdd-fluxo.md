---
trigger: model_decision
description: Fluxo spec-driven do kit SDD — backlog, níveis, etapas e portões, change, TDD, evidência, rastreabilidade, desfecho tipado, archive e loop
---

# Fluxo SDD

> Gerenciado pelo sdd-kit. Os caminhos usam a raiz `projeto.specs_root` de
> `.sdd/profile.json` (padrão `Docs/Specs`). Comandos: `tools/sdd/sdd.ps1`.

## 1. Peças

| Peça | Local |
|---|---|
| Ideia | `<specs>/backlog/NN - Tema.md` (sem `NN` = provisório até o usuário numerar) |
| Change (o quê, porquê, como e tasks) | `<specs>/changes/NN-slug/change.md` |
| Evidência e verificação (só o motor grava) | `evidence.jsonl` e `verify.md`, na pasta da change |
| Spec viva (comportamento atual) | `<specs>/capabilities/<capacidade>/spec.md` |
| Registro de capacidades e IDs | `<specs>/capabilities/_index.md` |
| Moldes | `<specs>/_templates/{backlog,change,spec}.md` |
| Archive | `<specs>/concluidas/NN-slug/` |

- Não existe `plan.md`: o plano vive no `change.md`. A constituição do
  projeto é `AGENTS.md` + `.agents/rules/`; regra que deve sobreviver ao
  archive vai para lá, com o arquivo listado no `impact`.
- O legado não recebe retro-spec. A spec viva nasce na primeira change que
  toca a capacidade. Itens antigos não são reformatados em massa.

## 2. Prontidão do backlog (etapa 0)

`Levantamento` → `Requisitos` (IA, skill `backlog-refinement`) → `Pronto`,
`Adiado` ou `Descartado` (**só o usuário**, com motivo e data). "Solução"
escrita no levantamento é hipótese; caminho citado é conferido no código.

## 3. Níveis

| Nível | Quando | Documento | DoD |
|---|---|---|---|
| Trivial | bugfix localizado, texto, lint, ajuste mecânico | mensagem de commit | `sdd check` verde; bugfix com teste do trecho |
| Pequeno | ajuste em fluxo existente, sem contrato nem capacidade nova | `## Tasks` no item do backlog | tasks fechadas, `sdd test` em cada RED/GREEN, `sdd validate` verde, revisão independente do diff se houver lógica |
| Feature | capacidade ou contrato novo, ou risco declarado pelo projeto | change completa | `sdd goal NN` = `GOAL PASS` |

**Promoção automática para feature:** contrato público (API, formato de
arquivo, protocolo, save), schema ou persistência, tag de risco que o projeto
declarou como promotora (`AGENTS.md`, seção Riscos), ou mudança do
comportamento de um requisito `SPEC-…` de spec viva. Correção que faz o
código voltar a cumprir o requisito não promove. Na dúvida, pergunte.

## 4. Etapas e portões

| # | Etapa | Saída | Status |
|---|---|---|---|
| 1 | Especificação | Por quê + deltas com cenários `SPEC-<DOM>-NNN/Cn` | `Draft` |
| 2 | Clarificação | `## Perguntas em aberto` vazia; respostas viram `D<n>` | **P1**: usuário roda `sdd approve NN P1` → `Approved` |
| 3 | Plano | Decisões, Contratos, Invariantes por risco, `impact` | `Approved` |
| 4 | Tarefas | `## Tasks` RED → GREEN → REFACTOR por cenário | `Approved` |
| 5 | Análise (só feature) | `## Análise pré-implementação` | **P2**: `sdd approve NN P2` → `In-Implementation` + `base_ref` |
| 6 | Implementação | código + testes + evidência; verificador; `GOAL PASS` | `In-Implementation` |
| ↺ | Archive (a pedido do usuário) | deltas na spec viva; pasta em `concluidas/` | `Done` |

- **Clarificação:** só vira pergunta o que muda o resultado (regra,
  contrato, fonte normativa, escopo). Escolha com padrão óbvio vai para
  Decisões citando o padrão. Uma pergunta por vez, com a sua recomendação;
  cada resposta vira linha `D<n>` com a data e a fala do usuário.
- **Análise:** cenário sem task, task sem cenário, task fora do `impact`,
  arquivo do `impact` sem task, invariante de risco sem cenário, variante do
  desfecho sem cenário, caminho inexistente, fonte normativa ausente. Cita a
  implementação, não o comentário. Achado bloqueante volta à etapa 2 ou 3.
- **Aceite automatizável:** na etapa 3, todo aceite "o usuário executa"
  responde se é automatizável. O padrão é teste. Manual só para hardware,
  instalador ou sensação de jogo, em até 3 ou 4 passos, verificado por log ou
  consulta, nunca pelo relato.
- **Tamanho:** a change mira até ~250 linhas e não carrega diário de
  revisões (isso vai para o `verify.md` e para o commit). Acima de ~20
  cenários, 3 requisitos, 2 capacidades ou 40 arquivos no `impact`, recomende
  dividir antes do P1; quem decide é o usuário.

## 5. Change: campos e seções lidos pelo motor

- Frontmatter (subconjunto estrito de YAML; o motor falha fechado no resto):
  `id` (`CHG-NNN`, igual ao número da pasta), `title`, `status`, `capabilities`,
  `risk`, `fonte_normativa` (obrigatória nas tags de `projeto.riscos_com_fonte`),
  `base_ref` (só o `sdd approve P2` grava), `impact.modified_files` e
  `impact.new_files` (aceitam glob e pasta terminada em `/`).
- Seções de título fixo: `Perguntas em aberto`, `Análise pré-implementação`,
  `Tasks` (com a subseção `Pós-GOAL`, que o goal ignora), `Exceções`,
  `Aprovações` (só o `sdd approve` grava).
- Linhas de evidência: `- [x] RED (Cn): <alvo do sdd test> -> Falha esperada: <asserção>`
  e `- [x] GREEN (Cn): <alvo> -> passou`. O alvo é a string exata passada ao
  `sdd test`. O goal exige RED e GREEN com lastro para cada `Scenario: Cn`
  dos deltas. Cenário só provável à mão: `- [x] MANUAL (Cn): <roteiro de até
  4 passos> -> verificado por <quem>` (o goal lista como não verificado por
  máquina).
- O fecho (validate, verificador, goal) fica na subseção `Pós-GOAL` ou fora
  das Tasks: nunca marque `[x]` antecipando um resultado que ainda não rodou.
- Rebase ou squash que tira o `base_ref` da história: o usuário roda de novo
  `sdd approve NN P2`, que só re-ancora o `base_ref` no HEAD atual.
- **Bugfix:** seção `## Comportamento que não muda`, com um cenário de
  regressão por item, conferida na Análise.
- **Exceções:** só o usuário aceita uma exceção, com prazo. A change não
  fecha com exceção aberta: o resíduo vira item de backlog.

## 6. TDD

- **Test-first** para todo código escrito à mão que decide comportamento
  (domínio, serviços, contratos, validação, regras de tela ou de jogo).
- **Casca** (markup, layout, cena, prefab, animação, fiação de engine) pode
  nascer antes do teste; o teste da casca é obrigatório até o commit.
  **Proteção:** regra de negócio dentro de `build()`, handler de UI,
  `Update()`, `Tick()`, Blueprint ou Animator não é casca: sobe para unidade
  testável e entra no test-first. O perfil (`tdd`) diz o que é casca na stack.
- **RED válido** = o motor classificou `falha` (asserção). Não valem `carga`
  (compilação, import, erro de coleta), `zero` (nenhum teste rodou), `erro`
  (exceção ou timeout no corpo do teste) nem `inconsistente` (relatório verde
  com exit de falha). Use o stub do perfil (`tdd.stub_red`): a unidade existe
  e devolve valor errado. **GREEN** = `passou`.
- **Bugfix:** o RED é rodado **antes** do fix, no código com o bug; o ledger
  guarda a ordem (`falha` e depois `passou` no mesmo alvo). Sem esse RED, use a
  prova de mutação (`sdd-revisao.md` §4).
- **Gerados e mecânicos** (código gerado, barrel sem lógica, entrypoint) não
  entram no test-first; os gates da stack valem para eles.
- **Pré-requisito:** suíte verde antes do primeiro RED de uma change, rodada
  antes de escrever o teste. Falha conhecida fica em quarentena: o skip
  nativo da stack com motivo + item de backlog; teste em quarentena não serve
  de RED nem de GREEN.
- **Legado sem teste:** mudança de comportamento exige teste do trecho
  alterado; ajuste mecânico dispensa.
- **Hotfix sem tempo para o RED:** marcador `RED-pending: AAAA-MM-DD` no
  arquivo; o teste retroativo remove o marcador antes dessa data.
- **Spike** fica fora do código de produção; o que sobreviver entra pelo RED.
- **Evidência mínima por tipo:** bugfix = RED que reproduz o bug no código
  anterior à correção; feature = RED por cenário + GREEN; refactor = suíte do
  escopo igual antes e depois; dependência = changelog citado + `validate`;
  infra/config = backup ou rollback descrito + verificação por comando;
  asset/conteúdo = teste que carrega e afirma a ligação; sensação/playtest =
  evidência manual curta ou "Não verificado"; performance = medição com
  método, amostra e limite.
- **Testes:** mock só em fronteira externa; persistência real em memória
  quando a stack permite; não apague teste que guarda contrato; não aumente
  timeout para esconder falha; teste ignorado não prova aceite; cobertura %
  não é gate.

## 7. Rastreabilidade

- Cada teste que cobre um cenário carrega a tag literal `SPEC-<DOM>-NNN/Cn`
  no nome, descrição, atributo ou comentário colado ao teste (forma da stack
  em `rastreio.molde` do perfil). `<DOM>` tem 2 a 8 letras maiúsculas.
- O ID é reservado no `_index.md` no P1. O contador só sobe; ID removido
  nunca volta e vai para `Requisitos removidos` da spec viva.

## 8. Desfecho tipado e catch-all

- Falha de negócio esperada em operação nova ou contrato alterado devolve
  um desfecho tipado com todas as variantes, consumido de forma exaustiva
  (idioma da stack em `erro_idioma` do perfil). Um cenário por variante.
- Exceção fica para bug e infraestrutura inesperada.
- Catch-all novo só com rethrow, conversão no desfecho tipado ou comentário
  `catch-all: <motivo>` + telemetria. Legado não alterado fica como está;
  legado alterado converte ou justifica (conferido no Verify Pass).

## 9. Archive (depois do `GOAL PASS` e do pedido do usuário)

1. Capacidade sem spec viva: crie `capabilities/<x>/spec.md` pelo molde e
   registre no `_index.md`.
2. `ADDED` acrescenta o requisito; `MODIFIED` reescreve o bloco inteiro;
   `REMOVED` apaga e registra ID, change e motivo em `Requisitos removidos`.
3. Atualize as linhas de contrato e de testes dos requisitos tocados.
4. Acrescente `CHG-NNN | data | efeito` no histórico da spec viva.
5. `git mv` da pasta para `concluidas/` e `status: Done`.

Quem arquiva por último faz o rebase sobre a spec viva já atualizada. Achado
depois do archive que muda requisito abre change nova.

## 10. Loop, paralelismo e estado

- Estado durável: `change.md`, `evidence.jsonl`, `verify.md` e `.sdd/state/`
  (local). Sem `STATE.md`. Depois de compactar a conversa, releia a change.
- Condição de parada: a última linha do `sdd goal NN` (`GOAL PASS` ou
  `GOAL FAIL: …`). Três falhas seguidas no mesmo critério: pare e pergunte.
- Uma change ativa por worktree. Com duas ativas na mesma cópia, use
  `sdd test <alvo> --change NN`. Sessões paralelas em worktree ou branch
  próprio; a IA não faz merge.
