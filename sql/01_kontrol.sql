-- =====================================================================
-- 01 · Yükleme kontrolü
-- Slayt: "PISA verisini BigQuery'ye taşımak"
-- Ne gösterir: Her döngüde kaç öğrenci, kaç ülke var; Türkiye satırları.
-- Maliyet: birkaç MB (yalnızca 3 sütun okunur)
-- =====================================================================
SELECT
  CYCLE                         AS dongu,
  COUNT(*)                      AS ogrenci_sayisi,
  COUNT(DISTINCT CNT)           AS ulke_sayisi,
  COUNTIF(CNT = 'TUR')          AS turkiye_ogrenci,
  ROUND(SUM(IF(CNT = 'TUR', W_FSTUWT, 0))) AS turkiye_temsil_edilen_15_yas
FROM `pisa.ogrenci`
GROUP BY dongu
ORDER BY dongu;
