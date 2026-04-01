using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Reporte.Consulta.ExportarReporte
{
    public class ExportarReporteService
    {
        private readonly List<Audiencia>    _audiencias;
        private readonly List<Recordatorio> _recordatorios;

        public ExportarReporteService(
            List<Audiencia>    audiencias,
            List<Recordatorio> recordatorios)
        {
            _audiencias    = audiencias;
            _recordatorios = recordatorios;
        }

        public ResultadoExportacion Exportar(ExportarReporteRequest request)
        {
            if (string.IsNullOrEmpty(request.UsuarioGenerador))
                return ResultadoExportacion.Error("El usuario generador es requerido");

            if (string.IsNullOrEmpty(request.FormatoExportacion))
                return ResultadoExportacion.Error("El formato de exportación es requerido");

            var formatosPermitidos = new[] { "XLSX", "PDF", "CSV" };
            if (!formatosPermitidos.Contains(request.FormatoExportacion.ToUpper()))
                return ResultadoExportacion.Error(
                    $"El formato {request.FormatoExportacion} no está permitido. " +
                    $"Formatos válidos: {string.Join(", ", formatosPermitidos)}");

            try
            {
                var filas = GenerarFilas(request);
                var encabezado = GenerarEncabezado(request);
                var contenido  = new ContenidoReporte
                {
                    Encabezado         = encabezado,
                    Filas              = filas,
                    FechaGeneracion    = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss"),
                    UsuarioGenerador   = request.UsuarioGenerador,
                    FormatoExportacion = request.FormatoExportacion.ToUpper(),
                    TotalRegistros     = filas.Count
                };

                return ResultadoExportacion.Exitoso(contenido);
            }
            catch (Exception ex)
            {
                var folio = Guid.NewGuid().ToString()[..8].ToUpper();
                return ResultadoExportacion.Error(
                    $"Error al generar el reporte. Folio: {folio}. Detalle: {ex.Message}");
            }
        }

        private List<string> GenerarEncabezado(ExportarReporteRequest request)
        {
            var encabezado = new List<string>();

            if (request.IncluirAudiencias)
                encabezado.AddRange(new[]
                {
                    "Expediente", "Parte", "Fecha Audiencia", "Hora Audiencia",
                    "Tipo Audiencia", "Resultado", "Agendado Por", "Secretario"
                });

            if (request.IncluirRecordatorios)
                encabezado.AddRange(new[]
                {
                    "Expediente", "Fecha Recordatorio", "Descripción",
                    "Capturado Por", "Asignado A"
                });

            return encabezado;
        }

        private List<List<string>> GenerarFilas(ExportarReporteRequest request)
        {
            var filas = new List<List<string>>();

            if (request.IncluirAudiencias)
            {
                var query = _audiencias.AsEnumerable();

                if (request.FechaInicio.HasValue && request.FechaFin.HasValue)
                    query = query.Where(a =>
                        a.FechaHora.Date >= request.FechaInicio.Value.Date &&
                        a.FechaHora.Date <= request.FechaFin.Value.Date);

                if (!string.IsNullOrEmpty(request.NumeroExpediente))
                    query = query.Where(a =>
                        a.NumeroExpediente.Contains(request.NumeroExpediente));

                foreach (var a in query)
                    filas.Add(new List<string>
                    {
                        a.NumeroExpediente,
                        a.PartesInteresadas,
                        a.FechaHora.ToString("dd/MM/yyyy"),
                        a.FechaHora.ToString("HH:mm"),
                        a.TipoAudiencia,
                        a.Estado,
                        a.PersonaQueAgenda,
                        a.Secretario
                    });
            }

            if (request.IncluirRecordatorios)
            {
                var query = _recordatorios.AsEnumerable();

                if (!string.IsNullOrEmpty(request.NumeroExpediente))
                    query = query.Where(r =>
                        r.NumeroExpediente.Contains(request.NumeroExpediente));

                foreach (var r in query)
                    filas.Add(new List<string>
                    {
                        r.NumeroExpediente,
                        r.Fecha.ToString("dd/MM/yyyy"),
                        r.Descripcion,
                        r.CapturedoPor,
                        r.AsignadoA
                    });
            }

            return filas;
        }
    }

    public class ExportarReporteRequest
    {
        public string    UsuarioGenerador   { get; set; } = string.Empty;
        public string    FormatoExportacion { get; set; } = "XLSX";
        public bool      IncluirAudiencias  { get; set; } = true;
        public bool      IncluirRecordatorios { get; set; } = true;
        public DateTime? FechaInicio        { get; set; }
        public DateTime? FechaFin           { get; set; }
        public string    NumeroExpediente   { get; set; } = string.Empty;
        public string    Persona            { get; set; } = string.Empty;
    }

    public class ContenidoReporte
    {
        public List<string>        Encabezado         { get; set; } = new();
        public List<List<string>>  Filas              { get; set; } = new();
        public string              FechaGeneracion    { get; set; } = string.Empty;
        public string              UsuarioGenerador   { get; set; } = string.Empty;
        public string              FormatoExportacion { get; set; } = string.Empty;
        public int                 TotalRegistros     { get; set; }
    }

    public class ResultadoExportacion
    {
        public bool             Exito    { get; private set; }
        public string           Mensaje  { get; private set; } = string.Empty;
        public ContenidoReporte? Contenido { get; private set; }

        public static ResultadoExportacion Exitoso(ContenidoReporte contenido) =>
            new ResultadoExportacion { Exito = true, Contenido = contenido };

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
