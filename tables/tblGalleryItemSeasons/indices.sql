CREATE UNIQUE INDEX UX_tblGalleryItemSeasons_Cover ON dbo.tblGalleryItemSeasons (SeasonId) WHERE IsCover = 1;
CREATE INDEX IX_tblGalleryItemSeasons_SeasonOrder ON dbo.tblGalleryItemSeasons (SeasonId, SortOrder, ItemId);
