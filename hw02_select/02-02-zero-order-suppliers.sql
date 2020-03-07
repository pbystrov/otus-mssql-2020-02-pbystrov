-- Поставщики, у которых не было сделано ни одного заказа
SELECT
    [ps].[SupplierID],
    [ps].[SupplierName]
FROM [Purchasing].[Suppliers] [ps]
LEFT JOIN [Purchasing].[SupplierTransactions] [pst] ON [ps].[SupplierID] = [pst].[SupplierID]
WHERE [pst].[SupplierTransactionID] IS NULL