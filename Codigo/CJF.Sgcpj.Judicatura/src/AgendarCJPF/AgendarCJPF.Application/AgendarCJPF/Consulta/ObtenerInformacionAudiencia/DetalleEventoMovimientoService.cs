using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.DetalleEventoMovimiento
{
    public class DetalleEventoMovimientoService
    {
        private readonly List<EventoMovimiento> _eventos;

        public DetalleEventoMovimientoService(List<EventoMovimiento> eventos)
        {
            _eventos = eventos;
        }

        public ResultadoEventos ObtenerDetalle(int audienciaId, FiltroEventoRequest filtro)
        {
            var query = _eventos.Where(e => e.AudienciaId == audienciaId);

            if (!string.IsNullOrEmpty(filtro.TipoEvento))
                query = query.Where(e => e.TipoEvento == filtro.TipoEvento);

            // ERROR ERR-EVT-001: Comentario incorrecto
            // El comentario dice "orden descendente" pero el código ordena
            // de forma ascendente (más antiguo primero)
            // Ordenar de forma descendente (más reciente primero)
            var eventos = filtro.OrdenCronologico
                ? query.OrderBy(e => e.FechaEvento).ToList()
                : query.OrderByDescending(e => e.FechaEvento).ToList();

            if (!eventos.Any())
                return ResultadoEventos.HistorialVacio();

            return ResultadoEventos.Exitoso(eventos.Select(e => new EventoMovimientoDto
            {
                Id          = e.Id,
                TipoEvento  = e.TipoEvento,
                FechaEvento = e.FechaEvento.ToString("dd/MM/yyyy HH:mm:ss"),
                Usuario     = e.Usuario,
                Comentario  = string.IsNullOrEmpty(e.Comentario) ? string.Empty : e.Comentario
            }).ToList());
        }

        public List<string> ObtenerTiposEvento(int audienciaId) =>
            _eventos
                .Where(e => e.AudienciaId == audienciaId)
                .Select(e => e.TipoEvento)
                .Distinct()
                .OrderBy(t => t)
                .ToList();
    }

    public class FiltroEventoRequest
    {
        public string TipoEvento        { get; set; } = string.Empty;
        public bool   OrdenCronologico  { get; set; } = true;
    }

    public class EventoMovimiento
    {
        public int      Id          { get; set; }
        public int      AudienciaId { get; set; }
        public string   TipoEvento  { get; set; } = string.Empty;
        public DateTime FechaEvento { get; set; }
        public string   Usuario     { get; set; } = string.Empty;
        public string   Comentario  { get; set; } = string.Empty;
    }

    public class EventoMovimientoDto
    {
        public int    Id          { get; set; }
        public string TipoEvento  { get; set; } = string.Empty;
        public string FechaEvento { get; set; } = string.Empty;
        public string Usuario     { get; set; } = string.Empty;
        public string Comentario  { get; set; } = string.Empty;
    }

    public class ResultadoEventos
    {
        public bool   Exito    { get; private set; }
        public string Mensaje  { get; private set; } = string.Empty;
        public List<EventoMovimientoDto> Eventos { get; private set; } = new();

        public static ResultadoEventos Exitoso(List<EventoMovimientoDto> eventos) =>
            new ResultadoEventos { Exito = true, Eventos = eventos };

        public static ResultadoEventos HistorialVacio() =>
            new ResultadoEventos { Exito = true, Mensaje = "No hay eventos registrados" };

        public static ResultadoEventos Error(string mensaje) =>
            new ResultadoEventos { Exito = false, Mensaje = mensaje };
    }
}
