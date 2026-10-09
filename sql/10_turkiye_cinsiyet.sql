-- =====================================================================
-- 10 · Türkiye: cinsiyet farkı, üç alanda, standart hata ve anlamlılıkla
-- Slayt: "Türkiye derinlemesine: cinsiyet"
-- ST004D01T: 1 = kız, 2 = erkek (PISA 2022 kodlaması; 2025'te teyit edin)
-- Fark = kız − erkek. |fark| > 1,96 × SH ise %5 düzeyinde anlamlı.
-- =====================================================================
WITH taban AS (
  SELECT CYCLE, CAST(ST004D01T AS INT64) AS cins, d.alan, d.pvler,
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
  FROM `pisa.ogrenci`,
  UNNEST([
    STRUCT('Matematik' AS alan, [PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
     PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH] AS pvler),
    STRUCT('Okuma', [PV1READ, PV2READ, PV3READ, PV4READ, PV5READ,
     PV6READ, PV7READ, PV8READ, PV9READ, PV10READ]),
    STRUCT('Fen', [PV1SCIE, PV2SCIE, PV3SCIE, PV4SCIE, PV5SCIE,
     PV6SCIE, PV7SCIE, PV8SCIE, PV9SCIE, PV10SCIE])
  ]) AS d
  WHERE CNT = 'TUR' AND ST004D01T IN (1, 2)
),
tahmin AS (
  SELECT CYCLE, alan, cins, p AS pv_no, r AS agirlik_no, SUM(w * puan) / SUM(w) AS theta
  FROM taban,
       UNNEST(pvler) AS puan WITH OFFSET p,
       UNNEST(agirliklar) AS w WITH OFFSET r
  GROUP BY CYCLE, alan, cins, pv_no, agirlik_no
),
fark AS (             -- her PV × ağırlık için kız − erkek farkı
  SELECT CYCLE, alan, pv_no, agirlik_no,
    MAX(IF(cins = 1, theta, NULL)) AS kiz,
    MAX(IF(cins = 2, theta, NULL)) AS erkek,
    MAX(IF(cins = 1, theta, NULL)) - MAX(IF(cins = 2, theta, NULL)) AS theta
  FROM tahmin
  GROUP BY CYCLE, alan, pv_no, agirlik_no
),
tam AS (
  SELECT CYCLE, alan, pv_no, kiz, erkek, theta AS theta_tam FROM fark WHERE agirlik_no = 0
),
orneklem AS (
  SELECT CYCLE, alan, pv_no, SUM(POW(f.theta - k.theta_tam, 2)) / 20 AS u
  FROM fark AS f JOIN tam AS k USING (CYCLE, alan, pv_no)
  WHERE f.agirlik_no > 0
  GROUP BY CYCLE, alan, pv_no
),
sonuc AS (
  SELECT CYCLE, alan, AVG(kiz) AS kiz, AVG(erkek) AS erkek, AVG(theta_tam) AS fark,
    SQRT(AVG(u) + (1 + 1 / 10) * VAR_SAMP(theta_tam)) AS sh
  FROM tam JOIN orneklem USING (CYCLE, alan, pv_no)
  GROUP BY CYCLE, alan
)
SELECT
  CYCLE AS dongu, alan,
  ROUND(kiz, 1) AS kiz, ROUND(erkek, 1) AS erkek,
  ROUND(fark, 1) AS fark_kiz_eksi_erkek,
  ROUND(sh, 1) AS standart_hata,
  IF(ABS(fark) > 1.96 * sh, 'anlamlı', 'anlamlı değil') AS p_005
FROM sonuc
ORDER BY alan, dongu;
