---
id: 260924-tbo
slug: corrigir-discrepancia-sem-orcamento-dash
status: planned
mode: quick
---

# PLAN: Align dashboard spent with Financeiro JTD

## Goal

Dashboard client cards for "Finalização do sistema" / Sistema ZOC must stop showing "Sem orçamento" / -71% when Financeiro JTD shows healthy budget (R$ 5.000 vs salário JTD R$ 248,86).

## Diagnosis (locked)

| Source | Metric | Value |
|--------|--------|-------|
| `projects.budget` | Orçamento | 5000 |
| Dashboard `list_projects_budget_summary` | `SUM(pc.amount)` | **8567.59** → (5000-8567)/5000 = **-71%** |
| Financeiro `get_k_cost_summary` | `SUM(hours_worked * ou.salary)` | **248.86** → lucro positivo |

Root cause: old `project_charges` frozen `hourly_rate=3000` (salary mistyped as hourly). Current `organization_users.salary=40`. Financeiro recomputes with **current** salary; dashboard uses **stored** `amount`.

UI label "Sem orçamento" = `restante < 0` (exhausted), not zero budget. With correct spent, alert disappears.

## Tasks

### Task 1 — Migration: align `list_projects_budget_summary`

**Repo:** `zoc-be-api`

**Action:** Create migration via `make migrate-new name=list_projects_budget_summary_jtd_salary` that replaces the function so `total_spent` = `COALESCE(SUM(pc.hours_worked * ou.salary), 0)` joining `organization_users` (same cost basis as `get_k_cost_summary`), not `SUM(pc.amount)`.

**Verify:** SQL against project `b6d8b26d-740d-453b-96c7-c96b07ccf325` returns `total_spent ≈ 248.86`.

**Done:** Function redefined + GRANT preserved.

### Task 2 — FE fallback + copy

**Repo:** `zoc-fe`

**Action:**
1. `buildProjectCardsFromStore`: prefer `hours_worked * hourly_rate` only if needed — when store has charges, compute spent as `hours_worked *` current path is weak; if charges lack live salary, keep RPC as source of truth (already primary in `useDashboard`). Optionally document that store fallback is approximate.
2. Fix misleading copy in `financialControl.tsx`: exhausted → "Orçamento esgotado" / "N projeto(s) com orçamento esgotado" (not "Sem orçamento"). Keep "Honorarios Zero" for `budget === 0`.

**Verify:** Typecheck / existing clientBudget usage; modal no longer says "Sem orçamento" for overspend.

**Done:** Labels fixed; dashboard prefers RPC (unchanged wiring).

### Task 3 — Optional consistency (same migration or follow-up)

Update `generate_project_budget_notifications` spent to JTD salary formula so alerts match dashboard. Include in Task 1 migration if low risk.

## Out of scope

- Backfill rewriting historical `amount`/`hourly_rate` rows (data archaeology).
- Changing `get_k_cost_summary` (already correct).

## Files

- `zoc-be-api/supabase/migrations/<ts>_list_projects_budget_summary_jtd_salary.sql`
- `zoc-fe/src/components/FinantialDashboardCard/financialControl.tsx`
- Possibly `zoc-fe/src/app/(private)/dashboard/utils/dashboard.ts` if store fallback needs hours×rate vs amount

## Success

Dashboard for Sistema ZOC / Finalização do sistema shows positive remaining (~95%) aligned with Financeiro JTD salary cost; no false "Sem orçamento".
