SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Efrén Peña MS
-- Alter date:  19/12/2023
-- Description: consulta para tablero de Actuaría 
-- Basado en:   [SISE3].[pcTableroTramites] 
-- [SISE3].[pcTableroActuaria] 180, 1000,1, null,'2024-01-01','2024-03-16',null, null, '', null, 0 ,null,null

-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcTableroActuaria] 

	-- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	@pi_TamanoPagina INT = NULL,
	--REPRESENTA EL NUMERO DE PÁGINA DE LA PAGINACIÓN
	@pi_NumeroPagina INT,
	-- REPRESENTA EL IDENTIFICADOR DEL EXPEDIENTE - PUEDE LLEGAR NULA
	@pi_AsuntoNeunId BIGINT = NULL,
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaAutorizacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaAutorizacionFin DATE = NULL,
	-- REPRESENTA EL IDENTITICADOR DEL EMPLEADO - PUEDE LLEGAR NULA
	@pi_UsuariId INT = NULL,
	@pi_Texto VARCHAR(MAX) = NULL,
	-- Recibe valor para ordenamiento de la página, PUEDE SER NULO, si es nulo ordena por fecha, de lo contrario por el campo recibido
	@pi_OrdenarPor VARCHAR(128) = NULL,
	-- Recibe configuración de ordenamiento Ascendente o Descendente? 1=Descendente 0=Ascendente
	@pi_TipoOrden INT = NULL,
	--Recibe parámetro del tipo de filtro 0=VerTodas, 1=2días, 2=+3días, 3=1día ,4=Notificados
	--Todo - 0, +3dias - 2 ,2días - 1, 1día - 3 ,Notificados - 4
	@pi_FiltroTipo INT = 0 ,
	--Recibe estado (1=Sin asignar​, 2=Pendiente​, 3=Notificados)
	@pi_Estado VARCHAR(25)=NULL,
	--Recibe ID proveniente del SP usp_CatalogosSel
	@pi_Contenido INT=NULL
	/*
	--Recibe parametro Secretario Id 
	@pi_SecretarioId BIGINT =NULL,
	--Recibe origen id
	@pi_Origen VARCHAR(25) =NULL,
	--Recibe Asunto id
	@pi_CatTipoAsuntoId INT =NULL,--
	--Recibe Capturo id
	@pi_CapturoId BIGINT =NULL,--
	--Recibe Preautorizo id
	@pi_PreautorizoId BIGINT =NULL,--
	--Recibe Autorizo id
	@pi_AutorizoId BIGINT =NULL,--
	--Recibe Cancelo id
	@pi_CanceloId BIGINT =NULL--
	*/
AS
BEGIN

/* SE DECLARAN VARIABLES NECESARIAS PARA LA VALIDACION DE PERMISOS */
        DECLARE @CargoId INT
        DECLARE @Permiso INT
        DECLARE @Preautoriza BIT
        DECLARE @Autoriza BIT
        DECLARE @Cancela BIT
        DECLARE @CancelaPreautorizado BIT
        DECLARE @pi_TipoFecha INT
		DECLARE @TOTAL AS INT
		DECLARE @SinAcuerdo INT
		DECLARE @Cancelados INT
		DECLARE @ConAcuerdo INT
		DECLARE @PreAutorizados INT
		DECLARE @Autorizados INT
		
		--LIMPIO VARIABLE DE ORDER BY PARA REMOVER ESPACIOS EN BLANCO
		IF @pi_OrdenarPor IS NOT NULL
		BEGIN
			SET @pi_OrdenarPor = ltrim(rtrim(@pi_OrdenarPor))
		END
		-- SI LA FECHA INICIAL ES NULA, SE ASIGNA EL VALOR DEL DÍA
		IF @pi_FechaAutorizacionIni IS NULL
		BEGIN
			SET @pi_FechaAutorizacionIni = convert(date,getdate())
		END
		-- SI LA FECHA FIN ES NULA SE ASIGNA EL VALOR DE LA FECHA DE INICIO 
		IF @pi_FechaAutorizacionFin IS NULL
		BEGIN
			SET @pi_FechaAutorizacionFin = ISNULL(@pi_FechaAutorizacionFin,@pi_FechaAutorizacionIni)
		END
		--DECLARE @Tramites SISE3.Tramites_type, @Tramites_Final SISE3.Tramites_type
		
		--Validar Filtros existentes
		IF @pi_FiltroTipo NOT IN (0,1,2,3,4,5)
		BEGIN
			SET @pi_FiltroTipo = 0
		END

		if trim(@pi_estado) = '' 
		BEGIN
			set @pi_estado = NULL
		END

		-- Cargos no esta siendo utilizado se valida por API 
