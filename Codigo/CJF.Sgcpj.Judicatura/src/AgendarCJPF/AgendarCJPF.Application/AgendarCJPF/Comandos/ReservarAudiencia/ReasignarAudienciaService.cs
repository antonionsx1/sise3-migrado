using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.ReasignarAudiencia
{
    public class ReasignarAudienciaService
    {
        private readonly List<AudienciaCJPF>         _audiencias;
        private readonly List<ResponsableCJPF>       _responsables;
        private readonly List<HistorialAsignacion>   _historial;

        public ReasignarAudienciaService(
            List<AudienciaCJPF>       audiencias,
            List<ResponsableCJPF>     responsables,
            List<HistorialAsignacion> historial)
        {
            _audiencias    = audiencias;
            _responsables  = responsables;
            _historial     = historial;
        }

        public ResultadoOperacion Reasignar(ReasignarAudienciaRequest request)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            // ERROR ERR-REAS-001: Manejo de errores erróneo
            // No se valida que el nuevo responsable exista y esté activo
            // antes de hacer la reasignación
            bool disponible = !_audiencias.Any(a =>
                a.ResponsableId == request.NuevoResponsableId &&
                a.Estado != "Cancelada" &&
                a.FechaHoraInicio < audiencia.FechaHoraFin &&
                a.FechaHoraFin > audiencia.FechaHoraInicio);

            if (!disponible)
                return ResultadoOperacion.Error(
                    "El nuevo responsable no tiene disponibilidad en ese horario");

            // Guardar historial
            _historial.Add(new HistorialAsignacion
            {
                Id              = _historial.Count + 1,
                AudienciaId     = audiencia.Id,
                ResponsableAnterior = audiencia.ResponsableId,
                ResponsableNuevo    = request.NuevoResponsableId,
                Motivo          = request.Motivo,
                FechaCambio     = DateTime.Now,
                UsuarioReasigno = request.UsuarioId
            });

            audiencia.ResponsableId = request.NuevoResponsableId;

            NotificarInvolucrados(audiencia, request);

            return ResultadoOperacion.Exitoso(
                $"Audiencia reasignada correctamente al responsable {request.NuevoResponsableId}");
        }

        private void NotificarInvolucrados(
            AudienciaCJPF audiencia, ReasignarAudienciaRequest request)
        {
            Console.WriteLine($"Notificando reasignación de audiencia {audiencia.Id}");
        }
    }

    public class ReasignarAudienciaRequest
    {
        public int    AudienciaId         { get; set; }
        public string NuevoResponsableId  { get; set; } = string.Empty;
        public string Motivo              { get; set; } = string.Empty;
        public string UsuarioId           { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int      Id              { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   ResponsableId   { get; set; } = string.Empty;
        public string   Estado          { get; set; } = string.Empty;
        public DateTime FechaHoraInicio { get; set; }
        public DateTime FechaHoraFin    { get; set; }
    }

    public class ResponsableCJPF
    {
        public string Id         { get; set; } = string.Empty;
        public string Nombre     { get; set; } = string.Empty;
        public bool   EstaActivo { get; set; }
    }

    public class HistorialAsignacion
    {
        public int      Id                  { get; set; }
        public int      AudienciaId         { get; set; }
        public string   ResponsableAnterior { get; set; } = string.Empty;
        public string   ResponsableNuevo    { get; set; } = string.Empty;
        public string   Motivo              { get; set; } = string.Empty;
        public DateTime FechaCambio         { get; set; }
        public string   UsuarioReasigno     { get; set; } = string.Empty;
    }

    public class ResultadoOperacion
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;

        public static ResultadoOperacion Exitoso(string mensaje) =>
            new ResultadoOperacion { Exito = true, Mensaje = mensaje };

        public static ResultadoOperacion Error(string mensaje) =>
            new ResultadoOperacion { Exito = false, Mensaje = mensaje };
    }
}
