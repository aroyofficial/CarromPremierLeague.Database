CREATE TABLE dbo.tblGalleryItemSeasons (
    ItemId BIGINT NOT NULL,
    SeasonId BIGINT NOT NULL,
    SortOrder INT NOT NULL CONSTRAINT DF_tblGalleryItemSeasons_SortOrder DEFAULT 0,
    IsCover BIT NOT NULL CONSTRAINT DF_tblGalleryItemSeasons_IsCover DEFAULT 0,
    CONSTRAINT PK_tblGalleryItemSeasons PRIMARY KEY (ItemId, SeasonId)
);
