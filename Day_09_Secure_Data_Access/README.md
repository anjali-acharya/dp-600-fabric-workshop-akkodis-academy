# Microsoft Fabric Boot Camp  Day 9 Notes

**Course:** DP-600 – Implement Analytics Solutions Using Microsoft Fabric
**Topics:** Finishing Fabric Data Agents (Ontology + Operations Agent) · Securing Data Access in Fabric · Governing Analytics Data

---

## Day 8 wrap-up: connecting a data agent to an ontology

Fixed Day 8 broken Microsoft Foundry connection first: **a Foundry resource must be in the same region as your Fabric capacity**  Day 8's demo failed because Foundry was in East US while the Fabric capacity was in Southeast Asia. Flagged as likely exam-relevant.

**Connecting a data agent to an ontology instead of plain tables** changes the setup in two ways:
- **No example queries or data source instructions needed**  setup is actually *simpler* than a table-connected agent, even though building the ontology itself took much longer.
- **Agent instructions must explicitly say "support group by GQL"**  without this one line, the agent still runs but silently gives wrong answers (or says it can't answer) for relationship-style questions, since it won't know to generate a graph query.

**Live demo highlights (ontology-connected agent, graph-aware):**
- Asked relationship questions a plain table-connected agent couldn't answer well: *"Which customer has the highest sales?"* → correct (cross-checked against an actual report) → *"What are his buying patterns?"* → *"Is he connected to any nearby customers?"* → *"Explore patterns for customers in England"* → each built on the last, exploring the graph conversationally.
- **Code Interpreter tool** (enabled under the agent's Tools) lets the agent run Python in a sandbox to do calculations and **render actual charts** (e.g., *"give me a bar chart of monthly sales in 2021"*)  something a Foundry-only agent can't display natively, but the Fabric/ontology data agent can.


### ⚠️ Admin setting required for agents to work outside the US/EU (easy to miss)
Under **Admin portal → Copilot settings**, there are two related toggles:
- **"Users can use Copilot, AI agents, and other AI experiences powered by Azure OpenAI"**  the baseline, needed everywhere.
- **"Data sent to Azure OpenAI can be processed outside your capacity's region"**  needed **in addition** if your tenant is outside the US or EU data boundary (confirmed: Australia, Brazil, Canada, India, Japan, South Korea, South Africa, Southeast Asia, UAE **all require this**, since the underlying Azure OpenAI service only runs in US and EU data centers today  the UK specifically needs it too, since it's no longer part of the EU boundary). Pre-built Azure OpenAI backing this also **requires F2 capacity or higher  not available on trial SKU**, flagged as likely exam-relevant.
- **Reassurance on data flow:** only the specific **retrieved data for that one question** (the RAG pattern  retrieval happens in-region, then that snippet + your question is sent elsewhere for generation) ever crosses the boundary  not your underlying dataset.

---

## Securing Data Access in Fabric

> Distinct from everything covered on Days 6–7 (RLS/OLS on a **semantic model**)  this is security for the **whole Fabric estate**: lakehouses, warehouses, workspaces, and every other item type.

### The 4-layer funnel (broadest → narrowest)
| Layer | Scope | Granularity |
|---|---|---|
| **1. Workspace roles** | Everything in the workspace | All-or-nothing per person |
| **2. Item permissions** | One specific item (a lakehouse, warehouse, notebook, report) | Per item |
| **3. Granular SQL security** | Tables/rows/columns, enforced through the **SQL analytics endpoint** | Per table/row/column |
| **4. OneLake data access (folder-level RBAC)** | Physical files/folders in OneLake storage itself | Per folder/table, independent of which engine touches it |

### Layer 1  Workspace roles
| Role | Can do | Best fit |
|---|---|---|
| **Admin** | Full control + manage permissions for everyone, including adding other admins; only admins can create/delete workspaces | Workspace owners only |
| **Member** | Modify content **and share it with others** (the dividing line vs. Contributor) | Team leads distributing reports, onboarding people |
| **Contributor** | Modify/create content, **cannot share** | Data engineers heads-down building pipelines |
| **Viewer** | Read-only  run queries, but can't open items directly (e.g., can't open a notebook) or create anything | Report consumers |

- **Rule of thumb: always choose the narrowest role that lets someone do their job** (principle of least privilege).
- ⚠️ **Common mistake, demonstrated live:** giving someone Viewer still means they see **everything** in the workspace  it's all-or-nothing at this layer, just read-only. If you only want someone to see *one* item, don't use a workspace role at all  jump to item permissions instead.
- **Minimum role that can grant access to others: Member** (confirmed in the knowledge check  not Contributor).
- **Live demo confirmed:** a Viewer in a lakehouse can only reach the **SQL analytics endpoint**  the Lakehouse Explorer itself (Files/Tables view) is completely unavailable, and "New item" is grayed out entirely (no semantic model, no agent, nothing).

### Layer 2  Item permissions
Lets you share **one item** without making someone a workspace member at all. Confirmed live: granting a user access to just a warehouse makes that warehouse (and nothing else) discoverable to them via the **OneLake catalog** (since they can't browse the workspace itself).

**Two independent sharing options worth knowing (shown live on the grant dialog):**
- **Read all SQL endpoint data**  grants SQL querying via the endpoint only.
- **Read all Apache Spark**  grants notebook/Spark-level file access.
These are separate checkboxes  granting one doesn't imply the other.

### Layer 3  Granular SQL security (T-SQL commands)
| Command | Effect |
|---|---|
| **GRANT** | Gives permission on a specific object (table, view, stored procedure) |
| **DENY** | Explicitly blocks access  **DENY always wins** over GRANT if a person has both |
| **REVOKE** | Removes a previously applied GRANT *or* DENY  it's not a third rule, just a cleanup/removal of whichever was set |

On top of these: **row-level security**, **column-level security** (e.g., hiding a salary column entirely), and **dynamic data masking** (doesn't hide the column, just obscures the value  e.g., showing `XXX-XX-1234`).

**Live demo confirmed a key layering behavior:** a user with only **ReadData** on a warehouse could `SELECT` but a `DROP TABLE` and a `DELETE FROM` were both denied outright  granular SQL permissions genuinely restrict what SQL verbs are usable, not just which rows/columns are visible.


### Layer 4  OneLake data access (folder-level RBAC)
Since every table in OneLake is really just a folder of Parquet files underneath, this layer lets you restrict access down to **specific folders/tables**, independent of which compute engine (Spark, SQL, Power BI) touches the data.

**3-step process:**
1. Open the lakehouse → **Manage OneLake data access**.
2. **Create a custom role**, selecting exactly which folders/tables it covers.
3. **Assign the role** to a Microsoft Entra ID user or **security group**.

- **Folder security is inheritable**  access to a parent folder cascades down to subfolders.
- Demonstrated live with the healthcare ontology lakehouse: a `shared` role covering `Departments`/`Hospitals`/`Rooms`/`VitalSignEquipment`, and patient data kept out of that role entirely (more restricted)  a direct, practical PII-separation pattern.

### Cross-cutting best practice: use security groups, not individuals
Repeated at every layer: **assign Entra ID security groups, not individual people**, to workspace roles, item permissions, and OneLake roles alike. Managing 1,000 people's access directly doesn't scale; managing group *membership* does  when someone joins or leaves, you update the group once instead of touching every item they had access to.

---

## Exercise 1  Secure Data Access in Microsoft Fabric

**Lab:** [Secure data access in Microsoft Fabric](https://microsoftlearning.github.io/mslearn-fabric/Instructions/Labs/19-secure-data-access.html)

> ⚠️ **This lab genuinely requires two separate user accounts to complete as designed**  one acting as Workspace Admin, one as Workspace Viewer, testing access changes back and forth between two browser sessions. **The lab's own instructions confirm this** and explicitly offer a fallback: *"If you don't have access to a second account in the same organization, you can still do the exercise as a Workspace Admin and skip the steps done as a Workspace Viewer account, referring to the exercise's screenshots to see what a Workspace Viewer account has access to."*

---

## Governing Analytics Data in Microsoft Fabric

### Why governance matters
As the number of lakehouses/warehouses/reports grows across multiple teams, there's **no way to tell which items are trustworthy**  someone's half-finished sandbox experiment looks identical to a reviewed, production-ready asset. Two concrete risks:
1. **An unvetted report reaches leadership**  a polished dashboard built on an experimental warehouse ends up informing a real decision, with nobody realizing it was never reviewed.
2. **An AI agent can't tell the difference either**  from a machine's perspective, an unreviewed table and a trusted one look identical, so it might surface confidential data or answer from the wrong source entirely.

Governance gives you three things: **classification** (sensitivity labels), **trust signals** (endorsement), and **documentation** (descriptions/context)  all of which an AI agent can read and act on, not just humans browsing a catalog.

### Sensitivity labels (Microsoft Purview)
> ⚠️ **Theory only  not demonstrated live.** Requires a **Microsoft Purview P1 or P2 license**
- Four levels, least → most sensitive: **Public** (safe to share with anyone) → **General** (internal, everyday default) → **Confidential** (PII, financial data) → **Highly Confidential** (health records, secrets  strictest handling).
- Levels are **defined by a compliance team**, not invented ad hoc by individual users.
- **Downstream inheritance/propagation**: apply a label **once** at the source (e.g., a lakehouse), and it flows automatically to the SQL endpoint, the semantic model, and the report built on top  you don't re-apply it at every layer.
- **Only ever tightens, never loosens**: a more restrictive label downstream can override a less restrictive one, but a label never gets *weakened* automatically, and automatic propagation never overrides a label someone applied manually.
- **Default labeling** applies a sensible default automatically if nobody applies one; **mandatory labeling** (P1+) blocks saving an item at all until a label is present.
- **Labels travel with exports**  to Excel, PDF, PowerPoint  so protection doesn't vanish the moment data leaves Fabric.
- **AI-specific consequence:** if a protection policy blocks a user from confidential/highly-confidential data, **an AI agent cannot bypass that and surface it anyway**  this is a hard enforcement boundary, not a suggestion to the model.

### Endorsement  three ascending trust tiers
| Tier | Who can apply it | Meaning |
|---|---|---|
| **Promoted** | Anyone with write access, no formal review | "Team-ready, self-service"  the creator's own judgment that it's solid enough to reuse |
| **Certified** | Only an **authorized reviewer/admin** | Vetted across teams  safe to rely on organization-wide |
| **Master data** | Only specific **admin-designated users** | The single source of truth for a concept (e.g., the one real Customer or Product list)  getting this wrong has org-wide consequences |

- **No endorsement at all is itself a signal**  an implicit warning that an item is personal/experimental and shouldn't anchor real decisions.
- **AI relevance:** when an agent has to choose between two similar tables, **a certified item is prioritized over an unendorsed one**  endorsement is a real ranking signal for retrieval, not just a cosmetic badge for humans.
- Demonstrated live: admin portal lets you restrict **who in the org can certify / mark something as master data** (specific security groups)  this shouldn't be open to everyone, by design.

### Documentation, tags, and domains (all demonstrated live)
- **Descriptions**: every item should have one.
- **Tags**: created centrally by admins (Admin portal), then applied to items to make them searchable/groupable across workspaces (e.g., tagging everything related to one e-commerce analytics effort, even if it's spread across several workspaces for access-control reasons).
- **Domains**: an organizational grouping layer above workspaces (e.g., a "Sales" domain)  **one domain can contain multiple workspaces**, confirmed live in response to a question.

### The OneLake catalog's 3 tabs
| Tab | Purpose |
|---|---|
| **Explore** | Browse/search/filter everything by domain, item type, endorsement status, or tag  across **all workspaces at once**. Includes **lineage** (trace data flow from source to report) and **impact analysis** (see what would break *before* you delete/change something). |
| **Govern** | An active to-do list, not just a passive view  flags items with missing descriptions, missing sensitivity labels, or no endorsement, **with recommended actions** on how to fix each one. |
| **Secure** | A cross-workspace view of who has access to what  review, grant, or revoke permissions without hunting through each workspace individually; also shows every OneLake security role created anywhere in the tenant. |

### Bringing it together: governance signals drive AI behavior
Three signals an AI agent reads programmatically, not just a person browsing a catalog:
1. **Sensitivity labels set hard access boundaries**  enforced, not optional.
2. **Endorsement guides trust/ranking**  certified beats unpromoted when choosing between similar sources.
3. **Documentation guides grounding quality**  a vague/missing description leaves an agent "guessing," which produces generic or hallucinated answers (directly connects back to the Day 7 grounding content).

---

## Key Takeaways
- **Connecting a data agent to an ontology is simpler to configure than connecting to plain tables** (no data source instructions or example queries needed)  but requires explicitly telling the agent to **"support group by GQL"** in its instructions, or relationship-style questions will silently fail or go unanswered.
- **The Code Interpreter tool lets a data agent run Python and render real charts**  a capability a Foundry-only agent lacks natively.
- **Operations Agents are proactive** (continuously watch streaming Eventhouse data and act via Teams/Power Automate/notebook), unlike the reactive, chat-driven Fabric Data Agent  and can only connect to an Eventhouse or an ontology, never a lakehouse/warehouse directly.
- **Fabric's security model is a 4-layer funnel**: workspace roles (all-or-nothing) → item permissions (per item) → granular SQL security (table/row/column, via GRANT/DENY/REVOKE, DENY always wins) → OneLake folder-level RBAC (per physical folder, engine-independent).
- **A Viewer sees everything in a workspace but strictly read-only**  this is the single most common misconfiguration mistake; use item permissions instead if you want to limit someone to *one* thing.
- **Semantic-model RLS and warehouse/lakehouse-level security are independent layers**  access at one layer doesn't imply access (or restriction) at another; each must be deliberately configured.
- **Always assign security groups, not individuals**, at every layer  this is the single practice that makes access management scale.
- **Sensitivity labels propagate downstream automatically and only ever tighten**, never loosen, and they travel with exported files.
- **Endorsement has three tiers with increasingly restricted authority to apply them** (Promoted: anyone → Certified: authorized reviewers → Master data: designated admins)  and the *absence* of any endorsement is itself a meaningful signal.
- **Governance isn't just for humans**  sensitivity labels, endorsement, and documentation are all signals an AI agent consumes programmatically to decide what it can access and which source to trust.

## Follow-up
- **Day 10 (tomorrow):** finishing Day 9's security lab, a new topic on **pipelines** (explicitly **not** part of the DP-600 exam, but included as practical skill-building), a quick review session, and guidance on **scheduling/preparing for the certification exam** (home setup requirements for online testing vs. a testing center).
