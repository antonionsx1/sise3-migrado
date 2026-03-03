USE [SISE_NEW]
GO

/****** Object:  UserDefinedTableType [SISE3].[Promociones_type]    Script Date: 12/1/2023 6:30:41 PM ******/
CREATE TYPE [SISE3].[Promociones_type] AS TABLE(
	[No] [int] NULL,
	[AsuntoNeunId] [bigint] NULL,
	[Expediente] [varchar](50) NULL,
	[CatTipoAsunto] [varchar](100) NULL,
	[CatTipoAsuntoId] [int] NULL,
	[TipoProcedimiento] [varchar](500) NULL,
	[Cuaderno] [varchar](250) NULL,
	[NumeroRegistro] [int] NULL,
	[OrigenPromocion] [varchar](50) NULL,
	[Secretario] [varchar](300) NULL,
	[IdSecretario] [int] NULL,
	[SecretarioUserName] [varchar](550) NULL,
	[Mesa] [varchar](50) NULL,
	[FechaPresentacion] [datetime] NULL,
	[TipoPromociones] [varchar](50) NULL,
	[TipoContenido] [varchar](max) NULL,
	[Promovente] [varchar](350) NULL,
	[IdPromovente] [int] NULL,
	[ClasePromovente] [varchar](50) NULL,
	[NumeroCopias] [int] NULL,
	[NumeroAnexos] [int] NULL,
	[Registrada] [bit] NULL,
	[ConArchivo] [bit] NULL,
	[EsDemanda] [bit] NULL,
	[OrigenPromocionId] [int] NULL,
	[Folio] [int] NULL,
	[EsPromocionE] [bit] NULL,
	[CatAutorizacionDocumentosId] [int] NULL,
	[NombreArchivo] [varchar](300) NULL,
	[Origen] [int] NULL,
	[NombreOrigen] [varchar](250) NULL,
	[Fojas] [smallint] NULL,
	[NumeroOrden] [int] NULL,
	[UsuarioCaptura] [varchar](550) NULL,
	[CatOrganismoId] [int] NULL,
	[YearPromocion] [int] NULL,
	[kIdElectronica] [bigint] NULL,
	[FechaCaptura] [datetime] NULL,
	[NumeroAlias] [int] NULL,
	[EstadoAcuerdo] [int] NULL
)
GO

