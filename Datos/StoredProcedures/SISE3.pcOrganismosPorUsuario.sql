SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:  Diana Quiroga
-- Alter date:  13/10/2013
-- Description: Obtiene los organos a los que está adscrito un usuario en específico -- Basado en usp_ObtieneOrganismosXEmpleado
-- Permite la carga masiva de archivos para ser asociados a diferentes promociones basado en el Año, numero de orden y numero de Organismo
-- Basado en: EXEC [SISE3].[pcOrganismosPorUsuario] 6712
-- =============================================
CREATE OR ALTER PROCEDURE  [SISE3].[pcOrganismosPorUsuario]
      @pi_EmpleadoId int  
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
      

	  Declare @Empleado int,
			  @CatOrganismoId int

 
      --select @Empleado= EmpleadoId from  CatEmpleados where UserName=@pi_Username


      IF EXISTS (SELECT CatOrganismoId 
	             FROM EmpleadoOrganismo
				 WHERE EmpleadoId=@pi_EmpleadoId AND CatOrganismoId=1580  AND StatusRegistro=1)
      BEGIN

                  --se crean las tablas temporales. 
                  CREATE TABLE #Tmp1580 
				  (CircuitoOrden int,
				   CatOrganismoId int,
				   NombreOficial  varchar(300), 
				   CatTipoOrganismoId INT, 
				   Visible varchar(5),
				   CatHorarioIngresoValidoId int, 
				   TurnoActivo varchar(5))

                  CREATE TABLE #TmpSIN1580  
				  (CircuitoOrden int,
				  CatOrganismoId int,
				  NombreOficial  varchar(300), 
				  CatTipoOrganismoId INT, 
				  Visible varchar(5)
				  ,CatHorarioIngresoValidoId int, 
				  TurnoActivo varchar(5))

				  --ART 18/10/2019 HISTORICO DE ORGANOS
				  CREATE TABLE #TmpHIST  
				  (CircuitoOrden int,
				  CatOrganismoId int,
				  NombreOficial  varchar(300), 
				  CatTipoOrganismoId INT, 
				  Visible varchar(5),
				  CatHorarioIngresoValidoId int, 
				  TurnoActivo varchar(5))

                  --Se inserta en la primera tabla sólo el valor de 1580
                  INSERT INTO #Tmp1580  
				  SELECT cc.CircuitoOrden, co.CatOrganismoId, co.NombreOficial, co.CatTipoOrganismoId, 
						CASE isnull(a.IdRol, '0') WHEN 0 THEN 'false' ELSE 'true' END AS Visible, 
						dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo) AS CatHorarioIngresoValidoId,
						CASE WHEN dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo) = 1 THEN 'true' ELSE 'false' END AS TurnoActivo
                  FROM CatEmpleados AS b WITH (nolock) 
						--INNER JOIN EmpleadoOrganismo AS a WITH (nolock) ON b.EmpleadoId = a.EmpleadoId 
						INNER JOIN SISE3.REL_RolEmpleadoXOrganismo a on a.IdCatEmpleado =b.EmpleadoId
						INNER JOIN CatOrganismos AS co WITH (nolock) ON a.IdOrganismo = co.CatOrganismoId 
						INNER JOIN CatCircuitos AS cc WITH (nolock) ON co.CatCircuitoId = cc.CatCircuitoId
                  WHERE	(b.EmpleadoId=@pi_EmpleadoId) AND (b.StatusRegistro = 1) 
				  AND (co.StatusReg = 1) /*AND (a.StatusRegistro = 1) AND (a.FechaBaja IS NULL) AND (ISNULL(a.CargoId, 0) <> 63)*/ AND (co.CatOrganismoId = 1580)


                  --Se inserta todos los valores excepto el 1580

                  INSERT INTO #TmpSIN1580   
				  SELECT cc.CircuitoOrden, co.CatOrganismoId, co.NombreOficial, co.CatTipoOrganismoId, 
						CASE isnull(a.IdRol, '0') WHEN 0 THEN 'false' ELSE 'true' END AS Visible, 
                        dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo) AS CatHorarioIngresoValidoId, 
						CASE WHEN dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo) = 1 THEN 'true' ELSE 'false' END AS TurnoActivo
                  FROM CatEmpleados AS b WITH (nolock) 
						--INNER JOIN EmpleadoOrganismo AS a WITH (nolock) ON b.EmpleadoId = a.EmpleadoId 
						INNER JOIN SISE3.REL_RolEmpleadoXOrganismo a on a.IdCatEmpleado =b.EmpleadoId
						INNER JOIN CatOrganismos AS co WITH (nolock) ON a.IdOrganismo = co.CatOrganismoId 
						INNER JOIN CatCircuitos AS cc WITH (nolock) ON co.CatCircuitoId = cc.CatCircuitoId
                  WHERE (b.EmpleadoId=@pi_EmpleadoId) AND (b.StatusRegistro = 1) AND (co.StatusReg = 1) 
						/*AND (a.StatusRegistro = 1) AND (a.FechaBaja IS NULL) AND (ISNULL(a.CargoId, 0) <> 63)*/ AND (co.CatOrganismoId != 1580) --AND (co.CatOrganismoId != 3847)


				  --ART 18/10/2019 HISTORICO DE ORGANOS, Modalidad Cierre con modo captura temporal
				  --ART 12/02/2020  HISTORICO DE ORGANOS, se agregan tipo de cambio 1,3,9 con modalidad de captura
				  INSERT INTO #TmpHIST 
				  SELECT cc.CircuitoOrden, co.fkIdCatOrganismoCronologia, 
				  co.sNombreOficial+'('+convert(VARCHAR,co.fFechaInicio,103)+' - '+convert(VARCHAR,co.fFechaFin,103)+')', 
				  JSON_VALUE(co.sJsonOrganoRespaldo,'$.Organismo[0].CatTipoOrganismoId')AS CatTipoOrganismoId,
				  CASE isnull(a.IdRol, '0') WHEN 0 THEN 'false' ELSE 'true' END AS Visible,
				  dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo) AS CatHorarioIngresoValidoId,
				  CASE WHEN dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo)=1 THEN 'true' else 'false' end AS TurnoActivo
				  FROM dbo.CatEmpleados AS b with(nolock)
					   --INNER JOIN dbo.EmpleadoOrganismo a with(nolock) ON b.EmpleadoId = a.EmpleadoId 
					   INNER JOIN SISE3.REL_RolEmpleadoXOrganismo a on a.IdCatEmpleado =b.EmpleadoId
					   INNER JOIN dbo.HISTOJ_REL_OrganismoCronologia co with(nolock) ON a.IdOrganismo = co.fkIdCatOrganismoCronologia 
					   INNER JOIN dbo.CatCircuitos cc with(nolock) ON JSON_VALUE(co.sJsonOrganoRespaldo,'$.Organismo[0].CatCircuitoId') = cc.CatCircuitoId
				  WHERE  co.fkIdCatTipoCambioOrganismo in(1,2,3,9) and co.fkIdCatModalidadFunciones=3
				  AND (b.EmpleadoId=@pi_EmpleadoId)
				  AND (b.StatusRegistro = 1) 
				  /*AND (a.StatusRegistro = 1) 
				  AND (a.FechaBaja IS NULL) 
				  AND (isnull(A.CargoId,0)<>63) */
				  --AND (co.fkIdCatOrganismoCronologia != 3847) 

                  --se hace la Union de las tablas
				 /* select * from #Tmp1580  union all
                    select * from #TmpSIN1580*/

				  --ART 18/10/2019 HISTORICO DE ORGANOS,Union de tablas con historico Modalidad: Cierre con modo captura temporal
				  select * from #Tmp1580  union all
				  select X.CircuitoOrden,X.CatOrganismoId,X.NombreOficial, X.CatTipoOrganismoId, 
				  X.Visible,X.CatHorarioIngresoValidoId, X.TurnoActivo
                  from (select * from #TmpSIN1580 UNION all  
				        select * from #TmpHIST) X
      END

      ELSE
      BEGIN

	      --ART 14/11/2019 HISTORICO DE ORGANOS
		  CREATE TABLE #TmpHISTn2   
				(CircuitoOrden int,
				CatOrganismoId int,
				NombreOficial  varchar(300), 
				CatTipoOrganismoId INT, 
				Visible varchar(5),
				CatHorarioIngresoValidoId int, 
				TurnoActivo varchar(5))
		  
		  CREATE TABLE #TmpSIN1580n2
			  (CircuitoOrden int,
			  CatOrganismoId int,
			  NombreOficial  varchar(300), 
			  CatTipoOrganismoId INT, 
			  Visible varchar(5),
			  CatHorarioIngresoValidoId int, 
			  TurnoActivo varchar(5))
				 
           INSERT INTO #TmpSIN1580n2
           SELECT cc.CircuitoOrden, co.CatOrganismoId, co.NombreOficial, co.CatTipoOrganismoId, 
				CASE isnull(a.IdRol, '0') WHEN 0 THEN 'false' ELSE 'true' END AS Visible
               , dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo) AS CatHorarioIngresoValidoId
               , CASE WHEN dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo)=1 THEN 'true' else 'false' end AS TurnoActivo
            FROM dbo.CatEmpleados AS b with(nolock)
                  --INNER JOIN dbo.EmpleadoOrganismo a with(nolock) ON b.EmpleadoId = a.EmpleadoId 
				  INNER JOIN SISE3.REL_RolEmpleadoXOrganismo a on a.IdCatEmpleado =b.EmpleadoId
                  INNER JOIN dbo.CatOrganismos co with(nolock) ON a.IdOrganismo = co.CatOrganismoId 
                  INNER JOIN dbo.CatCircuitos cc with(nolock) ON co.CatCircuitoId = cc.CatCircuitoId
            WHERE (b.EmpleadoId=@pi_EmpleadoId) AND (b.StatusRegistro = 1) 
				AND (co.StatusReg = 1) /*AND (a.StatusRegistro = 1) AND (a.FechaBaja IS NULL) AND (isnull(A.CargoId,0)<>63)*/ --AND (co.CatOrganismoId != 3847)

			 --ART 14/11/2019 HISTORICO DE ORGANOS, Modalidad Cierre con modo captura temporal
			 --ART 12/02/2020  HISTORICO DE ORGANOS, se agregan tipo de cambio 1,3,9 con modalidad de captura
			INSERT INTO #TmpHISTn2 
			SELECT cc.CircuitoOrden, co.fkIdCatOrganismoCronologia, 
			co.sNombreOficial+'('+convert(VARCHAR,co.fFechaInicio,103)+' - '+convert(VARCHAR,co.fFechaFin,103)+')', 
			JSON_VALUE(co.sJsonOrganoRespaldo,'$.Organismo[0].CatTipoOrganismoId')AS CatTipoOrganismoId,
			CASE isnull(a.IdRol, '0') WHEN 0 THEN 'false' ELSE 'true' END AS Visible,
			dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo) AS CatHorarioIngresoValidoId,
			CASE WHEN dbo.fn_OT_ValidarFechaTurnoXOrganismo(a.IdOrganismo)=1 THEN 'true' else 'false' end AS TurnoActivo
			FROM dbo.CatEmpleados AS b with(nolock)
				--INNER JOIN dbo.EmpleadoOrganismo a with(nolock) ON b.EmpleadoId = a.EmpleadoId 
				INNER JOIN SISE3.REL_RolEmpleadoXOrganismo a on a.IdCatEmpleado =b.EmpleadoId
				INNER JOIN dbo.HISTOJ_REL_OrganismoCronologia co with(nolock) ON a.IdOrganismo = co.fkIdCatOrganismoCronologia 
				INNER JOIN dbo.CatCircuitos cc with(nolock) 
				ON JSON_VALUE(co.sJsonOrganoRespaldo,'$.Organismo[0].CatCircuitoId') = cc.CatCircuitoId
			WHERE  co.fkIdCatTipoCambioOrganismo in(1,2,3,9) and co.fkIdCatModalidadFunciones=3
			AND  (b.EmpleadoId=@pi_EmpleadoId)
			AND (b.StatusRegistro = 1) 
			/*AND (a.StatusRegistro = 1) 
			AND (a.FechaBaja IS NULL) 
			AND (isnull(A.CargoId,0)<>63) */
			--AND (co.fkIdCatOrganismoCronologia != 3847)

			--se hace la Union de las tablas
			SELECT * 
			FROM #TmpSIN1580n2 
			group by CircuitoOrden, CatOrganismoId, NombreOficial, CatTipoOrganismoId, Visible,CatHorarioIngresoValidoId,TurnoActivo
			UNION all  
			SELECT * 
			FROM #TmpHISTn2
			group by CircuitoOrden, CatOrganismoId, NombreOficial, CatTipoOrganismoId, Visible,CatHorarioIngresoValidoId,TurnoActivo

      END

	  IF OBJECT_ID('tempdb..#Tmp1580') IS NOT NULL
		DROP TABLE #Tmp1580;

		IF OBJECT_ID('tempdb..#TmpSIN1580') IS NOT NULL
		DROP TABLE #TmpSIN1580;

		IF OBJECT_ID('tempdb..#TmpHIST') IS NOT NULL
		DROP TABLE #TmpHIST;


END