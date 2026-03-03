USE [SISE_NEW]
GO

/****** Object:  UserDefinedTableType [SISE3].[Promociones_type]    Script Date: 8/25/2023 10:23:08 AM ******/
DROP TYPE [SISE3].[Promociones_type]
GO

/****** Object:  UserDefinedTableType [SISE3].[Promociones_type]    Script Date: 8/25/2023 10:23:09 AM ******/
CREATE TYPE [SISE3].[Promociones_type] AS TABLE(
	[No] [int] NULL,
	[AsuntoNeunId] [bigint] NULL,
	[Expediente] [varchar](50) NULL,
	[CatTipoAsunto] [varchar](100) NULL,
	[TipoProcedimiento] [varchar](100) NULL,
	[Cuaderno] [varchar](50) NULL,
	[NumeroRegistro] [int] NULL,
	[OrigenPromocion] [varchar](50) NULL,
	[Secretario] [varchar](300) NULL,
	[IdSecretario] [int] NULL,
	[SecretarioUserName] [varchar](300) NULL,
	[Mesa] [varchar](50) NULL,
	[FechaPresentacion] [datetime] NULL,
	[TipoPromociones] [varchar](50) NULL,
	[TipoContenido] [varchar](50) NULL,
	[Promovente] [varchar](100) NULL,
	[IdPromovente] [int] NULL,
	[ClasePromovente] [varchar](50) NULL,
	[NumeroCopias] [int] NULL,
	[NumeroAnexos] [int] NULL,
	[Registrada] [bit] NULL,
	[ConArchivo] [bit] NULL,
	[EsDemanda] [bit] NULL,
	[OrigenPromocionId] [int] NULL,
	[Folio] [int] NULL,
	[EsPromocionE] [int] NULL,
	[CatAutorizacionDocumentosId] [int] NULL,
	[NombreArchivo] [varchar](300) NULL,
	[Origen] [int] NULL
)
GO


