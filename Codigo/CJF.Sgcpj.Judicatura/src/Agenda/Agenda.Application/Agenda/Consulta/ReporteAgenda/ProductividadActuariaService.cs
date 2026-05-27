using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.ProductividadActuaria
{
    public class ProductividadActuariaService
    {
        private readonly List<UsuarioActuaria> _usuarios;
        private readonly List<Notificacion>    _notificaciones;

        public ProductividadActuariaService(
            List<UsuarioActuaria> usuarios,
            List<Notificacion>    notificaciones)
        {
            _usuarios       = usuarios;
            _notificaciones = notificaciones;
        }

        public List<PestanaActuariaDto> ObtenerPestanas(int organoId) =>
            _usuarios
                .Where(u => u.OrganoId == organoId)
                .OrderBy(u => u.Orden)
                .Select(u => new PestanaActuariaDto
                {
                    UsuarioId      = u.Id,
                    NombreCompleto = u.NombreCompleto,
                    NombreUsuario  = u.NombreUsuario,
                    Rol            = u.Rol,
                    Fotografia     = u.Fotografia
                }).ToList();

        public ResultadoActuaria ObtenerProductividad(ActuariaRequest request)
        {
            var usuario = _usuarios.FirstOrDefault(u => u.Id == request.UsuarioId);
            if (usuario == null)
                return ResultadoActuaria.Error("No se encontró el usuario indicado");

            var inicioAnio = new DateTime(DateTime.Today.Year, 1, 1);
            var hoy        = DateTime.Today;

            var notifPeriodo = _notificaciones
                .Where(n => n.UsuarioId == request.UsuarioId &&
                            n.FechaAsignacion.Date >= request.FechaInicio.Date &&
                            n.FechaAsignacion.Date <= request.FechaFin.Date)
                .ToList();

            var notifAnio = _notificaciones
                .Where(n => n.UsuarioId == request.UsuarioId &&
                            n.FechaAsignacion.Date >= inicioAnio &&
                            n.FechaAsignacion.Date <= hoy)
                .ToList();

            var realizadasPeriodo = notifPeriodo.Count(n => n.FechaNotificacion.HasValue);
            var realizadasAnio    = notifAnio.Count(n => n.FechaNotificacion.HasValue);

            var desglose = notifAnio
                .Where(n => n.FechaNotificacion.HasValue)
                .GroupBy(n => n.MedioNotificacion)
                .Select(g => new DesgloseMedioDto
                {
                    Medio    = g.Key,
                    Cantidad = g.Count()
                }).ToList();

            var graficaPuntos = ConstruirGraficaPuntos(notifPeriodo, request.PaginaGrafica);

            // CORRECCIÓN ERR-ACT-001: Comentario corregido
            // La gráfica por mes muestra los últimos 6 meses (no 12) según la HU
            // Gráfica de barras apiladas por mes - últimos 6 meses
            var hace6Meses   = DateTime.Today.AddMonths(-5);
            var inicioBarras = new DateTime(hace6Meses.Year, hace6Meses.Month, 1);

            var graficaBarrasMes = _notificaciones
                .Where(n => n.UsuarioId == request.UsuarioId &&
                            n.FechaAsignacion >= inicioBarras &&
                            n.FechaNotificacion.HasValue)
                .GroupBy(n => new
                {
                    Mes  = n.FechaAsignacion.ToString("MM/yyyy"),
                    Tipo = n.TipoNotificacion
                })
                .Select(g => new BarraNotificacionDto
                {
                    Periodo  = g.Key.Mes,
                    Tipo     = g.Key.Tipo,
                    Cantidad = g.Count()
                })
                .OrderBy(b => b.Periodo)
                .ToList();

            var mesGrafica      = request.MesGraficaBarras ?? DateTime.Today;
            var graficaBarrasSemana = ConstruirBarrasSemana(request.UsuarioId, mesGrafica);

            return ResultadoActuaria.Exitoso(new DashboardActuariaDto
            {
                Usuario = new PestanaActuariaDto
                {
                    UsuarioId      = usuario.Id,
                    NombreCompleto = usuario.NombreCompleto,
                    NombreUsuario  = usuario.NombreUsuario,
                    Rol            = usuario.Rol,
                    Fotografia     = usuario.Fotografia
                },
                ContadorPeriodo     = $"{realizadasPeriodo} de {notifPeriodo.Count}",
                TotalAnio           = realizadasAnio,
                DesgloseMedios      = desglose,
                GraficaPuntos       = graficaPuntos,
                GraficaBarrasMes    = graficaBarrasMes,
                GraficaBarrasSemana = graficaBarrasSemana
            });
        }

        private GraficaPuntosNotifDto ConstruirGraficaPuntos(
            List<Notificacion> notificaciones, int pagina)
        {
            const int tamanioPagina = 40;
            var ordenadas    = notificaciones.OrderBy(n => n.FechaAsignacion).ToList();
            var totalPaginas = (int)Math.Ceiling((double)ordenadas.Count / tamanioPagina);
            var paginaActual = Math.Max(1, Math.Min(pagina, totalPaginas));

            var puntos = ordenadas
                .Skip((paginaActual - 1) * tamanioPagina)
                .Take(tamanioPagina)
                .Select(n => new PuntoNotifDto
                {
                    NumeroExpediente = n.NumeroExpediente,
                    TipoAsuntoCorto  = n.TipoAsuntoCorto,
                    HoraAsignacion   = n.FechaAsignacion.ToString("HH:mm"),
                    HoraNotificacion = n.FechaNotificacion?.ToString("HH:mm") ?? string.Empty
                }).ToList();

            return new GraficaPuntosNotifDto
            {
                Puntos         = puntos,
                PaginaActual   = paginaActual,
                TotalPaginas   = totalPaginas,
                TotalRegistros = ordenadas.Count
            };
        }

        private List<BarraNotificacionDto> ConstruirBarrasSemana(
            string usuarioId, DateTime mes)
        {
            var inicioMes = new DateTime(mes.Year, mes.Month, 1);
            var finMes    = inicioMes.AddMonths(1).AddDays(-1);

            return _notificaciones
                .Where(n => n.UsuarioId == usuarioId &&
                            n.FechaAsignacion.Date >= inicioMes &&
                            n.FechaAsignacion.Date <= finMes &&
                            n.FechaNotificacion.HasValue)
                .GroupBy(n => new
                {
                    Semana = $"Sem {((n.FechaAsignacion.Day - 1) / 7) + 1}",
                    Tipo   = n.TipoNotificacion
                })
                .Select(g => new BarraNotificacionDto
                {
                    Periodo  = g.Key.Semana,
                    Tipo     = g.Key.Tipo,
                    Cantidad = g.Count()
                })
                .OrderBy(b => b.Periodo)
                .ToList();
        }
    }

    public class ActuariaRequest
    {
        public string    UsuarioId        { get; set; } = string.Empty;
        public DateTime  FechaInicio      { get; set; }
        public DateTime  FechaFin         { get; set; }
        public int       PaginaGrafica    { get; set; } = 1;
        public DateTime? MesGraficaBarras { get; set; }
    }

    public class UsuarioActuaria
    {
        public string Id             { get; set; } = string.Empty;
        public int    OrganoId       { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
        public int    Orden          { get; set; }
    }

    public class Notificacion
    {
        public int       Id                { get; set; }
        public string    UsuarioId         { get; set; } = string.Empty;
        public string    NumeroExpediente  { get; set; } = string.Empty;
        public string    TipoAsuntoCorto   { get; set; } = string.Empty;
        public string    TipoNotificacion  { get; set; } = string.Empty;
        public string    MedioNotificacion { get; set; } = string.Empty;
        public DateTime  FechaAsignacion   { get; set; }
        public DateTime? FechaNotificacion { get; set; }
    }

    public class PestanaActuariaDto
    {
        public string UsuarioId      { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
    }

    public class DesgloseMedioDto
    {
        public string Medio    { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class GraficaPuntosNotifDto
    {
        public List<PuntoNotifDto> Puntos         { get; set; } = new();
        public int                 PaginaActual   { get; set; }
        public int                 TotalPaginas   { get; set; }
        public int                 TotalRegistros { get; set; }
    }

    public class PuntoNotifDto
    {
        public string NumeroExpediente { get; set; } = string.Empty;
        public string TipoAsuntoCorto  { get; set; } = string.Empty;
        public string HoraAsignacion   { get; set; } = string.Empty;
        public string HoraNotificacion { get; set; } = string.Empty;
    }

    public class BarraNotificacionDto
    {
        public string Periodo  { get; set; } = string.Empty;
        public string Tipo     { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class DashboardActuariaDto
    {
        public PestanaActuariaDto         Usuario             { get; set; } = new();
        public string                     ContadorPeriodo     { get; set; } = string.Empty;
        public int                        TotalAnio           { get; set; }
        public List<DesgloseMedioDto>     DesgloseMedios      { get; set; } = new();
        public GraficaPuntosNotifDto      GraficaPuntos       { get; set; } = new();
        public List<BarraNotificacionDto> GraficaBarrasMes    { get; set; } = new();
        public List<BarraNotificacionDto> GraficaBarrasSemana { get; set; } = new();
    }

    public class ResultadoActuaria
    {
        public bool                  Exito     { get; private set; }
        public string                Mensaje   { get; private set; } = string.Empty;
        public DashboardActuariaDto? Dashboard { get; private set; }

        public static ResultadoActuaria Exitoso(DashboardActuariaDto dashboard) =>
            new ResultadoActuaria { Exito = true, Dashboard = dashboard };

        public static ResultadoActuaria Error(string mensaje) =>
            new ResultadoActuaria { Exito = false, Mensaje = mensaje };
    }
}
