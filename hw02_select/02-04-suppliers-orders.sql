-- Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post,
-- добавьте название поставщика, имя контактного лица принимавшего заказ
SELECT
    [po].[PurchaseOrderID],
    [po].[OrderDate],
    [po].[IsOrderFinalized],
    [dm].[DeliveryMethodName],
    [s].[SupplierName],
    [p].[FullName] AS [ContactName]
FROM [Purchasing].[PurchaseOrders] [po]
JOIN [Application].[DeliveryMethods] [dm] ON [po].[DeliveryMethodID] = [dm].[DeliveryMethodID]
JOIN [Application].[People] [p] ON [po].[ContactPersonID] = [p].[PersonID]
JOIN [Purchasing].[Suppliers] [s] ON [po].[SupplierID] = [s].[SupplierID]
WHERE [po].[IsOrderFinalized] = 1
  AND DATEPART(YEAR, [po].[OrderDate]) = 2014
  AND [dm].[DeliveryMethodName] IN ('Road Freight', 'Post')