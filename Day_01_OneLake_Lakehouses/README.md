# Day 1: OneLake and Lakehouses

## Daily Learning Summary
* **End-to-End Analytics with Fabric:** Microsoft Fabric is a unified SaaS platform that integrates Data Engineering, Data Warehousing, Real-Time Intelligence, Data Science, and Power BI.
* **OneLake and Open Formats:** OneLake functions as a single logical data lake for the entire organization. All data is stored in an open Delta Parquet format natively, preventing data silos and allowing AI agents to access governed data without needing separate preparation pipelines.
* **Data Virtualization:** Explored "Shortcuts," a feature used to reference data from other workspaces or external cloud storages without duplicating the physical data.

## Lakehouse Labs & Exercises

### Exercise 1: Discover data in OneLake
* **Action:** Created a Fabric workspace and an initial Lakehouse. Uploaded the `sales.csv` resource file into the Lakehouse's unstructured files area, then used "Load to Tables" to land it in the structured Tables section.
* **Purpose:** To understand the difference between unstructured file storage and governed Delta Parquet tables, and to practice basic data ingestion.
* **Action:** Created a second Lakehouse and established a shortcut to the table residing in the first Lakehouse.
* **Purpose:** To demonstrate data virtualization, allowing data access across different workloads without physically copying the underlying files.
* **Action:** Created a Semantic Model connected directly to the `dbo.sales` table.
* **Purpose:** To prepare the Lakehouse data for Power BI reporting using Direct Lake mode.

### Exercise 2: Querying and Data Transformation
* **Action:** Created a Visual Query in the Lakehouse, used "Manage columns" to select specific fields, and transformed the sales data by grouping by `SalesOrderNumber` to generate a distinct count of line items per order.
* **Purpose:** To utilize the built-in SQL Analytics Endpoint's visual tools for no-code data exploration and aggregation.
* **Action:** Created a Fabric Notebook to read and transform data from the Lakehouse using Spark SQL.
* **Purpose:** To leverage the Apache Spark compute engine for programmatic data analysis and query execution.

## Repository Artifacts
* `notebooks/Ex2_Data_Exploration.ipynb`: Contains the PySpark/Spark SQL code for Lakehouse data transformations, including the following query executed during Exercise 2:
  ```python
  # Number of line items by sales order number
  query = """
  SELECT
      SalesOrderNumber,
      Count(DISTINCT SalesOrderLineNumber) AS LineCount
  FROM LH_Ex_1.dbo.sales
  GROUP BY SalesOrderNumber
  ORDER BY LineCount DESC
  """
  grouped_result = spark.sql(query)
  display(grouped_result)