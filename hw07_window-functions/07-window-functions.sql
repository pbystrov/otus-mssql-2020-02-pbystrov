-- 1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы
-- В качестве запроса с временной таблицей и табличной переменной можно взять свой запрос или следующий запрос:
-- Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
-- Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

-- temp table
DROP TABLE IF EXISTS #sales;
SELECT
    YearMonth = DATEADD(month, DATEDIFF(month, 0, i1.InvoiceDate), 0)
    ,YearMonthTotal = SUM(il1.UnitPrice * il1.Quantity)
    ,RunningTotal = (
        SELECT SUM(il2.UnitPrice * il2.Quantity)
        FROM Sales.Invoices i2
        INNER JOIN Sales.InvoiceLines il2 ON (il2.InvoiceID = i2.InvoiceID)
        WHERE YEAR(i2.InvoiceDate) >= 2015
        AND DATEADD(month, DATEDIFF(month, 0, i1.InvoiceDate), 0) >= DATEADD(month, DATEDIFF(month, 0, i2.InvoiceDate), 0)
    )
INTO #sales
FROM Sales.Invoices i1
INNER JOIN Sales.InvoiceLines il1 ON (il1.InvoiceID = i1.InvoiceID)
WHERE YEAR(i1.InvoiceDate) >= 2015
GROUP BY DATEADD(month, DATEDIFF(month, 0, i1.InvoiceDate), 0);

SELECT
    i.InvoiceID
    ,c.CustomerName
    ,i.InvoiceDate
    ,InvoiceSum = SUM(il.UnitPrice * il.Quantity)
    ,MonthSales = MIN(s.YearMonthTotal)
    ,RunningTotal = MIN(s.RunningTotal)
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON (il.InvoiceID = i.InvoiceID)
INNER JOIN Sales.Customers c ON (i.CustomerID = c.CustomerID)
INNER JOIN #sales s ON (s.YearMonth = DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0))
WHERE YEAR(i.InvoiceDate) >= 2015
GROUP BY
    i.InvoiceID,
    c.CustomerName,
    i.InvoiceDate;

-- table variable
DECLARE @sales TABLE (
    YearMonth DATE
    ,YearMonthTotal DECIMAL(18,2)
    ,RunningTotal DECIMAL(18,2)
)
INSERT INTO @sales
SELECT
    YearMonth = DATEADD(month, DATEDIFF(month, 0, i1.InvoiceDate), 0)
    ,YearMonthTotal = SUM(il1.UnitPrice * il1.Quantity)
    ,RunningTotal = (
        SELECT SUM(il2.UnitPrice * il2.Quantity)
        FROM Sales.Invoices i2
        INNER JOIN Sales.InvoiceLines il2 ON (il2.InvoiceID = i2.InvoiceID)
        WHERE YEAR(i2.InvoiceDate) >= 2015
        AND DATEADD(month, DATEDIFF(month, 0, i1.InvoiceDate), 0) >= DATEADD(month, DATEDIFF(month, 0, i2.InvoiceDate), 0)
    )
FROM Sales.Invoices i1
INNER JOIN Sales.InvoiceLines il1 ON (il1.InvoiceID = i1.InvoiceID)
WHERE YEAR(i1.InvoiceDate) >= 2015
GROUP BY DATEADD(month, DATEDIFF(month, 0, i1.InvoiceDate), 0);

SELECT
    i.InvoiceID
    ,c.CustomerName
    ,i.InvoiceDate
    ,InvoiceSum = SUM(il.UnitPrice * il.Quantity)
    ,MonthSales = MIN(s.YearMonthTotal)
    ,RunningTotal = MIN(s.RunningTotal)
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON (il.InvoiceID = i.InvoiceID)
INNER JOIN Sales.Customers c ON (i.CustomerID = c.CustomerID)
INNER JOIN @sales s ON (s.YearMonth = DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0))
WHERE YEAR(i.InvoiceDate) >= 2015
GROUP BY
    i.InvoiceID,
    c.CustomerName,
    i.InvoiceDate
ORDER BY i.InvoiceDate;
/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

(17 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 2063 ms,  elapsed time = 2061 ms.

(31440 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 187 ms,  elapsed time = 230 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/

-- 2. Если вы брали предложенный выше запрос, то сделайте расчет суммы нарастающим итогом с помощью оконной функции.
-- Сравните 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;
SELECT DISTINCT
    i.InvoiceID
    ,c.CustomerName
    ,i.InvoiceDate
    ,InvoiceSum = SUM(il.UnitPrice * il.Quantity) OVER (PARTITION BY i.InvoiceID)
    ,MonthSales = SUM(il.UnitPrice * il.Quantity) OVER (PARTITION BY DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0))
    ,RunningTotal = SUM(il.UnitPrice * il.Quantity) OVER (ORDER BY DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0))
