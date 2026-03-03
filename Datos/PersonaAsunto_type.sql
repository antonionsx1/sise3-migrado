USE [SISE_NEW]
GO

/****** Object:  UserDefinedTableType [SISE3].[PersonaAsunto_type]    Script Date: 8/25/2023 1:41:23 PM ******/
DROP TYPE [SISE3].[PersonaAsunto_type]
GO

/****** Object:  UserDefinedTableType [SISE3].[PersonaAsunto_type]    Script Date: 8/25/2023 1:41:24 PM ******/
CREATE TYPE [SISE3].[PersonaAsunto_type] AS TABLE(
	[Nombre] [varchar](500) NOT NULL,
	[APaterno] [varchar](50) NULL,
	[AMaterno] [varchar](50) NULL,
	[CatTipoPersonaId] [smallint] NULL,
	[CatCaracterPersonaAsuntoId] [smallint] NOT NULL,
	[CatTipoPersonaJuridicaId] [smallint] NULL,
	[CaracterPromueveNombre] [int] NULL
)
GO


