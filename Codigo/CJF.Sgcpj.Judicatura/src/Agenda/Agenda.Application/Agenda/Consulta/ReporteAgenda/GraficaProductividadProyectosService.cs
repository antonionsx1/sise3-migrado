using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.GraficaProductividadProyectos
{
    public class GraficaProductividadProyectosService
    {
        private readonly List<SecretarioProyecto> _secretarios;
        private readonly List<Proyecto>           _proyectos;

        public GraficaProductividadProyectosService(
            List<SecretarioProyecto> secretarios,
            List<Proyecto>           proyectos)
        {
            _secretarios = secretarios;
            _proyectos   = proyectos;
        }

        public List<PestanaSecretarioDto> ObtenerPestanas(int organoId) =>
            _secretarios
                .Where(s => s.OrganoId == organoId)
                .Select(s => new PestanaSecretarioDto
                {
                    SecretarioId   = s.Id,
                    NombreCompleto = s.NombreCompleto,
                    NombreUsuario  = s.NombreUsuario,
                    Rol            = s.Rol,
                    Fotografia     = s.Fotografia
                }).ToList();

        public ResultadoProductividadProyectos ObtenerProductividad(
            ProductividadProyectosRequest request)
        {
            var secretario = _secretarios.FirstOrDefault(s => s.Id == request.SecretarioId);
            if (secretario == null)
                return ResultadoProductividadProyectos.Error(
                    "No se encontró el secretario indicado");

            var proyectosPeriodo = _proyectos
                .Where(p => p.SecretarioId == request.SecretarioId &&
                            p.FechaEntrega.HasValue &&
                            p.FechaEntrega.Value.Date >= request.FechaInicio.Date &&
                            p.FechaEntrega.Value.Date <= request.FechaFin.Date)
                .ToList();

            var contadores    = CalcularContadores(proyectosPeriodo, request);
            var graficaMeses  = ConstruirGraficaMeses(request.SecretarioId);
            var graficaSemana = ConstruirGraficaSemana(
                request.SecretarioId, request.MesDetalle ?? request.FechaInicio);

            return ResultadoProductividadProyectos.Exitoso(new DashboardProyectosDto
            {
                Secretario    = new PestanaSecretarioDto
                {
                    SecretarioId   = secretario.Id,
                    NombreCompleto = secretario.NombreCompleto,
                    NombreUsuario  = secretario.NombreUsuario,
                    Rol            = secretario.Rol,
                    Fotografia     = secretario.Fotografia
                },
                Contadores    = contadores,
                GraficaMeses  = graficaMeses,
                GraficaSemana = graficaSemana
            });
        }

        private ContadoresProyectosDto CalcularContadores(
            List<Proyecto> proyectos, ProductividadProyectosRequest request)
        {
            var diasPeriodo = (request.FechaFin - request.FechaInicio).Days + 1;
            var semanas     = Math.Max(1, diasPeriodo / 7);

            var aprobados       = proyectos.Count(p => p.Estatus == "Aprobado");
            var creados         = proyectos.Count;
            var porSemana       = semanas > 0 ? Math.Round((double)aprobados / semanas, 2) : 0;
            var efectividad     = proyectos.Any()
                ? Math.Round(proyectos.Average(p => p.VersionesPromedio), 2) : 0;

            return new ContadoresProyectosDto
            {
                ProyectosAprobados = aprobados,
                ProyectosPorSemana = porSemana,
                CreacionProyectos  = creados,
                Efectividad        = efectividad
            };
        }

        private List<BarraProyectoMesDto> ConstruirGraficaMeses(string secretarioId)
        {
            var hace12Meses  = DateTime.Today.AddMonths(-11);
            var inicioBarras = new DateTime(hace12Meses.Year, hace12Meses.Month, 1);

            return _proyectos
                .Where(p => p.SecretarioId == secretarioId &&
                            p.FechaEntrega.HasValue &&
                            p.FechaEntrega.Value >= inicioBarras &&
                            p.Estatus == "Aprobado")
                .GroupBy(p => p.FechaEntrega!.Value.ToString("MM/yyyy"))
                .Select(g => new BarraProyectoMesDto
                {
                    Mes      = g.Key,
                    Cantidad = g.Count()
                })
                .OrderBy(b => b.Mes)
                .ToList();
        }

        private List<BarraProyectoSemanaDto> ConstruirGraficaSemana(
            string secretarioId, DateTime mes)
        {
            var inicioMes = new DateTime(mes.Year, mes.Month, 1);
            var finMes    = inicioMes.AddMonths(1).AddDays(-1);

            return _proyectos
                .Where(p => p.SecretarioId == secretarioId &&
                            p.FechaEntrega.HasValue &&
                            p.FechaEntrega.Value.Date >= inicioMes &&
                            p.FechaEntrega.Value.Date <= finMes &&
                            p.Estatus == "Aprobado")
                .GroupBy(p => $"Sem {((p.FechaEntrega!.Value.Day - 1) / 7) + 1}")
                .Select(g => new BarraProyectoSemanaDto
                {
                    Semana   = g.Key,
                    Cantidad = g.Count()
                })
                .OrderBy(b => b.Semana)
                .ToList();
        }
    }

    public class ProductividadProyectosRequest
    {
        public string    SecretarioId { get; set; } = string.Empty;
        public DateTime  FechaInicio  { get; set; }
        public DateTime  FechaFin     { get; set; }
        public DateTime? MesDetalle   { get; set; }
    }

    public class SecretarioProyecto
    {
        public string Id             { get; set; } = string.Empty;
        public int    OrganoId       { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
    }

    public class Proyecto
    {
        public int      Id               { get; set; }
        public string   SecretarioId     { get; set; } = string.Empty;
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   Estatus          { get; set; } = string.Empty;
        public double   VersionesPromedio { get; set; }
        public DateTime FechaCreacion    { get; set; }
        public DateTime? FechaEntrega    { get; set; }
    }

    public class PestanaSecretarioDto
    {
        public string SecretarioId   { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
    }

    public class ContadoresProyectosDto
    {
        public int    ProyectosAprobados { get; set; }
        public double ProyectosPorSemana { get; set; }
        public int    CreacionProyectos  { get; set; }
        public double Efectividad        { get; set; }
    }

    public class BarraProyectoMesDto
    {
        public string Mes      { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class BarraProyectoSemanaDto
    {
        public string Semana   { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class DashboardProyectosDto
    {
        public PestanaSecretarioDto       Secretario    { get; set; } = new();
        public ContadoresProyectosDto     Contadores    { get; set; } = new();
        public List<BarraProyectoMesDto>  GraficaMeses  { get; set; } = new();
        public List<BarraProyectoSemanaDto> GraficaSemana { get; set; } = new();
    }

    public class ResultadoProductividadProyectos
    {
        public bool                   Exito     { get; private set; }
        public string                 Mensaje   { get; private set; } = string.Empty;
        public DashboardProyectosDto? Dashboard { get; private set; }

        public static ResultadoProductividadProyectos Exitoso(DashboardProyectosDto d) =>
            new ResultadoProductividadProyectos { Exito = true, Dashboard = d };

        public static ResultadoProductividadProyectos Error(string mensaje) =>
            new ResultadoProductividadProyectos { Exito = false, Mensaje = mensaje };
    }
}
