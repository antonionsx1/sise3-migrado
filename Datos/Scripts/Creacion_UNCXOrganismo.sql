USE [SISE_NEW]
GO

/****** Object:  Table [SISE3].[PromocionPromoventeParte]    Script Date: 11/28/2023 4:41:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [SISE3].[UNCXOrganismo](
	[IdUNC] [int] IDENTITY(1,1) NOT NULL,
	[CatOrganismoId] [int] NOT NULL,
	[FechaAlta] [datetime] NULL,
	[FechaBaja] [datetime] NULL,
	[StatusReg] [smallint] NULL,
	[Descripcion] [VARCHAR] (150) NULL
) ON [PRIMARY]
GO
ALTER TABLE [SISE3].[UNCXOrganismo]
ADD CONSTRAINT [FK_CatOrganismoId] FOREIGN KEY ( [CatOrganismoId]) REFERENCES [dbo]. [CatOrganismos] 

INSERT INTO SISE3.UNCXOrganismo (CatOrganismoId, FechaAlta, StatusReg, Descripcion)
VALUES (180,GETDATE(),1, 'Unidad notificadora Comun Organismo 180')
SELECT * FROM SISE3.UNCXOrganismo