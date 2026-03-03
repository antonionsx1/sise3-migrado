USE [SISE_NEW]
GO

/****** Object:  Table [SISE3].[OtrasPartesAsunto_Adicional]    Script Date: 11/06/2025 03:59:25 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [SISE3].[OtrasPartesAsunto_Adicional](
	[PersonaOtrasPartesId] [bigint] IDENTITY(1,1) NOT NULL,
	[AsuntoNeunId] [bigint] NOT NULL,
	[iAsuntoId] [int] NOT NULL,
	[iPersonaId] [bigint] NOT NULL,
	[iTipoNotificacionId] [int] NOT NULL,
	[fFechaAlta] [datetime] NULL,
	[fFechaBaja] [datetime] NULL,
	[bStatusReg] [bit] NOT NULL,
	[UsuarioCaptura] [bigint] NOT NULL,
 CONSTRAINT [PK_SISE3.OtrasPartesAsunto_Adicional] PRIMARY KEY CLUSTERED 
(
	[PersonaOtrasPartesId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto_Adicional] ADD  CONSTRAINT [DF__OtrasPartesAdicional___Fecha]  DEFAULT (getdate()) FOR [fFechaAlta]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto_Adicional]  WITH NOCHECK ADD  CONSTRAINT [FK_OtrasPartesAsuntoAdic_Notificaciones] FOREIGN KEY([iTipoNotificacionId])
REFERENCES [dbo].[CatNotificaciones] ([kIdCatNotificaciones])
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto_Adicional] NOCHECK CONSTRAINT [FK_OtrasPartesAsuntoAdic_Notificaciones]
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto_Adicional]  WITH NOCHECK ADD  CONSTRAINT [FK_OtrasPartesAsuntoAdic_Persona] FOREIGN KEY([iPersonaId])
REFERENCES [SISE3].[OtrasPartesAsunto] ([iPersonaId])
GO

ALTER TABLE [SISE3].[OtrasPartesAsunto_Adicional] NOCHECK CONSTRAINT [FK_OtrasPartesAsuntoAdic_Persona]
GO


