-- Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа,
-- включите также к какой трети года относится дата - каждая треть по 4 месяца,
-- дата забора заказа должна быть задана, с ценой товара более 100$ либо количество единиц товара более 20.
-- Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей.
-- Сортировка должна быть по номеру квартала, трети года, дате продажи
SELECT DISTINCT
    [o].[OrderID],
    [o].[OrderDate],
    DATENAME(MONTH, [o].[OrderDate]) AS [OrderMonth],
    DATEPART(QUARTER, [o].[OrderDate]) AS [OrderQuarter],
    (MONTH([o].[OrderDate])-1)/4+1 AS [OrderTrimester]
FROM [Sales].[Orders] [o]
LEFT JOIN [Sales].[OrderLines] [ol] ON [o].[OrderID] = [ol].[OrderID]
WHERE [ol].[PickingCompletedWhen] IS NOT NULL
  AND ([ol].[UnitPrice] > 100 OR [ol].[Quantity] > 20)
ORDER BY [OrderQuarter],
         [OrderTrimester],
         [o].[OrderDate]
--OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY