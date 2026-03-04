using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Comandos.MarcarEstadoAudiencia
{
    public class MarcarEstadoAudienciaService
    {
        private readonly List<Audiencia> _audiencias;

        public MarcarEstadoAudienciaService(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion MarcarEstado(string numeroExpediente, int audienciaId, string nuevoEstado)
        {
            var estadosValidos = new[] { "Cancelada", "Diferida", "Celebrada" };
            if (!estadosValidos.Contains(nuevoEstado))
                return ResultadoOperacion.Error($"El estado '{nuevoEstado}' no es válido");

            var ultimaAudiencia = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente)
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            if (ultimaAudiencia == null)
                return ResultadoOperacion.Error("No se encontró audiencia para el expediente indicado");

            if (ultimaAudiencia.Id != audienciaId)
                return ResultadoOperacion.Error("Solo se puede modificar el estado de la última audiencia del expediente");

            ultimaAudiencia.Estado = nuevoEstado;

            return ResultadoOperacion.Exitoso(
                $"El estado de la audiencia del expediente {numeroExpediente} fue actualizado a {nuevoEstado}");
        }

        public string ObtenerColorEstado(string estado)
        {
            return estado switch
            {
                "Cancelada" => "rojo",
                "Diferida"  => "amarillo",
                "Celebrada" => "verde",
                _           => "azul"
            };
        }

        public bool EsUltimaAudiencia(string numeroExpediente, int audienciaId)
        {
            var ultima = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente)
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            return ultima?.Id == audienciaId;
        }
    }
}
