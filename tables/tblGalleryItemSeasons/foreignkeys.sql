ALTER TABLE dbo.tblGalleryItemSeasons ADD CONSTRAINT FK_tblGalleryItemSeasons_Items FOREIGN KEY (ItemId) REFERENCES dbo.tblGalleryItems(Id);
ALTER TABLE dbo.tblGalleryItemSeasons ADD CONSTRAINT FK_tblGalleryItemSeasons_Seasons FOREIGN KEY (SeasonId) REFERENCES dbo.tblSeasons(Id);
