using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.ObtenerAgendaFecha
{
    /// <summary>
    /// Servicio para obtener la agenda de audiencias por fecha y filtros.
    /// HU001 - US12001_VerAgenda
    /// </summary>
    public class ObtenerAgendaFechaService
    {
        // Modos de visualización del calendario
        public enum ModoVisualizacion { Dia, Semana, SemanaLaboral, Mes }

        // Estados de filtro disponibles
        public enum EstadoFiltro { VerTodo, Canceladas, Diferidas, Celebradas }

        private readonly List<Audiencia> _audiencias;

        public ObtenerAgendaFechaService()
        {
            // Datos simulados
            _audiencias = new List<Audiencia>
            {
                new Audiencia { Id = 1, NumeroExpediente = "001/2026", TipoAsunto = "Penal",
                    TipoProcedimiento = "Oral", FechaHora = DateTime.Today.AddHours(9),
                    TipoAudiencia = "Inicial", Secretario = "Juan Pérez",
                    PartesInteresadas = "Parte A, Parte B",
                    PersonaQueAgenda = "Laura Cortes", Estado = "Celebrada" },

                new Audiencia { Id = 2, NumeroExpediente = "002/2026", TipoAsunto = "Civil",
                    TipoProcedimiento = "Oral", FechaHora = DateTime.Today.AddHours(11),
                    TipoAudiencia = "Desahogo", Secretario = "María López",
                    PartesInteresadas = "Parte C, Parte D",
                    PersonaQueAgenda = "Laura Cortes", Estado = "Cancelada" },

                new Audiencia { Id = 3, NumeroExpediente = "003/2026", TipoAsunto = "Familiar",
                    TipoProcedimiento = "Oral", FechaHora = DateTime.Today.AddHours(13),
                    TipoAudiencia = "Sentencia", Secretario = "Carlos Ruiz",
                    PartesInteresadas = "Parte E, Parte F",
                    PersonaQueAgenda = "Laura Cortes", Estado = "Diferida" },
            };
        }

        /// <summary>
        /// Obtiene audiencias filtradas por estado y rango de fechas según modo de visualización.
        /// </summary>
        public List<AudienciaDto> ObtenerAudiencias(DateTime fechaInicio, DateTime fechaFin,
            EstadoFiltro filtro, ModoVisualizacion modo)
        {
            var fechasFiltradas = ObtenerFechasHabiles(fechaInicio, fechaFin, modo);

            var audienciasFiltradas = _audiencias
                .Where(a => fechasFiltradas.Contains(a.FechaHora.Date))
                .Where(a => AplicarFiltroEstado(a, filtro))
                .Select(a => MapearADto(a))
                .ToList();

            return audienciasFiltradas;
        }

        /// <summary>
        /// Filtra audiencias por estado según el filtro seleccionado.
        /// </summary>
        private bool AplicarFiltroEstado(Audiencia audiencia, EstadoFiltro filtro)
        {
            return filtro switch
            {
                EstadoFiltro.VerTodo    => true,
                EstadoFiltro.Canceladas => audiencia.Estado == "Cancelada",
                EstadoFiltro.Diferidas  => audiencia.Estado == "Diferida",
                EstadoFiltro.Celebradas => audiencia.Estado == "Celebrada",
                _                       => true
            };
        }

        /// <summary>
        /// Obtiene fechas hábiles (excluye fines de semana) en el rango según modo de visualización.
        /// </summary>
        private List<DateTime> ObtenerFechasHabiles(DateTime inicio, DateTime fin,
            ModoVisualizacion modo)
        {
            var fechas = new List<DateTime>();
            var current = inicio.Date;

            while (current <= fin.Date)
            {
                // Excluir fines de semana
                if (current.DayOfWeek != DayOfWeek.Saturday
                    && current.DayOfWeek != DayOfWeek.Sunday)
                {
                    // En modo SemanaLaboral solo lunes a viernes
                    if (modo == ModoVisualizacion.SemanaLaboral)
                    {
                        if (current.DayOfWeek >= DayOfWeek.Monday
                            && current.DayOfWeek <= DayOfWeek.Friday)
                            fechas.Add(current);
                    }
                    else
                    {
                        fechas.Add(current);
                    }
                }
                current = current.AddDays(1);
            }

            return fechas;
        }

        private AudienciaDto MapearADto(Audiencia a) => new AudienciaDto
        {
            Id                 = a.Id,
            NumeroExpediente   = a.NumeroExpediente,
            TipoAsunto         = a.TipoAsunto,
            TipoProcedimiento  = a.TipoProcedimiento,
            FechaHora          = a.FechaHora,
            TipoAudiencia      = a.TipoAudiencia,
            Secretario         = a.Secretario,
            PartesInteresadas  = a.PartesInteresadas,
            PersonaQueAgenda   = a.PersonaQueAgenda,
            Estado             = a.Estado
        };
    }
}