--		SELECT @CargoId = CargoId 
--        FROM EmpleadoOrganismo WITH(NOLOCK) 
--        WHERE  EmpleadoId = @pi_UsuariId
--		AND StatusRegistro = 1	
--        AND CargoId IN (4,5,18,19)

        
        /* CONSULTO EL PERMISO DEL EMPLEADO */
--        SELECT @Permiso = ISNULL(Permiso,0)
--        FROM EmpleadoPermisoAutorizaPanel WITH(NOLOCK) 
--        WHERE EmpleadoId=@pi_UsuariId  
        
-- Tabla temporal con datos de Notificaciones electronicas personas desde asuntos documentos
		SELECT nep.PersonaId as Parte
		,ad.AsuntoNeunId
		,ad.AsuntoId
		,ad.SintesisOrden
		,pas.Nombre
		,pas.APaterno
		,pas.AMaterno
		,nep.FechaNotificacion
		,IIF(nea.NombreArchivo is null,0,1) AS TieneArchivo
		,nep.ActuarioId
		INTO #TMP_TABLE
		FROM AsuntosDocumentos ad WITH(NOLOCK) 
			INNER JOIN NotificacionElectronica_Personas nep ON ad.AsuntoID=nep.AsuntoId AND ad.AsuntoNeunId=nep.AsuntoNeunId AND  ad.SintesisOrden = nep.SintesisOrden
			INNER join PersonasAsunto  pas ON  ad.AsuntoId = pas.AsuntoId and ad.AsuntoNeunId = pas.AsuntoNeunId AND nep.PersonaId = pas.PersonaId
			LEFT JOIN NotificacionElectronica_Archivos nea ON nep.NotElecId = nea.NotElecId
		WHERE 
			ad.StatusReg=1 AND nep.StatusReg=1
            AND ad.CatAutorizacionDocumentosId NOT IN (4,8,9)
			AND CONVERT(Date,ad.fechaAutoriza) <=@pi_FechaAutorizacionFin 
			AND CONVERT(Date,ad.fechaAutoriza) >=@pi_FechaAutorizacionIni
--			AND (ISNULL(@pi_AsuntoNeunId,1) = iif(@pi_AsuntoNeunId is not null, ad.AsuntoNeunId,1))
		AND nep.TipoNotificacion IN (1, 3, 5, 6, 11,12) 

		SELECT COUNT(Parte) AS COUNTPARTE,
		 SUM(IIF(TieneArchivo=0 OR FechaNotificacion is null,0,1)) AS ConAcuse,
		 --CASE FechaNotificacion is null then 0 else 1 END)
        Asignados = SUM(IIF(ActuarioId is null or ActuarioId =10273, 0, 1)),
		AsuntoNeunId
		,AsuntoId
		,SintesisOrden
		,STRING_AGG(convert(nvarchar(MAX), concat(Nombre,' ', APaterno,' ',AMaterno) ), ', ') AS Nombres
		into #TempCantNotificaciones
		FROM #TMP_TABLE
		group by 
		 AsuntoNeunId
		,AsuntoId
		,SintesisOrden

		--Se genera conteo de actuarios asignados a partes
--		SELECT COUNT(ActuarioId) as CountActuarios
--		,AsuntoNeunId
--		,AsuntoId
--		,SintesisOrden
--		INTO #TMP_Actuario
--		FROM #TMP_TABLE
--		WHERE ActuarioId <> 10273
--		GROUP BY AsuntoNeunId
--		,AsuntoId
--		,SintesisOrden

		SELECT 	a.AsuntoAlias As No_Exp
                ,a.CatTipoAsuntoId as CatTipoAsuntoId
				,cto.Descripcion As TipoAsuntoDescripcion
				,ad.NombreArchivo+ ad.ExtensionDocumento as NombreArchivo
				,ISNULL(CONVERT(VARCHAR(10),ad.FechaAlta,103),'') as FechaAuto_F
				,FechaAutoriza = ad.FechaAutoriza
				,DATEDIFF(DD,ad.FechaAutoriza, GETDATE()) AS Transcurrido
				, ISNULL(tmpCN.COUNTPARTE,0) AS Notificados   -- Deberia ser por notificar
				,ISNULL(ConAcuse,0) AS ConAcuse
				--,CONVERT(VARCHAR(50), 'Pendiente') as Estado
