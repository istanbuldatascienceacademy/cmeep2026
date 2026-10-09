-- =====================================================================
-- 05 · Yeterlik düzeyleri: Düzey 2 altı ve Düzey 5 ve üstü öğrenci yüzdesi
-- Slayt: "PISA 2025: Türkiye, OECD ve tüm ülkeler"
-- DOĞRULAMA (MEB, PISA 2025): Türkiye fen Düzey 5+ ≈ %7,4 (OECD ≈ %7,2),
--                             okuma Düzey 5+ ≈ %4,2
-- EŞİKLER (önceki döngülerin ölçek eşikleri):
--   Matematik: Düzey 2 = 420,07 · Düzey 5 = 606,99
--   Okuma    : Düzey 2 = 407,47 · Düzey 5 = 625,61
--   Fen      : Düzey 2 = 409,54 · Düzey 5 = 633,33
-- PISA 2025'te fen çerçevesi yenilendi: fen eşiklerini 2025 teknik raporundan
-- teyit edin. Yukarıdaki %7,4 tutuyorsa eşikler doğrudur.
-- =====================================================================
WITH secim AS (
  SELECT CNT, OECD, W_FSTUWT,
    PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
    PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH,
    PV1READ, PV2READ, PV3READ, PV4READ, PV5READ,
    PV6READ, PV7READ, PV8READ, PV9READ, PV10READ,
    PV1SCIE, PV2SCIE, PV3SCIE, PV4SCIE, PV5SCIE,
    PV6SCIE, PV7SCIE, PV8SCIE, PV9SCIE, PV10SCIE
  FROM `pisa.ogrenci`
  WHERE CYCLE = 2025
),
uzun AS (
  SELECT * FROM secim
  UNPIVOT ((mat, oku, fen) FOR pv_no IN (
      (PV1MATH, PV1READ, PV1SCIE) AS 1,
      (PV2MATH, PV2READ, PV2SCIE) AS 2,
      (PV3MATH, PV3READ, PV3SCIE) AS 3,
      (PV4MATH, PV4READ, PV4SCIE) AS 4,
      (PV5MATH, PV5READ, PV5SCIE) AS 5,
      (PV6MATH, PV6READ, PV6SCIE) AS 6,
      (PV7MATH, PV7READ, PV7SCIE) AS 7,
      (PV8MATH, PV8READ, PV8SCIE) AS 8,
      (PV9MATH, PV9READ, PV9SCIE) AS 9,
      (PV10MATH, PV10READ, PV10SCIE) AS 10))
),
pv_oran AS (             -- her ülke × PV için ağırlıklı oranlar
  SELECT CNT, ANY_VALUE(OECD) AS oecd, pv_no,
    SUM(IF(mat <  420.07, W_FSTUWT, 0)) / SUM(W_FSTUWT) AS mat_alt2,
    SUM(IF(mat >= 606.99, W_FSTUWT, 0)) / SUM(W_FSTUWT) AS mat_ust5,
    SUM(IF(oku <  407.47, W_FSTUWT, 0)) / SUM(W_FSTUWT) AS oku_alt2,
    SUM(IF(oku >= 625.61, W_FSTUWT, 0)) / SUM(W_FSTUWT) AS oku_ust5,
    SUM(IF(fen <  409.54, W_FSTUWT, 0)) / SUM(W_FSTUWT) AS fen_alt2,
    SUM(IF(fen >= 633.33, W_FSTUWT, 0)) / SUM(W_FSTUWT) AS fen_ust5
  FROM uzun
  GROUP BY CNT, pv_no
),
ulke AS (                -- 10 PV sonucunun ortalaması
  SELECT CNT, ANY_VALUE(oecd) AS oecd,
    AVG(mat_alt2) AS mat_alt2, AVG(mat_ust5) AS mat_ust5,
    AVG(oku_alt2) AS oku_alt2, AVG(oku_ust5) AS oku_ust5,
    AVG(fen_alt2) AS fen_alt2, AVG(fen_ust5) AS fen_ust5
  FROM pv_oran
  GROUP BY CNT
)
SELECT * FROM (
  SELECT CNT AS ulke,
    ROUND(100 * fen_alt2, 1) AS fen_duzey2_alti, ROUND(100 * fen_ust5, 1) AS fen_duzey5_ustu,
    ROUND(100 * oku_alt2, 1) AS okuma_duzey2_alti, ROUND(100 * oku_ust5, 1) AS okuma_duzey5_ustu,
    ROUND(100 * mat_alt2, 1) AS mat_duzey2_alti, ROUND(100 * mat_ust5, 1) AS mat_duzey5_ustu
  FROM ulke
  UNION ALL
  SELECT 'OECD ortalaması',
    ROUND(100 * AVG(fen_alt2), 1), ROUND(100 * AVG(fen_ust5), 1),
    ROUND(100 * AVG(oku_alt2), 1), ROUND(100 * AVG(oku_ust5), 1),
    ROUND(100 * AVG(mat_alt2), 1), ROUND(100 * AVG(mat_ust5), 1)
  FROM ulke WHERE oecd = 1
)
WHERE ulke IN ('TUR', 'OECD ortalaması')   -- tüm ülkeler için bu satırı silin
ORDER BY ulke DESC;
