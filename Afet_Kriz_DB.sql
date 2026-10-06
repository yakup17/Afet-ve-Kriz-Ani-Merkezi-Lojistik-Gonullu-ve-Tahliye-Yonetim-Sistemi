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