IF NOT EXISTS (
    SELECT 1
    FROM sys.tables
    WHERE name = 'tblSeasons'
    AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE [dbo].[tblSeasons]
    (
        [Id]        BIGINT        NOT NULL IDENTITY(1,1),
        [CreatedAt] DATETIME2(7)  NOT NULL CONSTRAINT [DF_tblSeasons_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        [UpdatedAt] DATETIME2(7)  NOT NULL CONSTRAINT [DF_tblSeasons_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        [Void]      BIT           NOT NULL CONSTRAINT [DF_tblSeasons_Void] DEFAULT (0),

        CONSTRAINT [PK_tblSeasons] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO
