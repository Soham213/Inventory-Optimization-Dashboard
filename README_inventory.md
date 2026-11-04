# Inventory Optimization Dashboard

I built this to answer the questions a warehouse planner deals with every week: what's about to run out, what should I reorder and how much, and which products are taking up shelf space without earning it.

![Stock Health page](screenshots/01_stock_health.png)

## What the dashboard shows

It has three pages, one per question:

- **Stock Health:** where inventory is overstocked and where there's a risk of running out.
- **Reorder Suggestions:** which products have hit their reorder point, and how much to order.
- **Fast vs Slow Movers:** which products sell quickly and which ones sit.

## The data

I used Microsoft's AdventureWorksDW2025 sample warehouse, restored locally on SQL Server Express and queried in SSMS.

Tables: `DimDate`, `DimProduct`, `DimProductCategory`, `DimProductSubcategory`, `FactInternetSales`, `FactProductInventory`.

I limited the project to the 158 products that appear in `FactInternetSales`. `DimProduct` has 606, but the rest were never sold or are only components, so there's nothing to forecast for them.

The raw data isn't in this repo. To reproduce the results, download the sample database from Microsoft and restore it.

## How I built it

1. **SQL.** Average daily sales over the last 90 days, a Fast / Medium / Slow classification using `NTILE(3)` on sales velocity, and a reorder point flag.
2. **Power BI model.** A star schema, a `_Measures` table with 9 DAX measures, and a Mover Category column on `DimProduct`.
3. **Dashboard.** Three pages with KPI cards, conditional formatting, and a mix of gauge, donut, stacked bar and scatter visuals.

## The reorder point

```
Reorder Point = Avg Daily Sales (last 90 days) x (Lead Time Days + 7-day safety buffer)
```

The dataset comes with a `SafetyStockLevel` field, but it didn't track real demand at all, so I left it out and based the formula on sales instead.

One caveat: the dataset has no real supplier lead times. Lead time is an assumed value, set in the `Assumed Lead Time Days` measure. With real supplier data, that's the first thing to replace.

## What I found

About 20% of the 158 products (stockout risk of 20.3%) are at or below their reorder point. I got the same result in SQL and in Power BI, which is how I checked the model.

## A data problem I left visible

`FactProductInventory` has some negative inventory balances, which shouldn't be possible. I could have filtered them or floored them at zero. I kept them in and added a note on the dashboard, since the people who own the source data need to know about it.

## DAX measures

Current Stock, Total Inventory Value, Negative Balance Flag Count, Total Units Sold, Avg Daily Sales 90d, Assumed Lead Time Days, Calculated Reorder Point, Stockout Risk %, Reorder Quantity Suggested.

Formulas are in [`dax/measures.md`](dax/measures.md).

## Repo layout

```
inventory-optimization-dashboard/
├── README.md
├── sql/                  # avg daily sales, mover classification, reorder flag
├── dax/measures.md       # the 9 measures and the Mover Category column
├── dashboard/            # Inventory_Dashboard.pdf (plus the .pbix if it's under 100 MB)
└── screenshots/          # one PNG per dashboard page
```

## Tools

SQL Server (T-SQL, SSMS), Power BI, DAX, Excel

## Author

Soham Patil · [LinkedIn](https://www.linkedin.com/in/soham-patil-dv/)
