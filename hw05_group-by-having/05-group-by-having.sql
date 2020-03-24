-- 1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
SELECT
    YearMonth = FORMAT(i.InvoiceDate, 'yyyy-MM'),
    AverageItemPrice = AVG(il.UnitPrice),
    SalesTotal = SUM(il.UnitPrice * il.Quantity)
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
GROUP BY FORMAT(i.InvoiceDate, 'yyyy-MM');

-- 2. Отобразить все месяцы, где общая сумма продаж превысила 10 000
SELECT
    YearMonth = FORMAT(i.InvoiceDate, 'yyyy-MM'),
    SalesTotal = SUM(il.UnitPrice * il.Quantity)
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
GROUP BY FORMAT(i.InvoiceDate, 'yyyy-MM')
HAVING SUM(il.UnitPrice * il.Quantity) > 10000
ORDER BY YearMonth;

-- 3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам по товарам,
--    продажи которых менее 50 ед в месяц. Группировка должна быть по году и месяцу
SELECT
    YearMonth = FORMAT(i.InvoiceDate, 'yyyy-MM'),
    SalesTotal = SUM(il.UnitPrice * il.Quantity),
    FirstSale = (SELECT MIN(i.InvoiceDate) WHERE StockItemID = il.StockItemID),
    TotalItemsSold = SUM(il.Quantity)
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
GROUP BY FORMAT(i.InvoiceDate, 'yyyy-MM'), il.StockItemID
HAVING SUM(il.Quantity) < 50;

-- 4. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную
DROP TABLE IF EXISTS #tempCTE;
WITH myEmployeesCTE AS (
    SELECT
        EmployeeID
        ,Name = CONCAT(FirstName, ' ', LastName)
        ,Title
        ,ManagerID
        ,EmployeeLevel = 1
    FROM dbo.MyEmployees
    WHERE ManagerID IS NULL
    UNION ALL
    SELECT
        me.EmployeeID
        ,Name = CONCAT(me.FirstName, ' ', me.LastName)
        ,me.Title
        ,me.ManagerID
        ,EmployeeLevel = EmployeeLevel + 1
    FROM dbo.MyEmployees me
    INNER JOIN myEmployeesCTE meCTE ON meCTE.EmployeeID = me.ManagerID
)
SELECT * INTO #tempCTE FROM myEmployeesCTE;

SELECT
    EmployeeID
    ,Name = CONCAT(REPLICATE('| ', EmployeeLevel-1), Name)
    ,Title
    ,EmployeeLevel
FROM #tempCTE;