-- 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ
SELECT TOP (10)
    [o].[OrderID],
    [o].[OrderDate],
    [c].[CustomerName],
    [p].[FullName] AS [EmployeeName]
FROM [Sales].[Orders] [o]
JOIN [Sales].[Customers] [c] ON [o].[CustomerID] = [c].[CustomerID]
JOIN [Application].[People] [p] ON [o].[SalespersonPersonID] = [p].[PersonID]
ORDER BY [o].[OrderDate] DESC