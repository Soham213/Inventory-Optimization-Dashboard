USE AdventureWorksDW2025;
GO

WITH DateRange AS (
    SELECT 
        MIN(OrderDate) AS FirstOrderDate,
        MAX(OrderDate) AS AsOfDate,
        DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) + 1 AS TotalDaysInHistory
    FROM FactInternetSales
),
HistoricalSales AS (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalUnitsSold_AllTime
    FROM FactInternetSales
    GROUP BY ProductKey
),
Last90DaySales AS (
    SELECT fis.ProductKey, SUM(fis.OrderQuantity) AS UnitsSold_Last90Days
    FROM FactInternetSales fis
    CROSS JOIN DateRange d
    WHERE fis.OrderDate > DATEADD(DAY, -90, d.AsOfDate)
    GROUP BY fis.ProductKey
)
SELECT
    p.ProductKey,
    p.EnglishProductName,
    h.TotalUnitsSold_AllTime,
    ROUND(h.TotalUnitsSold_AllTime * 1.0 / d.TotalDaysInHistory, 3) AS AvgDailySales_FullHistory,
    ISNULL(l90.UnitsSold_Last90Days, 0) AS UnitsSold_Last90Days,
    ROUND(ISNULL(l90.UnitsSold_Last90Days, 0) * 1.0 / 90, 3) AS AvgDailySales_Last90Days
FROM DimProduct p
INNER JOIN HistoricalSales h ON p.ProductKey = h.ProductKey   -- inner join naturally scopes us to the 158 sold products
CROSS JOIN DateRange d
LEFT JOIN Last90DaySales l90 ON p.ProductKey = l90.ProductKey
ORDER BY AvgDailySales_FullHistory DESC;