using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.AlertamientoAgenda
{
    public class AlertamientoAgendaService
    {
        private readonly List<Audiencia>    _audiencias;
        private readonly List<Recordatorio> _recordatorios;
        private readonly List<AlertaAgenda> _alertas;
        private readonly List<ConfiguracionAlerta> _configuraciones;

        public AlertamientoAgendaService(
            List<Audiencia>           audiencias,
            List<Recordatorio>        recordatorios,
            List<AlertaAgenda>        alertas,
            List<ConfiguracionAlerta> configuraciones)
        {
            _audiencias      = audiencias;
            _recordatorios   = recordatorios;
            _alertas         = alertas;
            _configuraciones = configuraciones;
        }

        public ResultadoOperacion GenerarAlertas(string usuarioId)
        {
            var alertasGeneradas = 0;

            // Generar alertas para audiencias próximas
            foreach (var audiencia in _audiencias.Where(a => a.Estado == "Programada"))
            {
                var config = ObtenerConfiguracion("Audiencia");
                if (config == null) continue;

                var fechaAlerta = audiencia.FechaHora.AddMinutes(-config.MinutosAnticipacion);

                bool yaExiste = _alertas.Any(a =>
                    a.ElementoId == audiencia.Id &&
                    a.TipoElemento == "Audiencia" &&
                    a.UsuarioId == usuarioId);

                if (!yaExiste && fechaAlerta > DateTime.Now)
                {
                    _alertas.Add(new AlertaAgenda
                    {
                        Id           = _alertas.Count + 1,
                        ElementoId   = audiencia.Id,
                        TipoElemento = "Audiencia",
                        UsuarioId    = usuarioId,
                        FechaAlerta  = fechaAlerta,
                        Descripcion  = $"Audiencia: {audiencia.TipoAudiencia} - " +
                                       $"Exp: {audiencia.NumeroExpediente}",
                        Atendida     = false
                    });
                    alertasGeneradas++;
                }
            }

            // Generar alertas para recordatorios
            foreach (var recordatorio in _recordatorios
                .Where(r => r.AsignadoA == usuarioId))
            {
                var config = ObtenerConfiguracion("Recordatorio");
                if (config == null) continue;

                var fechaAlerta = recordatorio.Fecha.AddMinutes(-config.MinutosAnticipacion);

                bool yaExiste = _alertas.Any(a =>
                    a.ElementoId == recordatorio.Id &&
                    a.TipoElemento == "Recordatorio" &&
                    a.UsuarioId == usuarioId);

                if (!yaExiste && fechaAlerta > DateTime.Now)
                {
                    _alertas.Add(new AlertaAgenda
                    {
                        Id           = _alertas.Count + 1,
                        ElementoId   = recordatorio.Id,
                        TipoElemento = "Recordatorio",
                        UsuarioId    = usuarioId,
                        FechaAlerta  = fechaAlerta,
                        Descripcion  = $"Recordatorio: {recordatorio.Descripcion} - " +
                                       $"Exp: {recordatorio.NumeroExpediente}",
                        Atendida     = false
                    });
                    alertasGeneradas++;
                }
            }

            MarcarAlertasVencidas();

            return ResultadoOperacion.Exitoso(
                $"Se generaron {alertasGeneradas} alertas para el usuario {usuarioId}");
        }

        public ResultadoOperacion MarcarComoAtendida(int alertaId, string usuarioId)
        {
            var alerta = _alertas.FirstOrDefault(a =>
                a.Id == alertaId && a.UsuarioId == usuarioId);

            if (alerta == null)
                return ResultadoOperacion.Error("No se encontró la alerta indicada");

            alerta.Atendida      = true;
            alerta.FechaAtendida = DateTime.Now;

            return ResultadoOperacion.Exitoso("Alerta marcada como atendida");
        }

        public ResultadoOperacion RecalcularAlertas(int audienciaId, DateTime nuevaFecha)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            audiencia.FechaHora = nuevaFecha;

            // Eliminar alertas anteriores de esta audiencia
            _alertas.RemoveAll(a =>
                a.ElementoId == audienciaId &&
                a.TipoElemento == "Audiencia" &&
                !a.Atendida);

            // Regenerar con nueva fecha
            var config = ObtenerConfiguracion("Audiencia");
            if (config != null)
            {
                var fechaAlerta = nuevaFecha.AddMinutes(-config.MinutosAnticipacion);
                if (fechaAlerta > DateTime.Now)
                {
                    _alertas.Add(new AlertaAgenda
                    {
                        Id           = _alertas.Count + 1,
                        ElementoId   = audienciaId,
                        TipoElemento = "Audiencia",
                        FechaAlerta  = fechaAlerta,
                        Descripcion  = $"Audiencia reagendada: {audiencia.TipoAudiencia}",
                        Atendida     = false
                    });
                }
            }

            return ResultadoOperacion.Exitoso("Alertas recalculadas correctamente");
        }

        public List<AlertaAgenda> ObtenerAlertasPendientes(string usuarioId)
        {
            return _alertas
                .Where(a => a.UsuarioId == usuarioId &&
                            !a.Atendida &&
                            a.FechaAlerta <= DateTime.Now.AddHours(1))
                .OrderBy(a => a.FechaAlerta)
                .ToList();
        }

        private void MarcarAlertasVencidas()
        {
            foreach (var alerta in _alertas.Where(a => !a.Atendida &&
                                                        a.FechaAlerta < DateTime.Now))
                alerta.Vencida = true;
        }

        private ConfiguracionAlerta? ObtenerConfiguracion(string tipoElemento) =>
            _configuraciones.FirstOrDefault(c => c.TipoElemento == tipoElemento);
    }

    public class AlertaAgenda
    {
        public int      Id           { get; set; }
        public int      ElementoId   { get; set; }
        public string   TipoElemento { get; set; } = string.Empty;
        public string   UsuarioId    { get; set; } = string.Empty;
        public DateTime FechaAlerta  { get; set; }
        public string   Descripcion  { get; set; } = string.Empty;
        public bool     Atendida     { get; set; }
        public bool     Vencida      { get; set; }
        public DateTime? FechaAtendida { get; set; }
    }

    public class ConfiguracionAlerta
    {
        public string TipoElemento        { get; set; } = string.Empty;
        public int    MinutosAnticipacion  { get; set; }
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

    public class Recordatorio
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime Fecha            { get; set; }
        public string   Descripcion      { get; set; } = string.Empty;
        public string   AsignadoA        { get; set; } = string.Empty;
    }
}
