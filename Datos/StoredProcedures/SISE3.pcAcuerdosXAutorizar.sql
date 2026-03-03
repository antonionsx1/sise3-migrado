SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- =============================================
-- Author:  Diana Quiroga MS
-- Alter date:  02/10/2023
-- Description: Inserta y actualizar Asunto Documento 
-- Basado en:   uspx_tt_getTableroTramite
/*
EXECUTE [SISE3].[pcAcuerdosXAutorizar]
   @pi_CatOrganismoId = 1494
  ,@pi_TamanoPagina = 0
  ,@pi_NumeroPagina = 1
  ,@pi_AsuntoNeunId = 0
  ,@pi_FechaPresentacionIni = '2024-02-13'
  ,@pi_FechaPresentacionFin = '2024-02-13'
  ,@pi_UsuariId = 6712
  ,@pi_Texto = ''
  ,@pi_OrdenarPor = promocion
  ,@pi_TipoOrden = 1
  ,@pi_FiltroTipo = 2
GO
*/

-- =============================================
CREATE OR ALTER PROCEDURE [SISE3].[pcAcuerdosXAutorizar] 
    -- REPRESENTA EL IDENTIFICADOR DEL ORGANISMO
	@pi_CatOrganismoId INT,	
	-- REPRESENTA EL TAMAÑO DE PAGINACIÓN DE REGISTROS  
	@pi_TamanoPagina INT = NULL,
	--REPRESENTA EL NUMERO DE PÁGINA DE LA PAGINACIÓN
	@pi_NumeroPagina INT,
	-- REPRESENTA EL IDENTIFICADOR DEL EXPEDIENTE - PUEDE LLEGAR NULA
	@pi_AsuntoNeunId BIGINT = NULL,
	-- REPRESENTA LA FECHA DE INICIO DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionIni DATE = NULL,
	-- REPRESENTA LA FECHA FIN DEL REPORTE - PUEDE LLEGAR NULA
	@pi_FechaPresentacionFin DATE = NULL,
	-- REPRESENTA EL IDENTITICADOR DEL EMPLEADO - PUEDE LLEGAR NULA
	@pi_UsuariId INT = NULL,
	-- REPRESENTA LA BUSQUEDA DE PROMOCIONES CON(1) o SIN ACUERTO(0) - PUEDE LLEGAR NULA
	@pi_SinConAcuerdo BIT = NULL,
	-- Recibe valor para búsqueda en los campos de texto, PUEDE SER NULO
	@pi_Texto VARCHAR(MAX) = NULL,
	-- Recibe valor para ordenamiento de la página, PUEDE SER NULO, si es nulo ordena por fecha, de lo contrario por el campo recibido
	@pi_OrdenarPor VARCHAR(128) = NULL,
	-- Recibe configuración de ordenamiento Ascendente o Descendente? 1=Descendente 0=Ascendente
	@pi_TipoOrden INT = NULL,
	--Recibe parámetro del tipo de filtro 0=VerTodas, 1=Sin Captura, 2=Capturadas, 4=Asignadas
	@pi_FiltroTipo INT = 0, 
	--Recibe parametro Secretario Id 
	@pi_SecretarioId BIGINT =NULL,
	--Recibe origen id
	@pi_Origen VARCHAR(25) =NULL,
	--Recibe Asunto id
	@pi_CatTipoAsuntoId INT =NULL,
	--Recibe Capturo id
	@pi_CapturoId BIGINT =NULL,
	--Recibe Preautorizo id
	@pi_PreautorizoId BIGINT =NULL,
	--Recibe Autorizo id
	@pi_AutorizoId BIGINT =NULL,
	--Recibe Cancelo id
	@pi_CanceloId BIGINT =NULL
