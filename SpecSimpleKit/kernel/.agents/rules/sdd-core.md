---
trigger: always_on
description: Núcleo do kit SDD — comportamento da IA, portões humanos, evidência, fecho de entrega e o que é imposto por máquina
---

# Núcleo SDD

> Gerenciado pelo sdd-kit: não edite neste projeto. Lição de método vai para
> o INBOX do repositório do kit (skill `learn`); regra de domínio vai para
> `.agents/rules/<dominio>.md` do projeto. O projeto pode endurecer o núcleo,
> nunca afrouxar.

## Comportamento

- Idioma de respostas, planos, commits e comentários: o do `AGENTS.md`.
  Identificadores no idioma do código.
- **Scope guard:** pedido que contraria arquitetura, segurança ou guardrail,
  ou que traz dependência não aprovada → alerte e peça revisão antes. Nunca
  exceção silenciosa. Dependência nova: aprovação do usuário + changelog lido.
- **Sem invenção:** toda afirmação normativa cita a fonte (regra, decisão
  `D<n>`, doc oficial com data ou medição). O que não conferiu é "não
  verificado". O código vale mais que o documento: confira antes de afirmar.
- **Segredos e PII:** não leia nem exiba `.env`, chaves, certificados ou
  senhas; mascare dados pessoais em log, telemetria e relatório.
- **Commit, push e merge são do usuário.** A IA não faz commit nem push por
  iniciativa própria; só quando o usuário pede, e a ferramenta confirma.
- Para desfazer mutação de teste em arquivo com mudança não commitada,
  copie para um temporário antes e restaure a cópia. Nunca `git restore` nem
  `git checkout -- <arquivo>`.
- Não altere dependências de terceiros (`vendor/`, `node_modules/`, pacotes)
  nem arquivos gerados: use wrapper, adapter ou o gerador.
- Dado corrompido se corrige em script avulso, nunca na lógica permanente.
- No Windows, renomear só a caixa de arquivo ou pasta exige `git mv` em dois
  passos (`X` → `tmp` → `x`); senão o Git não registra a troca.
- Duas regras em conflito: relate e pergunte. Segurança vem primeiro.

## Fluxo (detalhe em `.agents/rules/sdd-fluxo.md`: leia antes de trabalho não trivial)

- Classifique o nível (trivial, pequeno, feature) e aplique a promoção
  automática. Na dúvida, pergunte.
- A spec viva da capacidade é leitura obrigatória antes de refinar, abrir
  change ou alterar o código que ela cobre.
- **A IA nunca se autoaprova.** P1 e P2 só com a frase do usuário que cita
  aprovação, portão e change ("aprovo P1 da change 01"): a IA roda
  `sdd approve <NN> P1|P2 --frase "<frase>"`. "Ok" ou "segue" não aprovam.
- **Quem implementa não declara pronto:** o fecho é do verificador
  independente (skill `sdd-verify`).
- Escopo novo no meio da implementação devolve a change à clarificação.
- RED e GREEN só com `sdd test <alvo>`: o motor grava a evidência. Nunca
  marque `[x]` sem ter rodado.
- Execução sem supervisão declara teto de turnos e custo, e para depois de 3
  `GOAL FAIL` seguidos no mesmo critério, devolvendo a decisão ao usuário.

## Fecho de entrega (toda tarefa não trivial)

1. Evidência desta rodada para cada afirmação.
2. Gate proporcional: `sdd check` depois de alterar; `sdd validate` antes de
   commit e no fecho da change. Se quebrar pela alteração, reverta a causa;
   não suprima o erro.
3. Resumo de 3 a 5 linhas: o que fazer agora, o que adiar e o próximo passo,
   mais a linha **"Não verificado:"** com o que ficou sem prova.

## O que é imposto e o que é honra

Modelo de ameaça: agente cooperativo mas descuidado, não fraude. No Windows
não há sandbox.

| Garantia | Mecanismo |
|---|---|
| Portão humano | `sdd approve` recusa a IA sem `--frase` e frase sem aprovação, portão e número; o P2 e o goal exigem a linha P1; o hook de edição nega gravar status, `base_ref` ou linha de aprovação (Claude; no Antigravity, não confirmado) |
| Fonte normativa | approve e goal recusam risco de `projeto.riscos_com_fonte` sem `fonte_normativa` |
| Evidência de teste | `sdd test` grava resultado, contagens e árvore; o goal exige RED/GREEN agrupado que cubra todas as tags de cenário da change; o hook nega editar `evidence.jsonl`, `verify.md` e `.sdd/state/` |
| Pronto | `sdd goal <NN>`: perfil calibrado, status e portões, tasks, evidência, `validate` da árvore atual, `impact`, exceções e verificador da árvore atual |
| Commit validado | pre-commit `sdd commit-gate` (lembrete; `--no-verify` burla) + confirmação de `git commit`/`git push` |
| Comando destrutivo | guard da máquina pede confirmação; escapa por script novo, subprocesso ou alias |
| Só honra | a frase do `--frase` ser do usuário; ordem test-first; independência do verificador (o guard pede a sua confirmação no `verify-record`, mas a IA que implementou consegue rodá-lo); evidência `MANUAL`; tag `SPEC-…/Cn` nos testes (conferida só pelo verificador); prazo do `RED-pending`; evidência do nível pequeno (local, em `.sdd/state`); forja deliberada de arquivo |

Comandos do motor: `powershell -File tools/sdd/sdd.ps1 ajuda`.
