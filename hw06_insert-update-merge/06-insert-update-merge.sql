-- 1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers
INSERT INTO Purchasing.Suppliers (
    SupplierName
    ,SupplierCategoryID
    ,PrimaryContactPersonID
    ,AlternateContactPersonID
    ,DeliveryMethodID
    ,DeliveryCityID
    ,PostalCityID
    ,SupplierReference
    ,BankAccountName
    ,BankAccountBranch
    ,BankAccountCode
    ,BankAccountNumber
    ,BankInternationalCode
    ,PaymentDays
    ,InternalComments
    ,PhoneNumber
    ,FaxNumber
    ,WebsiteURL
    ,DeliveryAddressLine1
    ,DeliveryAddressLine2
    ,DeliveryPostalCode
    ,DeliveryLocation
    ,PostalAddressLine1
    ,PostalAddressLine2
    ,PostalPostalCode
    ,LastEditedBy
    ,ValidFrom
    ,ValidTo
)
VALUES (
    'New Supplier1'
    ,1
    ,1
    ,1
    ,1
    ,1
    ,1
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,5
    ,'Internal comment1'
    ,'(999) 123-4567'
    ,'(999) 891-0111'
    ,'https://newsupplier1.com'
    ,'Apt. 37'
    ,'Beverly Hills'
    ,'90210'
    ,NULL
    ,'Apt. 37'
    ,'Beverly Hills'
    ,'90210'
    ,1
    ,DEFAULT
    ,DEFAULT
);

INSERT INTO Purchasing.Suppliers (
    SupplierName
    ,SupplierCategoryID
    ,PrimaryContactPersonID
    ,AlternateContactPersonID
    ,DeliveryMethodID
    ,DeliveryCityID
    ,PostalCityID
    ,SupplierReference
    ,BankAccountName
    ,BankAccountBranch
    ,BankAccountCode
    ,BankAccountNumber
    ,BankInternationalCode
    ,PaymentDays
    ,InternalComments
    ,PhoneNumber
    ,FaxNumber
    ,WebsiteURL
    ,DeliveryAddressLine1
    ,DeliveryAddressLine2
    ,DeliveryPostalCode
    ,DeliveryLocation
    ,PostalAddressLine1
    ,PostalAddressLine2
    ,PostalPostalCode
    ,LastEditedBy
)
SELECT TOP (4)
    CONCAT('New Supplier ', NEWID())
    ,SupplierCategoryID
    ,PrimaryContactPersonID - 1
    ,AlternateContactPersonID / 2
    ,NULL
    ,DeliveryCityID
    ,PostalCityID
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,5
    ,NULL
    ,'(999) 123-4567'
    ,'(999) 891-0111'
    ,'https://example.com'
    ,'Some address line'
    ,NULL
    ,'12345'
    ,NULL
    ,'Some postal address line'
    ,NULL
    ,'67891'
    ,LastEditedBy
FROM Purchasing.Suppliers;

-- 2. удалите 1 запись, которая была вами добавлена
DELETE FROM Purchasing.Suppliers
WHERE ValidFrom > '2020-03-29'
AND SupplierName = 'New Supplier1';

-- 3. изменить одну запись, из добавленных через UPDATE
UPDATE Purchasing.Suppliers
SET SupplierName = 'New Supplier2', InternalComments = 'Unnecessary comment'
WHERE SupplierID = 15;

-- 4. Написать MERGE, который вставит вставит запись, если ее там нет, и изменит если она уже есть
WITH newSupplierCTE (
    SupplierName
    ,SupplierCategoryID
    ,PrimaryContactPersonID
    ,AlternateContactPersonID
    ,DeliveryCityID
    ,PostalCityID
    ,PaymentDays
    ,InternalComments
    ,PhoneNumber
    ,FaxNumber
    ,WebsiteURL
    ,DeliveryAddressLine1
    ,DeliveryPostalCode
    ,PostalAddressLine1
    ,PostalPostalCode
    ,LastEditedBy
) AS (
    SELECT
        'Merge Supplier'
        ,SupplierCategoryID
        ,PrimaryContactPersonID
        ,AlternateContactPersonID
        ,DeliveryCityID
        ,PostalCityID
        ,PaymentDays
        ,InternalComments
        ,PhoneNumber
        ,FaxNumber
        ,WebsiteURL
        ,DeliveryAddressLine1
        ,DeliveryPostalCode
        ,PostalAddressLine1
        ,PostalPostalCode
        ,LastEditedBy
    FROM Purchasing.Suppliers
    WHERE SupplierID = (SELECT MAX(SupplierID) FROM Purchasing.Suppliers WHERE InternalComments IS NOT NULL)
)
MERGE Purchasing.Suppliers AS dest
USING newSupplierCTE AS src
ON (dest.SupplierName = src.SupplierName)
WHEN MATCHED
    THEN UPDATE SET SupplierName = 'Even Newer Supplier'
