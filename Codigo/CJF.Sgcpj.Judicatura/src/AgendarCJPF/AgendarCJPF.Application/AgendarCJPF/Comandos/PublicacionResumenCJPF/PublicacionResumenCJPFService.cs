using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.PublicacionResumenCJPF
{
    public class PublicacionResumenCJPFService
    {
        private readonly List<ResumenAudienciaCJPF> _resumenes;
        private readonly List<TrazoPublicacion>     _trazos;
        private readonly List<PermisoUsuario>       _permisos;
        private readonly List<ReglaPublicacion>     _reglas;

        public PublicacionResumenCJPFService(
            List<ResumenAudienciaCJPF> resumenes,
            List<TrazoPublicacion>     trazos,
            List<PermisoUsuario>       permisos,
            List<ReglaPublicacion>     reglas)
        {
            _resumenes = resumenes;
            _trazos    = trazos;
            _permisos  = permisos;
            _reglas    = reglas;
        }

        public ResultadoOperacion Publicar(PublicarResumenRequest request)
        {
            var resumen = _resumenes.FirstOrDefault(r => r.Id == request.ResumenId);
            if (resumen == null)
                return ResultadoOperacion.Error("No se encontró el resumen indicado");

            bool tienePermiso = _permisos.Any(p =>
                p.UsuarioId == request.UsuarioId && p.Accion == "PublicarResumen");
            if (!tienePermiso)
                return ResultadoOperacion.Error(
                    "No cuenta con permiso para publicar resúmenes de audiencia");

            var validacion = ValidarReglas(resumen);
            if (!validacion.Exito)
                return validacion;

            resumen.Publicado     = true;
            resumen.FechaPublicacion = DateTime.Now;
            resumen.PublicadoPor  = request.UsuarioId;

            _trazos.Add(new TrazoPublicacion
            {
                Id         = _trazos.Count + 1,
                ResumenId  = resumen.Id,
                Accion     = "Publicacion",
                UsuarioId  = request.UsuarioId,
                Fecha      = DateTime.Now,
                Exitoso    = true
            });

            return ResultadoOperacion.Exitoso(
                $"Resumen de audiencia {resumen.AudienciaId} publicado correctamente");
        }

        public ResultadoExportacion Exportar(ExportarResumenRequest request)
        {
            var resumen = _resumenes.FirstOrDefault(r => r.Id == request.ResumenId);
            if (resumen == null)
                return ResultadoExportacion.Error("No se encontró el resumen indicado");

            bool tienePermiso = _permisos.Any(p =>
                p.UsuarioId == request.UsuarioId && p.Accion == "ExportarResumen");
            if (!tienePermiso)
                return ResultadoExportacion.Error(
                    "No cuenta con permiso para exportar resúmenes de audiencia");

            var formatosPermitidos = new[] { "PDF", "XLSX", "DOCX" };
            if (!formatosPermitidos.Contains(request.Formato.ToUpper()))
                return ResultadoExportacion.Error(
                    $"Formato '{request.Formato}' no permitido. Use: {string.Join(", ", formatosPermitidos)}");

            try
            {
                var contenido = GenerarContenido(resumen, request.Formato);

                _trazos.Add(new TrazoPublicacion
                {
                    Id        = _trazos.Count + 1,
                    ResumenId = resumen.Id,
                    Accion    = $"Exportacion_{request.Formato}",
                    UsuarioId = request.UsuarioId,
                    Fecha     = DateTime.Now,
                    Exitoso   = true
                });

                return ResultadoExportacion.Exitoso(contenido, request.Formato);
            }
            catch (Exception ex)
            {
                var folio = Guid.NewGuid().ToString()[..8].ToUpper();

                _trazos.Add(new TrazoPublicacion
                {
                    Id        = _trazos.Count + 1,
                    ResumenId = resumen.Id,
                    Accion    = $"Exportacion_{request.Formato}",
                    UsuarioId = request.UsuarioId,
                    Fecha     = DateTime.Now,
                    Exitoso   = false,
                    Error     = ex.Message
                });

                return ResultadoExportacion.Error(
                    $"Error al exportar. Folio: {folio}. Puede reintentar la exportación");
            }
        }

        private ResultadoOperacion ValidarReglas(ResumenAudienciaCJPF resumen)
        {
            foreach (var regla in _reglas.Where(r => r.EstaActiva))
            {
                if (regla.Nombre == "RequiereAudienciaCelebrada" &&
                    resumen.EstadoAudiencia != "Celebrada")
                    return ResultadoOperacion.Error(
                        "La audiencia debe estar en estado Celebrada para publicar el resumen");

                if (regla.Nombre == "RequiereResolucion" &&
                    !resumen.TieneResoluciones)
                    return ResultadoOperacion.Error(
                        "El resumen debe contar con al menos una resolución para publicarse");
            }

            return ResultadoOperacion.Exitoso("Validaciones superadas");
        }

        private ContenidoResumen GenerarContenido(
            ResumenAudienciaCJPF resumen, string formato) =>
            new ContenidoResumen
            {
                ResumenId       = resumen.Id,
                AudienciaId     = resumen.AudienciaId,
                Formato         = formato.ToUpper(),
                FechaGeneracion = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss"),
                Secciones       = new List<string>
                {
                    "Datos generales de la audiencia",
                    "Resoluciones",
                    "Participantes",
                    "Índices"
                }
            };
    }

    public class PublicarResumenRequest
    {
        public int    ResumenId { get; set; }
        public string UsuarioId { get; set; } = string.Empty;
    }

    public class ExportarResumenRequest
    {
        public int    ResumenId { get; set; }
        public string UsuarioId { get; set; } = string.Empty;
        public string Formato   { get; set; } = "PDF";
    }

    public class ResumenAudienciaCJPF
    {
        public int      Id               { get; set; }
        public int      AudienciaId      { get; set; }
        public string   EstadoAudiencia  { get; set; } = string.Empty;
        public bool     TieneResoluciones { get; set; }
        public bool     Publicado        { get; set; }
        public DateTime? FechaPublicacion { get; set; }
        public string?  PublicadoPor     { get; set; }
    }

    public class TrazoPublicacion
    {
        public int      Id        { get; set; }
        public int      ResumenId { get; set; }
        public string   Accion    { get; set; } = string.Empty;
        public string   UsuarioId { get; set; } = string.Empty;
        public DateTime Fecha     { get; set; }
        public bool     Exitoso   { get; set; }
        public string?  Error     { get; set; }
    }

    public class PermisoUsuario
    {
        public string UsuarioId { get; set; } = string.Empty;
        public string Accion    { get; set; } = string.Empty;
    }

    public class ReglaPublicacion
    {
        public string Nombre    { get; set; } = string.Empty;
        public bool   EstaActiva { get; set; }
    }

    public class ContenidoResumen
    {
        public int          ResumenId       { get; set; }
        public int          AudienciaId     { get; set; }
        public string       Formato         { get; set; } = string.Empty;
        public string       FechaGeneracion { get; set; } = string.Empty;
        public List<string> Secciones       { get; set; } = new();
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

    public class ResultadoExportacion
    {
        public bool             Exito     { get; private set; }
        public string           Mensaje   { get; private set; } = string.Empty;
        public ContenidoResumen? Contenido { get; private set; }

        public static ResultadoExportacion Exitoso(ContenidoResumen contenido, string formato) =>
            new ResultadoExportacion
            {
                Exito    = true,
                Mensaje  = $"Resumen exportado en formato {formato}",
                Contenido = contenido
            };

        public static ResultadoExportacion Error(string mensaje) =>
            new ResultadoExportacion { Exito = false, Mensaje = mensaje };
    }
}
