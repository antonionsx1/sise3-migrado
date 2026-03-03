USE SISE_NEW
GO

-- =============================================
-- Proyecto: SISE3
-- Autor: Erick Gonzalez
-- Creado: [2024-06-07]
-- Modificado:  2025-01-03 - MTS - Se optimiza consulta
-- Objetivo: Obtener las notificaciones por tipo y por semana del mes seleccionado
-- =============================================

ALTER PROCEDURE [SISE3].[sp_ObtenerActuariaDetalleMes]
    @pi_CatOrganismoId INT,          -- Identificador del organismo
    @pi_FiltroActuarioID BIGINT,     -- Identificador del actuario (puede ser 0 para no filtrar)
    @pi_FechaInicial DATE,           -- Fecha inicial del rango de búsqueda
    @pi_FechaFinal DATE,             -- Fecha final del rango de búsqueda
    @MesSeleccionado INT,             -- Mes seleccionado para el filtro
    @is_Coordinador BIT	= 0,			-- Bandera para determinar si es Coordinador
    @is_OtrosUsuarios BIT = 0			-- Bandera para determinar si es OtrosUsuarios
AS
BEGIN
    SET NOCOUNT ON;

	WITH NOTIFICACIONES AS (
	    SELECT distinct
	        ad.AsuntoNeunId,
	        a.AsuntoAlias AS No_Exp,
	        a.CatTipoAsunto AS TipoAsunto,
	        ad.TipoCuaderno,
	        ad.AsuntoDocumentoId,
	        ad.SintesisOrden,
	        ad.NombreDocumento AS DocumentoAcuerdo,
	        1 AS TipoParte,
	        nep.PersonaId AS ParteID,
	        CASE
	            WHEN (nep.FechaNotificacion IS NULL) THEN 1
	            WHEN (nep.TipoConstanciaId IN ('5726', '5731', '5732', '1440') OR nea.ArchivoId IS NULL) THEN 2
	            WHEN (CASE WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO WHEN @is_Coordinador = 0 THEN nep.ActuarioId END) IS NOT NULL AND (nep.TipoConstanciaId IS NOT NULL AND nep.TipoConstanciaId NOT IN ('5726', '5731', '5732', '1440')) AND nea.ArchivoId IS NOT NULL THEN 3
	            ELSE NULL
	        END AS EstadoId,
	        ctn.DESCRIPCION AS EstadoDescripcion,
	        nep.FechaNotificacion AS EstadoFecha,
			nep.FechaAlta,
			nep.HoraNotificacion,
	        cnt.sDescripcionCorta AS Tipo,
	        nep.TipoNotificacion AS TipoId,
	        CASE
	            WHEN (CASE WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO WHEN @is_Coordinador = 0 THEN nep.ActuarioId END) <> 10273 THEN CONCAT(emp.Nombre, ' ', emp.ApellidoPaterno, ' ', emp.ApellidoMaterno)
	            ELSE NULL
	        END AS AsignadoActuario,
	        ar.Nombre AS AsignadoZona,
	        CASE
				WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO
				WHEN @is_Coordinador = 0 THEN nep.ActuarioId
			END				AS ActuarioId,
	        nep.NotElecId,
	        ad.FechaAutoriza
	    FROM AsuntosDocumentos ad WITH (NOLOCK)
	    CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
		INNER JOIN NotificacionElectronica_Personas nep WITH (NOLOCK) ON ad.AsuntoID = nep.AsuntoId AND ad.AsuntoNeunId = nep.AsuntoNeunId AND ad.SintesisOrden = nep.SintesisOrden
		LEFT JOIN NotificacionElectronica_AsignaActuario neaa WITH (NOLOCK) ON nep.AsuntoNeunId = neaa.AsuntoNeunId AND nep.SintesisOrden = neaa.SintesisOrden AND nep.NotElecId = neaa.NotElecId AND neaa.IESTATUSREG = 1
	    LEFT JOIN dbo.Areas ar ON ar.EmpleadoId =	CASE
														WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO
														WHEN @is_Coordinador = 0 THEN nep.ActuarioId
													END
	    LEFT JOIN dbo.CatNotificaciones cnt ON cnt.kIdCatNotificaciones = nep.TipoNotificacion
	    LEFT JOIN dbo.CatEmpleados emp ON emp.EmpleadoId = CASE
																WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO
															    WHEN @is_Coordinador = 0 THEN nep.ActuarioId
															END
	    LEFT JOIN (
	        SELECT ID, DESCRIPCION, Elementos
	        FROM viCatalogos a WITH (NOLOCK)
	        INNER JOIN Catalogos b WITH (NOLOCK) ON a.Catalogo = b.CatalogoId
	        WHERE CatalogoPadre = 6867 AND CatalogoPadre > 0
	    ) ctn ON ctn.ID = nep.TipoConstanciaId
	    LEFT JOIN NotificacionElectronica_Archivos nea ON nep.NotElecId = nea.NotElecId
	    WHERE nep.StatusReg = 1 AND ad.StatusReg = 1
	    AND nep.TipoNotificacion IN (1, 3, 5, 6, 11, 12)
	    AND a.CatOrganismoId = @pi_CatOrganismoId    
		AND 1 = 
			CASE
				WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) AND (neaa.IDUSUARIOASIGNO = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0) THEN 1
			    WHEN @is_Coordinador = 0 AND (nep.ActuarioId = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0) THEN 1
			END
		AND nep.StatusReg = 1 AND ad.StatusReg = 1
		AND ad.FechaAutoriza >= @pi_FechaInicial AND ad.FechaAutoriza < DATEADD(DAY, 1, @pi_FechaFinal)
	)
	
    -- Consulta para obtener las notificaciones por tipo y por semana del mes seleccionado
    SELECT 
        DATEPART(WEEK, FechaAutoriza) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, FechaAutoriza), 0)) + 1 AS Semana,
        Tipo,
        COUNT(*) AS Total
    FROM NOTIFICACIONES
    WHERE EstadoId = 3
        AND MONTH(FechaAutoriza) = @MesSeleccionado
    GROUP BY
        DATEPART(WEEK, FechaAutoriza) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, FechaAutoriza), 0)) + 1,
        Tipo
    ORDER BY Semana

    SET NOCOUNT OFF;
END;