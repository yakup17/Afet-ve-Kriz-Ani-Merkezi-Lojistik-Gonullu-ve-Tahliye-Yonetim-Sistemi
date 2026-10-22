CREATE DATABASE AfetKrizDB;
GO

USE AfetKrizDB;
GO

                    -- HAFTA 1: İLK 11 TABLONUN OLUŞTURULMASI

-- 1. Afetler
CREATE TABLE Afetler (
    AfetID INT IDENTITY(1,1) PRIMARY KEY,
    AfetTuru NVARCHAR(50) NOT NULL, -- Deprem, Sel, Yangın vb.
    AfetTarihi DATETIME NOT NULL,
    SiddetKategorisi INT CHECK (SiddetKategorisi BETWEEN 1 AND 5),
    Aciklama NVARCHAR(500)
);

-- 2. AfetBolgeleri
CREATE TABLE AfetBolgeleri (
    BolgeID INT IDENTITY(1,1) PRIMARY KEY,
    AfetID INT NOT NULL,
    Il NVARCHAR(50) NOT NULL,
    Ilce NVARCHAR(50) NOT NULL,
    Koordinat_Lat DECIMAL(9,6),
    Koordinat_Long DECIMAL(9,6),
    AciliyetDurumu NVARCHAR(20) DEFAULT 'Yüksek' -- Yüksek, Orta, Düşük
);

-- 3. AfetzedeTalepleri
CREATE TABLE AfetzedeTalepleri (
    TalepID INT IDENTITY(1,1) PRIMARY KEY,
    BolgeID INT NOT NULL,
    TalepEdenTC NCHAR(11),
    TalepEdenAdSoyad NVARCHAR(100) NOT NULL,
    IletisimNo NVARCHAR(15),
    TalepTarihi DATETIME DEFAULT GETDATE(),
    Durum NVARCHAR(20) DEFAULT 'Bekliyor' -- Bekliyor, Karsilandi, Iptal
);

-- 4. TalepDetaylari
CREATE TABLE TalepDetaylari (
    TalepDetayID INT IDENTITY(1,1) PRIMARY KEY,
    TalepID INT NOT NULL,
    UrunID INT NOT NULL,
    IstenenMiktar INT NOT NULL CHECK (IstenenMiktar > 0),
    KarsilananMiktar INT DEFAULT 0
);

-- 5. ToplanmaMerkezleri
CREATE TABLE ToplanmaMerkezleri (
    MerkezID INT IDENTITY(1,1) PRIMARY KEY,
    BolgeID INT NULL, -- Bazı merkezler genel olabilir, bölgeye özel olmayabilir
    MerkezAdi NVARCHAR(150) NOT NULL,
    Kapasite INT NOT NULL CHECK (Kapasite > 0),
    MevcutKisiSayisi INT DEFAULT 0,
    Koordinatlar NVARCHAR(100)
);

-- 6. TahliyeKayitlari
CREATE TABLE TahliyeKayitlari (
    TahliyeID INT IDENTITY(1,1) PRIMARY KEY,
    MerkezID INT NOT NULL,
    VatandasTC NCHAR(11) NOT NULL,
    AdSoyad NVARCHAR(100) NOT NULL,
    TahliyeTarihi DATETIME DEFAULT GETDATE(),
    AyrilisTarihi DATETIME NULL
);

-- 7. LojistikDepolar
CREATE TABLE LojistikDepolar (
    DepoID INT IDENTITY(1,1) PRIMARY KEY,
    DepoAdi NVARCHAR(100) NOT NULL,
    Il NVARCHAR(50) NOT NULL,
    Adres NVARCHAR(250),
    SogukHavaVarMi BIT DEFAULT 0 -- 1: Evet, 0: Hayır (İlaç ve Gıda için önemli)
);

-- 8. UrunKategorileri
CREATE TABLE UrunKategorileri (
    KategoriID INT IDENTITY(1,1) PRIMARY KEY,
    KategoriAdi NVARCHAR(50) NOT NULL -- Gıda, Barınma, Sağlık, Giyim vb.
);

