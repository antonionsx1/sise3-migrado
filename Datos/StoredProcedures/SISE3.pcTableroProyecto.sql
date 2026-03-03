SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author: Mario A Hernández Román
-- Create date: 06/03/2024
-- Description:	Realiza el conteo y registros de Módulo Proyecto
-- Version: 1.3
--	06/03/2024 - Datos Dummy
--	11/03/2024 - Se implementan conexiones con bases de datos
--  12/03/2024 - Se coloca como funcion SISE3.fnTableroProyectoTienenAudiencia
--							 para obtener registros con Celebreda la Audiencia Constitucional
--						 - Se implementa busqueda por texto
--  13/03/2024 - Actualiza [SISE3].[fnTableroProyectoV3] para retirar Tabla Proyecto
--						 - Se agrega funcionalidad Ordenamiento y paginado
--  14/03/2024 - Se agregan columnas de TipoCuaderno y sTipocuaderno.
--						 - Se agregan opciones de ordenamiento. 
-- EXEC [SISE3].[pcTableroProyecto] 180, 50, 1, '2024-03-06', '2024-03-12', NULL, NULL, 'Secretario', 0, 0
-- =============================================

CREATE OR ALTER PROCEDURE [SISE3].[pcTableroProyecto](
	@pi_CatOrganismoId INT,	
	@pi_TamanoPagina INT=2,
	@pi_NumeroPagina INT=1,
	@pi_FechaPresentacionIni DATE=NULL,
	@pi_FechaPresentacionFin DATE=NULL,
	@pi_UsuariId INT=NULL,
	@pi_Texto VARCHAR(MAX)=NULL,
	@pi_OrdenarPor VARCHAR(128)=NULL,
	@pi_TipoOrden INT=NULL,  -- 0 = Ascendente y 1 = Descendente 
	@pi_FiltroTipo INT=0
) AS BEGIN

	IF @pi_OrdenarPor IS NOT NULL BEGIN
		SET @pi_OrdenarPor = LTRIM(RTRIM(@pi_OrdenarPor))
	END

	SET @pi_FiltroTipo = ISNULL(@pi_FiltroTipo, -1) 
	IF @pi_FiltroTipo NOT IN (1, 2, 3, 4, 5) BEGIN
		SET @pi_FiltroTipo = 0
	END

	DECLARE @TotalProyectos INT
	DECLARE @TotalSinProyecto INT
	DECLARE @TotalParaRevision INT
	DECLARE @TotalNoAprobado INT
	DECLARE @TotalConAjustes INT
	DECLARE @TotalAprobado INT 

	DECLARE @pi_Estados VARCHAR(30) 

	DECLARE @TableroProyecto SISE3.TableroProyecto_type
	
	-- Conteo Sin proyecto
	SET @pi_Estados = '1'
	SET @TotalSinProyecto = (
		SELECT 
			COUNT(ftp.AsuntoNeunId) 
		FROM 
			[SISE3].[fnTableroProyectoV3](	
				@pi_CatOrganismoId,
				@pi_Estados,
				@pi_Texto,
				@pi_FechaPresentacionIni,
				@pi_FechaPresentacionFin
			) ftp
	)

	-- Conteo Para revision
	SET @pi_Estados = '2'
	SET @TotalParaRevision = (
		SELECT 
			COUNT(AsuntoNeunId)
		FROM 
			[SISE3].[fnTableroProyectoV3](	
				@pi_CatOrganismoId,
				@pi_Estados,
				@pi_Texto,
				@pi_FechaPresentacionIni,
				@pi_FechaPresentacionFin
			)
	)

	-- Conteo No aprobados
	SET @pi_Estados = '3'
	SET @TotalNoAprobado = (
		SELECT 
			COUNT(AsuntoNeunId)
		FROM 
			[SISE3].[fnTableroProyectoV3](	
				@pi_CatOrganismoId,
				@pi_Estados,
				@pi_Texto,
				@pi_FechaPresentacionIni,
				@pi_FechaPresentacionFin
			)
	)

	-- Conteo Con Ajuste de Fondo y Forma
	SET @pi_Estados = '4,5'
	SET @TotalConAjustes = (
		SELECT 
			COUNT(AsuntoNeunId)
		FROM 
			[SISE3].[fnTableroProyectoV3](	
				@pi_CatOrganismoId,
				@pi_Estados,
				@pi_Texto,
				@pi_FechaPresentacionIni,
				@pi_FechaPresentacionFin
			)
	)

	-- Conteo Aprobados
	SET @pi_Estados = '6'
	SET @TotalAprobado = (
		SELECT 
			COUNT(AsuntoNeunId)
		FROM 
			[SISE3].[fnTableroProyectoV3](	
				@pi_CatOrganismoId,
				@pi_Estados,
				@pi_Texto,
				@pi_FechaPresentacionIni,
				@pi_FechaPresentacionFin
			)
	)

	-- Conteo Total
	SET @pi_Estados = '1,2,3,4,5,6'
	SET @TotalProyectos = (	
		SELECT 
			COUNT(ftp.AsuntoNeunId) 
		FROM 
			[SISE3].[fnTableroProyectoV3](	
				@pi_CatOrganismoId,
				@pi_Estados,
				@pi_Texto,
				@pi_FechaPresentacionIni,
				@pi_FechaPresentacionFin
			) ftp
	)

	-- Conteos de los agrupadores
	SELECT 
		@TotalProyectos AS totalProyectos, 
		@TotalSinProyecto AS totalSinProyecto, 
		@TotalParaRevision AS totalParaRevision, 
		@TotalNoAprobado AS totalNoAprobado,
		@TotalConAjustes AS totalConAjustes, 
		@TotalAprobado AS totalAprobado
	
	-- Sin proyecto
	IF (@pi_FiltroTipo = 1) BEGIN
		SET @pi_Estados = '1'
		INSERT INTO @TableroProyecto
			SELECT 
				*
			FROM 
				[SISE3].[fnTableroProyectoV3](	
					@pi_CatOrganismoId,
					@pi_Estados,
					@pi_Texto,
					@pi_FechaPresentacionIni,
					@pi_FechaPresentacionFin
				) ftp
	END

	-- Para revision
	IF (@pi_FiltroTipo = 2) BEGIN
		SET @pi_Estados = '2'
		INSERT INTO @TableroProyecto
			SELECT 
				*
			FROM 
				[SISE3].[fnTableroProyectoV3](	
					@pi_CatOrganismoId,
					@pi_Estados,
					@pi_Texto,
					@pi_FechaPresentacionIni,
					@pi_FechaPresentacionFin
				) ftp
	END

	-- No aprobados
	IF (@pi_FiltroTipo = 3) BEGIN
		SET @pi_Estados = '3'
		INSERT INTO @TableroProyecto
			SELECT 
				*
			FROM 
				[SISE3].[fnTableroProyectoV3](	
					@pi_CatOrganismoId,
					@pi_Estados,
					@pi_Texto,
					@pi_FechaPresentacionIni,
					@pi_FechaPresentacionFin
				) ftp
	END

	-- Con Ajuste de Fondo y Forma
	IF (@pi_FiltroTipo = 4) BEGIN
		SET @pi_Estados = '4,5'
		INSERT INTO @TableroProyecto
			SELECT 
				*
			FROM 
				[SISE3].[fnTableroProyectoV3](	
					@pi_CatOrganismoId,
					@pi_Estados,
					@pi_Texto,
					@pi_FechaPresentacionIni,
					@pi_FechaPresentacionFin
				) ftp

	END

	-- Aprobados
	IF (@pi_FiltroTipo = 5) BEGIN
		SET @pi_Estados = '6'
		INSERT INTO @TableroProyecto
			SELECT 
				*
			FROM 
				[SISE3].[fnTableroProyectoV3](	
					@pi_CatOrganismoId,
					@pi_Estados,
					@pi_Texto,
					@pi_FechaPresentacionIni,
					@pi_FechaPresentacionFin
				) ftp
	END

	-- Todos los proyectos
	IF (@pi_FiltroTipo = 0) BEGIN
		SET @pi_Estados = '1,2,3,4,5,6'
		INSERT INTO @TableroProyecto
			SELECT 
				*
			FROM 
				[SISE3].[fnTableroProyectoV3](	
					@pi_CatOrganismoId,
					@pi_Estados,
					@pi_Texto,
					@pi_FechaPresentacionIni,
					@pi_FechaPresentacionFin
				) ftp
			ORDER BY 
				EstadoProyecto
	END

	-- Ordenamiento y paginado
	SELECT 
		* 
	FROM 
		@TableroProyecto
	ORDER BY
		CASE WHEN @pi_OrdenarPor = 'asuntoAlias' AND @pi_TipoOrden = 0 THEN 
			NumeroAlias 
		END ASC,
		CASE WHEN @pi_OrdenarPor = 'asuntoAlias' AND @pi_TipoOrden = 1 THEN 
			NumeroAlias 
		END DESC,
		CASE WHEN @pi_OrdenarPor = 'fechaAudiencia' AND @pi_TipoOrden = 0 THEN 
			FechaAudiencia 
		END ASC,
		CASE WHEN @pi_OrdenarPor = 'fechaAudiencia' AND @pi_TipoOrden = 1 THEN
			FechaAudiencia 
		END DESC,
		CASE WHEN @pi_OrdenarPor = 'secretario' AND @pi_TipoOrden = 0 THEN 
			Secretario 
		END ASC,
		CASE WHEN @pi_OrdenarPor = 'secretario' AND @pi_TipoOrden = 1 THEN
			Secretario 
		END DESC,
		CASE WHEN @pi_OrdenarPor = 'fechaCargaProyecto' AND @pi_TipoOrden = 0 THEN 
			FechaCargaProyecto 
		END ASC,
		CASE WHEN @pi_OrdenarPor = 'fechaCargaProyecto' AND @pi_TipoOrden = 1 THEN
			FechaCargaProyecto 
		END DESC,
		CASE WHEN @pi_OrdenarPor = 'estadoProyecto' AND @pi_TipoOrden = 0 THEN 
			EstadoProyecto 
		END ASC,
		CASE WHEN @pi_OrdenarPor = 'estadoProyecto' AND @pi_TipoOrden = 1 THEN
			EstadoProyecto 
		END DESC,
		CASE WHEN @pi_OrdenarPor = 'NumeroVersionProyecto' AND @pi_TipoOrden = 0 THEN 
			NumeroVersionProyecto 
		END ASC,
		CASE WHEN @pi_OrdenarPor = 'NumeroVersionProyecto' AND @pi_TipoOrden = 1 THEN
			NumeroVersionProyecto 
		END DESC,
		CASE WHEN @pi_OrdenarPor = 'descripcionSentido' AND @pi_TipoOrden = 0 THEN 
			sSentido 
		END ASC,
		CASE WHEN @pi_OrdenarPor = 'descripcionSentido' AND @pi_TipoOrden = 1 THEN
			sSentido 
		END DESC,
		CASE WHEN @pi_OrdenarPor IS NULL THEN 
			EstadoProyecto
		END
	OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
	FETCH NEXT IIF(@pi_TamanoPagina=0, 0x7ffffff, @pi_TamanoPagina) ROWS ONLY

END;