using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.AutorizacionAudienciaExtendida
{
    public class AutorizacionAudienciaExtendidaService
    {
        private readonly List<SolicitudExtension> _solicitudes;
        private readonly List<PerfilAutorizador>  _autorizadores;
        private readonly List<AudienciaCJPF>      _audiencias;

        public AutorizacionAudienciaExtendidaService(
            List<SolicitudExtension> solicitudes,
            List<PerfilAutorizador>  autorizadores,
            List<AudienciaCJPF>      audiencias)
        {
            _solicitudes   = solicitudes;
            _autorizadores = autorizadores;
            _audiencias    = audiencias;
        }

        public ResultadoOperacion CrearSolicitud(CrearSolicitudExtensionRequest request)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            if (audiencia.Estado != "En celebración")
                return ResultadoOperacion.Error(
                    "Solo se puede solicitar extensión de audiencias en celebración");

            // CORRECCIÓN ERR-AUT-001: Manejo de errores corregido
            // Se valida que no exista una solicitud pendiente para esta audiencia
            bool solicitudPendiente = _solicitudes.Any(s =>
                s.AudienciaId == request.AudienciaId &&
                s.Estado == "Pendiente");

            if (solicitudPendiente)
                return ResultadoOperacion.Error(
                    "ERR-AUT-001: Ya existe una solicitud de extensión pendiente para esta audiencia");

            var solicitud = new SolicitudExtension
            {
                Id              = _solicitudes.Count + 1,
                AudienciaId     = request.AudienciaId,
                MotivoExtension = request.MotivoExtension,
                FechaFinReal    = request.FechaFinReal,
                SolicitanteId   = request.UsuarioId,
                FechaSolicitud  = DateTime.Now,
                Estado          = "Pendiente",
                FechaExpiracion = DateTime.Now.AddHours(request.HorasExpiracion)
            };

            _solicitudes.Add(solicitud);

            return ResultadoOperacion.Exitoso(
                $"Solicitud de extensión creada. ID: {solicitud.Id}");
        }

        public ResultadoOperacion Autorizar(AutorizarExtensionRequest request)
        {
            var solicitud = _solicitudes.FirstOrDefault(s => s.Id == request.SolicitudId);
            if (solicitud == null)
                return ResultadoOperacion.Error("No se encontró la solicitud indicada");

            // CORRECCIÓN ERR-AUT-002: Manejo de errores corregido
            // Se valida que el autorizador tenga perfil autorizado antes de proceder
            var perfilAutorizador = _autorizadores.FirstOrDefault(a =>
                a.UsuarioId == request.AutorizadorId && a.PuedeAutorizar);

            if (perfilAutorizador == null)
                return ResultadoOperacion.Error(
                    "ERR-AUT-002: El usuario no cuenta con perfil autorizado para aprobar extensiones");

            if (solicitud.Estado != "Pendiente")
                return ResultadoOperacion.Error(
                    "Solo se pueden autorizar solicitudes en estado Pendiente");

            if (DateTime.Now > solicitud.FechaExpiracion)
            {
                solicitud.Estado = "Vencida";
                return ResultadoOperacion.Error(
                    "La solicitud de extensión ha vencido");
            }

            var audiencia = _audiencias.FirstOrDefault(a => a.Id == solicitud.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia asociada");

            solicitud.Estado             = "Autorizada";
            solicitud.AutorizadorId      = request.AutorizadorId;
            solicitud.FechaAutorizacion  = DateTime.Now;
            solicitud.MotivoAutorizacion = request.MotivoAutorizacion;

            audiencia.FechaFinReal    = solicitud.FechaFinReal;
            audiencia.MotivoExtension = solicitud.MotivoExtension;

            return ResultadoOperacion.Exitoso(
                "Extensión de audiencia autorizada correctamente");
        }

        public ResultadoOperacion Rechazar(RechazarExtensionRequest request)
        {
            var solicitud = _solicitudes.FirstOrDefault(s => s.Id == request.SolicitudId);
            if (solicitud == null)
                return ResultadoOperacion.Error("No se encontró la solicitud indicada");

            if (solicitud.Estado != "Pendiente")
                return ResultadoOperacion.Error(
                    "Solo se pueden rechazar solicitudes en estado Pendiente");

            solicitud.Estado            = "Rechazada";
            solicitud.AutorizadorId     = request.AutorizadorId;
            solicitud.MotivoRechazo     = request.MotivoRechazo;
            solicitud.FechaAutorizacion = DateTime.Now;

            return ResultadoOperacion.Exitoso(
                "Solicitud rechazada. La agenda original se conserva sin cambios");
        }
    }

    public class CrearSolicitudExtensionRequest
    {
        public int      AudienciaId     { get; set; }
        public string   MotivoExtension { get; set; } = string.Empty;
        public DateTime FechaFinReal    { get; set; }
        public string   UsuarioId       { get; set; } = string.Empty;
        public int      HorasExpiracion { get; set; } = 2;
    }

    public class AutorizarExtensionRequest
    {
        public int    SolicitudId        { get; set; }
        public string AutorizadorId      { get; set; } = string.Empty;
        public string MotivoAutorizacion { get; set; } = string.Empty;
    }

    public class RechazarExtensionRequest
    {
        public int    SolicitudId   { get; set; }
        public string AutorizadorId { get; set; } = string.Empty;
        public string MotivoRechazo { get; set; } = string.Empty;
    }

    public class SolicitudExtension
    {
        public int      Id                 { get; set; }
        public int      AudienciaId        { get; set; }
        public string   MotivoExtension    { get; set; } = string.Empty;
        public DateTime FechaFinReal       { get; set; }
        public string   SolicitanteId      { get; set; } = string.Empty;
        public DateTime FechaSolicitud     { get; set; }
        public DateTime FechaExpiracion    { get; set; }
        public string   Estado             { get; set; } = string.Empty;
        public string?  AutorizadorId      { get; set; }
        public DateTime? FechaAutorizacion { get; set; }
        public string?  MotivoAutorizacion { get; set; }
        public string?  MotivoRechazo      { get; set; }
    }

    public class PerfilAutorizador
    {
        public string UsuarioId      { get; set; } = string.Empty;
        public bool   PuedeAutorizar { get; set; }
    }

    public class AudienciaCJPF
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   Estado           { get; set; } = string.Empty;
        public DateTime FechaHoraFin     { get; set; }
        public DateTime? FechaFinReal    { get; set; }
        public string?  MotivoExtension  { get; set; }
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
