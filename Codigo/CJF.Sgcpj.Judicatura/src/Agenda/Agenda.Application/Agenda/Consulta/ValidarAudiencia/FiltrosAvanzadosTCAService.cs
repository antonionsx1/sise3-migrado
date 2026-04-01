using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.FiltrosAvanzadosTCA
{
    public class FiltrosAvanzadosTCAService
    {
        private readonly List<Audiencia> _audiencias;

        public FiltrosAvanzadosTCAService(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoFiltro AplicarFiltros(FiltroAvanzadoTCARequest filtro)
        {
            // ERROR ERR-FIL-001: Manejo de errores erróneo
            // No se valida que el rango de fechas sea correcto antes de filtrar
            // Si FechaFin < FechaInicio la consulta devuelve resultados vacíos
            // sin informar al usuario que el rango es inválido
            var query = _audiencias.AsEnumerable();

            if (filtro.FechaInicio.HasValue)
                query = query.Where(a => a.FechaHora.Date >= filtro.FechaInicio.Value.Date);

            if (filtro.FechaFin.HasValue)
                query = query.Where(a => a.FechaHora.Date <= filtro.FechaFin.Value.Date);

            if (!string.IsNullOrEmpty(filtro.Estado))
                query = query.Where(a => a.Estado == filtro.Estado);

            if (!string.IsNullOrEmpty(filtro.TipoAudiencia))
                query = query.Where(a => a.TipoAudiencia == filtro.TipoAudiencia);

            if (!string.IsNullOrEmpty(filtro.OrganoId))
                query = query.Where(a => a.OrganoId == filtro.OrganoId);

            var resultados = query.Select(a => new AudienciaTCAFiltradaDto
            {
                Id               = a.Id,
                NumeroExpediente = a.NumeroExpediente,
                TipoAudiencia    = a.TipoAudiencia,
                FechaHora        = a.FechaHora.ToString("dd/MM/yyyy HH:mm"),
                Estado           = a.Estado,
                OrganoId         = a.OrganoId
            }).ToList();

            if (!resultados.Any())
                return ResultadoFiltro.SinResultados();

            return ResultadoFiltro.Exitoso(resultados);
        }

        public FiltroAvanzadoTCARequest LimpiarFiltros() =>
            new FiltroAvanzadoTCARequest();
    }

    public class FiltroAvanzadoTCARequest
    {
        public DateTime? FechaInicio   { get; set; }
        public DateTime? FechaFin      { get; set; }
        public string    Estado        { get; set; } = string.Empty;
        public string    TipoAudiencia { get; set; } = string.Empty;
        public string    OrganoId      { get; set; } = string.Empty;
    }

    public class AudienciaTCAFiltradaDto
    {
        public int    Id               { get; set; }
        public string NumeroExpediente { get; set; } = string.Empty;
        public string TipoAudiencia    { get; set; } = string.Empty;
        public string FechaHora        { get; set; } = string.Empty;
        public string Estado           { get; set; } = string.Empty;
        public string OrganoId         { get; set; } = string.Empty;
    }

    public class ResultadoFiltro
    {
        public bool   Exito     { get; private set; }
        public string Mensaje   { get; private set; } = string.Empty;
        public List<AudienciaTCAFiltradaDto> Resultados { get; private set; } = new();

        public static ResultadoFiltro Exitoso(List<AudienciaTCAFiltradaDto> resultados) =>
            new ResultadoFiltro { Exito = true, Resultados = resultados };

        public static ResultadoFiltro SinResultados() =>
            new ResultadoFiltro { Exito = true, Mensaje = "No se encontraron coincidencias" };

        public static ResultadoFiltro Error(string mensaje) =>
            new ResultadoFiltro { Exito = false, Mensaje = mensaje };
    }
}
