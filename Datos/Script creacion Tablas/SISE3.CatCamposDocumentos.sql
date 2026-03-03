USE [SISE_NEW]
GO

/****** Object:  Table [SISE3].[CatCamposDocumentos]    Script Date: 1/9/2025 3:15:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [SISE3].[CatCamposDocumentos](
	[iCampoDocumentoId] [int] NOT NULL,
	[iTipoCampoId] [int] NOT NULL,
	[iTipoAsuntoId] [int] NOT NULL,
	[fFechaAlta] [datetime] NOT NULL,
	[fFechaBaja] [datetime] NULL,
	[bIsBajaBillete] [bit] NULL,
	[iCatTipoAsunto] [int] NOT NULL,
	[iCatTipoOrganismoId] [int] NOT NULL,
	[bStatusReg] [bit] NULL,
 CONSTRAINT [PK_CatCamposDocumentos] PRIMARY KEY CLUSTERED 
(
	[iCampoDocumentoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [SISE3].[CatCamposDocumentos]  WITH CHECK ADD  CONSTRAINT [FK_CatCamposDocumentos_CatCamposDocumentos] FOREIGN KEY([iCampoDocumentoId])
REFERENCES [SISE3].[CatCamposDocumentos] ([iCampoDocumentoId])
GO

ALTER TABLE [SISE3].[CatCamposDocumentos] CHECK CONSTRAINT [FK_CatCamposDocumentos_CatCamposDocumentos]
GO


