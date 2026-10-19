# Changelog do SpecSimpleKit

## Não lançado

- Modo Pasta Autocontido (CHG-001): o kit opera dentro de `SpecSimpleKit/` sem copiar regras ou motor para a raiz do usuário. Início conversacional via chat (`detectar` e `modo-pasta`), remoção limpa (`remover -ModoPasta`) com zero resíduo do kit no projeto, e suíte de desenvolvimento movida para fora do pacote distribuído (`tests/` na oficina), mantendo a pasta `Specs/` preservada intacta como documentação viva.
- Portão P0 de Tema do Plano e ciclo contínuo pós-P2 (CHG-006): portão inicial antes da clarificação detalhada, mantendo a IA em loop autônomo contínuo até a entrega após a aprovação de P2.
- Changes completas têm gates P1/P2 únicos por documento; RED/GREEN pode ser agrupado por suíte/alvo com cobertura de cenários agregada no goal. Limites normais: até 2 capacidades relacionadas, 4 requisitos, 12 cenários, cerca de 20 arquivos de produto e 400 linhas no change.md. Excedentes exigem justificativa de coesão e validação no P1; specs vivas podem crescer sem teto de extensão.
- `sdd archive <NN>` exige GOAL PASS final e `verify.md` APROVADO para a árvore atual; grava `Done` e move a change completa para `concluidas/` sem criar commit.

- A ferramenta passa a se chamar SpecSimpleKit e mora em `SpecSimpleKit/`
  dentro do repositório SDD-TDDkit, cuja raiz é o projeto de desenvolvimento
  (com o próprio método). Identificadores técnicos seguem `sdd-kit`, para
  não quebrar os projetos instalados.
- README com início rápido: `git clone`, `instalar.cmd` e bootstrap.
- `install.ps1` sem parâmetros vira assistente (`instalar.cmd` chama com
  `-ExecutionPolicy Bypass`): pergunta a pasta (padrão: a atual), oferece
  `git init`, detecta o perfil pela stack, oferece o guard da máquina na
  primeira vez e o update quando o kit já está instalado. Árvore suja só pede
  confirmação. O modo com parâmetros não mudou.

- Ao abrir uma change, o item do backlog que a gerou é movido para
  `changes/NN-slug/origem/` (fluxo §1, skill `backlog-refinement` modo
  abrir, molde da change): a change guarda a documentação de origem.

- `docs/como-usar-fluxo.md`: guia de uso pelo chat (fluxo do pedido ao
  código pronto, pastas, portões e o que dizer em cada etapa).

- `sdd approve <NN> P1|P2 --frase "<frase do usuário>"` (CHG-002): a IA
  aprova o portão com a frase do usuário no chat, que precisa citar
  aprovação, portão e a change ("change 02" ou "CHG-002"; número solto não
  vale); a frase fica na linha de aprovação
  (`via chat: "..."`). Sem `--frase`, a IA continua recusada; o formato
  antigo da linha continua válido. É honra, não imposto (núcleo atualizado).

## 0.1.0 — 12/10/2026

Primeira versão, extraída da metodologia do ERP PDV D+ (CHG-049, CHG-050,
CHG-087, CHG-088), da auditoria de 10/10/2026 e de um painel de revisão com
5 lentes (custo para dev solo, fidelidade ao método, OpenSpec, stacks de
jogo, segurança).

- **Núcleo:** regras `sdd-core` (sempre ativa), `sdd-fluxo` e `sdd-revisao`
  (sob demanda); moldes de backlog, change e spec viva (cabeçalhos no formato
  do OpenSpec); skills `backlog-refinement`, `sdd-verify` e `sdd-bootstrap`;
  subagente `sdd-verifier` sem Write/Edit; `learn` com destino "upstream do kit".
- **Motor `tools/sdd/sdd.ps1`:** `check`, `validate`, `fix`, `test`,
  `spec-lint`, `goal`, `approve`, `verify-record`, `commit-gate`,
  `install-hook`, `calibrate`, `status`.
  - frescor pela árvore (`git write-tree` de um índice temporário), não por mtime;
  - evidência gravada pelo próprio motor, com classificação
    `falha`/`passou`/`carga`/`zero`/`erro`/`inconsistente` por relatório estruturado (JUnit, TRX,
    NUnit3, JSON do dart/flutter test, index.json do Unreal) e padrões;
  - `approve` só em terminal humano (recusa stdin redirecionado e sessão do
    Claude Code);
  - frontmatter estrito que falha fechado.
- **Instalador:** `projeto`, `check`, `update` (lock com sha256, `.kitnew`
  para texto editado, recusa para executável editado, sem gravação parcial) e
  `maquina` (guard + permissões no escopo do usuário, com backup e merge).
- **Guard da máquina:** git normalizado (-C, -c, git.exe, aspas, +refspec),
  checkout/restore/clean/reset, commit/push, rm/Remove-Item recursivo,
  iex/-EncodedCommand, SQL destrutivo, escrita direta em ledger.
  **edit_guard:** nega status de portão, `base_ref`, linha de aprovação e
  edição de `evidence.jsonl`/`verify.md`.
- **Perfis:** node, python e dotnet testados; flutter testado na variante
  dart puro; rust, unity e unreal em rascunho (`calibrado: false`).
- **Verificação independente antes da entrega** (subagente sem acesso de
  escrita ao kit, sandbox próprio). As correções:
  - goal sem evidência passava → exige RED e GREEN com lastro por cenário;
  - commit de outra frente reprovava → vira aviso; só o working tree reprova;
  - caminho com acento → `core.quotepath=false`;
  - P1 pulável com status entre aspas → edit_guard lê aspas, e P2 e goal
    exigem P1;
  - `fonte_normativa` passa a ser cobrada no approve e no goal;
  - exit diferente de 0 com relatório verde → `inconsistente`; exceção → `erro`;
  - perfil rust com `docs/specs` → raiz resolvida antes de gravar e
    comparação sem caixa;
  - `{raiz}` nos gates e `^`/`$` no alvo (perfil unity);
  - task "Fecho" circular movida para Pós-GOAL;
  - RED do verificador conferido pelo ledger;
  - edit_guard cobre `.sdd/state/` e `specs_root` próprio;
  - instalação sem gravação parcial com marcador quebrado;
  - sondas amarradas ao perfil;
  - `--pre-verify` não conta como GOAL PASS;
  - P2 re-ancora o `base_ref` depois de rebase;
  - guard pede confirmação no `verify-record`.
- **Testes:** 226 asserts por interpretador (`tests/run_all.ps1`), nos dois
  interpretadores.