--				,IIF(COUNTPARTE=ConAcuse,'Notificados','Pendiente') as Estado
                ,CASE 
                    WHEN ISNULL(tmpCN.Asignados,0) < ISNULL(tmpCN.COUNTPARTE,0) THEN 'Sin asignar'
                    WHEN ISNULL(tmpCN.COUNTPARTE,0) = ISNULL(ConAcuse,0) THEN 'Notificados'
                    ELSE 'Pendiente'
                END as Estado
--				,IIF(ISNULL(tmpCN.COUNTPARTE,0)=ISNULL(ConAcuse,0),'Notificados','Pendiente') as Estado
				,IIF(sa.StatusReg=1, sa.Sintesis, '') as Sintesis
				,a.AsuntoNeunId
				,ad.TipoCuaderno
                ,dbo.funRecuperaCatalogoDependienteDescripcion(527, ad.TipoCuaderno) as TipoCuadernoDesc
                ,p.Secretario as SecretarioPId
				,sa.UsuarioCaptura
				,ad.asuntoDocumentoId
				,sa.SintesisOrden
				,tmpCN.Nombres AS NombresPartes
				,(select CatalogoElementoDescripcion from CatalogosElementosDescripcion with(nolock) where CatalogoElementoDescripcionID = ad.CatContenidoId) as Contenido
--				,(select CatalogoPromocionDescripcion from CatPromocion with(nolock) where CatalogoPromocionId = ad.CatContenidoId) as Contenido
				,ad.CatContenidoId As ContenidoId
				,a.NumeroAlias
--				,Isnull(tmpac.CountActuarios,0) as CountActuarios
                ,ISNULL(tmpCN.Asignados,0) as Asignados
				,a.TipoProcedimiento as TipoProcedimiento
		INTO #TempActuaria 
		FROM 
		 AsuntosDocumentos ad WITH(NOLOCK) 
		CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
		JOIN CatOrganismos ct WITH(NOLOCK) on a.CatOrganismoId =ct.CatOrganismoId
		JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
		LEFT JOIN CatPlantillas cp ON cp.CatPlantillaId = ad.CatPlantillaId
		LEFT JOIN tbx_CatTiposAsunto ta ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId AND ad.TipoCuaderno = ta.CuadernoId
		LEFT JOIN SintesisAcuerdoAsunto sa  WITH(NOLOCK) on sa.AsuntoNeunId = ad.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden --- Se relaciona para obtener la fecha de captura 
		LEFT JOIN #TempCantNotificaciones tmpCN WITH(NOLOCK) ON tmpCN.AsuntoNeunId=	 ad.AsuntoNeunId AND tmpCN.AsuntoId=ad.AsuntoId AND tmpCN.SintesisOrden=ad.SintesisOrden
--		LEFT JOIN #TMP_Actuario tmpAc ON tmpAc.AsuntoNeunId=ad.AsuntoNeunId AND tmpAc.AsuntoId=ad.AsuntoId AND tmpAc.SintesisOrden=ad.SintesisOrden
		LEFT JOIN Promociones p WITH(NOLOCK) ON p.AsuntoNeunId = ad.AsuntoNeunId AND p.AsuntoId = ad.AsuntoId AND p.SintesisOrden = ad.SintesisOrden
        WHERE 
		ad.StatusReg=1
        AND ad.CatAutorizacionDocumentosId NOT IN (4,8,9)
        AND a.CatOrganismoId = @pi_CatOrganismoId
		AND  CONVERT(Date,ad.fechaAutoriza) <=@pi_FechaAutorizacionFin AND CONVERT(Date,ad.fechaAutoriza) >=@pi_FechaAutorizacionIni 
