WITH DateRange AS (
    SELECT MAX(OrderDate) AS AsOfDate FROM FactInternetSales
),
Last90DaySales AS (
    SELECT fis.ProductKey, SUM(fis.OrderQuantity) AS UnitsSold_Last90Days
    FROM FactInternetSales fis
    CROSS JOIN DateRange d
    WHERE fis.OrderDate > DATEADD(DAY, -90, d.AsOfDate)
    GROUP BY fis.ProductKey
),
LatestInventory AS (
    SELECT fpi.ProductKey, fpi.UnitsBalance AS CurrentStock
    FROM FactProductInventory fpi
    INNER JOIN (
        SELECT ProductKey, MAX(MovementDate) AS MaxDate
        FROM FactProductInventory
        GROUP BY ProductKey
    ) latest ON fpi.ProductKey = latest.ProductKey AND fpi.MovementDate = latest.MaxDate
),
SoldProducts AS (
    SELECT DISTINCT ProductKey FROM FactInternetSales
)
SELECT
    p.ProductKey,
    p.EnglishProductName,
    ROUND(ISNULL(l90.UnitsSold_Last90Days, 0) * 1.0 / 90, 2) AS AvgDailySales,
    CASE WHEN p.DaysToManufacture = 0 THEN 7 ELSE p.DaysToManufacture END AS AssumedLeadTimeDays,
    7 AS SafetyBufferDays,  -- documented assumption: hold 7 extra days of avg demand as buffer
    li.CurrentStock,
    p.SafetyStockLevel AS Reference_SafetyStockLevel,   -- kept for comparison only, not used in the flag
    p.ReorderPoint AS Reference_SourceReorderPoint,      -- kept for comparison only, not used in the flag
    ROUND(
        (ISNULL(l90.UnitsSold_Last90Days, 0) * 1.0 / 90)
        * ((CASE WHEN p.DaysToManufacture = 0 THEN 7 ELSE p.DaysToManufacture END) + 7)
        , 0) AS CalculatedReorderPoint,
    CASE 
        WHEN li.CurrentStock <= ROUND(
                (ISNULL(l90.UnitsSold_Last90Days, 0) * 1.0 / 90)
                * ((CASE WHEN p.DaysToManufacture = 0 THEN 7 ELSE p.DaysToManufacture END) + 7)
            , 0)
        THEN 'REORDER NOW' 
        ELSE 'OK' 
    END AS ReorderFlag,
    CASE WHEN li.CurrentStock < 0 THEN 'Data Quality: Negative Balance' ELSE NULL END AS DataQualityNote
FROM DimProduct p
INNER JOIN SoldProducts sp ON p.ProductKey = sp.ProductKey
LEFT JOIN Last90DaySales l90 ON p.ProductKey = l90.ProductKey
LEFT JOIN LatestInventory li ON p.ProductKey = li.ProductKey
ORDER BY ReorderFlag DESC, AvgDailySales DESC;