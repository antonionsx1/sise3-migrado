USE [SISE_NEW]
GO

/****** Object:  UserDefinedTableType [SISE3].[PromocionesAcuerdo_type]    Script Date: 12/1/2023 6:31:19 PM ******/
CREATE TYPE [SISE3].[PromocionesAcuerdo_type] AS TABLE(
	[NumeroOrden] [int] NULL,
	[YearPromocion] [int] NULL,
	[EstadoPromocionId] [int] NULL,
	[Proceso] [smallint] NULL
)
GO

