using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Comandos.EliminarAudienciaTCA
{
    public class EliminarAudienciaTCAService
    {
        private readonly List<Audiencia> _audiencias;

        public EliminarAudienciaTCAService(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion EliminarAudiencia(int audienciaId,
            string numeroExpediente, bool confirmado)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            // CORRECCIÓN ERR-TCA-006: Manejo de errores corregido
            // La validación de confirmación ahora retorna error correctamente
            if (!confirmado)
                return ResultadoOperacion.Error(
                    "ERR-TCA-006: Se requiere confirmación para eliminar la audiencia");

            var validacion = ValidarEliminacion(audiencia, numeroExpediente);
            if (!validacion.Exito)
                return validacion;

            _audiencias.Remove(audiencia);

            return ResultadoOperacion.Exitoso(
                $"Audiencia del expediente {audiencia.NumeroExpediente} eliminada correctamente");
        }

        private ResultadoOperacion ValidarEliminacion(Audiencia audiencia, string numeroExpediente)
        {
            // CORRECCIÓN ERR-TCA-007: Comentario corregido
            // Solo se puede eliminar la última audiencia del expediente
            var ultimaAudiencia = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente)
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            if (ultimaAudiencia?.Id != audiencia.Id)
                return ResultadoOperacion.Error(
                    "Solo se puede eliminar la última audiencia registrada del expediente");

            // CORRECCIÓN ERR-TCA-008: Comentario corregido
            // No se pueden eliminar audiencias con fecha pasada (anterior a la actual)
            if (audiencia.FechaHora.Date < DateTime.Today)
                return ResultadoOperacion.Error(
                    "No se pueden eliminar audiencias con fecha anterior a la actual");

            if (audiencia.Estado == "Celebrada")
                return ResultadoOperacion.Error(
                    "Las audiencias en estado Celebrada no pueden eliminarse");

            // CORRECCIÓN ERR-TCA-009: Operador lógico corregido
            // Se usa || para que la validación funcione correctamente
            // verificando si el estado es Cancelada O Diferida
            if (audiencia.Estado == "Cancelada" || audiencia.Estado == "Diferida")
                return ResultadoOperacion.Error(
                    "ERR-TCA-009: Esta audiencia no puede ser eliminada en su estado actual");

            return ResultadoOperacion.Exitoso(string.Empty);
        }

        public bool PuedeEliminar(Audiencia audiencia, string numeroExpediente)
        {
            var ultimaAudiencia = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente)
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            return ultimaAudiencia?.Id == audiencia.Id &&
                   audiencia.Estado != "Celebrada" &&
                   audiencia.FechaHora.Date >= DateTime.Today;
        }
    }
}
