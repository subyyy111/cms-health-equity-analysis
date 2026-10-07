-- =====================================================================
-- CMS Medicare Health Equity Analysis: SQL queries (revised)
-- Table: cms_county (2023 county rows from the CMS Geographic Variation PUF)
-- Note: numeric columns are stored as TEXT and CMS suppressed values appear
-- as '*'. Every query filters '*' out BEFORE casting, because SQLite turns
-- CAST('*' AS REAL) into 0.0, which silently distorts averages and minimums.
-- =====================================================================


-- Query 1: Composite need score, top 20 counties
-- Need score = min-max normalized dual eligibility rate + min-max normalized
-- average risk score (range 0 to 2, equal weights).
-- Fixes vs. original version:
--   * min/max are computed only on unsuppressed rows (previously '*' rows
--     were cast to 0, which pulled the risk score minimum down to 0)
--   * counties below a minimum FFS beneficiary count are excluded, so tiny
--     counties with noisy rates do not dominate the ranking
--     (requires BENES_FFS_CNT in the table. Try 500 and 1000 and compare.)
WITH base AS (
    SELECT
        BENE_GEO_DESC,
        CAST(BENE_DUAL_PCT AS REAL)       AS dual_pct,
        CAST(BENE_AVG_RISK_SCRE AS REAL)  AS risk_score,
        CASE WHEN ER_VISITS_PER_1000_BENES = '*' THEN NULL
             ELSE CAST(ER_VISITS_PER_1000_BENES AS REAL) END AS er_visits,
        CASE WHEN TOT_MDCR_STDZD_PYMT_PC = '*' THEN NULL
             ELSE CAST(TOT_MDCR_STDZD_PYMT_PC AS REAL) END   AS total_spending,
        CAST(BENES_FFS_CNT AS REAL)       AS ffs_benes
    FROM cms_county
    WHERE BENE_DUAL_PCT != '*'
      AND BENE_AVG_RISK_SCRE != '*'
      AND BENES_FFS_CNT != '*'
      AND CAST(BENES_FFS_CNT AS REAL) >= 500
),
min_max AS (
    SELECT
        MIN(dual_pct)   AS dual_min,  MAX(dual_pct)   AS dual_max,
        MIN(risk_score) AS risk_min,  MAX(risk_score) AS risk_max
    FROM base
)
SELECT
    b.BENE_GEO_DESC,
    CAST(b.ffs_benes AS INTEGER)      AS ffs_beneficiaries,
    ROUND(b.dual_pct, 4)              AS dual_eligibility_rate,
    ROUND(b.risk_score, 2)            AS avg_risk_score,
    ROUND(b.er_visits, 0)             AS er_visits_per_1000,
    ROUND(b.total_spending, 2)        AS std_spending_per_capita,
    ROUND((b.dual_pct - m.dual_min) / (m.dual_max - m.dual_min)
        + (b.risk_score - m.risk_min) / (m.risk_max - m.risk_min), 4) AS need_score
FROM base b
CROSS JOIN min_max m
ORDER BY need_score DESC
LIMIT 20;


-- Query 2: ER visits per ER user, by dual eligibility quartile
-- Visits per user = ER visits per 1,000 / (share with any ER visit x 1,000).
-- Tests whether higher ER volume in high-dual counties comes from more people
-- using the ER or from more visits per person who uses it.
-- County-level data: this describes counties, not individual patients.
WITH base AS (
    SELECT
        CAST(BENE_DUAL_PCT AS REAL)            AS dual_pct,
        CAST(ER_VISITS_PER_1000_BENES AS REAL) AS er_visits,
        CAST(BENES_ER_VISITS_PCT AS REAL)      AS er_user_share
    FROM cms_county
    WHERE BENE_DUAL_PCT != '*'
      AND ER_VISITS_PER_1000_BENES != '*'
      AND BENES_ER_VISITS_PCT != '*'
      AND CAST(BENES_ER_VISITS_PCT AS REAL) > 0
),
quartiled AS (
    SELECT *, NTILE(4) OVER (ORDER BY dual_pct) AS dual_quartile
    FROM base
)
SELECT
    dual_quartile,
    COUNT(*)                                  AS counties,
    ROUND(MIN(dual_pct), 3)                   AS min_dual_rate,
    ROUND(MAX(dual_pct), 3)                   AS max_dual_rate,
    ROUND(AVG(er_visits), 1)                  AS avg_er_visits_per_1000,
    ROUND(AVG(er_user_share), 3)              AS avg_share_with_er_visit,
    ROUND(AVG(er_visits / (er_user_share * 1000)), 2) AS avg_visits_per_er_user
FROM quartiled
GROUP BY dual_quartile
ORDER BY dual_quartile;


-- Query 3: High ER intensity county profiles (exploratory)
-- Counties with above-average ER visits per 1,000, with their other measures.
-- Fix vs. original: suppressed rows are excluded before the average is taken,
-- so '*' values no longer count as zeros and lower the cutoff.
WITH base AS (
    SELECT
        BENE_GEO_DESC,
        CAST(ER_VISITS_PER_1000_BENES AS REAL) AS er_visits,
        CASE WHEN BENE_DUAL_PCT = '*' THEN NULL ELSE CAST(BENE_DUAL_PCT AS REAL) END AS dual_pct,
        CASE WHEN BENE_AVG_RISK_SCRE = '*' THEN NULL ELSE CAST(BENE_AVG_RISK_SCRE AS REAL) END AS risk_score,
        CASE WHEN TOT_MDCR_STDZD_PYMT_PC = '*' THEN NULL ELSE CAST(TOT_MDCR_STDZD_PYMT_PC AS REAL) END AS total_spending,
        CASE WHEN ACUTE_HOSP_READMSN_PCT = '*' THEN NULL ELSE CAST(ACUTE_HOSP_READMSN_PCT AS REAL) END AS readmission_rate,
        CAST(BENES_FFS_CNT AS REAL) AS ffs_benes
    FROM cms_county
    WHERE ER_VISITS_PER_1000_BENES != '*'
      AND BENES_FFS_CNT != '*'
)
SELECT
    BENE_GEO_DESC,
    CAST(ffs_benes AS INTEGER)   AS ffs_beneficiaries,
    ROUND(er_visits, 0)          AS er_visits_per_1000,
    ROUND(dual_pct, 4)           AS dual_eligibility_rate,
    ROUND(risk_score, 2)         AS avg_risk_score,
    ROUND(total_spending, 2)     AS std_spending_per_capita,
    ROUND(readmission_rate, 4)   AS readmission_rate
FROM base
WHERE er_visits > (SELECT AVG(er_visits) FROM base)
  AND ffs_benes >= 500
ORDER BY er_visits DESC
LIMIT 20;

-- Removed: the original "high spending, low dual eligibility" query.
-- It compared TEXT columns to numeric averages (alphabetical comparison),
-- and the finding it supported (elective care in wealthier counties) had no
-- supporting analysis, so both were cut from the project.
