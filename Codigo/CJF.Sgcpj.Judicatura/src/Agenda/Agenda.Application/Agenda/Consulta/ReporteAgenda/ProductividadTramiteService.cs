using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.ProductividadTramite
{
    // ERROR ERR-TRAM-001: Estructura incorrecta
    // La lógica de contadores, gráfica de puntos, barras apiladas y cálculo
    // por rol (Secretario, Oficial Judicial, Titular) están todas mezcladas
    // en una sola clase sin separación de responsabilidades.
    // Debería separarse en:
    // - ProductividadTramiteService: orquesta la consulta
    // - ContadoresHelper: calcula contadores por rol
    // - GraficaPuntosHelper: construye y pagina la gráfica de puntos
    // - BarrasApiladasHelper: agrupa acuerdos por tipo y mes
    public class ProductividadTramiteService
    {
        private readonly List<UsuarioTramite> _usuarios;
        private readonly List<Acuerdo>        _acuerdos;

        public ProductividadTramiteService(
            List<UsuarioTramite> usuarios,
            List<Acuerdo>        acuerdos)
        {
            _usuarios = usuarios;
            _acuerdos = acuerdos;
        }

        public List<PestanaTramiteDto> ObtenerPestanas(int organoId)
        {
            return _usuarios
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
        }

        // Contadores, gráficas y cálculo de rol mezclados en un solo método
        public ResultadoProductividadTramite ObtenerProductividad(
            ProductividadTramiteRequest request)
        {
            var usuario = _usuarios.FirstOrDefault(u => u.Id == request.UsuarioId);
            if (usuario == null)
                return ResultadoProductividadTramite.Error("No se encontró el usuario");

            var inicioAnio = new DateTime(DateTime.Today.Year, 1, 1);
            var hoy        = DateTime.Today;

            // Lógica de rol mezclada con contadores
            var acuerdosPeriodo = ObtenerAcuerdosPorRol(
                request.UsuarioId, usuario.Rol,
                request.FechaInicio, request.FechaFin);

            var acuerdosAnio = ObtenerAcuerdosPorRol(
                request.UsuarioId, usuario.Rol, inicioAnio, hoy);

            var trabajadosPeriodo = acuerdosPeriodo.Count(a => EsTrabajado(a, usuario.Rol));
            var trabajadosAnio    = acuerdosAnio.Count(a => EsTrabajado(a, usuario.Rol));
            var diasAnio          = (hoy - inicioAnio).Days + 1;

            double promedioXDia = diasAnio > 0
                ? Math.Round((double)trabajadosAnio / diasAnio, 2) : 0;

            double tiempoPromedio = acuerdosAnio
                .Where(a => EsTrabajado(a, usuario.Rol))
                .Select(a => ObtenerTiempoTrabajo(a, usuario.Rol))
                .DefaultIfEmpty(0)
                .Average();

            // Gráfica de puntos mezclada con paginación
            const int tamanioPagina = 40;
            var ordenados    = acuerdosPeriodo.OrderBy(a => ObtenerHoraInicio(a, usuario.Rol)).ToList();
            var totalPaginas = (int)Math.Ceiling((double)ordenados.Count / tamanioPagina);
            var paginaActual = Math.Max(1, Math.Min(request.PaginaGrafica, totalPaginas));

            var puntos = ordenados
                .Skip((paginaActual - 1) * tamanioPagina)
                .Take(tamanioPagina)
                .Select(a => new PuntoAcuerdoDto
                {
                    NumeroExpediente = a.NumeroExpediente,
                    TipoAsuntoCorto  = a.TipoAsuntoCorto,
                    HoraInicio       = ObtenerHoraInicio(a, usuario.Rol)?.ToString("HH:mm") ?? string.Empty,
                    HoraFin          = ObtenerHoraFin(a, usuario.Rol)?.ToString("HH:mm") ?? string.Empty
                }).ToList();

            // Gráfica de barras apiladas mezclada
            var hace12Meses   = DateTime.Today.AddMonths(-11);
            var inicioBarras  = new DateTime(hace12Meses.Year, hace12Meses.Month, 1);
            var barrasApiladas = _acuerdos
                .Where(a => a.UsuarioId == request.UsuarioId && a.FechaAsignacion >= inicioBarras)
                .GroupBy(a => new { Mes = a.FechaAsignacion.ToString("MM/yyyy"), a.TipoAsunto })
                .Select(g => new BarraAcuerdoDto
                {
                    Mes        = g.Key.Mes,
                    TipoAsunto = g.Key.TipoAsunto,
                    Cantidad   = g.Count()
                })
                .OrderBy(b => b.Mes)
                .ToList();

            var etiquetaRol = ObtenerEtiquetaRol(usuario.Rol);

            return ResultadoProductividadTramite.Exitoso(new DashboardTramiteDto
            {
                Usuario          = new PestanaTramiteDto
                {
                    UsuarioId      = usuario.Id,
                    NombreCompleto = usuario.NombreCompleto,
                    NombreUsuario  = usuario.NombreUsuario,
                    Rol            = usuario.Rol,
                    TipoArea       = usuario.TipoArea,
                    Fotografia     = usuario.Fotografia
                },
                EtiquetaRol      = etiquetaRol,
                ContadorPeriodo  = $"{trabajadosPeriodo} de {acuerdosPeriodo.Count}",
                TotalAnio        = trabajadosAnio,
                PromedioXDia     = promedioXDia,
                TiempoPromedioMin = Math.Round(tiempoPromedio, 1),
                GraficaPuntos    = new GraficaPuntosAcuerdoDto
                {
                    Puntos         = puntos,
                    PaginaActual   = paginaActual,
                    TotalPaginas   = totalPaginas,
                    TotalRegistros = ordenados.Count
                },
                GraficaBarras    = barrasApiladas
            });
        }

        private List<Acuerdo> ObtenerAcuerdosPorRol(
            string usuarioId, string rol, DateTime inicio, DateTime fin)
        {
            return _acuerdos.Where(a =>
                a.UsuarioId == usuarioId &&
                a.FechaAsignacion.Date >= inicio.Date &&
                a.FechaAsignacion.Date <= fin.Date).ToList();
        }

        private bool EsTrabajado(Acuerdo a, string rol) => rol switch
        {
            "Secretario"      => a.FechaPreautorizacion.HasValue,
            "Oficial Judicial" => a.FechaElaboracion.HasValue,
            _                 => a.FechaAutorizacion.HasValue
        };

        private double ObtenerTiempoTrabajo(Acuerdo a, string rol) => rol switch
        {
            "Secretario"      => a.FechaPreautorizacion.HasValue
                ? (a.FechaPreautorizacion.Value - a.FechaElaboracion!.Value).TotalMinutes : 0,
            "Oficial Judicial" => a.FechaElaboracion.HasValue
                ? (a.FechaElaboracion.Value - a.FechaAsignacion).TotalMinutes : 0,
            _                 => a.FechaAutorizacion.HasValue && a.FechaPreautorizacion.HasValue
                ? (a.FechaAutorizacion.Value - a.FechaPreautorizacion.Value).TotalMinutes : 0
        };

        private DateTime? ObtenerHoraInicio(Acuerdo a, string rol) => rol switch
        {
            "Secretario"      => a.FechaElaboracion,
            "Oficial Judicial" => a.FechaAsignacion,
            _                 => a.FechaPreautorizacion
        };

        private DateTime? ObtenerHoraFin(Acuerdo a, string rol) => rol switch
        {
            "Secretario"      => a.FechaPreautorizacion,
            "Oficial Judicial" => a.FechaElaboracion,
            _                 => a.FechaAutorizacion
        };

        private string ObtenerEtiquetaRol(string rol) => rol switch
        {
            "Secretario"      => "Preautorizaciones",
            "Oficial Judicial" => "Elaboraciones",
            _                 => "Autorizaciones"
        };
    }

    public class ProductividadTramiteRequest
    {
        public string   UsuarioId    { get; set; } = string.Empty;
        public DateTime FechaInicio  { get; set; }
        public DateTime FechaFin     { get; set; }
        public int      PaginaGrafica { get; set; } = 1;
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
        public int      Id                  { get; set; }
        public string   UsuarioId           { get; set; } = string.Empty;
        public string   NumeroExpediente    { get; set; } = string.Empty;
        public string   TipoAsunto          { get; set; } = string.Empty;
        public string   TipoAsuntoCorto     { get; set; } = string.Empty;
        public DateTime FechaAsignacion     { get; set; }
        public DateTime? FechaElaboracion   { get; set; }
        public DateTime? FechaPreautorizacion { get; set; }
        public DateTime? FechaAutorizacion  { get; set; }
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
        public PestanaTramiteDto        Usuario           { get; set; } = new();
        public string                   EtiquetaRol       { get; set; } = string.Empty;
        public string                   ContadorPeriodo   { get; set; } = string.Empty;
        public int                      TotalAnio         { get; set; }
        public double                   PromedioXDia      { get; set; }
        public double                   TiempoPromedioMin { get; set; }
        public GraficaPuntosAcuerdoDto  GraficaPuntos     { get; set; } = new();
        public List<BarraAcuerdoDto>    GraficaBarras     { get; set; } = new();
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
        public bool                  Exito     { get; private set; }
        public string                Mensaje   { get; private set; } = string.Empty;
        public DashboardTramiteDto?  Dashboard { get; private set; }

        public static ResultadoProductividadTramite Exitoso(DashboardTramiteDto dashboard) =>
            new ResultadoProductividadTramite { Exito = true, Dashboard = dashboard };

        public static ResultadoProductividadTramite Error(string mensaje) =>
            new ResultadoProductividadTramite { Exito = false, Mensaje = mensaje };
    }
}
