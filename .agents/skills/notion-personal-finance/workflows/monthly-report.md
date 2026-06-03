# Workflow F: Create a Monthly Report (Auto-Linking)

One row per month. All fixed expenses and month transactions are auto-linked dynamically — no manual relation setup.

**Pre-requisite**: Pre-flight completed (`$monthlyReportDS`, `$fixedExpensesDS`, `$transactionsDS`, `$templateId` resolved).

## Step 1 — Discover and apply the template

Create the report row using the dynamically discovered template:

```
notion_notion-create-pages(
  parent = { data_source_id: $monthlyReportDS },
  pages = [{
    template_id: $templateId,
    properties: {
      "Month": "2026-06",
      "date:Period Start:start": "2026-06-01",
      "date:Period Start:is_datetime": 0
    }
  }]
)
```

## Step 2 — Auto-link ALL Fixed Expenses (Monthly Amortization > 0)

**Do not** rely solely on `data_source_url` in `notion_notion-search` — use a two-pass approach:

**Pass 1** — Try scoped search (fast path):

```
notion_notion-search(
  query = "a",
  data_source_url = $fixedExpensesDS,
  page_size = 25
)
```

If it returns pages with `type: "page"`, verify each via ancestor-path check, then collect.

**Pass 2** — Fall back to workspace search + verification if Pass 1 returned zero results or `type` is `workspace_search`:

Search the workspace broadly for known fixed expense names (e.g. "貸款", "電信", "Copilot", "燃料", "牌照"). For each candidate, fetch the page and inspect its `<ancestor-path>`:

```
notion_notion-fetch(id = "<candidate page url>")
# Check if response contains:
# <parent-data-source url="collection://<matches $fixedExpensesDS>" name="Fixed Expenses DB"/>
```

Only include pages that pass this verification.

For each verified Fixed Expense page, compute Monthly Amortization:

- `Monthly` cycle → MA = `Amount` (> 0 if Amount > 0)
- `Annually` cycle → MA = `round(Amount / 12)` (> 0 if Amount > 0)

**Only link fixed expenses where Monthly Amortization > 0.** (If Amount is 0 or null, skip it.)

Collect all qualifying page URLs and link them to the report:

```
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Fixed Expenses": "[\"<url 1>\", \"<url 2>\", ...]"
  }
)
```

## Step 3 — Auto-link ALL month Transactions

**Pass 1** — Try scoped search (fast path):

```
notion_notion-search(
  query = "YYYY-MM",
  data_source_url = $transactionsDS,
  page_size = 25
)
```

If it returns pages with `type: "page"`, verify each via ancestor-path check, then collect and skip to linking.

**Pass 2** — Fall back to workspace search + verification:

Search the workspace broadly. Try multiple queries:

- The month label: `notion_notion-search(query = "YYYY-MM")`
- Known transaction item names
- Recent pages by scanning various terms

For each candidate result, fetch the page and inspect its `<ancestor-path>`. Only include pages whose ancestor chain matches `$transactionsDS` AND whose `date:Date:start` value starts with the target month:

```
notion_notion-fetch(id = "<candidate page url>")
# Check if response contains:
# <parent-data-source url="collection://<matches $transactionsDS>" name="Transactions DB"/>
# AND properties.date:Date:start starts with "YYYY-MM"
```

Collect all verified transaction page URLs and link them to the report:

```
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Transactions": "[\"<tx url 1>\", \"<tx url 2>\", ...]"
  }
)
```

If no transactions exist yet for the month, skip linking.

## Step 4 — Computed properties auto-update

Once relations are set, all aggregates update automatically:

- `Total Income` = sum of Income transactions
- `Variable Spending` = sum of Expense transactions
- `Fixed Burden` = sum of Monthly Amortization from all linked Fixed Expenses
- `Total Spending` = Variable Spending + Fixed Burden
- `Net` = Total Income − Total Spending

## Step 5 — Confirm

Reply with the month, Total Income, Total Spending, Net, the full Fixed Burden breakdown (each expense + amount), and the Notion URL of the report page.
