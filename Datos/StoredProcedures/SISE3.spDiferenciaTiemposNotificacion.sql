USE [SISE_NEW]
GO

-- =====================================================================================
-- Proyecto: SISE3
-- Autor: Erick Gonzalez
-- Modificado:  2025-01-03 - MTS - Se optimiza consulta
-- Creado: [2024-06-07]
-- Procedimiento Almacenado: spDiferenciaTiemposNotificacion
-- Descripción: Obtener la información de notificaciones electrónicas
--              para un actuario específico dentro de un rango de fechas. Calcula la
--              diferencia en días entre la fecha de asignación y la fecha de notificación,
--              y también incluye el día del mes de ambas fechas.
--EXEC:	EXEC [SISE3].[spDiferenciaTiemposNotificacion] 147, 57615, '2020-01-01', '2024-08-06'
-- =====================================================================================

ALTER PROCEDURE [SISE3].[spDiferenciaTiemposNotificacion]
    @pi_CatOrganismoId INT,				-- Identificador del organismo
    @EmpleadoId BIGINT,
    @fechaInicio DATETIME,
    @fechaFin DATETIME,
    @is_Coordinador BIT	= 0,			-- Bandera para determinar si es Coordinador
    @is_OtrosUsuarios BIT = 0			-- Bandera para determinar si es OtrosUsuarios