--		AND (ISNULL(@pi_AsuntoNeunId,1) = iif(@pi_AsuntoNeunId is not null, ad.AsuntoNeunId,1))

		DECLARE @Todos INT, @TresDias INT, @DosDias INT, @UnDia INT, @Notificados INT 

		--Se obtiene el conteo de los registros según estado de Captura y Asignación


		SELECT @Todos= COUNT(*) --, @Notificados=SUM(Notificados)
						FROM #TempActuaria
						WHERE IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
				        CONCAT(NombresPartes,No_Exp,Estado,Contenido,TipoAsuntoDescripcion,Sintesis,CONCAT(ConAcuse,' de ',Notificados)))
						LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
						AND ISNULL(@pi_Contenido,1) = IIF(@pi_Contenido IS NOT NULL, ContenidoId,1)
						AND ISNULL(@pi_Estado,'1') = IIF(@pi_Estado IS NOT NULL, ISNULL(Estado,'SIN ORIGEN'),'1')

		SET  @Notificados=(SELECT COUNT(*)
					FROM #TempActuaria
						WHERE IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
				        CONCAT(NombresPartes,No_Exp,Estado,Contenido,TipoAsuntoDescripcion,Sintesis,CONCAT(ConAcuse,' de ',Notificados)))
						LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
--						AND Notificados > 0
						AND (Notificados - ConAcuse)=0
						AND ISNULL(@pi_Contenido,1) = IIF(@pi_Contenido IS NOT NULL, ContenidoId,1)
						AND ISNULL(@pi_Estado,'1') = IIF(@pi_Estado IS NOT NULL, ISNULL(Estado,'SIN ORIGEN'),'1')
						)

		SET @TresDias = (	SELECT COUNT(*)
					FROM #TempActuaria
					WHERE IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
				        CONCAT(NombresPartes,No_Exp,Estado,Contenido,TipoAsuntoDescripcion,Sintesis,CONCAT(ConAcuse,' de ',Notificados)))
						LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
						AND DATEDIFF(DD,FechaAutoriza, GETDATE()) >= 3
						AND ISNULL(@pi_Contenido,1) = IIF(@pi_Contenido IS NOT NULL, ContenidoId,1)
						AND ISNULL(@pi_Estado,'1') = IIF(@pi_Estado IS NOT NULL, ISNULL(Estado,'SIN ORIGEN'),'1')
                        AND Notificados <> ConAcuse
						)
						
		SET @DosDias = (	SELECT COUNT(*)
					FROM #TempActuaria
					WHERE IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
				        CONCAT(NombresPartes,No_Exp,Estado,Contenido,TipoAsuntoDescripcion,Sintesis,CONCAT(ConAcuse,' de ',Notificados)))
						LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
						AND DATEDIFF(DD,FechaAutoriza, GETDATE()) = 2
						AND ISNULL(@pi_Contenido,1) = IIF(@pi_Contenido IS NOT NULL, ContenidoId,1)
						AND ISNULL(@pi_Estado,'1') = IIF(@pi_Estado IS NOT NULL, ISNULL(Estado,'SIN ORIGEN'),'1')
                        AND Notificados <> ConAcuse
						)
						

		SET @UnDia = (	SELECT COUNT(*)
					FROM #TempActuaria
					WHERE IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
				        CONCAT(NombresPartes,No_Exp,Estado,Contenido,TipoAsuntoDescripcion,Sintesis,CONCAT(ConAcuse,' de ',Notificados)))
						LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
						AND DATEDIFF(DD,FechaAutoriza, GETDATE()) <= 1
						AND ISNULL(@pi_Contenido,1) = IIF(@pi_Contenido IS NOT NULL, ContenidoId,1)
						AND ISNULL(@pi_Estado,'1') = IIF(@pi_Estado IS NOT NULL, ISNULL(Estado,'SIN ORIGEN'),'1')
                        AND Notificados <> ConAcuse
						)
						


		 Select @Todos AS [Todos], @TresDias AS [TresDias], @DosDias AS [DosDias], @unDia as [UnDia]	,@Notificados as [Notificados]

		 SELECT *
		 FROM #TempActuaria
		 WHERE IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
				        CONCAT(NombresPartes,No_Exp,Estado,Contenido,TipoAsuntoDescripcion,Sintesis,CONCAT(ConAcuse,' de ',Notificados)))
						LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
						AND ISNULL(@pi_Contenido,1) = IIF(@pi_Contenido IS NOT NULL, ContenidoId,1)
						AND ISNULL(@pi_Estado,'1') = IIF(@pi_Estado IS NOT NULL, ISNULL(Estado,'SIN ORIGEN'),'1')
						AND IIF(@pi_FiltroTipo=1, Transcurrido, 1) = IIF(@pi_FiltroTipo=1, 2, 1) 
						AND IIF(@pi_FiltroTipo=3, Transcurrido, 1) <= IIF(@pi_FiltroTipo=2, 1, 1)
						AND IIF(@pi_FiltroTipo=2, Transcurrido, 1) >= IIF(@pi_FiltroTipo=2, 3, 1) 
						AND IIF(@pi_FiltroTipo in (1,2,3),  Notificados - ConAcuse, 1) >= IIF(@pi_FiltroTipo in (1,2,3), 1, 1) 