WHEN NOT MATCHED
    THEN INSERT (
        SupplierName
        ,SupplierCategoryID
        ,PrimaryContactPersonID
        ,AlternateContactPersonID
        ,DeliveryCityID
        ,PostalCityID
        ,PaymentDays
        ,InternalComments
        ,PhoneNumber
        ,FaxNumber
        ,WebsiteURL
        ,DeliveryAddressLine1
        ,DeliveryPostalCode
        ,PostalAddressLine1
        ,PostalPostalCode
        ,LastEditedBy
    ) VALUES (
        src.SupplierName
        ,src.SupplierCategoryID
        ,src.PrimaryContactPersonID
        ,src.AlternateContactPersonID
        ,src.DeliveryCityID
        ,src.PostalCityID
        ,src.PaymentDays
        ,src.InternalComments
        ,src.PhoneNumber
        ,src.FaxNumber
        ,src.WebsiteURL
        ,src.DeliveryAddressLine1
        ,src.DeliveryPostalCode
        ,src.PostalAddressLine1
        ,src.PostalPostalCode
        ,src.LastEditedBy
    );

-- 5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
EXEC master.dbo.xp_cmdshell 'bcp.exe "Purchasing.Suppliers" out "C:\sql_backup\suppliers.bcp" -d WideWorldImporters -T -w -t (())'

CREATE TABLE [dbo].[MySuppliers] (
    [SupplierID] [int] NOT NULL PRIMARY KEY CLUSTERED,
    [SupplierName] [nvarchar](100) NOT NULL,
    [SupplierCategoryID] [int] NOT NULL,
    [PrimaryContactPersonID] [int] NOT NULL,
    [AlternateContactPersonID] [int] NOT NULL,
    [DeliveryMethodID] [int] NULL,
    [DeliveryCityID] [int] NOT NULL,
    [PostalCityID] [int] NOT NULL,
    [SupplierReference] [nvarchar](20) NULL,
    [BankAccountName] [nvarchar](50) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountBranch] [nvarchar](50) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountCode] [nvarchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankAccountNumber] [nvarchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
    [BankInternationalCode] [nvarchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
    [PaymentDays] [int] NOT NULL,
    [InternalComments] [nvarchar](max) NULL,
    [PhoneNumber] [nvarchar](20) NOT NULL,
    [FaxNumber] [nvarchar](20) NOT NULL,
    [WebsiteURL] [nvarchar](256) NOT NULL,
    [DeliveryAddressLine1] [nvarchar](60) NOT NULL,
    [DeliveryAddressLine2] [nvarchar](60) NULL,
    [DeliveryPostalCode] [nvarchar](10) NOT NULL,
    [DeliveryLocation] [geography] NULL,
    [PostalAddressLine1] [nvarchar](60) NOT NULL,
    [PostalAddressLine2] [nvarchar](60) NULL,
    [PostalPostalCode] [nvarchar](10) NOT NULL,
    [LastEditedBy] [int] NOT NULL,
    [ValidFrom] [datetime2](7) NOT NULL,
    [ValidTo] [datetime2](7) NOT NULL
);

BULK INSERT WideWorldImporters.dbo.MySuppliers
FROM "C:\sql_backup\suppliers.bcp"
WITH (
    BATCHSIZE = 1000,
    DATAFILETYPE = 'widechar',
    FIELDTERMINATOR = '(())',
    ROWTERMINATOR ='\n',
    KEEPNULLS
);

SELECT * from MySuppliers;