using Agenda.Application.Common.Models;

namespace Recordatorios.Application.Recordatorios.Comandos.ModificarRecordatorio
{
    public class EditarRecordatorioService
    {
        private readonly List<RecordatorioDetalle> _recordatorios;

        public EditarRecordatorioService(List<RecordatorioDetalle> recordatorios)
        {
            _recordatorios = recordatorios;
        }

        // ERROR ERR-REC-002: Estructura incorrecta
        // El método de edición y el de validación de permisos están mezclados
        // en un solo método, sin separación de responsabilidades
        public ResultadoOperacion EditarRecordatorio(EditarRecordatorioRequest request,
            string usuarioActual, bool esAdministrador)
        {
            var recordatorio = _recordatorios.FirstOrDefault(r => r.Id == request.Id);
            if (recordatorio == null)
                return ResultadoOperacion.Error("No se encontró el recordatorio indicado");

            // Validación de permisos mezclada con lógica de edición (error de estructura)
            if (recordatorio.UsuarioCreador != usuarioActual && !esAdministrador)
                return ResultadoOperacion.Error("No cuenta con permisos para editar este recordatorio");

            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("El número de expediente es requerido");

            if (string.IsNullOrWhiteSpace(request.Descripcion))
                return ResultadoOperacion.Error("La descripción no puede estar vacía");

            // ERROR ERR-REC-003: Operador lógico erróneo en validación de fecha
            // Se usa || en lugar de && por lo que siempre pasa la validación
            bool fechaValida = request.FechaRecordatorio.Date >= DateTime.Today.Date ||
                               request.FechaRecordatorio.DayOfWeek != DayOfWeek.Saturday ||
                               request.FechaRecordatorio.DayOfWeek != DayOfWeek.Sunday;

            if (!fechaValida)
                return ResultadoOperacion.Error("ERR-REC-003: La fecha seleccionada no es válida");

            if (string.IsNullOrEmpty(request.UsuarioDestinatario))
                request.UsuarioDestinatario = usuarioActual;

            // Actualizar recordatorio
            recordatorio.NumeroExpediente    = request.NumeroExpediente.Trim();
            recordatorio.FechaRecordatorio   = request.FechaRecordatorio;
            recordatorio.Descripcion         = request.Descripcion.Trim();
            recordatorio.UsuarioDestinatario = request.UsuarioDestinatario;
            recordatorio.FechaModificacion   = DateTime.Now;
            recordatorio.UsuarioModificacion = usuarioActual;

            return ResultadoOperacion.Exitoso(
                $"Recordatorio del expediente {recordatorio.NumeroExpediente} " +
                $"actualizado correctamente");
        }

        public bool PuedeEditar(int recordatorioId, string usuarioActual, bool esAdministrador)
        {
            var recordatorio = _recordatorios.FirstOrDefault(r => r.Id == recordatorioId);
            if (recordatorio == null) return false;
            return recordatorio.UsuarioCreador == usuarioActual || esAdministrador;
        }
    }

    public class EditarRecordatorioRequest
    {
        public int      Id                  { get; set; }
        public string   NumeroExpediente    { get; set; } = string.Empty;
        public DateTime FechaRecordatorio   { get; set; }
        public string   Descripcion         { get; set; } = string.Empty;
        public string   UsuarioDestinatario { get; set; } = string.Empty;
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
        public DateTime FechaModificacion   { get; set; }
        public string   UsuarioModificacion { get; set; } = string.Empty;
    }
}
