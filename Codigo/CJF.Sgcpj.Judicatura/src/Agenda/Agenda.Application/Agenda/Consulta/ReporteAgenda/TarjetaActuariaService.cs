using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.TarjetaActuaria
{
    public class TarjetaActuariaService
    {
        private readonly List<Notificacion> _notificaciones;

        public TarjetaActuariaService(List<Notificacion> notificaciones)
        {
            _notificaciones = notificaciones;
        }

        public ResultadoTarjetaActuaria ObtenerTarjeta(TarjetaActuariaRequest request)
        {
            var notifPeriodo = _notificaciones
                .Where(n => n.FechaAsignacion.Date >= request.FechaInicio.Date &&
                            n.FechaAsignacion.Date <= request.FechaFin.Date)
                .ToList();

            var graficaAnillo    = ConstruirGraficaAnillo(notifPeriodo);
            var graficaPendientes = ConstruirGraficaPendientes(notifPeriodo);
            var graficaNotificadas = ConstruirGraficaNotificadas(notifPeriodo);

            return ResultadoTarjetaActuaria.Exitoso(new DashboardActuariaDto
            {
                GraficaAnillo     = graficaAnillo,
                GraficaPendientes = graficaPendientes,
                GraficaNotificadas = graficaNotificadas
            });
        }

        public ResultadoTarjetaActuaria Restaurar(TarjetaActuariaRequest request) =>
            ObtenerTarjeta(request);

        public FiltrosModuloDto ObtenerFiltrosPorTemporalidad(
            string temporalidad, DateTime fechaInicio, DateTime fechaFin) =>
            new FiltrosModuloDto
            {
                FechaInicio   = fechaInicio,
                FechaFin      = fechaFin,
                Temporalidad  = temporalidad,
                MedioNotificacion = string.Empty
            };

        public FiltrosModuloDto ObtenerFiltrosPorMedio(
            string medioNotificacion, DateTime fechaInicio, DateTime fechaFin) =>
            new FiltrosModuloDto
            {
                FechaInicio       = fechaInicio,
                FechaFin          = fechaFin,
                Temporalidad      = string.Empty,
                MedioNotificacion = medioNotificacion
            };

        private GraficaAnilloDto ConstruirGraficaAnillo(List<Notificacion> notificaciones)
        {
            var pendientes  = notificaciones.Count(n => !n.FechaNotificacion.HasValue);
            var notificadas = notificaciones.Count(n => n.FechaNotificacion.HasValue);

            return new GraficaAnilloDto
            {
                Segmentos = new List<SegmentoAnilloDto>
                {
                    new SegmentoAnilloDto { Estatus = "Pendientes",  Cantidad = pendientes },
                    new SegmentoAnilloDto { Estatus = "Notificadas", Cantidad = notificadas }
                },
                Total = notificaciones.Count
            };
        }

        private List<BarraTemporalidadDto> ConstruirGraficaPendientes(
            List<Notificacion> notificaciones)
        {
            var hoy       = DateTime.Today;
            var pendientes = notificaciones.Where(n => !n.FechaNotificacion.HasValue).ToList();

            return pendientes
                .GroupBy(n =>
                {
                    var dias = (hoy - n.FechaAsignacion.Date).Days;
                    return dias > 3 ? "+3 días" : dias == 2 ? "2 días" : "1 día";
                })
                .Select(g => new BarraTemporalidadDto
                {
                    Temporalidad = g.Key,
                    Cantidad     = g.Count()
                })
                .OrderByDescending(b => b.Temporalidad)
                .ToList();
        }

        private List<BarraMedioDto> ConstruirGraficaNotificadas(
            List<Notificacion> notificaciones)
        {
            return notificaciones
                .Where(n => n.FechaNotificacion.HasValue)
                .GroupBy(n => n.MedioNotificacion)
                .Select(g => new BarraMedioDto
                {
                    MedioNotificacion = g.Key,
                    Cantidad          = g.Count()
                })
                .OrderByDescending(b => b.Cantidad)
                .ToList();
        }
    }

    public class TarjetaActuariaRequest
    {
        public DateTime FechaInicio { get; set; }
        public DateTime FechaFin    { get; set; }
    }

    public class Notificacion
    {
        public int       Id                { get; set; }
        public string    UsuarioId         { get; set; } = string.Empty;
        public string    NumeroExpediente  { get; set; } = string.Empty;
        public string    MedioNotificacion { get; set; } = string.Empty;
        public DateTime  FechaAsignacion   { get; set; }
        public DateTime? FechaNotificacion { get; set; }
    }

    public class GraficaAnilloDto
    {
        public List<SegmentoAnilloDto> Segmentos { get; set; } = new();
        public int                     Total     { get; set; }
    }

    public class SegmentoAnilloDto
    {
        public string Estatus  { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class BarraTemporalidadDto
    {
        public string Temporalidad { get; set; } = string.Empty;
        public int    Cantidad     { get; set; }
    }

    public class BarraMedioDto
    {
        public string MedioNotificacion { get; set; } = string.Empty;
        public int    Cantidad          { get; set; }
    }

    public class DashboardActuariaDto
    {
        public GraficaAnilloDto          GraficaAnillo      { get; set; } = new();
        public List<BarraTemporalidadDto> GraficaPendientes  { get; set; } = new();
        public List<BarraMedioDto>        GraficaNotificadas { get; set; } = new();
    }

    public class FiltrosModuloDto
    {
        public DateTime FechaInicio        { get; set; }
        public DateTime FechaFin           { get; set; }
        public string   Temporalidad       { get; set; } = string.Empty;
        public string   MedioNotificacion  { get; set; } = string.Empty;
    }

    public class ResultadoTarjetaActuaria
    {
        public bool                Exito     { get; private set; }
        public string              Mensaje   { get; private set; } = string.Empty;
        public DashboardActuariaDto? Dashboard { get; private set; }

        public static ResultadoTarjetaActuaria Exitoso(DashboardActuariaDto dashboard) =>
            new ResultadoTarjetaActuaria { Exito = true, Dashboard = dashboard };

        public static ResultadoTarjetaActuaria Error(string mensaje) =>
            new ResultadoTarjetaActuaria { Exito = false, Mensaje = mensaje };
    }
}
