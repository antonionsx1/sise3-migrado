using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Reporte.Consulta.ObtenerReporteTCA
{
    public class ObtenerReporteTCAService
    {
        private readonly List<Audiencia>    _audiencias;
        private readonly List<Recordatorio> _recordatorios;

        public ObtenerReporteTCAService(
            List<Audiencia>    audiencias,
            List<Recordatorio> recordatorios)
        {
            _audiencias    = audiencias;
            _recordatorios = recordatorios;
        }

        public ResultadoOperacion<ResultadoReporteTCA> ObtenerReporte(FiltroReporteTCARequest filtro)
        {
            // CORRECCIÓN ERR-TCA-005: Manejo de errores corregido
            // Se valida que al menos un checkbox esté activo antes de ejecutar la búsqueda
            if (!filtro.IncluirAudiencias && !filtro.IncluirRecordatorios)
                return ResultadoOperacion<ResultadoReporteTCA>.Error(
                    "ERR-TCA-005: Debe seleccionar al menos una opción: Audiencias o Recordatorios");

            var resultado = new ResultadoReporteTCA();

            if (filtro.IncluirAudiencias)
                resultado.Audiencias = FiltrarAudiencias(filtro);

            if (filtro.IncluirRecordatorios)
                resultado.Recordatorios = FiltrarRecordatorios(filtro);

            return ResultadoOperacion<ResultadoReporteTCA>.Exitoso(resultado);
        }

        private List<AudienciaReporteTCADto> FiltrarAudiencias(FiltroReporteTCARequest filtro)
        {
            var query = _audiencias.AsEnumerable();

            query = AplicarFiltroPeriodo(query, filtro);

            if (!string.IsNullOrEmpty(filtro.NumeroExpediente))
                query = query.Where(a => a.NumeroExpediente.Contains(filtro.NumeroExpediente));

            if (!string.IsNullOrEmpty(filtro.TextoBusqueda))
                query = query.Where(a =>
                    a.NumeroExpediente.Contains(filtro.TextoBusqueda) ||
                    a.TipoAudiencia.Contains(filtro.TextoBusqueda) ||
                    a.Secretario.Contains(filtro.TextoBusqueda));

            return query.Select(a => new AudienciaReporteTCADto
            {
                Expediente     = a.NumeroExpediente,
                Parte          = a.PartesInteresadas,
                FechaAudiencia = a.FechaHora.ToString("dd/MM/yyyy"),
                HoraAudiencia  = a.FechaHora.ToString("HH:mm"),
                Audiencia      = a.TipoAudiencia,
                Resultado      = a.Estado,
                AgendadoPor    = a.PersonaQueAgenda,
                Secretario     = a.Secretario,
                Color          = ObtenerColorEstado(a.Estado)
            }).ToList();
        }

        private List<RecordatorioReporteTCADto> FiltrarRecordatorios(FiltroReporteTCARequest filtro)
        {
            var query = _recordatorios.AsEnumerable();

            if (!string.IsNullOrEmpty(filtro.NumeroExpediente))
                query = query.Where(r => r.NumeroExpediente.Contains(filtro.NumeroExpediente));

            if (filtro.SoloMisRecordatorios && !string.IsNullOrEmpty(filtro.UsuarioActual))
                query = query.Where(r => r.CapturedoPor == filtro.UsuarioActual);

            return query.Select(r => new RecordatorioReporteTCADto
            {
                Expediente   = r.NumeroExpediente,
                Fecha        = r.Fecha.ToString("dd/MM/yyyy"),
                Recordatorio = r.Descripcion,
                CapturedoPor = r.CapturedoPor,
                AsignadoA    = r.AsignadoA
            }).ToList();
        }

        private IEnumerable<Audiencia> AplicarFiltroPeriodo(
            IEnumerable<Audiencia> query, FiltroReporteTCARequest filtro)
        {
            return filtro.FiltroPeriodo switch
            {
                "Ultimos3Dias"  => query.Where(a => a.FechaHora.Date >= DateTime.Today.AddDays(-3)),
                "Ultimos7Dias"  => query.Where(a => a.FechaHora.Date >= DateTime.Today.AddDays(-7)),
                "Ultimos30Dias" => query.Where(a => a.FechaHora.Date >= DateTime.Today.AddDays(-30)),
                "RangoFechas" when filtro.FechaInicio.HasValue && filtro.FechaFin.HasValue =>
                    query.Where(a => a.FechaHora.Date >= filtro.FechaInicio.Value.Date &&
                                     a.FechaHora.Date <= filtro.FechaFin.Value.Date),
                _ => query
            };
        }

        private string ObtenerColorEstado(string estado) => estado switch
        {
            "Cancelada" => "rojo",
            "Diferida"  => "amarillo",
            "Celebrada" => "verde",
            _           => "azul"
        };
    }

    public class ResultadoOperacion<T>
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;
        public T?     Datos   { get; private set; }

        public static ResultadoOperacion<T> Exitoso(T datos) =>
            new ResultadoOperacion<T> { Exito = true, Datos = datos };

        public static ResultadoOperacion<T> Error(string mensaje) =>
            new ResultadoOperacion<T> { Exito = false, Mensaje = mensaje };
    }

    public class FiltroReporteTCARequest
    {
        public bool      IncluirAudiencias    { get; set; } = true;
        public bool      IncluirRecordatorios { get; set; } = true;
        public string    FiltroPeriodo        { get; set; } = string.Empty;
        public DateTime? FechaInicio          { get; set; }
        public DateTime? FechaFin             { get; set; }
        public string    NumeroExpediente     { get; set; } = string.Empty;
        public string    Persona              { get; set; } = string.Empty;
        public string    TextoBusqueda        { get; set; } = string.Empty;
        public bool      SoloMisRecordatorios { get; set; }
        public string    UsuarioActual        { get; set; } = string.Empty;
    }

    public class ResultadoReporteTCA
    {
        public List<AudienciaReporteTCADto>    Audiencias    { get; set; } = new();
        public List<RecordatorioReporteTCADto> Recordatorios { get; set; } = new();
    }

    public class AudienciaReporteTCADto
    {
        public string Expediente     { get; set; } = string.Empty;
        public string Parte          { get; set; } = string.Empty;
        public string FechaAudiencia { get; set; } = string.Empty;
        public string HoraAudiencia  { get; set; } = string.Empty;
        public string Audiencia      { get; set; } = string.Empty;
        public string Resultado      { get; set; } = string.Empty;
        public string AgendadoPor    { get; set; } = string.Empty;
        public string Secretario     { get; set; } = string.Empty;
        public string Color          { get; set; } = string.Empty;
    }

    public class RecordatorioReporteTCADto
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
