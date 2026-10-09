-- =====================================================================
-- 04 · Sosyoekonomik gruplara göre fen başarısı (Türkiye, tüm döngüler)
-- Slayt: "Sosyoekonomik gruplara göre fen başarısı"
-- ESCS: OECD ortalaması 0, standart sapması 1 olacak biçimde ölçeklenir.
-- =====================================================================
WITH taban AS (
  SELECT
    CYCLE,
    W_FSTUWT AS w,
    CASE
      WHEN ESCS < -1 THEN '1 Düşük (ESCS < -1)'
      WHEN ESCS <  0 THEN '2 Orta-alt'
      WHEN ESCS <  1 THEN '3 Orta-üst'
      ELSE                '4 Yüksek (ESCS ≥ 1)'
    END AS escs_grup,
    PV1SCIE, PV2SCIE, PV3SCIE, PV4SCIE, PV5SCIE,
    PV6SCIE, PV7SCIE, PV8SCIE, PV9SCIE, PV10SCIE
  FROM `pisa.ogrenci`
  WHERE CNT = 'TUR' AND ESCS IS NOT NULL
),
uzun AS (
  SELECT * FROM taban
  UNPIVOT (puan FOR pv_no IN (
    PV1SCIE, PV2SCIE, PV3SCIE, PV4SCIE, PV5SCIE,
    PV6SCIE, PV7SCIE, PV8SCIE, PV9SCIE, PV10SCIE))
),
pv_ort AS (
  SELECT CYCLE, escs_grup, pv_no,
         SUM(w * puan) / SUM(w) AS ort,
         SUM(w) AS agirlik
  FROM uzun
  GROUP BY CYCLE, escs_grup, pv_no
)
SELECT
  CYCLE AS dongu,
  escs_grup,
  ROUND(AVG(ort), 1) AS fen,
  ROUND(100 * AVG(agirlik) / SUM(AVG(agirlik)) OVER (PARTITION BY CYCLE), 1) AS ogrenci_yuzdesi
FROM pv_ort
GROUP BY dongu, escs_grup
ORDER BY escs_grup, dongu;