-- 9. Urunler
CREATE TABLE Urunler (
    UrunID INT IDENTITY(1,1) PRIMARY KEY,
    KategoriID INT NOT NULL,
    UrunAdi NVARCHAR(100) NOT NULL,
    Birim NVARCHAR(20) NOT NULL -- Koli, Adet, Ton, Litre vb.
);

-- 10. DepoStoklari
CREATE TABLE DepoStoklari (
    StokID INT IDENTITY(1,1) PRIMARY KEY,
    DepoID INT NOT NULL,
    UrunID INT NOT NULL,
    MevcutMiktar INT NOT NULL DEFAULT 0,
    KritikSeviye INT DEFAULT 100 -- Sistem uyarı versin diye
);

-- 11. Bagiscilar
CREATE TABLE Bagiscilar (
    BagisciID INT IDENTITY(1,1) PRIMARY KEY,
    AdSoyadKurum NVARCHAR(150) NOT NULL,
    Iletisim NVARCHAR(50),
    BagisciTipi NVARCHAR(20) -- Bireysel, Kurumsal
);

                    -- YABANCI ANAHTAR (FOREIGN KEY) İLİŞKİLERİ

ALTER TABLE AfetBolgeleri ADD CONSTRAINT FK_AfetBolgeleri_Afetler FOREIGN KEY (AfetID) REFERENCES Afetler(AfetID);

ALTER TABLE AfetzedeTalepleri ADD CONSTRAINT FK_AfetzedeTalepleri_AfetBolgeleri FOREIGN KEY (BolgeID) REFERENCES AfetBolgeleri(BolgeID);

ALTER TABLE TalepDetaylari ADD CONSTRAINT FK_TalepDetaylari_AfetzedeTalepleri FOREIGN KEY (TalepID) REFERENCES AfetzedeTalepleri(TalepID);
ALTER TABLE TalepDetaylari ADD CONSTRAINT FK_TalepDetaylari_Urunler FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID);

ALTER TABLE ToplanmaMerkezleri ADD CONSTRAINT FK_ToplanmaMerkezleri_AfetBolgeleri FOREIGN KEY (BolgeID) REFERENCES AfetBolgeleri(BolgeID);

ALTER TABLE TahliyeKayitlari ADD CONSTRAINT FK_TahliyeKayitlari_ToplanmaMerkezleri FOREIGN KEY (MerkezID) REFERENCES ToplanmaMerkezleri(MerkezID);

ALTER TABLE Urunler ADD CONSTRAINT FK_Urunler_UrunKategorileri FOREIGN KEY (KategoriID) REFERENCES UrunKategorileri(KategoriID);

ALTER TABLE DepoStoklari ADD CONSTRAINT FK_DepoStoklari_LojistikDepolar FOREIGN KEY (DepoID) REFERENCES LojistikDepolar(DepoID);
ALTER TABLE DepoStoklari ADD CONSTRAINT FK_DepoStoklari_Urunler FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID);

PRINT 'İlk 11 tablo ve ilişkileri başarıyla oluşturuldu!';

USE AfetKrizDB;
GO

-- ============================================================================
-- KISIM 1: RAPORDAKİ ALGORİTMA İHTİYAÇLARI İÇİN İLK 11 TABLOYA YAPILAN EKLEMELER
-- ============================================================================

-- Ürün kategorisine atanan 1-5 arasındaki kritiklik seviyesinin eklenmesi[cite: 4]
ALTER TABLE UrunKategorileri 
ADD KritiklikSeviyesi INT CHECK (KritiklikSeviyesi BETWEEN 1 AND 5) DEFAULT 1;

-- Bölge hasar durumu ve etkilenen kişi sayısının eklenmesi[cite: 5]
ALTER TABLE AfetBolgeleri 
ADD HasarDurumu INT CHECK (HasarDurumu BETWEEN 1 AND 5) DEFAULT 3,
    EtkilenenKisiSayisi INT DEFAULT 0;

