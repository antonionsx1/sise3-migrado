using Agenda.Application.Common.Models;

namespace Recordatorios.Application.Recordatorios.Comandos.InsertarRecordatorio
{
    public class InsertarRecordatorioService
    {
        private readonly List<RecordatorioDetalle> _recordatorios;

        public InsertarRecordatorioService(List<RecordatorioDetalle> recordatorios)
        {
            _recordatorios = recordatorios;
        }

        public ResultadoOperacion Insertar(InsertarRecordatorioRequest request)
        {
            var validacion = ValidarRequest(request);
            if (!validacion.Exito)
                return validacion;

            if (string.IsNullOrEmpty(request.UsuarioDestinatario))
                request.UsuarioDestinatario = request.UsuarioCreador;

            var recordatorio = new RecordatorioDetalle
            {
                Id                  = _recordatorios.Count + 1,
                NumeroExpediente    = request.NumeroExpediente.Trim(),
                FechaRecordatorio   = request.FechaRecordatorio,
                Descripcion         = request.Descripcion.Trim(),
                UsuarioCreador      = request.UsuarioCreador,
                UsuarioDestinatario = request.UsuarioDestinatario,
                FechaCreacion       = DateTime.Now
            };

            _recordatorios.Add(recordatorio);

            return ResultadoOperacion.Exitoso(
                $"Recordatorio registrado para el expediente {recordatorio.NumeroExpediente} " +
                $"con fecha {recordatorio.FechaRecordatorio:dd/MM/yyyy}, " +
                $"asignado a {recordatorio.UsuarioDestinatario}");
        }

        private ResultadoOperacion ValidarRequest(InsertarRecordatorioRequest request)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("El número de expediente es requerido");

            if (string.IsNullOrWhiteSpace(request.Descripcion))
                return ResultadoOperacion.Error("La descripción del recordatorio no puede estar vacía");

            if (request.FechaRecordatorio.Date < DateTime.Today)
                return ResultadoOperacion.Error("La fecha del recordatorio no puede ser anterior al día en curso");

            bool esDiaHabil = request.FechaRecordatorio.DayOfWeek != DayOfWeek.Saturday
                           && request.FechaRecordatorio.DayOfWeek != DayOfWeek.Sunday;

            if (!esDiaHabil)
                return ResultadoOperacion.Error("La fecha seleccionada corresponde a un día inhábil");

            return ResultadoOperacion.Exitoso(string.Empty);
        }

        public List<RecordatorioDetalle> ObtenerPorExpediente(string numeroExpediente)
        {
            return _recordatorios
                .Where(r => r.NumeroExpediente == numeroExpediente)
                .OrderBy(r => r.FechaRecordatorio)
                .ToList();
        }

        public List<RecordatorioDetalle> ObtenerPorUsuario(string usuarioDestinatario)
        {
            return _recordatorios
                .Where(r => r.UsuarioDestinatario == usuarioDestinatario)
                .OrderBy(r => r.FechaRecordatorio)
                .ToList();
        }
    }

    public class InsertarRecordatorioRequest
    {
        public string   NumeroExpediente    { get; set; } = string.Empty;
        public DateTime FechaRecordatorio   { get; set; }
        public string   Descripcion         { get; set; } = string.Empty;
        public string   UsuarioCreador      { get; set; } = string.Empty;
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
    }
}
