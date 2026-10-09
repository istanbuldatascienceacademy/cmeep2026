-- =====================================================================
-- 03 · Doğru standart hata: 10 PV × 81 ağırlık = ülke başına 810 tahmin
-- Slayt: "Ağırlıklar ve olası değerler: dört adım"
--   Örnekleme varyansı (Fay BRR, k = 0,5): U = (1/20) · Σ (θ_r − θ)²
--   Ölçme varyansı (PV'ler arası):        B = (1/9)  · Σ (θ_i − θ̄)²
--   Toplam: V = Ū + (1 + 1/10) · B     →  SH = √V
-- Matematik yerine fen için: PV…MATH → PV…SCIE
-- Daha hızlı demo için WHERE satırına ülke listesi ekleyin:
--   AND CNT IN ('TUR', 'GRC', 'DEU', 'JPN', 'SGP')
-- =====================================================================
WITH taban AS (
  SELECT
    CNT,
    [PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
     PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH] AS pvler,
    [W_FSTUWT, W_FSTURWT1, W_FSTURWT2, W_FSTURWT3, W_FSTURWT4, W_FSTURWT5, W_FSTURWT6, W_FSTURWT7,
     W_FSTURWT8, W_FSTURWT9, W_FSTURWT10, W_FSTURWT11, W_FSTURWT12, W_FSTURWT13, W_FSTURWT14, W_FSTURWT15,
     W_FSTURWT16, W_FSTURWT17, W_FSTURWT18, W_FSTURWT19, W_FSTURWT20, W_FSTURWT21, W_FSTURWT22, W_FSTURWT23,
     W_FSTURWT24, W_FSTURWT25, W_FSTURWT26, W_FSTURWT27, W_FSTURWT28, W_FSTURWT29, W_FSTURWT30, W_FSTURWT31,
     W_FSTURWT32, W_FSTURWT33, W_FSTURWT34, W_FSTURWT35, W_FSTURWT36, W_FSTURWT37, W_FSTURWT38, W_FSTURWT39,
     W_FSTURWT40, W_FSTURWT41, W_FSTURWT42, W_FSTURWT43, W_FSTURWT44, W_FSTURWT45, W_FSTURWT46, W_FSTURWT47,
     W_FSTURWT48, W_FSTURWT49, W_FSTURWT50, W_FSTURWT51, W_FSTURWT52, W_FSTURWT53, W_FSTURWT54, W_FSTURWT55,
     W_FSTURWT56, W_FSTURWT57, W_FSTURWT58, W_FSTURWT59, W_FSTURWT60, W_FSTURWT61, W_FSTURWT62, W_FSTURWT63,
     W_FSTURWT64, W_FSTURWT65, W_FSTURWT66, W_FSTURWT67, W_FSTURWT68, W_FSTURWT69, W_FSTURWT70, W_FSTURWT71,
     W_FSTURWT72, W_FSTURWT73, W_FSTURWT74, W_FSTURWT75, W_FSTURWT76, W_FSTURWT77, W_FSTURWT78, W_FSTURWT79,
     W_FSTURWT80] AS agirliklar
  FROM `pisa.ogrenci`
  WHERE CYCLE = 2025
),
tahmin AS (            -- her ülke × PV (0–9) × ağırlık (0 = tam, 1–80 = tekrarlı)
  SELECT CNT, p AS pv_no, r AS agirlik_no,
         SUM(w * puan) / SUM(w) AS theta
  FROM taban,
       UNNEST(pvler) AS puan WITH OFFSET p,
       UNNEST(agirliklar) AS w WITH OFFSET r
  GROUP BY CNT, pv_no, agirlik_no
),
tam AS (               -- tam ağırlıkla 10 tahmin
  SELECT CNT, pv_no, theta AS theta_tam
  FROM tahmin
  WHERE agirlik_no = 0
),
orneklem AS (          -- her PV için örnekleme varyansı (Fay: 1 / (80 · 0,5²) = 1/20)
  SELECT CNT, pv_no, SUM(POW(t.theta - k.theta_tam, 2)) / 20 AS u
  FROM tahmin AS t
  JOIN tam AS k USING (CNT, pv_no)
  WHERE t.agirlik_no > 0
  GROUP BY CNT, pv_no
)
SELECT
  CNT AS ulke,
  ROUND(AVG(theta_tam), 1)                                      AS ortalama,
  ROUND(SQRT(AVG(u) + (1 + 1 / 10) * VAR_SAMP(theta_tam)), 2)   AS standart_hata,
  ROUND(SQRT(AVG(u)), 2)                                        AS sh_yalniz_orneklem,
  ROUND(SQRT((1 + 1 / 10) * VAR_SAMP(theta_tam)), 2)            AS sh_yalniz_olcme
FROM tam
JOIN orneklem USING (CNT, pv_no)
GROUP BY ulke
ORDER BY ortalama DESC;
