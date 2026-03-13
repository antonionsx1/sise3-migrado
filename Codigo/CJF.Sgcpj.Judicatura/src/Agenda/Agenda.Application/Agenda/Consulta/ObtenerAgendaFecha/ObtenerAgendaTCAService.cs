using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.ObtenerAgendaTCA
{
    public class ObtenerAgendaTCAService
    {
        private readonly List<Audiencia> _audiencias;

        public ObtenerAgendaTCAService(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public AgendaTCADto ObtenerAgenda(AgendaTCARequest request)
        {
            var audienciasFiltradas = FiltrarAudiencias(request);

            return new AgendaTCADto
            {
                Audiencias        = audienciasFiltradas,
                ModoVisualizacion = request.ModoVisualizacion,
                FechaActual       = DateTime.Today
            };
        }

        private List<AudienciaTCADto> FiltrarAudiencias(AgendaTCARequest request)
        {
            var query = _audiencias.AsEnumerable();

            query = query.Where(a =>
                a.FechaHora.Date >= request.FechaInicio.Date &&
                a.FechaHora.Date <= request.FechaFin.Date);

            query = query.Where(a => EsDiaHabil(a.FechaHora));

            if (!string.IsNullOrEmpty(request.FiltroEstado))
                query = query.Where(a => AplicarFiltroEstado(a, request.FiltroEstado));

            return query.Select(a => new AudienciaTCADto
            {
                Id                = a.Id,
                NumeroExpediente  = a.NumeroExpediente,
                TipoAsunto        = a.TipoAsunto,
                FechaHora         = a.FechaHora,
                TipoAudiencia     = a.TipoAudiencia,
                Secretario        = a.Secretario,
                PartesInteresadas = a.PartesInteresadas,
                PersonaQueAgenda  = a.PersonaQueAgenda,
                Estado            = a.Estado,
                Color             = ObtenerColorEstado(a.Estado)
            }).ToList();
        }

        private bool EsDiaHabil(DateTime fecha) =>
            fecha.DayOfWeek != DayOfWeek.Saturday &&
            fecha.DayOfWeek != DayOfWeek.Sunday;

        private bool AplicarFiltroEstado(Audiencia audiencia, string filtroEstado) =>
            filtroEstado switch
            {
                "Programadas" => audiencia.Estado == "Programada",
                "Canceladas"  => audiencia.Estado == "Cancelada",
                "Diferidas"   => audiencia.Estado == "Diferida",
                "Celebradas"  => audiencia.Estado == "Celebrada",
                "Otros"       => audiencia.Estado == "Otros",
                _             => true
            };

        private string ObtenerColorEstado(string estado) => estado switch
        {
            "Cancelada" => "rojo",
            "Diferida"  => "amarillo",
            "Celebrada" => "verde",
            _           => "azul"
        };
    }

    public class AgendaTCARequest
    {
        public DateTime FechaInicio       { get; set; }
        public DateTime FechaFin          { get; set; }
        public string   ModoVisualizacion { get; set; } = "Mes";
        public string   FiltroEstado      { get; set; } = string.Empty;
    }

    public class AgendaTCADto
    {
        public List<AudienciaTCADto> Audiencias        { get; set; } = new();
        public string                ModoVisualizacion { get; set; } = string.Empty;
        public DateTime              FechaActual       { get; set; }
    }

    public class AudienciaTCADto
    {
        public int      Id                { get; set; }
        public string   NumeroExpediente  { get; set; } = string.Empty;
        public string   TipoAsunto        { get; set; } = string.Empty;
        public DateTime FechaHora         { get; set; }
        public string   TipoAudiencia     { get; set; } = string.Empty;
        public string   Secretario        { get; set; } = string.Empty;
        public string   PartesInteresadas { get; set; } = string.Empty;
        public string   PersonaQueAgenda  { get; set; } = string.Empty;
        public string   Estado            { get; set; } = string.Empty;
        public string   Color             { get; set; } = string.Empty;
    }
}
