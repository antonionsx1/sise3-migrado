using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.ProyectosSentencias
{
    public class ProyectosSentenciasService
    {
        private readonly List<Proyecto>   _proyectos;
        private readonly List<Sentencia>  _sentencias;

        public ProyectosSentenciasService(
            List<Proyecto>  proyectos,
            List<Sentencia> sentencias)
        {
            _proyectos  = proyectos;
            _sentencias = sentencias;
        }

        public ResultadoPanel ObtenerPanel(PanelRequest request)
        {
            if (request.FechaInicio > request.FechaFin)
                return ResultadoPanel.Error(
                    "La fecha de inicio no puede ser mayor a la fecha fin");

            var proyectosPeriodo = _proyectos
                .Where(p => p.FechaCreacion.Date >= request.FechaInicio.Date &&
                            p.FechaCreacion.Date <= request.FechaFin.Date)
                .ToList();

            var sentenciasPeriodo = _sentencias
                .Where(s => s.FechaCreacion.Date >= request.FechaInicio.Date &&
                            s.FechaCreacion.Date <= request.FechaFin.Date &&
                            (s.Estatus == "Preautorizado" || s.Estatus == "Autorizado"))
                .ToList();

            var graficaCircular   = ConstruirGraficaCircular(proyectosPeriodo);
            var graficaSentencias = ConstruirGraficaSentencias(sentenciasPeriodo);
            var graficaSecretario = ConstruirGraficaSecretario(
                proyectosPeriodo, request.EstatusFiltro);

            return ResultadoPanel.Exitoso(new DashboardSentenciasDto
            {
                GraficaCircularProyectos   = graficaCircular,
                GraficaBarrasSentencias    = graficaSentencias,
                GraficaBarrasSecretario    = graficaSecretario
            });
        }

        public ResultadoPanel FiltrarPorEstatus(PanelRequest request, string estatus)
        {
            request.EstatusFiltro = estatus;
            return ObtenerPanel(request);
        }

        private GraficaCircularDto ConstruirGraficaCircular(List<Proyecto> proyectos)
        {
            var segmentos = proyectos
                .GroupBy(p => p.Estatus)
                .Select(g => new SegmentoCircularDto
                {
                    Estatus  = g.Key,
                    Cantidad = g.Count()
                })
                .OrderByDescending(s => s.Cantidad)
                .ToList();

            return new GraficaCircularDto
            {
                Segmentos = segmentos,
                Total     = proyectos.Count
            };
        }

        private List<BarraSentenciaDto> ConstruirGraficaSentencias(
            List<Sentencia> sentencias)
        {
            return sentencias
                .GroupBy(s => s.Estatus)
                .Select(g => new BarraSentenciaDto
                {
                    Estatus  = g.Key,
                    Cantidad = g.Count()
                })
                .OrderBy(b => b.Estatus)
                .ToList();
        }

        private List<BarraSecretarioDto> ConstruirGraficaSecretario(
            List<Proyecto> proyectos, string? estatusFiltro)
        {
            var query = proyectos.AsEnumerable();

            if (!string.IsNullOrEmpty(estatusFiltro))
                query = query.Where(p => p.Estatus == estatusFiltro);

            return query
                .GroupBy(p => new { p.SecretarioId, p.NombreSecretario, p.Estatus })
                .Select(g => new BarraSecretarioDto
                {
                    SecretarioId     = g.Key.SecretarioId,
                    NombreSecretario = g.Key.NombreSecretario,
                    Estatus          = g.Key.Estatus,
                    Cantidad         = g.Count()
                })
                .OrderBy(b => b.NombreSecretario)
                .ThenBy(b => b.Estatus)
                .ToList();
        }
    }

    public class PanelRequest
    {
        public DateTime FechaInicio   { get; set; }
        public DateTime FechaFin      { get; set; }
        public string?  EstatusFiltro { get; set; }
    }

    public class Proyecto
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   Estatus          { get; set; } = string.Empty;
        public string   SecretarioId     { get; set; } = string.Empty;
        public string   NombreSecretario { get; set; } = string.Empty;
        public DateTime FechaCreacion    { get; set; }
    }

    public class Sentencia
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   Estatus          { get; set; } = string.Empty;
        public DateTime FechaCreacion    { get; set; }
    }

    public class GraficaCircularDto
    {
        public List<SegmentoCircularDto> Segmentos { get; set; } = new();
        public int                       Total     { get; set; }
    }

    public class SegmentoCircularDto
    {
        public string Estatus  { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class BarraSentenciaDto
    {
        public string Estatus  { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class BarraSecretarioDto
    {
        public string SecretarioId     { get; set; } = string.Empty;
        public string NombreSecretario { get; set; } = string.Empty;
        public string Estatus          { get; set; } = string.Empty;
        public int    Cantidad         { get; set; }
    }

    public class DashboardSentenciasDto
    {
        public GraficaCircularDto       GraficaCircularProyectos { get; set; } = new();
        public List<BarraSentenciaDto>  GraficaBarrasSentencias  { get; set; } = new();
        public List<BarraSecretarioDto> GraficaBarrasSecretario  { get; set; } = new();
    }

    public class ResultadoPanel
    {
        public bool                  Exito     { get; private set; }
        public string                Mensaje   { get; private set; } = string.Empty;
        public DashboardSentenciasDto? Dashboard { get; private set; }

        public static ResultadoPanel Exitoso(DashboardSentenciasDto dashboard) =>
            new ResultadoPanel { Exito = true, Dashboard = dashboard };

        public static ResultadoPanel Error(string mensaje) =>
            new ResultadoPanel { Exito = false, Mensaje = mensaje };
    }
}