--						AND IIF(@pi_FiltroTipo=2,  Notificados - ConAcuse, 1) >= IIF(@pi_FiltroTipo=2, 1, 1) 
						AND ( IIF(@pi_FiltroTipo=4, Notificados - ConAcuse, 1) = IIF(@pi_FiltroTipo=4, 0, 1) )

						/*
						AND (
								CASE 
								WHEN @pi_FiltroTipo 1 then Transcurrido = 2
								WHEN @pi_FiltroTipo 2 then Transcurrido >= 3
								WHEN @pi_FiltroTipo 3 then Transcurrido = 1
								WHEN @pi_FiltroTipo 4 then (Notificados - ConAcuse) = 0
								END
							)*/
		ORDER BY 
			CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 0 THEN NumeroAlias END ASC,
			CASE WHEN (@pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 1) THEN NumeroAlias END DESC,
			CASE WHEN @pi_OrdenarPor= 'Acuerdo' and @pi_TipoOrden = 0 THEN Contenido END ASC,
			CASE WHEN (@pi_OrdenarPor= 'Acuerdo' and @pi_TipoOrden = 1) THEN Contenido END DESC,
			CASE WHEN @pi_OrdenarPor= 'IngresoActuaria' and @pi_TipoOrden = 0 THEN fechaAutoriza END ASC,
			CASE WHEN (@pi_OrdenarPor= 'IngresoActuaria' and @pi_TipoOrden = 1) THEN fechaAutoriza END DESC,
			CASE WHEN @pi_OrdenarPor= 'Transcurrido' and @pi_TipoOrden = 0 THEN Transcurrido END ASC,
			CASE WHEN @pi_OrdenarPor= 'Transcurrido' and @pi_TipoOrden = 1 THEN Transcurrido END DESC,
			CASE WHEN @pi_OrdenarPor= 'Partes' and @pi_TipoOrden = 0 THEN NombresPartes END ASC,
			CASE WHEN @pi_OrdenarPor= 'Partes' and @pi_TipoOrden = 1 THEN NombresPartes END DESC,
			CASE WHEN @pi_OrdenarPor= 'Estado' and @pi_TipoOrden = 0 THEN Estado END ASC,
			CASE WHEN @pi_OrdenarPor= 'Estado' and @pi_TipoOrden = 1 THEN Estado END DESC,
			--CASE WHEN @pi_OrdenarPor= 'Sintesis' and @pi_TipoOrden = 0 THEN Sintesis END ASC,
			--CASE WHEN @pi_OrdenarPor= 'Sintesis' and @pi_TipoOrden = 1 THEN Sintesis END DESC,
			CASE WHEN @pi_OrdenarPor not in('Expediente','Acuerdo','IngresoActuaria','Transcurrido','Partes','Estado','Sintesis') THEN FechaAutoriza END DESC
			OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
			FETCH NEXT iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)  ROWS ONLY

--Select * from #TMP_TABLE
--Select * from #TempCantNotificaciones
--Select * from #TempActuaria
--Select * from #TMP_Actuario
--
--		SELECT count(*)
--		FROM #TempActuaria
--			WHERE IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
--		       CONCAT(NombresPartes,No_Exp,Estado,Contenido,TipoAsuntoDescripcion,Sintesis,CONCAT(ConAcuse,' de ',Notificados)))
--			LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
--			AND Notificados > 0
--			AND (Notificados - ConAcuse)=0
--			AND ISNULL(@pi_Contenido,1) = IIF(@pi_Contenido IS NOT NULL, ContenidoId,1)
--			AND ISNULL(@pi_Estado,'1') = IIF(@pi_Estado IS NOT NULL, ISNULL(Estado,'SIN ORIGEN'),'1')
						

			drop table #TMP_TABLE
			drop table #TempCantNotificaciones
			drop table #TempActuaria
--			drop table #TMP_Actuario

END;
