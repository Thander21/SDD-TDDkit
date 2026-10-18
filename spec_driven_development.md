# Diretrizes de Spec-Driven Development (SDD)

Ao trabalhar em projetos que adotem a metodologia Spec-Driven Development (SDD), e nao tenham nenhuma documentaçã em .agents inicie com essa e siga rigorosamente este fluxo e salvaguardas:

## 1. O Ciclo dos 4 Artefatos

1. **Constitution (`constitution.md`)**:
   - Estabelece as regras permanentes e invariantes do projeto (Stack, Arquitetura, Qualidade, Governança).
   - Todos os critérios devem ser verificáveis (evite afirmações subjetivas como "código limpo").
   - DEVE conter uma seção explícita de **Limites e Anti-padrões (O que NÃO fazer)** para blindar o escopo e evitar complexidade acidental.
2. **Specification (`spec.md`)**:
   - Responde apenas **O quê** e **Por quê**.
   - PROIBIDO mencionar tecnologias, linguagens, bancos ou frameworks na especificação de negócio/produto.
   - Deve conter problemas, objetivos, personas, histórias de usuário, requisitos funcionais, regras de negócio, casos de borda e critérios de aceite mensuráveis.
3. **Technical Plan (`plan.md`)**:
   - Responde **Como**.
   - Toda biblioteca ou pacote externo novo DEVE conter uma justificativa escrita vinculada a um requisito da Spec.
   - Detalha arquitetura de pastas/módulos, modelo de dados, contratos/interfaces e tabela de riscos com mitigações concretas.
4. **Tasks (`tasks.md`)**:
   - Tarefas pequenas, atômicas, ordenadas e rastreáveis.
   - Cada tarefa deve apontar para sua origem na Spec/Plan, declarar dependências, possuir status (`[ ]` / `[x]`) e um comando exato de verificação.

## 2. Governança e Execução Iterativa

- **Aprovação por Etapas**: Não avance para o artefato seguinte sem a revisão e validação explícita do artefato anterior pelo usuário.
- **Auditoria Prévia de Gaps**: Antes de congelar a Spec, audite códigos ou especificações legadas em busca de regras tácitas (ex.: fallback, detecção de duplicados, organização de pastas).
- **Desenvolvimento com Testes em Par (Test-Pair / TDD)**: Cada tarefa de código deve ser entregue acompanhada de seus testes unitários ou de integração automatizados aprovados no mesmo ciclo.
- **Precisão Financeira**: Em rotinas contábeis, tributárias ou fiscais, utilize obrigatoriamente o tipo primitivo `decimal` (nunca `double` ou `float`) com cultura invariante (`CultureInfo.InvariantCulture`).
