# cms-health-equity-analysis
# CMS Medicare Health Equity Analysis
**Analyzing county-level Medicare data to identify communities 
with barriers to preventive and outpatient care access**

## Business / Policy Question
Which U.S. counties face the greatest barriers to preventive 
and outpatient care access, and where should CMS direct 
infrastructure investment to reduce preventable 
hospitalizations and emergency care dependency?

## Background
Dual eligibility — enrollment in both Medicare and Medicaid 
simultaneously — requires meeting Medicaid's strict income 
and asset thresholds, making it a direct administrative 
proxy for poverty. This project uses dual eligibility rates 
alongside health risk scores to identify counties where 
economic vulnerability intersects with poor healthcare access.

## Data Sources
- **CMS Medicare Fee-for-Service Geographic Variation 
  Public Use File (2023)** — county-level spending, 
  utilization, and quality indicators for ~3,200 U.S. counties
- Source: data.cms.gov

## Methodology
1. Exploratory data analysis — summary statistics, 
   null analysis, distribution checks
2. Correlation analysis — identifying outcome variables 
   most strongly associated with dual eligibility
3. Quartile analysis — comparing outcome averages across 
   four dual eligibility groups
4. Composite need score — normalizing dual eligibility 
   and risk score to create a county-level intervention 
   priority ranking
5. SQL queries — profiling highest need counties, 
   identifying high spending profiles, and flagging 
   access desert communities
6. Power BI dashboard — interactive visualization for 
   policy decision makers

## Key Findings

### Finding 1 — ER as Primary Care Substitute
Counties in the highest dual eligibility quartile show 
24.9% higher ER visit intensity than the lowest quartile, 
while overall health burden increases only 12.2%. 
This disproportionate ER reliance suggests low-income 
Medicare populations are accessing care through emergency 
channels due to inadequate outpatient infrastructure.

### Finding 2 — Two Distinct High-Spending Profiles
High Medicare spending occurs for fundamentally different 
reasons across county types:
- **Wealthy counties** (low dual eligibility) — spending 
  driven by elective and specialty care, lower ER intensity. 
- **Impoverished counties** (high dual eligibility) — 
  spending driven by emergency and inpatient crisis care, 
  higher ER intensity
Same dollar amount, fundamentally different care quality 
and outcomes. The communities in wealthier counties are
influnced by the culture of prioritizing elective care.

### Finding 3 — Access Desert Communities
High need score counties with low utilization — primarily 
concentrated in rural Alaska and Native American reservation 
counties — represent communities where need is high but 
care is not being accessed. Two hypothesized barriers:
- **Infrastructure gap** — geographic isolation and lack 
  of facilities (particularly rural Alaska)
- **Systemic distrust** — historical trauma with federal 
  healthcare systems in Native American communities

## Intervention Framework
| Group | Profile | Recommended Intervention |
|-------|---------|--------------------------|
| S1 | High need, low utilization | Infrastructure investment, community-led care models |
| S2 | High need, high ER utilization | Outpatient facility expansion, preventive care awareness |

## Skills Demonstrated
- Python (pandas, matplotlib, seaborn)
- SQL (SQLite, CTEs, window functions, subqueries)
- Power BI (ArcGIS Maps, scatter plots, KPI cards)
- Exploratory data analysis
- Correlation and quartile analysis
- Health equity analytics
- Policy-facing data communication

## How to Reproduce
1. Download the CMS Geographic Variation PUF (2023) 
   from data.cms.gov
2. Place in `data/raw/`
3. Run `notebooks/01_data_exploration.ipynb`
4. Run `notebooks/02_sql_analysis.ipynb`
5. Open `cms_equity_dashboard.pbix` in Power BI Desktop
