using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.ResolucionSinAudiencia
{
    public class ResolucionSinAudienciaService
    {
        private readonly List<ResolucionCJPF> _resoluciones;
        private readonly List<JuezCJPF>       _jueces;

        public ResolucionSinAudienciaService(
            List<ResolucionCJPF> resoluciones,
            List<JuezCJPF>       jueces)
        {
            _resoluciones = resoluciones;
            _jueces       = jueces;
        }

        public ResultadoOperacion<ResolucionCJPF> GuardarResolucion(
            GuardarResolucionRequest request)
        {
            if (string.IsNullOrEmpty(request.TipoResolucion))
                return ResultadoOperacion<ResolucionCJPF>.Error(
                    "El tipo de resolución es requerido");

            if (request.FechaInicio.Date < DateTime.Today)
                return ResultadoOperacion<ResolucionCJPF>.Error(
                    "No se pueden seleccionar días anteriores al día en curso");

            if (request.FechaInicio >= request.FechaFin)
                return ResultadoOperacion<ResolucionCJPF>.Error(
                    "La fecha final debe ser mayor a la fecha de inicio");

            if (request.TipoResolucion == "Innominada" &&
                string.IsNullOrEmpty(request.Descripcion))
                return ResultadoOperacion<ResolucionCJPF>.Error(
                    "La descripción es requerida para resoluciones Innominadas");

            var validacionJuez = ValidarDisponibilidadJuez(request);
            if (!validacionJuez.Exito)
                return ResultadoOperacion<ResolucionCJPF>.Error(validacionJuez.Mensaje);

            var resolucion = new ResolucionCJPF
            {
                Id             = _resoluciones.Count + 1,
                TipoResolucion = request.TipoResolucion == "Innominada"
                    ? request.Descripcion ?? request.TipoResolucion
                    : request.TipoResolucion,
                FechaInicio    = request.FechaInicio,
                FechaFin       = request.FechaFin,
                JuezAsignado   = request.JuezId,
                Estado         = "Asignada",
                GeneraExclusionJuez = true
            };

            _resoluciones.Add(resolucion);

            return ResultadoOperacion<ResolucionCJPF>.Exitoso(resolucion);
        }

        public ResultadoOperacion CancelarResolucion(int resolucionId, bool confirmado)
        {
            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == resolucionId);
            if (resolucion == null)
                return ResultadoOperacion.Error("No se encontró la resolución indicada");

            // ERROR ERR-RES-006: Manejo de errores erróneo
            // No se valida que la resolución esté en estado "Asignada"
            // antes de cancelarla, permite cancelar resoluciones en cualquier estado
            if (!confirmado)
                return ResultadoOperacion.Error(
                    "Se requiere confirmación para cancelar la resolución");

            resolucion.Estado = "Cancelada";

            return ResultadoOperacion.Exitoso(
                $"Resolución cancelada correctamente");
        }

        public ResultadoOperacion FinalizarResolucion(int resolucionId)
        {
            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == resolucionId);
            if (resolucion == null)
                return ResultadoOperacion.Error("No se encontró la resolución indicada");

            if (DateTime.Now < resolucion.FechaInicio || DateTime.Now > resolucion.FechaFin)
                return ResultadoOperacion.Error(
                    "Solo se puede finalizar la resolución durante el tiempo asignado");

            resolucion.Estado = "Finalizada";

            return ResultadoOperacion.Exitoso("Resolución finalizada correctamente");
        }

        private ResultadoOperacion ValidarDisponibilidadJuez(GuardarResolucionRequest request)
        {
            var juez = _jueces.FirstOrDefault(j => j.Id == request.JuezId);
            if (juez == null)
                return ResultadoOperacion.Error("No se encontró el juez indicado");

            bool juezOcupado = _resoluciones.Any(r =>
                r.JuezAsignado == request.JuezId &&
                r.Estado != "Cancelada" &&
                r.FechaInicio < request.FechaFin &&
                r.FechaFin > request.FechaInicio);

            if (juezOcupado)
                return ResultadoOperacion.Error(
                    $"El juez {juez.Nombre} no tiene disponibilidad en el horario indicado. " +
                    "Se presentará otro juez como opción");

            return ResultadoOperacion.Exitoso(string.Empty);
        }
    }

    public class GuardarResolucionRequest
    {
        public string   TipoResolucion { get; set; } = string.Empty;
        public DateTime FechaInicio    { get; set; }
        public DateTime FechaFin       { get; set; }
        public string   JuezId         { get; set; } = string.Empty;
        public string?  Descripcion    { get; set; }
    }

    public class ResolucionCJPF
    {
        public int      Id                  { get; set; }
        public string   TipoResolucion      { get; set; } = string.Empty;
        public DateTime FechaInicio         { get; set; }
        public DateTime FechaFin            { get; set; }
        public string   JuezAsignado        { get; set; } = string.Empty;
        public string   Estado              { get; set; } = string.Empty;
        public bool     GeneraExclusionJuez { get; set; }
    }

    public class JuezCJPF
    {
        public string Id     { get; set; } = string.Empty;
        public string Nombre { get; set; } = string.Empty;
    }

    public class ResultadoOperacion
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;

        public static ResultadoOperacion Exitoso(string mensaje) =>
            new ResultadoOperacion { Exito = true, Mensaje = mensaje };

        public static ResultadoOperacion Error(string mensaje) =>
            new ResultadoOperacion { Exito = false, Mensaje = mensaje };
    }

    public class ResultadoOperacion<T>
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;
        public T?     Datos   { get; private set; }

        public static ResultadoOperacion<T> Exitoso(T datos) =>
            new ResultadoOperacion<T> { Exito = true, Datos = datos };

        public static ResultadoOperacion<T> Error(string mensaje) =>
            new ResultadoOperacion<T> { Exito = false, Mensaje = mensaje };
    }
}
