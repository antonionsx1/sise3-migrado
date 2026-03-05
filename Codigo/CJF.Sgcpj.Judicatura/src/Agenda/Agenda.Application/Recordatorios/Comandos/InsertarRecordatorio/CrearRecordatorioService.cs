using Agenda.Application.Common.Models;

namespace Agenda.Application.Recordatorios.Comandos.InsertarRecordatorio
{
    public class CrearRecordatorioService
    {
        private readonly List<Recordatorio> _recordatorios;

        public CrearRecordatorioService(List<Recordatorio> recordatorios)
        {
            _recordatorios = recordatorios;
        }

        public ResultadoOperacion CrearRecordatorio(CrearRecordatorioRequest request)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("El número de expediente es requerido");

            if (string.IsNullOrWhiteSpace(request.Descripcion))
                return ResultadoOperacion.Error("La descripción del recordatorio es requerida");

            // CORRECCIÓN ERR-REC-001: Operador lógico corregido
            // Se usa && para que todas las condiciones se cumplan simultáneamente
            // validando correctamente que la fecha sea hábil y no anterior al día actual
            bool fechaValida = request.Fecha.Date >= DateTime.Today.Date &&
                               request.Fecha.DayOfWeek != DayOfWeek.Saturday &&
                               request.Fecha.DayOfWeek != DayOfWeek.Sunday;

            if (!fechaValida)
                return ResultadoOperacion.Error("ERR-REC-001: La fecha seleccionada no es válida");

            // Si no se asigna destinatario, se asigna al usuario que crea el recordatorio
            if (string.IsNullOrEmpty(request.AsignadoA))
                request.AsignadoA = request.CreadoPor;

            var recordatorio = new Recordatorio
            {
                Id               = _recordatorios.Count + 1,
                NumeroExpediente = request.NumeroExpediente,
                Fecha            = request.Fecha,
                Descripcion      = request.Descripcion,
                CapturedoPor     = request.CreadoPor,
                AsignadoA        = request.AsignadoA
            };

            _recordatorios.Add(recordatorio);

            return ResultadoOperacion.Exitoso(
                $"Recordatorio creado correctamente para el expediente {request.NumeroExpediente} " +
                $"con fecha {request.Fecha:dd/MM/yyyy}");
        }
    }

    public class CrearRecordatorioRequest
    {
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public string   Descripcion      { get; set; } = string.Empty;
        public string   AsignadoA        { get; set; } = string.Empty;
        public string   CreadoPor        { get; set; } = string.Empty;
    }

    public class Recordatorio
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public string   Descripcion      { get; set; } = string.Empty;
        public string   CapturedoPor     { get; set; } = string.Empty;
        public string   AsignadoA        { get; set; } = string.Empty;
    }
}
