using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.ProductividadTramite
{
    // CORRECCIÓN ERR-TRAM-001: Estructura corregida
    // Se separan las responsabilidades en clases independientes:
    // - ProductividadTramiteService: orquesta la consulta
    // - ContadoresRolHelper: calcula contadores según el rol
    // - GraficaPuntosAcuerdoHelper: construye y pagina la gráfica de puntos
    // - BarrasApiladasAcuerdoHelper: agrupa acuerdos por tipo y mes

    public class ProductividadTramiteService
    {
        private readonly List<UsuarioTramite>       _usuarios;
        private readonly ContadoresRolHelper        _contadoresHelper;
        private readonly GraficaPuntosAcuerdoHelper _graficaHelper;
        private readonly BarrasApiladasAcuerdoHelper _barrasHelper;

        public ProductividadTramiteService(
            List<UsuarioTramite> usuarios,
            List<Acuerdo>        acuerdos)
        {
            _usuarios         = usuarios;
            _contadoresHelper = new ContadoresRolHelper(acuerdos);
            _graficaHelper    = new GraficaPuntosAcuerdoHelper(acuerdos);
            _barrasHelper     = new BarrasApiladasAcuerdoHelper(acuerdos);
        }

        public List<PestanaTramiteDto> ObtenerPestanas(int organoId) =>
            _usuarios
                .Where(u => u.OrganoId == organoId)
                .OrderBy(u => u.Orden)
                .Select(u => new PestanaTramiteDto
                {
                    UsuarioId      = u.Id,
                    NombreCompleto = u.NombreCompleto,
                    NombreUsuario  = u.NombreUsuario,
                    Rol            = u.Rol,
                    TipoArea       = u.TipoArea,
                    Fotografia     = u.Fotografia
                }).ToList();

        public ResultadoProductividadTramite ObtenerProductividad(
            ProductividadTramiteRequest request)
        {
            var usuario = _usuarios.FirstOrDefault(u => u.Id == request.UsuarioId);
            if (usuario == null)
                return ResultadoProductividadTramite.Error("No se encontró el usuario");

            var contadores    = _contadoresHelper.Calcular(request, usuario.Rol);
            var graficaPuntos = _graficaHelper.Construir(request, usuario.Rol);
            var graficaBarras = _barrasHelper.Agrupar(request.UsuarioId);

            return ResultadoProductividadTramite.Exitoso(new DashboardTramiteDto
            {
                Usuario = new PestanaTramiteDto
                {
                    UsuarioId      = usuario.Id,
                    NombreCompleto = usuario.NombreCompleto,
                    NombreUsuario  = usuario.NombreUsuario,
                    Rol            = usuario.Rol,
                    TipoArea       = usuario.TipoArea,
                    Fotografia     = usuario.Fotografia
                },
                EtiquetaRol       = contadores.EtiquetaRol,
                ContadorPeriodo   = contadores.ContadorPeriodo,
                TotalAnio         = contadores.TotalAnio,
                PromedioXDia      = contadores.PromedioXDia,
                TiempoPromedioMin = contadores.TiempoPromedioMin,
                GraficaPuntos     = graficaPuntos,
                GraficaBarras     = graficaBarras
            });
        }
    }

    public class ContadoresRolHelper
    {
        private readonly List<Acuerdo> _acuerdos;

        public ContadoresRolHelper(List<Acuerdo> acuerdos) => _acuerdos = acuerdos;

        public ContadoresRolDto Calcular(ProductividadTramiteRequest request, string rol)
        {
            var inicioAnio = new DateTime(DateTime.Today.Year, 1, 1);
            var hoy        = DateTime.Today;

            var periodo = Filtrar(request.UsuarioId, request.FechaInicio, request.FechaFin);
            var anio    = Filtrar(request.UsuarioId, inicioAnio, hoy);

            var trabajadosPeriodo = periodo.Count(a => EsTrabajado(a, rol));
            var trabajadosAnio    = anio.Count(a => EsTrabajado(a, rol));
            var diasAnio          = (hoy - inicioAnio).Days + 1;

            double promedioXDia = diasAnio > 0
                ? Math.Round((double)trabajadosAnio / diasAnio, 2) : 0;

            double tiempoPromedio = anio
                .Where(a => EsTrabajado(a, rol))
                .Select(a => ObtenerTiempo(a, rol))
                .DefaultIfEmpty(0).Average();

            return new ContadoresRolDto
            {
                EtiquetaRol       = ObtenerEtiqueta(rol),
                ContadorPeriodo   = $"{trabajadosPeriodo} de {periodo.Count}",
                TotalAnio         = trabajadosAnio,
                PromedioXDia      = promedioXDia,
                TiempoPromedioMin = Math.Round(tiempoPromedio, 1)
            };
        }

        private List<Acuerdo> Filtrar(string usuarioId, DateTime inicio, DateTime fin) =>
            _acuerdos.Where(a =>
                a.UsuarioId == usuarioId &&
                a.FechaAsignacion.Date >= inicio.Date &&
                a.FechaAsignacion.Date <= fin.Date).ToList();

        private bool EsTrabajado(Acuerdo a, string rol) => rol switch
        {
            "Secretario"       => a.FechaPreautorizacion.HasValue,
            "Oficial Judicial" => a.FechaElaboracion.HasValue,
            _                  => a.FechaAutorizacion.HasValue
        };

        private double ObtenerTiempo(Acuerdo a, string rol) => rol switch
        {
            "Secretario"       => a.FechaPreautorizacion.HasValue && a.FechaElaboracion.HasValue
                ? (a.FechaPreautorizacion.Value - a.FechaElaboracion.Value).TotalMinutes : 0,
            "Oficial Judicial" => a.FechaElaboracion.HasValue
                ? (a.FechaElaboracion.Value - a.FechaAsignacion).TotalMinutes : 0,
            _                  => a.FechaAutorizacion.HasValue && a.FechaPreautorizacion.HasValue
                ? (a.FechaAutorizacion.Value - a.FechaPreautorizacion.Value).TotalMinutes : 0
        };

        private string ObtenerEtiqueta(string rol) => rol switch
        {
            "Secretario"       => "Preautorizaciones",
            "Oficial Judicial" => "Elaboraciones",
            _                  => "Autorizaciones"
        };
    }

    public class GraficaPuntosAcuerdoHelper
    {
        private readonly List<Acuerdo> _acuerdos;

        public GraficaPuntosAcuerdoHelper(List<Acuerdo> acuerdos) => _acuerdos = acuerdos;

        public GraficaPuntosAcuerdoDto Construir(
            ProductividadTramiteRequest request, string rol)
        {
            const int tamanioPagina = 40;
            var acuerdos = _acuerdos
                .Where(a => a.UsuarioId == request.UsuarioId &&
                            a.FechaAsignacion.Date >= request.FechaInicio.Date &&
                            a.FechaAsignacion.Date <= request.FechaFin.Date)
                .OrderBy(a => ObtenerHoraInicio(a, rol))
                .ToList();

            var totalPaginas = (int)Math.Ceiling((double)acuerdos.Count / tamanioPagina);
            var paginaActual = Math.Max(1, Math.Min(request.PaginaGrafica, totalPaginas));

            var puntos = acuerdos
                .Skip((paginaActual - 1) * tamanioPagina)
                .Take(tamanioPagina)
                .Select(a => new PuntoAcuerdoDto
                {
                    NumeroExpediente = a.NumeroExpediente,
                    TipoAsuntoCorto  = a.TipoAsuntoCorto,
                    HoraInicio       = ObtenerHoraInicio(a, rol)?.ToString("HH:mm") ?? string.Empty,
                    HoraFin          = ObtenerHoraFin(a, rol)?.ToString("HH:mm") ?? string.Empty
                }).ToList();

            return new GraficaPuntosAcuerdoDto
            {
                Puntos         = puntos,
                PaginaActual   = paginaActual,
                TotalPaginas   = totalPaginas,
                TotalRegistros = acuerdos.Count
            };
        }

        private DateTime? ObtenerHoraInicio(Acuerdo a, string rol) => rol switch
        {
            "Secretario"       => a.FechaElaboracion,
            "Oficial Judicial" => a.FechaAsignacion,
            _                  => a.FechaPreautorizacion
        };

        private DateTime? ObtenerHoraFin(Acuerdo a, string rol) => rol switch
        {
            "Secretario"       => a.FechaPreautorizacion,
            "Oficial Judicial" => a.FechaElaboracion,
            _                  => a.FechaAutorizacion
        };
    }

    public class BarrasApiladasAcuerdoHelper
    {
        private readonly List<Acuerdo> _acuerdos;

        public BarrasApiladasAcuerdoHelper(List<Acuerdo> acuerdos) => _acuerdos = acuerdos;

        public List<BarraAcuerdoDto> Agrupar(string usuarioId)
        {
            var hace12Meses  = DateTime.Today.AddMonths(-11);
            var inicioBarras = new DateTime(hace12Meses.Year, hace12Meses.Month, 1);

            return _acuerdos
                .Where(a => a.UsuarioId == usuarioId && a.FechaAsignacion >= inicioBarras)
                .GroupBy(a => new { Mes = a.FechaAsignacion.ToString("MM/yyyy"), a.TipoAsunto })
                .Select(g => new BarraAcuerdoDto
                {
                    Mes        = g.Key.Mes,
                    TipoAsunto = g.Key.TipoAsunto,
                    Cantidad   = g.Count()
                })
                .OrderBy(b => b.Mes)
                .ToList();
        }
    }

    // ── Modelos ───────────────────────────────────────────────────────────────

    public class ProductividadTramiteRequest
    {
        public string   UsuarioId     { get; set; } = string.Empty;
        public DateTime FechaInicio   { get; set; }
        public DateTime FechaFin      { get; set; }
        public int      PaginaGrafica { get; set; } = 1;
    }

    public class ContadoresRolDto
    {
        public string EtiquetaRol       { get; set; } = string.Empty;
        public string ContadorPeriodo   { get; set; } = string.Empty;
        public int    TotalAnio         { get; set; }
        public double PromedioXDia      { get; set; }
        public double TiempoPromedioMin { get; set; }
    }

    public class UsuarioTramite
    {
        public string Id             { get; set; } = string.Empty;
        public int    OrganoId       { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string TipoArea       { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
        public int    Orden          { get; set; }
    }

    public class Acuerdo
    {
        public int       Id                    { get; set; }
        public string    UsuarioId             { get; set; } = string.Empty;
        public string    NumeroExpediente      { get; set; } = string.Empty;
        public string    TipoAsunto            { get; set; } = string.Empty;
        public string    TipoAsuntoCorto       { get; set; } = string.Empty;
        public DateTime  FechaAsignacion       { get; set; }
        public DateTime? FechaElaboracion      { get; set; }
        public DateTime? FechaPreautorizacion  { get; set; }
        public DateTime? FechaAutorizacion     { get; set; }
    }

    public class PestanaTramiteDto
    {
        public string UsuarioId      { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string TipoArea       { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
    }

    public class DashboardTramiteDto
    {
        public PestanaTramiteDto       Usuario           { get; set; } = new();
        public string                  EtiquetaRol       { get; set; } = string.Empty;
        public string                  ContadorPeriodo   { get; set; } = string.Empty;
        public int                     TotalAnio         { get; set; }
        public double                  PromedioXDia      { get; set; }
        public double                  TiempoPromedioMin { get; set; }
        public GraficaPuntosAcuerdoDto GraficaPuntos     { get; set; } = new();
        public List<BarraAcuerdoDto>   GraficaBarras     { get; set; } = new();
    }

    public class GraficaPuntosAcuerdoDto
    {
        public List<PuntoAcuerdoDto> Puntos         { get; set; } = new();
        public int                   PaginaActual   { get; set; }
        public int                   TotalPaginas   { get; set; }
        public int                   TotalRegistros { get; set; }
    }

    public class PuntoAcuerdoDto
    {
        public string NumeroExpediente { get; set; } = string.Empty;
        public string TipoAsuntoCorto  { get; set; } = string.Empty;
        public string HoraInicio       { get; set; } = string.Empty;
        public string HoraFin          { get; set; } = string.Empty;
    }

    public class BarraAcuerdoDto
    {
        public string Mes        { get; set; } = string.Empty;
        public string TipoAsunto { get; set; } = string.Empty;
        public int    Cantidad   { get; set; }
    }

    public class ResultadoProductividadTramite
    {
        public bool                 Exito     { get; private set; }
        public string               Mensaje   { get; private set; } = string.Empty;
        public DashboardTramiteDto? Dashboard { get; private set; }

        public static ResultadoProductividadTramite Exitoso(DashboardTramiteDto d) =>
            new ResultadoProductividadTramite { Exito = true, Dashboard = d };

        public static ResultadoProductividadTramite Error(string mensaje) =>
            new ResultadoProductividadTramite { Exito = false, Mensaje = mensaje };
    }
}
