USE SISE_NEW
GO

-- ====================================================================================
-- Author:        Erick Gonzalez
-- Create date:   06/06/2024
-- Modificado:    03/01/2025 - MTS - Se optimiza consulta
-- Description:   Este procedimiento almacenado obtiene una lista de empleados junto con 
--                su información asociada a un organismo específico y cargo(s) específico(s).
-- ====================================================================================

ALTER PROCEDURE [SISE3].[sp_ObtenerKipsIncialActuaria]
    @pi_CatOrganismoId INT,				-- Identificador del organismo
    @pi_FiltroActuarioID BIGINT,		-- Identificador del actuario (puede ser 0 para no filtrar)
    @pi_FechaInicial DATE,				-- Fecha inicial del rango de búsqueda
    @pi_FechaFinal DATE,				-- Fecha final del rango de búsqueda
    @is_header BIT,						-- Bandera para determinar el filtro de fecha
    @is_Coordinador BIT	= 0,			-- Bandera para determinar si es Coordinador
    @is_OtrosUsuarios BIT = 0			-- Bandera para determinar si es OtrosUsuarios
AS
BEGIN
SET NOCOUNT ON;

    DECLARE @FechaInicioAnActual DATE;
    SET @FechaInicioAnActual = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
   
    -- Eliminar la tabla temporal
    DROP TABLE IF EXISTS #TMP_NOTIFICACIONES
    DROP TABLE IF EXISTS #TMP_NOTIFICACIONES2

	-- Insertar datos en la tabla temporal
	SELECT distinct
	    ad.AsuntoNeunId,
	    a.AsuntoAlias,
	    ad.AsuntoDocumentoID,
	    nep.NotElecId,
	    ax.FOLIO,
		nep.FechaAlta,
	    ad.FECHAAUTORIZA,
	    cnt.sDescripcionCorta AS Tipo,   -- Tipo de notificación
	    CASE
	        WHEN (nep.FechaNotificacion IS NULL) THEN 1
	        WHEN (nep.TipoConstanciaId IN ('5726', '5731', '5732', '1440') OR nea.ArchivoId IS NULL) THEN 2
	        WHEN ((CASE WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO WHEN @is_Coordinador = 0 THEN nep.ActuarioId END) IS NOT NULL) AND (nep.TipoConstanciaId IS NOT NULL AND nep.TipoConstanciaId NOT IN ('5726', '5731', '5732', '1440')) AND nea.ArchivoId IS NOT NULL THEN 3
	        ELSE NULL
	    END AS EstadoId,
	    nep.TipoNotificacion,
	    nep.FechaNotificacion,
	    nep.TipoConstanciaId,
	    CASE
	        WHEN (@is_Coordinador = 1 OR @is_OtrosUsuarios = 1) THEN neaa.IDUSUARIOASIGNO
		    WHEN @is_Coordinador = 0 THEN nep.ActuarioId
	        ELSE neaa.IDUSUARIOASIGNO
	    END AS ActuarioId,
	    ad.TipoCuaderno
	INTO #TMP_NOTIFICACIONES
	FROM AsuntosDocumentos ad WITH (NOLOCK)
	CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
	INNER JOIN NotificacionElectronica_Personas nep WITH (NOLOCK) ON ad.AsuntoID = nep.AsuntoId AND ad.AsuntoNeunId = nep.AsuntoNeunId AND ad.SintesisOrden = nep.SintesisOrden
	LEFT JOIN dbo.CatNotificaciones cnt WITH (NOLOCK) ON cnt.kIdCatNotificaciones = nep.TipoNotificacion
	LEFT JOIN NotificacionElectronica_Archivos nea WITH (NOLOCK) ON nep.NotElecId = nea.NotElecId
	LEFT JOIN NotificacionElectronica_AsignaActuario neaa WITH (NOLOCK) ON nep.AsuntoNeunId = neaa.AsuntoNeunId AND nep.SintesisOrden = neaa.SintesisOrden AND nep.NotElecId = neaa.NotElecId AND neaa.IESTATUSREG = 1
	LEFT JOIN Anexos ax WITH (NOLOCK) ON nep.PersonaId = ax.AnexoParteId AND ad.AsuntoDocumentoId = ax.AsuntoDocumentoId AND ax.AnexoTipoId IN (1, 6)
	INNER JOIN Asuntos an WITH (NOLOCK) ON ad.AsuntoNeunId = an.AsuntoNeunId
	WHERE nep.StatusReg = 1 AND ad.StatusReg = 1
	AND nep.TipoNotificacion IN (1, 3, 5, 6, 11, 12)
	AND a.CatOrganismoId = @pi_CatOrganismoId 
	AND (
	    (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) AND (neaa.IDUSUARIOASIGNO = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0)
	    OR 
	    (@is_Coordinador = 0 AND (nep.ActuarioId = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0))
	)
	AND (
		(@is_header = 1 AND ad.FechaAutoriza >= @pi_FechaInicial AND ad.FechaAutoriza < DATEADD(DAY, 1, @pi_FechaFinal))
	    OR (@is_header = 0 AND ad.FechaAutoriza >= @FechaInicioAnActual AND ad.FechaAutoriza < DATEADD(DAY, 1, GETDATE()))
	)
	AND ad.FECHAAUTORIZA IS NOT NULL

	--Crear indice
	CREATE INDEX ix_01 ON #TMP_NOTIFICACIONES(EstadoId, FechaAutoriza)

	
    -- 1. Primer conjunto de resultados: Notificaciones pendientes divididas por días
    SELECT 
        CASE 
            WHEN DATEDIFF(DAY, FECHAAUTORIZA, @pi_FechaFinal) >= 3 THEN '+3 días'
            WHEN DATEDIFF(DAY, FECHAAUTORIZA, @pi_FechaFinal) = 2 THEN '2 días'
            WHEN DATEDIFF(DAY, FECHAAUTORIZA, @pi_FechaFinal) <= 1 THEN '1 día'
            ELSE 'Hoy'
        END AS Dias,
        COUNT(*) AS Total
    FROM #TMP_NOTIFICACIONES
	WHERE EstadoId IN (1,2)
    GROUP BY
        CASE 
            WHEN DATEDIFF(DAY, FECHAAUTORIZA, @pi_FechaFinal) >= 3 THEN '+3 días'
            WHEN DATEDIFF(DAY, FECHAAUTORIZA, @pi_FechaFinal) = 2 THEN '2 días'
            WHEN DATEDIFF(DAY, FECHAAUTORIZA, @pi_FechaFinal) <= 1 THEN '1 día'
            ELSE 'Hoy'
        END

    -- 2. Segundo conjunto de resultados: Total de notificaciones
    SELECT 
        COUNT(*) AS Total,
        SUM(CASE WHEN EstadoId IN (1,2) THEN 1 ELSE 0 END) AS Pendientes,		
        SUM(CASE WHEN EstadoId = 3 THEN 1 ELSE 0 END) AS Notificadas
    FROM #TMP_NOTIFICACIONES
	WHERE EstadoId IN (1, 2, 3)

    -- 3. Tercer conjunto de resultados: Notificaciones notificadas divididas por tipo de notificación
    SELECT 
        Tipo,
        COUNT(*) AS Total
    FROM #TMP_NOTIFICACIONES
	WHERE EstadoId = 3
    GROUP BY
        Tipo

	-- Insertar datos en la tabla temporal respetando siempre el rango de fechas dado
	SELECT DISTINCT
	    ad.AsuntoNeunId,
	    a.AsuntoAlias,
	    ad.AsuntoDocumentoID,
	    nep.NotElecId,
	    ax.FOLIO,
		nep.FechaAlta,
	    ad.FECHAAUTORIZA,
	    cnt.sDescripcionCorta AS Tipo,   -- Tipo de notificación
	    CASE
	        WHEN (nep.FechaNotificacion IS NULL) THEN 1
	        WHEN (nep.TipoConstanciaId IN ('5726', '5731', '5732', '1440') OR nea.ArchivoId IS NULL) THEN 2
	        WHEN (CASE WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) THEN neaa.IDUSUARIOASIGNO WHEN @is_Coordinador = 0 THEN nep.ActuarioId END) IS NOT NULL AND (nep.TipoConstanciaId IS NOT NULL AND nep.TipoConstanciaId NOT IN ('5726', '5731', '5732', '1440')) AND nea.ArchivoId IS NOT NULL THEN 3
	        ELSE NULL
	    END AS EstadoId,
	    nep.TipoNotificacion,
	    nep.FechaNotificacion,
	    nep.TipoConstanciaId,
	    CASE
	        WHEN (@is_Coordinador = 1 OR @is_OtrosUsuarios = 1) THEN neaa.IDUSUARIOASIGNO
		    WHEN @is_Coordinador = 0 THEN nep.ActuarioId
	        ELSE neaa.IDUSUARIOASIGNO
	    END AS ActuarioId,
	    ad.TipoCuaderno
	INTO #TMP_NOTIFICACIONES2
	FROM AsuntosDocumentos ad WITH (NOLOCK)
	CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
	INNER JOIN NotificacionElectronica_Personas nep WITH (NOLOCK) ON ad.AsuntoID = nep.AsuntoId AND ad.AsuntoNeunId = nep.AsuntoNeunId AND ad.SintesisOrden = nep.SintesisOrden
	LEFT JOIN dbo.CatNotificaciones cnt WITH (NOLOCK) ON cnt.kIdCatNotificaciones = nep.TipoNotificacion
	LEFT JOIN NotificacionElectronica_Archivos nea WITH (NOLOCK) ON nep.NotElecId = nea.NotElecId
	LEFT JOIN NotificacionElectronica_AsignaActuario neaa WITH (NOLOCK) ON nep.AsuntoNeunId = neaa.AsuntoNeunId AND nep.SintesisOrden = neaa.SintesisOrden AND nep.NotElecId = neaa.NotElecId AND neaa.IESTATUSREG = 1
	LEFT JOIN Anexos ax WITH (NOLOCK) ON nep.PersonaId = ax.AnexoParteId AND ad.AsuntoDocumentoId = ax.AsuntoDocumentoId AND ax.AnexoTipoId IN (1, 6)
	INNER JOIN Asuntos an WITH (NOLOCK) ON ad.AsuntoNeunId = an.AsuntoNeunId
	WHERE nep.StatusReg = 1 AND ad.StatusReg = 1
	AND nep.TipoNotificacion IN (1, 3, 5, 6, 11, 12)
	AND a.CatOrganismoId = @pi_CatOrganismoId
	AND (
	    (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) AND (neaa.IDUSUARIOASIGNO = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0)
	    OR 
	    (@is_Coordinador = 0 AND (nep.ActuarioId = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0))
	)
	AND ad.FECHAAUTORIZA >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AND ad.FECHAAUTORIZA < DATEADD(DAY, 1, @pi_FechaFinal)
	AND ad.FECHAAUTORIZA IS NOT NULL

	--Crear indice
	CREATE INDEX ix_01 ON #TMP_NOTIFICACIONES2(EstadoId, FechaAutoriza, Tipo)
	
    -- <Tarjeta Notificaciones>
    ---4. Total de notificaciones siempre respetando el rango de fechas proporcionado 
    SELECT 
        Total			= SUM(CASE WHEN FECHAAUTORIZA >= @pi_FechaInicial AND FECHAAUTORIZA < DATEADD(DAY, 1, @pi_FechaFinal) THEN 1 ELSE 0 END), --Total Por Notificar Hasta hoy (x/N)
        Pendientes		= SUM(CASE WHEN FECHAAUTORIZA >= @pi_FechaInicial AND FECHAAUTORIZA < DATEADD(DAY, 1, @pi_FechaFinal) AND EstadoId IN (1, 2) THEN 1 ELSE 0 END),	--Cantidad Por Notificar Hasta hoy (N/x)
        Notificadas		= SUM(CASE WHEN EstadoId = 3 THEN 1 ELSE 0 END),		--Realizadas
        Personales		= SUM(CASE WHEN EstadoId = 3 AND Tipo = 'Personal' THEN 1 ELSE 0 END),
        Oficios			= SUM(CASE WHEN EstadoId = 3 AND Tipo IN ('Oficio', 'Oficio libre') THEN 1 ELSE 0 END),
        Listas			= SUM(CASE WHEN EstadoId = 3 AND Tipo = 'Lista' THEN 1 ELSE 0 END),
        Electronicas	= SUM(CASE WHEN EstadoId = 3 AND Tipo = 'Electrónica' THEN 1 ELSE 0 END),
        Edictos			= SUM(CASE WHEN EstadoId = 3 AND Tipo = 'Edicto' THEN 1 ELSE 0 END)
    FROM #TMP_NOTIFICACIONES2
        
    -- Eliminar la tabla temporal
    DROP TABLE IF EXISTS #TMP_NOTIFICACIONES
    DROP TABLE IF EXISTS #TMP_NOTIFICACIONES2

	SET NOCOUNT OFF
    
END
