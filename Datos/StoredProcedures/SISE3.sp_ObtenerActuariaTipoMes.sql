USE SISE_NEW
GO

-- =============================================
-- Proyecto: SISE3
-- Autor: Erick Gonzalez
-- Creado: [2024-06-07]
-- Modificado:  2025-01-03 - MTS - Se optimiza consulta
-- Objetivo: Obtener las notificaciones por tipo y por mes
-- =============================================

ALTER PROCEDURE [SISE3].[sp_ObtenerActuariaTipoMes]
    @pi_CatOrganismoId INT,          -- Identificador del organismo
    @pi_FiltroActuarioID BIGINT,     -- Identificador del actuario (puede ser 0 para no filtrar)
    @pi_FechaInicial DATE,           -- Fecha inicial del rango de búsqueda
    @pi_FechaFinal DATE,             -- Fecha final del rango de búsqueda
    @is_Coordinador BIT	= 0,			-- Bandera para determinar si es Coordinador
    @is_OtrosUsuarios BIT = 0			-- Bandera para determinar si es OtrosUsuarios
AS
BEGIN
	
	DECLARE @FechaInicioAnActual		DATE
    SET NOCOUNT ON;
	SET LANGUAGE Spanish;
    SET @FechaInicioAnActual = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-5, 0);
   
	WITH NOTIFICACIONES AS (
		SELECT distinct
		    ad.AsuntoNeunId,
		    a.AsuntoAlias,
		    ad.AsuntoDocumentoID,
		    nep.NotElecId,
		    ax.Folio,
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
		AND 1 = 
			CASE
				WHEN (@is_OtrosUsuarios = 1 OR @is_Coordinador = 1) AND (neaa.IDUSUARIOASIGNO = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0) THEN 1
			    WHEN @is_Coordinador = 0 AND (nep.ActuarioId = @pi_FiltroActuarioID OR @pi_FiltroActuarioID = 0) THEN 1
			END
		AND ad.FechaAutoriza >= @FechaInicioAnActual AND ad.FechaAutoriza < DATEADD(DAY, 1, @pi_FechaFinal)
		AND ad.FECHAAUTORIZA IS NOT NULL
	) 

    -- Consulta para obtener las notificaciones por tipo y por mes
    SELECT 
        ISNULL(DATENAME(MONTH, FECHAAUTORIZA), 'SinMes') AS Mes,
        ISNULL(DATEPART(MONTH, FECHAAUTORIZA), 0) AS NumeroMes,
        Tipo,
        COUNT(*) AS Total
    FROM NOTIFICACIONES
	WHERE EstadoId = 3
    GROUP BY
        ISNULL(DATENAME(MONTH, FECHAAUTORIZA), 'SinMes'),
        ISNULL(DATEPART(YEAR, FECHAAUTORIZA), 0),
        ISNULL(DATEPART(MONTH, FECHAAUTORIZA), 0),
        Tipo
    ORDER BY
        ISNULL(DATEPART(YEAR, FECHAAUTORIZA), 0),
		NumeroMes
    
    SET NOCOUNT OFF;
END;