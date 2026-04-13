using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.NotificacionResolucionCJPF
{
    public class NotificacionResolucionCJPFService
    {
        private readonly List<ResolucionCJPF>    _resoluciones;
        private readonly List<EvidenciaEnvio>    _evidencias;
        private readonly List<ConfigCanal>       _canales;
        private readonly PoliticaReintentos      _politica;

        public NotificacionResolucionCJPFService(
            List<ResolucionCJPF> resoluciones,
            List<EvidenciaEnvio> evidencias,
            List<ConfigCanal>    canales,
            PoliticaReintentos   politica)
        {
            _resoluciones = resoluciones;
            _evidencias   = evidencias;
            _canales      = canales;
            _politica     = politica;
        }

        public ResultadoNotificacion NotificarResolucion(int resolucionId)
        {
            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == resolucionId);
            if (resolucion == null)
                return ResultadoNotificacion.Error("No se encontró la resolución indicada");

            if (resolucion.Estado != "Firmada")
                return ResultadoNotificacion.Error(
                    "Solo se pueden notificar resoluciones en estado Firmada");

            var resultados = new List<ResultadoEnvio>();

            foreach (var destinatario in resolucion.Destinatarios)
            {
                var resultado = EnviarConReintentos(resolucion, destinatario);
                resultados.Add(resultado);

                _evidencias.Add(new EvidenciaEnvio
                {
                    Id           = _evidencias.Count + 1,
                    ResolucionId = resolucion.Id,
                    Destinatario = destinatario.Email,
                    Exitoso      = resultado.Exitoso,
                    FechaEnvio   = DateTime.Now,
                    Intentos     = resultado.Intentos,
                    Error        = resultado.Error
                });
            }

            bool todosExitosos = resultados.All(r => r.Exitoso);
            int  exitosos      = resultados.Count(r => r.Exitoso);
            int  fallidos      = resultados.Count(r => !r.Exitoso);

            return ResultadoNotificacion.Exitoso(exitosos, fallidos);
        }

        public ResultadoNotificacion ReintentarEnvio(int evidenciaId)
        {
            var evidencia = _evidencias.FirstOrDefault(e => e.Id == evidenciaId);
            if (evidencia == null)
                return ResultadoNotificacion.Error("No se encontró la evidencia de envío");

            if (evidencia.Exitoso)
                return ResultadoNotificacion.Error("Este envío ya fue exitoso, no requiere reintento");

            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == evidencia.ResolucionId);
            if (resolucion == null)
                return ResultadoNotificacion.Error("No se encontró la resolución asociada");

            var destinatario = resolucion.Destinatarios
                .FirstOrDefault(d => d.Email == evidencia.Destinatario);

            if (destinatario == null)
                return ResultadoNotificacion.Error("Destinatario no encontrado");

            var resultado = EnviarNotificacion(resolucion, destinatario);
            evidencia.Exitoso    = resultado.Exitoso;
            evidencia.Intentos  += 1;
            evidencia.Error      = resultado.Error;
            evidencia.FechaEnvio = DateTime.Now;

            return resultado.Exitoso
                ? ResultadoNotificacion.Exitoso(1, 0)
                : ResultadoNotificacion.Error($"Reintento fallido: {resultado.Error}");
        }

        private ResultadoEnvio EnviarConReintentos(
            ResolucionCJPF resolucion, Destinatario destinatario)
        {
            if (string.IsNullOrEmpty(destinatario.Email) ||
                !destinatario.Email.Contains('@'))
                return new ResultadoEnvio
                {
                    Exitoso  = false,
                    Intentos = 0,
                    Error    = $"Destinatario inválido: {destinatario.Email}"
                };

            int intentos = 0;
            while (intentos < _politica.MaxReintentos)
            {
                intentos++;
                var resultado = EnviarNotificacion(resolucion, destinatario);
                if (resultado.Exitoso)
                    return new ResultadoEnvio { Exitoso = true, Intentos = intentos };

                if (intentos < _politica.MaxReintentos)
                    System.Threading.Thread.Sleep(_politica.EsperaEntreIntentosMs);
            }

            return new ResultadoEnvio
            {
                Exitoso  = false,
                Intentos = intentos,
                Error    = "Se agotaron los reintentos de envío"
            };
        }

        private ResultadoEnvio EnviarNotificacion(
            ResolucionCJPF resolucion, Destinatario destinatario)
        {
            var canal = _canales.FirstOrDefault(c => c.EstaActivo);
            if (canal == null)
                return new ResultadoEnvio { Exitoso = false, Error = "No hay canales activos" };

            // Simulación de envío
            return new ResultadoEnvio { Exitoso = true, Intentos = 1 };
        }
    }

    public class ResolucionCJPF
    {
        public int               Id              { get; set; }
        public string            TipoResolucion  { get; set; } = string.Empty;
        public string            Estado          { get; set; } = string.Empty;
        public List<Destinatario> Destinatarios  { get; set; } = new();
    }

    public class Destinatario
    {
        public string Nombre { get; set; } = string.Empty;
        public string Email  { get; set; } = string.Empty;
    }

    public class EvidenciaEnvio
    {
        public int      Id           { get; set; }
        public int      ResolucionId { get; set; }
        public string   Destinatario { get; set; } = string.Empty;
        public bool     Exitoso      { get; set; }
        public DateTime FechaEnvio   { get; set; }
        public int      Intentos     { get; set; }
        public string?  Error        { get; set; }
    }

    public class ConfigCanal
    {
        public string Nombre    { get; set; } = string.Empty;
        public bool   EstaActivo { get; set; }
    }

    public class PoliticaReintentos
    {
        public int MaxReintentos          { get; set; } = 3;
        public int EsperaEntreIntentosMs  { get; set; } = 1000;
    }

    public class ResultadoEnvio
    {
        public bool    Exitoso  { get; set; }
        public int     Intentos { get; set; }
        public string? Error    { get; set; }
    }

    public class ResultadoNotificacion
    {
        public bool   Exito    { get; private set; }
        public string Mensaje  { get; private set; } = string.Empty;
        public int    Exitosos { get; private set; }
        public int    Fallidos { get; private set; }

        public static ResultadoNotificacion Exitoso(int exitosos, int fallidos) =>
            new ResultadoNotificacion
            {
                Exito    = true,
                Exitosos = exitosos,
                Fallidos = fallidos,
                Mensaje  = $"Notificaciones enviadas: {exitosos} exitosas, {fallidos} fallidas"
            };

        public static ResultadoNotificacion Error(string mensaje) =>
            new ResultadoNotificacion { Exito = false, Mensaje = mensaje };
    }
}
