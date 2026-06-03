# Pre-flight: Discover Database IDs

Run this before any workflow. Store discovered IDs as variables for the session.

## Step 1 — Find the Personal Finance page

Search for it by name:

```
notion_notion-search(query = "Personal Finance")
```

Look for the result with title "Personal Finance". Use its `id` or `url`.

## Step 2 — Fetch and extract database entries

Fetch the page to reveal linked databases:

```
notion_notion-fetch(id = "<personal finance page id/url>")
```

The response contains `<database>` tags with `data-source-url` attributes:

```xml
<database data-source-url="collection://<uuid>">Transactions DB</database>
<database data-source-url="collection://<uuid>">Categories DB</database>
<database data-source-url="collection://<uuid>">Accounts DB</database>
<database data-source-url="collection://<uuid>">Fixed Expenses DB</database>
<database data-source-url="collection://<uuid>">Monthly Report DB</database>
```

Extract both forms for each:

| Variable | For search `data_source_url` | For create `parent.data_source_id` |
|---|---|---|
| `$transactionsDS` | `collection://<uuid>` | `<uuid>` |
| `$categoriesDS` | `collection://<uuid>` | `<uuid>` |
| `$accountsDS` | `collection://<uuid>` | `<uuid>` |
| `$fixedExpensesDS` | `collection://<uuid>` | `<uuid>` |
| `$monthlyReportDS` | `collection://<uuid>` | `<uuid>` |

## Step 3 — Discover the Monthly Report template

Fetch the Monthly Report DB:

```
notion_notion-fetch(id = "<monthly report db page url>")
```

Look for `<templates>` section. Extract the template page ID (UUID) — this is `$templateId`. If no templates section exists, fetch each page in the Monthly Report DB to find one with title containing "Template".

## Step 4 — Discover Category and Account page URLs

Before creating transactions, always search the Categories DB and Accounts DB to resolve current page URLs (do not reuse cached URLs from previous sessions):

```
notion_notion-search(query = "<category name>", data_source_url = $categoriesDS)
notion_notion-search(query = "<account name>", data_source_url = $accountsDS)
```