-- Talepte öncelik puanı, karşılanma zamanı ve çevrimdışı senkronizasyon kimliğinin eklenmesi[cite: 5]
ALTER TABLE AfetzedeTalepleri 
ADD OncelikPuani DECIMAL(5,2) DEFAULT 0,
    KarsilanmaZamani DATETIME NULL,
    SyncID UNIQUEIDENTIFIER DEFAULT NEWID();

-- Depo koordinatlarının eklenmesi[cite: 5]
ALTER TABLE LojistikDepolar 
ADD Koordinat_Lat DECIMAL(9,6),
    Koordinat_Long DECIMAL(9,6);


-- ============================================================================
-- KISIM 2: EKSİK TABLOLARIN VE DENEY/TEST MİMARİSİNİN OLUŞTURULMASI
-- ============================================================================

-- 12. GÖNÜLLÜLER TABLOSU
-- Gönüllü koordinatları, müsaitlik durumu ve görev süresini içerir[cite: 5]
CREATE TABLE Gonulluler (
    GonulluID INT IDENTITY(1,1) PRIMARY KEY,
    AdSoyad NVARCHAR(100) NOT NULL,
    TCNo CHAR(11) UNIQUE NOT NULL,
    Telefon VARCHAR(15) NOT NULL,
    MusaitMi BIT DEFAULT 1, 
    Son48SaatGorevSuresi INT DEFAULT 0, -- Saat cinsinden
    Koordinat_Lat DECIMAL(9,6),
    Koordinat_Long DECIMAL(9,6),
    SyncID UNIQUEIDENTIFIER DEFAULT NEWID()
);

-- 13. YETKİNLİKLER TABLOSU
CREATE TABLE Yetkinlikler (
    YetkinlikID INT IDENTITY(1,1) PRIMARY KEY,
    YetkinlikAdi NVARCHAR(50) NOT NULL UNIQUE
);

-- 14. GÖNÜLLÜ YETKİNLİKLERİ (M-N İLİŞKİ)
CREATE TABLE GonulluYetkinlikleri (
    GonulluID INT FOREIGN KEY REFERENCES Gonulluler(GonulluID),
    YetkinlikID INT FOREIGN KEY REFERENCES Yetkinlikler(YetkinlikID),
    PRIMARY KEY (GonulluID, YetkinlikID)
);

-- 15. SAHA GÖREVLERİ (GÖNÜLLÜ ATAMALARI İÇİN)
-- Görev için zorunlu yetkinlik ve konum bilgilerini içerir[cite: 5]
CREATE TABLE SahaGorevleri (
    GorevID INT IDENTITY(1,1) PRIMARY KEY,
    BolgeID INT FOREIGN KEY REFERENCES AfetBolgeleri(BolgeID),
    Aciklama NVARCHAR(255) NOT NULL,
    ZorunluYetkinlikID INT FOREIGN KEY REFERENCES Yetkinlikler(YetkinlikID),
    Koordinat_Lat DECIMAL(9,6),
    Koordinat_Long DECIMAL(9,6),
    AtananGonulluID INT FOREIGN KEY REFERENCES Gonulluler(GonulluID),
    GorevDurumu NVARCHAR(20) DEFAULT 'Bekliyor',
    OlusturulmaTarihi DATETIME DEFAULT GETDATE(),
    KarsilanmaZamani DATETIME NULL,
    SyncID UNIQUEIDENTIFIER DEFAULT NEWID()
);

-- 16. ARAÇLAR TABLOSU
-- Araç kapasitesini içerir[cite: 5]
CREATE TABLE Araclar (
    AracID INT IDENTITY(1,1) PRIMARY KEY,
    Plaka VARCHAR(15) UNIQUE NOT NULL,
    AracTipi NVARCHAR(30) NOT NULL, 
    KapasiteKg DECIMAL(10,2) NOT NULL,
    Durum NVARCHAR(20) DEFAULT 'Müsait'
);

