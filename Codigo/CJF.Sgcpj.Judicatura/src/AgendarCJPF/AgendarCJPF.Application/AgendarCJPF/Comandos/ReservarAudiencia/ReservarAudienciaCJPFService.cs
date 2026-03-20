using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.ReservarAudienciaCJPF
{
    public class ReservarAudienciaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public ReservarAudienciaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion ReservarAudiencia(ReservarAudienciaCJPFRequest request)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("El número de expediente es requerido");

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                return ResultadoOperacion.Error("El tipo de audiencia es requerido");

            // CORRECCIÓN ERR-CJPF2-001: Manejo de errores corregido
            // La validación de imputados ahora retorna error correctamente
            if (request.EsCausaPenal && !request.ImputadosSeleccionados.Any())
                return ResultadoOperacion.Error(
                    "ERR-CJPF2-001: Se requiere agregar los imputados a la audiencia");

            var validacionPrioridad = ValidarPrioridad(request);
            if (!validacionPrioridad.Exito)
                return validacionPrioridad;

            // CORRECCIÓN ERR-CJPF2-002: Operador lógico corregido
            // Se usa && para validar correctamente el horario ordinario (9:15 - 17:59)
            bool esHorarioOrdinario = (request.HoraInicio.Hour > 9 ||
                                      (request.HoraInicio.Hour == 9 && request.HoraInicio.Minute >= 15))
                                      && request.HoraInicio.Hour < 18;

            bool esHorarioExtraordinario = request.HoraInicio.Hour >= 18 ||
                                           request.HoraInicio.Hour < 9;

            if (!esHorarioOrdinario && !esHorarioExtraordinario)
                return ResultadoOperacion.Error(
                    "ERR-CJPF2-002: El horario no corresponde a ninguno de los rangos permitidos");

            // CORRECCIÓN ERR-CJPF2-003: Operador lógico corregido
            // Se usa && para que ambas condiciones se cumplan simultáneamente:
            // misma sala Y intervalo menor a 15 minutos
            bool salaDisponible = !_audiencias.Any(a =>
                a.Sala == request.Sala &&
                Math.Abs((a.FechaHoraInicio - request.FechaHoraInicio).TotalMinutes) < 15);

            if (!salaDisponible)
                return ResultadoOperacion.Error(
                    "ERR-CJPF2-003: No hay disponibilidad en la sala para el horario indicado. " +
                    "Debe existir un intervalo mínimo de 15 minutos entre audiencias");

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
                Estado                 = "Programada",
                EsAuxilio              = request.EsAuxilio
            };

            _audiencias.Add(nuevaAudiencia);

            return ResultadoOperacion.Exitoso(
                $"Audiencia {request.TipoAudiencia} reservada para el expediente " +
                $"{request.NumeroExpediente} el {request.FechaHoraInicio:dd/MM/yyyy} " +
                $"de {request.FechaHoraInicio:HH:mm} a {request.FechaHoraFin:HH:mm} " +
                $"en sala {request.Sala}");
        }

        private ResultadoOperacion ValidarPrioridad(ReservarAudienciaCJPFRequest request)
        {
            if (request.Prioridad == "Alta" && !request.TiempoTraslado.HasValue)
                return ResultadoOperacion.Error("El tiempo de traslado es requerido para prioridad Alta");

            if (request.Prioridad == "Baja" && !request.TiempoNotificacion.HasValue)
                return ResultadoOperacion.Error("El tiempo de notificación es requerido para prioridad Baja");

            if (request.EsConDetenido)
            {
                request.Prioridad = "Alta";
                if (!request.FechaInicialAudiencia.HasValue)
                    return ResultadoOperacion.Error("La fecha inicial de audiencia es requerida para Con Detenido");
            }

            return ResultadoOperacion.Exitoso(string.Empty);
        }
    }

    public class ReservarAudienciaCJPFRequest
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
        public bool     EsAuxilio              { get; set; }
        public List<string> ImputadosSeleccionados { get; set; } = new();
        public string?  Descripcion            { get; set; }
        public int?     TiempoTraslado         { get; set; }
        public int?     TiempoNotificacion     { get; set; }
        public DateTime? FechaInicialAudiencia { get; set; }
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
        public bool     EsAuxilio              { get; set; }
        public List<string> ImputadosSeleccionados { get; set; } = new();
        public string   Estado                 { get; set; } = string.Empty;
    }
}
