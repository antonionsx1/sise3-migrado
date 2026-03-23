using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.AgregarResolucionAudiencia
{
    public class ResolucionAudienciaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public ResolucionAudienciaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion AgregarResolucion(AgregarResolucionRequest request)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            // CORRECCIÓN ERR-RES-001: Manejo de errores corregido
            // Se valida que la audiencia esté en estado "Celebrada"
            // antes de permitir agregar resoluciones
            if (audiencia.Estado != "Celebrada")
                return ResultadoOperacion.Error(
                    "ERR-RES-001: Solo se pueden agregar resoluciones a audiencias en estado Celebrada");

            if (string.IsNullOrEmpty(request.ResolucionId))
                return ResultadoOperacion.Error("Debe seleccionar una resolución");

            var resolucion = new Resolucion
            {
                Id            = audiencia.Resoluciones.Count + 1,
                ResolucionId  = request.ResolucionId,
                Descripcion   = request.Descripcion,
                FechaAgrego   = DateTime.Now,
                UsuarioAgrego = request.UsuarioAgrego
            };

            audiencia.Resoluciones.Add(resolucion);

            return ResultadoOperacion.Exitoso(
                $"Resolución agregada correctamente a la audiencia {audiencia.Id}");
        }

        public ResultadoOperacion EliminarResolucion(int audienciaId, int resolucionId)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null)
                return ResultadoOperacion.Error("No se encontró la audiencia indicada");

            var resolucion = audiencia.Resoluciones.FirstOrDefault(r => r.Id == resolucionId);
            if (resolucion == null)
                return ResultadoOperacion.Error("No se encontró la resolución indicada");

            audiencia.Resoluciones.Remove(resolucion);

            return ResultadoOperacion.Exitoso("Resolución eliminada correctamente");
        }

        public List<Resolucion> ObtenerResoluciones(int audienciaId)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            return audiencia?.Resoluciones ?? new List<Resolucion>();
        }
    }

    public class AgregarResolucionRequest
    {
        public int    AudienciaId   { get; set; }
        public string ResolucionId  { get; set; } = string.Empty;
        public string Descripcion   { get; set; } = string.Empty;
        public string UsuarioAgrego { get; set; } = string.Empty;
    }

    public class Resolucion
    {
        public int      Id            { get; set; }
        public string   ResolucionId  { get; set; } = string.Empty;
        public string   Descripcion   { get; set; } = string.Empty;
        public DateTime FechaAgrego   { get; set; }
        public string   UsuarioAgrego { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int    Id               { get; set; }
        public string Estado           { get; set; } = string.Empty;
        public string NumeroExpediente { get; set; } = string.Empty;
        public List<Resolucion> Resoluciones { get; set; } = new();
    }
}
