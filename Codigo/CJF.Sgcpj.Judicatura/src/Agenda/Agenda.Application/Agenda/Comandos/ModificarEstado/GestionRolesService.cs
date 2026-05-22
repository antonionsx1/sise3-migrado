using Agenda.Application.Common.Models;

namespace Agenda.Application.Perfiles.Comandos.GestionRoles
{
    public class GestionRolesService
    {
        private readonly List<RolSistema>    _roles;
        private readonly List<ModuloPermiso> _modulos;
        private readonly List<PermisoRol>    _permisosRol;

        public GestionRolesService(
            List<RolSistema>    roles,
            List<ModuloPermiso> modulos,
            List<PermisoRol>    permisosRol)
        {
            _roles       = roles;
            _modulos     = modulos;
            _permisosRol = permisosRol;
        }

        // ── Consulta ──────────────────────────────────────────────────────────

        public List<RolDto> ObtenerRoles() =>
            _roles.Select(r => new RolDto { Id = r.Id, Nombre = r.Nombre }).ToList();

        public ResultadoPermisosRol ObtenerPermisosRol(int rolId)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == rolId);
            if (rol == null)
                return ResultadoPermisosRol.Error("No se encontró el rol indicado");

            var permisosAsignados = _permisosRol
                .Where(p => p.RolId == rolId)
                .Select(p => p.PermisoId)
                .ToHashSet();

            var modulosDto = _modulos.Select(m => new ModuloDto
            {
                Id     = m.Id,
                Nombre = m.Nombre,
                TodosSeleccionados = m.Permisos.All(p => permisosAsignados.Contains(p.Id)),
                Permisos = m.Permisos.Select(p => new PermisoDto
                {
                    Id       = p.Id,
                    Nombre   = p.Nombre,
                    Asignado = permisosAsignados.Contains(p.Id)
                }).ToList()
            }).ToList();

