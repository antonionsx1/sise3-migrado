using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.AsignacionesReglasCJPF
{
    public class AsignacionesReglasCJPFService
    {
        private readonly List<JuezCJPF>      _jueces;
        private readonly List<AudienciaCJPF> _audiencias;
        private readonly List<ParametroAsignacion> _parametros;

        public AsignacionesReglasCJPFService(
            List<JuezCJPF>           jueces,
            List<AudienciaCJPF>      audiencias,
            List<ParametroAsignacion> parametros)
        {
            _jueces     = jueces;
            _audiencias = audiencias;
            _parametros = parametros;
        }

        public ResultadoAsignacion SugerirAsignacion(SolicitudAsignacionRequest request)
        {
            if (string.IsNullOrEmpty(request.TipoAudiencia))
                return ResultadoAsignacion.Error("El tipo de audiencia es requerido");

            if (request.FechaHoraInicio == default)
                return ResultadoAsignacion.Error("La fecha y hora de inicio son requeridas");

            var juezSugerido = AsignarJuezPorReglas(request);
            if (juezSugerido == null)
            {
                var siguienteVentana = BuscarSiguienteVentanaDisponible(request);
                return ResultadoAsignacion.SinDisponibilidad(siguienteVentana);
            }

            return ResultadoAsignacion.Exitoso(new PropuestaAsignacion
            {
                JuezId          = juezSugerido.Id,
                NombreJuez      = juezSugerido.Nombre,
                FechaHoraInicio = request.FechaHoraInicio,
                FechaHoraFin    = request.FechaHoraInicio.AddHours(2),
                ReglasAplicadas = ObtenerReglasAplicadas(request)
            });
        }

        public ResultadoOperacion ConfirmarAsignacion(ConfirmarAsignacionRequest request)
        {
            if (!request.EsAsignacionManual)
                return ProcesarAsignacionAutomatica(request);

            if (!TienePermisoAjusteManual(request.RolUsuario))
                return ResultadoOperacion.Error(
                    "No cuenta con permiso para realizar ajustes manuales de asignación");

            if (string.IsNullOrEmpty(request.MotivoAjuste))
                return ResultadoOperacion.Error(
                    "Debe indicar el motivo del ajuste manual de asignación");

            return ProcesarAsignacionManual(request);
        }

        private JuezCJPF? AsignarJuezPorReglas(SolicitudAsignacionRequest request)
        {
            var juecesDisponibles = _jueces
                .Where(j => j.EstaActivo)
                .Where(j => !TieneConflictoHorario(j.Id, request.FechaHoraInicio,
                                                    request.FechaHoraInicio.AddHours(2)))
                .ToList();

            if (!juecesDisponibles.Any()) return null;

            // Asignación secuencial para equilibrio de carga
            return juecesDisponibles
                .OrderBy(j => ContarAudienciasJuez(j.Id))
                .FirstOrDefault();
        }

        private bool TieneConflictoHorario(string juezId, DateTime inicio, DateTime fin)
        {
            return _audiencias.Any(a =>
                a.JuezAsignado == juezId &&
                a.Estado != "Cancelada" &&
                a.FechaHoraInicio < fin &&
                a.FechaHoraFin > inicio);
        }

        private int ContarAudienciasJuez(string juezId) =>
            _audiencias.Count(a => a.JuezAsignado == juezId &&
                                   a.Estado != "Cancelada");

        private DateTime? BuscarSiguienteVentanaDisponible(SolicitudAsignacionRequest request)
        {
            var candidato = request.FechaHoraInicio.AddHours(1);
            for (int i = 0; i < 8; i++)
            {
                bool hayJuezDisponible = _jueces
                    .Where(j => j.EstaActivo)
                    .Any(j => !TieneConflictoHorario(j.Id, candidato, candidato.AddHours(2)));

                if (hayJuezDisponible) return candidato;
                candidato = candidato.AddHours(1);
            }
            return null;
        }

        private List<string> ObtenerReglasAplicadas(SolicitudAsignacionRequest request)
        {
            return _parametros
                .Where(p => p.TipoAudiencia == request.TipoAudiencia || p.TipoAudiencia == "*")
                .Select(p => p.Descripcion)
                .ToList();
        }

        private bool TienePermisoAjusteManual(string rol) =>
            rol == "Administrador" || rol == "AsistenteConstancias";

        private ResultadoOperacion ProcesarAsignacionAutomatica(ConfirmarAsignacionRequest request)
        {
            var audiencia = new AudienciaCJPF
            {
                Id               = _audiencias.Count + 1,
                NumeroExpediente = request.NumeroExpediente,
                TipoAudiencia    = request.TipoAudiencia,
                JuezAsignado     = request.JuezId,
                FechaHoraInicio  = request.FechaHoraInicio,
                FechaHoraFin     = request.FechaHoraFin,
                Estado           = "Programada"
            };
            _audiencias.Add(audiencia);
            return ResultadoOperacion.Exitoso("Audiencia asignada automáticamente");
        }

        private ResultadoOperacion ProcesarAsignacionManual(ConfirmarAsignacionRequest request)
        {
            var audiencia = new AudienciaCJPF
            {
                Id               = _audiencias.Count + 1,
                NumeroExpediente = request.NumeroExpediente,
                TipoAudiencia    = request.TipoAudiencia,
                JuezAsignado     = request.JuezId,
                FechaHoraInicio  = request.FechaHoraInicio,
                FechaHoraFin     = request.FechaHoraFin,
                Estado           = "Programada",
                MotivoAjuste     = request.MotivoAjuste
            };
            _audiencias.Add(audiencia);
            return ResultadoOperacion.Exitoso(
                $"Audiencia asignada manualmente. Motivo: {request.MotivoAjuste}");
        }
    }

    public class SolicitudAsignacionRequest
    {
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public DateTime FechaHoraInicio  { get; set; }
    }

    public class ConfirmarAsignacionRequest
    {
        public string   NumeroExpediente  { get; set; } = string.Empty;
        public string   TipoAudiencia     { get; set; } = string.Empty;
        public string   JuezId            { get; set; } = string.Empty;
        public DateTime FechaHoraInicio   { get; set; }
        public DateTime FechaHoraFin      { get; set; }
        public bool     EsAsignacionManual { get; set; }
        public string   MotivoAjuste      { get; set; } = string.Empty;
        public string   RolUsuario        { get; set; } = string.Empty;
    }

    public class PropuestaAsignacion
    {
        public string        JuezId          { get; set; } = string.Empty;
        public string        NombreJuez      { get; set; } = string.Empty;
        public DateTime      FechaHoraInicio { get; set; }
        public DateTime      FechaHoraFin    { get; set; }
        public List<string>  ReglasAplicadas { get; set; } = new();
    }

    public class ResultadoAsignacion
    {
        public bool               Exito            { get; private set; }
        public string             Mensaje          { get; private set; } = string.Empty;
        public PropuestaAsignacion? Propuesta       { get; private set; }
        public DateTime?          SiguienteVentana { get; private set; }

        public static ResultadoAsignacion Exitoso(PropuestaAsignacion propuesta) =>
            new ResultadoAsignacion { Exito = true, Propuesta = propuesta };

        public static ResultadoAsignacion SinDisponibilidad(DateTime? siguiente) =>
            new ResultadoAsignacion
            {
                Exito = false,
                Mensaje = "No hay disponibilidad en el horario solicitado",
                SiguienteVentana = siguiente
            };

        public static ResultadoAsignacion Error(string mensaje) =>
            new ResultadoAsignacion { Exito = false, Mensaje = mensaje };
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

    public class JuezCJPF
    {
        public string Id         { get; set; } = string.Empty;
        public string Nombre     { get; set; } = string.Empty;
        public bool   EstaActivo { get; set; }
    }

    public class AudienciaCJPF
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   JuezAsignado     { get; set; } = string.Empty;
        public DateTime FechaHoraInicio  { get; set; }
        public DateTime FechaHoraFin     { get; set; }
        public string   Estado           { get; set; } = string.Empty;
        public string?  MotivoAjuste     { get; set; }
    }

    public class ParametroAsignacion
    {
        public string TipoAudiencia { get; set; } = string.Empty;
        public string Descripcion   { get; set; } = string.Empty;
    }
}
