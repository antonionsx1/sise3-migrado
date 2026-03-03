USE [SISE_NEW]
GO

/****** Object:  UserDefinedTableType [SISE3].[PersonaAsunto_type]    Script Date: 12/1/2023 6:30:11 PM ******/
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

