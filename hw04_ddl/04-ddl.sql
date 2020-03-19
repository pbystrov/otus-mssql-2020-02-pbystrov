/*  Нужно используя операторы DDL создать:
    1. Создать базу данных
    2. 3-4 основные таблицы для своего проекта
    3. Первичные и внешние ключи для всех созданных таблиц
    4. 1-2 индекса на таблицы
    5. Наложите по одному ограничению в каждой таблице на ввод данных   */

-- 1
CREATE DATABASE [suvidor]
ON PRIMARY (
    NAME = suvidor_data,
    FILENAME = 'C:\sql_data\suvidor.mdf',
    SIZE = 32MB,
    FILEGROWTH = 16MB
)
LOG ON (
    NAME = suvidor_log,
    FILENAME = 'C:\sql_logs\suvidor.ldf',
    SIZE = 16MB,
    FILEGROWTH = 16MB
);
GO

-- 2, 3
USE [suvidor];
GO

CREATE TABLE [ingredients] (
    [ingredientID] int NOT NULL IDENTITY,
    [name] nvarchar(256) NOT NULL, 
    CONSTRAINT [PK_ingredients] PRIMARY KEY CLUSTERED ([ingredientID] ASC)
);
CREATE TABLE [products] (
    [productID] int NOT NULL IDENTITY,
    [ingredientID] int NOT NULL,
    [name] nvarchar(256) NOT NULL, 
    CONSTRAINT [PK_products] PRIMARY KEY CLUSTERED ([productID] ASC),
    CONSTRAINT [FK_products_ingredients] FOREIGN KEY ([ingredientID]) REFERENCES [ingredients]([ingredientID])
);
CREATE TABLE [dishes] (
    [dishID] int NOT NULL IDENTITY,
    [productID] int NOT NULL,
    [name] nvarchar(256) NOT NULL, 
    CONSTRAINT [PK_dishes] PRIMARY KEY CLUSTERED ([dishID] ASC),
    CONSTRAINT [FK_dishes_products] FOREIGN KEY ([productID]) REFERENCES [products]([productID])
);
CREATE TABLE [meals] (
    [mealID] int NOT NULL IDENTITY,
    [dishID] int NOT NULL,
    [name] nvarchar(256) NOT NULL,
    CONSTRAINT [PK_meals] PRIMARY KEY CLUSTERED ([mealID] ASC),
    CONSTRAINT [FK_meals_dishes] FOREIGN KEY ([dishID]) REFERENCES [dishes]([dishID])
);
CREATE TABLE [sets] (
    [setID] int NOT NULL IDENTITY,
    [mealID] int NOT NULL,
    [name] nvarchar(256) NOT NULL,
    CONSTRAINT [PK_sets] PRIMARY KEY CLUSTERED ([setID] ASC),
    CONSTRAINT [FK_sets_meals] FOREIGN KEY ([mealID]) REFERENCES [meals]([mealID])
);
CREATE TABLE [clients] (
    [clientID] int NOT NULL IDENTITY,
    [name] nvarchar(256) NOT NULL,
    [address] nvarchar(256) NOT NULL,
    [phone] nvarchar(256) NOT NULL,
    [email] nvarchar(256) NOT NULL,
    CONSTRAINT [PK_clients] PRIMARY KEY CLUSTERED ([clientID] ASC)
);
CREATE TABLE [orders] (
    [orderID] int NOT NULL IDENTITY,
    [clientID] int NOT NULL,
    [orderdate] datetime NOT NULL,
    [deliverydate] datetime NOT NULL,
    [comments] nvarchar(max) NULL,
    CONSTRAINT [PK_orders] PRIMARY KEY CLUSTERED ([orderID] ASC),
    CONSTRAINT [FK_orders_clients] FOREIGN KEY ([clientID]) REFERENCES [clients]([clientID])
);
CREATE TABLE [orderlines] (
    [orderlineID] int NOT NULL IDENTITY,
    [orderID] int NOT NULL,
    [setID] int NOT NULL,
    [quantity] int NOT NULL,
    CONSTRAINT [PK_orderlines] PRIMARY KEY CLUSTERED ([orderlineID] ASC),
    CONSTRAINT [FK_orderlines_orders] FOREIGN KEY ([orderID]) REFERENCES [orders]([orderID]),
    CONSTRAINT [FK_orderlines_sets] FOREIGN KEY ([setID]) REFERENCES [sets]([setID])
);
GO

-- 4
CREATE NONCLUSTERED INDEX [IX_orders_clients] ON [orders] ([clientID] ASC);
CREATE NONCLUSTERED INDEX [IX_orders_orderdate] ON [orders] ([orderdate] ASC) INCLUDE ([deliverydate]);
CREATE NONCLUSTERED INDEX [IX_orderlines_orders] ON [orderlines] ([orderID] ASC);
CREATE UNIQUE INDEX [IX_clients_name] ON [clients] ([name] ASC, [phone] ASC, [email] ASC);
GO

-- 5
ALTER TABLE [ingredients] ADD CONSTRAINT [CT_ingredients_name] UNIQUE ([name]);
ALTER TABLE [orders] ADD CONSTRAINT [CT_orders_orderdate] DEFAULT (GETUTCDATE()) FOR [orderdate];
ALTER TABLE [clients] ADD CONSTRAINT [CT_clients_email] CHECK (COALESCE(CHARINDEX('@',[email]),0) > 0);
