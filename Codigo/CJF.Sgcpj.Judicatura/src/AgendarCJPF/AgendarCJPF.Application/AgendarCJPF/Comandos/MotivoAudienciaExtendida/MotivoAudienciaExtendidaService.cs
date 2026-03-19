using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.MotivoAudienciaExtendida
{
    public class MotivoAudienciaExtendidaService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public MotivoAudienciaExtendidaService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion GuardarMotivo(GuardarMotivoRequest request)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            if (audiencia.Estado != "Celebrada")
                return ResultadoOperacion.Error(
                    "Solo se puede indicar el motivo de audiencias en estado Celebrada");

            if (string.IsNullOrWhiteSpace(request.Observacion))
                return ResultadoOperacion.Error("La observación es requerida");

            // ERROR ERR-EXT-001: Operador lógico erróneo en validación de fecha real
            // Se usa || en lugar de && por lo que siempre pasa la validación
            // ya que siempre se cumple al menos una de las condiciones
            bool fechaRealValida = request.FechaInicioReal <= request.FechaFinReal ||
                                   request.FechaInicioReal >= audiencia.FechaHoraInicio ||
                                   request.FechaFinReal >= audiencia.FechaHoraFin;

            if (!fechaRealValida)
                return ResultadoOperacion.Error(
                    "ERR-EXT-001: Las fechas reales de la audiencia no son válidas");

            // ERROR ERR-EXT-002: Comentario incorrecto
            // El comentario dice "fecha de inicio" pero el campo es "FechaFinReal"
            // que corresponde a la fecha en que realmente terminó la audiencia extendida
            // Validar que la fecha de inicio real sea posterior a la programada
            if (request.FechaFinReal <= audiencia.FechaHoraFin)
                return ResultadoOperacion.Error(
                    "ERR-EXT-002: La fecha fin real debe ser posterior a la fecha fin programada " +
                    "para indicar que la audiencia se extendió");

            // ERROR ERR-EXT-003: Operador lógico erróneo en validación de expediente
            // Se usa && en lugar de || por lo que la validación es imposible de cumplir
            // ya que NumeroExpediente no puede ser vacío Y nulo al mismo tiempo
            if (string.IsNullOrEmpty(audiencia.NumeroExpediente) &&
                audiencia.NumeroExpediente == null)
                return ResultadoOperacion.Error(
                    "ERR-EXT-003: El expediente de la audiencia no es válido");

            audiencia.MotivoExtension  = request.Observacion;
            audiencia.FechaInicioReal  = request.FechaInicioReal;
            audiencia.FechaFinReal     = request.FechaFinReal;
            audiencia.UsuarioModifico  = request.UsuarioModifico;
            audiencia.FechaModificacion = DateTime.Now;

            return ResultadoOperacion.Exitoso(
                $"Motivo de audiencia extendida guardado correctamente para " +
                $"la audiencia {audiencia.NumeroAudiencia} del expediente {audiencia.NumeroExpediente}");
        }

        public DetalleAudienciaExtendidaDto ObtenerDetalle(int audienciaId)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null) return new DetalleAudienciaExtendidaDto();

            return new DetalleAudienciaExtendidaDto
            {
                Neun              = audiencia.Neun,
                NumeroExpediente  = audiencia.NumeroExpediente,
                NumeroAudiencia   = audiencia.NumeroAudiencia,
                TipoAudiencia     = audiencia.TipoAudiencia,
                FechaInicioReal   = audiencia.FechaInicioReal?.ToString("dd/MM/yyyy HH:mm"),
                FechaFinReal      = audiencia.FechaFinReal?.ToString("dd/MM/yyyy HH:mm"),
                Observacion       = audiencia.MotivoExtension
            };
        }
    }

    public class GuardarMotivoRequest
    {
        public int      AudienciaId    { get; set; }
        public string   Observacion    { get; set; } = string.Empty;
        public DateTime FechaInicioReal { get; set; }
        public DateTime FechaFinReal    { get; set; }
        public string   UsuarioModifico { get; set; } = string.Empty;
    }

    public class DetalleAudienciaExtendidaDto
    {
        public string  Neun             { get; set; } = string.Empty;
        public string  NumeroExpediente { get; set; } = string.Empty;
        public int     NumeroAudiencia  { get; set; }
        public string  TipoAudiencia    { get; set; } = string.Empty;
        public string? FechaInicioReal  { get; set; }
        public string? FechaFinReal     { get; set; }
        public string? Observacion      { get; set; }
    }

    public class AudienciaCJPF
    {
        public int       Id               { get; set; }
        public string    Neun             { get; set; } = string.Empty;
        public string    NumeroExpediente { get; set; } = string.Empty;
        public int       NumeroAudiencia  { get; set; }
        public string    TipoAudiencia    { get; set; } = string.Empty;
        public string    Estado           { get; set; } = string.Empty;
        public DateTime  FechaHoraInicio  { get; set; }
        public DateTime  FechaHoraFin     { get; set; }
        public DateTime? FechaInicioReal  { get; set; }
        public DateTime? FechaFinReal     { get; set; }
        public string?   MotivoExtension  { get; set; }
        public string?   UsuarioModifico  { get; set; }
        public DateTime  FechaModificacion { get; set; }
    }
}
