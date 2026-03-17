using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ObtenerAgendaCJPF
{
    public class ObtenerAgendaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public ObtenerAgendaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public AgendaCJPFDto ObtenerAgenda(AgendaCJPFRequest request)
        {
            var audienciasFiltradas = FiltrarAudiencias(request);

            return new AgendaCJPFDto
            {
                Audiencias        = audienciasFiltradas,
                ModoVisualizacion = request.ModoVisualizacion,
                FechaActual       = DateTime.Today
            };
        }

        private List<AudienciaCJPFDetalleDto> FiltrarAudiencias(AgendaCJPFRequest request)
        {
            var query = _audiencias.AsEnumerable();

            query = query.Where(a =>
                a.FechaHoraInicio.Date >= request.FechaInicio.Date &&
                a.FechaHoraInicio.Date <= request.FechaFin.Date);

            if (!string.IsNullOrEmpty(request.TipoAudiencia))
                query = query.Where(a => a.TipoAudiencia == request.TipoAudiencia);

            if (!string.IsNullOrEmpty(request.Sala))
                query = query.Where(a => a.Sala == request.Sala);

            if (!string.IsNullOrEmpty(request.FiltroEstado) &&
                request.FiltroEstado != "VerTodo")
                query = query.Where(a => a.Estado == request.FiltroEstado);

            return query.Select(a => new AudienciaCJPFDetalleDto
            {
                Id                = a.Id,
                NumeroSala        = a.Sala,
                NumeroExpediente  = a.NumeroExpediente,
                TipoAsunto        = a.TipoAsunto,
                TipoProcedimiento = a.TipoProcedimiento,
                NumeroAudiencia   = a.NumeroAudiencia,
                IdentificadorSistema = a.IdentificadorSistema,
                HoraInicio        = a.FechaHoraInicio.ToString("HH:mm"),
                HoraFin           = a.FechaHoraFin.ToString("HH:mm"),
                Estado            = a.Estado,
                Color             = ObtenerColorEstado(a.Estado)
            }).ToList();
        }

        private string ObtenerColorEstado(string estado) => estado switch
        {
            "Cancelada" => "rojo",
            "Diferida"  => "amarillo",
            "Activa"    => "verde",
            _           => "azul"
        };
    }

    public class AgendaCJPFRequest
    {
        public DateTime FechaInicio       { get; set; }
        public DateTime FechaFin          { get; set; }
        public string   ModoVisualizacion { get; set; } = "Mes";
        public string   FiltroEstado      { get; set; } = "VerTodo";
        public string   TipoAudiencia     { get; set; } = string.Empty;
        public string   Sala              { get; set; } = string.Empty;
        public bool     MostrarAudiencias { get; set; } = true;
    }

    public class AgendaCJPFDto
    {
        public List<AudienciaCJPFDetalleDto> Audiencias        { get; set; } = new();
        public string                         ModoVisualizacion { get; set; } = string.Empty;
        public DateTime                       FechaActual       { get; set; }
    }

    public class AudienciaCJPFDetalleDto
    {
        public int    Id                   { get; set; }
        public string NumeroSala           { get; set; } = string.Empty;
        public string NumeroExpediente     { get; set; } = string.Empty;
        public string TipoAsunto          { get; set; } = string.Empty;
        public string TipoProcedimiento   { get; set; } = string.Empty;
        public int    NumeroAudiencia      { get; set; }
        public string IdentificadorSistema { get; set; } = string.Empty;
        public string HoraInicio           { get; set; } = string.Empty;
        public string HoraFin             { get; set; } = string.Empty;
        public string Estado              { get; set; } = string.Empty;
        public string Color               { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int      Id                   { get; set; }
        public string   NumeroExpediente     { get; set; } = string.Empty;
        public string   TipoAsunto          { get; set; } = string.Empty;
        public string   TipoProcedimiento   { get; set; } = string.Empty;
        public string   TipoAudiencia       { get; set; } = string.Empty;
        public int      NumeroAudiencia      { get; set; }
        public string   IdentificadorSistema { get; set; } = string.Empty;
        public string   Sala                { get; set; } = string.Empty;
        public DateTime FechaHoraInicio      { get; set; }
        public DateTime FechaHoraFin        { get; set; }
        public string   Estado              { get; set; } = string.Empty;
        public string   TipoProcedimiento2  { get; set; } = string.Empty;
    }
}
