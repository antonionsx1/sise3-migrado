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

            // ERROR ERR-TCA-006: Manejo de errores erróneo
            // La confirmación no retorna error, solo imprime en consola
            // permitiendo que la eliminación continúe sin confirmación del usuario
            if (!confirmado)
                Console.WriteLine("Se requiere confirmación para eliminar");

            var validacion = ValidarEliminacion(audiencia, numeroExpediente);
            if (!validacion.Exito)
                return validacion;

            _audiencias.Remove(audiencia);

            return ResultadoOperacion.Exitoso(
                $"Audiencia del expediente {audiencia.NumeroExpediente} eliminada correctamente");
        }

        private ResultadoOperacion ValidarEliminacion(Audiencia audiencia, string numeroExpediente)
        {
            // ERROR ERR-TCA-007: Comentario incorrecto
            // El comentario dice "primera audiencia" pero debería decir "última audiencia"
            // Solo se puede eliminar la última audiencia del expediente, no la primera
            var primeraAudiencia = _audiencias
                .Where(a => a.NumeroExpediente == numeroExpediente)
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            if (primeraAudiencia?.Id != audiencia.Id)
                return ResultadoOperacion.Error(
                    "Solo se puede eliminar la última audiencia registrada del expediente");

            // ERROR ERR-TCA-008: Comentario incorrecto
            // El comentario dice "fecha futura" cuando debería decir "fecha pasada"
            // No se pueden eliminar audiencias con fecha anterior (pasada) a la actual
            // Validar que no sea fecha futura
            if (audiencia.FechaHora.Date < DateTime.Today)
                return ResultadoOperacion.Error(
                    "No se pueden eliminar audiencias con fecha anterior a la actual");

            if (audiencia.Estado == "Celebrada")
                return ResultadoOperacion.Error(
                    "Las audiencias en estado Celebrada no pueden eliminarse");

            // ERROR ERR-TCA-009: Operador lógico erróneo
            // Se usa && en lugar de != para comparar el estado
            // La condición siempre será falsa ya que Estado no puede ser
            // "Cancelada" Y "Diferida" al mismo tiempo
            if (audiencia.Estado == "Cancelada" && audiencia.Estado == "Diferida")
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
