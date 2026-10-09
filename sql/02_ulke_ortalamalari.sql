-- =====================================================================
-- 02 · Ülke ortalamaları: 10 olası değer + tam örneklem ağırlığı
-- Slayt: "Olası değerlerle ülke ortalaması"
-- DOĞRULAMA (resmi raporlarla):
--   TUR 2025 → matematik 462 · okuma 472 · fen 494   (OECD ort. 463 · 461 · 482)
-- Döngüyü değiştirmek için aşağıdaki "CYCLE = 2025" ifadesini düzenleyin.
-- OECD ortalaması satırı dosyadaki OECD değişkeniyle hesaplanır; üye
-- kümesi raporla aynı değilse birkaç puan sapabilir.
-- =====================================================================

WITH secim AS (            -- yalnızca gereken sütunlar: daha az bayt, daha az maliyet
  SELECT CYCLE, CNT, OECD, W_FSTUWT,
    PV1MATH, PV2MATH, PV3MATH, PV4MATH, PV5MATH,
    PV6MATH, PV7MATH, PV8MATH, PV9MATH, PV10MATH,
    PV1READ, PV2READ, PV3READ, PV4READ, PV5READ,
    PV6READ, PV7READ, PV8READ, PV9READ, PV10READ,
    PV1SCIE, PV2SCIE, PV3SCIE, PV4SCIE, PV5SCIE,
    PV6SCIE, PV7SCIE, PV8SCIE, PV9SCIE, PV10SCIE
  FROM `pisa.ogrenci`
  WHERE CYCLE = 2025
),
uzun AS (                  -- 10 olası değeri satırlara çevir
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
pv_ort AS (                -- her döngü × ülke × PV için ağırlıklı ortalama
  SELECT CYCLE, CNT, ANY_VALUE(OECD) AS oecd, pv_no,
    SUM(W_FSTUWT * mat) / SUM(W_FSTUWT) AS mat,
    SUM(W_FSTUWT * oku) / SUM(W_FSTUWT) AS oku,
    SUM(W_FSTUWT * fen) / SUM(W_FSTUWT) AS fen
  FROM uzun
  GROUP BY CYCLE, CNT, pv_no
),
ulke AS (                  -- 10 sonucun ortalaması (PV'lerin ortalaması DEĞİL)
  SELECT CYCLE, CNT, ANY_VALUE(oecd) AS oecd,
    AVG(mat) AS mat, AVG(oku) AS oku, AVG(fen) AS fen
  FROM pv_ort
  GROUP BY CYCLE, CNT
)
SELECT * FROM (
  SELECT CNT AS ulke, ROUND(mat, 1) AS matematik, ROUND(oku, 1) AS okuma, ROUND(fen, 1) AS fen
  FROM ulke
  UNION ALL
  SELECT 'OECD ortalaması', ROUND(AVG(mat), 1), ROUND(AVG(oku), 1), ROUND(AVG(fen), 1)
  FROM ulke
  WHERE oecd = 1
)
ORDER BY matematik DESC;
