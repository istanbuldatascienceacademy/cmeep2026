-- =====================================================================
-- 06 · BigQuery ML: matematikte Düzey 2 altında kalma riski
-- Slayt: "Düzey 2 altında kalma riskini tahmin" + "Model ne kadar iyi?"
-- ÖNEMLİ: Modelleri DEMODAN ÖNCE eğitin (ağaç modeli birkaç dakika sürer).
--         Demoda yalnızca C, D, E bölümlerini çalıştırın.
-- Etiket: PV1MATH < 420,07 (OECD Düzey 2 alt sınırı). Puan özellik olarak girmez.
-- Bölme: öğrenci kimliğinin özetiyle sabit %20 test → iki model aynı testte.
-- Sınırlılık: BigQuery ML bu modellerde örneklem ağırlığı kullanmaz;
--             sonuçlar keşifseldir, nüfus kestirimi değildir.
-- Veri: PISA 2025, Türkiye.
-- Özellik listesi (ESCS … cinsiyet) 2025 dosyasında aynı adlarla olmalı:
-- defterin 4. hücresinde "EKSİK" çıkan değişkeni 06, 07, 14, 15'ten silin
-- ya da 2025'teki karşılığıyla değiştirin.
-- =====================================================================

-- A) Yorumlanabilir taban model: lojistik regresyon  (~1 dk)
CREATE OR REPLACE MODEL `pisa.m_risk_lojistik`
OPTIONS (
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['duzey2_alti'],
  data_split_method = 'CUSTOM',
  data_split_col = 'test_mi',
  enable_global_explain = TRUE
) AS
SELECT
  IF(PV1MATH < 420.07, 1, 0) AS duzey2_alti,
  ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet,
  MOD(ABS(FARM_FINGERPRINT(CAST(CNTSTUID AS STRING))), 5) = 0 AS test_mi
FROM `pisa.ogrenci`
WHERE CNT = 'TUR' AND CYCLE = 2025;

-- B) Gradyan artırmalı ağaç  (~3–5 dk)
CREATE OR REPLACE MODEL `pisa.m_risk_2025`
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
WHERE CNT = 'TUR' AND CYCLE = 2025;

-- C) İki modeli aynı test kümesinde karşılaştır
SELECT 'lojistik' AS model, precision, recall, f1_score, roc_auc
FROM ML.EVALUATE(MODEL `pisa.m_risk_lojistik`)
UNION ALL
SELECT 'boosted_tree', precision, recall, f1_score, roc_auc
FROM ML.EVALUATE(MODEL `pisa.m_risk_2025`);

-- D) Genel değişken önemi
SELECT * FROM ML.GLOBAL_EXPLAIN(MODEL `pisa.m_risk_2025`)
ORDER BY attribution DESC;

-- E) Öğrenci düzeyinde açıklama (5 örnek öğrenci)
SELECT *
FROM ML.EXPLAIN_PREDICT(
  MODEL `pisa.m_risk_2025`,
  (SELECT CNTSTUID, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet
   FROM `pisa.ogrenci`
   WHERE CNT = 'TUR' AND CYCLE = 2025
   LIMIT 5),
  STRUCT(3 AS top_k_features));
