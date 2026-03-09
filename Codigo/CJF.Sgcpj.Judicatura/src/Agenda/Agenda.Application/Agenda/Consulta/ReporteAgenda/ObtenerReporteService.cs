using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Reporte.Consulta.ObtenerReporte
{
    public class ObtenerReporteService
    {
        private readonly List<Audiencia> _audiencias;
        private readonly List<Recordatorio> _recordatorios;

        public ObtenerReporteService(List<Audiencia> audiencias, List<Recordatorio> recordatorios)
        {
            _audiencias    = audiencias;
            _recordatorios = recordatorios;
        }

        public ResultadoReporte ObtenerReporte(FiltroReporteRequest filtro)
        {
            var resultado = new ResultadoReporte();

            if (filtro.IncluirAudiencias)
                resultado.Audiencias = FiltrarAudiencias(filtro);

            if (filtro.IncluirRecordatorios)
                resultado.Recordatorios = FiltrarRecordatorios(filtro);

            return resultado;
        }

        private List<AudienciaReporteDto> FiltrarAudiencias(FiltroReporteRequest filtro)
        {
            var query = _audiencias.AsEnumerable();

            // CORRECCIÓN ERR-REP-001: Operador lógico corregido
            // Se usa && para que ambas condiciones se cumplan y el rango de fechas sea correcto
            if (filtro.FechaInicio.HasValue && filtro.FechaFin.HasValue)
            {
                query = query.Where(a =>
                    a.FechaHora.Date >= filtro.FechaInicio.Value.Date &&
                    a.FechaHora.Date <= filtro.FechaFin.Value.Date);
            }

            if (!string.IsNullOrEmpty(filtro.NumeroExpediente))
                query = query.Where(a => a.NumeroExpediente.Contains(filtro.NumeroExpediente));

            if (!string.IsNullOrEmpty(filtro.TextoBusqueda))
                query = query.Where(a =>
                    a.NumeroExpediente.Contains(filtro.TextoBusqueda) ||
                    a.TipoAudiencia.Contains(filtro.TextoBusqueda) ||
                    a.Secretario.Contains(filtro.TextoBusqueda));

            return query.Select(a => new AudienciaReporteDto
            {
                Expediente     = a.NumeroExpediente,
                Parte          = a.PartesInteresadas,
                FechaAudiencia = a.FechaHora.ToString("dd/MM/yyyy"),
                HoraAudiencia  = a.FechaHora.ToString("HH:mm"),
                TipoAudiencia  = a.TipoAudiencia,
                Resultado      = a.Estado,
                AgendadoPor    = a.PersonaQueAgenda,
                Secretario     = a.Secretario
            }).ToList();
        }

        private List<RecordatorioReporteDto> FiltrarRecordatorios(FiltroReporteRequest filtro)
        {
            var query = _recordatorios.AsEnumerable();

            if (!string.IsNullOrEmpty(filtro.NumeroExpediente))
                query = query.Where(r => r.NumeroExpediente.Contains(filtro.NumeroExpediente));

            if (filtro.SoloMisRecordatorios && !string.IsNullOrEmpty(filtro.UsuarioActual))
                query = query.Where(r => r.CapturedoPor == filtro.UsuarioActual);

            return query.Select(r => new RecordatorioReporteDto
            {
                Expediente   = r.NumeroExpediente,
                Fecha        = r.Fecha.ToString("dd/MM/yyyy"),
                Recordatorio = r.Descripcion,
                CapturedoPor = r.CapturedoPor,
                AsignadoA    = r.AsignadoA
            }).ToList();
        }
    }

    public class FiltroReporteRequest
    {
        public bool      IncluirAudiencias    { get; set; } = true;
        public bool      IncluirRecordatorios { get; set; } = true;
        public DateTime? FechaInicio          { get; set; }
        public DateTime? FechaFin             { get; set; }
        public string    NumeroExpediente     { get; set; } = string.Empty;
        public string    Persona              { get; set; } = string.Empty;
        public string    TextoBusqueda        { get; set; } = string.Empty;
        public bool      SoloMisRecordatorios { get; set; }
        public string    UsuarioActual        { get; set; } = string.Empty;
    }

    public class ResultadoReporte
    {
        public List<AudienciaReporteDto>    Audiencias    { get; set; } = new();
        public List<RecordatorioReporteDto> Recordatorios { get; set; } = new();
    }

    public class AudienciaReporteDto
    {
        public string Expediente     { get; set; } = string.Empty;
        public string Parte          { get; set; } = string.Empty;
        public string FechaAudiencia { get; set; } = string.Empty;
        public string HoraAudiencia  { get; set; } = string.Empty;
        public string TipoAudiencia  { get; set; } = string.Empty;
        public string Resultado      { get; set; } = string.Empty;
        public string AgendadoPor    { get; set; } = string.Empty;
        public string Secretario     { get; set; } = string.Empty;
    }

    public class RecordatorioReporteDto
    {
        public string Expediente   { get; set; } = string.Empty;
        public string Fecha        { get; set; } = string.Empty;
        public string Recordatorio { get; set; } = string.Empty;
        public string CapturedoPor { get; set; } = string.Empty;
        public string AsignadoA    { get; set; } = string.Empty;
    }

    public class Recordatorio
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public string   Descripcion      { get; set; } = string.Empty;
        public string   CapturedoPor     { get; set; } = string.Empty;
        public string   AsignadoA        { get; set; } = string.Empty;
    }
}
