using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.SegmentacionProductividad
{
    public class SegmentacionProductividadService
    {
        private readonly List<IndicadorProductividad> _indicadores;
        private readonly List<PermisoTablero>         _permisos;
        private readonly List<TrabajoSegundo>         _trabajos;

        public SegmentacionProductividadService(
            List<IndicadorProductividad> indicadores,
            List<PermisoTablero>         permisos,
            List<TrabajoSegundo>         trabajos)
        {
            _indicadores = indicadores;
            _permisos    = permisos;
            _trabajos    = trabajos;
        }

        public ResultadoSegmentacion ObtenerSegmentacion(
            SegmentacionRequest request, string usuarioId)
        {
            if (!TienePermiso(usuarioId))
                return ResultadoSegmentacion.Denegado(
                    "No cuenta con permisos para visualizar indicadores de productividad");

            if (request.FechaInicio > request.FechaFin)
                return ResultadoSegmentacion.Error(
                    "La fecha de inicio no puede ser mayor a la fecha fin");

            var diasRango = (request.FechaFin - request.FechaInicio).TotalDays;
            if (diasRango > 365)
            {
                var trabajo = new TrabajoSegundo
                {
                    Id          = _trabajos.Count + 1,
                    UsuarioId   = usuarioId,
                    Estado      = "EnProceso",
                    FechaInicio = DateTime.Now,
                    Parametros  = $"{request.FechaInicio:dd/MM/yyyy}-{request.FechaFin:dd/MM/yyyy}"
                };
                _trabajos.Add(trabajo);
                return ResultadoSegmentacion.EnSegundoPlano(trabajo.Id);
            }

            var query = _indicadores
                .Where(i => i.Fecha.Date >= request.FechaInicio.Date &&
                            i.Fecha.Date <= request.FechaFin.Date);

            if (!string.IsNullOrEmpty(request.OrganoId))
                query = query.Where(i => i.OrganoId == request.OrganoId);

            if (!string.IsNullOrEmpty(request.TipoAsunto))
                query = query.Where(i => i.TipoAsunto == request.TipoAsunto);

            var datos = query.ToList();

            var segmentos    = GenerarSegmentos(datos, request);
            var comparativos = GenerarComparativos(segmentos);

            return ResultadoSegmentacion.Exitoso(segmentos, comparativos);
        }

        private List<SegmentoProductividad> GenerarSegmentos(
            List<IndicadorProductividad> datos, SegmentacionRequest request)
        {
            return datos
                .GroupBy(i => new
                {
                    Periodo  = i.Fecha.ToString("MM/yyyy"),
                    OrganoId = i.OrganoId,
                    Asunto   = i.TipoAsunto
                })
                .Select(g => new SegmentoProductividad
                {
                    Periodo         = g.Key.Periodo,
                    OrganoId        = g.Key.OrganoId,
                    TipoAsunto      = g.Key.Asunto,
                    TotalExpedientes = g.Sum(i => i.TotalExpedientes),
                    TotalAudiencias  = g.Sum(i => i.TotalAudiencias),
                    PromedioResolucion = g.Any()
                        ? g.Average(i => i.DiasResolucion)
                        : 0,
                    EstaDisponible  = g.Any()
                }).ToList();
        }

        private List<ComparativoSegmento> GenerarComparativos(
            List<SegmentoProductividad> segmentos)
        {
            if (segmentos.Count < 2) return new List<ComparativoSegmento>();

            return segmentos
                .GroupBy(s => s.OrganoId)
                .Where(g => g.Count() > 1)
                .Select(g =>
                {
                    var lista = g.OrderBy(s => s.Periodo).ToList();
                    return new ComparativoSegmento
                    {
                        OrganoId             = g.Key,
                        PeriodoBase          = lista.First().Periodo,
                        PeriodoComparado     = lista.Last().Periodo,
                        VariacionExpedientes = lista.Last().TotalExpedientes - lista.First().TotalExpedientes,
                        VariacionAudiencias  = lista.Last().TotalAudiencias - lista.First().TotalAudiencias
                    };
                }).ToList();
        }

        private bool TienePermiso(string usuarioId) =>
            _permisos.Any(p => p.UsuarioId == usuarioId && p.PuedeVerTablero);
    }

    public class SegmentacionRequest
    {
        public DateTime FechaInicio { get; set; }
        public DateTime FechaFin    { get; set; }
        public string   OrganoId    { get; set; } = string.Empty;
        public string   TipoAsunto  { get; set; } = string.Empty;
    }

    public class IndicadorProductividad
    {
        public int      Id               { get; set; }
        public string   OrganoId         { get; set; } = string.Empty;
        public string   TipoAsunto       { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public int      TotalExpedientes { get; set; }
        public int      TotalAudiencias  { get; set; }
        public double   DiasResolucion   { get; set; }
    }

    public class SegmentoProductividad
    {
        public string Periodo            { get; set; } = string.Empty;
        public string OrganoId           { get; set; } = string.Empty;
        public string TipoAsunto         { get; set; } = string.Empty;
        public int    TotalExpedientes   { get; set; }
        public int    TotalAudiencias    { get; set; }
        public double PromedioResolucion { get; set; }
        public bool   EstaDisponible     { get; set; }
    }

    public class ComparativoSegmento
    {
        public string OrganoId             { get; set; } = string.Empty;
        public string PeriodoBase          { get; set; } = string.Empty;
        public string PeriodoComparado     { get; set; } = string.Empty;
        public int    VariacionExpedientes { get; set; }
        public int    VariacionAudiencias  { get; set; }
    }

    public class PermisoTablero
    {
        public string UsuarioId      { get; set; } = string.Empty;
        public bool   PuedeVerTablero { get; set; }
    }

    public class TrabajoSegundo
    {
        public int      Id          { get; set; }
        public string   UsuarioId   { get; set; } = string.Empty;
        public string   Estado      { get; set; } = string.Empty;
        public DateTime FechaInicio { get; set; }
        public string   Parametros  { get; set; } = string.Empty;
    }

    public class ResultadoSegmentacion
    {
        public bool   Exito    { get; private set; }
        public string Mensaje  { get; private set; } = string.Empty;
        public int?   TrabajoId { get; private set; }
        public List<SegmentoProductividad>  Segmentos    { get; private set; } = new();
        public List<ComparativoSegmento>    Comparativos { get; private set; } = new();

        public static ResultadoSegmentacion Exitoso(
            List<SegmentoProductividad> segmentos,
            List<ComparativoSegmento>   comparativos) =>
            new ResultadoSegmentacion
            {
                Exito        = true,
                Segmentos    = segmentos,
                Comparativos = comparativos
            };

        public static ResultadoSegmentacion EnSegundoPlano(int trabajoId) =>
            new ResultadoSegmentacion
            {
                Exito     = true,
                TrabajoId = trabajoId,
                Mensaje   = "El rango es amplio. El reporte se procesará en segundo plano"
            };

        public static ResultadoSegmentacion Denegado(string mensaje) =>
            new ResultadoSegmentacion { Exito = false, Mensaje = mensaje };

        public static ResultadoSegmentacion Error(string mensaje) =>
            new ResultadoSegmentacion { Exito = false, Mensaje = mensaje };
    }
}
