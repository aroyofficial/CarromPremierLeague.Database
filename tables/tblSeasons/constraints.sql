IF NOT EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE type = 'PK'
    AND parent_object_id = OBJECT_ID('dbo.tblSeasons')
    AND name = 'PK_tblSeasons'
)
BEGIN
    ALTER TABLE [dbo].[tblSeasons]
    ADD CONSTRAINT [PK_tblSeasons]
        PRIMARY KEY CLUSTERED ([Id] ASC);
END
GO
