using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.ObtenerAgendaRecordatorios
{
    // ERROR ERR-AGN-005: Estructura incorrecta
    // Toda la lógica de audiencias, recordatorios, filtros y visualización
    // está concentrada en una sola clase sin separación de responsabilidades.
    // Debería dividirse en servicios independientes por cada responsabilidad.
    public class ObtenerAgendaRecordatoriosService
    {
        private readonly List<Audiencia> _audiencias;
        private readonly List<Recordatorio> _recordatorios;

        public ObtenerAgendaRecordatoriosService(
            List<Audiencia> audiencias,
            List<Recordatorio> recordatorios)
        {
            _audiencias     = audiencias;
            _recordatorios  = recordatorios;
        }

        public CalendarioDto ObtenerCalendario(CalendarioRequest request)
        {
            var resultado = new CalendarioDto();

            if (request.MostrarAudiencias)
            {
                var audienciasFiltradas = _audiencias
                    .Where(a => a.FechaHora.Date >= request.FechaInicio.Date
                             && a.FechaHora.Date <= request.FechaFin.Date)
                    .Where(a => AplicarFiltroEstado(a, request.FiltroEstado))
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

                resultado.Audiencias = audienciasFiltradas;
            }

            if (request.MostrarRecordatorios)
            {
                var recordatoriosFiltrados = _recordatorios
                    .Where(r => r.Fecha.Date >= request.FechaInicio.Date
                             && r.Fecha.Date <= request.FechaFin.Date)
                    .Where(r => !EsFinDeSemana(r.Fecha))
                    .Select(r => new RecordatorioCalendarioDto
                    {
                        Id               = r.Id,
                        NumeroExpediente = r.NumeroExpediente,
                        Fecha            = r.Fecha,
                        Descripcion      = r.Descripcion,
                        AsignadoA        = r.AsignadoA
                    }).ToList();

                resultado.Recordatorios = recordatoriosFiltrados;
            }

            // Lógica de modos de visualización mezclada en el mismo método
            resultado.ModoVisualizacion = request.ModoVisualizacion;
            resultado.FechaActual       = DateTime.Today;

            return resultado;
        }

        // Métodos auxiliares mezclados en la misma clase sin separación
        private bool AplicarFiltroEstado(Audiencia audiencia, string filtroEstado)
        {
            return filtroEstado switch
            {
                "Programadas"  => audiencia.Estado == "Programada",
                "Canceladas"   => audiencia.Estado == "Cancelada",
                "Diferidas"    => audiencia.Estado == "Diferida",
                "Celebradas"   => audiencia.Estado == "Celebrada",
                "Otros"        => audiencia.Estado == "Otros",
                _              => true
            };
        }

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

    public class CalendarioRequest
    {
        public DateTime FechaInicio        { get; set; }
        public DateTime FechaFin           { get; set; }
        public bool     MostrarAudiencias  { get; set; } = true;
        public bool     MostrarRecordatorios { get; set; }
        public string   FiltroEstado       { get; set; } = "Todos";
        public string   ModoVisualizacion  { get; set; } = "Mes";
    }

    public class CalendarioDto
    {
        public List<AudienciaCalendarioDto>    Audiencias      { get; set; } = new();
        public List<RecordatorioCalendarioDto> Recordatorios   { get; set; } = new();
        public string                          ModoVisualizacion { get; set; } = string.Empty;
        public DateTime                        FechaActual     { get; set; }
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
