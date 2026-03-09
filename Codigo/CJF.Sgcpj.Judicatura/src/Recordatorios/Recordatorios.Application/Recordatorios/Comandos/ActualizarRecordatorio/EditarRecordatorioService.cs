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

        // CORRECCIÓN ERR-REC-002: Estructura corregida
        // Se separan las responsabilidades en métodos independientes:
        // ValidarPermisos, ValidarRequest y EditarRecordatorio
        public ResultadoOperacion EditarRecordatorio(EditarRecordatorioRequest request,
            string usuarioActual, bool esAdministrador)
        {
            var recordatorio = _recordatorios.FirstOrDefault(r => r.Id == request.Id);
            if (recordatorio == null)
                return ResultadoOperacion.Error("No se encontró el recordatorio indicado");

            var permiso = ValidarPermisos(recordatorio, usuarioActual, esAdministrador);
            if (!permiso.Exito)
                return permiso;

            var validacion = ValidarRequest(request);
            if (!validacion.Exito)
                return validacion;

            if (string.IsNullOrEmpty(request.UsuarioDestinatario))
                request.UsuarioDestinatario = usuarioActual;

            ActualizarRecordatorio(recordatorio, request, usuarioActual);

            return ResultadoOperacion.Exitoso(
                $"Recordatorio del expediente {recordatorio.NumeroExpediente} " +
                $"actualizado correctamente");
        }

        // CORRECCIÓN ERR-REC-002: Validación de permisos en método independiente
        private ResultadoOperacion ValidarPermisos(RecordatorioDetalle recordatorio,
            string usuarioActual, bool esAdministrador)
        {
            if (recordatorio.UsuarioCreador != usuarioActual && !esAdministrador)
                return ResultadoOperacion.Error("No cuenta con permisos para editar este recordatorio");

            return ResultadoOperacion.Exitoso(string.Empty);
        }

        // CORRECCIÓN ERR-REC-003: Operador lógico corregido
        // Se usa && para validar correctamente que la fecha sea hábil y no anterior al día actual
        private ResultadoOperacion ValidarRequest(EditarRecordatorioRequest request)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("El número de expediente es requerido");

            if (string.IsNullOrWhiteSpace(request.Descripcion))
                return ResultadoOperacion.Error("La descripción no puede estar vacía");

            bool fechaValida = request.FechaRecordatorio.Date >= DateTime.Today.Date &&
                               request.FechaRecordatorio.DayOfWeek != DayOfWeek.Saturday &&
                               request.FechaRecordatorio.DayOfWeek != DayOfWeek.Sunday;

            if (!fechaValida)
                return ResultadoOperacion.Error("ERR-REC-003: La fecha seleccionada no es válida");

            return ResultadoOperacion.Exitoso(string.Empty);
        }

        private void ActualizarRecordatorio(RecordatorioDetalle recordatorio,
            EditarRecordatorioRequest request, string usuarioActual)
        {
            recordatorio.NumeroExpediente    = request.NumeroExpediente.Trim();
            recordatorio.FechaRecordatorio   = request.FechaRecordatorio;
            recordatorio.Descripcion         = request.Descripcion.Trim();
            recordatorio.UsuarioDestinatario = request.UsuarioDestinatario;
            recordatorio.FechaModificacion   = DateTime.Now;
            recordatorio.UsuarioModificacion = usuarioActual;
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
