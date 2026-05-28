using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.TarjetaEjecucion
{
    public class TarjetaEjecucionService
    {
        private readonly List<EjecucionSentencia> _ejecuciones;

        public TarjetaEjecucionService(List<EjecucionSentencia> ejecuciones)
        {
            _ejecuciones = ejecuciones;
        }

        public ResultadoTarjetaEjecucion ObtenerTarjeta(TarjetaEjecucionRequest request)
        {
            var ejecPeriodo = _ejecuciones
                .Where(e => e.Fecha.Date >= request.FechaInicio.Date &&
                            e.Fecha.Date <= request.FechaFin.Date)
                .ToList();

            var contadores     = CalcularContadores(ejecPeriodo);
            var graficaAnillo  = ConstruirGraficaAnillo(ejecPeriodo, request.EstatusFiltro);
            var graficaBarras  = ConstruirGraficaBarras(ejecPeriodo, request.EstatusFiltro);

            return ResultadoTarjetaEjecucion.Exitoso(new DashboardEjecucionDto
            {
                Contadores    = contadores,
                GraficaAnillo = graficaAnillo,
                GraficaBarras = graficaBarras
            });
        }

        public ResultadoTarjetaEjecucion Restablecer(TarjetaEjecucionRequest request)
        {
            request.EstatusFiltro = null;
            return ObtenerTarjeta(request);
        }

        public FiltrosModuloEjecucionDto ObtenerFiltrosPorSecretarioYEstatus(
            string secretarioId, string estatus,
            DateTime fechaInicio, DateTime fechaFin) =>
            new FiltrosModuloEjecucionDto
            {
                SecretarioId = secretarioId,
                Estatus      = estatus,
                FechaInicio  = fechaInicio,
                FechaFin     = fechaFin
            };

        private ContadoresEjecucionDto CalcularContadores(
            List<EjecucionSentencia> ejecuciones) =>
            new ContadoresEjecucionDto
            {
                SinRequerimientoCumplimiento =
                    ejecuciones.Count(e => e.TipoContador == "SinRequerimientoCumplimiento"),
                SinDesahogo =
                    ejecuciones.Count(e => e.TipoContador == "SinDesahogo"),
                SinAcuerdoCumplimiento =
                    ejecuciones.Count(e => e.TipoContador == "SinAcuerdoCumplimiento")
            };

        private GraficaAnilloEjecucionDto ConstruirGraficaAnillo(
            List<EjecucionSentencia> ejecuciones, string? estatusFiltro)
        {
            var query = ejecuciones.AsEnumerable();
            if (!string.IsNullOrEmpty(estatusFiltro))
                query = query.Where(e => e.Estatus == estatusFiltro);

            var lista = query.ToList();

            var segmentos = lista
                .GroupBy(e => e.Estatus)
                .Select(g => new SegmentoAnilloEjecucionDto
                {
                    Estatus   = g.Key,
                    Cantidad  = g.Count(),
                    Porcentaje = lista.Count > 0
                        ? Math.Round((double)g.Count() / lista.Count * 100, 1) : 0
                })
                .OrderBy(s => s.Estatus)
                .ToList();

            return new GraficaAnilloEjecucionDto
            {
                Segmentos       = segmentos,
                Total           = lista.Count,
                EstatusFiltrado = estatusFiltro ?? string.Empty
            };
        }

        private List<BarraSecretarioEjecucionDto> ConstruirGraficaBarras(
            List<EjecucionSentencia> ejecuciones, string? estatusFiltro)
        {
            var query = ejecuciones.AsEnumerable();
            if (!string.IsNullOrEmpty(estatusFiltro))
                query = query.Where(e => e.Estatus == estatusFiltro);

            return query
                .GroupBy(e => new
                {
                    e.SecretarioId,
                    e.NombreSecretario,
                    e.Estatus
                })
                .Select(g => new BarraSecretarioEjecucionDto
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

    public class TarjetaEjecucionRequest
    {
        public DateTime FechaInicio   { get; set; } = DateTime.Today;
        public DateTime FechaFin      { get; set; } = DateTime.Today;
        public string?  EstatusFiltro { get; set; }
    }

    public class EjecucionSentencia
    {
        public int      Id               { get; set; }
        public string   SecretarioId     { get; set; } = string.Empty;
        public string   NombreSecretario { get; set; } = string.Empty;
        public string   Estatus          { get; set; } = string.Empty;
        public string   TipoContador     { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
    }

    public class ContadoresEjecucionDto
    {
        public int SinRequerimientoCumplimiento { get; set; }
        public int SinDesahogo                 { get; set; }
        public int SinAcuerdoCumplimiento      { get; set; }
    }

    public class GraficaAnilloEjecucionDto
    {
        public List<SegmentoAnilloEjecucionDto> Segmentos       { get; set; } = new();
        public int                              Total           { get; set; }
        public string                           EstatusFiltrado { get; set; } = string.Empty;
    }

    public class SegmentoAnilloEjecucionDto
    {
        public string Estatus    { get; set; } = string.Empty;
        public int    Cantidad   { get; set; }
        public double Porcentaje { get; set; }
    }

    public class BarraSecretarioEjecucionDto
    {
        public string SecretarioId     { get; set; } = string.Empty;
        public string NombreSecretario { get; set; } = string.Empty;
        public string Estatus          { get; set; } = string.Empty;
        public int    Cantidad         { get; set; }
    }

    public class DashboardEjecucionDto
    {
        public ContadoresEjecucionDto              Contadores    { get; set; } = new();
        public GraficaAnilloEjecucionDto           GraficaAnillo { get; set; } = new();
        public List<BarraSecretarioEjecucionDto>   GraficaBarras { get; set; } = new();
    }

    public class FiltrosModuloEjecucionDto
    {
        public string   SecretarioId { get; set; } = string.Empty;
        public string   Estatus      { get; set; } = string.Empty;
        public DateTime FechaInicio  { get; set; }
        public DateTime FechaFin     { get; set; }
    }

    public class ResultadoTarjetaEjecucion
    {
        public bool                  Exito     { get; private set; }
        public string                Mensaje   { get; private set; } = string.Empty;
        public DashboardEjecucionDto? Dashboard { get; private set; }

        public static ResultadoTarjetaEjecucion Exitoso(DashboardEjecucionDto dashboard) =>
            new ResultadoTarjetaEjecucion { Exito = true, Dashboard = dashboard };

        public static ResultadoTarjetaEjecucion Error(string mensaje) =>
            new ResultadoTarjetaEjecucion { Exito = false, Mensaje = mensaje };
    }
}
