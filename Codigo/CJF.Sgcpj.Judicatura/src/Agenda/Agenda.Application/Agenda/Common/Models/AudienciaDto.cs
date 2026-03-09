namespace Agenda.Application.Common.Models
{
    public class AudienciaDto
    {
        public int Id { get; set; }
        public string NumeroExpediente { get; set; } = string.Empty;
        public string TipoAsunto { get; set; } = string.Empty;
        public string TipoProcedimiento { get; set; } = string.Empty;
        public DateTime FechaHora { get; set; }
        public string TipoAudiencia { get; set; } = string.Empty;
        public string Secretario { get; set; } = string.Empty;
        public string PartesInteresadas { get; set; } = string.Empty;
        public string PersonaQueAgenda { get; set; } = string.Empty;
        public string Estado { get; set; } = string.Empty;
        public string ColorEstado => Estado switch
        {
            "Cancelada" => "rojo",
            "Diferida"  => "amarillo",
            "Celebrada" => "verde",
            _           => "azul"
        };
    }
}
