using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ObtenerAudienciasPreviasCJPF
{
    // CORRECCIÓN ERR-AUD-001: Estructura corregida
    // Se separan las responsabilidades en clases independientes:
    // - AudienciasPreviasCJPFService: consulta y filtrado
    // - MenuContextualService: lógica del menú por estado

    public class AudienciasPreviasCJPFService
    {
        private readonly List<AudienciaCJPF>  _audiencias;
        private readonly MenuContextualService _menuService;

        public AudienciasPreviasCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias  = audiencias;
            _menuService = new MenuContextualService();
        }

        public ResultadoAudienciasPrevias ObtenerAudiencias(
            string numeroExpediente, string filtroEstado)
        {
            var query = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente);

            if (!string.IsNullOrEmpty(filtroEstado) && filtroEstado != "Todas")
                query = query.Where(a => a.Estado == filtroEstado);

            var audiencias = query
                .OrderByDescending(a => a.FechaHoraInicio)
                .Select(a => new AudienciaPreviaDto
                {
                    Id                  = a.Id,
                    TipoAudiencia       = a.TipoAudiencia,
                    Imputado            = a.Imputado,
                    Juez                = a.JuezAsignado,
                    Forma               = a.FormatoAudiencia,
                    FechaHoraInicio     = a.FechaHoraInicio.ToString("dd/MM/yyyy HH:mm"),
                    FechaHoraFin        = a.FechaHoraFin.ToString("dd/MM/yyyy HH:mm"),
                    Capturo             = $"{a.AgendadoPor} - {a.FechaCaptura:dd/MM/yyyy}",
                    Estado              = a.Estado,
                    MostrarResoluciones = a.Estado == "Celebrada",
                    OpcionesMenu        = _menuService.ObtenerOpciones(a.Estado)
                }).ToList();

            return new ResultadoAudienciasPrevias
            {
                NumeroExpediente = numeroExpediente,
                Audiencias       = audiencias
            };
        }

        public List<string> ObtenerEstadosFiltro()
        {
            return new List<string>
            {
                "Todas", "Programada", "Diferida", "Cancelada", "Celebrada"
            };
        }
    }

    // CORRECCIÓN ERR-AUD-002: Clase independiente para el menú contextual
    public class MenuContextualService
    {
        public List<string> ObtenerOpciones(string estado)
        {
            return estado switch
            {
                "Programada" => new List<string> { "Movimientos", "Cambiar Juez", "Cancelar" },
                "Diferida"   => new List<string> { "Movimientos", "Reservar" },
                "Cancelada"  => new List<string> { "Ver Detalle" },
                "Celebrada"  => new List<string> { "Movimientos", "Resumen", "Continuar" },
                _            => new List<string>()
            };
        }
    }

    public class ResultadoAudienciasPrevias
    {
        public string                   NumeroExpediente { get; set; } = string.Empty;
        public List<AudienciaPreviaDto> Audiencias       { get; set; } = new();
    }

    public class AudienciaPreviaDto
    {
        public int          Id                  { get; set; }
        public string       TipoAudiencia       { get; set; } = string.Empty;
        public string       Imputado            { get; set; } = string.Empty;
        public string       Juez                { get; set; } = string.Empty;
        public string       Forma               { get; set; } = string.Empty;
        public string       FechaHoraInicio     { get; set; } = string.Empty;
        public string       FechaHoraFin        { get; set; } = string.Empty;
        public string       Capturo             { get; set; } = string.Empty;
        public string       Estado              { get; set; } = string.Empty;
        public bool         MostrarResoluciones { get; set; }
        public List<string> OpcionesMenu        { get; set; } = new();
    }

    public class AudienciaCJPF
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Imputado         { get; set; } = string.Empty;
        public string   JuezAsignado     { get; set; } = string.Empty;
        public string   FormatoAudiencia { get; set; } = string.Empty;
        public DateTime FechaHoraInicio  { get; set; }
        public DateTime FechaHoraFin     { get; set; }
        public string   AgendadoPor      { get; set; } = string.Empty;
        public DateTime FechaCaptura     { get; set; }
        public string   Estado           { get; set; } = string.Empty;
    }
}
