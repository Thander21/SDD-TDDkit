## Metodologia (sdd-kit)

- **Núcleo sempre ativo:** `.agents/rules/sdd-core.md` (no Claude, importado
  pelo `.claude/CLAUDE.md`; no Antigravity, `trigger: always_on`).
- **Fluxo spec-driven:** `.agents/rules/sdd-fluxo.md`, lido antes de trabalho
  não trivial. **Revisão:** `.agents/rules/sdd-revisao.md`.
- **Skills:** `backlog-refinement`, `sdd-verify` e `sdd-bootstrap` em
  `.agents/skills/` (wrappers do Claude em `.claude/skills/`); `learn` só no
  Claude. Subagente verificador: `.claude/agents/sdd-verifier.md`.
- **Motor:** `powershell -File tools/sdd/sdd.ps1 <check|validate|test|goal|status|ajuda>`;
  perfil de gates em `.sdd/profile.json`.
- **Onde registrar:** regras = invariantes; skills = processo;
  `.agents/usage/` = manual humano; `.agents/reports/` = relatório (nunca
  fonte de regra); specs em `projeto.specs_root` do perfil.
- Bloco reescrito pelo update do kit. O projeto pode endurecer o núcleo,
  nunca afrouxar; lição de método vai para o INBOX do kit (skill `learn`).
