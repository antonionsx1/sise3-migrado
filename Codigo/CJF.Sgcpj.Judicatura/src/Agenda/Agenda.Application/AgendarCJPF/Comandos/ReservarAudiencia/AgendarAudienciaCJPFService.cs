using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.InsertarAudienciaCJPF
{
    public class AgendarAudienciaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public AgendarAudienciaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion AgendarAudiencia(AgendarAudienciaCJPFRequest request)
        {
            // CORRECCIÓN ERR-CJPF-001: Manejo de errores corregido
            // Las validaciones ahora retornan error correctamente
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("ERR-CJPF-001: El expediente es requerido");

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                return ResultadoOperacion.Error("ERR-CJPF-001: El tipo de audiencia es requerido");

            if (request.EsCausaPenal && !request.ImputadosSeleccionados.Any())
                return ResultadoOperacion.Error("ERR-CJPF-001: Se requiere agregar los imputados a la audiencia");

            // CORRECCIÓN ERR-CJPF-002: Operador lógico corregido
            // Se usa && para validar correctamente el rango de horario ordinario (9:15 - 17:59)
            // y extraordinario (18:00 - 8:59)
            bool esHorarioOrdinario = request.HoraInicio.Hour >= 9 &&
                                      request.HoraInicio.Hour < 18;

            bool esHorarioExtraordinario = request.HoraInicio.Hour >= 18 ||
                                           request.HoraInicio.Hour < 9;

            if (!esHorarioOrdinario && !esHorarioExtraordinario)
                return ResultadoOperacion.Error("ERR-CJPF-002: Horario fuera del rango permitido");

            // Validar disponibilidad de sala y juez
            bool salaDisponible = !_audiencias.Any(a =>
                a.Sala == request.Sala &&
                a.FechaHoraInicio == request.FechaHoraInicio);

            if (!salaDisponible)
                return ResultadoOperacion.Error(
                    $"ERR-CJPF-003: No hay disponibilidad en la sala {request.Sala} " +
                    $"para el horario {request.FechaHoraInicio:dd/MM/yyyy HH:mm}");

            // Validar intervalo mínimo de 15 minutos entre audiencias
            bool intervaloValido = !_audiencias.Any(a =>
                a.Sala == request.Sala &&
                Math.Abs((a.FechaHoraInicio - request.FechaHoraInicio).TotalMinutes) < 15);

            if (!intervaloValido)
                return ResultadoOperacion.Error(
                    "ERR-CJPF-004: Debe existir un intervalo mínimo de 15 minutos entre audiencias");

            var nuevaAudiencia = new AudienciaCJPF
            {
                Id                     = _audiencias.Count + 1,
                NumeroExpediente       = request.NumeroExpediente,
                TipoAudiencia          = request.TipoAudiencia,
                FormatoAudiencia       = request.FormatoAudiencia,
                Prioridad              = request.Prioridad,
                Sala                   = request.Sala,
                FechaHoraInicio        = request.FechaHoraInicio,
                FechaHoraFin           = request.FechaHoraFin,
                EsConDetenido          = request.EsConDetenido,
                ImputadosSeleccionados = request.ImputadosSeleccionados,
                Estado                 = "Programada"
            };

            _audiencias.Add(nuevaAudiencia);

            return ResultadoOperacion.Exitoso(
                $"Audiencia {request.TipoAudiencia} agendada para el expediente " +
                $"{request.NumeroExpediente} el {request.FechaHoraInicio:dd/MM/yyyy} " +
                $"a las {request.FechaHoraInicio:HH:mm} hrs. en sala {request.Sala}");
        }
    }

    public class AgendarAudienciaCJPFRequest
    {
        public string   NumeroExpediente       { get; set; } = string.Empty;
        public string   TipoAudiencia          { get; set; } = string.Empty;
        public string   FormatoAudiencia       { get; set; } = "Presencial";
        public string   Prioridad              { get; set; } = string.Empty;
        public string   Sala                   { get; set; } = string.Empty;
        public DateTime FechaHoraInicio        { get; set; }
        public DateTime FechaHoraFin           { get; set; }
        public TimeSpan HoraInicio             => FechaHoraInicio.TimeOfDay;
        public bool     EsCausaPenal           { get; set; }
        public bool     EsConDetenido          { get; set; }
        public List<string> ImputadosSeleccionados { get; set; } = new();
        public string?  Descripcion            { get; set; }
        public int?     TiempoTraslado         { get; set; }
        public int?     TiempoNotificacion     { get; set; }
    }

    public class AudienciaCJPF
    {
        public int      Id                     { get; set; }
        public string   NumeroExpediente       { get; set; } = string.Empty;
        public string   TipoAudiencia          { get; set; } = string.Empty;
        public string   FormatoAudiencia       { get; set; } = string.Empty;
        public string   Prioridad              { get; set; } = string.Empty;
        public string   Sala                   { get; set; } = string.Empty;
        public DateTime FechaHoraInicio        { get; set; }
        public DateTime FechaHoraFin           { get; set; }
        public bool     EsConDetenido          { get; set; }
        public List<string> ImputadosSeleccionados { get; set; } = new();
        public string   Estado                 { get; set; } = string.Empty;
    }
}
