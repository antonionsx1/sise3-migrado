USE [SISE_NEW]
GO

/****** Object:  UserDefinedTableType [SISE3].[AutoridadAsunto_type]    Script Date: 12/1/2023 6:29:38 PM ******/
CREATE TYPE [SISE3].[AutoridadAsunto_type] AS TABLE(
	[TipoAnexoId] [int] NULL,
	[AnexoParteId] [int] NULL,
	[AnexoParteDescripcion] [varchar](max) NULL,
	[TextoOficioLibre] [nvarchar](max) NULL
)
GO

