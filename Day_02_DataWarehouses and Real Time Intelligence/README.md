# Day 2: Data Warehouses and Real-Time Intelligence

## Daily Learning Summary
* **Data Warehousing Concepts:** Explored the differences between OLTP (operational, transactional data) and OLAP (analytical data), and learned the fundamentals of dimensional modeling including Fact tables, Dimension tables, and Star versus Snowflake schemas.
* **Fabric Warehouse vs. SQL Endpoint:** A Fabric Warehouse supports full T-SQL read and write capabilities (DDL and DML), allowing users to create tables, alter schemas, and insert/update/delete records. In contrast, the Lakehouse SQL Analytics Endpoint is strictly read-only.
* **Security Layers:** Covered the hierarchy of security in Fabric, ranging from broad workspace roles down to item-level permissions and granular SQL security, including row-level security, column-level security, and dynamic data masking.
* **Real-Time Intelligence Components:** Examined the end-to-end real-time flow: Event Streams route data (the "plumbing"), Event Houses store it in KQL databases, KQL (Kusto Query Language) analyzes it, Dashboards visualize it, and Activators monitor conditions to trigger alerts.

## Data Warehouse & Real-Time Labs

### Exercise 3: Analyze data in a data warehouse
* **Action:** Created a Fabric workspace backed by a Fabric capacity and provisioned a new Data Warehouse workload. 
* **Purpose:** To utilize a relational database designed for large-scale analytics, which provides full SQL semantics (INSERT, UPDATE, DELETE) unlike the default read-only SQL endpoint of a lakehouse.
* **Action:** Used the T-SQL tile to write DDL queries (`CREATE TABLE`) to define the `dbo.DimProduct` table, followed by DML queries (`INSERT INTO`) to load it with sample rows. Subsequently ran a larger script to fully populate a schema containing `DimCustomer`, `DimDate`, `DimProduct`, and `FactSalesOrder` tables.
* **Purpose:** To build a foundational star schema where fact tables contain aggregatable numeric measures (e.g., sales revenue) and dimension tables contain descriptive attributes (e.g., product or customer details).
* **Action:** Created a saved SQL view named `vSalesByRegion` using a `CREATE VIEW` statement that joined the fact and dimension tables and aggregated revenue by region and date. 
* **Purpose:** To encapsulate complex SQL logic into a reusable object for downstream analytics and reporting.
* **Action:** Used the visual query designer to drag `FactSalesOrder` and `DimProduct` onto the canvas. Combined them using the "Merge queries" function with a Left outer join on `ProductKey`, and expanded the `ProductName` column from the merged data.
* **Purpose:** To demonstrate how to use no-code visual tools to perform data transformations and joins.
* **Action:** Generated a Semantic Model on top of the warehouse and manually defined one-to-many relationships linking the dimension keys to the fact table keys.
* **Purpose:** To prepare the warehouse data for downstream Power BI reporting using Direct Lake mode.

## Repository Artifacts
* `sql/queries.txt`: Contains the DDL and DML scripts used to provision and populate the fact and dimension tables.
* `interactive exercises`: Contains Microsoft learn material that was used for the exercise.