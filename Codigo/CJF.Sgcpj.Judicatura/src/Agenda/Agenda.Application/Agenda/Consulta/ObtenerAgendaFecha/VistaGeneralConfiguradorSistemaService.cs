using Agenda.Application.Common.Models;

namespace Agenda.Application.Configuracion.Consulta.VistaGeneralConfiguradorSistema
{
    public class VistaGeneralConfiguradorSistemaService
    {
        private readonly List<ConfiguracionAccion> _acciones;
        private readonly List<TipoArea>            _tiposArea;
        private readonly List<RolSistema>          _roles;
        private readonly List<PerfilSistema>       _perfiles;

        public VistaGeneralConfiguradorSistemaService(
            List<ConfiguracionAccion> acciones,
            List<TipoArea>            tiposArea,
            List<RolSistema>          roles,
            List<PerfilSistema>       perfiles)
        {
            _acciones  = acciones;
            _tiposArea = tiposArea;
            _roles     = roles;
            _perfiles  = perfiles;
        }

        public ResultadoVistaConfigurador ObtenerVista()
        {
            var unidadNotificadores = _acciones
                .FirstOrDefault(a => a.Clave == "UnidadNotificadoresComun");
            var correosAlerta = _acciones
                .FirstOrDefault(a => a.Clave == "CorreosAlerta");

            return new ResultadoVistaConfigurador
            {
                Secciones = new List<SeccionConfiguradorDto>
                {
                    new SeccionConfiguradorDto { Clave = "Areas",    Nombre = "Áreas",    TotalRegistros = _tiposArea.Count },
                    new SeccionConfiguradorDto { Clave = "Perfiles", Nombre = "Perfiles", TotalRegistros = _perfiles.Count },
                    new SeccionConfiguradorDto { Clave = "Roles",    Nombre = "Roles",    TotalRegistros = _roles.Count }
                },
                Acciones = new List<AccionConfiguradorDto>
                {
                    new AccionConfiguradorDto
                    {
                        Clave    = "UnidadNotificadoresComun",
                        Nombre   = "Unidad de Notificadores Común",
                        Activada = unidadNotificadores?.EstaActiva ?? false
                    },
                    new AccionConfiguradorDto
                    {
                        Clave    = "CorreosAlerta",
                        Nombre   = "Correos de alerta",
                        Activada = correosAlerta?.EstaActiva ?? false
                    }
                }
            };
        }

        public ResultadoOperacion ToggleAccion(ToggleAccionRequest request)
        {
            var accionesPermitidas = new[] { "UnidadNotificadoresComun", "CorreosAlerta" };
            if (!accionesPermitidas.Contains(request.ClaveAccion))
                return ResultadoOperacion.Error(
                    $"La acción '{request.ClaveAccion}' no es válida");

            var accion = _acciones.FirstOrDefault(a => a.Clave == request.ClaveAccion);

            if (accion == null)
            {
                _acciones.Add(new ConfiguracionAccion
                {
                    Clave     = request.ClaveAccion,
                    EstaActiva = request.Activar
                });
            }
            else
            {
                accion.EstaActiva = request.Activar;
            }

            var estado = request.Activar ? "activada" : "desactivada";
            return ResultadoOperacion.Exitoso(
                $"La acción '{request.ClaveAccion}' fue {estado} correctamente");
        }

        public ResultadoSeccion ObtenerSeccion(string claveSeccion)
        {
            return claveSeccion switch
            {
                "Areas"    => ResultadoSeccion.Exitoso("Áreas",    _tiposArea.Cast<object>().ToList()),
                "Perfiles" => ResultadoSeccion.Exitoso("Perfiles", _perfiles.Cast<object>().ToList()),
                "Roles"    => ResultadoSeccion.Exitoso("Roles",    _roles.Cast<object>().ToList()),
                _ => ResultadoSeccion.Error($"La sección '{claveSeccion}' no existe")
            };
        }
    }

    public class ToggleAccionRequest
    {
        public string ClaveAccion { get; set; } = string.Empty;
        public bool   Activar     { get; set; }
    }

    public class ConfiguracionAccion
    {
        public string Clave      { get; set; } = string.Empty;
        public bool   EstaActiva { get; set; }
    }

    public class TipoArea
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class RolSistema
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class PerfilSistema
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class SeccionConfiguradorDto
    {
        public string Clave          { get; set; } = string.Empty;
        public string Nombre         { get; set; } = string.Empty;
        public int    TotalRegistros { get; set; }
    }

    public class AccionConfiguradorDto
    {
        public string Clave    { get; set; } = string.Empty;
        public string Nombre   { get; set; } = string.Empty;
        public bool   Activada { get; set; }
    }

    public class ResultadoVistaConfigurador
    {
        public List<SeccionConfiguradorDto> Secciones { get; set; } = new();
        public List<AccionConfiguradorDto>  Acciones  { get; set; } = new();
    }

    public class ResultadoSeccion
    {
        public bool          Exito    { get; private set; }
        public string        Mensaje  { get; private set; } = string.Empty;
        public string        Nombre   { get; private set; } = string.Empty;
        public List<object>  Registros { get; private set; } = new();

        public static ResultadoSeccion Exitoso(string nombre, List<object> registros) =>
            new ResultadoSeccion { Exito = true, Nombre = nombre, Registros = registros };

        public static ResultadoSeccion Error(string mensaje) =>
            new ResultadoSeccion { Exito = false, Mensaje = mensaje };
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
