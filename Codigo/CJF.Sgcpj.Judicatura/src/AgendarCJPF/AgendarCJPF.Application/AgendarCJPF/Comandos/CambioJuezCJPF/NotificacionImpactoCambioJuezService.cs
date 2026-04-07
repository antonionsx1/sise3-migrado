using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.NotificacionImpactoCambioJuez
{
    public class NotificacionImpactoCambioJuezService
    {
        private readonly List<AudienciaCJPF>       _audiencias;
        private readonly List<TareaRelacionada>    _tareas;
        private readonly List<TrazaCambioJuez>     _trazas;
        private readonly List<DependenciaAudiencia> _dependencias;
        private readonly List<CanalNotificacion>   _canales;

        public NotificacionImpactoCambioJuezService(
            List<AudienciaCJPF>        audiencias,
            List<TareaRelacionada>     tareas,
            List<TrazaCambioJuez>      trazas,
            List<DependenciaAudiencia> dependencias,
            List<CanalNotificacion>    canales)
        {
            _audiencias    = audiencias;
            _tareas        = tareas;
            _trazas        = trazas;
            _dependencias  = dependencias;
            _canales       = canales;
        }

        public ResultadoImpacto ProcesarCambioJuez(CambioJuezImpactoRequest request)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoImpacto.Error("No se encontró la audiencia indicada");

            var juezAnterior = audiencia.JuezAsignado;

            // Registrar trazabilidad
            _trazas.Add(new TrazaCambioJuez
            {
                Id              = _trazas.Count + 1,
                AudienciaId     = audiencia.Id,
                JuezAnterior    = juezAnterior,
                JuezNuevo       = request.JuezNuevoId,
                Motivo          = request.Motivo,
                UsuarioId       = request.UsuarioId,
                FechaCambio     = DateTime.Now,
                EsReversionn    = request.EsReversion
            });

            audiencia.JuezAsignado = request.JuezNuevoId;

            // Recalcular tareas relacionadas
            var resultadosTareas = RecalcularTareas(audiencia, request);

            // Notificar a roles afectados
            var notificaciones = NotificarRolesAfectados(
                audiencia, juezAnterior, request.JuezNuevoId, request.EsReversion);

            return ResultadoImpacto.Exitoso(
                tareasRecalculadas: resultadosTareas.Count(r => r.Recalculada),
                tareasParaRevision: resultadosTareas.Count(r => !r.Recalculada),
                notificacionesEnviadas: notificaciones);
        }

        private List<ResultadoRecalculo> RecalcularTareas(
            AudienciaCJPF audiencia, CambioJuezImpactoRequest request)
        {
            var resultados = new List<ResultadoRecalculo>();

            var tareasAfectadas = _tareas
                .Where(t => t.AudienciaId == audiencia.Id && t.Estado != "Completada")
                .ToList();

            foreach (var tarea in tareasAfectadas)
            {
                var dependencia = _dependencias.FirstOrDefault(d =>
                    d.TipoTarea == tarea.Tipo && d.RequiereJuezEspecifico);

                if (dependencia != null && !dependencia.PuedeReasignarse)
                {
                    tarea.Estado = "PendienteRevision";
                    resultados.Add(new ResultadoRecalculo
                    {
                        TareaId      = tarea.Id,
                        Recalculada  = false,
                        Motivo       = "La tarea no puede reasignarse automáticamente"
                    });
                }
                else
                {
                    tarea.ResponsableId = request.JuezNuevoId;
                    resultados.Add(new ResultadoRecalculo
                    {
                        TareaId     = tarea.Id,
                        Recalculada = true
                    });
                }
            }

            return resultados;
        }

        private int NotificarRolesAfectados(
            AudienciaCJPF audiencia, string juezAnterior,
            string juezNuevo, bool esReversion)
        {
            var canal = _canales.FirstOrDefault(c => c.EstaActivo);
            if (canal == null) return 0;

            var mensaje = esReversion
                ? $"Reversion de cambio de juez en audiencia {audiencia.Id}: " +
                  $"{juezNuevo} -> {juezAnterior}"
                : $"Cambio de juez en audiencia {audiencia.Id}: " +
                  $"{juezAnterior} -> {juezNuevo}";

            // Simular envío a roles afectados: juez anterior, juez nuevo, secretario
            var rolesNotificados = new[] { juezAnterior, juezNuevo, audiencia.SecretarioId };
            Console.WriteLine($"Notificando: {mensaje} a {rolesNotificados.Length} roles");

            return rolesNotificados.Length;
        }
    }

    public class CambioJuezImpactoRequest
    {
        public int    AudienciaId  { get; set; }
        public string JuezNuevoId  { get; set; } = string.Empty;
        public string Motivo       { get; set; } = string.Empty;
        public string UsuarioId    { get; set; } = string.Empty;
        public bool   EsReversion  { get; set; }
    }

    public class AudienciaCJPF
    {
        public int    Id            { get; set; }
        public string JuezAsignado  { get; set; } = string.Empty;
        public string SecretarioId  { get; set; } = string.Empty;
        public string Estado        { get; set; } = string.Empty;
    }

    public class TareaRelacionada
    {
        public int    Id            { get; set; }
        public int    AudienciaId   { get; set; }
        public string Tipo          { get; set; } = string.Empty;
        public string Estado        { get; set; } = string.Empty;
        public string ResponsableId { get; set; } = string.Empty;
    }

    public class TrazaCambioJuez
    {
        public int      Id           { get; set; }
        public int      AudienciaId  { get; set; }
        public string   JuezAnterior { get; set; } = string.Empty;
        public string   JuezNuevo    { get; set; } = string.Empty;
        public string   Motivo       { get; set; } = string.Empty;
        public string   UsuarioId    { get; set; } = string.Empty;
        public DateTime FechaCambio  { get; set; }
        public bool     EsReversionn { get; set; }
    }

    public class DependenciaAudiencia
    {
        public string TipoTarea              { get; set; } = string.Empty;
        public bool   RequiereJuezEspecifico { get; set; }
        public bool   PuedeReasignarse       { get; set; }
    }

    public class CanalNotificacion
    {
        public string Nombre    { get; set; } = string.Empty;
        public bool   EstaActivo { get; set; }
    }

    public class ResultadoRecalculo
    {
        public int    TareaId    { get; set; }
        public bool   Recalculada { get; set; }
        public string Motivo     { get; set; } = string.Empty;
    }

    public class ResultadoImpacto
    {
        public bool   Exito                   { get; private set; }
        public string Mensaje                 { get; private set; } = string.Empty;
        public int    TareasRecalculadas       { get; private set; }
        public int    TareasParaRevision       { get; private set; }
        public int    NotificacionesEnviadas   { get; private set; }

        public static ResultadoImpacto Exitoso(
            int tareasRecalculadas, int tareasParaRevision, int notificacionesEnviadas) =>
            new ResultadoImpacto
            {
                Exito                 = true,
                TareasRecalculadas    = tareasRecalculadas,
                TareasParaRevision    = tareasParaRevision,
                NotificacionesEnviadas = notificacionesEnviadas,
                Mensaje = $"Impacto procesado: {tareasRecalculadas} tareas recalculadas, " +
                          $"{tareasParaRevision} para revisión, " +
                          $"{notificacionesEnviadas} notificaciones enviadas"
            };

        public static ResultadoImpacto Error(string mensaje) =>
            new ResultadoImpacto { Exito = false, Mensaje = mensaje };
    }
}
