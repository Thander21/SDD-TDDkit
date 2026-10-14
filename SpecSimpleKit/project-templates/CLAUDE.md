# Entrada do Claude Code

@../AGENTS.md
@../.agents/rules/sdd-core.md

## Só no Claude Code

- Este é o único CLAUDE.md do projeto: não criar `CLAUDE.md` nem
  `CLAUDE.local.md` na raiz (entrada única para as duas IDEs).
- Skills do Claude em `.claude/skills/` são wrappers gerados pelo kit a
  partir de `.agents/skills/`; `learn` é só do Claude.
- Verificação independente de change: subagente `sdd-verifier`.
- Revisão de diff: `/code-review`; enxugar: `/simplify`.
