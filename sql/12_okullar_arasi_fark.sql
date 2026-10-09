-- =====================================================================
-- 12 · Okullar arası fark: başarı farklılıklarının ne kadarı okullar arasında?
-- Slayt: "Türkiye derinlemesine: okullar"
-- Betimsel varyans ayrıştırması: okul ortalamalarının varyansı / toplam varyans.
-- (OECD raporları çok düzeyli model kullanır; değerler yakın ama birebir değildir.)
-- =====================================================================

-- A) Ülkelere göre okullar arası varyans payı (10 PV ortalaması)
WITH secim AS (
  SELECT CNT, OECD, CNTSCHID, W_FSTUWT AS w,
    PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
    PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH
  FROM `pisa.ogrenci`
  WHERE CYCLE = 2025
),
uzun AS (
  SELECT * FROM secim
  UNPIVOT (puan FOR pv_no IN (
    PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
    PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH))
),
genel AS (
  SELECT CNT, pv_no, SUM(w * puan) / SUM(w) AS m FROM uzun GROUP BY CNT, pv_no
),
okul AS (
  SELECT CNT, pv_no, CNTSCHID, SUM(w) AS wo, SUM(w * puan) / SUM(w) AS mo
  FROM uzun GROUP BY CNT, pv_no, CNTSCHID
),
toplam AS (
  SELECT CNT, pv_no, SUM(u.w * POW(u.puan - g.m, 2)) / SUM(u.w) AS v_toplam
  FROM uzun AS u JOIN genel AS g USING (CNT, pv_no) GROUP BY CNT, pv_no
),
arasi AS (
  SELECT CNT, pv_no, SUM(o.wo * POW(o.mo - g.m, 2)) / SUM(o.wo) AS v_arasi
  FROM okul AS o JOIN genel AS g USING (CNT, pv_no) GROUP BY CNT, pv_no
),
ulke AS (
  SELECT CNT, AVG(v_arasi / v_toplam) AS pay
  FROM toplam JOIN arasi USING (CNT, pv_no) GROUP BY CNT
)
SELECT * FROM (
  SELECT CNT AS ulke, ROUND(100 * pay, 1) AS okullar_arasi_yuzde FROM ulke
  UNION ALL
  SELECT 'OECD ortalaması', ROUND(100 * AVG(pay), 1)
  FROM ulke WHERE CNT IN (SELECT DISTINCT CNT FROM secim WHERE OECD = 1)
)
WHERE ulke IN ('TUR', 'OECD ortalaması', 'FIN', 'DEU', 'JPN', 'GRC')   -- tüm ülkeler için silin
ORDER BY okullar_arasi_yuzde DESC;

-- B) Türkiye: okulların sosyoekonomik düzeyine göre dört grup
WITH okul AS (
  SELECT CNTSCHID,
    SAFE_DIVIDE(SUM(W_FSTUWT * ESCS), SUM(IF(ESCS IS NULL, 0, W_FSTUWT))) AS okul_escs,
    SUM(W_FSTUWT * (PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH + PV6MATH + PV7MATH + PV8MATH + PV9MATH + PV10MATH) / 10) / SUM(W_FSTUWT) AS okul_mat,
    SUM(W_FSTUWT) AS w
  FROM `pisa.ogrenci`
  WHERE CNT = 'TUR' AND CYCLE = 2025
  GROUP BY CNTSCHID
),
ceyrek AS (
  SELECT *, NTILE(4) OVER (ORDER BY okul_escs) AS c FROM okul WHERE okul_escs IS NOT NULL
)
SELECT
  CASE c WHEN 1 THEN '1 En dezavantajlı okullar' WHEN 2 THEN '2' WHEN 3 THEN '3'
         ELSE '4 En avantajlı okullar' END AS okul_grubu,
  COUNT(*) AS okul_sayisi,
  ROUND(SUM(w * okul_escs) / SUM(w), 2) AS ort_escs,
  ROUND(SUM(w * okul_mat) / SUM(w), 1) AS matematik
FROM ceyrek
GROUP BY okul_grubu
ORDER BY okul_grubu;

-- C) Okul ESCS ile okul başarısı arasındaki korelasyon (Türkiye)
SELECT ROUND(CORR(okul_escs, okul_mat), 2) AS korelasyon, COUNT(*) AS okul_sayisi
FROM (
  SELECT CNTSCHID,
    SAFE_DIVIDE(SUM(W_FSTUWT * ESCS), SUM(IF(ESCS IS NULL, 0, W_FSTUWT))) AS okul_escs,
    SUM(W_FSTUWT * (PV1MATH + PV2MATH + PV3MATH + PV4MATH + PV5MATH + PV6MATH + PV7MATH + PV8MATH + PV9MATH + PV10MATH) / 10) / SUM(W_FSTUWT) AS okul_mat
  FROM `pisa.ogrenci`
  WHERE CNT = 'TUR' AND CYCLE = 2025
  GROUP BY CNTSCHID
);
