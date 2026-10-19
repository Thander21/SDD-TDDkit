# Metodologia documentada e guiada

> **Prontidão:** Levantamento <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
> **Regra:** `.agents/rules/sdd-fluxo.md` §2. **Skill:** `backlog-refinement`.
> Arquivo: `<specs>/backlog/NN - Tema.md`; sem `NN` = provisório até o usuário numerar.

## Levantamento

Fala do usuário, 12/10/2026 (resposta no refinamento do item "Assistente do
instalador"):

> sem terminal somente pelo assitente o projeto e para ser simples e facil
> sem codigos no terminal somente comandos no chat e texto para ia definir a
> skill e o passo correto, é um framework guiado para quem nao é
> desenvolvedor ou nao tem conhecimento exato da metodologia por isso deve
> sempre guiar e ter documentado a metodologia sdd + tdd + bdd + xp + loop +
> validações extras do escopo

Fala do usuário, 14/10/2026, sobre o desenho do fluxo feito no chat:

> esta otimo salve ese fluxo na documentação do kit para usarmos depois
> como explicação de como usar

Salvo em `SpecSimpleKit/docs/como-usar-fluxo.md` (fora do kernel, que está
em 39,9 KB de 40 KB); onde ele mora de vez e como chega ao usuário é parte
deste item.

Fala do usuário e diretrizes de SDD, 18/10/2026 (origem `spec_driven_development.md`):

> incorporar ao item 3 a explicacao de que o specsimplekit segue SDD + TDD com BDD
> para testes direcionados e Agile Extreme (XP), com o ciclo dos 4 artefatos:
> 1. Constitution (regras permanentes, limites e anti-padroes do que NAO fazer);
> 2. Specification (o que e porque, sem stack, criterios mensuraveis e cenarios BDD);
> 3. Technical Plan (como, arquitetura, modelo de dados, riscos e justificativas de deps);
> 4. Tasks (atomicas, rastreaveis e verificaveis).
> Explicar que a IA executa em loop autonomo pos-P2 ate o fecho, e que no kit
> a Constitution mora no AGENTS.md/.agents/rules e os outros 3 artefatos moram
> de forma integrada e auditavel dentro de change.md aprovados via P1 e P2.

Contexto: hoje a metodologia está nas regras `sdd-core`, `sdd-fluxo` e
`sdd-revisao` (escritas para a IA), em `SpecSimpleKit/Metodologia SDD.ai`
(decisão e protocolo) e em `spec_driven_development.md`. O orçamento do Markdown
gerenciado está em 39,5 KB de 40 KB (README, Regras de manutenção 2).

## Requisitos

<!-- Preenchido pela skill backlog-refinement. -->

### Problema e valor

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|

### Requisitos funcionais

### Regras de negócio e restrições

### Fora de escopo

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|

### Perguntas para o usuário

### Respostas

| # | Resposta | Data |
|---|---|---|

## Tasks

## Encaminhamento
