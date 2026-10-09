-- =====================================================================
-- 15 · Geleceğe dönük planlama 2: okul düzeyinde erken uyarı ve kaynak hedefleme
-- Slayt: "Planlama 2: erken uyarı ve 2029"
-- GEREKSİNİM: 06 dosyasındaki pisa.m_risk_2025 modeli.
-- PISA'da okul kimlikleri anonimdir: bu sorgu YÖNTEMİ gösterir. Aynı akış
-- ulusal verilerde (ör. ABİDE, LGS, e-Okul) gerçek okul listesi üretir.
-- Not: Model bu öğrencilerin %80'iyle eğitildi; okul sıralaması örneklem içidir.
-- =====================================================================

-- A) Tahmini riski en yüksek 15 okul
WITH tahmin AS (
  SELECT CNTSCHID, W_FSTUWT AS w,
    (SELECT prob FROM UNNEST(predicted_duzey2_alti_probs) WHERE label = 1) AS risk
  FROM ML.PREDICT(MODEL `pisa.m_risk_2025`,
    (SELECT CNTSCHID, W_FSTUWT, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet
     FROM `pisa.ogrenci`
     WHERE CNT = 'TUR' AND CYCLE = 2025))
),
okul AS (
  SELECT CNTSCHID, COUNT(*) AS ogrenci,
    SUM(w * risk) / SUM(w) AS risk,
    SUM(w * risk) AS riskli_ogrenci_tahmini
  FROM tahmin GROUP BY CNTSCHID
),
sirali AS (
  SELECT *,
    ROW_NUMBER() OVER (ORDER BY risk DESC) AS sira,
    COUNT(*) OVER () AS toplam_okul,
    SUM(riskli_ogrenci_tahmini) OVER (ORDER BY risk DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      / SUM(riskli_ogrenci_tahmini) OVER () AS kumulatif_pay
  FROM okul
)
SELECT sira, CNTSCHID AS okul_kimligi, ogrenci,
  ROUND(100 * risk, 1) AS tahmini_risk_yuzdesi
FROM sirali
ORDER BY sira
LIMIT 15;

-- B) Yoğunlaşma: risk altındaki öğrencilerin yarısı okulların yüzde kaçında?
WITH tahmin AS (
  SELECT CNTSCHID, W_FSTUWT AS w,
    (SELECT prob FROM UNNEST(predicted_duzey2_alti_probs) WHERE label = 1) AS risk
  FROM ML.PREDICT(MODEL `pisa.m_risk_2025`,
    (SELECT CNTSCHID, W_FSTUWT, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet
     FROM `pisa.ogrenci`
     WHERE CNT = 'TUR' AND CYCLE = 2025))
),
okul AS (
  SELECT CNTSCHID, COUNT(*) AS ogrenci,
    SUM(w * risk) / SUM(w) AS risk,
    SUM(w * risk) AS riskli_ogrenci_tahmini
  FROM tahmin GROUP BY CNTSCHID
),
sirali AS (
  SELECT *,
    ROW_NUMBER() OVER (ORDER BY risk DESC) AS sira,
    COUNT(*) OVER () AS toplam_okul,
    SUM(riskli_ogrenci_tahmini) OVER (ORDER BY risk DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      / SUM(riskli_ogrenci_tahmini) OVER () AS kumulatif_pay
  FROM okul
)
SELECT
  MIN(sira) AS okul_sayisi,
  ANY_VALUE(toplam_okul) AS toplam_okul,
  ROUND(100 * MIN(sira) / ANY_VALUE(toplam_okul), 1) AS okullarin_yuzdesi
FROM sirali
WHERE kumulatif_pay >= 0.5;
