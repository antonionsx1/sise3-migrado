using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.AgendarDuranteCelebracion
{
    public class AgendarDuranteCelebracionService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public AgendarDuranteCelebracionService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion<PropuestaReservacion> ReservarAudiencia(
            ReservarDuranteCelebracionRequest request)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion<PropuestaReservacion>.Error(
                    "El número de expediente o NEUN es requerido");

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                return ResultadoOperacion<PropuestaReservacion>.Error(
                    "El tipo de audiencia es requerido");

            // CORRECCIÓN ERR-CEL-001: Manejo de errores corregido
            // Se valida que exista una audiencia en celebración activa
            // y se retorna error si no existe
            var audienciaEnCelebracion = _audiencias
                .FirstOrDefault(a => a.NumeroExpediente == request.NumeroExpediente
                                  && a.Estado == "En celebración");

            if (audienciaEnCelebracion == null)
                return ResultadoOperacion<PropuestaReservacion>.Error(
                    "ERR-CEL-001: No existe una audiencia en celebración activa " +
                    "para el expediente indicado");

            // CORRECCIÓN ERR-CEL-002: Operador lógico corregido
            // Se usa == con condicional separado para cada prioridad
            DateTime limiteHorario;
            if (request.Prioridad == "Alta")
                limiteHorario = DateTime.Today.AddHours(18); // Alta: hasta 6:00 PM del día en curso
            else
                limiteHorario = DateTime.Today.AddDays(1).AddHours(9).AddMinutes(15); // Baja: siguiente día 9:15

            if (request.FechaInicialAudiencia > limiteHorario)
                return ResultadoOperacion<PropuestaReservacion>.Error(
                    "ERR-CEL-002: La fecha inicial de audiencia excede el límite permitido " +
                    "según la prioridad seleccionada");

            var propuesta = new PropuestaReservacion
            {
                JuezPropuesto         = AsignarJuez(request),
                FechaInicialPropuesta = request.FechaInicialAudiencia,
                FechaFinalPropuesta   = request.FechaInicialAudiencia.AddHours(2),
                NumeroExpediente      = request.NumeroExpediente,
                TipoAudiencia         = request.TipoAudiencia,
                EsMovil               = request.EsMovil,
                NumeroSala            = request.EsMovil ? request.NumeroSala : null
            };

            return ResultadoOperacion<PropuestaReservacion>.Exitoso(propuesta);
        }

        public ResultadoOperacion AceptarPropuesta(PropuestaReservacion propuesta,
            string usuarioAgenda)
        {
            var nuevaAudiencia = new AudienciaCJPF
            {
                Id               = _audiencias.Count + 1,
                NumeroExpediente = propuesta.NumeroExpediente,
                TipoAudiencia    = propuesta.TipoAudiencia,
                FechaHoraInicio  = propuesta.FechaInicialPropuesta,
                FechaHoraFin     = propuesta.FechaFinalPropuesta,
                JuezAsignado     = propuesta.JuezPropuesto,
                Estado           = "Programada",
                AgendadoPor      = usuarioAgenda
            };

            _audiencias.Add(nuevaAudiencia);

            return ResultadoOperacion.Exitoso(
                $"Audiencia reservada exitosamente para el expediente " +
                $"{propuesta.NumeroExpediente} con el juez {propuesta.JuezPropuesto}");
        }

        private string AsignarJuez(ReservarDuranteCelebracionRequest request)
        {
            return "Juez Disponible 1";
        }
    }

    public class ReservarDuranteCelebracionRequest
    {
        public string   NumeroExpediente      { get; set; } = string.Empty;
        public string   Neun                  { get; set; } = string.Empty;
        public string   TipoAudiencia         { get; set; } = string.Empty;
        public string   Prioridad             { get; set; } = string.Empty;
        public bool     EsMovil               { get; set; }
        public string?  NumeroSala            { get; set; }
        public bool     EsSalaVirtual         { get; set; }
        public DateTime FechaInicialAudiencia { get; set; }
        public bool     EsContinuacion        { get; set; }
    }

    public class PropuestaReservacion
    {
        public string   JuezPropuesto         { get; set; } = string.Empty;
        public DateTime FechaInicialPropuesta { get; set; }
        public DateTime FechaFinalPropuesta   { get; set; }
        public string   NumeroExpediente      { get; set; } = string.Empty;
        public string   TipoAudiencia         { get; set; } = string.Empty;
        public bool     EsMovil               { get; set; }
        public string?  NumeroSala            { get; set; }
    }

    public class AudienciaCJPF
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Estado           { get; set; } = string.Empty;
        public DateTime FechaHoraInicio  { get; set; }
        public DateTime FechaHoraFin     { get; set; }
        public string   JuezAsignado     { get; set; } = string.Empty;
        public string   AgendadoPor      { get; set; } = string.Empty;
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
