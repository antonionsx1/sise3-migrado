USE [SISE_NEW]
GO

/****** Object:  Table [SISE3].[CatTipoCampos]    Script Date: 1/9/2025 3:18:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [SISE3].[CatTipoCampos](
	[iTipoCampoId] [int] NOT NULL,
	[iPadreId] [int] NOT NULL,
	[bStatusReg] [bit] NULL
) ON [PRIMARY]
GO
