let
  Source = Csv.Document(Web.Contents("https://raw.githubusercontent.com/MicrosoftLearning/dp-data/main/orders.csv"), [Delimiter = ",", Columns = 7, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
  #"Changed column type" = Table.TransformColumnTypes(#"Promoted headers", {{"SalesOrderID", Int64.Type}, {"OrderDate", type date}, {"CustomerID", Int64.Type}, {"LineItem", Int64.Type}, {"ProductID", Int64.Type}, {"OrderQty", Int64.Type}, {"LineItemTotal", type number}}),
  #"Choose columns" = Table.SelectColumns(#"Changed column type", {"OrderDate", "CustomerID", "LineItem", "OrderQty", "LineItemTotal"}),
  #"Filtered rows" = Table.SelectRows(#"Choose columns", each [OrderDate] <> null and [OrderDate] <> ""),
  #"Filtered rows 1" = Table.SelectRows(#"Filtered rows", each [OrderQty] >= 0),
  #"Renamed columns" = Table.RenameColumns(#"Filtered rows 1", {{"OrderQty", "Quantity"}, {"LineItemTotal", "Line Total"}, {"LineItem", "Item"}}),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Renamed columns", "Unit Price", each [Line Total] / [Quantity]), {{"Unit Price", type number}})
in
  #"Added custom"
