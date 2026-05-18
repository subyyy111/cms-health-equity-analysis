
-- Query 1: Composite Need Score - Top 20 Highest Need Counties
WITH min_max AS (
    SELECT 
        MIN(CAST(BENE_DUAL_PCT AS FLOAT)) as dual_min,
        MAX(CAST(BENE_DUAL_PCT AS FLOAT)) as dual_max,
        MIN(CAST(BENE_AVG_RISK_SCRE AS FLOAT)) as risk_min,
        MAX(CAST(BENE_AVG_RISK_SCRE AS FLOAT)) as risk_max
    FROM cms_county
),
normalized AS (
    SELECT
        c.BENE_GEO_DESC,
        CAST(c.BENE_DUAL_PCT AS FLOAT) as dual_pct,
        CAST(c.BENE_AVG_RISK_SCRE AS FLOAT) as risk_score,
        CAST(c.ER_VISITS_PER_1000_BENES AS FLOAT) as er_visits,
        CAST(c.TOT_MDCR_STDZD_PYMT_PC AS FLOAT) as total_spending,
        CAST(c.ACUTE_HOSP_READMSN_PCT AS FLOAT) as readmission_pct,
        (CAST(c.BENE_DUAL_PCT AS FLOAT) - m.dual_min) / 
            (m.dual_max - m.dual_min) as dual_normalized,
        (CAST(c.BENE_AVG_RISK_SCRE AS FLOAT) - m.risk_min) / 
            (m.risk_max - m.risk_min) as risk_normalized
    FROM cms_county c, min_max m
    WHERE c.BENE_DUAL_PCT != '*'
    AND c.BENE_AVG_RISK_SCRE != '*'
)
SELECT
    BENE_GEO_DESC,
    ROUND(dual_pct, 4) as dual_eligibility,
    ROUND(risk_score, 2) as risk_score,
    ROUND(er_visits, 0) as er_visits_per_1000,
    ROUND(total_spending, 2) as total_spending_pc,
    ROUND(readmission_pct, 4) as readmission_rate,
    ROUND(dual_normalized + risk_normalized, 4) as need_score
FROM normalized
ORDER BY need_score DESC
LIMIT 20;

-- Query 2: High Spending, Low Dual Eligibility Counties
SELECT 
    BENE_GEO_DESC, 
    BENE_DUAL_PCT, 
    ER_VISITS_PER_1000_BENES, 
    TOT_MDCR_STDZD_PYMT_PC,
    BENE_AVG_RISK_SCRE, 
    ACUTE_HOSP_READMSN_PCT
FROM cms_county
WHERE
    TOT_MDCR_STDZD_PYMT_PC > (SELECT AVG(CAST(TOT_MDCR_STDZD_PYMT_PC AS FLOAT)) FROM cms_county) 
    AND
    BENE_DUAL_PCT < (SELECT AVG(CAST(BENE_DUAL_PCT AS FLOAT)) FROM cms_county)
ORDER BY TOT_MDCR_STDZD_PYMT_PC DESC
LIMIT 20;

-- Query 3: High ER Intensity County Profiles
SELECT 
    BENE_GEO_DESC,
    BENE_DUAL_PCT,
    CAST(ER_VISITS_PER_1000_BENES AS FLOAT) as er_visits_per_1000,
    TOT_MDCR_STDZD_PYMT_PC,
    BENE_AVG_RISK_SCRE,
    ACUTE_HOSP_READMSN_PCT
FROM cms_county
WHERE CAST(ER_VISITS_PER_1000_BENES AS FLOAT) > (
    SELECT AVG(CAST(ER_VISITS_PER_1000_BENES AS FLOAT)) 
    FROM cms_county
)
ORDER BY CAST(ER_VISITS_PER_1000_BENES AS FLOAT) DESC
LIMIT 20;
