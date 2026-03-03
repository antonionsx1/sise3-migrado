SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Diana Quiroga - MS
-- Alter date: 08/09/2023 
-- Description: Se uliliza para lista los promoventes por asunto
-- Basado en: uspx_getPromoventesPorAsunto
--execute [SISE3].[pcPromoventesXAsunto] 30313784
-- ============================================= 

CREATE OR ALTER PROCEDURE [SISE3].[pcPromoventesXAsunto]
@pi_AsuntoNeunId [bigint]
AS

BEGIN
	SET NOCOUNT ON

	DECLARE @AsuntoId int
	
	SELECT @AsuntoId = AsuntoId
	FROM Asuntos 
	WHERE AsuntoNeunId = @pi_AsuntoNeunId
	/* SE CREA LA TABLA TEMPORAL */
	CREATE TABLE #tmpCatalogo
	(
		ID int,
		DESCRIPCION varchar(255),
		ELEMENTOS int
	)
	--Se insertan los tipos de promovente
	INSERT INTO #tmpCatalogo
	EXEC usp_CatalogosSel 450,0,1

	SELECT DISTINCT  [Promovente].[PromoventeId]  as PersonaId 			 
			,[Promovente].[AsuntoNeunId]
			,[Promovente].[AsuntoId]
			,[Promovente].[PersonaId] as PersonaIdReal
			,[Promovente].[Tipo]
			,TC.DESCRIPCION as PromoventeTipo
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
		INNER JOIN #tmpCatalogo TC ON [Promovente].[Tipo] = TC.ID
		LEFT JOIN [SISE_NEW].[dbo].[DomicilioPromovente]WITH (NOLOCK) on DomicilioPromovente.PromoventeId=Promovente.PromoventeId	  
		WHERE [Estatus] = 1 AND 
			[AsuntoId] = @AsuntoId AND
			[AsuntoNeunId] = @pi_AsuntoNeunId 
		
	DROP TABLE #tmpCatalogo
	SET NOCOUNT OFF
END
