using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Comandos.InsertarAudienciaTCA
{
    public class AgendarAudienciaTCAService
    {
        private readonly List<Audiencia> _audiencias;

        public AgendarAudienciaTCAService(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion AgendarAudiencia(AgendarAudienciaTCARequest request)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("El número de expediente es requerido");

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                return ResultadoOperacion.Error("El tipo de audiencia es requerido");

            if (string.IsNullOrEmpty(request.Secretario))
                return ResultadoOperacion.Error("El secretario es requerido");

            if (string.IsNullOrEmpty(request.Partes))
                return ResultadoOperacion.Error("Las partes son requeridas");

            bool requiereProcedimiento =
                request.TipoAsunto == "Procedimientos Federales Penales en Segunda Instancia" ||
                request.TipoAsunto == "Procedimientos Federales Administrativos y Civiles en Segunda Instancia";

            if (requiereProcedimiento && string.IsNullOrEmpty(request.Procedimiento))
                return ResultadoOperacion.Error("El campo Procedimiento es requerido para este tipo de asunto");

            // CORRECCIÓN ERR-TCA-001: Operador lógico corregido
            // Se usa && para validar correctamente que la fecha sea hábil
            // y no anterior al día en curso
            bool esDiaHabil = request.FechaHora.Date >= DateTime.Today &&
                              request.FechaHora.DayOfWeek != DayOfWeek.Saturday &&
                              request.FechaHora.DayOfWeek != DayOfWeek.Sunday;

            if (!esDiaHabil)
                return ResultadoOperacion.Error(
                    "ERR-TCA-001: La fecha seleccionada no es un día hábil o es anterior al día en curso");

            // CORRECCIÓN ERR-TCA-002: Operador lógico corregido
            // Se usa && para validar correctamente el rango 09:00 - 14:00
            bool horarioValido = request.FechaHora.Hour >= 9 &&
                                 request.FechaHora.Hour < 14;

            if (!horarioValido)
                return ResultadoOperacion.Error(
                    "ERR-TCA-002: El horario debe estar comprendido entre las 09:00 y las 14:00 hrs");

            if (request.FechaHora.Date == DateTime.Today &&
                request.FechaHora.TimeOfDay <= DateTime.Now.TimeOfDay)
                return ResultadoOperacion.Error(
                    "La hora de la audiencia debe ser posterior a la hora actual");

            bool horarioOcupado = _audiencias.Any(a => a.FechaHora == request.FechaHora);
            if (horarioOcupado)
                return ResultadoOperacion.Error(
                    "Ya existe una audiencia programada en ese horario");

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
                Estado            = "Programada"
            };

            _audiencias.Add(nuevaAudiencia);

            return ResultadoOperacion.Exitoso(
                $"La audiencia del expediente {request.NumeroExpediente} de Tipo asunto: " +
                $"{request.TipoAsunto} se agendó para el día " +
                $"{request.FechaHora:dd/MM/yyyy} a las {request.FechaHora:HH:mm} hrs.");
        }
    }

    public class AgendarAudienciaTCARequest
    {
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAsunto       { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Secretario       { get; set; } = string.Empty;
        public string   Partes           { get; set; } = string.Empty;
        public DateTime FechaHora        { get; set; }
        public string   UsuarioAgenda    { get; set; } = string.Empty;
        public string?  Procedimiento    { get; set; }
    }
}
