USE SISE_NEW
GO

CREATE TABLE [SISE3].[EquivalenciasIDs]
	(
	EquivalenciaId int NOT NULL IDENTITY (1, 1),
	CatTipoAsuntoId int NOT NULL,
	CatTipoOrganismoId int NOT NULL,
	IdAsuntoBase int NOT NULL,
	IdPadreBase int NOT NULL,
	IdAsuntoEquivalente int NOT NULL,
	IdPadreEquivalente int NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE [SISE3].[EquivalenciasIDs] ADD CONSTRAINT
	[PK_SISE3]].[EquivalenciasIDs] PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO