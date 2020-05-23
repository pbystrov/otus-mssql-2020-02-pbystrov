-- 1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
-- Название клиента
-- МесяцГод Количество покупок

-- Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
-- имя клиента нужно поменять так чтобы осталось только уточнение
-- например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
-- дата должна иметь формат dd.mm.yyyy например 25.12.2019
SELECT * FROM (
    SELECT
        InvoiceMonth = FORMAT(DATEADD(month, DATEDIFF(month, 0, InvoiceDate), 0), 'dd.MM.yyyy')
        ,Customer = REPLACE(SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName)+1, 100), ')', '')
        ,PurchaseCount = InvoiceID
    FROM Sales.Invoices AS i
    INNER JOIN Sales.Customers AS c ON (i.CustomerID = c.CustomerID AND i.CustomerID IN (2,3,4,5,6))
) AS tbl
PIVOT (
    COUNT(PurchaseCount) FOR Customer IN (
        [Sylvanite, MT]
        ,[Peeples Valley, AZ]
        ,[Medicine Lodge, KS]
        ,[Gasport, NY]
        ,[Jessie, ND]
    )
) AS pvt;

-- 2. Для всех клиентов с именем, в котором есть Tailspin Toys
-- вывести все адреса, которые есть в таблице, в одной колонке
SELECT CustomerName,AddressLine FROM (
    SELECT
        CustomerName
        ,DeliveryAddressLine1
        ,DeliveryAddressLine2
        ,PostalAddressLine1
        ,PostalAddressLine2
    FROM Sales.Customers WHERE CustomerName LIKE 'Tailspin Toys%'
) AS tbl
UNPIVOT (
    AddressLine FOR col IN (
        DeliveryAddressLine1
        ,DeliveryAddressLine2
        ,PostalAddressLine1
        ,PostalAddressLine2
    )
) AS unpvt;

-- 3. В таблице стран есть поля с кодом страны цифровым и буквенным
-- сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код
SELECT
    unpvt.CountryID
    ,c.CountryName
    ,unpvt.Code
FROM (
    SELECT
        CountryID
        ,CodeA = IsoAlpha3Code
        ,CodeN = CAST(IsoNumericCode AS nvarchar(3))
    FROM Application.Countries
) AS tbl
UNPIVOT (
    Code FOR col IN (CodeA, CodeN)
) AS unpvt
INNER JOIN Application.Countries AS c ON (unpvt.CountryID = c.CountryID);

-- 4. Перепишите ДЗ из оконных функций через CROSS APPLY
-- Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
-- В результатах должно быть ид клиента, его название, ид товара, цена, дата покупки
SELECT
    CustomerID
    ,CustomerName
    ,xapply.*
FROM Sales.Customers AS c
CROSS APPLY (
    SELECT TOP (2)
        il.StockItemID
        ,StockItemName = il.Description
        ,StockItemPrice = il.UnitPrice
        ,PurchaseDate = i.InvoiceDate
    FROM Sales.InvoiceLines AS il
    INNER JOIN Sales.Invoices AS i ON (il.InvoiceID = i.InvoiceID)
    WHERE i.CustomerID = c.CustomerID
    ORDER BY il.UnitPrice DESC
) AS xapply;