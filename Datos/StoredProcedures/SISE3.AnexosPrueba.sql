SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE SISE3.[AnexosPrueba]
(
@pi_AsuntoNeunId [bigint] 
)
AS
/****** 11/01/2012			 ******/
/****** Proyecto: SISE       ******/
/****** Autor: David Guzmán Callejas	 ******/
/****** Objetivo: Consulta registros en Asuntos para la API del ver captura******/


	BEGIN
		SET NOCOUNT ON

		    -- Obtengo el maximo registro de AsuntoID por AsuntoNeunId
			--insert into dbo.[AnexosPrueba1]([AsuntoNeunId]) values(@pi_AsuntoNeunId)

			insert into dbo.[AnexosPrueba2]([AsuntoNeunId]) values(@pi_AsuntoNeunId)
		    
				
		SET NOCOUNT OFF
	END

