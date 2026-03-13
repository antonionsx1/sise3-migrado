using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.ObtenerAgendaRecordatorios
{
    // CORRECCIÓN ERR-AGN-005: Estructura corregida
    // Se separan las responsabilidades en servicios y helpers independientes:
    // - ObtenerAgendaRecordatoriosService: orquesta la consulta
    // - AudienciaCalendarioHelper: lógica de audiencias
    // - RecordatorioCalendarioHelper: lógica de recordatorios

    public class ObtenerAgendaRecordatoriosService
    {
        private readonly AudienciaCalendarioHelper    _audienciaHelper;
        private readonly RecordatorioCalendarioHelper _recordatorioHelper;

        public ObtenerAgendaRecordatoriosService(
            List<Audiencia>    audiencias,
            List<Recordatorio> recordatorios)
        {
            _audienciaHelper    = new AudienciaCalendarioHelper(audiencias);
            _recordatorioHelper = new RecordatorioCalendarioHelper(recordatorios);
        }

        public CalendarioDto ObtenerCalendario(CalendarioRequest request)
        {
            var resultado = new CalendarioDto
            {
                ModoVisualizacion = request.ModoVisualizacion,
                FechaActual       = DateTime.Today
            };

            if (request.MostrarAudiencias)
                resultado.Audiencias = _audienciaHelper
                    .ObtenerAudiencias(request.FechaInicio, request.FechaFin, request.FiltroEstado);

            if (request.MostrarRecordatorios)
                resultado.Recordatorios = _recordatorioHelper
                    .ObtenerRecordatorios(request.FechaInicio, request.FechaFin);

            return resultado;
        }
    }

    public class AudienciaCalendarioHelper
    {
        private readonly List<Audiencia> _audiencias;

        public AudienciaCalendarioHelper(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public List<AudienciaCalendarioDto> ObtenerAudiencias(
            DateTime fechaInicio, DateTime fechaFin, string filtroEstado)
        {
            return _audiencias
                .Where(a => a.FechaHora.Date >= fechaInicio.Date
                         && a.FechaHora.Date <= fechaFin.Date)
                .Where(a => AplicarFiltroEstado(a, filtroEstado))
                .Where(a => !EsFinDeSemana(a.FechaHora))
                .Select(a => new AudienciaCalendarioDto
                {
                    Id                = a.Id,
                    NumeroExpediente  = a.NumeroExpediente,
                    TipoAsunto        = a.TipoAsunto,
                    TipoProcedimiento = a.TipoProcedimiento,
                    FechaHora         = a.FechaHora,
                    TipoAudiencia     = a.TipoAudiencia,
                    Secretario        = a.Secretario,
                    PartesInteresadas = a.PartesInteresadas,
                    PersonaQueAgenda  = a.PersonaQueAgenda,
                    Estado            = a.Estado,
                    Color             = ObtenerColorEstado(a.Estado)
                }).ToList();
        }

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

        private bool EsFinDeSemana(DateTime fecha) =>
            fecha.DayOfWeek == DayOfWeek.Saturday ||
            fecha.DayOfWeek == DayOfWeek.Sunday;

        private string ObtenerColorEstado(string estado) => estado switch
        {
            "Cancelada" => "rojo",
            "Diferida"  => "amarillo",
            "Celebrada" => "verde",
            _           => "azul"
        };
    }

    public class RecordatorioCalendarioHelper
    {
        private readonly List<Recordatorio> _recordatorios;

        public RecordatorioCalendarioHelper(List<Recordatorio> recordatorios)
        {
            _recordatorios = recordatorios;
        }

        public List<RecordatorioCalendarioDto> ObtenerRecordatorios(
            DateTime fechaInicio, DateTime fechaFin)
        {
            return _recordatorios
                .Where(r => r.Fecha.Date >= fechaInicio.Date
                         && r.Fecha.Date <= fechaFin.Date)
                .Where(r => !EsFinDeSemana(r.Fecha))
                .Select(r => new RecordatorioCalendarioDto
                {
                    Id               = r.Id,
                    NumeroExpediente = r.NumeroExpediente,
                    Fecha            = r.Fecha,
                    Descripcion      = r.Descripcion,
                    AsignadoA        = r.AsignadoA
                }).ToList();
        }

        private bool EsFinDeSemana(DateTime fecha) =>
            fecha.DayOfWeek == DayOfWeek.Saturday ||
            fecha.DayOfWeek == DayOfWeek.Sunday;
    }

    public class CalendarioRequest
    {
        public DateTime FechaInicio          { get; set; }
        public DateTime FechaFin             { get; set; }
        public bool     MostrarAudiencias    { get; set; } = true;
        public bool     MostrarRecordatorios { get; set; }
        public string   FiltroEstado         { get; set; } = "Todos";
        public string   ModoVisualizacion    { get; set; } = "Mes";
    }

    public class CalendarioDto
    {
        public List<AudienciaCalendarioDto>    Audiencias        { get; set; } = new();
        public List<RecordatorioCalendarioDto> Recordatorios     { get; set; } = new();
        public string                          ModoVisualizacion { get; set; } = string.Empty;
        public DateTime                        FechaActual       { get; set; }
    }

    public class AudienciaCalendarioDto
    {
        public int      Id                { get; set; }
        public string   NumeroExpediente  { get; set; } = string.Empty;
        public string   TipoAsunto        { get; set; } = string.Empty;
        public string   TipoProcedimiento { get; set; } = string.Empty;
        public DateTime FechaHora         { get; set; }
        public string   TipoAudiencia     { get; set; } = string.Empty;
        public string   Secretario        { get; set; } = string.Empty;
        public string   PartesInteresadas { get; set; } = string.Empty;
        public string   PersonaQueAgenda  { get; set; } = string.Empty;
        public string   Estado            { get; set; } = string.Empty;
        public string   Color             { get; set; } = string.Empty;
    }

    public class RecordatorioCalendarioDto
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public string   Descripcion      { get; set; } = string.Empty;
        public string   AsignadoA        { get; set; } = string.Empty;
    }

    public class Recordatorio
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public string   Descripcion      { get; set; } = string.Empty;
        public string   AsignadoA        { get; set; } = string.Empty;
    }
}
