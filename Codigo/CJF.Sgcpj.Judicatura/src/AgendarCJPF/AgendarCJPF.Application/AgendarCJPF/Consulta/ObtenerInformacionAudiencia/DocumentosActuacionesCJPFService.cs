using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.DocumentosActuacionesCJPF
{
    public class DocumentosActuacionesCJPFService
    {
        private readonly List<DocumentoAudiencia> _documentos;
        private readonly List<ActuacionAudiencia> _actuaciones;
        private readonly List<PermisoUsuario>     _permisos;

        public DocumentosActuacionesCJPFService(
            List<DocumentoAudiencia> documentos,
            List<ActuacionAudiencia> actuaciones,
            List<PermisoUsuario>     permisos)
        {
            _documentos  = documentos;
            _actuaciones = actuaciones;
            _permisos    = permisos;
        }

        public ResultadoDocumentos ObtenerDocumentos(int audienciaId, string usuarioId)
        {
            var documentos = _documentos
                .Where(d => d.AudienciaId == audienciaId)
                .Select(d => new DocumentoDto
                {
                    Id            = d.Id,
                    Nombre        = d.Nombre,
                    TipoDocumento = d.TipoDocumento,
                    FechaCaptura  = d.FechaCaptura.ToString("dd/MM/yyyy"),
                    Tamanio       = d.Tamanio,
                    Disponible    = d.Disponible,
                    EstadoAcceso  = d.Disponible
                        ? ObtenerEstadoAcceso(d, usuarioId)
                        : "No disponible"
                }).ToList();

            return new ResultadoDocumentos
            {
                Documentos      = documentos,
                TotalDocumentos = documentos.Count
            };
        }

        public ResultadoActuaciones ObtenerActuaciones(int audienciaId, string usuarioId)
        {
            bool tienePermiso = _permisos.Any(p =>
                p.UsuarioId == usuarioId && p.Accion == "VerActuaciones");

            var actuaciones = _actuaciones
                .Where(a => a.AudienciaId == audienciaId)
                .Select(a => new ActuacionDto
                {
                    Id            = a.Id,
                    TipoActuacion = a.TipoActuacion,
                    Descripcion   = a.Descripcion,
                    FechaActuacion = a.FechaActuacion.ToString("dd/MM/yyyy HH:mm"),
                    UsuarioCaptura = a.UsuarioCaptura,
                    PuedeAbrir    = tienePermiso && a.Autorizada
                }).ToList();

            return new ResultadoActuaciones
            {
                Actuaciones      = actuaciones,
                TotalActuaciones = actuaciones.Count
            };
        }

        private string ObtenerEstadoAcceso(DocumentoAudiencia documento, string usuarioId)
        {
            bool tienePermiso = _permisos.Any(p =>
                p.UsuarioId == usuarioId &&
                p.Accion == "AbrirDocumento");

            if (!tienePermiso) return "Sin permiso";
            return "Disponible";
        }
    }

    public class DocumentoAudiencia
    {
        public int      Id            { get; set; }
        public int      AudienciaId   { get; set; }
        public string   Nombre        { get; set; } = string.Empty;
        public string   TipoDocumento { get; set; } = string.Empty;
        public DateTime FechaCaptura  { get; set; }
        public string   Tamanio       { get; set; } = string.Empty;
        public bool     Disponible    { get; set; }
    }

    public class ActuacionAudiencia
    {
        public int      Id             { get; set; }
        public int      AudienciaId    { get; set; }
        public string   TipoActuacion  { get; set; } = string.Empty;
        public string   Descripcion    { get; set; } = string.Empty;
        public DateTime FechaActuacion { get; set; }
        public string   UsuarioCaptura { get; set; } = string.Empty;
        public bool     Autorizada     { get; set; }
    }

    public class DocumentoDto
    {
        public int    Id            { get; set; }
        public string Nombre        { get; set; } = string.Empty;
        public string TipoDocumento { get; set; } = string.Empty;
        public string FechaCaptura  { get; set; } = string.Empty;
        public string Tamanio       { get; set; } = string.Empty;
        public bool   Disponible    { get; set; }
        public string EstadoAcceso  { get; set; } = string.Empty;
    }

    public class ActuacionDto
    {
        public int    Id             { get; set; }
        public string TipoActuacion  { get; set; } = string.Empty;
        public string Descripcion    { get; set; } = string.Empty;
        public string FechaActuacion { get; set; } = string.Empty;
        public string UsuarioCaptura { get; set; } = string.Empty;
        public bool   PuedeAbrir     { get; set; }
    }

    public class ResultadoDocumentos
    {
        public List<DocumentoDto> Documentos      { get; set; } = new();
        public int                TotalDocumentos { get; set; }
    }

    public class ResultadoActuaciones
    {
        public List<ActuacionDto> Actuaciones      { get; set; } = new();
        public int                TotalActuaciones { get; set; }
    }

    public class PermisoUsuario
    {
        public string UsuarioId { get; set; } = string.Empty;
        public string Accion    { get; set; } = string.Empty;
    }
}
