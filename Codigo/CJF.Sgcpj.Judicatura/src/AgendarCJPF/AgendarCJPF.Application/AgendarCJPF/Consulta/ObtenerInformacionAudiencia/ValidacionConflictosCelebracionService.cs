using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ValidacionConflictosCelebracion
{
    public class ValidacionConflictosCelebracionService
    {
        private readonly List<AudienciaCJPF>    _audiencias;
        private readonly List<PermisoExcepcion> _permisos;
        private readonly List<CapturaTemporal>  _capturas;

        public ValidacionConflictosCelebracionService(
            List<AudienciaCJPF>    audiencias,
            List<PermisoExcepcion> permisos,
            List<CapturaTemporal>  capturas)
        {
            _audiencias = audiencias;
            _permisos   = permisos;
            _capturas   = capturas;
        }

        public ResultadoValidacionConflicto ValidarEnTiempoReal(
            ValidarConflictoRequest request)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoValidacionConflicto.Error("El número de expediente es requerido");

            if (request.FechaHoraInicio == default || request.FechaHoraFin == default)
                return ResultadoValidacionConflicto.Error("Las fechas de inicio y fin son requeridas");

            if (request.FechaHoraInicio >= request.FechaHoraFin)
                return ResultadoValidacionConflicto.Error(
                    "La fecha de inicio debe ser anterior a la fecha de fin");

            var conflictosCriticos  = DetectarConflictosCriticos(request);
            var conflictosMenores   = DetectarConflictosMenores(request);

            if (conflictosCriticos.Any())
            {
                bool tienePermiso = _permisos.Any(p =>
                    p.UsuarioId == request.UsuarioId && p.TipoPermiso == "ExcepcionConflicto");

                if (!tienePermiso)
                    return ResultadoValidacionConflicto.ConflictoCritico(conflictosCriticos);

                return ResultadoValidacionConflicto.ExcepcionPermitida(
                    conflictosCriticos, "Conflicto crítico permitido por permiso especial");
            }

            if (conflictosMenores.Any())
                return ResultadoValidacionConflicto.Advertencia(conflictosMenores);

            return ResultadoValidacionConflicto.SinConflicto();
        }

        public ResultadoOperacion GuardarCapturaTemporal(
            CapturaTemporal captura, string usuarioId)
        {
            var existente = _capturas.FirstOrDefault(c =>
                c.UsuarioId == usuarioId && c.AudienciaId == captura.AudienciaId);

            if (existente != null)
            {
                existente.DatosCaptura   = captura.DatosCaptura;
                existente.FechaGuardado  = DateTime.Now;
            }
            else
            {
                captura.Id           = _capturas.Count + 1;
                captura.UsuarioId    = usuarioId;
                captura.FechaGuardado = DateTime.Now;
                _capturas.Add(captura);
            }

            return ResultadoOperacion.Exitoso("Captura temporal guardada correctamente");
        }

        public CapturaTemporal? RecuperarCapturaTemporal(int audienciaId, string usuarioId) =>
            _capturas.FirstOrDefault(c =>
                c.AudienciaId == audienciaId && c.UsuarioId == usuarioId);

        private List<ConflictoDetectado> DetectarConflictosCriticos(
            ValidarConflictoRequest request)
        {
            return _audiencias
                .Where(a =>
                    a.Estado != "Cancelada" &&
                    a.FechaHoraInicio < request.FechaHoraFin &&
                    a.FechaHoraFin > request.FechaHoraInicio &&
                    (a.Sala == request.Sala || a.JuezAsignado == request.JuezId))
                .Select(a => new ConflictoDetectado
                {
                    AudienciaConflictoId = a.Id,
                    TipoConflicto        = "Critico",
                    Descripcion          = a.Sala == request.Sala
                        ? $"Conflicto de sala: {a.Sala} ocupada de {a.FechaHoraInicio:HH:mm} a {a.FechaHoraFin:HH:mm}"
                        : $"Conflicto de juez: {a.JuezAsignado} asignado en ese horario"
                }).ToList();
        }

        private List<ConflictoDetectado> DetectarConflictosMenores(
            ValidarConflictoRequest request)
        {
            var margenMinutos = 15;
            return _audiencias
                .Where(a =>
                    a.Estado != "Cancelada" &&
                    Math.Abs((a.FechaHoraInicio - request.FechaHoraFin).TotalMinutes) < margenMinutos)
                .Select(a => new ConflictoDetectado
                {
                    AudienciaConflictoId = a.Id,
                    TipoConflicto        = "Menor",
                    Descripcion          =
                        $"Intervalo menor a {margenMinutos} minutos con audiencia {a.Id}"
                }).ToList();
        }
    }

    public class ValidarConflictoRequest
    {
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   UsuarioId        { get; set; } = string.Empty;
        public string   Sala             { get; set; } = string.Empty;
        public string   JuezId           { get; set; } = string.Empty;
        public DateTime FechaHoraInicio  { get; set; }
        public DateTime FechaHoraFin     { get; set; }
    }

    public class ConflictoDetectado
    {
        public int    AudienciaConflictoId { get; set; }
        public string TipoConflicto        { get; set; } = string.Empty;
        public string Descripcion          { get; set; } = string.Empty;
    }

    public class CapturaTemporal
    {
        public int      Id            { get; set; }
        public int      AudienciaId   { get; set; }
        public string   UsuarioId     { get; set; } = string.Empty;
        public string   DatosCaptura  { get; set; } = string.Empty;
        public DateTime FechaGuardado { get; set; }
    }

    public class PermisoExcepcion
    {
        public string UsuarioId    { get; set; } = string.Empty;
        public string TipoPermiso  { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int      Id             { get; set; }
        public string   Sala           { get; set; } = string.Empty;
        public string   JuezAsignado   { get; set; } = string.Empty;
        public string   Estado         { get; set; } = string.Empty;
        public DateTime FechaHoraInicio { get; set; }
        public DateTime FechaHoraFin   { get; set; }
    }

    public class ResultadoValidacionConflicto
    {
        public bool                    Exito      { get; private set; }
        public string                  Mensaje    { get; private set; } = string.Empty;
        public string                  TipoResult { get; private set; } = string.Empty;
        public List<ConflictoDetectado> Conflictos { get; private set; } = new();

        public static ResultadoValidacionConflicto SinConflicto() =>
            new ResultadoValidacionConflicto { Exito = true, TipoResult = "SinConflicto" };

        public static ResultadoValidacionConflicto Advertencia(
            List<ConflictoDetectado> conflictos) =>
            new ResultadoValidacionConflicto
            {
                Exito      = true,
                TipoResult = "Advertencia",
                Conflictos = conflictos,
                Mensaje    = "Se detectaron conflictos menores"
            };

        public static ResultadoValidacionConflicto ConflictoCritico(
            List<ConflictoDetectado> conflictos) =>
            new ResultadoValidacionConflicto
            {
                Exito      = false,
                TipoResult = "ConflictoCritico",
                Conflictos = conflictos,
                Mensaje    = "No es posible agendar: conflicto crítico detectado"
            };

        public static ResultadoValidacionConflicto ExcepcionPermitida(
            List<ConflictoDetectado> conflictos, string mensaje) =>
            new ResultadoValidacionConflicto
            {
                Exito      = true,
                TipoResult = "ExcepcionPermitida",
                Conflictos = conflictos,
                Mensaje    = mensaje
            };

        public static ResultadoValidacionConflicto Error(string mensaje) =>
            new ResultadoValidacionConflicto { Exito = false, Mensaje = mensaje };
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
