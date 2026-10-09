-- =====================================================================
-- 14 · Geleceğe dönük planlama 1: "Ne olurdu?" senaryo simülasyonu
-- Slayt: "Planlama 1: senaryo simülasyonu"
-- GEREKSİNİM: 06 dosyasındaki pisa.m_risk_2025 modeli.
-- Ne yapar: Öğrencilerin özelliklerini bir senaryoya göre değiştirir, modelle
--   Düzey 2 altında kalma olasılığını yeniden tahmin eder ve nüfusa
--   (ağırlıklarla) genelleştirir.
-- UYARI: Bu bir NEDENSEL etki tahmini değildir. Model ilişkileri öğrenir;
--   senaryolar "bu ilişkiler sabit kalırsa" sorusunu yanıtlar. Politika
--   kararı için deneysel/yarı deneysel kanıtla birlikte kullanın.
-- =====================================================================
WITH taban AS (
  SELECT W_FSTUWT, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT,
    CAST(CAST(ST004D01T AS INT64) AS STRING) AS cinsiyet
  FROM `pisa.ogrenci`
  WHERE CNT = 'TUR' AND CYCLE = 2025
),
senaryolar AS (
  SELECT '0 Mevcut durum' AS senaryo, W_FSTUWT, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, REPEAT, cinsiyet FROM taban
  UNION ALL
  SELECT '1 Okul aidiyeti +0,5 SS', W_FSTUWT, ESCS, HOMEPOS, BELONG + 0.5, ANXMAT, MATHEFF, REPEAT, cinsiyet FROM taban
  UNION ALL
  SELECT '2 Matematik kaygısı −0,5 SS', W_FSTUWT, ESCS, HOMEPOS, BELONG, ANXMAT - 0.5, MATHEFF, REPEAT, cinsiyet FROM taban
  UNION ALL
  SELECT '3 Matematik öz-yeterliği +0,5 SS', W_FSTUWT, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF + 0.5, REPEAT, cinsiyet FROM taban
  UNION ALL
  SELECT '4 Sınıf tekrarı olmasaydı', W_FSTUWT, ESCS, HOMEPOS, BELONG, ANXMAT, MATHEFF, 0, cinsiyet FROM taban
  UNION ALL
  SELECT '5 Dezavantajlı öğrencilere destek (ESCS < −1 için +0,5)', W_FSTUWT,
    IF(ESCS < -1, ESCS + 0.5, ESCS), IF(ESCS < -1, HOMEPOS + 0.5, HOMEPOS),
    BELONG, ANXMAT, MATHEFF, REPEAT, cinsiyet FROM taban
  UNION ALL
  SELECT '6 Birleşik paket (1 + 2 + 3)', W_FSTUWT, ESCS, HOMEPOS, BELONG + 0.5, ANXMAT - 0.5, MATHEFF + 0.5, REPEAT, cinsiyet FROM taban
),
tahmin AS (
  SELECT senaryo, W_FSTUWT,
    (SELECT prob FROM UNNEST(predicted_duzey2_alti_probs) WHERE label = 1) AS risk
  FROM ML.PREDICT(MODEL `pisa.m_risk_2025`, (SELECT * FROM senaryolar))
),
ozet AS (
  SELECT senaryo, 100 * SUM(W_FSTUWT * risk) / SUM(W_FSTUWT) AS risk_yuzde
  FROM tahmin GROUP BY senaryo
)
SELECT
  senaryo,
  ROUND(risk_yuzde, 1) AS duzey2_alti_tahmini_yuzde,
  ROUND(risk_yuzde - MAX(IF(senaryo = '0 Mevcut durum', risk_yuzde, NULL)) OVER (), 1) AS mevcuda_gore_puan
FROM ozet
ORDER BY senaryo;
