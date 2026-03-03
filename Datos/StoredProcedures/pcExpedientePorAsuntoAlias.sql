USE [SISE_NEW]
GO
/****** Object:  StoredProcedure [SISE3].[pcExpedientePorAsuntoAlias]    Script Date: 01/07/2025 10:22:13 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author: Diana Quiroga 
-- Create date: 13/10/2013
-- Description:	Busca la información principal de un asunto dado un Asunto Alias que tiene promociones asignadas
-- Basado en: uspx_getExpedientePorAsuntoAlias
-- EXEC [SISE3].[pcExpedientePorAsuntoAlias] '334343/2023',1494,NULL, 1, 11896
--  EXEC [SISE3].[pcExpedientePorAsuntoAlias] '1/2024', 180,NULL, 2, null
--  EXEC [SISE3].[pcExpedientePorAsuntoAlias] '1946/2024', 2746, NULL, 4, null
--  Modificación: LAGS 01.07.2024, Se agrega parametro para tomar el NEUN.
--  Modificación: SBGE 06/08/2024, Se agregó modulo 3 para recuperar los expedientes de un organo seleccionado y un 
--				  asuntoalias capturado que esten disponibles (exista en la tabla
--Modificación: INSG 04/09/2024, Se agrego modulo 4 para mostrar tipo procedimiento en tribunales colegiados de apelación.
-- Modificación: LAGS, 07.02.2025, Se quita validación modulo 1, busqueda de expediente para que no muestre registros repetidos.
--EXEC [SISE3].[pcExpedientePorAsuntoAlias] '1/2025', 1495, 18, 1, 384, null, 0
--  Modificación: ARS 30/04/2025, Se agrega el módulo 5 para cuando se busque un expediente basado en el xpediente origen
--  Modificación: ALV 01/06/2025, Se agrega validación al módulo 5 para cuando se busque un expediente basado en el expediente origen
--  Modificación: ARS 09/07/2025, Se ajustó propiedad para permitir la carga de info
-- ==========================================================================================

ALTER PROCEDURE [SISE3].[pcExpedientePorAsuntoAlias]	
	@pi_AsuntoAlias VARCHAR(50),				-- REPRESENTA EL ASUNTO ALIAS POR EL CUAL SE DESEA OBTENER	
	@pi_CatOrganismoId INT,						-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO	
	@pio_CatTipoAsuntoId INT = NULL,			-- REPRESENTA EL IDENTIFICADOR DEL TIPO DE ORGANISMO, PARAMETRO OPCIONAL VALOR NULO POR DEFAULT
	@pi_Modulo INT ,							-- 1 Promocion 2 Tramite 3 Expediente Electrónico(Vincular expediente), 4 Tribunales Colegiados de Apelación
	@pi_CatTipoProcedimiento INT  = NULL,
	@pi_AsuntoNeunId BIGINT = NULL,
	@pi_AsuntoNeunIdDestino BIGINT = NULL
AS
BEGIN
		Declare @TipAsuntoDGAJ int=1011

		IF @pi_Modulo = 1 
		BEGIN
		IF @pi_AsuntoNeunId IS NULL
		BEGIN
			IF @pio_CatTipoAsuntoId IS NULL OR @pio_CatTipoAsuntoId!=@TipAsuntoDGAJ
			BEGIN
					SELECT a.AsuntoNeunId
					, @pi_CatOrganismoId CatOrganismoId 
					, a.AsuntoAlias
					, a.CatTipoAsuntoId
					, a.CatMateriaId
					, a.NumeroOCC
					, ta.Descripcion AS TipoAsunto
					, a.CatTipoProcedimiento AS CatTipoProcedimiento
					, ISNULL(vc.DESCRIPCION, '') AS TipoProcedimiento		
					, a.AsuntoId
					/*,ar.AsuntoNeunIdOrg AS AsuntoNeunIdOrigen--SBGE 22012025
					,aOrigen.AsuntoAlias AS AsuntoAliasOrigen--SBGE 22012025
					,aOrigen.CatTipoAsuntoId AS CatTipoAsuntoIdOrigen--SBGE 22012025
					,aOrigen.CatOrganismoId AS CatOrganismoIdOrigen--SBGE 22012025
					,cato.NombreOficial AS NombreOrganismoOrigen--SBGE 22012025*/
				FROM Asuntos a WITH(NOLOCK)
				INNER JOIN CatTiposAsunto ta  WITH(NOLOCK)
					ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
				LEFT JOIN viCatalogos vc WITH(NOLOCK) 
				ON vc.ID = a.CatTipoProcedimiento
					AND vc.Catalogo IN (464,124,208,1207,734,1933,1892, 2201)
				/*LEFT JOIN AsuntosRelacionados ar on ar.AsuntoNeunIdDest=a.AsuntoNeunId--SBGE 22012025
				LEFT JOIN Asuntos aOrigen on aOrigen.AsuntoNeunId=ar.AsuntoNeunIdOrg--SBGE 22012025
				LEFT JOIN  CatOrganismos cato on cato.CatOrganismoId=aOrigen.CatOrganismoId--SBGE 22012025*/

				WHERE  a.StatusReg = 1
					AND a.CatOrganismoId = @pi_CatOrganismoId
					AND a.AsuntoAlias = @pi_AsuntoAlias
					AND a.CatTipoAsuntoId = ISNULL(@pio_CatTipoAsuntoId,a.CatTipoAsuntoId)
					AND a.CatTipoProcedimiento=ISNULL(@pi_CatTipoProcedimiento,a.CatTipoProcedimiento)
			END
			ELSE			
			BEGIN
				SELECT a.AsuntoNeunId
				, @pi_CatOrganismoId CatOrganismoId 
				, a.AsuntoAlias
				, a.CatTipoAsuntoId
				, a.CatMateriaId
				, a.NumeroOCC
				, ta.Descripcion AS TipoAsunto
				, a.CatTipoProcedimiento AS CatTipoProcedimiento
				, ISNULL(vc.DESCRIPCION, '') AS TipoProcedimiento		
				, a.AsuntoId
				,ar.AsuntoNeunIdOrg AS AsuntoNeunIdOrigen--SBGE 22012025
				,aOrigen.AsuntoAlias AS AsuntoAliasOrigen--SBGE 22012025
				,aOrigen.CatTipoAsuntoId AS CatTipoAsuntoIdOrigen--SBGE 22012025
				,aOrigen.CatOrganismoId AS CatOrganismoIdOrigen--SBGE 22012025
				,cato.NombreOficial AS NombreOrganismoOrigen--SBGE 22012025
					FROM Asuntos a WITH(NOLOCK)
					INNER JOIN CatTiposAsunto ta  WITH(NOLOCK)
						ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
					LEFT JOIN viCatalogos vc WITH(NOLOCK) 
					ON vc.ID = a.CatTipoProcedimiento
						AND vc.Catalogo IN (464,124,208,1207,734,1933,1892, 2201)
					LEFT JOIN AsuntosRelacionados ar on ar.AsuntoNeunIdDest=a.AsuntoNeunId--SBGE 22012025
					LEFT JOIN Asuntos aOrigen on aOrigen.AsuntoNeunId=ar.AsuntoNeunIdOrg--SBGE 22012025
					LEFT JOIN  CatOrganismos cato on cato.CatOrganismoId=aOrigen.CatOrganismoId--SBGE 22012025

					WHERE  a.StatusReg = 1
						AND a.CatOrganismoId = @pi_CatOrganismoId
						AND a.AsuntoAlias = @pi_AsuntoAlias
						AND a.CatTipoAsuntoId = ISNULL(@pio_CatTipoAsuntoId,a.CatTipoAsuntoId)
			END
	
		END
		ELSE

		IF @pio_CatTipoAsuntoId!=@TipAsuntoDGAJ-- diferente a DGAJ
		BEGIN
		SELECT a.AsuntoNeunId
				, @pi_CatOrganismoId CatOrganismoId 
				, a.AsuntoAlias
				, a.CatTipoAsuntoId
				, a.CatMateriaId
				, a.NumeroOCC
				, ta.Descripcion AS TipoAsunto
				, a2.TipoProcedimientoId AS CatTipoProcedimiento
				, a2.TipoProcedimiento AS TipoProcedimiento
				, a.AsuntoId
				--,ar.AsuntoNeunIdOrg AS AsuntoNeunIdOrigen--SBGE 22012025
				--,aOrigen.AsuntoAlias AS AsuntoAliasOrigen--SBGE 22012025
				--,aOrigen.CatOrganismoId AS CatOrganismoIdOrigen--SBGE 22012025
				--,cato.NombreOficial AS NombreOrganismoOrigen--SBGE 22012025	
			FROM Asuntos a WITH(NOLOCK)
			CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunId) a2
			INNER JOIN CatTiposAsunto ta WITH(NOLOCK) ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
			LEFT JOIN (SELECT row = ROW_NUMBER() OVER(PARTITION BY cd.CatalogoDependienteElementoIDNew
							,ceta.CatTipoAsuntoId  ORDER BY cd.CatalogoDependienteElementoIDNew)
							,TipoProcedimiento = ced.CatalogoElementoDescripcion
							,CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew
							,ceta.CatTipoAsuntoId
						FROM dbo.CatalogosDependientes AS cd WITH(NOLOCK)  
						INNER JOIN dbo.CatalogosElementosDescripcion AS ced WITH(NOLOCK)
							ON cd.CatalogoDependienteElementoIDNew = ced.CatalogoElementoDescripcionID
						INNER JOIN CatalogosElementosTiposAsunto ceta WITH(NOLOCK) 
							ON cd.CatalogoDependienteId=ceta.CatalogoId 
							AND cd.CatalogoDependienteElementoIDNew = ceta.CatalogoElementoIdNew
						WHERE cd.CatalogoDependienteId IN (464,124,208,1207,734,1933,1892)
		) ctp 
		ON a.CatTipoProcedimiento = ctp.CatTipoProcedimiento AND a.CatTipoAsuntoId = ctp.CatTipoAsuntoId AND ctp.row = 1

			----LEFT JOIN AsuntosRelacionados ar on ar.AsuntoNeunIdDest=a.AsuntoNeunId--SBGE 22012025
			----LEFT JOIN Asuntos aOrigen on aOrigen.AsuntoNeunId=ar.AsuntoNeunIdOrg--SBGE 22012025
			----LEFT JOIN  CatOrganismos cato on cato.CatOrganismoId=aOrigen.CatOrganismoId--SBGE 22012025
		WHERE  a.StatusReg = 1
			AND a.CatOrganismoId = @pi_CatOrganismoId
			AND a.AsuntoNeunId = @pi_AsuntoNeunId
			AND IIF(ISNULL(@pi_CatTipoProcedimiento, 0) = 0, 0, ctp.CatTipoProcedimiento) = ISNULL(@pi_CatTipoProcedimiento, 0)
		END
		ELSE
		BEGIN
		SELECT a.AsuntoNeunId
				, @pi_CatOrganismoId CatOrganismoId 
				, a.AsuntoAlias
				, a.CatTipoAsuntoId
				, a.CatMateriaId
				, a.NumeroOCC
				, ta.Descripcion AS TipoAsunto
				, a2.TipoProcedimientoId AS CatTipoProcedimiento
				, a2.TipoProcedimiento AS TipoProcedimiento
				, a.AsuntoId
				,ar.AsuntoNeunIdOrg AS AsuntoNeunIdOrigen--SBGE 22012025
				,aOrigen.AsuntoAlias AS AsuntoAliasOrigen--SBGE 22012025
				,aOrigen.CatOrganismoId AS CatOrganismoIdOrigen--SBGE 22012025
				,cato.NombreOficial AS NombreOrganismoOrigen--SBGE 22012025	
			FROM Asuntos a WITH(NOLOCK)
			CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunId) a2
			INNER JOIN CatTiposAsunto ta WITH(NOLOCK) ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
			LEFT JOIN (SELECT row = ROW_NUMBER() OVER(PARTITION BY cd.CatalogoDependienteElementoIDNew
							,ceta.CatTipoAsuntoId  ORDER BY cd.CatalogoDependienteElementoIDNew)
							,TipoProcedimiento = ced.CatalogoElementoDescripcion
							,CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew
							,ceta.CatTipoAsuntoId
						FROM dbo.CatalogosDependientes AS cd WITH(NOLOCK)  
						INNER JOIN dbo.CatalogosElementosDescripcion AS ced WITH(NOLOCK)
							ON cd.CatalogoDependienteElementoIDNew = ced.CatalogoElementoDescripcionID
						INNER JOIN CatalogosElementosTiposAsunto ceta WITH(NOLOCK) 
							ON cd.CatalogoDependienteId=ceta.CatalogoId 
							AND cd.CatalogoDependienteElementoIDNew = ceta.CatalogoElementoIdNew
						WHERE cd.CatalogoDependienteId IN (464,124,208,1207,734,1933,1892)
		) ctp 
		ON a.CatTipoProcedimiento = ctp.CatTipoProcedimiento AND a.CatTipoAsuntoId = ctp.CatTipoAsuntoId AND ctp.row = 1

			LEFT JOIN AsuntosRelacionados ar on ar.AsuntoNeunIdDest=a.AsuntoNeunId--SBGE 22012025
			LEFT JOIN Asuntos aOrigen on aOrigen.AsuntoNeunId=ar.AsuntoNeunIdOrg--SBGE 22012025
			LEFT JOIN  CatOrganismos cato on cato.CatOrganismoId=aOrigen.CatOrganismoId--SBGE 22012025
		WHERE  a.StatusReg = 1
			AND a.CatOrganismoId = @pi_CatOrganismoId
			AND a.AsuntoNeunId = @pi_AsuntoNeunId
			AND IIF(ISNULL(@pi_CatTipoProcedimiento, 0) = 0, 0, ctp.CatTipoProcedimiento) = ISNULL(@pi_CatTipoProcedimiento, 0)
		END

			
	END 
	ELSE 
	IF @pi_Modulo = 3--SBGE 06/08/2024  Módulo Expediente Electrónico 
	BEGIN
		SELECT a.AsuntoNeunId
			, @pi_CatOrganismoId CatOrganismoId 
			, a.AsuntoAlias
			, a.CatTipoAsuntoId
			, a.CatMateriaId
			, a.NumeroOCC
			, ta.Descripcion AS TipoAsunto
			, a2.TipoProcedimientoId AS CatTipoProcedimiento
			, a2.TipoProcedimiento AS TipoProcedimiento
			, a.AsuntoId
		FROM Asuntos a WITH(NOLOCK)
		CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunId) a2
		INNER JOIN CatTiposAsunto ta  WITH(NOLOCK) 
		ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId		
		LEFT JOIN (SELECT row = ROW_NUMBER() OVER(PARTITION BY cd.CatalogoDependienteElementoIDNew
						,ceta.CatTipoAsuntoId  ORDER BY cd.CatalogoDependienteElementoIDNew)
						,TipoProcedimiento = ced.CatalogoElementoDescripcion
						,CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew
						,ceta.CatTipoAsuntoId
					FROM dbo.CatalogosDependientes AS cd WITH(NOLOCK)  
					INNER JOIN dbo.CatalogosElementosDescripcion AS ced WITH(NOLOCK)
						ON cd.CatalogoDependienteElementoIDNew = ced.CatalogoElementoDescripcionID
					INNER JOIN CatalogosElementosTiposAsunto ceta WITH(NOLOCK) 
						ON cd.CatalogoDependienteId=ceta.CatalogoId 
						AND cd.CatalogoDependienteElementoIDNew = ceta.CatalogoElementoIdNew
					WHERE cd.CatalogoDependienteId IN (464,124,208,1207,734,1933,1892)
		) ctp 
		ON a.CatTipoProcedimiento = ctp.CatTipoProcedimiento 
			AND a.CatTipoAsuntoId = ctp.CatTipoAsuntoId 
			AND ctp.row = 1
		INNER JOIN AsuntosRelacionados ar 
		ON a.AsuntoNeunId = ar.AsuntoNeunIdOrg 
			AND ar.Status = 1 
			AND ar.AsuntoNeunIdDest = 0
		WHERE  a.StatusReg = 1
		AND a.CatOrganismoId = @pi_CatOrganismoId
		AND a.AsuntoAlias = @pi_AsuntoAlias
		AND a.CatTipoAsuntoId = ISNULL(@pio_CatTipoAsuntoId,a.CatTipoAsuntoId)
		AND IIF(ISNULL(@pi_CatTipoProcedimiento, 0) = 0, 0, ctp.CatTipoProcedimiento) = ISNULL(@pi_CatTipoProcedimiento, 0)
		AND NOT EXISTS (SELECT IdAsuntoRela FROM AsuntosRelacionados WHERE AsuntoNeunIdOrg = a.AsuntoNeunId AND AsuntoNeunIdDest = @pi_AsuntoNeunIdDestino AND Status = 1)--Si el expediente disponible ya esta relacionado con el expediente destino ya no se lista
		AND a.AsuntoNeunId != @pi_AsuntoNeunIdDestino				--No se muestra el mismo asunto destino, ya que no se puede relacionar un asunto con el mismo
	END
	ELSE

	IF @pi_Modulo = 4 --INSG 04/09/2024 Tribunales Colegiados de Apelación - Se agrega opción para devolver tipo de procedimiento para TCA
	BEGIN
	IF @pi_AsuntoNeunId IS NULL
		BEGIN
			SELECT a.AsuntoNeunId
				, @pi_CatOrganismoId CatOrganismoId 
				, a.AsuntoAlias
				, a.CatTipoAsuntoId
				, a.CatMateriaId
				, a.NumeroOCC
				, ta.Descripcion AS TipoAsunto
				, a.CatTipoProcedimiento AS CatTipoProcedimiento
				, ISNULL(vc.DESCRIPCION, '') AS TipoProcedimiento	
				, a.AsuntoId
			FROM Asuntos a WITH(NOLOCK) 
			CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunId) a2
			LEFT JOIN [SISE_NEW].[dbo].[MapeoCamposTipoProcedimiento_TU_TCA] mctp 
			ON a2.CatTipoProcedimiento = mctp.CatalogoDependienteElementoIdNew
			INNER JOIN CatTiposAsunto ta WITH(NOLOCK) 
			ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
			LEFT JOIN viCatalogos vc WITH(NOLOCK) 
			ON vc.ID = a.CatTipoProcedimiento
				AND vc.Catalogo IN (464, 124, 208, 1207, 734, 1933, 1892, 2201)
			WHERE  a.StatusReg = 1
				AND a.CatOrganismoId = @pi_CatOrganismoId
				AND a.AsuntoAlias = @pi_AsuntoAlias
				AND a.CatTipoAsuntoId = ISNULL(@pio_CatTipoAsuntoId, a.CatTipoAsuntoId)
		END
		ELSE
			SELECT a.AsuntoNeunId
			, @pi_CatOrganismoId CatOrganismoId 
			, a.AsuntoAlias
			, a.CatTipoAsuntoId
			, a.CatMateriaId
			, a.NumeroOCC
			, ta.Descripcion AS TipoAsunto
			, mctp.CatalogoDependienteElementoIdNew AS CatTipoProcedimiento
			, mctp.CatalogoDependienteDescripcionNew AS TipoProcedimiento
		FROM Asuntos a WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunId) a2
		LEFT JOIN [SISE_NEW].[dbo].[MapeoCamposTipoProcedimiento_TU_TCA] mctp 
		ON a2.CatTipoProcedimiento = mctp.CatalogoDependienteElementoIdNew
		INNER JOIN CatTiposAsunto ta WITH(NOLOCK) 
			ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
		LEFT JOIN (SELECT row = ROW_NUMBER() OVER(PARTITION BY cd.CatalogoDependienteElementoIDNew
						,ceta.CatTipoAsuntoId  ORDER BY cd.CatalogoDependienteElementoIDNew)
						,TipoProcedimiento = ced.CatalogoElementoDescripcion
						,CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew
						,ceta.CatTipoAsuntoId
					FROM dbo.CatalogosDependientes AS cd WITH(NOLOCK)  
					INNER JOIN dbo.CatalogosElementosDescripcion AS ced WITH(NOLOCK)
						ON cd.CatalogoDependienteElementoIDNew = ced.CatalogoElementoDescripcionID
					INNER JOIN CatalogosElementosTiposAsunto ceta WITH(NOLOCK) 
						ON cd.CatalogoDependienteId=ceta.CatalogoId 
						AND cd.CatalogoDependienteElementoIDNew = ceta.CatalogoElementoIdNew
					WHERE cd.CatalogoDependienteId IN (464,124,208,1207,734,1933,1892)
		) ctp 
			ON a.CatTipoProcedimiento = ctp.CatTipoProcedimiento 
			AND a.CatTipoAsuntoId = ctp.CatTipoAsuntoId 
			AND ctp.row = 1
		WHERE  a.StatusReg = 1
		AND a.CatOrganismoId = @pi_CatOrganismoId
		AND a.AsuntoNeunId = @pi_AsuntoNeunId
		AND IIF(ISNULL(@pi_CatTipoProcedimiento,0)=0,0,ctp.CatTipoProcedimiento) = ISNULL(@pi_CatTipoProcedimiento,0)
	END
	ELSE
	IF @pi_Modulo = 5 --ARS 29/04/2025 Se agregó una validación para la búsqueda por asuntoNeunDestino
		BEGIN
			SELECT TOP(1) 
				aD.AsuntoNeunId, 
				aD.CatOrganismoId, 
				aD.AsuntoAlias, 
				aD.CatTipoAsuntoId, 
				aD.CatMateriaId, 
				aD.NumeroOCC, 
				ta.Descripcion AS TipoAsunto, 
				aD.CatTipoProcedimiento AS CatTipoProcedimiento, 
				ISNULL(vc.DESCRIPCION, '') AS TipoProcedimiento, 
				aD.AsuntoId
				FROM Asuntos aO WITH(NOLOCK)
				LEFT JOIN viCatalogos vc WITH(NOLOCK) 
					ON vc.ID = aO.CatTipoProcedimiento
					AND vc.Catalogo IN (464,124,208,1207,734,1933,1892, 2201)
				LEFT JOIN AsuntosRelacionados ar on ar.AsuntoNeunIdOrg=aO.AsuntoNeunId--SBGE 22012025
				LEFT JOIN Asuntos aD on aD.AsuntoNeunId=ar.AsuntoNeunIdDest--SBGE 22012025
				INNER JOIN CatTiposAsunto ta  WITH(NOLOCK)
					ON aD.CatTipoAsuntoId = ta.CatTipoAsuntoId

				WHERE  aO.StatusReg = 1
					AND aO.AsuntoNeunId = @pi_AsuntoNeunIdDestino
					AND aO.FechaBaja IS NULL --ALV 01/07/2025 Se agregan validaciones para recuperar el expediente relacionado cuando el status = 1
					AND aD.CatOrganismoId = @pi_CatOrganismoId
		END
	ELSE
	BEGIN
		/*Cargar Asuntos Documentos que no tienen promoción*/
		CREATE TABLE #MaxSec
		(AsuntoNeunId BIGINT, 
			Expediente VARCHAR(50) collate SQL_Latin1_General_CP850_CI_AI, 
			Mesa varchar(15),
			Id int 
		)


		INSERT INTO #MaxSec
		SELECT p.AsuntoNeunId, 
		aa.AsuntoAlias ,
		p.Mesa,
		ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, aa.AsuntoAlias ORDER BY CAST(CONCAT(CONVERT(VARCHAR,p.FechaPresentacion,112),' ',p.HoraPresentacion) AS DATETIME) DESC) AS id
		FROM Promociones p WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) aa
		INNER JOIN CatTiposAsunto ta WITH(NOLOCK) ON aa.CatTipoAsuntoId = ta.CatTipoAsuntoId
		LEFT JOIN PromocionArchivos pa WITH(NOLOCK) ON pa.AsuntoNeunId = p.AsuntoNeunId
													AND pa.CatOrganismoId = p.CatOrganismoId 
													AND pa.NumeroOrden = p.NumeroOrden
													AND pa.Origen = p.OrigenPromocion 
													AND pa.YearPromocion = p.YearPromocion
													AND pa.StatusArchivo = 1
													AND pa.ClaseAnexo = 0
		WHERE p.StatusReg = 1 
		AND aa.AsuntoAlias = @pi_AsuntoAlias
		AND aa.CatOrganismoId = @pi_CatOrganismoId
		AND aa.CatTipoAsuntoId = ta.CatTipoAsuntoId

		SELECT a.AsuntoNeunId
			, @pi_CatOrganismoId CatOrganismoId
			, a.AsuntoAlias
			, a.CatTipoAsuntoId
			, a.CatMateriaId
			, a.NumeroOCC
			, ta.Descripcion as TipoAsunto
			, a.CatTipoProcedimiento AS CatTipoProcedimiento
			, ISNULL(vc.DESCRIPCION, '') AS TipoProcedimiento
			, m.Mesa
			, a.AsuntoId
		FROM Asuntos a WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(a.AsuntoNeunId) a2
		INNER JOIN CatTiposAsunto ta WITH(NOLOCK) 
			ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId
		LEFT JOIN #MaxSec m ON  a.AsuntoNeunId = m.AsuntoNeunId AND a.AsuntoAlias = m.Expediente AND m.id = 1
		LEFT JOIN viCatalogos vc WITH(NOLOCK) 
		ON vc.ID = a.CatTipoProcedimiento
			AND vc.Catalogo IN (464,124,208,1207,734,1933,1892, 2201)
		WHERE a.CatOrganismoId = @pi_CatOrganismoId
		AND a.AsuntoAlias = @pi_AsuntoAlias
		AND a.CatTipoAsuntoId = ISNULL(@pio_CatTipoAsuntoId,a.CatTipoAsuntoId)
		AND a.StatusReg = 1
	END
END