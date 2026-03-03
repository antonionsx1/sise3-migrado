USE [SISE_NEW]
GO

/****** Object:  Table [SISE3].[OtrasPartesAsunto]    Script Date: 11/06/2025 03:54:55 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [SISE3].[OtrasPartesAsunto](
	[iPersonaId] [bigint] IDENTITY(1,1) NOT NULL,
	[AsuntoId] [int] NOT NULL,
	[AsuntoNeunId] [bigint] NOT NULL,
	[sNombre] [varchar](500) NOT NULL,
	[sAPaterno] [varchar](50) NULL,
	[sAMaterno] [varchar](50) NULL,
	[CatTipoPersonaId] [smallint] NULL,
	[iSexo] [int] NULL,
	[iMayorEdad] [int] NULL,
	[CatTipoPersonaJuridicaId] [smallint] NULL,
	[sDenominacionDeAutoridad] [varchar](255) NULL,
	[ClasificaAutoridadGenericaId] [smallint] NULL,
	[iSujetoDerechoAgrario] [int] NULL,
	[iAceptaOponePublicarDatos] [int] NOT NULL,
	[fFechaAceptaOponePublicarDatos] [datetime] NULL,
	[fFechaAlta] [datetime] NOT NULL,
	[fFechaBaja] [datetime] NULL,
	[StatusReg] [smallint] NOT NULL,
	[iForaneo] [int] NOT NULL,
	[iCatAutoridadId] [int] NULL,
	[iUsuarioCaptura] [bigint] NULL,
	[iEsParteGrupoVulnerable] [int] NULL,
	[iGrupoVulnerable] [int] NULL,
	[iEdadMenor] [smallint] NULL,
	[iHablaLengua] [smallint] NULL,
	[iLengua] [int] NULL,
	[iTraductor] [smallint] NULL,
 CONSTRAINT [PK_PERSONASASUNTO] PRIMARY KEY CLUSTERED 
(
	[iPersonaId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto] ADD  CONSTRAINT [DF__OtrasPartesA___Fecha]  DEFAULT (getdate()) FOR [fFechaAlta]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto] ADD  CONSTRAINT [DF__OtrasPartesA___Statu]  DEFAULT ((1)) FOR [StatusReg]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto] ADD  CONSTRAINT [DF_OtrasPartesA__CatAutoridadId]  DEFAULT ((0)) FOR [iCatAutoridadId]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto]  WITH NOCHECK ADD  CONSTRAINT [FK_OtrasPartesAsunto_CatTipoPerJuridica] FOREIGN KEY([CatTipoPersonaJuridicaId])
REFERENCES [dbo].[CatTipoPersonaJuridicaNew] ([CatTipoPerJuridicaId])
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto] NOCHECK CONSTRAINT [FK_OtrasPartesAsunto_CatTipoPerJuridica]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto]  WITH NOCHECK ADD  CONSTRAINT [FK_OtrasPartesAsunto_ClasificaAutoridad] FOREIGN KEY([ClasificaAutoridadGenericaId])
REFERENCES [dbo].[CatClasificaAutoridadGenerica] ([ClasificaAutoridadGenericaId])
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto] NOCHECK CONSTRAINT [FK_OtrasPartesAsunto_ClasificaAutoridad]
GO


