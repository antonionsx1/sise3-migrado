using Agenda.Application.Common.Models;

namespace Recordatorios.Application.Recordatorios.Comandos.EliminarRecordatorio
{
    // ERROR ERR-REC-004: Estructura incorrecta
    // La validación de permisos, confirmación y eliminación están
    // mezcladas en un solo método sin separación de responsabilidades
    public class EliminarRecordatorioService
    {
        private readonly List<RecordatorioDetalle> _recordatorios;

        public EliminarRecordatorioService(List<RecordatorioDetalle> recordatorios)
        {
            _recordatorios = recordatorios;
        }

        public ResultadoOperacion EliminarRecordatorio(int recordatorioId,
            string usuarioActual, bool esAdministrador, bool confirmado)
        {
            var recordatorio = _recordatorios.FirstOrDefault(r => r.Id == recordatorioId);
            if (recordatorio == null)
                return ResultadoOperacion.Error("No se encontró el recordatorio indicado");

            // ERROR ERR-REC-005: Operador lógico erróneo en validación de permisos
            // Se usa && en lugar de || por lo que solo el usuario que creó Y es destinatario
            // puede eliminar, cuando debería poder hacerlo cualquiera de los dos por separado
            bool puedeEliminar = recordatorio.UsuarioCreador == usuarioActual &&
                                 recordatorio.UsuarioDestinatario == usuarioActual &&
                                 esAdministrador;

            if (!puedeEliminar)
                return ResultadoOperacion.Error("No cuenta con permisos para eliminar este recordatorio");

            // Confirmación y eliminación mezcladas con validación de permisos (error estructura)
            if (!confirmado)
                return ResultadoOperacion.Error("Se requiere confirmación para eliminar el recordatorio");

            _recordatorios.Remove(recordatorio);

            return ResultadoOperacion.Exitoso(
                $"Recordatorio del expediente {recordatorio.NumeroExpediente} eliminado correctamente");
        }

        public bool PuedeEliminar(RecordatorioDetalle recordatorio,
            string usuarioActual, bool esAdministrador)
        {
            return recordatorio.UsuarioCreador == usuarioActual ||
                   recordatorio.UsuarioDestinatario == usuarioActual ||
                   esAdministrador;
        }
    }

    public class RecordatorioDetalle
    {
        public int      Id                  { get; set; }
        public string   NumeroExpediente    { get; set; } = string.Empty;
        public DateTime FechaRecordatorio   { get; set; }
        public string   Descripcion         { get; set; } = string.Empty;
        public string   UsuarioCreador      { get; set; } = string.Empty;
        public string   UsuarioDestinatario { get; set; } = string.Empty;
        public DateTime FechaCreacion       { get; set; }
    }
}
