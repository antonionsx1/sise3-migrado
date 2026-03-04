namespace Agenda.Domain.Entities
{
    public class Audiencia
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
        public string Estado { get; set; } = string.Empty; // Cancelada, Diferida, Celebrada
    }
}
