# Metodologia documentada e guiada

> **Prontidão:** Pronto <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
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

### Problema e valor

O SpecSimpleKit é projetado para ser simples e acessível tanto para desenvolvedores quanto para pessoas sem conhecimento aprofundado de desenvolvimento de software ou de metodologias ágeis. O fluxo de trabalho deve ser 100% conversacional pelo chat da IA (Claude Code, Antigravity), sem necessidade de rodar comandos de terminal à mão.

O kit precisa de documentação clara e canônica que formalize a metodologia:
- **SDD + TDD + BDD + XP:** Especificação guiada por comportamento (cenários BDD `DADO/QUANDO/ENTÃO`), ciclo de feedback rápido e refatoração contínua (XP), e TDD rigoroso com evidência de RED/GREEN gravada pelo motor.
- **O Ciclo dos 4 Artefatos:**
  1. *Constitution* (Regras permanentes, invariantes e limites do que NÃO fazer: `AGENTS.md` e `.agents/rules/`);
  2. *Specification* (O que e por quê, agnóstico de stack, critérios mensuráveis e cenários BDD no `change.md`);
  3. *Technical Plan* (Como, arquitetura, modelo de dados, riscos e justificativa de dependências no `change.md`);
  4. *Tasks* (Atômicas, rastreáveis e verificáveis no `change.md`).
- **Loop Autônomo e Portões:** Explicação clara do papel dos portões humanos (P1 para escopo/especificação, P2 para plano técnico/tasks) e da execução contínua em loop autônomo da IA entre P2 e o fecho (`sdd goal`), culminando na verificação independente (`sdd-verify`).
- **Guia Conversacional para Não-Devs:** Tabela clara do que o usuário digita no chat em cada etapa e o que a IA executa por baixo dos panos.

Valor: Transparência total sobre como o método funciona, reduzindo atrito de adoção e servindo como material de referência tanto para o usuário quanto para o treinamento do próprio assistente.

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|
| Rascunho do fluxo pelo chat | Sim | `SpecSimpleKit/docs/como-usar-fluxo.md:1-131` (fora do kernel) |
| Decisão e diagnóstico da metodologia | Sim | `SpecSimpleKit/Metodologia SDD.ai:1-425` |
| Regras do fluxo para a IA | Sim | `SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md:1-387` |
| Menção a `.agents/usage/` como manual humano | Sim (só menção) | `SpecSimpleKit/kernel/AGENTS.kit.md:13` |
| Documentação dos 4 artefatos e XP | Não formalizada | Citada em `docs/Specs/backlog/03 - Metodologia documentada e guiada.md:28-39` |
| Orçamento Markdown gerenciado | No limite (42,8 KB) | Regras de manutenção 2 no `README.md:110-112` |

### Requisitos funcionais

- **RF-1 (Documentação Canônica da Metodologia e dos 4 Artefatos):**
  Estruturar um guia completo e didático da metodologia SDD + TDD + BDD + XP no kit, detalhando:
  1. Os 4 artefatos (Constitution, Specification, Technical Plan, Tasks), onde residem e suas responsabilidades;
  2. O ciclo de vida da feature: Backlog ➔ Refinamento ➔ P1 ➔ Plano/Tasks ➔ P2 ➔ Loop TDD ➔ Verificação ➔ Goal ➔ Archive;
  3. O loop de execução autônoma pós-P2 e as salvaguardas (parada em 3 falhas, limite de turnos, verificador independente);
  4. O guia de comandos conversacionais do chat para não-desenvolvedores ("O que você diz no chat").

- **RF-2 (Distribuição e Integração no Kit):**
  Definir a localização definitiva e a integração da documentação:
  1. Consolidar o guia canônico em `SpecSimpleKit/docs/como-usar-fluxo.md` (ou `metodologia-fluxo.md`) no repositório do kit, mantendo projetos instalados enxutos sem arquivos copiados adicionais;
  2. Atualizar referências no `README.md` (tabela de fluxo e links de documentação);
  3. Criar a spec viva da capacidade `fluxo` (`capabilities/fluxo/spec.md`) com os IDs reservados para rastreabilidade.

### Regras de negócio e restrições

- **RN-1 (Isolamento de Contexto da IA):**
  O manual humano NUNCA deve ser incluído em regras ativas (`sdd-core.md`, `sdd-fluxo.md`). Ele pertence à camada de documentação humana (`.agents/usage/` ou `docs/`).
- **RN-2 (Orçamento de Markdown Gerenciado):**
  Se o manual for empacotado no `kernel/` como arquivo gerenciado, deve ser avaliado contra o teto de 40 KB (D9), ou ser tratado como recurso não carregado no prompt da IA, ou distribuído via pasta de docs do kit.
- **RN-3 (Compatibilidade com Chat):**
  Todas as etapas devem priorizar o fluxo via frase no chat ("aprovo P1...", "aprovo P2...", "refine o item..."), mantendo o terminal apenas como fallback.
- **RN-4 (Linguagem):**
  Texto didático em português do Brasil (pt-BR), claro para desenvolvedores e não-programadores.

### Fora de escopo

- Alterações na lógica interna do motor PowerShell (`sdd.ps1`) para novos gates ou comandos não existentes.
- Automatização de interfaces gráficas (GUI) ou web apps de visualização nesta change.

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|
| Metodologia documentada e guiada (4 artefatos + guia conversacional) | feature | `fluxo` | `contrato-do-motor` | CHG-002, CHG-005 |

### Perguntas para o usuário

1. Onde a documentação da metodologia para humanos deve residir nos projetos instalados pelo kit?
   - **Opção A (Recomendada):** Em `SpecSimpleKit/docs/` (repositório do kit) e copiada no projeto em `.agents/usage/metodologia.md` (o padrão já previsto no `AGENTS.md` para manuais humanos, fora do contexto da IA).
   - **Opção B:** Apenas centralizada no repositório do kit (`SpecSimpleKit/docs/` e `README.md`), sem copiar arquivo adicional para os projetos instalados.
   - **Opção C:** Dentro da pasta de documentação de especificações do projeto (`docs/Specs/metodologia.md`).

### Respostas

| # | Resposta | Data |
|---|---|---|
| 1 | Apenas centralizado no repositório do kit (`SpecSimpleKit/docs/` e `README.md`), sem copiar arquivos adicionais para cada projeto instalado. | 19/10/2026 |

## Tasks

<!-- Preenchido quando o item estiver Pronto. -->

## Encaminhamento

Aberta a change CHG-003 em `docs/Specs/changes/03-metodologia-guiada/` (status Draft). Item do backlog movido para `origem/`.
