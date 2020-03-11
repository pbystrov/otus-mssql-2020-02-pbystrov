-- 1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи
-- 1-subquery
SELECT
    [p].[PersonID],
    [p].[FullName]
FROM [Application].[People] [p]
WHERE [IsSalesperson] = 1
    AND NOT EXISTS (
        SELECT 1
        FROM [Sales].[Orders]
        WHERE [SalespersonPersonID] = [p].[PersonID]
        );

-- 1-CTE
WITH salesPersonCTE (PersonID, FullName) AS
(
    SELECT [PersonID],[FullName]
    FROM [Application].[People]
    WHERE [IsSalesperson] = 1
)
SELECT [s].[PersonID],[s].[FullName]
FROM [salesPersonCTE] [s]
LEFT JOIN [Sales].[Orders] [o] ON [o].[SalespersonPersonID] = [s].[PersonID]
WHERE [o].[OrderID] IS NULL;

-- 2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса
-- 2-subquery-1
SELECT
    [StockItemID],
    [StockItemName],
    [UnitPrice]
FROM [Warehouse].[StockItems]
WHERE [UnitPrice] <= ALL (SELECT [UnitPrice] FROM [Warehouse].[StockItems]);

-- 2-subquery-2
SELECT
    [StockItemID],
    [StockItemName],
    [UnitPrice]
FROM [Warehouse].[StockItems]
WHERE [UnitPrice] = (SELECT MIN([UnitPrice]) FROM [Warehouse].[StockItems]);

-- 2-CTE
WITH tenCheapestCTE (StockItemID) AS
(
    SELECT TOP (10) [StockItemID]
    FROM [Warehouse].[StockItems]
    ORDER BY [UnitPrice] ASC
)
SELECT
    [StockItemID],
    [StockItemName],
    [UnitPrice]
FROM [Warehouse].[StockItems]
WHERE [StockItemID] IN (SELECT [StockItemID] FROM [tenCheapestCTE]);

-- 3. Выберите информацию по клиентам, которые перевели компании 5 максимальных платежей из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
-- 3-subquery-1
SELECT
    [CustomerID],
    [CustomerName]
FROM [Sales].[Customers]
WHERE [CustomerID] IN (
    SELECT TOP (5) [CustomerID]
    FROM [Sales].[CustomerTransactions]
    ORDER BY [TransactionAmount] DESC
    );

-- 3-subquery-2
SELECT TOP (5)
    [c].[CustomerID],
    [c].[CustomerName]
FROM [Sales].[Customers] [c]
JOIN (
    SELECT [CustomerID], [TransactionAmount]
    FROM [Sales].[CustomerTransactions]
    ) [t] ON [c].[CustomerID] = [t].[CustomerID]
ORDER BY [t].[TransactionAmount] DESC;

-- 3-CTE
WITH fiveLargestCTE (CustomerID) AS
(
    SELECT TOP (5) [CustomerID]
    FROM [Sales].[CustomerTransactions]
    ORDER BY [TransactionAmount] DESC
)
SELECT
    [CustomerID],
    [CustomerName]
FROM [Sales].[Customers]
WHERE [CustomerID] IN (SELECT [CustomerID] FROM [fiveLargestCTE]);

-- 4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов
-- 4-subquery
SELECT
    [ci].[CityID],
    CONCAT([ci].[CityName],', ',[sp].[StateProvinceCode]) AS [CityName],
    [p].[FullName] AS [PackedBy],
    [i].[OrderID],[i].*
FROM [Sales].[Invoices] [i]
JOIN (
    SELECT DISTINCT [OrderID] FROM [Sales].[OrderLines]
    WHERE [StockItemID] IN (SELECT TOP (3) [StockItemID] FROM [Warehouse].[StockItems] ORDER BY [UnitPrice] DESC)
) [o] ON [o].[OrderID] = [i].[OrderID]
JOIN [Sales].[Customers] [c] ON [c].[CustomerID] = [i].[CustomerID]
JOIN [Application].[Cities] [ci] ON [ci].[CityID] = [c].[DeliveryCityID]
JOIN [Application].[StateProvinces] [sp] ON [ci].[StateProvinceID] = [sp].[StateProvinceID]
JOIN [Application].[People] [p] ON [p].[PersonID] = [i].[PackedByPersonID];

-- 4-CTE
WITH priciestItemsCTE (StockItemID) AS
(
    SELECT TOP (3) [StockItemID]
    FROM [Warehouse].[StockItems]
    ORDER BY [UnitPrice] DESC
),
ordersCTE (OrderID) AS
(
    SELECT DISTINCT [OrderID] FROM [Sales].[OrderLines]
    WHERE [StockItemID] IN (SELECT [StockItemID] FROM [priciestItemsCTE])
)
SELECT
    [ci].[CityID],
    CONCAT([ci].[CityName],', ',[sp].[StateProvinceCode]) AS [CityName],
    [p].[FullName] AS [PackedBy],
    [i].[OrderID]