FROM Sales.Invoices i
LEFT JOIN Sales.InvoiceLines il ON (il.InvoiceID = i.InvoiceID)
LEFT JOIN Sales.Customers c ON (i.CustomerID = c.CustomerID)
WHERE YEAR(i.InvoiceDate) >= 2015
ORDER BY i.InvoiceDate;
/*
Window function быстрее и читабельнее

SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

(31440 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 188 ms,  elapsed time = 275 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/

-- 2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)
SELECT * FROM (
    SELECT *, Position = ROW_NUMBER() OVER (PARTITION BY MonthNum ORDER BY TotalSold DESC) FROM (
        SELECT DISTINCT
            MonthNum = MONTH(i.InvoiceDate)
            ,il.StockItemID
            ,il.Description
            ,TotalSold = SUM(il.Quantity) OVER (PARTITION BY il.StockItemID, MONTH(i.InvoiceDate))
        FROM Sales.Invoices AS i
        LEFT JOIN Sales.InvoiceLines AS il ON (il.InvoiceID = i.InvoiceID)
        WHERE YEAR(i.InvoiceDate) = 2016
    ) AS t
) AS tt
WHERE Position <= 2
ORDER BY MonthNum,Position;

-- 3. Функции одним запросом
-- Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
-- пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
-- посчитайте общее количество товаров и выведите полем в этом же запросе
-- посчитайте общее количество товаров в зависимости от первой буквы названия товара
-- отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
-- предыдущий ид товара с тем же порядком отображения (по имени)
-- названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
-- сформируйте 30 групп товаров по полю вес товара на 1 шт
SELECT
    StockItemID
    ,StockItemName
    ,Brand
    ,UnitPrice
    ,TypicalWeightPerUnit
    ,RowNumber = ROW_NUMBER() OVER (PARTITION BY LEFT(StockItemName,1) ORDER BY LEFT(StockItemName,1))
    ,TotalItemCount = COUNT(StockItemName) OVER ()
    ,ItemCountPerLetter = COUNT(StockItemName) OVER (PARTITION BY LEFT(StockItemName,1))
    ,NextItemId = LEAD(StockItemID) OVER (ORDER BY StockItemName)
    ,PrevItemId = LAG(StockItemID) OVER (ORDER BY StockItemName)
    ,PrevPrevItemName = LAG(StockItemName,2,'No Items') OVER (ORDER BY StockItemName)
    ,ItemWeightGroup = NTILE(30) OVER (ORDER BY TypicalWeightPerUnit)
FROM Warehouse.StockItems;

-- 4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
-- В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки
WITH lastCustomerForEmployee AS (
    SELECT DISTINCT
        EmployeeID = p.PersonID
        ,EmployeeName = p.FullName
        ,CustomerID = LAST_VALUE(i.CustomerID) OVER (
            PARTITION BY p.PersonID ORDER BY i.InvoiceDate,i.InvoiceID ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
        ,Invoice = LAST_VALUE(i.InvoiceID) OVER (
            PARTITION BY p.PersonID ORDER BY i.InvoiceDate,i.InvoiceID ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
        ,InvoiceDate = LAST_VALUE(i.InvoiceDate) OVER (
            PARTITION BY p.PersonID ORDER BY i.InvoiceDate,i.InvoiceID ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
    FROM Application.People AS p
    INNER JOIN Sales.Invoices AS i ON (i.SalespersonPersonID = p.PersonID)
)
SELECT DISTINCT
    l.EmployeeID
    ,l.EmployeeName
    ,l.CustomerID
    ,c.CustomerName
    ,l.Invoice
    ,l.InvoiceDate
    ,InvoiceSum = SUM(il.UnitPrice * il.Quantity) OVER (PARTITION BY il.InvoiceID)
FROM lastCustomerForEmployee AS l
INNER JOIN Sales.Customers AS c ON (l.CustomerID = c.CustomerID)
INNER JOIN Sales.InvoiceLines AS il ON (il.InvoiceID = l.Invoice);

-- 5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
-- В результатах должно быть ид клиента, его название, ид товара, цена, дата покупки
WITH expensivestItemsForClient AS (
    SELECT DISTINCT
        i.CustomerID
        ,OrderID = LAST_VALUE(i.OrderID) OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC)
        ,InvoiceDate = LAST_VALUE(i.InvoiceDate) OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC)
        ,StockItemID = LAST_VALUE(il.StockItemID) OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC)
        ,StockItemName = LAST_VALUE(il.Description) OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC)
        ,il.UnitPrice
        ,PriceRank = DENSE_RANK() OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC)
    FROM Sales.InvoiceLines AS il
    INNER JOIN Sales.Invoices AS i ON (i.InvoiceID = il.InvoiceID)
)
SELECT DISTINCT
    e.CustomerID
    ,c.CustomerName
    ,e.StockItemID
    ,e.StockItemName
    ,StockItemPrice = e.UnitPrice
    ,SaleDate = e.InvoiceDate
    ,e.PriceRank
FROM expensivestItemsForClient AS e
INNER JOIN Sales.Customers AS c ON (e.CustomerID = c.CustomerID AND e.PriceRank <= 2)
ORDER BY CustomerName,PriceRank;