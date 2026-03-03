USE [SISE_NEW]
GO

/****** Object:  StoredProcedure [SISE3].[pcPomoventesXAsunto]    Script Date: 10/12/2023 1:36:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ============================================= 
-- Author: Diana Quiroga - MS
-- Alter date: 08/09/2023 
-- Description: Se uliliza para lista los promoventes por asunto
-- Basado en: uspx_getPromoventesPorAsunto
--execute [SISE3].[pcPomoventesXAsunto] 1153425
-- ============================================= 

CREATE PROCEDURE [SISE3].[pcPomoventesXAsunto]
@pi_AsuntoNeunId [bigint]
AS

BEGIN
	SET NOCOUNT ON

	DECLARE @AsuntoId int
	
	SELECT @AsuntoId = AsuntoId
	FROM Asuntos 
	WHERE AsuntoNeunId = @pi_AsuntoNeunId


	SELECT DISTINCT  [Promovente].[PromoventeId]  as PersonaId 			 
			,[Promovente].[AsuntoNeunId]
			,[Promovente].[AsuntoId]
			,[Promovente].[PersonaId] as PersonaIdReal
			,[Promovente].[Tipo]
			,[Promovente].[Nombre]
			,[Promovente].[APaterno]
			,[Promovente].[AMaterno]
			,[Promovente].[Sexo]
			,[Promovente].[FechaNacimiento]
			,[Promovente].[TipoIdentificador]
			,[Promovente].[Email]
			,[Promovente].[Uso]
			,[Promovente].[Estatus]
			,[Promovente].[RegistroEmpleadoId]
			,[Promovente].[FechaCaptura]
			,[DomicilioPromovente].CalleNumero
			,[DomicilioPromovente].CodigoPostal
			,[DomicilioPromovente].Colonia
			,[DomicilioPromovente].PromoventeId
			,EsInterconexion = ((SELECT COUNT(*) 
								FROM PromoventeInterconexion pin 
								WHERE pin.AsuntoNeunId= @pi_AsuntoNeunId
								AND	 pin.PromoventeId = Promovente.PromoventeId))
		FROM [SISE_NEW].[dbo].[Promovente]  WITH (NOLOCK)
		LEFT JOIN [SISE_NEW].[dbo].[DomicilioPromovente]WITH (NOLOCK) on DomicilioPromovente.PromoventeId=Promovente.PromoventeId	  
		WHERE [Estatus] = 1 AND 
			[AsuntoId] = @AsuntoId AND
			[AsuntoNeunId] = @pi_AsuntoNeunId 
		
		SET NOCOUNT OFF
END
GO

