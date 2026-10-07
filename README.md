# CMS Medicare Health Equity Analysis

County-level look at whether lower-income Medicare populations use the ER more than their health needs would predict, using the CMS Medicare Fee-for-Service Geographic Variation file (2023).

## Question

Is a county's dual eligibility rate linked to higher ER use, beyond what its average health risk explains? And which counties rank highest when poverty and health risk are combined?

## Data

- **Source:** CMS Medicare Fee-for-Service Geographic Variation Public Use File, 2014 to 2023 (data.cms.gov). I use the 2023 county rows: 3,198 counties.
- **Fee-for-service only.** Medicare Advantage enrollees are not in this file. In some counties they are more than half of all beneficiaries, so results describe the FFS population, not all of Medicare.
- **Suppressed values.** CMS replaces values based on fewer than 11 beneficiaries with `*`. I converted these to missing and dropped them per analysis (90 counties, about 3%, were dropped from the regression). This is not random: it mostly affects small rural counties, so those counties are under-represented.

## Key measures

| Measure | Column | Used as |
|---|---|---|
| Dual eligibility rate | `BENE_DUAL_PCT` | Proxy for low income among Medicare beneficiaries |
| Average risk score (CMS-HCC) | `BENE_AVG_RISK_SCRE` | Proxy for health need (predicted cost, 1.0 = average) |
| ER visits per 1,000 beneficiaries | `ER_VISITS_PER_1000_BENES` | ER intensity |
| Share with at least one ER visit | `BENES_ER_VISITS_PCT` | ER reach |
| Standardized spending per beneficiary | `TOT_MDCR_STDZD_PYMT_PC` | Spending with regional price differences removed |
| Medicare Advantage participation rate | `MA_PRTCPTN_RATE` | Control variable in the regression |
| FFS beneficiary count | `BENES_FFS_CNT` | Regression weight and minimum county size |

Why dual eligibility instead of county median income: it describes the Medicare beneficiaries themselves (not all county residents) and comes from the same file.

Known limits of these proxies: dual eligibility also includes beneficiaries under 65 with disabilities, Medicaid rules differ by state, and duals enrolled in Medicare Advantage plans are not in this file. The CMS-HCC risk score uses Medicaid status as one of its inputs, so it is not fully independent of dual eligibility.

## Method

1. Filtered to 2023 county rows and converted suppressed values to missing.
2. Split counties into four equal-size groups by dual eligibility rate and compared group averages, both as percent differences and in standard deviations (descriptive).
3. Ran weighted least squares regressions of ER visits per 1,000 on dual eligibility rate, adding risk score and then Medicare Advantage rate. Counties are weighted by FFS beneficiary count, with robust standard errors because small counties have noisier rates.
4. Built a composite need score: min-max normalized dual eligibility rate plus min-max normalized risk score (0 to 2, equal weights), limited to counties with at least 500 FFS beneficiaries.
5. Built a Power BI dashboard of the need score and ER use.

## Results

**1. ER use is higher in high-dual counties.** Counties in the highest dual eligibility quartile have about 26% more ER visits per 1,000 than the lowest quartile. Their average risk score is about 11% higher. Measured in standard deviations, the gaps are closer than the percentages suggest: about 1.25 for ER visits versus about 1.0 for risk score.

**2. The link holds after accounting for health need, but it is modest.**

| Model | ER visits per 1,000 per 10-point higher dual rate | 95% CI | R² |
|---|---|---|---|
| Dual rate only | 31 | 14 to 49 | 0.11 |
| + risk score | 20 | 4 to 37 | 0.16 |
| + risk score + Medicare Advantage rate | 20 | 4 to 37 | 0.16 |

Among counties with the same risk score and Medicare Advantage rate, each 10-point higher dual eligibility rate is associated with about 20 more ER visits per 1,000, roughly 3.5% of the average county's ER use (about 584 visits per 1,000, weighted). Accounting for risk score reduces the raw link by about a third. The confidence interval is wide, and the model explains only about 16% of the variation in ER use, so most of what drives county ER use is outside this model. Medicare Advantage rate had no meaningful relationship and did not change the result.

**Robustness.** Dropping the 17 Alaska counties leaves the estimate unchanged (about 21). Without weighting, the estimate is larger (about 45), because small counties have noisier and more extreme rates, so the weighted estimate of about 20 is the conservative one.

**3. More ER users and more visits per user.** The share of beneficiaries with any ER visit is about 12% higher in the highest quartile, and visits per ER user rise steadily across quartiles, from about 1.9 to 2.1 (about 13% higher). The extra ER use comes roughly equally from more people using the ER and from more visits per user.

**4. Need score ranking.** The top 20 counties by need score are listed in `sql/equity_analysis_queries.sql` (Query 1). Without a size threshold, small counties dominate the top of the ranking (median of about 890 FFS beneficiaries, compared with about 3,070 for all counties). After requiring at least 500 FFS beneficiaries, 16 of the original top 20 remain. The ranking is relative to other U.S. counties in 2023, not an absolute measure of need.

## Limitations

- County-level associations only. These results describe counties, not individual beneficiaries.
- Risk score partly includes Medicaid status, so poverty is partly counted twice in the need score, and the two regression predictors overlap.
- Risk scores depend on diagnoses being recorded. Where people see doctors less, risk scores likely understate need.
- The regression errors are skewed by a few extreme counties, mostly in Alaska, with far fewer ER visits than predicted. Robust standard errors are used, and removing Alaska does not change the result, but these counties deserve a closer look.
- One year (2023). I have not yet checked whether the pattern holds across 2014 to 2023.
- Care outside Medicare FFS (Medicare Advantage, VA, Indian Health Service and tribal health programs) is not visible in this file.

## Open questions

Some counties on the dashboard show a high need score but relatively low ER use. These could be access gaps, but low use in FFS data can also mean care is happening outside the file (for example through tribal health systems or Medicare Advantage). Testing this would need a defined threshold and outside data such as primary care physicians per capita and rural-urban codes.

## Repository

```
README.md
cms_equity_dashboard.pbix     Power BI dashboard
data/raw/                     CMS file (zipped CSV, also available from data.cms.gov)
docs/                         CMS data dictionary and methods paper
notebooks/01_data_exploration.ipynb   cleaning, quartiles, regression, robustness checks
notebooks/02_sql_analysis.ipynb       runs the SQL queries against a SQLite table
sql/equity_analysis_queries.sql       need score, ER visits per user, high ER counties
visuals/                      charts and dashboard screenshot
```

## How to reproduce

1. Run `notebooks/01_data_exploration.ipynb`. It reads the zipped CSV in `data/raw/` directly.
2. Run `notebooks/02_sql_analysis.ipynb` to load the `cms_county` table and run the queries in `sql/equity_analysis_queries.sql`.
3. Open `cms_equity_dashboard.pbix` in Power BI Desktop.

## Tools

Python (pandas, statsmodels, matplotlib, seaborn), SQL (SQLite, CTEs, window functions), Power BI.
