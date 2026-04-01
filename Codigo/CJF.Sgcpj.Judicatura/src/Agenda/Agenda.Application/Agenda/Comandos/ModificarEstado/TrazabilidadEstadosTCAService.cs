using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Comandos.TrazabilidadEstadosTCA
{
    public class TrazabilidadEstadosTCAService
    {
        private readonly List<Audiencia>        _audiencias;
        private readonly List<TransicionEstado> _transiciones;
        private readonly List<FlujosPermitidos> _flujosPermitidos;

        public TrazabilidadEstadosTCAService(
            List<Audiencia>        audiencias,
            List<TransicionEstado> transiciones,
            List<FlujosPermitidos> flujosPermitidos)
        {
            _audiencias       = audiencias;
            _transiciones     = transiciones;
            _flujosPermitidos = flujosPermitidos;
        }

        public ResultadoOperacion CambiarEstado(CambiarEstadoTCARequest request)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            // CORRECCIÓN ERR-TRZ-001: Comentario corregido
            // Valida que la transición de estado esté permitida en el flujo definido por negocio
            bool transicionPermitida = _flujosPermitidos.Any(f =>
                f.EstadoOrigen == audiencia.Estado &&
                f.EstadoDestino == request.NuevoEstado);

            if (!transicionPermitida)
                return ResultadoOperacion.Error(
                    $"La transición de '{audiencia.Estado}' a '{request.NuevoEstado}' " +
                    "no está permitida en el flujo definido");

            // CORRECCIÓN ERR-TRZ-002: Comentario corregido
            // Registra la nueva transición en el historial de trazabilidad con sello de tiempo
            var estadoAnterior = audiencia.Estado;
            audiencia.Estado = request.NuevoEstado;

            _transiciones.Add(new TransicionEstado
            {
                Id              = _transiciones.Count + 1,
                AudienciaId     = audiencia.Id,
                EstadoAnterior  = estadoAnterior,
                EstadoNuevo     = request.NuevoEstado,
                UsuarioId       = request.UsuarioId,
                FechaTransicion = DateTime.Now,
                Motivo          = request.Motivo
            });

            return ResultadoOperacion.Exitoso(
                $"Estado de audiencia actualizado a '{request.NuevoEstado}' correctamente");
        }

        public List<TransicionEstado> ObtenerHistorial(int audienciaId) =>
            _transiciones
                .Where(t => t.AudienciaId == audienciaId)
                .OrderByDescending(t => t.FechaTransicion)
                .ToList();

        public List<string> ObtenerTransicionesPermitidas(string estadoActual) =>
            _flujosPermitidos
                .Where(f => f.EstadoOrigen == estadoActual)
                .Select(f => f.EstadoDestino)
                .ToList();
    }

    public class CambiarEstadoTCARequest
    {
        public int    AudienciaId   { get; set; }
        public string NuevoEstado   { get; set; } = string.Empty;
        public string UsuarioId     { get; set; } = string.Empty;
        public string Motivo        { get; set; } = string.Empty;
        public string VersionActual { get; set; } = string.Empty;
    }

    public class TransicionEstado
    {
        public int      Id              { get; set; }
        public int      AudienciaId     { get; set; }
        public string   EstadoAnterior  { get; set; } = string.Empty;
        public string   EstadoNuevo     { get; set; } = string.Empty;
        public string   UsuarioId       { get; set; } = string.Empty;
        public DateTime FechaTransicion { get; set; }
        public string   Motivo          { get; set; } = string.Empty;
    }

    public class FlujosPermitidos
    {
        public string EstadoOrigen  { get; set; } = string.Empty;
        public string EstadoDestino { get; set; } = string.Empty;
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
