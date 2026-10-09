-- =====================================================================
-- 09 · (İSTEĞE BAĞLI) Üretken YZ ile açık uçlu yanıt kodlama
-- Slayt: "BigQuery'de SQL içinden yapay zekâ"
-- GEREKSİNİM: Faturalandırması açık bir proje (sandbox'ta çalışmaz),
--             BigQuery'nin yönetilen YZ fonksiyonlarına erişim. Gemini
--             çağrıları ayrıca ücretlendirilir; az satırla deneyin.
-- Parametre adlarını güncel dokümandan teyit edin:
--   cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-classify
-- AŞAĞIDAKİ YANITLAR DEMO İÇİN UYDURULMUŞ ÖRNEKLERDİR; gerçek öğrenci verisi değildir.
-- Kamuya açık PISA dosyalarında açık uçlu yanıt metinleri bulunmaz.
-- =====================================================================

-- A) YZ ile kodla ve sonucu tabloya yaz (YZ bir kez çağrılır)
CREATE OR REPLACE TABLE `pisa.yz_kodlama` AS
WITH yanitlar AS (
  SELECT * FROM UNNEST([
    STRUCT(1 AS ogrenci, 'Bitkiler güneş ışığıyla fotosentez yapıp kendi besinlerini üretir.' AS yanit, 'tam doğru' AS uzman_kodu),
    STRUCT(2, 'Güneş ışığından enerji alıp karbondioksit ve sudan şeker yaparlar.', 'tam doğru'),
    STRUCT(3, 'Işık olmazsa bitki ölür.', 'kısmen doğru'),
    STRUCT(4, 'Büyümek için ışık lazım, yeşil kalmak için.', 'kısmen doğru'),
    STRUCT(5, 'Bitkiler ışığı topraktan alır.', 'yanlış'),
    STRUCT(6, 'Isınmak için güneşe ihtiyaç duyarlar, yoksa donarlar.', 'yanlış'),
    STRUCT(7, 'bilmiyorum', 'boş veya ilgisiz'),
    STRUCT(8, 'Klorofil ışığı soğurur ve bu enerjiyle glikoz üretilir, oksijen açığa çıkar.', 'tam doğru'),
    STRUCT(9, 'Güneş bitkilere vitamin verir.', 'yanlış'),
    STRUCT(10, 'Fotosentez için.', 'kısmen doğru')
  ])
)
SELECT
  ogrenci, yanit, uzman_kodu,
  AI.CLASSIFY(
    CONCAT('Soru: Bitkiler neden güneş ışığına ihtiyaç duyar? Öğrenci yanıtı: ', yanit),
    categories => ['tam doğru', 'kısmen doğru', 'yanlış', 'boş veya ilgisiz']
  ) AS yz_kodu
FROM yanitlar;

-- B) Sonuçlar yan yana
SELECT ogrenci, yanit, uzman_kodu, yz_kodu, uzman_kodu = yz_kodu AS uyumlu
FROM `pisa.yz_kodlama`
ORDER BY ogrenci;

-- C) Uzman ile YZ arasında uyum: yüzde uyum ve Cohen kappa
WITH n AS (SELECT COUNT(*) AS toplam FROM `pisa.yz_kodlama`),
po AS (SELECT AVG(IF(uzman_kodu = yz_kodu, 1, 0)) AS p FROM `pisa.yz_kodlama`),
pe AS (
  SELECT SUM(u.adet * y.adet) / POW(ANY_VALUE(n.toplam), 2) AS p
  FROM (SELECT uzman_kodu AS kod, COUNT(*) AS adet FROM `pisa.yz_kodlama` GROUP BY kod) AS u
  JOIN (SELECT yz_kodu AS kod, COUNT(*) AS adet FROM `pisa.yz_kodlama` GROUP BY kod) AS y USING (kod)
  CROSS JOIN n
)
SELECT ROUND(po.p, 2) AS yuzde_uyum, ROUND((po.p - pe.p) / (1 - pe.p), 2) AS cohen_kappa
FROM po CROSS JOIN pe;
