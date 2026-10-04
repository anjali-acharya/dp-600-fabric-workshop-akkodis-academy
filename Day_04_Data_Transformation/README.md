# Microsoft Fabric Boot Camp - Day 4 Notes

**Course:** DP-600 – Implement Analytics Solutions Using Microsoft Fabric
**Topics:** Transform Data with Notebooks (Spark) · Transform Data with T-SQL in a Warehouse

---
## Transform Data with Notebooks (Apache Spark)

### Why notebooks (vs Dataflow Gen2)
Visual tools stop being the right answer when you have **billions of rows**, heavy calculations/window logic, custom algorithms, **ML libraries**, external API calls, or you want transformation logic in **Git with code review**.

**Four reasons to use a notebook**
1. **Distributed compute** - Spark splits data into partitions across cluster nodes and processes them in parallel; Fabric provisions the compute from your capacity (no cluster to manage). The same PySpark code that runs on a dev sample runs on the full dataset unchanged.
2. **Iterative development** - cell-by-cell execution; DataFrames stay in session memory, so if step 3 fails you fix step 3 and rerun *only* that cell (unlike a Python script that restarts from the top).
3. **Complex logic** - window functions, custom algorithms (loops/recursion), ML (MLlib, scikit-learn), external APIs, extra libraries.
4. **Version control** - Git integration → branches, pull requests, history, rollback.

### Notebook features worth remembering
- **Multi-language:** PySpark (Python + DataFrame API - by far the most common), Spark SQL, Scala, R. Mix languages in one notebook.
- **`%%sql` magic command** turns a cell into Spark SQL. To go back to Python, just start a new cell in Python. **No performance penalty** for switching - same engine and session.
- **Lakehouse attached** - browse files/tables in the Explorer pane and read tables by name (no paths, connection strings or credentials).
- **Pipeline-ready** - add a **parameter cell** at the top; a Fabric pipeline can pass values (e.g. the name of the file that triggered it) and run the notebook unattended on a schedule. Same engine lineage as Synapse/ADF.
- **One Spark session per notebook run** - a pipeline running 3 notebooks provisions 3 sessions. Cells run one at a time (no parallel cell execution).
-  **Capacity:** on a small capacity (e.g. F2), check **Monitor** for open Spark sessions - a session left running can make a new notebook fail to start. Stop sessions when done.

### PySpark ↔ Spark SQL - same engine, two interfaces
| Task | PySpark | Spark SQL |
|---|---|---|
| Read table | `spark.table("raw_sales")` | `FROM raw_sales` |
| Remove duplicates | `.dropDuplicates([...])` | `SELECT DISTINCT` |
| Fill nulls | `.fillna({...})` | `COALESCE(col, 'Unknown')` |
| Filter | `.filter(...)` | `WHERE` |
| Derived column | `.withColumn("line_total", qty * price)` | `qty * price AS line_total` |

**Which to choose?** Decide by **team skill** first. Loops/recursion/library calls → Python. Reading, filtering, multi-table joins → often clearer in SQL.

### Combining & enriching data
| Join | Behaviour |
|---|---|
| **Inner** | Only rows matching on both sides |
| **Left** | All left rows; nulls where no match on the right |
| **Right** | All right rows; nulls where no match on the left |
| **Full outer** | Everything from both; nulls where unmatched |

⚠️ **Silent-drop risk:** an **inner join discards fact rows whose key is missing from the dimension** - revenue quietly drops. **Check row counts before and after the join.**

**GROUP BY vs window functions**
- `GROUP BY` **collapses** rows (1M rows → 12 monthly rows).
- **Window functions** keep every row and add a calculation alongside - running totals, rankings, sequence numbers, previous-row comparisons.

### Writing results to Delta (write modes)
| Mode | Use for | Watch out for |
|---|---|---|
| **Overwrite** | Full rebuild (e.g. nightly gold refresh); deterministic result | Reprocesses everything each run |
| **Append** | Incremental loads, event data | **Duplicates** if the same batch runs twice - nothing warns you |
| **Merge** | Upserts and **SCD** (expire old row + insert new, as one atomic operation) | More complex logic |

Delta writes are **ACID** (fully commit or not at all) with schema enforcement.

### Keeping Delta tables healthy
- **OPTIMIZE** - compacts many small files (created by frequent appends) into fewer large ones → much faster reads. Make it a **scheduled routine** (tip from chat: if you load daily, optimize weekly).
- **VACUUM** - removes old files no longer referenced by the current table version to reclaim storage. Trade-off: **you can't time-travel back beyond the retention window** - don't shorten it casually.
- **V-Order** - Fabric write-time optimization on Parquet that speeds up downstream engines.
- **Partitioning** - physically organizes data into folders by column value (e.g. month → 24 folders for 2 years) so queries skip irrelevant folders. Use a **low-cardinality** column, only on **large** tables, with a **predictable filter pattern**. High-cardinality partitioning creates too many folders and makes performance *worse*.


