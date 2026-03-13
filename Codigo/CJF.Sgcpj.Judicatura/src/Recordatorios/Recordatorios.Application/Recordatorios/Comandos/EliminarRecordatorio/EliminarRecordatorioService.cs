using Agenda.Application.Common.Models;

namespace Recordatorios.Application.Recordatorios.Comandos.EliminarRecordatorio
{
    // CORRECCIÓN ERR-REC-004: Estructura corregida
    // Se separan las responsabilidades en métodos independientes:
    // ValidarPermisos, SolicitarConfirmacion y Eliminar
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

            var permiso = ValidarPermisos(recordatorio, usuarioActual, esAdministrador);
            if (!permiso.Exito)
                return permiso;

            var confirmacion = ValidarConfirmacion(confirmado);
            if (!confirmacion.Exito)
                return confirmacion;

            return Eliminar(recordatorio);
        }

        // CORRECCIÓN ERR-REC-004: Validación de permisos en método independiente
        // CORRECCIÓN ERR-REC-005: Operador lógico corregido
        // Se usa || para que cualquiera de los tres perfiles pueda eliminar por separado
        private ResultadoOperacion ValidarPermisos(RecordatorioDetalle recordatorio,
            string usuarioActual, bool esAdministrador)
        {
            bool puedeEliminar = recordatorio.UsuarioCreador == usuarioActual ||
                                 recordatorio.UsuarioDestinatario == usuarioActual ||
                                 esAdministrador;

            if (!puedeEliminar)
                return ResultadoOperacion.Error("No cuenta con permisos para eliminar este recordatorio");

            return ResultadoOperacion.Exitoso(string.Empty);
        }

        private ResultadoOperacion ValidarConfirmacion(bool confirmado)
        {
            if (!confirmado)
                return ResultadoOperacion.Error("Se requiere confirmación para eliminar el recordatorio");

            return ResultadoOperacion.Exitoso(string.Empty);
        }

        private ResultadoOperacion Eliminar(RecordatorioDetalle recordatorio)
        {
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
