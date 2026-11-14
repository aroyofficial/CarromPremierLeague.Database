ALTER TABLE dbo.tblGalleryItems ADD CONSTRAINT FK_tblGalleryItems_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.tblAdmins(Id);
ALTER TABLE dbo.tblGalleryItems ADD CONSTRAINT FK_tblGalleryItems_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.tblAdmins(Id);