AS
BEGIN
    SET NOCOUNT ON;

	--Actuario
    SELECT DISTINCT
        a.AsuntoAlias,
		CASE 
			WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO
			WHEN @is_Coordinador = 0 THEN nep.IdUsuarioNotifico
		END								AS IdUsuarioNotifico,
        neaa.FECHAUSUARIOASIGNO AS FechaAsigna,
        nep.FechaNotificacion AS FechaNotifica, 
		DiaAsigna		= DAY(CASE WHEN ISNULL(ap.EsCoordinador,0) = 1 THEN ad.FECHAAUTORIZA ELSE neaa.FECHAUSUARIOASIGNO END),
	    DiaNotifica		= DAY(CASE WHEN ISNULL(ap.EsCoordinador,0) = 1 THEN neaa.FECHAUSUARIOASIGNO ELSE nep.FechaNotificacion END),
	    DiferenciaDias	= DATEDIFF(DAY, CASE WHEN ISNULL(ap.EsCoordinador,0) = 1 THEN ad.FECHAAUTORIZA ELSE neaa.FECHAUSUARIOASIGNO END
								, CASE WHEN ISNULL(ap.EsCoordinador,0) = 1 THEN neaa.FECHAUSUARIOASIGNO ELSE nep.FechaNotificacion END),
		cd.NombreCorto,
		cd.CatalogoDependienteDescripcion,
		ax.Folio
    FROM NotificacionElectronica_Personas nep WITH(NOLOCK)
    INNER JOIN Asuntos a WITH(NOLOCK) ON nep.AsuntoNeunId = a.AsuntoNeunId 
	INNER JOIN AsuntosDocumentos ad WITH (NOLOCK) ON ad.AsuntoID = nep.AsuntoId AND ad.AsuntoNeunId = nep.AsuntoNeunId AND ad.SintesisOrden = nep.SintesisOrden
	LEFT JOIN NotificacionElectronica_AsignaActuario neaa WITH (NOLOCK) ON nep.AsuntoNeunId = neaa.AsuntoNeunId AND nep.SintesisOrden = neaa.SintesisOrden AND nep.NotElecId = neaa.NotElecId AND neaa.IESTATUSREG = 1
	LEFT JOIN Anexos ax WITH (NOLOCK) ON nep.PersonaId = ax.AnexoParteId AND ad.AsuntoDocumentoId = ax.AsuntoDocumentoId AND ax.AnexoTipoId IN (1, 6)
	LEFT JOIN (
		SELECT t.* 
		FROM (
			SELECT ArchivoId, NotElecId, FechaAlta,ROW_NUMBER() OVER (PARTITION BY NotElecId ORDER BY FECHAALTA DESC) rn
			FROM NotificacionElectronica_Archivos WITH(NOLOCK)
		) t
		WHERE t.rn = 1
	) nea ON nep.NotElecId = nea.NotElecId
	LEFT JOIN (
		SELECT 
			a.EMPLEADOID
			,MAX(CASE WHEN a.fkIdTipoArea = 3 THEN 1 ELSE 0 END)		AS EsCoordinador
			,MAX(CASE WHEN a.fkIdTipoArea = 5 THEN 1 ELSE 0 END)		AS EsActuario
		FROM areas a WITH (NOLOCK)
		LEFT JOIN EmpleadoOrganismo eo WITH (NOLOCK)
			ON eo.EmpleadoId = a.EmpleadoId
			AND eo.STATUSREGISTRO = 1
		WHERE a.EmpleadoId = @EmpleadoId
			AND a.fkIdTipoArea IN (3, 5)		--3=COordinador, 5=Actuario
			AND a.STATUSREG = 1
		GROUP BY a.EMPLEADOID
	) ap
		ON ap.EMPLEADOID =	CASE 
								WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO
								WHEN @is_Coordinador = 0 THEN nep.ActuarioId
							END
	LEFT JOIN (
		SELECT 
			a.AsuntoNeunId 
			,ta.NombreCorto
			,ctp.CatalogoDependienteDescripcion
		FROM Asuntos a WITH(NOLOCK)
		INNER JOIN CatTiposAsunto cta WITH (NOLOCK) on a.CatTipoAsuntoId = cta.CatTipoAsuntoId
		LEFT JOIN (
				SELECT 
					nombreCorto
					,CatTipoAsuntoId
					,row = ROW_NUMBER() OVER(PARTITION BY CatTipoAsuntoId ORDER BY nombreCorto) 
				FROM dbo.tbx_CatTiposAsunto WITH (NOLOCK)
		) ta ON cta.CatTipoAsuntoId = ta.CatTipoAsuntoId AND row  = 1
		LEFT JOIN (
			SELECT row = ROW_NUMBER() OVER(PARTITION BY cd.CatalogoDependienteElementoIDNew,ceta.CatTipoAsuntoId  ORDER BY cd.CatalogoDependienteElementoIDNew) 
				,TipoProcedimiento = ced.CatalogoElementoDescripcion, 
				CatTipoProcedimiento = cd.CatalogoDependienteElementoIDNew, 
				ceta.CatTipoAsuntoId,TipoProcedimientoId = ced.CatalogoElementoDescripcionID
				,cd.CatalogoDependienteDescripcion
			FROM dbo.CatalogosDependientes AS cd WITH(NOLOCK)  
			INNER JOIN dbo.CatalogosElementosDescripcion AS ced WITH(NOLOCK)  ON cd.CatalogoDependienteElementoIDNew = ced.CatalogoElementoDescripcionID
			INNER JOIN CatalogosElementosTiposAsunto ceta with(nolock) on cd.CatalogoDependienteId=ceta.CatalogoId and cd.CatalogoDependienteElementoIDNew = ceta.CatalogoElementoIdNew
			WHERE cd.CatalogoDependienteId  IN (464,124,208,1207,734,1933,1892)
		) ctp 
			ON a.CatTipoProcedimiento = ctp.CatTipoProcedimiento 
			AND a.CatTipoAsuntoId = ctp.CatTipoAsuntoId 
			AND ctp.row = 1
		WHERE a.StatusReg = 1
	) cd
		ON cd.AsuntoNeunId = nep.AsuntoNeunId
    WHERE 
    	nep.StatusReg = 1 
    	AND ad.StatusReg = 1
    	AND nep.TipoNotificacion IN (1, 3, 5, 6, 11, 12)
    	AND a.CatOrganismoId = @pi_CatOrganismoId 
		AND (
		    (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1 AND neaa.IDUSUARIOASIGNO = @EmpleadoId) 
		    OR (@is_Coordinador = 0 AND nep.ActuarioId = @EmpleadoId)
		)
		AND ad.FechaAutoriza >= @fechaInicio AND ad.FechaAutoriza < DATEADD(DAY, 1, @fechaFin)
    	AND ad.FECHAAUTORIZA IS NOT NULL
        AND CASE
            WHEN (nep.FechaNotificacion IS NULL) THEN 1
            WHEN (nep.TipoConstanciaId IN ('5726', '5731', '5732', '1440') OR nea.ArchivoId IS NULL) THEN 2
            WHEN ((CASE WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO WHEN @is_Coordinador = 0 THEN nep.ActuarioId END) IS NOT NULL) AND (nep.TipoConstanciaId IS NOT NULL AND nep.TipoConstanciaId NOT IN ('5726', '5731', '5732', '1440')) AND nea.ArchivoId IS NOT NULL THEN 3
            ELSE NULL
	        END 
			IN (3)	
    ORDER BY
        nep.FechaNotificacion,
        a.AsuntoAlias,
        neaa.FECHAUSUARIOASIGNO

    SET NOCOUNT OFF
END