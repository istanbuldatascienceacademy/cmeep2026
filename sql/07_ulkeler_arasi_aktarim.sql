-- =====================================================================
-- 07 · "Türkiye'de öğren, başka ülkelerde sına"  (06'daki m_risk_2025 gerekli)
-- Slayt: "Türkiye'de öğren, başka ülkelerde sına"
-- Soru: Türkiye'de başarı riskini belirleyen ilişkiler başka eğitim
--       sistemlerinde de geçerli mi? Karşılaştırma ülkelerini değiştirebilirsiniz.
-- A bölümünü DEMODAN ÖNCE çalıştırın (~3–5 dk).
-- =====================================================================

-- A) Aynı modeli karşılaştırma ülkesinde (Yunanistan) eğit
CREATE OR REPLACE MODEL `pisa.m_risk_grc`
OPTIONS (
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['duzey2_alti'],
  data_split_method = 'CUSTOM',
  data_split_col = 'test_mi',
  max_iterations = 50,
  enable_global_explain = TRUE
) AS
SELECT
  IF(PV1MATH < 420.07, 1, 0) AS duzey2_alti,
  ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet,
  MOD(ABS(FARM_FINGERPRINT(CAST(CNTSTUID AS STRING))), 5) = 0 AS test_mi
FROM `pisa.ogrenci`
WHERE CNT = 'GRC' AND CYCLE = 2025;

-- B) Türkiye modeli başka ülkelerde ne kadar iyi?
SELECT 'TUR modeli → TUR (test kümesi)' AS sinama, precision, recall, f1_score, roc_auc
FROM ML.EVALUATE(MODEL `pisa.m_risk_2025`)
UNION ALL
SELECT 'TUR modeli → GRC', precision, recall, f1_score, roc_auc
FROM ML.EVALUATE(MODEL `pisa.m_risk_2025`,
  (SELECT IF(PV1MATH < 420.07, 1, 0) AS duzey2_alti, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet
   FROM `pisa.ogrenci` WHERE CNT = 'GRC' AND CYCLE = 2025))
UNION ALL
SELECT 'TUR modeli → ITA', precision, recall, f1_score, roc_auc
FROM ML.EVALUATE(MODEL `pisa.m_risk_2025`,
  (SELECT IF(PV1MATH < 420.07, 1, 0) AS duzey2_alti, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet
   FROM `pisa.ogrenci` WHERE CNT = 'ITA' AND CYCLE = 2025))
UNION ALL
SELECT 'TUR modeli → ESP', precision, recall, f1_score, roc_auc
FROM ML.EVALUATE(MODEL `pisa.m_risk_2025`,
  (SELECT IF(PV1MATH < 420.07, 1, 0) AS duzey2_alti, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet
   FROM `pisa.ogrenci` WHERE CNT = 'ESP' AND CYCLE = 2025));

-- C) Başarı riskinin belirleyicileri aynı mı? Türkiye ve Yunanistan modelleri yan yana
SELECT feature,
  ROUND(MAX(IF(model = 'TUR', attribution, NULL)), 3) AS onem_turkiye,
  ROUND(MAX(IF(model = 'GRC', attribution, NULL)), 3) AS onem_yunanistan
FROM (
  SELECT 'TUR' AS model, feature, attribution FROM ML.GLOBAL_EXPLAIN(MODEL `pisa.m_risk_2025`)
  UNION ALL
  SELECT 'GRC', feature, attribution FROM ML.GLOBAL_EXPLAIN(MODEL `pisa.m_risk_grc`)
)
GROUP BY feature
ORDER BY onem_turkiye DESC;
