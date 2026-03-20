using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.CancelarAudienciaCJPF
{
    public class CancelarAudienciaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public CancelarAudienciaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion CancelarAudiencia(CancelarAudienciaCJPFRequest request)
        {
            if (!request.Confirmado)
                return ResultadoOperacion.Error("Se requiere confirmación para cancelar la audiencia");

            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            if (string.IsNullOrEmpty(request.MotivoCancelacion))
                return ResultadoOperacion.Error("El motivo de cancelación es requerido");

            if (string.IsNullOrEmpty(request.CausaPrecisa))
                return ResultadoOperacion.Error("La causa precisa de la cancelación es requerida");

            if (request.MotivoCancelacion == "Diferimiento" &&
                string.IsNullOrEmpty(request.TipoDiferimiento))
                return ResultadoOperacion.Error("El tipo de diferimiento es requerido");

            // Determinar nuevo estado según motivo
            audiencia.Estado = request.MotivoCancelacion == "Diferimiento"
                ? "Diferida"
                : "Cancelada";

            audiencia.MotivoCancelacion  = request.MotivoCancelacion;
            audiencia.CausaPrecisa       = request.CausaPrecisa;
            audiencia.TipoDiferimiento   = request.TipoDiferimiento;
            audiencia.FechaCancelacion   = DateTime.Now;
            audiencia.UsuarioCancelo     = request.UsuarioCancelo;

            var mensajeEstado = audiencia.Estado == "Diferida" ? "diferida" : "cancelada";

            return ResultadoOperacion.Exitoso(
                $"La audiencia {audiencia.NumeroAudiencia} del expediente " +
                $"{audiencia.NumeroExpediente} fue {mensajeEstado} exitosamente. " +
                $"Motivo: {request.MotivoCancelacion}");
        }

        public bool PuedeCancelar(string rol)
        {
            return rol == "Administrador" ||
                   rol == "AsistenteConstancias" ||
                   rol == "AuxiliarSala";
        }
    }

    public class CancelarAudienciaCJPFRequest
    {
        public int     AudienciaId        { get; set; }
        public bool    Confirmado         { get; set; }
        public string  MotivoCancelacion  { get; set; } = string.Empty;
        public string  CausaPrecisa       { get; set; } = string.Empty;
        public string? TipoDiferimiento   { get; set; }
        public string  UsuarioCancelo     { get; set; } = string.Empty;
        public string  FirmaElectronica   { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public int      NumeroAudiencia  { get; set; }
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Sala             { get; set; } = string.Empty;
        public DateTime FechaHoraInicio  { get; set; }
        public DateTime FechaHoraFin     { get; set; }
        public string   Estado           { get; set; } = string.Empty;
        public string?  MotivoCancelacion { get; set; }
        public string?  CausaPrecisa     { get; set; }
        public string?  TipoDiferimiento { get; set; }
        public DateTime? FechaCancelacion { get; set; }
        public string?  UsuarioCancelo   { get; set; }
    }
}
