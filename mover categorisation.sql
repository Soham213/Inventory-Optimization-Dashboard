WITH DateRange AS (
    SELECT DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) + 1 AS TotalDaysInHistory
    FROM FactInternetSales
),
HistoricalSales AS (
    SELECT ProductKey, SUM(OrderQuantity) AS TotalUnitsSold
    FROM FactInternetSales
    GROUP BY ProductKey
),
Velocity AS (
    SELECT
        h.ProductKey,
        h.TotalUnitsSold,
        ROUND(h.TotalUnitsSold * 1.0 / d.TotalDaysInHistory, 3) AS AvgDailySales
    FROM HistoricalSales h
    CROSS JOIN DateRange d
),
Ranked AS (
    SELECT *, NTILE(3) OVER (ORDER BY AvgDailySales DESC) AS VelocityTile
    FROM Velocity
)
SELECT
    p.ProductKey,
    p.EnglishProductName,
    dsc.EnglishProductSubcategoryName,
    r.TotalUnitsSold,
    r.AvgDailySales,
    CASE r.VelocityTile
        WHEN 1 THEN 'Fast Mover'
        WHEN 2 THEN 'Medium Mover'
        WHEN 3 THEN 'Slow Mover'
    END AS MoverCategory
FROM Ranked r
INNER JOIN DimProduct p ON r.ProductKey = p.ProductKey
LEFT JOIN DimProductSubcategory dsc ON p.ProductSubcategoryKey = dsc.ProductSubcategoryKey
ORDER BY r.AvgDailySales DESC;