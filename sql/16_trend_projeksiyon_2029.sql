-- =====================================================================
-- 16 · Geleceğe dönük planlama 3: Türkiye için 2029 senaryoları
-- Slayt: "Planlama 2: erken uyarı ve 2029"
-- Veri: MEB/OECD raporlarındaki Türkiye ortalamaları (2003–2025, 8 döngü).
-- Neden ARIMA / derin öğrenme değil? 8 noktalık, düzensiz aralıklı bir seri
-- karmaşık bir zaman serisi modeli için çok kısadır. Burada şeffaf bir doğrusal
-- eğilim ve iki basit senaryo kullanılır; ±2 artık standart sapması
-- belirsizliğin büyüklüğünü gösterir. Sonuç bir "hedef aralığı"dır, kehanet değildir.
-- =====================================================================
WITH rapor AS (
  SELECT * FROM UNNEST([
    STRUCT(2003 AS yil, 423 AS matematik, 441 AS okuma, 434 AS fen),
    STRUCT(2006, 424, 447, 424),
    STRUCT(2009, 445, 464, 454),
    STRUCT(2012, 448, 475, 463),
    STRUCT(2015, 420, 428, 425),
    STRUCT(2018, 454, 466, 468),
    STRUCT(2022, 453, 456, 476),
    STRUCT(2025, 462, 472, 494)
  ])
),
uzun AS (
  SELECT yil, alan, puan
  FROM rapor
  UNPIVOT (puan FOR alan IN (matematik, okuma, fen))
),
egilim AS (
  SELECT alan,
    COVAR_POP(yil, puan) / VAR_POP(yil) AS egim,
    AVG(puan) - COVAR_POP(yil, puan) / VAR_POP(yil) * AVG(yil) AS sabit,
    MAX(IF(yil = 2025, puan, NULL)) AS p2025,
    MAX(IF(yil = 2022, puan, NULL)) AS p2022
  FROM uzun GROUP BY alan
),
artik AS (
  SELECT alan, SQRT(SUM(POW(puan - (sabit + egim * yil), 2)) / (COUNT(*) - 2)) AS sd
  FROM uzun JOIN egilim USING (alan)
  GROUP BY alan
)
SELECT
  alan,
  ROUND(egim, 2)                          AS yillik_egim,
  p2025                                   AS puan_2025,
  p2025                                   AS s1_duzey_korunursa,
  ROUND(sabit + egim * 2029)              AS s2_uzun_donem_egilim,
  ROUND(2 * sd)                           AS s2_belirsizlik_arti_eksi,
  ROUND(p2025 + (p2025 - p2022) / 3 * 4)  AS s3_son_donem_hizi_surerse
FROM egilim JOIN artik USING (alan)
ORDER BY alan;
