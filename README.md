# Microsoft Fabric Analytics Engineer (DP-600) Online Boot Camp - Learning Journal

Personal study notes, hands-on exercise write-ups, and completed lab artifacts from a 10-day **Microsoft Fabric Online Boot Camp**, mapped to the **DP-600: Implement Analytics Solutions Using Microsoft Fabric** certification.

This repo exists as a daily, structured record - both to track my own progress and as a reference I can search back through later (relationships, DAX patterns, security setup, etc.).

---

## Course Map

| Day | Focus | Key topics |
|---|---|---|
| [Day 1](./Day_01) | OneLake & Lakehouses | OneLake foundation, lakehouse structure, notebook vs. SQL analytics endpoint |
| [Day 2](./Day_02) | Data Warehousing & Real-Time Intelligence | Star schema, fact/dimension design, Fabric Warehouse, Eventstream → Eventhouse → KQL → Dashboard/Activator |
| [Day 3](./Day_03) | Choosing a Data Store & Dimensional Modeling | Lakehouse vs. Warehouse vs. Eventhouse, grain, SCD Type 1/2, conformed & role-playing dimensions, Dataflow Gen2, query folding |
| [Day 4](./Day_04) | Transform Data: Notebooks & T-SQL | PySpark/Spark SQL, joins & window functions, Delta write modes, OPTIMIZE/VACUUM, views & stored procedures |
| [Day 5](./Day_05) | Semantic Models & DAX | Storage modes (Import/DirectQuery/Direct Lake), calculated tables/columns/measures, row vs. filter context, `USERELATIONSHIP`, calculation groups |
| [Day 6](./Day_06) | Optimizing Semantic Model Performance & Security Theory | Performance Analyzer, DAX anti-patterns, cardinality, RLS/OLS concepts |
| [Day 7](./Day_07) | Security Hands-On & Semantic Model Lifecycle | RLS/OLS lab, PBIP + Git version control, SemPy validation, deployment pipelines |
| [Day 8](./Day_08) | Ontology & Fabric Data Agents | Entity types/properties/relationships, graph data & GraphQL, data agent setup, operations agents |
| [Day 9](./Day_09) | Securing & Governing Fabric | Workspace roles, item permissions, OneLake folder-level RBAC, sensitivity labels, endorsement |
| [Day 10](./Day_10) | Governance Wrap-up, Pipelines & Medallion Architecture  | Pipeline orchestration, triggers & parameters, bronze/silver/gold design patterns |

---

## Repo Structure

Each day's folder generally contains:
- **`README.md`** (or `DayN_notes.md`) - the session write-up: topic summaries, live-demo gotchas, knowledge-check Q&As, key takeaways, and a follow-up list of anything left unresolved.
- **Exercise artifacts** - the actual file type produced by that lab, kept close to its native format rather than converted to something else:
  - `.sql` - compiled T-SQL scripts (warehouse/dimensional modeling exercises)
  - `.ipynb` - exported Fabric notebooks, with outputs, often with a markdown summary cell appended
  - `.pbix` - Power BI Desktop files (DAX/semantic model exercises)
  - `.md` - step logs for no-code exercises (Dataflow Gen2, M/Power Query) where there's no single executable file to share
- **`images/`** - screenshots referenced by that day's notes (lineage views, architecture diagrams, etc.)

---

## Tools & Technologies Covered

- **Fabric items:** Lakehouse, Warehouse, Eventhouse/KQL Database, Eventstream, Dataflow Gen2, Notebooks, Semantic Models, Data Agents, Ontologies, Pipelines
- **Languages:** T-SQL, PySpark / Spark SQL, DAX, KQL, M (Power Query), GraphQL
- **Governance & security:** RLS, OLS, OneLake data access roles, sensitivity labels, endorsement, deployment pipelines, Git/PBIP version control
- **AI:** Copilot (Prep for AI, grounding), SemPy (semantic link), Fabric Data Agents, Microsoft Foundry integration

---

## A Note on Trial-Capacity Limitations

Several exercises in the back half of the course **require a paid Fabric capacity (F2+) with Copilot enabled** and could not be completed hands-on using the free trial:
- Preparing a semantic model for AI / Copilot (Day 7)
- Implementing a Fabric Data Agent (Day 8)
- Sensitivity labels via Microsoft Purview, which additionally need a P1/P2 license (Day 9)

---


## Acknowledgments

Based on a 10-day live online boot camp. Lab exercises sourced from Microsoft's official [`mslearn-fabric`](https://microsoftlearning.github.io/mslearn-fabric/) training materials, linked individually within each day's notes.
Thanks to Akkodis Academy Australia for organizing and running this boot camp.

---

## Disclaimer

These are personal study notes compiled from session recordings and official Microsoft Learn materials - not an official Microsoft or course-provider publication. Treat this as a learning log, not documentation.
