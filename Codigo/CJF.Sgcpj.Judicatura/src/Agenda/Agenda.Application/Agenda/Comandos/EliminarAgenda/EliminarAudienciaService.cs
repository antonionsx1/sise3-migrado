using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Comandos.EliminarAudiencia
{
    public class EliminarAudienciaService
    {
        private readonly List<Audiencia> _audiencias;

        public EliminarAudienciaService(List<Audiencia> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion EliminarAudiencia(int audienciaId,
            string numeroExpediente, bool confirmado)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            if (!confirmado)
                return ResultadoOperacion.Error("Se requiere confirmación para eliminar la audiencia");

            var validacion = ValidarEliminacion(audiencia, numeroExpediente);
            if (!validacion.Exito)
                return validacion;

            _audiencias.Remove(audiencia);

            return ResultadoOperacion.Exitoso(
                $"Audiencia del expediente {audiencia.NumeroExpediente} eliminada correctamente");
        }

        private ResultadoOperacion ValidarEliminacion(Audiencia audiencia, string numeroExpediente)
        {
            // Validar que sea la última audiencia del expediente
            var ultimaAudiencia = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente)
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            if (ultimaAudiencia?.Id != audiencia.Id)
                return ResultadoOperacion.Error(
                    "Solo se puede eliminar la última audiencia registrada del expediente");

            // Validar que no sea fecha pasada
            if (audiencia.FechaHora.Date < DateTime.Today)
                return ResultadoOperacion.Error(
                    "No se pueden eliminar audiencias con fecha anterior a la actual");

            // Validar que no esté Celebrada
            if (audiencia.Estado == "Celebrada")
                return ResultadoOperacion.Error(
                    "Las audiencias en estado Celebrada no pueden eliminarse");

            // ERROR ERR-AGN-006: Operador lógico erróneo en validación de roles
            // Se usa && en lugar de || por lo que solo puede eliminar
            // quien sea Titular Y Secretario al mismo tiempo, lo cual es imposible
            bool rolPermitido = audiencia.PersonaQueAgenda == "Titular" &&
                                audiencia.PersonaQueAgenda == "Secretario";

            if (!rolPermitido)
                return ResultadoOperacion.Error(
                    "ERR-AGN-006: Solo el Titular del Juzgado o el Secretario pueden eliminar audiencias");

            return ResultadoOperacion.Exitoso(string.Empty);
        }

        public bool PuedeEliminar(Audiencia audiencia, string rol)
        {
            return (rol == "Titular" || rol == "Secretario") &&
                   audiencia.Estado != "Celebrada" &&
                   audiencia.FechaHora.Date >= DateTime.Today;
        }
    }
}
