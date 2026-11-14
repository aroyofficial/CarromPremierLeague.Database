ALTER TABLE dbo.tblGalleryItems ADD CONSTRAINT CK_tblGalleryItems_SourceType CHECK (SourceType IN ('upload', 'link'));
ALTER TABLE dbo.tblGalleryItems ADD CONSTRAINT CK_tblGalleryItems_Size CHECK (Width > 0 AND Height > 0);
