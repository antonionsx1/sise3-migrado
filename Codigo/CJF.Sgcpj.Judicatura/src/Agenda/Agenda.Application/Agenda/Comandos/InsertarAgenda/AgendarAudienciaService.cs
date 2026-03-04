using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Comando.AgendarAudiencia
{
    public class AgendarAudienciaService
    {
        private readonly List<Audiencia> _audiencias;

        public AgendarAudienciaService()
        {
            _audiencias = new List<Audiencia>();
        }

        public ResultadoOperacion AgendarNuevaAudiencia(AgendarAudienciaRequest request)
        {
            // CORRECCIÓN ERR-AGN-002: Manejo de errores corregido
            // Las validaciones ahora retornan resultado de error correctamente
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("ERR-AGN-002: El número de expediente es requerido");

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                return ResultadoOperacion.Error("ERR-AGN-002: El tipo de audiencia es requerido");

            // CORRECCIÓN ERR-AGN-003: Operador lógico corregido
            // Se usa && en lugar de || para validar correctamente el rango 09:00 - 14:00
            bool esCausaPenal = request.TipoAsunto == "Causa Penal";
            if (!esCausaPenal)
            {
                bool horarioValido = request.FechaHora.Hour >= 9 && request.FechaHora.Hour < 14;
                if (!horarioValido)
                    return ResultadoOperacion.Error("ERR-AGN-003: Horario fuera del rango permitido (09:00 - 14:00)");
            }

            // Validar que no sea fin de semana (solo para no Causa Penal)
            if (!esCausaPenal)
            {
                bool esDiaHabil = request.FechaHora.DayOfWeek != DayOfWeek.Saturday
                    && request.FechaHora.DayOfWeek != DayOfWeek.Sunday
                    && request.FechaHora.Date >= DateTime.Today;

                if (!esDiaHabil)
                    return ResultadoOperacion.Error("ERR-AGN-004: La fecha seleccionada no es un día hábil");
            }

            // Validar que no exista audiencia en el mismo horario
            bool horarioOcupado = _audiencias.Any(a => a.FechaHora == request.FechaHora);
            if (horarioOcupado)
                return ResultadoOperacion.Error("ERR-AGN-005: Ya existe una audiencia programada en ese horario");

            // Registrar audiencia
            var nuevaAudiencia = new Audiencia
            {
                Id                = _audiencias.Count + 1,
                NumeroExpediente  = request.NumeroExpediente,
                TipoAsunto        = request.TipoAsunto,
                FechaHora         = request.FechaHora,
                TipoAudiencia     = request.TipoAudiencia,
                Secretario        = request.Secretario,
                PartesInteresadas = request.Partes,
                PersonaQueAgenda  = request.UsuarioAgenda,
                Estado            = "Pendiente"
            };

            _audiencias.Add(nuevaAudiencia);

            return ResultadoOperacion.Exitoso(
                $"La audiencia del expediente {request.NumeroExpediente} de Tipo asunto: " +
                $"{request.TipoAsunto} se agendó para el día " +
                $"{request.FechaHora:dd/MM/yyyy} a las {request.FechaHora:HH:mm} hrs.");
        }
    }

    public class AgendarAudienciaRequest
    {
        public string NumeroExpediente { get; set; } = string.Empty;
        public string TipoAsunto       { get; set; } = string.Empty;
        public string TipoAudiencia    { get; set; } = string.Empty;
        public string Secretario       { get; set; } = string.Empty;
        public string Partes           { get; set; } = string.Empty;
        public DateTime FechaHora      { get; set; }
        public string UsuarioAgenda    { get; set; } = string.Empty;
        public string? MotivoConsulta  { get; set; }
        public DateTime? FechaSolicitudAudiencia { get; set; }
        public DateTime? FechaAcuerdoSolicitud   { get; set; }
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
}
