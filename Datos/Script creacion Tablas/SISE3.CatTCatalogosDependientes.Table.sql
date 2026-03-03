USE [SISE_NEW]
GO

/****** Object:  Table [SISE3].[CatTipoCampos]    Script Date: 20/03/2025 05:03:23 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [SISE3].[CatTCatalogosDependientes](
	[iCatTCatalogosDependientesId] [int] NOT NULL IDENTITY(1,1),
	[iCatalogoPadreId] [int] NOT NULL,
	[iCatalogoHijoId] [int] NOT NULL,
	[bStatusReg] [bit] NULL
) ON [PRIMARY]
GO

INSERT INTO [SISE3].[CatTCatalogosDependientes] (iCatalogoPadreId, iCatalogoHijoId, bStatusReg)
VALUES(4426,4427,1);
