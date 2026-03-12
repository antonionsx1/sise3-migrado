using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Comandos.ModificarEstadoAudienciaTCA
{
    public class MarcarEstadoAudienciaTCAService
    {
        private readonly List<Audiencia> _audiencias;

        public MarcarEstadoAudienciaTCAService(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion MarcarEstado(string numeroExpediente,
            int audienciaId, string nuevoEstado)
        {
            // ERROR ERR-TCA-003: Comentario incorrecto
            // El comentario indica que se validan todos los estados pero
            // el código no incluye "Suspendida" que es un estado válido según la HU
            // Estados válidos: Cancelada, Diferida, Celebrada, Suspendida (otros)
            var estadosValidos = new[] { "Cancelada", "Diferida", "Celebrada" };
            if (!estadosValidos.Contains(nuevoEstado))
                return ResultadoOperacion.Error($"El estado '{nuevoEstado}' no es válido");

            var ultimaAudiencia = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente)
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            if (ultimaAudiencia == null)
                return ResultadoOperacion.Error(
                    "No se encontró audiencia para el expediente indicado");

            if (ultimaAudiencia.Id != audienciaId)
                return ResultadoOperacion.Error(
                    "Solo se puede modificar el estado de la última audiencia del expediente");

            ultimaAudiencia.Estado = nuevoEstado;

            return ResultadoOperacion.Exitoso(
                $"El estado de la audiencia del expediente {numeroExpediente} " +
                $"fue actualizado a {nuevoEstado}");
        }

        // ERROR ERR-TCA-004: Operador lógico erróneo en ObtenerColorEstado
        // Se usa && en lugar de || en la condición de "Otros" estados
        // por lo que nunca se asigna el color azul correctamente
        public string ObtenerColorEstado(string estado)
        {
            if (estado == "Cancelada")
                return "rojo";

            if (estado == "Diferida")
                return "amarillo";

            if (estado == "Celebrada")
                return "verde";

            // ERROR: usa && por lo que la condición nunca se cumple
            if (estado == "Procedimiento suspendido" &&
                estado == "Sin efectos" &&
                estado == "Sobreseimiento fuera de Audiencia")
                return "azul";

            return "azul";
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
