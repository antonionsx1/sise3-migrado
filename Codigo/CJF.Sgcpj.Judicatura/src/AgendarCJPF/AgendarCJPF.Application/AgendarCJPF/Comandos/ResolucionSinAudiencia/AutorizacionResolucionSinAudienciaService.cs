using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.AutorizacionResolucionSinAudiencia
{
    public class AutorizacionResolucionSinAudienciaService
    {
        private readonly List<ResolucionCJPF>    _resoluciones;
        private readonly List<NivelAutorizacion> _niveles;
        private readonly List<PerfilAutorizador> _perfiles;
        private readonly List<DictamenFinal>     _dictamenes;

        public AutorizacionResolucionSinAudienciaService(
            List<ResolucionCJPF>    resoluciones,
            List<NivelAutorizacion> niveles,
            List<PerfilAutorizador> perfiles,
            List<DictamenFinal>     dictamenes)
        {
            _resoluciones = resoluciones;
            _niveles      = niveles;
            _perfiles     = perfiles;
            _dictamenes   = dictamenes;
        }

        public ResultadoOperacion Autorizar(AutorizarResolucionRequest request)
        {
            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == request.ResolucionId);
            if (resolucion == null)
                return ResultadoOperacion.Error("No se encontró la resolución indicada");

            if (resolucion.Estado != "PendienteAutorizacion")
                return ResultadoOperacion.Error(
                    "Solo se pueden autorizar resoluciones en estado PendienteAutorizacion");

            // CORRECCIÓN ERR-DOC-001: Manejo de errores corregido
            // Se valida que exista soporte documental antes de autorizar
            if (!resolucion.TieneSoporteDocumental)
                return ResultadoOperacion.Error(
                    "ERR-DOC-001: La resolución no cuenta con soporte documental requerido para su autorización");

            var nivel = ObtenerNivelRequerido(resolucion);
            if (nivel == null)
                return ResultadoOperacion.Error(
                    "No se encontró el nivel de autorización requerido para este tipo de resolución");

            var perfil = ObtenerAutorizadorDisponible(nivel, request.AutorizadorId);
            if (perfil == null)
                return ResultadoOperacion.Error(
                    "El autorizador no tiene el nivel requerido o no está disponible. " +
                    "Se escalará al suplente");

            resolucion.Estado            = "Autorizada";
            resolucion.AutorizadoPor     = perfil.UsuarioId;
            resolucion.FechaAutorizacion = DateTime.Now;

            _dictamenes.Add(new DictamenFinal
            {
                Id            = _dictamenes.Count + 1,
                ResolucionId  = resolucion.Id,
                Dictamen      = "Autorizada",
                AutorizadorId = perfil.UsuarioId,
                Observaciones = request.Observaciones,
                Fecha         = DateTime.Now
            });

            return ResultadoOperacion.Exitoso(
                $"Resolución {resolucion.Id} autorizada correctamente por {perfil.Nombre}");
        }

        public ResultadoOperacion Rechazar(RechazarResolucionRequest request)
        {
            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == request.ResolucionId);
            if (resolucion == null)
                return ResultadoOperacion.Error("No se encontró la resolución indicada");

            if (string.IsNullOrEmpty(request.MotivoRechazo))
                return ResultadoOperacion.Error("El motivo de rechazo es requerido");

            resolucion.Estado = "Rechazada";

            _dictamenes.Add(new DictamenFinal
            {
                Id            = _dictamenes.Count + 1,
                ResolucionId  = resolucion.Id,
                Dictamen      = "Rechazada",
                AutorizadorId = request.AutorizadorId,
                Observaciones = request.MotivoRechazo,
                Fecha         = DateTime.Now
            });

            return ResultadoOperacion.Exitoso("Resolución rechazada correctamente");
        }

        private NivelAutorizacion? ObtenerNivelRequerido(ResolucionCJPF resolucion) =>
            _niveles.FirstOrDefault(n => n.TipoResolucion == resolucion.TipoResolucion);

        private PerfilAutorizador? ObtenerAutorizadorDisponible(
            NivelAutorizacion nivel, string autorizadorId)
        {
            var perfil = _perfiles.FirstOrDefault(p =>
                p.UsuarioId == autorizadorId &&
                p.NivelAutorizacion >= nivel.NivelRequerido &&
                p.EstaDisponible);

            if (perfil != null) return perfil;

            // Escalar al suplente
            return _perfiles.FirstOrDefault(p =>
                p.EsSuplente &&
                p.NivelAutorizacion >= nivel.NivelRequerido &&
                p.EstaDisponible);
        }
    }

    public class AutorizarResolucionRequest
    {
        public int    ResolucionId  { get; set; }
        public string AutorizadorId { get; set; } = string.Empty;
        public string Observaciones { get; set; } = string.Empty;
    }

    public class RechazarResolucionRequest
    {
        public int    ResolucionId  { get; set; }
        public string AutorizadorId { get; set; } = string.Empty;
        public string MotivoRechazo { get; set; } = string.Empty;
    }

    public class ResolucionCJPF
    {
        public int      Id                     { get; set; }
        public string   TipoResolucion         { get; set; } = string.Empty;
        public string   Estado                 { get; set; } = string.Empty;
        public bool     TieneSoporteDocumental { get; set; }
        public string?  AutorizadoPor          { get; set; }
        public DateTime? FechaAutorizacion     { get; set; }
    }

    public class NivelAutorizacion
    {
        public string TipoResolucion { get; set; } = string.Empty;
        public int    NivelRequerido { get; set; }
    }

    public class PerfilAutorizador
    {
        public string UsuarioId         { get; set; } = string.Empty;
        public string Nombre            { get; set; } = string.Empty;
        public int    NivelAutorizacion { get; set; }
        public bool   EstaDisponible    { get; set; }
        public bool   EsSuplente        { get; set; }
    }

    public class DictamenFinal
    {
        public int      Id            { get; set; }
        public int      ResolucionId  { get; set; }
        public string   Dictamen      { get; set; } = string.Empty;
        public string   AutorizadorId { get; set; } = string.Empty;
        public string   Observaciones { get; set; } = string.Empty;
        public DateTime Fecha         { get; set; }
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