AS
BEGIN

        /*
        SET @pi_CatOrganismoId = 772
        SET @pi_FechaPresentacionIni = '2013-03-01' 
        SET @pi_FechaPresentacionFin = '2013-04-30'
        SET @pi_TipoFecha = 1
        SET @pi_UsuariId  = 52936
        */
        
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
		DECLARE @Mesa VARCHAR(100)
		
		--LIMPIO VARIABLE DE ORDER BY PARA REMOVER ESPACIOS EN BLANCO
		IF @pi_OrdenarPor IS NOT NULL
		BEGIN
			SET @pi_OrdenarPor = ltrim(rtrim(@pi_OrdenarPor))
		END
		-- SI LA FECHA INICIAL ES NULA, SE ASIGNA EL VALOR DEL DÍA
		IF @pi_FechaPresentacionIni IS NULL
		BEGIN
			SET @pi_FechaPresentacionIni = convert(date,getdate())
		END
		-- SI LA FECHA FIN ES NULA SE ASIGNA EL VALOR DE LA FECHA DE INICIO 
		IF @pi_FechaPresentacionFin IS NULL
		BEGIN
			SET @pi_FechaPresentacionFin = ISNULL(@pi_FechaPresentacionFin,@pi_FechaPresentacionIni)
		END
		DECLARE @Tramites SISE3.Tramites_type, @Tramites_Final SISE3.Tramites_type
		
		--Validar Filtros existentes
		IF @pi_FiltroTipo NOT IN (0,1,2,3,4,5)
		BEGIN
			SET @pi_FiltroTipo = 0
		END

		IF TRIM(@pi_Origen)= ''
			SET @pi_Origen = NULL
                
        /* SE VALIDAN VALORES NULOS PARA INDICAR VALORES POR DEFAULT */
        SET @pi_FechaPresentacionFin = ISNULL(@pi_FechaPresentacionFin,@pi_FechaPresentacionIni)
        SET @pi_TipoFecha = ISNULL(@pi_TipoFecha,0)
        
        /* CONSULTO EL CARGO DEL EMPLEADO */
        SELECT @CargoId = CargoId 
        FROM EmpleadoOrganismo WITH(NOLOCK) 
        WHERE  EmpleadoId = @pi_UsuariId 
		AND StatusRegistro = 1	
        AND CatOrganismoId = @pi_CatOrganismoId
        AND CargoId IN (4,5,18,19)

        
        /* CONSULTO EL PERMISO DEL EMPLEADO */
        SELECT @Permiso = ISNULL(Permiso,0)
        FROM EmpleadoPermisoAutorizaPanel WITH(NOLOCK) 
        WHERE EmpleadoId=@pi_UsuariId  
        AND CatOrganismoId=@pi_CatOrganismoId    
        --AND = 1
        
        IF(@CargoId IN (4,5) OR @Permiso = 12490)/* TITULARES Y PERMISO DE AUTORIZAR Y CANCELAR */
        BEGIN
                SET @Autoriza = 1
                SET @Cancela = 1
                SET @CancelaPreautorizado = 1
        END
        ELSE IF(@CargoId IN (18,19) OR @Permiso = 12496)/* SECRETARIOS Y PERMISOS PARA PREAUTORIZAR Y CANCELAR */
        BEGIN
                SET @Preautoriza = 1
                SET @CancelaPreautorizado = 1
        END
        ELSE IF(@Permiso = 12488)/* AUTORIZA */
        BEGIN
                SET @Autoriza = 1
        END
        ELSE IF(@Permiso = 12489) /* CANCELAR */
        BEGIN
                SET @Cancela = 1
        END
        ELSE IF (@Permiso = 12497) /*CANCELAR PREAUTORIZADO*/
        BEGIN
                SET @CancelaPreautorizado = 1
        END
        ELSE IF (@Permiso = 12495) /*PREAUTORIZA*/
        BEGIN
                SET @Preautoriza = 1
        END



		SELECT TOP 1  @Mesa = a.Descripcion
		FROM CatEmpleados e WITH (NOLOCK) 
		INNER JOIN EmpleadoOrganismo eo WITH (NOLOCK) 
			ON e.EmpleadoId = eo.EmpleadoId 
		LEFT JOIN Areas a WITH(NOLOCK) 
			ON a.EmpleadoId = e.EmpleadoId 
			AND a.CatOrganismoId = eo.CatOrganismoId
		WHERE e.StatusRegistro = 1 
		AND eo.StatusRegistro = 1 
		AND eo.cargoId IN (14,18,19) 
		AND eo.CatOrganismoId = @pi_CatOrganismoId
		AND e.EmpleadoId NOT IN (SELECT EmpleadoId 
								 FROM EmpleadoOrganismo 
								 WHERE CatOrganismoId in (3,1580) 
								 AND StatusRegistro=1)
		AND e.EmpleadoId = @pi_UsuariId

        
		/* SE EJECUTA EL PRIMER SP QUE EXTRAE LA INFORMACION DE PROMOCIONES CON SU CORESPONDIENTE ACUERDO SI LO TIENE Y EL RESULTADO SE INSERTA EN LA TABLA TEMPORAL */
		/***** TRAMITES ****/
		INSERT INTO @Tramites
		([No_Exp], [TipoAsuntoDescripcion], [NumeroRegistro], [TipoPromocionDescripcion], [FechaRecibido], [NumeroOrden], [NombreTipoCuaderno],
		[Promovente],[TipoContenidoDescripcion], [Contenido], [Copias], [Anexos], [Estado], [Mesa], [SecretarioDescripcion], [FechaAuto], [Plantilla], 
		[AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], [NombreArchivo], [NombreCapDJ], [EstadoAutorizacion], [NumeroAlias], [ArchivoPromocion], 
		[NombreOrigen], [EmpleadoCancela], [EmpleadoAutoriza], [EmpleadoPreAutoriza], [FechaAutoriza], [FechaPreAutoriza], [FechaCancela], [userNameCapDJ], [userNameSecretario], [FechaRecibido_F],
		[FechaAuto_F],	[NombreDocumento], [YearPromocion], [TipoAsuntoId], [TipoCuadernoId], [NombreCorto] , [RutaArchivoNAS] , [Origen], 
		[SintesisOrden], [TipoProcedimiento], [secretarioId], [OrigenId], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId],[GuidDocumento])
		SELECT 
				a.AsuntoAlias As No_Exp
				,cto.Descripcion As TipoAsuntoDescripcion
				,p.NumeroRegistro
				,TipoPromocionDescripcion = CASE ClasePromocion WHEN '1' THEN 'Escrito' ELSE 'Oficio' END       
				,CONVERT(DATETIME,p.FechaPresentacion + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END) As FechaRecibido
				,p.NumeroOrden
				,dbo.funRecuperaCatalogoDependienteDescripcion(527,p.TipoCuaderno) as NombreTipoCuaderno
				,Promovente = ISNULL(
				CASE WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid = 1 THEN SISE3.ConcatenarNombres(pas.Nombre, pas.APaterno, pas.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1) = 1 and pas.CatTipoPersonaid <> 1 THEN pas.DenominacionDeAutoridad
					WHEN ISNULL(p.ClasePromovente,1) = 2 THEN SISE3.ConcatenarNombres(pr.Nombre, pr.APaterno,pr.AMaterno)
					WHEN ISNULL(p.ClasePromovente,1)  = 3 THEN SISE3.ConcatenarNombres(ea.Nombre, ea.ApellidoPaterno, ea.ApellidoMaterno)
					WHEN ISNULL(p.ClasePromovente,1)  =4 THEN ajo.AJONombre
					END,'')
				,TipoContenidoDescripcion = ISNULL((SELECT CatalogoPromocionDescripcion FROM CatPromocion with(nolock) where CatalogoPromocionId=TipoContenido),'')
				,(select CatalogoElementoDescripcion from CatalogosElementosDescripcion with(nolock) where CatalogoElementoDescripcionID = ad.CatContenidoId) as Contenido
				,ISNULL(p.[NumeroCopias],0) As Copias
				,ISNULL(p.[NumeroAnexos],0) As Anexos
				,isnull(dbo.fnDevuelveElementoCatalogo(p.EstadoPromocion),'Pendiente') as Estado        
				,Mesa = p.Mesa
				,SecretarioDescripcion =  SISE3.ConcatenarNombres(s.Nombre,s.ApellidoPaterno,s.ApellidoMaterno)
				,ISNULL(sa.FechaActualizacion,sa.FechaAlta) as FechaAuto
				,CAST(cp.CatPlantillaId AS VARCHAR(10)) + ' - ' + cp.NombrePlantilla As Plantilla
				,a.AsuntoNeunId
				,a.CatTipoAsuntoId
				,p.AsuntoDocumentoId
				,ad.NombreArchivo+ ad.ExtensionDocumento as NombreArchivo
				,NombreCapDJ = dbo.FNOBTIENEEMPLEADO(ad.CreadorId)
				,ad.CatAutorizacionDocumentosId as EstadoAutorizacion
				,a.NumeroAlias
				,pa.NombreArchivo as ArchivoPromocion
				,NombreOrigen = /*CASE OrigenPromocion 
										WHEN '0' THEN 'SISE' 
										WHEN '1' THEN 'FESE' 
										WHEN '2' THEN 'San Lazaro' 
										WHEN '3' THEN 'VET' 
										WHEN '4' THEN 'Oficialía de Partes Virtual' 
										WHEN '5' THEN 'JUICIO EN LINEA' 
										WHEN '6' THEN 'SOLICITUD PGR' 
										WHEN '7' THEN 'OFICIALIA DE PARTES' ELSE 'S/O' END*/
									ISNULL(co.sNombreOrigenPromocion,'SIN ORIGEN')
				,EmpleadoCancela = dbo.fnx_getUserName(ad.EmpleadoIdCancela)
				,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
				,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
				,FechaAutoriza = ad.FechaAutoriza
				,FechaPreAutoriza = ad.FechaPreAutoriza
				,FechaCancela = ad.FechaCancela
				,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
				,userNameSecretario = s.UserName --dbo.fnx_getUserName(p.Secretario)
				,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
						ELSE '' END As FechaRecibido_F
				,ISNULL(CONVERT(VARCHAR(10),ad.FechaAlta,103),'') as FechaAuto_F
				,ad.NombreDocumento
				,p.YearPromocion
				,TipoAsuntoId = cto.CatTipoAsuntoId
				,TipoCuadernoId = p.TipoCuaderno
				,ta.nombreCorto
				,RutaArchivoNAS = ISNULL(pa.RutaArchivoNAS,0)
				,Origen = co.kIdOrigenPromocion
				,sa.SintesisOrden
				,a.TipoProcedimiento
				,p.Secretario
				,p.OrigenPromocion
				,ad.CreadorId
				,ad.EmpleadoIdPreautoriza
				,ad.EmpleadoIdAutoriza
				,ad.EmpleadoIdCancela
				,ad.uGuidDocumento GuidDocumento
		FROM Promociones p WITH(NOLOCK)
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
	--	JOIN Asuntos a WITH(NOLOCK) on a.AsuntoNeunId= p.AsuntoNeunId
		JOIN CatOrganismos ct WITH(NOLOCK) on a.CatOrganismoId =ct.CatOrganismoId
		JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
		LEFT JOIN PromocionArchivos pa WITH(NOLOCK) on pa.AsuntoNeunId=p.AsuntoNeunId and pa.NumeroOrden=p.NumeroOrden and pa.NumeroRegistro=p.NumeroRegistro
				AND pa.YearPromocion=p.YearPromocion and pa.StatusArchivo=1 AND pa.ClaseAnexo = 0
		LEFT JOIN AsuntosDocumentos ad WITH(NOLOCK) on a.AsuntoNeunId = ad.AsuntoNeunId and ad.AsuntoDocumentoId=p.AsuntoDocumentoId AND a.AsuntoId = ad.AsuntoID AND p.StatusReg=ad.StatusReg
		LEFT JOIN CatPlantillas cp ON cp.CatPlantillaId = ad.CatPlantillaId
		LEFT JOIN tbx_CatTiposAsunto ta ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId AND p.TipoCuaderno = ta.CuadernoId
		LEFT JOIN PersonasAsunto pas ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1
		LEFT JOIN Promovente pr ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 and pr.AsuntoNeunId = p.AsuntoNeunId
		LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
		LEFT JOIN CatEmpleados ea WITH(NOLOCK) ON ea.EmpleadoId = aj.EmpleadoId
		LEFT JOIN AutoridadJudicial_Otros ajo ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4
		LEFT JOIN CatEmpleados s WITH(NOLOCK) ON s.EmpleadoId = p.Secretario
		LEFT JOIN SintesisAcuerdoAsunto sa  WITH(NOLOCK) on sa.AsuntoNeunId = ad.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden --- Se relaciona para obtener la fecha de captura 
		LEFT JOIN SISE3.CAT_OrigenPromocion​ co WITH(NOLOCK) on co.kIdOrigenPromocion = p.OrigenPromocion
		WHERE 
		p.StatusReg=1