-- 17. YOL DURUMLARI TABLOSU
-- Yol durumlarında başlangıç ve bitiş noktalarını içerir[cite: 5]
CREATE TABLE YolDurumlari (
    YolID INT IDENTITY(1,1) PRIMARY KEY,
    Baslangic_Lat DECIMAL(9,6) NOT NULL,
    Baslangic_Long DECIMAL(9,6) NOT NULL,
    Bitis_Lat DECIMAL(9,6) NOT NULL,
    Bitis_Long DECIMAL(9,6) NOT NULL,
    YolDurumu NVARCHAR(20) DEFAULT 'Açık' -- Açık, Kapalı, Riskli
);

-- 18. SEVKİYATLAR TABLOSU
CREATE TABLE Sevkiyatlar (
    SevkiyatID INT IDENTITY(1,1) PRIMARY KEY,
    AracID INT FOREIGN KEY REFERENCES Araclar(AracID),
    SoforGonulluID INT FOREIGN KEY REFERENCES Gonulluler(GonulluID), 
    CikisDepoID INT FOREIGN KEY REFERENCES LojistikDepolar(DepoID), 
    HedefBolgeID INT FOREIGN KEY REFERENCES AfetBolgeleri(BolgeID), 
    CikisTarihi DATETIME DEFAULT GETDATE(),
    VarisTarihi DATETIME,
    Durum NVARCHAR(20) DEFAULT 'Yolda',
    SyncID UNIQUEIDENTIFIER DEFAULT NEWID()
);

-- 19. SEVKİYAT DETAYLARI TABLOSU
CREATE TABLE SevkiyatDetaylari (
    SevkiyatDetayID INT IDENTITY(1,1) PRIMARY KEY,
    SevkiyatID INT FOREIGN KEY REFERENCES Sevkiyatlar(SevkiyatID),
    UrunID INT FOREIGN KEY REFERENCES Urunler(UrunID),
    Miktar INT NOT NULL CHECK (Miktar > 0)
);

-- 20. BAĞIŞLAR TABLOSU
CREATE TABLE Bagislar (
    BagisID INT IDENTITY(1,1) PRIMARY KEY,
    BagisciID INT FOREIGN KEY REFERENCES Bagiscilar(BagisciID),
    DepoID INT FOREIGN KEY REFERENCES LojistikDepolar(DepoID),
    BagisTarihi DATETIME DEFAULT GETDATE(),
    SyncID UNIQUEIDENTIFIER DEFAULT NEWID()
);

-- 21. BAĞIŞ DETAYLARI TABLOSU
CREATE TABLE BagisDetaylari (
    BagisDetayID INT IDENTITY(1,1) PRIMARY KEY,
    BagisID INT FOREIGN KEY REFERENCES Bagislar(BagisID),
    UrunID INT FOREIGN KEY REFERENCES Urunler(UrunID),
    Miktar INT NOT NULL CHECK (Miktar > 0)
);

-- 22. SENARYOLAR TABLOSU
-- Deney sonuçları için ayrı bir senaryo tablosu[cite: 5]
CREATE TABLE Senaryolar (
    SenaryoID INT IDENTITY(1,1) PRIMARY KEY,
    SenaryoAdi NVARCHAR(100) NOT NULL,
    Aciklama NVARCHAR(500),
    TohumDegeri INT, -- Rastgele üretilen veriler için (Seed)
    OlusturulmaTarihi DATETIME DEFAULT GETDATE()
);

-- 23. DENEY SONUÇLARI TABLOSU
-- Ayrı bir sonuç tablosu[cite: 5]
CREATE TABLE DeneySonuclari (
    SonucID INT IDENTITY(1,1) PRIMARY KEY,
    SenaryoID INT FOREIGN KEY REFERENCES Senaryolar(SenaryoID),
    UygulananYontem NVARCHAR(50) NOT NULL, -- Algoritma vs FIFO
    TepkiSuresiMs DECIMAL(10,2),
    TalepKarsilamaOrani DECIMAL(5,2),
    KritikTalepKarsilamaOrani DECIMAL(5,2),
    OrtalamaBeklemeSuresiDk DECIMAL(10,2),
    AlgoritmaCalismaSuresiMs DECIMAL(10,2),
    TestTarihi DATETIME DEFAULT GETDATE()
);

PRINT 'Algoritma güncellemeleri ve kalan 12 tablo başarıyla oluşturuldu!';
