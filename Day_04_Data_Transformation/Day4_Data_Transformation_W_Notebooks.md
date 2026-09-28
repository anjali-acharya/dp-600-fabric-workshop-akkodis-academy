# Microsoft Fabric Boot Camp - Day 4 Notes

**Course:** DP-600 – Implement Analytics Solutions Using Microsoft Fabric
**Topics:** Transform Data with Notebooks (Spark) · Transform Data with T-SQL in a Warehouse

---
## Transform Data with Notebooks (Apache Spark)

### Why notebooks (vs Dataflow Gen2)
Visual tools stop being the right answer when you have **billions of rows**, heavy calculations/window logic, custom algorithms, **ML libraries**, external API calls, or you want transformation logic in **Git with code review**.

**Four reasons to use a notebook**
1. **Distributed compute** — Spark splits data into partitions across cluster nodes and processes them in parallel; Fabric provisions the compute from your capacity (no cluster to manage). The same PySpark code that runs on a dev sample runs on the full dataset unchanged.
2. **Iterative development** — cell-by-cell execution; DataFrames stay in session memory, so if step 3 fails you fix step 3 and rerun *only* that cell (unlike a Python script that restarts from the top).
3. **Complex logic** — window functions, custom algorithms (loops/recursion), ML (MLlib, scikit-learn), external APIs, extra libraries.
4. **Version control** — Git integration → branches, pull requests, history, rollback.

### Notebook features worth remembering
- **Multi-language:** PySpark (Python + DataFrame API — by far the most common), Spark SQL, Scala, R. Mix languages in one notebook.
- **`%%sql` magic command** turns a cell into Spark SQL. To go back to Python, just start a new cell in Python. **No performance penalty** for switching — same engine and session.
- **Lakehouse attached** — browse files/tables in the Explorer pane and read tables by name (no paths, connection strings or credentials).
- **Pipeline-ready** — add a **parameter cell** at the top; a Fabric pipeline can pass values (e.g. the name of the file that triggered it) and run the notebook unattended on a schedule. Same engine lineage as Synapse/ADF.
- **One Spark session per notebook run** — a pipeline running 3 notebooks provisions 3 sessions. Cells run one at a time (no parallel cell execution).
-  **Capacity:** on a small capacity (e.g. F2), check **Monitor** for open Spark sessions — a session left running can make a new notebook fail to start. Stop sessions when done.

### PySpark ↔ Spark SQL — same engine, two interfaces
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

⚠️ **Silent-drop risk:** an **inner join discards fact rows whose key is missing from the dimension** — revenue quietly drops. **Check row counts before and after the join.**

**GROUP BY vs window functions**
- `GROUP BY` **collapses** rows (1M rows → 12 monthly rows).
- **Window functions** keep every row and add a calculation alongside - running totals, rankings, sequence numbers, previous-row comparisons.

### Writing results to Delta (write modes)
| Mode | Use for | Watch out for |
|---|---|---|
| **Overwrite** | Full rebuild (e.g. nightly gold refresh); deterministic result | Reprocesses everything each run |
| **Append** | Incremental loads, event data | **Duplicates** if the same batch runs twice — nothing warns you |
| **Merge** | Upserts and **SCD** (expire old row + insert new, as one atomic operation) | More complex logic |

Delta writes are **ACID** (fully commit or not at all) with schema enforcement.

### Keeping Delta tables healthy
- **OPTIMIZE** — compacts many small files (created by frequent appends) into fewer large ones → much faster reads. Make it a **scheduled routine** (tip from chat: if you load daily, optimize weekly).
- **VACUUM** — removes old files no longer referenced by the current table version to reclaim storage. Trade-off: **you can't time-travel back beyond the retention window** — don't shorten it casually.
- **V-Order** — Fabric write-time optimization on Parquet that speeds up downstream engines.
- **Partitioning** — physically organizes data into folders by column value (e.g. month → 24 folders for 2 years) so queries skip irrelevant folders. Use a **low-cardinality** column, only on **large** tables, with a **predictable filter pattern**. High-cardinality partitioning creates too many folders and makes performance *worse*.


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

**My run (with outputs):** `Exercise1_SalesDataTransformation.ipynb`

**What the lab does**
1. New workspace + lakehouse (`Sales`); import the pre-built **Sales Data Transformation** notebook and attach the lakehouse.
2. Run the first cell → creates three Delta tables: `raw_sales` (11 rows, **includes a duplicate order_id 10 and a null region**), `customers`, `products`.
3. **Shape & clean (`%%sql`)** — `SELECT DISTINCT` removes the duplicate, `COALESCE` fills the null region with `Unknown`, a calculated `line_total`, and a `CASE` **value tier**. Result: **10 rows**. This produced a *temp view* (`clean_sales`) — not a table.
4. **Join & aggregate** — inner join sales ↔ customers ↔ products, then aggregate to **one row per region** (order count, total revenue, average order value).
5. **Window functions** — `SUM() OVER` running total and `ROW_NUMBER() OVER` order sequence, partitioned by customer; row count stays the same.
6. **Write to Delta** — `CREATE OR REPLACE TABLE gold_sales`; verify in Explorer and query revenue by category and region.
7. *(Optional Copilot prompts: extra column on `clean_sales`, aggregation by category, `RANK`, high-value orders.)*
8. Clean up: delete the workspace.