--		AND A.StatusReg=1 
		AND p.CatOrganismoId=@pi_CatOrganismoId
		--AND p.Mesa = @Mesa
		AND [SISE3].[fnEstatusPromocion] (NULL , IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0), pa.NombreArchivo, p.OrigenPromocion, NULL) = 4
		AND CAST(p.FechaPresentacion AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE)
         
		
		/* SE ACTUALIZA EL CAMPO ORIGEN DE LA TEMPORAL PARA INDICAR QUE LA INFORMACION ES DE PROMOCIONES */
		--UPDATE @Tramites 
		--SET Origen = NombreOrigen
	
	
		/* SE EJECUTA EL SEGUNDO SP QUE EXTRAE LA INFORMACION DE ACUERDO DE PROMOCIONES Y SE INSERTA EN LA TABLA TEMPORAL */
			INSERT INTO @Tramites
			([No_Exp], [TipoAsuntoDescripcion], [NumeroRegistro], [TipoPromocionDescripcion], [FechaRecibido], [NumeroOrden], [NombreTipoCuaderno],
			[Promovente],[TipoContenidoDescripcion], [Contenido], [Copias], [Anexos], [Estado], [Mesa], [SecretarioDescripcion], [FechaAuto], [Plantilla], 
			[AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], [NombreArchivo], [NombreCapDJ], [EstadoAutorizacion], [NumeroAlias], [ArchivoPromocion], 
			[NombreOrigen], [EmpleadoCancela], [EmpleadoAutoriza], [EmpleadoPreAutoriza],[FechaAutoriza],[FechaPreAutoriza], [FechaCancela], [userNameCapDJ], [userNameSecretario], [FechaRecibido_F],
			[FechaAuto_F],	[NombreDocumento], [YearPromocion], [TipoAsuntoId], [TipoCuadernoId], [NombreCorto] , [RutaArchivoNAS], [SintesisOrden], [TipoProcedimiento], [secretarioId],
			[OrigenId], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId],[GuidDocumento])
            SELECT 
				a.AsuntoAlias As No_Exp
				,cto.Descripcion As TipoAsuntoDescripcion
				,p.NumeroRegistro
				,TipoPromocionDescripcion = CASE ClasePromocion WHEN '1' THEN 'Escrito' ELSE 'Oficio' END       
				,CONVERT(DATETIME,p.FechaPresentacion + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN p.HoraPresentacion ELSE '' END)  As FechaRecibido
				,p.NumeroOrden
				,dbo.funRecuperaCatalogoDependienteDescripcion(495,p.TipoCuaderno) as NombreTipoCuaderno
				,dbo.funNombreParte(TipoPromovente,isnull(ClasePromovente,1)) as Promovente
				,TipoContenidoDescripcion = ISNULL((SELECT CatalogoPromocionDescripcion FROM CatPromocion with(nolock) where CatalogoPromocionId=TipoContenido),'')
				,(select CatalogoElementoDescripcion from CatalogosElementosDescripcion with(nolock) where CatalogoElementoDescripcionID = ad.CatContenidoId) as Contenido
				,ISNULL(p.[NumeroCopias],0) As Copias
				,ISNULL(p.[NumeroAnexos],0) As Anexos
				,isnull(dbo.fnDevuelveElementoCatalogo(p.EstadoPromocion),'Pendiente') as Estado        
				,Mesa = p.Mesa
				,SecretarioDescripcion =  SISE3.ConcatenarNombres(eas.Nombre,eas.ApellidoPaterno,eas.ApellidoMaterno)
				,sa.FechaAlta as FechaAuto
				,CAST(cp.CatPlantillaId AS VARCHAR(10)) + ' - ' + cp.NombrePlantilla As Plantilla
				,a.AsuntoNeunId
				,a.CatTipoAsuntoId
				,p.AsuntoDocumentoId
				,ad.NombreArchivo+ ad.ExtensionDocumento as NombreArchivo
				,NombreCapDJ = dbo.FNOBTIENEEMPLEADO(ad.CreadorId)
				,ad.CatAutorizacionDocumentosId as EstadoAutorizacion
				,a.NumeroAlias
				,pa.NombreArchivo as ArchivoPromocion
				,NombreOrigen = /*CASE OrigenPromocion 
									WHEN '0' THEN 'SISE' 
									WHEN '1' THEN 'FESE' 
									WHEN '2' THEN 'San Lazaro' 
									WHEN '3' THEN 'VET'
									WHEN '4' THEN 'Oficialia de Partes Virtual' 
									WHEN  '5' THEN 'JUICIO EN LINEA' 
									WHEN  '6' THEN 'SOLICITUD PGR' 
									WHEN  '7' THEN 'OFICIALIA DE PARTES' 
								ELSE 'S/O' END*/ ISNULL(co.sNombreOrigenPromocion,'SIN ORIGEN')
				,EmpleadoCancela = dbo.fnx_getUserName(ad.EmpleadoIdCancela)
				,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
				,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
				,FechaAutoriza = ad.FechaAutoriza
				,FechaPreAutoriza = ad.FechaPreAutoriza
				,FechaCancela = ad.FechaCancela
				,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
				,userNameSecretario = eas.UserName  --dbo.fnx_getUserName(p.Secretario)
				,CONVERT(VARCHAR(10),p.FechaPresentacion,103) + CASE WHEN ISDATE(p.HoraPresentacion) = 1 THEN ' ' + CONVERT(VARCHAR(5),CONVERT(time,p.HoraPresentacion)) 
				ELSE '' END As FechaRecibido_F
				,CONVERT(VARCHAR(10),ad.FechaAlta,103) as FechaAuto_F
				,ad.NombreDocumento
				,p.YearPromocion
				,TipoAsuntoId = cto.CatTipoAsuntoId
				,TipoCuadernoId = p.TipoCuaderno
				,ta.nombreCorto
				,RutaArchivoNAS = ISNULL(pa.RutaArchivoNAS,0)
				,sa.SintesisOrden
				,a.TipoProcedimiento
				,p.secretario
				,p.OrigenPromocion
				,ad.CreadorId
				,ad.EmpleadoIdPreautoriza
				,ad.EmpleadoIdAutoriza
				,ad.EmpleadoIdCancela
				,ad.uGuidDocumento GuidDocumento
		FROM Promociones p WITH(NOLOCK)
		CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
		--JOIN Asuntos a WITH(NOLOCK) on a.AsuntoNeunId= p.AsuntoNeunId
		JOIN CatOrganismos ct WITH(NOLOCK) on a.CatOrganismoId =ct.CatOrganismoId
		JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
		LEFT JOIN PromocionArchivos pa WITH(NOLOCK) on pa.AsuntoNeunId=p.AsuntoNeunId and pa.NumeroOrden=p.NumeroOrden and pa.NumeroRegistro=p.NumeroRegistro
		and pa.YearPromocion=p.YearPromocion and pa.StatusArchivo=1 AND pa.ClaseAnexo = 0
		left join AsuntosDocumentos ad WITH(NOLOCK) on a.AsuntoNeunId = ad.AsuntoNeunId and ad.AsuntoDocumentoId=p.AsuntoDocumentoId AND a.AsuntoId = ad.AsuntoID AND p.StatusReg=ad.StatusReg
		left join CatPlantillas cp ON cp.CatPlantillaId = ad.CatPlantillaId
		LEFT JOIN tbx_CatTiposAsunto ta ON a.CatTipoAsuntoId = ta.CatTipoAsuntoId AND p.TipoCuaderno = ta.CuadernoId
		LEFT JOIN PersonasAsunto pas ON pas.PersonaId = p.TipoPromovente AND p.ClasePromovente = 1
		LEFT JOIN Promovente pr ON pr.PromoventeId = p.TipoPromovente AND p.ClasePromovente = 2 and pr.AsuntoNeunId = p.AsuntoNeunId
		LEFT JOIN AutoridadJudicial aj ON aj.AutoridadJudicialId = p.TipoPromovente AND p.ClasePromovente = 3
		LEFT JOIN CatEmpleados ea WITH(NOLOCK) ON ea.EmpleadoId = aj.EmpleadoId
		LEFT JOIN AutoridadJudicial_Otros ajo ON ajo.AJOId = p.TipoPromovente AND ajo.AJOEstatus = 1 AND p.ClasePromovente = 4
		LEFT JOIN CatEmpleados eas WITH(NOLOCK) ON eas.EmpleadoId = p.secretario
		LEFT JOIN @Tramites ts ON  p.AsuntoNeunId= ts.AsuntoNeunId and p.NumeroRegistro = ts.NumeroRegistro
		LEFT JOIN SintesisAcuerdoAsunto sa ON sa.AsuntoNeunId = ad.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden
		LEFT JOIN SISE3.CAT_OrigenPromocion​ co WITH(NOLOCK) on co.kIdOrigenPromocion = p.OrigenPromocion
		WHERE 
		p.StatusReg=1 
	--	AND A.StatusReg=1 
		AND p.CatOrganismoId=@pi_CatOrganismoId
		--AND p.Mesa = @Mesa
		AND CAST(ad.FechaAlta AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE)
		AND ts.NumeroRegistro IS NULL
		AND [SISE3].[fnEstatusPromocion] (NULL , IIF(p.OrigenPromocion IN (6,14,22,5,15,29),1,0), pa.NombreArchivo, p.OrigenPromocion, NULL) = 4
		
       
		/* SE ACTUALIZA EL CAMPO ORIGEN DE LA TEMPORAL PARA INDICAR QUE LA INFORMACION ES DE ACUERDOS SIN PROMOCIONES */
		UPDATE @Tramites 
		SET Origen = 'SIN ORIGEN'
		WHERE Origen IS NULL
		--fecha de presentación 

		/*Temporal carga de catalogos*/
		CREATE TABLE #CATALOGOS (ID INT, Descripcion varchar (250), elementos int)
		INSERT INTO #Catalogos
		execute usp_catalogosSel 496, 0, 0


		/*Cargar Asuntos Documentos que no tienen promoción*/
		CREATE TABLE #MaxSec
		(AsuntoNeunId BIGINT, 
		Expediente VARCHAR(50) collate SQL_Latin1_General_CP850_CI_AI, 
		Secretario INT,
		Id int 
		)

	
		SELECT a.AsuntoAlias 
		,cto.Descripcion As TipoAsuntoDescripcion
		,Mesa = dbo.fnx_getValorPorNeunPorDescripcion(a.AsuntoNeunId,'Mesa')
		,SecretarioDescripcion = dbo.fnx_getValorPorNeunPorDescripcion(a.AsuntoNeunId,'Secretario') 
		,a.AsuntoNeunId
		,a.AsuntoId
		,ad.AsuntoDocumentoId
		,ad.NombreArchivo+ ad.ExtensionDocumento as NombreArchivo
		,NombreCapDJ = dbo.FNOBTIENEEMPLEADO(ad.CreadorId)
		,ad.CatAutorizacionDocumentosId as EstadoAutorizacion
		,a.NumeroAlias
		,ad.NombreArchivo as ArchivoPromocion
		,EmpleadoCancela = dbo.fnx_getUserName(ad.EmpleadoIdCancela)
		,EmpleadoAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdAutoriza)
		,EmpleadoPreAutoriza = dbo.fnx_getUserName(ad.EmpleadoIdPreautoriza)
		,FechaAutoriza = ad.FechaAutoriza
		,FechaPreAutoriza = ad.FechaPreAutoriza
		,FechaCancela = ad.FechaCancela
		,userNameCapDJ = dbo.fnx_getUserName(ad.CreadorId)
		,CONVERT(VARCHAR(10),ad.FechaAlta,103) as FechaAuto_F
		,ad.NombreDocumento
		,TipoAsuntoId = cto.CatTipoAsuntoId
		,FechaRecibido = ad.FechaAlta
		,ad.SintesisOrden
		,a.TipoProcedimiento
		,ad.TipoCuaderno
		,dbo.funRecuperaCatalogoDependienteDescripcion(527,ad.TipoCuaderno) as NombreTipoCuaderno
		,p.OrigenPromocion
		,ad.CreadorId
		,ad.EmpleadoIdPreautoriza
		,ad.EmpleadoIdAutoriza
		,ad.EmpleadoIdCancela
		,ad.uGuidDocumento GuidDocumento
		--,ISNULL((SELECT Descripcion FROM #Catalogos with(nolock) where ID=ad.CatContenidoId),'') AS Contenido
		,ad.CatContenidoId
		INTO #TempSinPromocion
		FROM AsuntosDocumentos ad  WITH(NOLOCK)
		--JOIN Asuntos a WITH(NOLOCK) ON  a.AsuntoNeunId= ad.AsuntoNeunId
		CROSS APPLY SISE3.fnExpediente(ad.AsuntoNeunId) a
		JOIN CatOrganismos ct WITH(NOLOCK) on a.CatOrganismoId =ct.CatOrganismoId
		JOIN CatTiposAsunto cto WITH (NOLOCK) on a.CatTipoAsuntoId = cto.CatTipoAsuntoId
		LEFT JOIN Promociones p WITH (NOLOCK) ON a.AsuntoNeunId= p.AsuntoNeunId AND ad.AsuntoDocumentoId= p.AsuntoDocumentoId
		LEFT JOIN SintesisAcuerdoAsunto si ON si.AsuntoNeunId = ad.AsuntoNeunId and si.SintesisOrden = ad.SintesisOrden
		LEFT JOIN SISE3.CAT_OrigenPromocion​ co WITH(NOLOCK) on co.kIdOrigenPromocion = p.OrigenPromocion
		WHERE-- a.StatusReg=1 
		ad.StatusReg=1 
		AND a.CatOrganismoId=@pi_CatOrganismoId
		AND CAST(ad.FechaAlta AS DATE) between CAST(@pi_FechaPresentacionIni AS DATE) and CAST(@pi_FechaPresentacionFin AS DATE)
		AND p.AsuntoDocumentoId IS NULL
		
		INSERT INTO #MaxSec
		SELECT p.AsuntoNeunId, 
		a.AsuntoAlias ,
		p.Secretario,
		ROW_NUMBER() OVER (PARTITION BY p.AsuntoNeunId, a.AsuntoAlias ORDER BY p.FechaPresentacion DESC) AS id
		FROM Promociones p WITH(NOLOCK) 
			CROSS APPLY SISE3.fnExpediente(p.AsuntoNeunId) a
			INNER JOIN @Tramites t ON p.AsuntoNeunId = t.AsuntoNeunId and a.AsuntoAlias = t.No_Exp 
			INNER JOIN #TempSinPromocion ts ON t.AsuntoNeunId = t.AsuntoNeunId and a.AsuntoAlias = ts.AsuntoAlias
		WHERE p.StatusReg=1 


		INSERT INTO @Tramites
			([No_Exp], [TipoAsuntoDescripcion] , [Mesa], [SecretarioDescripcion], [AsuntoNeunId], [AsuntoId], [AsuntoDocumentoId], 
			[NombreArchivo], [NombreCapDJ], [EstadoAutorizacion], [NumeroAlias], [ArchivoPromocion], 
			[EmpleadoCancela], [EmpleadoAutoriza], [EmpleadoPreAutoriza], [FechaAutoriza],[FechaPreAutoriza], [FechaCancela], [userNameCapDJ], 
			[FechaAuto_F],	[NombreDocumento], [TipoAsuntoId],FechaRecibido,[FechaAuto], [SintesisOrden],[TipoProcedimiento],TipoCuadernoId, NombreTipoCuaderno ,
			[secretarioId], [OrigenId], [CapturoId], [PreautorizoId], [AutorizoId],[CanceloId], [GuidDocumento], Contenido)

		SELECT ad.AsuntoAlias 
		,ad.TipoAsuntoDescripcion
		,ad.Mesa 
		,SecretarioDescripcion =  SISE3.ConcatenarNombres(eas.Nombre,eas.ApellidoPaterno,eas.ApellidoMaterno)
		,ad.AsuntoNeunId
		,ad.AsuntoId
		,ad.AsuntoDocumentoId
		,ad.NombreArchivo
		,ad.NombreCapDJ
		,ad.EstadoAutorizacion
		,ad.NumeroAlias
		,ad.NombreArchivo
		,ad.EmpleadoCancela 
		,ad.EmpleadoAutoriza 
		,ad.EmpleadoPreAutoriza 
		,ad.FechaAutoriza 
		,ad.FechaPreAutoriza 
		,ad.FechaCancela
		,ad.userNameCapDJ 
		,ad.FechaAuto_F
		,ad.NombreDocumento
		,ad.TipoAsuntoId
		,ad.FechaRecibido
		,ISNULL(sa.FechaActualizacion, sa.FechaAlta)
		,ad.SintesisOrden
		,ad.TipoProcedimiento
		,ad.TipoCuaderno
		,ad.NombreTipoCuaderno
		,m.Secretario
		,ad.OrigenPromocion
		,ad.CreadorId
		,ad.EmpleadoIdPreautoriza
		,ad.EmpleadoIdAutoriza
		,ad.EmpleadoIdCancela
		,ad.GuidDocumento
		,ISNULL((SELECT Descripcion FROM #Catalogos with(nolock) where ID=ad.CatContenidoId),'') AS Contenido
		FROM #TempSinPromocion ad 
		LEFT JOIN #MaxSec m ON  m.AsuntoNeunId= ad.AsuntoNeunId and m.Expediente = ad.AsuntoAlias and m.id = 1
		LEFT JOIN CatEmpleados eas WITH(NOLOCK) ON eas.EmpleadoId = m.Secretario
		LEFT JOIN SintesisAcuerdoAsunto sa ON sa.AsuntoNeunId = ad.AsuntoNeunId and sa.SintesisOrden = ad.SintesisOrden
		
		
		SELECT DISTINCT 
					p.No_Exp,
					p.TipoAsuntoDescripcion, 
					p.NombreOrigen,
					p.NumeroRegistro,
					p.NumeroOrden,
					p.ArchivoPromocion,
					p.FechaRecibido,
					TipoContenidoDescripcion = ISNULL(p.TipoContenidoDescripcion,''),
					SecretarioDescripcion = ISNULL(LTRIM(RTRIM(p.SecretarioDescripcion)),''),
					p.NombreTipoCuaderno,
					[Promovente] = ISNULL(LTRIM(RTRIM(REPLACE(p.[Promovente],'( ','('))),''),
					FechaAuto = p.FechaAuto,
					Plantilla = ISNULL(p.Plantilla,''),
					Mesa = ISNULL(p.Mesa,''),
					NombreCapDJ = ISNULL(LTRIM(RTRIM(p.NombreCapDJ)),''),
					NombreDocumento = ISNULL(p.NombreDocumento,''),
					ISNULL(p.EstadoAutorizacion,0)EstadoAutorizacion,
					ISNULL(cad.DescripcionAutorizacion,'')EstadoAutorizacionDescripcion,
					p.EmpleadoPreAutoriza,
					p.EmpleadoAutoriza,
					p.EmpleadoCancela,
					p.AsuntoNeunId,
					p.AsuntoId,
					p.AsuntoDocumentoId, 
					p.Origen,
					FechaPreAutoriza = p.FechaPreAutoriza, -- dbo.fnx_getFechaPorAutorizacionDocumento(p.EmpleadoPreAutoriza,p.AsuntoNeunId,p.AsuntoDocumentoId,2),
					FechaAutoriza = p.FechaAutoriza,--dbo.fnx_getFechaPorAutorizacionDocumento(p.EmpleadoAutoriza,p.AsuntoNeunId,p.AsuntoDocumentoId,3),
					FechaCancela = p.FechaCancela, --dbo.fnx_getFechaPorAutorizacionDocumento(p.EmpleadoCancela,p.AsuntoNeunId,p.AsuntoDocumentoId,4),
					UserNameSecretario = LOWER(p.userNameSecretario),
					UserNameOficial = LOWER(p.userNameCapDJ),
					NumeroAlias = p.NumeroAlias,
					Cancela = CAST(CASE WHEN (@Cancela = 1 AND p.EstadoAutorizacion = 3) OR 
																	 (@CancelaPreautorizado = 1 AND p.EstadoAutorizacion = 2) OR 
																	 (p.AsuntoDocumentoId > 0 AND p.EstadoAutorizacion IN(3,2,1) AND (@CargoId IN (/*18,19,*/4,5) OR @Permiso IN(12496,12490)))OR
																	 (p.AsuntoDocumentoId > 0 AND p.EstadoAutorizacion IN(1,5) AND (@CargoId IN (18,19,4,5) OR @Permiso IN(12496,12490))) 
													THEN 1 ELSE 0 END AS BIT),
					Preautoriza = CAST(CASE WHEN (@Preautoriza = 1 AND p.EstadoAutorizacion IN (1,4,5) ) THEN 1 ELSE 0 END AS BIT),
					Autoriza = CAST(CASE WHEN (@Autoriza = 1 AND p.EstadoAutorizacion IN (2,1,4,5) ) THEN 1 ELSE 0 END AS BIT),
					ISNULL(FechaRecibido_F,'')FechaRecibido_F ,
					ISNULL(FechaAuto_F,'')FechaAuto_F,
					ISNULL(NombreArchivo,'')NombreArchivo,
					OrigenCorto = CASE p.Origen WHEN  'SISE' THEN 'SISE' WHEN  'FESE' THEN 'FESE'  WHEN 'San Lazaro' THEN 'SL' WHEN  'VET' THEN 'VET' WHEN  'Oficialía de Partes Virtual' THEN 'OPV' WHEN  'Acuerdo sin Promociones' THEN 'S/P' ELSE 'S/O' END
					,p.YearPromocion
					,EmpleadoElimina = ISNULL(bap.Empleado,'')
					,UserNameElimina = ISNULL(bap.UserName,'')
					,FechaElimina = ISNULL(CONVERT (VARCHAR(15), bap.FechaAlta,103) + ' ' + CONVERT(VARCHAR(5),CONVERT(TIME,bap.FechaAlta)),'')
					, TipoAsuntoId
					,TipoCuadernoId
					,NombreCorto = ISNULL(NombreCorto,'')
					,RutaArchivoNAS
					,SintesisOrden
					,TipoProcedimiento
					,p.secretarioId
					,p.OrigenId
					,p.CapturoId
					,p.PreautorizoId
					,p.AutorizoId
					,p.CanceloId
					,p.Contenido
					,p.GuidDocumento
				INTO #TramiteFinal
		FROM @Tramites p
		LEFT JOIN CatAutorizacionesDocumentos cad ON p.EstadoAutorizacion = cad.CatAutorizacionDocumentosId
		LEFT JOIN uvix_BitacoraAcuerdoPromocion bap ON p.AsuntoNeunId = bap.AsuntoNeunId 
				AND p.NumeroOrden = bap.NumeroOrden
				AND p.YearPromocion = bap.YearPromocion
				AND bap.Operacion = 1
				AND bap.Status = 1

	
	
        /* REGRESA LA INFORMACIÖN NECESARIA PARA EL TABLERO DE TRAMITE */
        SELECT 
                p.No_Exp,
                p.TipoAsuntoDescripcion, 
                ISNULL(p.NombreOrigen,'SIN ORIGEN') AS NombreOrigen,
                p.NumeroRegistro,
                p.NumeroOrden,
                p.ArchivoPromocion,
                p.FechaRecibido,
                TipoContenidoDescripcion = ISNULL(p.TipoContenidoDescripcion,''),
                SecretarioDescripcion = ISNULL(LTRIM(RTRIM(p.SecretarioDescripcion)),''),
                p.NombreTipoCuaderno,
                Promovente = ISNULL(LTRIM(RTRIM(REPLACE(p.Promovente,'( ','('))),''),
                FechaAuto = p.FechaAuto,
                Plantilla = ISNULL(p.Plantilla,''),
                Mesa = ISNULL(p.Mesa,''),
                NombreCapDJ = ISNULL(LTRIM(RTRIM(p.NombreCapDJ)),''),
                NombreDocumento = ISNULL(p.NombreDocumento,''),
                p.EstadoAutorizacion,
                p.EstadoAutorizacionDescripcion,
                p.EmpleadoPreAutoriza,
                p.EmpleadoAutoriza,
                p.EmpleadoCancela,
                p.AsuntoNeunId,
                p.AsuntoId,
                p.AsuntoDocumentoId, 
                p.Origen,
                FechaPreAutoriza,
                FechaAutoriza,
                FechaCancela ,
                UserNameSecretario ,
                UserNameOficial ,
                NumeroAlias ,
                Cancela ,
                Preautoriza ,
                Autoriza ,
                FechaRecibido_F ,
                FechaAuto_F,
                NombreArchivo,
                OrigenCorto 
                ,p.YearPromocion
                ,EmpleadoElimina 
                ,UserNameElimina 
                ,FechaElimina 
                , TipoAsuntoId
                ,TipoCuadernoId
                ,NombreCorto
                ,RutaArchivoNAS
                ,Estado = 	IIF ((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL), 1,--Sin Acuerdo
                                IIF (EstadoAutorizacion  IN (4,8,9),5, --Cancelados
                                    IIF (EstadoAutorizacion NOT IN (2,3,4,8,9) AND NOT((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL)), 2, --Con acuerdo
                                        IIF (EstadoAutorizacion  IN (2),3, -- Pre autorizados
                                            IIF (EstadoAutorizacion  IN (3),4,0))))) --Autorizados
                ,SintesisOrden
                ,TipoProcedimiento
                ,[secretarioId]
                ,[OrigenId]
                ,[CapturoId]
                ,[PreautorizoId]
                ,[AutorizoId]
                ,[CanceloId]
                ,p.Contenido
                ,p.GuidDocumento
                ,ISNULL(ofi.OficiosFirmados,0) AS OficiosFirmados
        FROM #TramiteFinal p
        LEFT JOIN (SELECT 
                    CASE 
                        WHEN COUNT(uGuid) = SUM(CONVERT(int, Firmado)) THEN 1
                        ELSE 0
                    END AS OficiosFirmados,
                    AsuntoDocumentoId,
                    AsuntoNeunId
                FROM 
                    SISE3.EstadoOficio
                WHERE
                    Estatus = 1
                GROUP BY
                    AsuntoDocumentoId,
                    AsuntoNeunId) AS ofi
            ON ofi.AsuntoDocumentoId = p.AsuntoDocumentoId
            AND ofi.AsuntoNeunId = p.AsuntoNeunId            
        WHERE IIF(@pi_FiltroTipo=0 , @pi_FiltroTipo, 
                IIF ((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL), 1,
                    IIF (EstadoAutorizacion  IN (4,8,9),5,
                        IIF (EstadoAutorizacion NOT IN (2,3,4,8,9) AND NOT((p.AsuntoDocumentoId = 0 OR p.AsuntoDocumentoId IS NULL)), 2,
                            IIF (EstadoAutorizacion  IN (2),3,
                                IIF (EstadoAutorizacion  IN (3),4,0)))))) =  @pi_FiltroTipo
            AND IIF(TRIM(ISNULL(@pi_Texto,'')) ='', TRIM(ISNULL(@pi_Texto,'')),
                    CONCAT(UserNameSecretario, TipoAsuntoDescripcion,NombreTipoCuaderno, Origen, No_Exp, EmpleadoPreAutoriza, EmpleadoAutoriza,EmpleadoCancela,NumeroRegistro, NombreOrigen,Promovente,UserNameOficial)) LIKE '%'+TRIM(ISNULL(@pi_Texto,''))+'%'
            AND ISNULL(@pi_SecretarioId,1) = IIF(@pi_SecretarioId IS NOT NULL, SecretarioId,1)
            AND ISNULL(@pi_Origen,'1') = IIF(@pi_Origen IS NOT NULL AND TRIM(@pi_Origen)<>'', ISNULL(NombreOrigen,'SIN ORIGEN'),'1')
            AND ISNULL(@pi_CatTipoAsuntoId,1) = IIF(@pi_CatTipoAsuntoId IS NOT NULL, TipoAsuntoId,1)
            AND ISNULL(@pi_CapturoId,1) = IIF(@pi_CapturoId IS NOT NULL, CapturoId,1)
            AND ISNULL(@pi_PreautorizoId,1) = IIF(@pi_PreautorizoId IS NOT NULL, PreautorizoId,1)
            AND ISNULL(@pi_AutorizoId,1) = IIF(@pi_AutorizoId IS NOT NULL, AutorizoId,1)
            AND ISNULL(@pi_CanceloId,1) = IIF(@pi_CanceloId IS NOT NULL, CanceloId,1)
        ORDER BY 
        CASE WHEN @pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 0 THEN NumeroAlias END ASC,
        CASE WHEN (@pi_OrdenarPor= 'Expediente' and @pi_TipoOrden = 1) THEN NumeroAlias END DESC,
        CASE WHEN @pi_OrdenarPor= 'Secretario' and @pi_TipoOrden = 0 THEN UserNameSecretario END ASC,
        CASE WHEN @pi_OrdenarPor= 'Secretario' and @pi_TipoOrden = 1 THEN UserNameSecretario END DESC,
        CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 0 THEN NombreOrigen END ASC,
        CASE WHEN @pi_OrdenarPor= 'Origen' and @pi_TipoOrden = 1 THEN NombreOrigen END DESC,
        CASE WHEN @pi_OrdenarPor= 'Promovente' and @pi_TipoOrden = 0 THEN Promovente END ASC,
        CASE WHEN @pi_OrdenarPor= 'Promovente' and @pi_TipoOrden = 1 THEN Promovente END DESC,
        CASE WHEN @pi_OrdenarPor= 'Capturo' and @pi_TipoOrden = 0 THEN UserNameOficial END ASC,
        CASE WHEN @pi_OrdenarPor= 'Capturo' and @pi_TipoOrden = 1 THEN UserNameOficial END DESC,
        CASE WHEN @pi_OrdenarPor= 'Preautorizo' and @pi_TipoOrden = 0 THEN EmpleadoPreAutoriza END ASC,
        CASE WHEN @pi_OrdenarPor= 'Preautorizo' and @pi_TipoOrden = 1 THEN EmpleadoPreAutoriza END DESC,
        CASE WHEN @pi_OrdenarPor= 'Autorizo' and @pi_TipoOrden = 0 THEN EmpleadoAutoriza END ASC,
        CASE WHEN @pi_OrdenarPor= 'Autorizo' and @pi_TipoOrden = 1 THEN EmpleadoAutoriza END DESC,
        CASE WHEN @pi_OrdenarPor= 'Cancelo' and @pi_TipoOrden = 0 THEN EmpleadoCancela END ASC,
        CASE WHEN @pi_OrdenarPor= 'Cancelo' and @pi_TipoOrden = 1 THEN EmpleadoCancela END DESC,
        CASE WHEN @pi_OrdenarPor not in('Expediente','Secretario','Origen','Promovente','Capturo','Preautorizo', 'Autorizo', 'Cancelo') THEN NumeroRegistro END DESC
        
        OFFSET @pi_TamanoPagina * (@pi_NumeroPagina - 1) ROWS 
        FETCH NEXT iif(@pi_TamanoPagina=0,0x7ffffff,@pi_TamanoPagina)  ROWS ONLY
        
        DROP TABLE #Catalogos

END;
