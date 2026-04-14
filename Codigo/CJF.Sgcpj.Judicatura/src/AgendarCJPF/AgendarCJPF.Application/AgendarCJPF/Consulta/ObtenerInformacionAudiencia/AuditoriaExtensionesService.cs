using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.AuditoriaExtensiones
{
    public class AuditoriaExtensionesService
    {
        private readonly List<RegistroExtension> _registros;
        private readonly List<EvidenciaExtension> _evidencias;

        public AuditoriaExtensionesService(
            List<RegistroExtension>  registros,
            List<EvidenciaExtension> evidencias)
        {
            _registros  = registros;
            _evidencias = evidencias;
        }

        public ResultadoAuditoria ConsultarExtensiones(FiltroAuditoriaRequest filtro)
        {
            // ERROR ERR-AUD-003: Manejo de errores erróneo
            // No se valida que el rango de fechas sea correcto
            // Si FechaFin < FechaInicio, la consulta retorna vacío sin avisar al usuario
            var query = _registros.AsEnumerable();

            if (filtro.FechaInicio.HasValue)
                query = query.Where(r => r.FechaExtension.Date >= filtro.FechaInicio.Value.Date);

            if (filtro.FechaFin.HasValue)
                query = query.Where(r => r.FechaExtension.Date <= filtro.FechaFin.Value.Date);

            if (!string.IsNullOrEmpty(filtro.OrganoId))
                query = query.Where(r => r.OrganoId == filtro.OrganoId);

            var resultados = query.Select(r => new ExtensionAuditoriaDto
            {
                Id                = r.Id,
                AudienciaId       = r.AudienciaId,
                NumeroExpediente  = r.NumeroExpediente,
                OrganoId          = r.OrganoId,
                MotivoExtension   = r.MotivoExtension,
                FechaExtension    = r.FechaExtension.ToString("dd/MM/yyyy HH:mm"),
                AutorizadoPor     = r.AutorizadoPor,
                TieneEvidencia    = _evidencias.Any(e => e.RegistroId == r.Id),
                IncidenciaFaltaEvidencia = !_evidencias.Any(e => e.RegistroId == r.Id)
            }).ToList();

            if (!resultados.Any())
                return ResultadoAuditoria.SinResultados();

            return ResultadoAuditoria.Exitoso(resultados);
        }

        public EvidenciaExtension? ObtenerEvidencia(int registroId) =>
            _evidencias.FirstOrDefault(e => e.RegistroId == registroId);
    }

    public class FiltroAuditoriaRequest
    {
        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin    { get; set; }
        public string    OrganoId    { get; set; } = string.Empty;
    }

    public class RegistroExtension
    {
        public int      Id               { get; set; }
        public int      AudienciaId      { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   OrganoId         { get; set; } = string.Empty;
        public string   MotivoExtension  { get; set; } = string.Empty;
        public DateTime FechaExtension   { get; set; }
        public string   AutorizadoPor    { get; set; } = string.Empty;
    }

    public class EvidenciaExtension
    {
        public int    Id          { get; set; }
        public int    RegistroId  { get; set; }
        public string Descripcion { get; set; } = string.Empty;
        public string Archivo     { get; set; } = string.Empty;
    }

    public class ExtensionAuditoriaDto
    {
        public int    Id                       { get; set; }
        public int    AudienciaId             { get; set; }
        public string NumeroExpediente        { get; set; } = string.Empty;
        public string OrganoId                { get; set; } = string.Empty;
        public string MotivoExtension         { get; set; } = string.Empty;
        public string FechaExtension          { get; set; } = string.Empty;
        public string AutorizadoPor           { get; set; } = string.Empty;
        public bool   TieneEvidencia          { get; set; }
        public bool   IncidenciaFaltaEvidencia { get; set; }
    }

    public class ResultadoAuditoria
    {
        public bool   Exito     { get; private set; }
        public string Mensaje   { get; private set; } = string.Empty;
        public List<ExtensionAuditoriaDto> Extensiones { get; private set; } = new();

        public static ResultadoAuditoria Exitoso(List<ExtensionAuditoriaDto> extensiones) =>
            new ResultadoAuditoria { Exito = true, Extensiones = extensiones };

        public static ResultadoAuditoria SinResultados() =>
            new ResultadoAuditoria
            {
                Exito   = true,
                Mensaje = "No se encontraron extensiones para el periodo indicado"
            };

        public static ResultadoAuditoria Error(string mensaje) =>
            new ResultadoAuditoria { Exito = false, Mensaje = mensaje };
    }
}
