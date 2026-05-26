using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.ProductividadOficialia
{
    public class ProductividadOfficialiaService
    {
        private readonly List<UsuarioOficialia>   _usuarios;
        private readonly List<Promocion>          _promociones;

        public ProductividadOfficialiaService(
            List<UsuarioOficialia> usuarios,
            List<Promocion>        promociones)
        {
            _usuarios    = usuarios;
            _promociones = promociones;
        }

        public List<PestanaUsuarioDto> ObtenerPestanas(int organoId)
        {
            return _usuarios
                .Where(u => u.OrganoId == organoId &&
                            (u.Rol == "Oficial de Partes" ||
                             u.Rol == "Auxiliar de Oficial de Partes"))
                .Select(u => new PestanaUsuarioDto
                {
                    UsuarioId     = u.Id,
                    NombreCompleto = u.NombreCompleto,
                    NombreUsuario = u.NombreUsuario,
                    Rol           = u.Rol,
                    Fotografia    = u.Fotografia
                }).ToList();
        }

        public ResultadoProductividad ObtenerProductividad(
            ProductividadRequest request)
        {
            var usuario = _usuarios.FirstOrDefault(u => u.Id == request.UsuarioId);
            if (usuario == null)
                return ResultadoProductividad.Error("No se encontró el usuario indicado");

            var inicioAnio  = new DateTime(DateTime.Today.Year, 1, 1);
            var hoy         = DateTime.Today;

            // Promociones del periodo filtrado
            var promocionesPeriodo = _promociones
                .Where(p => p.UsuarioId == request.UsuarioId &&
                            p.FechaCaptura.Date >= request.FechaInicio.Date &&
                            p.FechaCaptura.Date <= request.FechaFin.Date)
                .ToList();

            // Promociones del año en curso
            var promocioneAnio = _promociones
                .Where(p => p.UsuarioId == request.UsuarioId &&
                            p.FechaCaptura.Date >= inicioAnio &&
                            p.FechaCaptura.Date <= hoy)
                .ToList();

            var turnadasPeriodo = promocionesPeriodo.Count(p => p.FechaTurno.HasValue);
            var diasAnio        = (hoy - inicioAnio).Days + 1;
            var turnadasAnio    = promocioneAnio.Count(p => p.FechaTurno.HasValue);

            double promedioXDia = diasAnio > 0 ? Math.Round((double)turnadasAnio / diasAnio, 2) : 0;

            double tiempoPromedio = promocioneAnio
                .Where(p => p.FechaTurno.HasValue)
                .Select(p => (p.FechaTurno!.Value - p.FechaCaptura).TotalMinutes)
                .DefaultIfEmpty(0)
                .Average();

            var paginacion = PaginarGraficaPuntos(promocionesPeriodo, request.PaginaGrafica);
            var barrasApiladas = ObtenerBarrasApiladas(request.UsuarioId);

            return ResultadoProductividad.Exitoso(new DashboardUsuarioDto
            {
                Usuario          = new PestanaUsuarioDto
                {
                    UsuarioId      = usuario.Id,
                    NombreCompleto = usuario.NombreCompleto,
                    NombreUsuario  = usuario.NombreUsuario,
                    Rol            = usuario.Rol,
                    Fotografia     = usuario.Fotografia
                },
                ContadorPeriodo  = $"{turnadasPeriodo} de {promocionesPeriodo.Count}",
                TotalAnio        = promocioneAnio.Count,
                PromedioXDia     = promedioXDia,
                TiempoPromedioMin = Math.Round(tiempoPromedio, 1),
                GraficaPuntos    = paginacion,
                GraficaBarras    = barrasApiladas
            });
        }

        private GraficaPuntosDto PaginarGraficaPuntos(
            List<Promocion> promociones, int pagina)
        {
            const int tamanioPagina = 40;
            var ordenadas = promociones.OrderBy(p => p.FechaCaptura).ToList();
            var totalPaginas = (int)Math.Ceiling((double)ordenadas.Count / tamanioPagina);
            var paginaActual = Math.Max(1, Math.Min(pagina, totalPaginas));

            var puntos = ordenadas
                .Skip((paginaActual - 1) * tamanioPagina)
                .Take(tamanioPagina)
                .Select(p => new PuntoGraficaDto
                {
                    NumeroPromocion = p.NumeroPromocion,
                    HoraCaptura     = p.FechaCaptura.ToString("HH:mm"),
                    HoraTurno       = p.FechaTurno?.ToString("HH:mm") ?? string.Empty,
                    FueTurnada      = p.FechaTurno.HasValue
                }).ToList();

            return new GraficaPuntosDto
            {
                Puntos       = puntos,
                PaginaActual = paginaActual,
                TotalPaginas = totalPaginas,
                TotalRegistros = ordenadas.Count
            };
        }

        private List<BarraApiladadaDto> ObtenerBarrasApiladas(string usuarioId)
        {
            var hace12Meses = DateTime.Today.AddMonths(-11);
            var inicio      = new DateTime(hace12Meses.Year, hace12Meses.Month, 1);

            return _promociones
                .Where(p => p.UsuarioId == usuarioId && p.FechaCaptura >= inicio)
                .GroupBy(p => new
                {
                    Mes       = p.FechaCaptura.ToString("MM/yyyy"),
                    TipoAsunto = p.TipoAsunto
                })
                .Select(g => new BarraApiladadaDto
                {
                    Mes        = g.Key.Mes,
                    TipoAsunto = g.Key.TipoAsunto,
                    Cantidad   = g.Count()
                })
                .OrderBy(b => b.Mes)
                .ToList();
        }
    }

    public class ProductividadRequest
    {
        public string   UsuarioId    { get; set; } = string.Empty;
        public DateTime FechaInicio  { get; set; }
        public DateTime FechaFin     { get; set; }
        public int      PaginaGrafica { get; set; } = 1;
    }

    public class UsuarioOficialia
    {
        public string Id             { get; set; } = string.Empty;
        public int    OrganoId       { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
    }

    public class Promocion
    {
        public int      NumeroPromocion { get; set; }
        public string   UsuarioId       { get; set; } = string.Empty;
        public string   TipoAsunto      { get; set; } = string.Empty;
        public DateTime FechaCaptura    { get; set; }
        public DateTime? FechaTurno     { get; set; }
    }

    public class PestanaUsuarioDto
    {
        public string UsuarioId      { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
    }

    public class DashboardUsuarioDto
    {
        public PestanaUsuarioDto   Usuario           { get; set; } = new();
        public string              ContadorPeriodo   { get; set; } = string.Empty;
        public int                 TotalAnio         { get; set; }
        public double              PromedioXDia      { get; set; }
        public double              TiempoPromedioMin { get; set; }
        public GraficaPuntosDto    GraficaPuntos     { get; set; } = new();
        public List<BarraApiladadaDto> GraficaBarras { get; set; } = new();
    }

    public class GraficaPuntosDto
    {
        public List<PuntoGraficaDto> Puntos         { get; set; } = new();
        public int                   PaginaActual   { get; set; }
        public int                   TotalPaginas   { get; set; }
        public int                   TotalRegistros { get; set; }
    }

    public class PuntoGraficaDto
    {
        public int    NumeroPromocion { get; set; }
        public string HoraCaptura    { get; set; } = string.Empty;
        public string HoraTurno      { get; set; } = string.Empty;
        public bool   FueTurnada     { get; set; }
    }

    public class BarraApiladadaDto
    {
        public string Mes        { get; set; } = string.Empty;
        public string TipoAsunto { get; set; } = string.Empty;
        public int    Cantidad   { get; set; }
    }

    public class ResultadoProductividad
    {
        public bool                Exito     { get; private set; }
        public string              Mensaje   { get; private set; } = string.Empty;
        public DashboardUsuarioDto? Dashboard { get; private set; }

        public static ResultadoProductividad Exitoso(DashboardUsuarioDto dashboard) =>
            new ResultadoProductividad { Exito = true, Dashboard = dashboard };

        public static ResultadoProductividad Error(string mensaje) =>
            new ResultadoProductividad { Exito = false, Mensaje = mensaje };
    }
}
