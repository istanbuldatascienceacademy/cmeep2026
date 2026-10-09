-- =====================================================================
-- 08 · K-ortalamalar ile öğrenci profilleri (Türkiye)
-- Slayt: "K-ortalamalar ile öğrenci profilleri"
-- A) bölümünü DEMODAN ÖNCE çalıştırın (~2 dk).
-- Küme sayısını seçmek için num_clusters = 3, 4, 5 deneyip
-- C) bölümündeki davies_bouldin_index'e bakın (küçük = daha iyi).
-- =====================================================================

-- A) Model
CREATE OR REPLACE MODEL `pisa.m_profil_2025`
OPTIONS (
  model_type = 'KMEANS',
  num_clusters = 4,
  kmeans_init_method = 'KMEANS++',
  standardize_features = TRUE
) AS
SELECT ESCS, BELONG, ANXMAT, MATHEFF
FROM `pisa.ogrenci`
WHERE CNT = 'TUR' AND CYCLE = 2025;

-- B) Profil merkezleri: her profilin ortalama özellikleri
SELECT *
FROM (
  SELECT centroid_id AS profil, feature, ROUND(numerical_value, 2) AS deger
  FROM ML.CENTROIDS(MODEL `pisa.m_profil_2025`)
)
PIVOT (ANY_VALUE(deger) FOR feature IN ('ESCS', 'BELONG', 'ANXMAT', 'MATHEFF'))
ORDER BY profil;

-- C) Kümeleme kalitesi
SELECT * FROM ML.EVALUATE(MODEL `pisa.m_profil_2025`);

-- D) Profillerin matematik başarısı (10 PV, ağırlıklı) ve nüfustaki payı
WITH atama AS (
  SELECT CENTROID_ID AS profil, W_FSTUWT AS w,
    PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
    PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH
  FROM ML.PREDICT(
    MODEL `pisa.m_profil_2025`,
    (SELECT ESCS, BELONG, ANXMAT, MATHEFF, W_FSTUWT,
       PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
       PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH
     FROM `pisa.ogrenci`
     WHERE CNT = 'TUR' AND CYCLE = 2025))
),
uzun AS (
  SELECT * FROM atama
  UNPIVOT (puan FOR pv_no IN (
    PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
    PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH))
),
pv_ort AS (
  SELECT profil, pv_no, SUM(w * puan) / SUM(w) AS ort, SUM(w) AS agirlik
  FROM uzun
  GROUP BY profil, pv_no
)
SELECT
  profil,
  ROUND(AVG(ort), 1) AS matematik,
  ROUND(100 * AVG(agirlik) / SUM(AVG(agirlik)) OVER (), 1) AS ogrenci_yuzdesi
FROM pv_ort
GROUP BY profil
ORDER BY matematik DESC;
