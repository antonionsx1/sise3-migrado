SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:  Saul Garcia
-- Create date:  20/12/2013
-- Description: Devuelve el oficio por el folio
-- EXEC [SISE3].[pcListadoOficio] 1494,'399/2023',6712
-- =============================================

CREATE OR ALTER PROC [SISE3].[pcListadoOficio]
(
	 @pi_CatOrganismo INT
	,@pi_FolioOficio VARCHAR(50)
	,@pi_EmpleadoId BIGINT
)
AS
BEGIN

	DECLARE @anexoId BIGINT
	DECLARE @asuntoNeunId BIGINT
	DECLARE @sintesisOrden INT
	DECLARE @acuseRecibido VARCHAR(50)
	DECLARE @nombreUsuario VARCHAR(100)
    DECLARE @StatusReg INT
    DECLARE @nombreEmpleado VARCHAR(100)

	SELECT @anexoId = AnexoId, @asuntoNeunId = ofi.AsuntoNeunId, @sintesisOrden=saa.SintesisOrden, @StatusReg = ofi.StatusRegistro
	FROM [SISE_NEW].[dbo].[Anexos] ofi WITH(NOLOCK)
	INNER JOIN AsuntosDocumentos ad 
			ON ad.AsuntoNeunId=ofi.AsuntoNeunId
			AND ad.AsuntoDocumentoId=ofi.AsuntoDocumentoId
	INNER JOIN SintesisAcuerdoAsunto saa
			ON saa.AsuntoNeunId = ofi.AsuntoNeunId
			AND saa.CatOrganismoId = ofi.CatOrganismoId
			AND saa.IdDocumento=ad.AsuntoDocumentoId
			AND saa.StatusReg != 0
	WHERE ofi.CatOrganismoId=@pi_CatOrganismo
	AND CONVERT(VARCHAR(100),ofi.Folio)+'/'+CONVERT(VARCHAR(100),ofi.Año)=@pi_FolioOficio
	
	SELECT @acuseRecibido = nep.AcuseRecibido
           ,@nombreEmpleado = SISE3.ConcatenarNombres(ce.Nombre,ce.ApellidoPaterno,ce.ApellidoMaterno)
    FROM NotificacionElectronica_Personas nep
    LEFT JOIN CatEmpleados ce 
        ON nep.ActuarioId = ce.EmpleadoId
	WHERE nep.AsuntoNeunId=@asuntoNeunId
	AND nep.SintesisOrden=@sintesisOrden

    IF(@StatusReg = 0)
    BEGIN
        THROW 51000,'El oficio se encuentra cancelado. No es posible su recepción.',1;
    END
	
	IF(@anexoId IS NOT NULL) -- VALIDACIÓN DE OFICIO EXISTENTE
	BEGIN
		IF NOT EXISTS(SELECT fkAnexoId
				  FROM [SISE3].[HIS_RecepcionOficio] 
				  WHERE IdEmpleadoRecepcion=@pi_EmpleadoId
				  AND fkCatOrganismoId=@pi_CatOrganismo
				  AND fkAnexoId=@anexoId
				  AND AsuntoNeunId=@asuntoNeunId
				  ) --VALIDACIÓN DE OFICIO RECIBIDO POR EL MISMO USUARIO
		BEGIN
			IF(@acuseRecibido IS NULL) --VALIDACIÓN PARA NO MOSTRAR OFICIOS CON ACUSES RECIBIDOS
			BEGIN
				SELECT
					 ex.AsuntoAlias AS Expediente
					,ex.CatTipoAsunto AS TipoAsuntoDescripcion
					,1 AS ConArchivo
					,ofi.Folio AS Folio
					,ex.AsuntoNeunId
					,ex.CatTipoAsuntoId
					,ofi.CatOrganismoId
					,dbo.funRecuperaCatalogoDependienteDescripcion(527,saa.TipoCuaderno) as NombreTipoCuaderno
					,saa.TipoCuaderno
					,ofi.AnexoId
					,'Oficio' TipoNotificacion
				FROM
					(
						SELECT AsuntoNeunId
							  ,Folio
							  ,CatOrganismoId
							  ,Año
							  ,AsuntoDocumentoId
							  ,AnexoId
						FROM [SISE_NEW].[dbo].[Anexos] WITH(NOLOCK)
						WHERE StatusRegistro=1
						GROUP BY AsuntoNeunId,Folio,CatOrganismoId,Año,AsuntoDocumentoId,AnexoId
					) AS ofi
				CROSS APPLY SISE3.fnExpediente(ofi.AsuntoNeunId) ex
				INNER JOIN AsuntosDocumentos ad 
					ON ad.AsuntoNeunId=ofi.AsuntoNeunId
					AND ad.AsuntoDocumentoId=ofi.AsuntoDocumentoId
				INNER JOIN SintesisAcuerdoAsunto saa
					ON saa.AsuntoNeunId = ofi.AsuntoNeunId
					AND saa.CatOrganismoId = ofi.CatOrganismoId
					AND saa.IdDocumento=ad.AsuntoDocumentoId
					AND saa.StatusReg != 0
				WHERE ofi.CatOrganismoId = @pi_CatOrganismo
				AND CONVERT(VARCHAR(100),ofi.Folio)+'/'+CONVERT(VARCHAR(100),ofi.Año) = @pi_FolioOficio
			END
			ELSE
			BEGIN
				THROW 51000,'El Oficio fue recibido por: ',1;
			END
		END
	END
	ELSE
	BEGIN
		THROW 51000,'El oficio no se encuentra registrado en el sistema.',1;
	END
END
