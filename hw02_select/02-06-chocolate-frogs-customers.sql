-- Все id и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g
SELECT DISTINCT
    [c].[CustomerID],
    [c].[CustomerName],
    [c].[PhoneNumber]
FROM [Sales].[Orders] [o]
JOIN [Sales].[OrderLines] [ol] ON [o].[OrderID] = [ol].[OrderID]
JOIN [Sales].[Customers] [c] ON [o].[CustomerID] = [c].[CustomerID]
WHERE [ol].[Description] = 'Chocolate frogs 250g'