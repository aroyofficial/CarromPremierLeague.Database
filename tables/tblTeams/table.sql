IF NOT EXISTS (
    SELECT 1
    FROM sys.tables
    WHERE name = 'tblTeams'
    AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE [dbo].[tblTeams]
    (
        [Id]        BIGINT        NOT NULL IDENTITY(1,1),
        [CreatedAt] DATETIME2(7)  NOT NULL CONSTRAINT [DF_tblTeams_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        [UpdatedAt] DATETIME2(7)  NOT NULL CONSTRAINT [DF_tblTeams_UpdatedAt] DEFAULT (SYSUTCDATETIME()),
        [Void]      BIT           NOT NULL CONSTRAINT [DF_tblTeams_Void] DEFAULT (0),

        CONSTRAINT [PK_tblTeams] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO
