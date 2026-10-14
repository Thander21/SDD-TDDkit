---
trigger: model_decision
description: Revisão anti-complacência do kit SDD — Regra de Ouro, Verify Pass, prova de mutação, relatório do verificador e seção de descartados
---

# Revisão anti-complacência

> Gerenciado pelo sdd-kit. Vale para toda revisão, análise, verificação de
> change e relatório que a IA produz. Skills apontam para cá; não recopiam.

## 1. Regra de Ouro

- Proibido relatório confirmatório ("passou no linter", "já está simples",
  "testes passam") sem evidência de que os critérios foram checados contra o
  escopo real.
- Zero achados é resultado honesto **só** com a lista do que foi checado e
  não bateu (matriz, lentes, vetores).
- Todo achado traz: ID, severidade, `arquivo:linha` (ou evidência), cenário
  de falha concreto (entrada/estado → efeito errado), proposta acionável e
  veredito.
- Piso de achados, quando uma skill tiver, conta só CONFIRMADO. Nunca
  promova PLAUSÍVEL a CONFIRMADO para bater piso.

## 2. Verify Pass (antes de fechar qualquer relatório)

1. O cenário de falha se sustenta contra evidência real (código, saída de
   teste, resposta) ou depende de suposição?
2. Classifique: **CONFIRMADO** (reproduzível agora), **PLAUSÍVEL** (risco
   real que depende de contexto externo não provado nesta rodada) ou
   **DESCARTADO** (não sobreviveu à checagem).
3. CONFIRMADO e PLAUSÍVEL entram no corpo. DESCARTADO vira uma linha em
   **"Descartados na verificação"** (achado + motivo); a seção existe mesmo
   vazia.

## 3. Verify Pass de change (skill `sdd-verify`)

1. **RED, pelo ledger:** depois do GREEN o mesmo alvo passa, então o RED não
   se reexecuta. Confira no `evidence.jsonl`: resultado `falha` (não `carga`,
   `zero`, `erro` nem `inconsistente`), de preferência `confianca: relatorio`,
   e anterior ao `passou` do mesmo alvo.
2. **Bugfix:** o RED do ledger tem de ter rodado no código **com o bug**
   (antes do fix). Na dúvida, o achado é PLAUSÍVEL e a prova de mutação (§4)
   fica para quem implementou; o verificador não edita código.
3. **GREEN independente:** o verificador roda os alvos de novo com
   `sdd test`; o GREEN dele substitui o "GREEN duas vezes".
4. **Legado sem teste:** mudança de comportamento tem teste do trecho.
5. **Catch-all:** bloco alterado converteu ou justificou o catch-all.
6. **Casca:** nenhuma regra de negócio ficou em código de casca.
7. **Escopo:** nada fora do `impact` sem a change ter voltado à etapa 2.
8. **Não verificável:** liste os arquivos que o verificador não consegue ler
   (binários de engine, Blueprint, cena, asset). APROVADO significa "nada
   CONFIRMADO no que pude ver"; a lista diz o que não pude ver.

## 4. Prova de mutação (sem perder trabalho)

1. Copie o arquivo de produção para um temporário **fora** do repositório.
2. Reverta o trecho do fix ou injete a mutação mínima.
3. Rode `sdd test <alvo>`: o esperado é `falha` na asserção do cenário.
4. Restaure a cópia e rode o alvo de novo: `passou`.
5. Nunca use `git restore`, `git checkout -- <arquivo>` nem `git stash` para
   desfazer. De preferência, faça em worktree. Registre o resultado no
   relatório (não no `tasks`).

## 5. Relatório

Seções mínimas: escopo e modo; evidência de checagem (também com zero
achados); achados CONFIRMADO/PLAUSÍVEL com cenário e proposta; descartados na
verificação; **resumo da recomendação** (o que corrigir agora, o que adiar,
próximo passo, o que não fazer).

- Verificação de change: o corpo vai para `sdd verify-record <NN>
  APROVADO|REPROVADO` (stdin ou `--arquivo`). O motor grava o `verify.md` com
  `Veredito`, `arvore` e `head` no topo; o corpo não pode trazer essas linhas.
  O guard pede a sua confirmação nesse comando. Código alterado depois da
  verificação exige verificação nova.
- Pipe a partir do Windows PowerShell 5.1: antes, rode
  `$OutputEncoding = New-Object System.Text.UTF8Encoding $false`, senão
  acentos chegam como `?`.
- Outros relatórios: `.agents/reports/` (versionado). Relatório nunca é
  fonte de regra; decisão aceita sobe para change, backlog ou regra.
- Relatório anterior a uma correção diz que é fotografia pré-correção e
  ganha a seção "Aplicação das correções" depois.
