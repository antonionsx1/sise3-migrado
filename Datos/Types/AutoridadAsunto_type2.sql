USE [SISE_NEW]
GO

/****** Object:  UserDefinedTableType [SISE3].[AutoridadAsunto_type2]    Script Date: 12/1/2023 6:29:54 PM ******/
CREATE TYPE [SISE3].[AutoridadAsunto_type2] AS TABLE(
	[TipoAnexoId] [int] NULL,
	[AnexoParteId] [int] NULL,
	[AnexoParteDescripcion] [varchar](max) NULL,
	[TextoOficioLibre] [nvarchar](max) NULL
)
GO

