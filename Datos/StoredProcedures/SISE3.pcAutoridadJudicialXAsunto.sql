SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================= 
-- Author: Diana Quiroga - MS
-- Alter date: 29/09/2023 
-- Description: Se uliliza para lista las partes cuando en el modulo promociones se selecciona el radio button Partes
-- OrigenPromocion '0 = SISE' '1 = FESE' '2 = San Lazaro' '3 = VET' '4 = Oficialía de Partes Virtual' 
--execute [SISE3].[pcAutoridadJudicialXAsunto] 30313631
-- exec [SISE3].[[pcAutoridadJudicialXAsunto]]  8367099, '1002,1,2', 'REGI'
-- exec [SISE3].[[pcAutoridadJudicialXAsunto]]  18672587,null, 'ANGEL'
-- ============================================= 

CREATE OR ALTER PROCEDURE [SISE3].[pcAutoridadJudicialXAsunto]
@pi_AsuntoNeunId [bigint], 
@pi_NoExp varchar(max) = NULL, 
@pi_Texto VARCHAR(MAX) = NULL
AS

        BEGIN
                SET NOCOUNT ON


				


				SELECT	DISTINCT
					Nombres = SISE3.ConcatenarNombres(ea.Nombre, ea.ApellidoPaterno, ea.ApellidoMaterno),
					AutoridadJudicialId = aj.AutoridadJudicialId, 
					AutoridadJudicialDescripcion = c.CargoDescripcion,
					NombreOficial = o.NombreOficial,
					o.CatOrganismoId
				FROM  AutoridadJudicial aj  
					LEFT JOIN Promociones p WITH(NOLOCK)ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
					CROSS APPLY SISE3.fnExpediente(aj.AsuntoNeunId) a
					LEFT JOIN CatEmpleados ea WITH(NOLOCK) ON ea.EmpleadoId = aj.EmpleadoId
					LEFT JOIN EmpleadoOrganismo eo WITH (NOLOCK) on eo.EmpleadoId=ea.EmpleadoId
					LEFT JOIN CatOrganismos o WITH (NOLOCK) on o.CatOrganismoId = eo.CatOrganismoId
					LEFT JOIN CatCargo c WITH (NOLOCK) on eO.CargoId=c.CargoId
				WHERE aj.StatusReg = 1
				AND aj.AsuntoNeunID = @pi_AsuntoNeunId
				AND o.StatusReg = 1
				AND c.CargoId <> 63
				AND IIF (@pi_NoExp is null, @pi_NoExp, a.AsuntoAlias) = @pi_NoExp
				AND IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
				CONCAT(isnull(c.CargoDescripcion,'') , SISE3.ConcatenarNombres(ea.Nombre, ea.ApellidoPaterno, ea.ApellidoMaterno))) LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'


                SET NOCOUNT OFF
        END
		