using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.FiltrosComparativosGrafica
{
    public class FiltrosComparativosGraficaService
    {
        private readonly List<DatoProductividad> _datos;
        private readonly List<CatalogoComparativo> _catalogos;

        public FiltrosComparativosGraficaService(
            List<DatoProductividad>    datos,
            List<CatalogoComparativo>  catalogos)
        {
            _datos     = datos;
            _catalogos = catalogos;
        }

        public ResultadoGrafica AplicarFiltrosComparativos(FiltroComparativoRequest request)
        {
            if (request.Comparaciones == null || request.Comparaciones.Count < 2)
                return ResultadoGrafica.Error(
                    "Se requieren al menos dos periodos o categorías para realizar una comparación");

            if (request.Comparaciones.Count > 5)
                return ResultadoGrafica.Error(
                    "Se permite comparar un máximo de 5 elementos simultáneamente");

            var series    = new List<SerieGrafica>();
            var leyendas  = new List<string>();
            var sinDatos  = new List<string>();

            foreach (var comparacion in request.Comparaciones)
            {
                var catalogo = _catalogos.FirstOrDefault(c =>
                    c.Clave == comparacion.Clave && c.EstaVigente);

                if (catalogo == null)
                {
                    return ResultadoGrafica.Informativo(
                        $"La comparación '{comparacion.Clave}' no está disponible en el catálogo vigente");
                }

                var datosQuery = FiltrarDatos(comparacion);

                if (!datosQuery.Any())
                {
                    sinDatos.Add(comparacion.Etiqueta);
                    series.Add(new SerieGrafica
                    {
                        Etiqueta    = comparacion.Etiqueta,
                        Puntos      = new List<PuntoGrafica>(),
                        SinDatos    = true
                    });
                }
                else
                {
                    series.Add(new SerieGrafica
                    {
                        Etiqueta = comparacion.Etiqueta,
                        Puntos   = datosQuery.Select(d => new PuntoGrafica
                        {
                            Etiqueta = d.Periodo,
                            Valor    = d.Valor
                        }).ToList(),
                        SinDatos = false
                    });
                }

                leyendas.Add($"{comparacion.Etiqueta} ({comparacion.TipoCriterio})");
            }

            return ResultadoGrafica.Exitoso(series, leyendas, sinDatos);
        }

        public ResultadoGrafica RestablecerVistaBase()
        {
            var serieBase = new SerieGrafica
            {
                Etiqueta = "Vista base",
                Puntos   = _datos
                    .OrderBy(d => d.Periodo)
                    .Select(d => new PuntoGrafica
                    {
                        Etiqueta = d.Periodo,
                        Valor    = d.Valor
                    }).ToList(),
                SinDatos = false
            };

            return ResultadoGrafica.Exitoso(
                new List<SerieGrafica> { serieBase },
                new List<string> { "Vista base" },
                new List<string>());
        }

        private List<DatoProductividad> FiltrarDatos(CriterioComparacion criterio)
        {
            var query = _datos.AsEnumerable();

            if (criterio.TipoCriterio == "Periodo" &&
                criterio.FechaInicio.HasValue && criterio.FechaFin.HasValue)
            {
                query = query.Where(d =>
                    d.Fecha.Date >= criterio.FechaInicio.Value.Date &&
                    d.Fecha.Date <= criterio.FechaFin.Value.Date);
            }

            if (criterio.TipoCriterio == "Categoria" &&
                !string.IsNullOrEmpty(criterio.Categoria))
            {
                query = query.Where(d => d.Categoria == criterio.Categoria);
            }

            return query.OrderBy(d => d.Periodo).ToList();
        }
    }

    public class FiltroComparativoRequest
    {
        public List<CriterioComparacion> Comparaciones { get; set; } = new();
    }

    public class CriterioComparacion
    {
        public string    Clave        { get; set; } = string.Empty;
        public string    Etiqueta     { get; set; } = string.Empty;
        public string    TipoCriterio { get; set; } = string.Empty;
        public DateTime? FechaInicio  { get; set; }
        public DateTime? FechaFin     { get; set; }
        public string    Categoria    { get; set; } = string.Empty;
    }

    public class DatoProductividad
    {
        public string   Periodo   { get; set; } = string.Empty;
        public DateTime Fecha     { get; set; }
        public string   Categoria { get; set; } = string.Empty;
        public double   Valor     { get; set; }
    }

    public class CatalogoComparativo
    {
        public string Clave      { get; set; } = string.Empty;
        public string Nombre     { get; set; } = string.Empty;
        public bool   EstaVigente { get; set; }
    }

    public class SerieGrafica
    {
        public string           Etiqueta { get; set; } = string.Empty;
        public List<PuntoGrafica> Puntos { get; set; } = new();
        public bool             SinDatos { get; set; }
    }

    public class PuntoGrafica
    {
        public string Etiqueta { get; set; } = string.Empty;
        public double Valor    { get; set; }
    }

    public class ResultadoGrafica
    {
        public bool             Exito    { get; private set; }
        public string           Mensaje  { get; private set; } = string.Empty;
        public string           TipoResult { get; private set; } = string.Empty;
        public List<SerieGrafica> Series  { get; private set; } = new();
        public List<string>     Leyendas { get; private set; } = new();
        public List<string>     SinDatos { get; private set; } = new();

        public static ResultadoGrafica Exitoso(
            List<SerieGrafica> series,
            List<string>       leyendas,
            List<string>       sinDatos) =>
            new ResultadoGrafica
            {
                Exito      = true,
                TipoResult = "Exitoso",
                Series     = series,
                Leyendas   = leyendas,
                SinDatos   = sinDatos
            };

        public static ResultadoGrafica Informativo(string mensaje) =>
            new ResultadoGrafica
            {
                Exito      = true,
                TipoResult = "Informativo",
                Mensaje    = mensaje
            };

        public static ResultadoGrafica Error(string mensaje) =>
            new ResultadoGrafica { Exito = false, Mensaje = mensaje };
    }
}