### Copilot in notebooks (what was observed)
- **Diagnose with Copilot** fixes errors in-place; **inline code completion** (write a comment, press Enter, **Tab** to accept); Copilot can also add **markdown documentation** above each step and **Explain code**.
- Copilot availability depends on capacity/tenant settings - it's **disabled on trial capacity** and admins can turn it off.

### Views in notebooks are temporary
`CREATE OR REPLACE TEMP VIEW` is **session-scoped** - it does **not** appear in the lakehouse's SQL analytics endpoint and disappears when the session ends. Persistent, permissioned views live in a **warehouse** (or created via the lakehouse SQL endpoint).

### Medallion reminder
**Never modify Bronze** (no merges there). Keep it pristine so any mistake in Silver/Gold can be fixed by rerunning from raw data. Merge/upsert belongs in Silver/Gold.

---

## Exercise 1: Transform data with notebooks

**Lab:** [Transform data with notebooks in Microsoft Fabric](https://microsoftlearning.github.io/mslearn-fabric/Instructions/Labs/26c-transform-data-notebooks.html)

**My run (with outputs):** `Day4_Exercise1_SalesDataTransformation.ipynb`

**What the lab does**
1. New workspace + lakehouse (`Sales`); import the pre-built **Sales Data Transformation** notebook and attach the lakehouse.
2. Run the first cell → creates three Delta tables: `raw_sales` (11 rows, **includes a duplicate order_id 10 and a null region**), `customers`, `products`.
3. **Shape & clean (`%%sql`)** - `SELECT DISTINCT` removes the duplicate, `COALESCE` fills the null region with `Unknown`, a calculated `line_total`, and a `CASE` **value tier**. Result: **10 rows**. This produced a *temp view* (`clean_sales`) - not a table.
4. **Join & aggregate** - inner join sales ↔ customers ↔ products, then aggregate to **one row per region** (order count, total revenue, average order value).
5. **Window functions** - `SUM() OVER` running total and `ROW_NUMBER() OVER` order sequence, partitioned by customer; row count stays the same.
6. **Write to Delta** - `CREATE OR REPLACE TABLE gold_sales`; verify in Explorer and query revenue by category and region.
7. *(Optional Copilot prompts: extra column on `clean_sales`, aggregation by category, `RANK`, high-value orders.)*
8. Clean up: delete the workspace.

## Transform Data with T-SQL in a Fabric Warehouse

The third of three transformation approaches: **Dataflow Gen2 → Notebooks → T-SQL**. Warehouse data is stored as **Delta/Parquet in OneLake**, so tables built with T-SQL are readable by Spark notebooks and by Power BI in **Direct Lake** mode - no export.

### T-SQL (Warehouse) vs Spark SQL (Notebook)
| | **T-SQL** | **Spark SQL** |
|---|---|---|
| Engine | Warehouse compute (always ready in the query editor) | Spark cluster (session start-up time) |
| Writes to | Warehouse tables | Lakehouse Delta tables |
| DML | Full **INSERT / UPDATE / DELETE / MERGE** with multi-table transactions | SELECT + Delta write modes (merge via Delta API) |
| Persistent objects | **Views & stored procedures** persist, can be permissioned/discovered/called by pipelines | Views are **session-scoped** temp views |
| Best for | Warehouse transformations, loading, automation | Large-scale processing, ML, complex logic |

> Remember: the **lakehouse SQL analytics endpoint is read-only**, you can't run UPDATE/MERGE there.
> The real deciding factor is usually **where curated data lives and who maintains the code**: SQL developers → warehouse + T-SQL; Python data engineers → lakehouse + notebooks + Git. The two aren't walled off (shortcuts, cross-database queries).

### The three persistent objects
| Object | What it is                                                                                                    | Why it matters |
|---|---------------------------------------------------------------------------------------------------------------|---|
| **View** | Saved SELECT - **read-only, always current** (stores definition, not data)                                    | Define logic **once**; acts as a semantic layer with friendly names; can grant access to a view without granting access to the underlying tables |
| **Stored procedure** | Parameterized, **read/write**, multi-step; supports variables, conditional logic, **TRY/CATCH**, transactions | The right tool for load processes; same procedure handles yesterday's load or a month-long reprocess; **callable from a pipeline on a schedule** |
| **Table clone** | **Zero-copy** snapshot sharing the original's files; created near-instantly; only changes diverge             | Safe testing against full-size production data, recovery point before risky changes, month-end audit snapshots |

### Loading patterns
1. **Full refresh**: delete everything, reinsert everything. Simple and reliable for small/reference tables.
2. **Incremental (watermark)**: load only rows newer than the last load. Needs **all three**: (a) a reliable created/last-modified column, (b) that column **must actually be updated when a row changes** (where many implementations quietly fail  e.g. restatements), and (c) the watermark **stored durably** (a control table updated in the same transaction as the load).
3. **Merge / upsert**: match on key, insert or update in **one atomic statement** (the SCD Type 2 pattern: expire Anna's East row, insert her West row - history is never lost).

### Typical T-SQL transformation patterns
- **Filter + calculate** : `WHERE status = 'Completed'`, derived columns (`line_total`), `ISNULL(discount, 0)`, `CASE` for tiers.
- **Join + null handling** : join orders to customers; replace null region with `Unknown`.
- **Aggregate** - group by region/month, `COUNT(*)` and `SUM(...)`.
- **Window functions** : `ROW_NUMBER`, running `SUM() OVER`, `LAG` for the previous order amount.
- **CTE** : break complex queries into named steps (e.g. monthly totals → YTD running total).

---

## Exercise 2 - Transform data with T-SQL in a Fabric warehouse

**Lab:** [Transform data with T-SQL in a Fabric warehouse](https://microsoftlearning.github.io/mslearn-fabric/Instructions/Labs/26d-transform-data-tsql.html)
📄 **All T-SQL for this lab:** the lab provides the official `26d-snippets.txt` - see the lab page

**What the lab builds (in order)**
1. New workspace + **warehouse**.
2. **Schemas** `staging`, `dim`, `fact`, `gold`; staging tables `customers`, `products`, `orders` (12 orders, one *Pending*), `dates` - loaded with sample data.
3. **Queries:** filter completed orders + calculated columns (`line_total`, `net_amount`, `order_tier`) → join + aggregate by region/segment → **window functions** (`ROW_NUMBER`, running `SUM`, `LAG`) → **CTE** with YTD total.
4. **View** `gold.vw_monthly_sales` (monthly sales by product category) - query it with a plain `SELECT`.
5. **Stored procedure** `gold.usp_refresh_monthly_sales @year, @month` - deletes that period from `gold.monthly_sales`, then inserts fresh aggregates (a **period-level full refresh**). Executed for Jan, then Feb–Apr, and the table accumulates.
6. **Dimensional tables:** `dim.date`, `dim.customer` (SCD Type 2 columns: `effective_date`, `end_date`, `is_current`), `dim.product`, and `fact.sales` loaded by joining staging orders to the dimensions to **look up surrogate keys** (customer join filtered on `is_current = 1`).
7. **Verify:** join the fact back to all dimensions (11 completed orders), then list all objects via `INFORMATION_SCHEMA` - expect **11 objects**.
8. Clean up: delete the workspace.

**Facts worth remembering**
- `IDENTITY` columns in a Fabric warehouse must be **`BIGINT`** and don't support a custom seed/increment.
- Natural keys (`customer_id`) become **surrogate keys** (`customer_key`) in the fact table.

**⚠️ Gotchas hit during the live session**
- **Don't leave text highlighted** in the SQL editor - Fabric runs *only the selection*. Selecting one line of a `CREATE VIEW`/`CREATE PROCEDURE` produced errors; click into the editor with no selection to run the whole script.
- Running the whole setup script at once can fail - **create the schemas first, then the tables in separate queries**, and if something half-fails, start from the top in a clean warehouse (re-running `CREATE` on an existing object errors).
- One query tab per logical step keeps things easy to re-run.

---


## Key Takeaways
- **Choose the transformation tool by scale, complexity and team skill:** Dataflow Gen2 (low-code, modest volume) → Notebooks (huge/complex, ML, Git) → T-SQL (warehouse-native loading, views, procedures).
- **PySpark and Spark SQL are one engine** - switch freely with `%%sql`
- **Inner joins can silently drop rows** - always compare row counts before and after.
- **Delta write modes:** overwrite = rebuild, append = incremental (duplicate risk), merge = upsert/SCD. Then **OPTIMIZE** (compact) and **VACUUM** (reclaim, but limits time travel).
- **Notebook temp views vanish; warehouse views/procedures persist** and can be permissioned and scheduled.
- **Table clones** = instant, zero-copy safety net before risky changes.
- **Incremental loads need a trustworthy modified-date column *and* a durably stored watermark.**
- **Never modify Bronze.**
