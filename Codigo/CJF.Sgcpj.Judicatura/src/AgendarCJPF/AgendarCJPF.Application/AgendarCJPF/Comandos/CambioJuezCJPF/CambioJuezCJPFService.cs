using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.CambioJuezCJPF
{
    public class CambioJuezCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public CambioJuezCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion CambiarJuez(CambiarJuezRequest request)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            // CORRECCIÓN ERR-JUZ-001: Comentario corregido
            // Solo se puede cambiar el juez si la audiencia está Pendiente de celebración
            if (audiencia.Estado != "Pendiente de celebración")
                return ResultadoOperacion.Error(
                    "ERR-JUZ-001: Solo se puede cambiar el juez en audiencias " +
                    "Pendientes de celebración");

            if (string.IsNullOrEmpty(request.JuezSustitutoId))
                return ResultadoOperacion.Error("Debe seleccionar un juez sustituto");

            if (string.IsNullOrEmpty(request.MotivosCambio))
                return ResultadoOperacion.Error("Debe indicar los motivos del cambio de juez");

            // CORRECCIÓN ERR-JUZ-002: Operador lógico corregido
            // Se usa && para detectar conflicto solo cuando el juez es el mismo
            // Y hay traslape de horario en el mismo día
            bool juezDisponible = !_audiencias.Any(a =>
                a.JuezAsignado == request.JuezSustitutoId &&
                a.FechaHoraInicio.Date == audiencia.FechaHoraInicio.Date &&
                a.FechaHoraInicio < audiencia.FechaHoraFin &&
                a.FechaHoraFin > audiencia.FechaHoraInicio);

            if (!juezDisponible)
                return ResultadoOperacion.Error(
                    "ERR-JUZ-002: El juez sustituto tiene audiencias reservadas " +
                    "en el mismo horario");

            // CORRECCIÓN ERR-JUZ-003: Operador lógico corregido
            // Se usa || para notificar si tiene AL MENOS UNO de los correos disponibles
            bool puedeNotificar = !string.IsNullOrEmpty(audiencia.CorreoJuezActual) ||
                                  !string.IsNullOrEmpty(request.CorreoJuezSustituto);

            string juezAnterior = audiencia.JuezAsignado;
            audiencia.JuezAsignado    = request.JuezSustitutoId;
            audiencia.MotivosCambio   = request.MotivosCambio;
            audiencia.FechaCambioJuez = DateTime.Now;

            if (puedeNotificar)
                NotificarCambioJuez(juezAnterior, request.JuezSustitutoId, audiencia);

            return ResultadoOperacion.Exitoso(
                $"Juez actualizado correctamente para la audiencia {audiencia.NumeroAudiencia}. " +
                $"Nuevo juez: {request.JuezSustitutoId}");
        }

        private void NotificarCambioJuez(string juezAnterior, string juezNuevo,
            AudienciaCJPF audiencia)
        {
            Console.WriteLine($"Notificando cambio de juez: {juezAnterior} -> {juezNuevo}");
        }
    }

    public class CambiarJuezRequest
    {
        public int    AudienciaId         { get; set; }
        public string JuezSustitutoId     { get; set; } = string.Empty;
        public string MotivosCambio       { get; set; } = string.Empty;
        public string CorreoJuezSustituto { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public int      NumeroAudiencia  { get; set; }
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Estado           { get; set; } = string.Empty;
        public DateTime FechaHoraInicio  { get; set; }
        public DateTime FechaHoraFin     { get; set; }
        public string   JuezAsignado     { get; set; } = string.Empty;
        public string   CorreoJuezActual { get; set; } = string.Empty;
        public string?  MotivosCambio    { get; set; }
        public DateTime? FechaCambioJuez { get; set; }
    }
}
