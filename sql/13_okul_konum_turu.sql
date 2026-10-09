-- =====================================================================
-- 13 · Türkiye: okulun bulunduğu yerleşim yeri ve okul türü (devlet/özel)
-- Slayt: "Türkiye derinlemesine: okullar"
-- GEREKSİNİM: Yükleme defterinde OKUL dosyası da yüklenmiş olmalı (pisa.okul).
-- SC001Q01TA: okulun bulunduğu yerleşim yeri büyüklüğü (köy … büyükşehir)
-- SCHLTYPE  : okul türü (özel bağımsız / devlete bağlı özel / devlet)
-- =====================================================================

-- A) Yerleşim yerine göre matematik
WITH taban AS (
  SELECT CYCLE, COALESCE(CAST(k.SC001Q01TA_ETIKET AS STRING), '(bilinmiyor)') AS grup,
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
  FROM `pisa.ogrenci` AS o JOIN `pisa.okul` AS k USING (CYCLE, CNT, CNTSCHID)
  WHERE CNT = 'TUR'
),
sayim AS (
  SELECT CYCLE, COALESCE(CAST(k.SC001Q01TA_ETIKET AS STRING), '(bilinmiyor)') AS grup,
    COUNT(*) AS ogrenci, COUNT(DISTINCT CNTSCHID) AS okul, SUM(W_FSTUWT) AS agirlik
  FROM `pisa.ogrenci` AS o JOIN `pisa.okul` AS k USING (CYCLE, CNT, CNTSCHID)
  WHERE CNT = 'TUR'
  GROUP BY CYCLE, grup
),
tahmin AS (          -- her grup × PV × ağırlık için ağırlıklı ortalama
  SELECT CYCLE, grup, p AS pv_no, r AS agirlik_no, SUM(w * puan) / SUM(w) AS theta
  FROM taban,
       UNNEST(pvler) AS puan WITH OFFSET p,
       UNNEST(agirliklar) AS w WITH OFFSET r
  GROUP BY CYCLE, grup, pv_no, agirlik_no
),
tam AS (
  SELECT CYCLE, grup, pv_no, theta AS theta_tam FROM tahmin WHERE agirlik_no = 0
),
orneklem AS (         -- Fay BRR: 1/20
  SELECT CYCLE, grup, pv_no, SUM(POW(t.theta - k.theta_tam, 2)) / 20 AS u
  FROM tahmin AS t JOIN tam AS k USING (CYCLE, grup, pv_no)
  WHERE t.agirlik_no > 0
  GROUP BY CYCLE, grup, pv_no
),
sonuc AS (            -- Rubin: V = Ū + (1 + 1/10)·B
  SELECT CYCLE, grup,
    AVG(theta_tam) AS ortalama,
    SQRT(AVG(u) + (1 + 1 / 10) * VAR_SAMP(theta_tam)) AS sh
  FROM tam JOIN orneklem USING (CYCLE, grup, pv_no)
  GROUP BY CYCLE, grup
)
SELECT
  CYCLE AS dongu, grup,
  ROUND(ortalama, 1) AS ortalama,
  ROUND(sh, 1) AS standart_hata,
  ogrenci, okul,
  ROUND(100 * agirlik / SUM(agirlik) OVER (PARTITION BY CYCLE), 1) AS nufus_yuzdesi,
  IF(okul < 10, 'dikkat: 10 okuldan az', '') AS uyari
FROM sonuc JOIN sayim USING (CYCLE, grup)
ORDER BY dongu, ortalama DESC;


-- B) Okul türüne göre matematik
WITH taban AS (
  SELECT CYCLE, COALESCE(CAST(k.SCHLTYPE_ETIKET AS STRING), '(bilinmiyor)') AS grup,
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
  FROM `pisa.ogrenci` AS o JOIN `pisa.okul` AS k USING (CYCLE, CNT, CNTSCHID)
  WHERE CNT = 'TUR'
),
sayim AS (
  SELECT CYCLE, COALESCE(CAST(k.SCHLTYPE_ETIKET AS STRING), '(bilinmiyor)') AS grup,
    COUNT(*) AS ogrenci, COUNT(DISTINCT CNTSCHID) AS okul, SUM(W_FSTUWT) AS agirlik
  FROM `pisa.ogrenci` AS o JOIN `pisa.okul` AS k USING (CYCLE, CNT, CNTSCHID)
  WHERE CNT = 'TUR'
  GROUP BY CYCLE, grup
),
tahmin AS (          -- her grup × PV × ağırlık için ağırlıklı ortalama
  SELECT CYCLE, grup, p AS pv_no, r AS agirlik_no, SUM(w * puan) / SUM(w) AS theta
  FROM taban,
       UNNEST(pvler) AS puan WITH OFFSET p,
       UNNEST(agirliklar) AS w WITH OFFSET r
  GROUP BY CYCLE, grup, pv_no, agirlik_no
),
tam AS (
  SELECT CYCLE, grup, pv_no, theta AS theta_tam FROM tahmin WHERE agirlik_no = 0
),
orneklem AS (         -- Fay BRR: 1/20
  SELECT CYCLE, grup, pv_no, SUM(POW(t.theta - k.theta_tam, 2)) / 20 AS u
  FROM tahmin AS t JOIN tam AS k USING (CYCLE, grup, pv_no)
  WHERE t.agirlik_no > 0
  GROUP BY CYCLE, grup, pv_no
),
sonuc AS (            -- Rubin: V = Ū + (1 + 1/10)·B
  SELECT CYCLE, grup,
    AVG(theta_tam) AS ortalama,
    SQRT(AVG(u) + (1 + 1 / 10) * VAR_SAMP(theta_tam)) AS sh
  FROM tam JOIN orneklem USING (CYCLE, grup, pv_no)
  GROUP BY CYCLE, grup
)
SELECT
  CYCLE AS dongu, grup,
  ROUND(ortalama, 1) AS ortalama,
  ROUND(sh, 1) AS standart_hata,
  ogrenci, okul,
  ROUND(100 * agirlik / SUM(agirlik) OVER (PARTITION BY CYCLE), 1) AS nufus_yuzdesi,
  IF(okul < 10, 'dikkat: 10 okuldan az', '') AS uyari
FROM sonuc JOIN sayim USING (CYCLE, grup)
ORDER BY dongu, ortalama DESC;

