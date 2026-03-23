using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ObtenerDetalleAudienciaCJPF
{
    public class ObtenerDetalleAudienciaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public ObtenerDetalleAudienciaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion<DetalleAudienciaCJPFDto> ObtenerDetalle(int audienciaId)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null)
                return ResultadoOperacion<DetalleAudienciaCJPFDto>.Error(
                    "No se encontró la audiencia indicada");

            var detalle = new DetalleAudienciaCJPFDto
            {
                NumeroExpediente     = audiencia.NumeroExpediente,
                TipoAsunto           = audiencia.TipoAsunto,
                TipoAudiencia        = audiencia.TipoAudiencia,
                Estado               = audiencia.Estado,
                FechaInicio          = audiencia.FechaHoraInicio.ToString("dd/MM/yyyy"),
                FechaFin             = audiencia.FechaHoraFin.ToString("dd/MM/yyyy"),
                HoraInicio           = audiencia.FechaHoraInicio.ToString("HH:mm"),
                HoraFin              = audiencia.FechaHoraFin.ToString("HH:mm"),
                EsPrivada            = audiencia.EsPrivada,
                Token                = audiencia.Token,
                Sala                 = audiencia.Sala,
                FolioVideoconferencia = audiencia.FolioVideoconferencia,
                Prioridad            = audiencia.Prioridad,
                EsContinuacion       = audiencia.EsContinuacion,
                AudienciaPrevia      = audiencia.AudienciaPrevia,
                JuezAsignado         = audiencia.JuezAsignado,
                AgendadoPor          = audiencia.AgendadoPor,
                FechaAlta            = audiencia.FechaAlta.ToString("dd/MM/yyyy HH:mm"),
                FormatoAudiencia     = audiencia.FormatoAudiencia,
                Participantes        = audiencia.Participantes.Select(p => new ParticipanteDto
                {
                    IdentificadorAsistente = p.IdentificadorAsistente,
                    Nombre                 = p.Nombre,
                    Rol                    = p.Rol
                }).ToList()
            };

            return ResultadoOperacion<DetalleAudienciaCJPFDto>.Exitoso(detalle);
        }
    }

    public class DetalleAudienciaCJPFDto
    {
        public string   NumeroExpediente      { get; set; } = string.Empty;
        public string   TipoAsunto            { get; set; } = string.Empty;
        public string   TipoAudiencia         { get; set; } = string.Empty;
        public string   Estado                { get; set; } = string.Empty;
        public string   FechaInicio           { get; set; } = string.Empty;
        public string   FechaFin              { get; set; } = string.Empty;
        public string   HoraInicio            { get; set; } = string.Empty;
        public string   HoraFin               { get; set; } = string.Empty;
        public bool     EsPrivada             { get; set; }
        public string   Token                 { get; set; } = string.Empty;
        public string   Sala                  { get; set; } = string.Empty;
        public string?  FolioVideoconferencia { get; set; }
        public string   Prioridad             { get; set; } = string.Empty;
        public bool     EsContinuacion        { get; set; }
        public string?  AudienciaPrevia       { get; set; }
        public string   JuezAsignado          { get; set; } = string.Empty;
        public string   AgendadoPor           { get; set; } = string.Empty;
        public string   FechaAlta             { get; set; } = string.Empty;
        public string   FormatoAudiencia      { get; set; } = string.Empty;
        public List<ParticipanteDto> Participantes { get; set; } = new();
    }

    public class ParticipanteDto
    {
        public string IdentificadorAsistente { get; set; } = string.Empty;
        public string Nombre                 { get; set; } = string.Empty;
        public string Rol                    { get; set; } = string.Empty;
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

    public class AudienciaCJPF
    {
        public int      Id                    { get; set; }
        public string   NumeroExpediente      { get; set; } = string.Empty;
        public string   TipoAsunto            { get; set; } = string.Empty;
        public string   TipoAudiencia         { get; set; } = string.Empty;
        public string   Estado                { get; set; } = string.Empty;
        public DateTime FechaHoraInicio       { get; set; }
        public DateTime FechaHoraFin          { get; set; }
        public bool     EsPrivada             { get; set; }
        public string   Token                 { get; set; } = string.Empty;
        public string   Sala                  { get; set; } = string.Empty;
        public string?  FolioVideoconferencia { get; set; }
        public string   Prioridad             { get; set; } = string.Empty;
        public bool     EsContinuacion        { get; set; }
        public string?  AudienciaPrevia       { get; set; }
        public string   JuezAsignado          { get; set; } = string.Empty;
        public string   AgendadoPor           { get; set; } = string.Empty;
        public DateTime FechaAlta             { get; set; }
        public string   FormatoAudiencia      { get; set; } = string.Empty;
        public List<Participante> Participantes { get; set; } = new();
    }

    public class Participante
    {
        public string IdentificadorAsistente { get; set; } = string.Empty;
        public string Nombre                 { get; set; } = string.Empty;
        public string Rol                    { get; set; } = string.Empty;
    }
}
