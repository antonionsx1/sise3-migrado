using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Reporte.Consulta.ExportarReporteTCA
{
    // ERROR ERR-EXP-001: Estructura incorrecta
    // La lógica de validación de permisos, generación de contenido,
    // procesamiento en segundo plano y descarga están todas mezcladas
    // en una sola clase sin separación de responsabilidades
    public class ExportarReporteTCAService
    {
        private readonly List<Audiencia>    _audiencias;
        private readonly List<Recordatorio> _recordatorios;
        private readonly List<PermisoUsuario> _permisos;
        private readonly List<TrabajoExportacion> _trabajos;

        public ExportarReporteTCAService(
            List<Audiencia>          audiencias,
            List<Recordatorio>       recordatorios,
            List<PermisoUsuario>     permisos,
            List<TrabajoExportacion> trabajos)
        {
            _audiencias    = audiencias;
            _recordatorios = recordatorios;
            _permisos      = permisos;
            _trabajos      = trabajos;
        }

        public ResultadoExportacion Exportar(ExportarReporteTCARequest request)
        {
            // Validación de permisos mezclada con generación
            var permiso = _permisos.FirstOrDefault(p =>
                p.UsuarioId == request.UsuarioId && p.Accion == "ExportarReporte");

            if (permiso == null)
                return ResultadoExportacion.Error("No cuenta con permiso para exportar reportes");

            // Generación de contenido mezclada con lógica de tamaño
            var filas = GenerarFilas(request);
            var estimadoBytes = filas.Count * 500;
            var limiteBytes   = 5 * 1024 * 1024; // 5MB

            // Procesamiento en segundo plano mezclado con generación directa
            if (estimadoBytes > limiteBytes)
            {
                var trabajo = new TrabajoExportacion
                {
                    Id          = Guid.NewGuid().ToString(),
                    UsuarioId   = request.UsuarioId,
                    Estado      = "EnProceso",
                    FechaInicio = DateTime.Now,
                    Parametros  = request
                };
                _trabajos.Add(trabajo);

                return ResultadoExportacion.EnSegundoPlano(trabajo.Id);
            }

            var contenido = new ContenidoExportacion
            {
                Encabezado         = GenerarEncabezado(request),
                Filas              = filas,
                FechaGeneracion    = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss"),
                UsuarioGenerador   = request.UsuarioId,
                FormatoExportacion = request.Formato,
                TotalRegistros     = filas.Count
            };

            return ResultadoExportacion.Exitoso(contenido);
        }

        private List<string> GenerarEncabezado(ExportarReporteTCARequest request)
        {
            var encabezado = new List<string>();
            if (request.IncluirAudiencias)
                encabezado.AddRange(new[] {
                    "Expediente", "Parte", "Fecha", "Hora",
                    "Audiencia", "Resultado", "Agendado Por", "Secretario"
                });
            if (request.IncluirRecordatorios)
                encabezado.AddRange(new[] {
                    "Expediente", "Fecha", "Recordatorio", "Capturado Por", "Asignado A"
                });
            return encabezado;
        }

        private List<List<string>> GenerarFilas(ExportarReporteTCARequest request)
        {
            var filas = new List<List<string>>();

            if (request.IncluirAudiencias)
            {
                var query = _audiencias.AsEnumerable();
                if (request.FechaInicio.HasValue && request.FechaFin.HasValue)
                    query = query.Where(a =>
                        a.FechaHora.Date >= request.FechaInicio.Value.Date &&
                        a.FechaHora.Date <= request.FechaFin.Value.Date);

                foreach (var a in query)
                    filas.Add(new List<string> {
                        a.NumeroExpediente, a.PartesInteresadas,
                        a.FechaHora.ToString("dd/MM/yyyy"), a.FechaHora.ToString("HH:mm"),
                        a.TipoAudiencia, a.Estado, a.PersonaQueAgenda, a.Secretario
                    });
            }

            if (request.IncluirRecordatorios)
            {
                foreach (var r in _recordatorios)
                    filas.Add(new List<string> {
                        r.NumeroExpediente, r.Fecha.ToString("dd/MM/yyyy"),
                        r.Descripcion, r.CapturedoPor, r.AsignadoA
                    });
            }

            return filas;
        }
    }

    public class ExportarReporteTCARequest
    {
        public string    UsuarioId          { get; set; } = string.Empty;
        public string    Formato            { get; set; } = "XLSX";
        public bool      IncluirAudiencias  { get; set; } = true;
        public bool      IncluirRecordatorios { get; set; } = true;
        public DateTime? FechaInicio        { get; set; }
        public DateTime? FechaFin           { get; set; }
    }

    public class ContenidoExportacion
    {
        public List<string>       Encabezado         { get; set; } = new();
        public List<List<string>> Filas              { get; set; } = new();
        public string             FechaGeneracion    { get; set; } = string.Empty;
        public string             UsuarioGenerador   { get; set; } = string.Empty;
        public string             FormatoExportacion { get; set; } = string.Empty;
        public int                TotalRegistros     { get; set; }
    }

    public class TrabajoExportacion
    {
        public string                    Id          { get; set; } = string.Empty;
        public string                    UsuarioId   { get; set; } = string.Empty;
        public string                    Estado      { get; set; } = string.Empty;
        public DateTime                  FechaInicio { get; set; }
        public ExportarReporteTCARequest? Parametros  { get; set; }
    }

    public class PermisoUsuario
    {
        public string UsuarioId { get; set; } = string.Empty;
        public string Accion    { get; set; } = string.Empty;
    }

    public class ResultadoExportacion
    {
        public bool                Exito        { get; private set; }
        public string              Mensaje      { get; private set; } = string.Empty;
        public ContenidoExportacion? Contenido  { get; private set; }
        public string?             TrabajoId    { get; private set; }

        public static ResultadoExportacion Exitoso(ContenidoExportacion contenido) =>
            new ResultadoExportacion { Exito = true, Contenido = contenido };

        public static ResultadoExportacion EnSegundoPlano(string trabajoId) =>
            new ResultadoExportacion
            {
                Exito     = true,
                Mensaje   = "El reporte se está generando en segundo plano",
                TrabajoId = trabajoId
            };

        public static ResultadoExportacion Error(string mensaje) =>
            new ResultadoExportacion { Exito = false, Mensaje = mensaje };
    }

    public class Recordatorio
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public string   Descripcion      { get; set; } = string.Empty;
        public string   CapturedoPor     { get; set; } = string.Empty;
        public string   AsignadoA        { get; set; } = string.Empty;
    }
}
