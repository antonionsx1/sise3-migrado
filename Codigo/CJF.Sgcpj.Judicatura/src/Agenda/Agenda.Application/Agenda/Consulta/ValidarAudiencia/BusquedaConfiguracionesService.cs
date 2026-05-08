using Agenda.Application.Common.Models;

namespace Agenda.Application.Configuracion.Consulta.BusquedaConfiguraciones
{
    public class BusquedaConfiguracionesService
    {
        private readonly List<ConfiguracionSistema> _configuraciones;
        private readonly List<PermisoAdministrador> _permisos;

        public BusquedaConfiguracionesService(
            List<ConfiguracionSistema> configuraciones,
            List<PermisoAdministrador> permisos)
        {
            _configuraciones = configuraciones;
            _permisos        = permisos;
        }

        public ResultadoBusqueda Buscar(BusquedaConfigRequest request, string usuarioId)
        {
            if (!TienePermisoAdministracion(usuarioId))
                return ResultadoBusqueda.Denegado(
                    "No cuenta con permisos de administración para acceder a las configuraciones");

            if (!string.IsNullOrEmpty(request.Clave) && request.Clave.Length < 2)
                return ResultadoBusqueda.Error(
                    "El criterio de búsqueda por clave debe tener al menos 2 caracteres");

            var query = _configuraciones.AsEnumerable();

            if (!string.IsNullOrEmpty(request.Clave))
                query = query.Where(c =>
                    c.Clave.Contains(request.Clave, StringComparison.OrdinalIgnoreCase) ||
                    c.Descripcion.Contains(request.Clave, StringComparison.OrdinalIgnoreCase));

            if (!string.IsNullOrEmpty(request.Modulo))
                query = query.Where(c => c.Modulo == request.Modulo);

            if (request.SoloActivas.HasValue)
                query = query.Where(c => c.EstaActiva == request.SoloActivas.Value);

            var resultados = query.Select(c => new ConfiguracionDto
            {
                Id          = c.Id,
                Clave       = c.Clave,
                Descripcion = c.Descripcion,
                Valor       = c.Valor,
                Modulo      = c.Modulo,
                EstaActiva  = c.EstaActiva,
                UltimaModificacion = c.UltimaModificacion.ToString("dd/MM/yyyy HH:mm")
            }).ToList();

            if (!resultados.Any())
                return ResultadoBusqueda.SinResultados();

            return ResultadoBusqueda.Exitoso(resultados);
        }

        public List<string> ObtenerModulos() =>
            _configuraciones
                .Select(c => c.Modulo)
                .Distinct()
                .OrderBy(m => m)
                .ToList();

        private bool TienePermisoAdministracion(string usuarioId) =>
            _permisos.Any(p => p.UsuarioId == usuarioId && p.PuedeAdministrar);
    }

    public class BusquedaConfigRequest
    {
        public string Clave        { get; set; } = string.Empty;
        public string Modulo       { get; set; } = string.Empty;
        public bool?  SoloActivas  { get; set; }
    }

    public class ConfiguracionSistema
    {
        public int      Id                 { get; set; }
        public string   Clave              { get; set; } = string.Empty;
        public string   Descripcion        { get; set; } = string.Empty;
        public string   Valor              { get; set; } = string.Empty;
        public string   Modulo             { get; set; } = string.Empty;
        public bool     EstaActiva         { get; set; }
        public DateTime UltimaModificacion { get; set; }
    }

    public class ConfiguracionDto
    {
        public int    Id                 { get; set; }
        public string Clave              { get; set; } = string.Empty;
        public string Descripcion        { get; set; } = string.Empty;
        public string Valor              { get; set; } = string.Empty;
        public string Modulo             { get; set; } = string.Empty;
        public bool   EstaActiva         { get; set; }
        public string UltimaModificacion { get; set; } = string.Empty;
    }

    public class PermisoAdministrador
    {
        public string UsuarioId       { get; set; } = string.Empty;
        public bool   PuedeAdministrar { get; set; }
    }

    public class ResultadoBusqueda
    {
        public bool   Exito     { get; private set; }
        public string Mensaje   { get; private set; } = string.Empty;
        public List<ConfiguracionDto> Resultados { get; private set; } = new();

        public static ResultadoBusqueda Exitoso(List<ConfiguracionDto> resultados) =>
            new ResultadoBusqueda { Exito = true, Resultados = resultados };

        public static ResultadoBusqueda SinResultados() =>
            new ResultadoBusqueda
            {
                Exito   = true,
                Mensaje = "No se encontraron configuraciones con los criterios indicados"
            };

        public static ResultadoBusqueda Denegado(string mensaje) =>
            new ResultadoBusqueda { Exito = false, Mensaje = mensaje };

        public static ResultadoBusqueda Error(string mensaje) =>
            new ResultadoBusqueda { Exito = false, Mensaje = mensaje };
    }
}
