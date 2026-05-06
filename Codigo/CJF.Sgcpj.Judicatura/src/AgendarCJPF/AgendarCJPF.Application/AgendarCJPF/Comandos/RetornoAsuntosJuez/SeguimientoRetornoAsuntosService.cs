using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.SeguimientoRetornoAsuntos
{
    public class SeguimientoRetornoAsuntosService
    {
        private readonly List<TareaRetorno>         _tareas;
        private readonly List<ResponsableElegible>  _responsables;
        private readonly List<ConfigSLA>            _slaConfig;
        private readonly List<AlertaRetorno>        _alertas;

        public SeguimientoRetornoAsuntosService(
            List<TareaRetorno>        tareas,
            List<ResponsableElegible> responsables,
            List<ConfigSLA>           slaConfig,
            List<AlertaRetorno>       alertas)
        {
            _tareas        = tareas;
            _responsables  = responsables;
            _slaConfig     = slaConfig;
            _alertas       = alertas;
        }

        public ResultadoOperacion GenerarTareaSeguimiento(GenerarTareaRequest request)
        {
            if (request.AudienciaId <= 0)
                return ResultadoOperacion.Error("El ID de audiencia es requerido");

            if (string.IsNullOrEmpty(request.JuezOrigenId))
                return ResultadoOperacion.Error("El juez de origen es requerido");

            if (string.IsNullOrEmpty(request.JuezDestinoId))
                return ResultadoOperacion.Error("El juez destino es requerido");

            var responsable = AsignarResponsable(request.JuezDestinoId);
            var sla = _slaConfig.FirstOrDefault(s => s.TipoTarea == "RetornoAsunto");
            var plazo = sla != null
                ? DateTime.Now.AddDays(sla.DiasMaximos)
                : DateTime.Now.AddDays(5);

            var tarea = new TareaRetorno
            {
                Id              = _tareas.Count + 1,
                AudienciaId     = request.AudienciaId,
                JuezOrigenId    = request.JuezOrigenId,
                JuezDestinoId   = request.JuezDestinoId,
                ResponsableId   = responsable?.UsuarioId ?? string.Empty,
                Estado          = "Pendiente",
                FechaCreacion   = DateTime.Now,
                FechaPlazo      = plazo,
                Descripcion     = $"Seguimiento de retorno de asuntos del juez " +
                                  $"{request.JuezOrigenId} al juez {request.JuezDestinoId}"
            };

            _tareas.Add(tarea);

            if (responsable == null)
                EscalarACoordinador(tarea);

            return ResultadoOperacion.Exitoso(
                $"Tarea de seguimiento creada. ID: {tarea.Id}. " +
                $"Plazo: {plazo:dd/MM/yyyy}. " +
                $"Responsable: {responsable?.Nombre ?? "Coordinador (escalado)"}");
        }

        public ResultadoOperacion ActualizarEstatus(ActualizarEstatusRequest request)
        {
            var tarea = _tareas.FirstOrDefault(t => t.Id == request.TareaId);
            if (tarea == null)
                return ResultadoOperacion.Error("No se encontró la tarea de seguimiento");

            if (tarea.Estado == "Cerrada")
                return ResultadoOperacion.Error("La tarea ya fue cerrada");

            tarea.Estado          = request.NuevoEstado;
            tarea.UltimaActualizacion = DateTime.Now;
            tarea.Observaciones   = request.Observaciones;

            if (request.NuevoEstado == "Cerrada")
                tarea.FechaCierre = DateTime.Now;

            return ResultadoOperacion.Exitoso(
                $"Estatus de tarea {tarea.Id} actualizado a '{request.NuevoEstado}'");
        }

        public ResultadoOperacion VerificarAlertas()
        {
            var tareasVencidas = _tareas
                .Where(t => t.Estado != "Cerrada" && DateTime.Now > t.FechaPlazo)
                .ToList();

            foreach (var tarea in tareasVencidas)
            {
                bool alertaExistente = _alertas.Any(a =>
                    a.TareaId == tarea.Id && !a.Atendida);

                if (!alertaExistente)
                {
                    _alertas.Add(new AlertaRetorno
                    {
                        Id          = _alertas.Count + 1,
                        TareaId     = tarea.Id,
                        Descripcion = $"Tarea de retorno {tarea.Id} ha vencido su plazo",
                        FechaAlerta = DateTime.Now,
                        Atendida    = false
                    });
                }
            }

            return ResultadoOperacion.Exitoso(
                $"Verificación completada. {tareasVencidas.Count} tareas vencidas alertadas");
        }

        public List<TareaRetorno> ConsultarSeguimiento(int audienciaId) =>
            _tareas
                .Where(t => t.AudienciaId == audienciaId)
                .OrderByDescending(t => t.FechaCreacion)
                .ToList();

        private ResponsableElegible? AsignarResponsable(string juezDestinoId)
        {
            return _responsables.FirstOrDefault(r =>
                r.UsuarioId == juezDestinoId && r.EstaDisponible) ??
                _responsables.FirstOrDefault(r => r.EstaDisponible && !r.EsCoordinador);
        }

        private void EscalarACoordinador(TareaRetorno tarea)
        {
            var coordinador = _responsables.FirstOrDefault(r => r.EsCoordinador && r.EstaDisponible);
            if (coordinador != null)
            {
                tarea.ResponsableId = coordinador.UsuarioId;
                tarea.EscaladaACoordinador = true;
            }
        }
    }

    public class GenerarTareaRequest
    {
        public int    AudienciaId   { get; set; }
        public string JuezOrigenId  { get; set; } = string.Empty;
        public string JuezDestinoId { get; set; } = string.Empty;
        public string UsuarioId     { get; set; } = string.Empty;
    }

    public class ActualizarEstatusRequest
    {
        public int    TareaId      { get; set; }
        public string NuevoEstado  { get; set; } = string.Empty;
        public string Observaciones { get; set; } = string.Empty;
    }

    public class TareaRetorno
    {
        public int      Id                    { get; set; }
        public int      AudienciaId           { get; set; }
        public string   JuezOrigenId          { get; set; } = string.Empty;
        public string   JuezDestinoId         { get; set; } = string.Empty;
        public string   ResponsableId         { get; set; } = string.Empty;
        public string   Estado                { get; set; } = string.Empty;
        public string   Descripcion           { get; set; } = string.Empty;
        public string   Observaciones         { get; set; } = string.Empty;
        public DateTime FechaCreacion         { get; set; }
        public DateTime FechaPlazo            { get; set; }
        public DateTime? UltimaActualizacion  { get; set; }
        public DateTime? FechaCierre          { get; set; }
        public bool     EscaladaACoordinador  { get; set; }
    }

    public class ResponsableElegible
    {
        public string UsuarioId      { get; set; } = string.Empty;
        public string Nombre         { get; set; } = string.Empty;
        public bool   EstaDisponible { get; set; }
        public bool   EsCoordinador  { get; set; }
    }

    public class ConfigSLA
    {
        public string TipoTarea   { get; set; } = string.Empty;
        public int    DiasMaximos { get; set; }
    }

    public class AlertaRetorno
    {
        public int      Id          { get; set; }
        public int      TareaId     { get; set; }
        public string   Descripcion { get; set; } = string.Empty;
        public DateTime FechaAlerta { get; set; }
        public bool     Atendida    { get; set; }
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