            return ResultadoPermisosRol.Exitoso(rol.Nombre, modulosDto);
        }

        // ── Crear ─────────────────────────────────────────────────────────────

        public ResultadoOperacion CrearRol(CrearRolRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Nombre))
                return ResultadoOperacion.Error("El nombre del rol es requerido y no puede contener solo espacios");

            if (string.IsNullOrWhiteSpace(request.Pantalla))
                return ResultadoOperacion.Error("La pantalla del rol es requerida y no puede contener solo espacios");

            bool nombreDuplicado = _roles.Any(r =>
                r.Nombre.Equals(request.Nombre.Trim(), StringComparison.OrdinalIgnoreCase));

            if (nombreDuplicado)
                return ResultadoOperacion.Error(
                    $"Ya existe un rol con el nombre '{request.Nombre.Trim()}'");

            var nuevoRol = new RolSistema
            {
                Id      = _roles.Count + 1,
                Nombre  = request.Nombre.Trim(),
                Pantalla = request.Pantalla.Trim()
            };

            _roles.Add(nuevoRol);

            return ResultadoOperacion.Exitoso(
                $"Rol '{nuevoRol.Nombre}' creado correctamente");
        }

        // ── Editar ────────────────────────────────────────────────────────────

        public ResultadoOperacion EditarRol(EditarRolRequest request)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == request.RolId);
            if (rol == null)
                return ResultadoOperacion.Error("No se encontró el rol indicado");

            if (string.IsNullOrWhiteSpace(request.Nombre))
                return ResultadoOperacion.Error("El nombre del rol es requerido");

            if (string.IsNullOrWhiteSpace(request.Pantalla))
                return ResultadoOperacion.Error("La pantalla del rol es requerida");

            bool sinCambios = rol.Nombre == request.Nombre.Trim() &&
                              rol.Pantalla == request.Pantalla.Trim();

            if (sinCambios)
                return ResultadoOperacion.Error(
                    "No se detectaron cambios. Modifique la información antes de guardar");

            rol.Nombre   = request.Nombre.Trim();
            rol.Pantalla = request.Pantalla.Trim();

            return ResultadoOperacion.Exitoso(
                $"Rol '{rol.Nombre}' modificado correctamente");
        }

        // ── Eliminar ──────────────────────────────────────────────────────────

        public ResultadoOperacion EliminarRol(EliminarRolRequest request)
        {
            if (!request.Confirmado)
                return ResultadoOperacion.Error(
                    "Se requiere confirmación para eliminar el rol");

            var rol = _roles.FirstOrDefault(r => r.Id == request.RolId);
            if (rol == null)
                return ResultadoOperacion.Error("No se encontró el rol indicado");

            _permisosRol.RemoveAll(p => p.RolId == request.RolId);
            _roles.Remove(rol);

            return ResultadoOperacion.Exitoso(
                $"Rol '{rol.Nombre}' eliminado correctamente");
        }

        // ── Guardar permisos ──────────────────────────────────────────────────

        public ResultadoOperacion GuardarPermisosRol(GuardarPermisosRolRequest request)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == request.RolId);
            if (rol == null)
                return ResultadoOperacion.Error("No se encontró el rol indicado");

            var actuales = _permisosRol
                .Where(p => p.RolId == request.RolId)
                .Select(p => p.PermisoId)
                .OrderBy(id => id)
                .ToList();

            var nuevos = request.PermisosIds.OrderBy(id => id).ToList();

            if (actuales.SequenceEqual(nuevos))
                return ResultadoOperacion.Error(
                    "No se detectaron cambios en los permisos");

            _permisosRol.RemoveAll(p => p.RolId == request.RolId);

            foreach (var permisoId in request.PermisosIds)
                _permisosRol.Add(new PermisoRol
                {
                    Id       = _permisosRol.Count + 1,
                    RolId    = request.RolId,
                    PermisoId = permisoId
                });

            return ResultadoOperacion.Exitoso(
                $"Permisos del rol '{rol.Nombre}' guardados correctamente");
        }
    }

    // ── Request DTOs ──────────────────────────────────────────────────────────

    public class CrearRolRequest
    {
        public string Nombre   { get; set; } = string.Empty;
        public string Pantalla { get; set; } = string.Empty;
    }

    public class EditarRolRequest
    {
        public int    RolId    { get; set; }
        public string Nombre   { get; set; } = string.Empty;
        public string Pantalla { get; set; } = string.Empty;
    }

    public class EliminarRolRequest
    {
        public int  RolId      { get; set; }
        public bool Confirmado { get; set; }
    }

    public class GuardarPermisosRolRequest
    {
        public int       RolId       { get; set; }
        public List<int> PermisosIds { get; set; } = new();
    }

    // ── Entidades ─────────────────────────────────────────────────────────────

    public class RolSistema
    {
        public int    Id       { get; set; }
        public string Nombre   { get; set; } = string.Empty;
        public string Pantalla { get; set; } = string.Empty;
    }

    public class ModuloPermiso
    {
        public int           Id       { get; set; }
        public string        Nombre   { get; set; } = string.Empty;
        public List<Permiso> Permisos { get; set; } = new();
    }

    public class Permiso
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class PermisoRol
    {
        public int Id        { get; set; }
        public int RolId     { get; set; }
        public int PermisoId { get; set; }
    }

    // ── Response DTOs ─────────────────────────────────────────────────────────

    public class RolDto
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class ModuloDto
    {
        public int             Id                 { get; set; }
        public string          Nombre             { get; set; } = string.Empty;
        public bool            TodosSeleccionados { get; set; }
        public List<PermisoDto> Permisos          { get; set; } = new();
    }

    public class PermisoDto
    {
        public int    Id       { get; set; }
        public string Nombre   { get; set; } = string.Empty;
        public bool   Asignado { get; set; }
    }

    public class ResultadoPermisosRol
    {
        public bool           Exito    { get; private set; }
        public string         Mensaje  { get; private set; } = string.Empty;
        public string         NombreRol { get; private set; } = string.Empty;
        public List<ModuloDto> Modulos  { get; private set; } = new();

        public static ResultadoPermisosRol Exitoso(string nombreRol, List<ModuloDto> modulos) =>
            new ResultadoPermisosRol { Exito = true, NombreRol = nombreRol, Modulos = modulos };

        public static ResultadoPermisosRol Error(string mensaje) =>
            new ResultadoPermisosRol { Exito = false, Mensaje = mensaje };
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