FROM [ordersCTE] [o]
JOIN [Sales].[Invoices] [i] ON [o].[OrderID] = [i].[OrderID]
JOIN [Sales].[Customers] [c] ON [c].[CustomerID] = [i].[CustomerID]
JOIN [Application].[Cities] [ci] ON [ci].[CityID] = [c].[DeliveryCityID]
JOIN [Application].[StateProvinces] [sp] ON [ci].[StateProvinceID] = [sp].[StateProvinceID]
JOIN [Application].[People] [p] ON [p].[PersonID] = [i].[PackedByPersonID];

-- 5. Объясните, что делает и оптимизируйте запрос:
-- Запрос выбирает полностью собранные заказы, дату заказа, продавца,
-- полную стоимость заказа и полную сумму соответсвующих инвойсов дороже 27000
SELECT Invoices.InvoiceID,
    Invoices.InvoiceDate,
    (   -- подзапрос для соотнесения продавца в инвойсе с полным именем
        SELECT People.FullName
        FROM Application.People
        WHERE People.PersonID = Invoices.SalespersonPersonID
    ) AS SalesPersonName,
    SalesTotals.TotalSumm AS TotalSummByInvoice,
    (   -- подзапрос для расчета общей стоимости заказа
        SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
        FROM Sales.OrderLines
        WHERE OrderLines.OrderId = 
        (   -- подзапрос для определения собранных заказов
            SELECT Orders.OrderId
            FROM Sales.Orders
            WHERE Orders.PickingCompletedWhen IS NOT NULL
            AND Orders.OrderId = Invoices.OrderId
        )
    ) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN ( -- подзапрос, выбирающий инвойсы с общей стоимостью товаров более 27000
    SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
    FROM Sales.InvoiceLines
    GROUP BY InvoiceId
    HAVING SUM(Quantity * UnitPrice) > 27000
    ) AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

-- 5-not-so-optimized-1
SELECT
    [InvoiceId],
    [InvoiceDate],
    [SalesPersonName] = (
        SELECT [FullName] FROM [Application].[People]
        WHERE [PersonID] = [SalespersonPersonID]
    ),
    [TotalSummForPickedItems] = (
        SELECT SUM([PickedQuantity] * [UnitPrice])
        FROM [Sales].[OrderLines]
        WHERE [OrderLines].[OrderId] = (
            SELECT [Orders].[OrderId] FROM [Sales].[Orders]
            WHERE [Orders].[PickingCompletedWhen] IS NOT NULL
            AND [Orders].[OrderId] = [Invoices].[OrderId]
        )
    ),
    [TotalSummByInvoice] = (
        SELECT SUM([Quantity] * [UnitPrice])
        FROM [Sales].[InvoiceLines]
        WHERE [InvoiceID] = [Invoices].[InvoiceID]
    )
FROM [Sales].[Invoices]
ORDER BY [TotalSummByInvoice] DESC;

-- 5-not-so-optimized-2
WITH premiumInvoicesCTE (InvoiceId,InvoiceDate,SalespersonPersonID,OrderId,TotalSum) AS
(
    SELECT
        [il].[InvoiceId],
        [i].[InvoiceDate],
        [i].[SalespersonPersonID],
        [i].[OrderId],
        [TotalSum] = SUM([il].[Quantity] * [il].[UnitPrice])
    FROM [Sales].[InvoiceLines] [il]
    JOIN [Sales].[Invoices] [i] ON [il].[InvoiceID] = [i].[InvoiceID]
    GROUP BY [il].[InvoiceId], [i].[InvoiceDate], [i].[SalespersonPersonID], [i].[OrderId]
    HAVING SUM([il].[Quantity] * [il].[UnitPrice]) > 27000
),
premiumInvoiceOrdersCTE (OrderId,TotalSumForPickedItems) AS
(
    SELECT [OrderId], SUM([PickedQuantity] * [UnitPrice])
    FROM [Sales].[OrderLines]
    WHERE [OrderId] IN 
    (
        SELECT [OrderId] FROM [Sales].[Orders]
        WHERE [PickingCompletedWhen] IS NOT NULL
        AND [OrderId] IN (SELECT [OrderId] FROM [premiumInvoicesCTE])
    )
    GROUP BY [OrderID]
)
SELECT
    [i].[InvoiceId],
    [i].[InvoiceDate],
    [p].[FullName],
    [TotalSumByInvoice] = [i].[TotalSum],
    [o].[TotalSumForPickedItems]
FROM [premiumInvoicesCTE] [i]
JOIN [premiumInvoiceOrdersCTE] [o] ON [o].[OrderId] = [i].[OrderId]
JOIN [Application].[People] [p] ON [p].[PersonID] = [i].[SalespersonPersonID]
ORDER BY [TotalSumByInvoice] DESC;
