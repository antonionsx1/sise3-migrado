using Agenda.Application.Common.Models;

namespace Agenda.Application.Seguridad.Comandos.PermisosPersonalizados
{
    public class PermisosPersonalizadosService
    {
        private readonly List<UsuarioSistema>      _usuarios;
        private readonly List<PermisoSistema>      _catalogoPermisos;
        private readonly List<AsignacionPermiso>   _asignaciones;
        private readonly List<IncompatibilidadPermiso> _incompatibilidades;
        private readonly List<BitacoraSeguridad>   _bitacora;

        public PermisosPersonalizadosService(
            List<UsuarioSistema>          usuarios,
            List<PermisoSistema>          catalogoPermisos,
            List<AsignacionPermiso>       asignaciones,
            List<IncompatibilidadPermiso> incompatibilidades,
            List<BitacoraSeguridad>       bitacora)
        {
            _usuarios            = usuarios;
            _catalogoPermisos    = catalogoPermisos;
            _asignaciones        = asignaciones;
            _incompatibilidades  = incompatibilidades;
            _bitacora            = bitacora;
        }

        public ResultadoOperacion AsignarPermisos(AsignarPermisosRequest request)
        {
            if (string.IsNullOrEmpty(request.UsuarioId) && string.IsNullOrEmpty(request.RolId))
                return ResultadoOperacion.Error("Debe especificar usuario o rol");

            if (!string.IsNullOrEmpty(request.UsuarioId))
            {
                var usuario = _usuarios.FirstOrDefault(u => u.Id == request.UsuarioId);
                if (usuario == null)
                    return ResultadoOperacion.Error(
                        "El usuario indicado no existe en el sistema");
            }

            if (!request.PermisosIds.Any())
                return ResultadoOperacion.Error("Debe seleccionar al menos un permiso");

            foreach (var permisoId in request.PermisosIds)
            {
                var permiso = _catalogoPermisos.FirstOrDefault(p => p.Id == permisoId);
                if (permiso == null)
                    return ResultadoOperacion.Error(
                        $"El permiso '{permisoId}' no existe en el catálogo vigente");
            }

            var conflicto = ValidarIncompatibilidades(request);
            if (!conflicto.Exito)
                return conflicto;

            var permisosAsignados = new List<string>();
            foreach (var permisoId in request.PermisosIds)
            {
                bool yaAsignado = _asignaciones.Any(a =>
                    a.PermisoId == permisoId &&
                    a.UsuarioId == request.UsuarioId &&
                    a.RolId == request.RolId &&
                    a.EstaActivo);

                if (!yaAsignado)
                {
                    _asignaciones.Add(new AsignacionPermiso
                    {
                        Id         = _asignaciones.Count + 1,
                        UsuarioId  = request.UsuarioId,
                        RolId      = request.RolId,
                        PermisoId  = permisoId,
                        AsignadoPor = request.AdministradorId,
                        FechaAsignacion = DateTime.Now,
                        EstaActivo = true
                    });
                    permisosAsignados.Add(permisoId);
                }
            }

            _bitacora.Add(new BitacoraSeguridad
            {
                Id             = _bitacora.Count + 1,
                Accion         = "AsignacionPermisos",
                UsuarioAfectado = request.UsuarioId,
                RolAfectado    = request.RolId,
                Permisos       = permisosAsignados,
                RealizadoPor   = request.AdministradorId,
                Fecha          = DateTime.Now
            });

            return ResultadoOperacion.Exitoso(
                $"Se asignaron {permisosAsignados.Count} permisos correctamente");
        }

        public ResultadoOperacion RevocarPermisos(RevocarPermisosRequest request)
        {
            var asignacionesActivas = _asignaciones
                .Where(a =>
                    a.UsuarioId == request.UsuarioId &&
                    request.PermisosIds.Contains(a.PermisoId) &&
                    a.EstaActivo)
                .ToList();

            if (!asignacionesActivas.Any())
                return ResultadoOperacion.Error("No se encontraron permisos activos para revocar");

            foreach (var asignacion in asignacionesActivas)
            {
                asignacion.EstaActivo   = false;
                asignacion.FechaRevocacion = DateTime.Now;
                asignacion.RevocadoPor  = request.AdministradorId;
            }

            _bitacora.Add(new BitacoraSeguridad
            {
                Id              = _bitacora.Count + 1,
                Accion          = "RevocacionPermisos",
                UsuarioAfectado = request.UsuarioId,
                Permisos        = request.PermisosIds,
                RealizadoPor    = request.AdministradorId,
                Fecha           = DateTime.Now
            });

            return ResultadoOperacion.Exitoso(
                $"Se revocaron {asignacionesActivas.Count} permisos correctamente");
        }

        public List<AsignacionPermiso> ConsultarPermisos(string usuarioId) =>
            _asignaciones
                .Where(a => a.UsuarioId == usuarioId && a.EstaActivo)
                .ToList();

        private ResultadoOperacion ValidarIncompatibilidades(AsignarPermisosRequest request)
        {
            var permisosActuales = _asignaciones
                .Where(a => a.UsuarioId == request.UsuarioId && a.EstaActivo)
                .Select(a => a.PermisoId)
                .ToList();

            var todosPermisos = permisosActuales.Concat(request.PermisosIds).ToList();

            foreach (var incompatibilidad in _incompatibilidades)
            {
                bool tieneA = todosPermisos.Contains(incompatibilidad.PermisoA);
                bool tieneB = todosPermisos.Contains(incompatibilidad.PermisoB);

                if (tieneA && tieneB)
                    return ResultadoOperacion.Error(
                        $"Conflicto detectado: los permisos '{incompatibilidad.PermisoA}' y " +
                        $"'{incompatibilidad.PermisoB}' son incompatibles. " +
                        "No es posible asignarlos simultáneamente");
            }

            return ResultadoOperacion.Exitoso(string.Empty);
        }
    }

    public class AsignarPermisosRequest
    {
        public string       UsuarioId       { get; set; } = string.Empty;
        public string       RolId           { get; set; } = string.Empty;
        public List<string> PermisosIds     { get; set; } = new();
        public string       AdministradorId { get; set; } = string.Empty;
    }

    public class RevocarPermisosRequest
    {
        public string       UsuarioId       { get; set; } = string.Empty;
        public List<string> PermisosIds     { get; set; } = new();
        public string       AdministradorId { get; set; } = string.Empty;
    }

    public class UsuarioSistema
    {
        public string Id     { get; set; } = string.Empty;
        public string Nombre { get; set; } = string.Empty;
        public bool   Activo { get; set; }
    }

    public class PermisoSistema
    {
        public string Id          { get; set; } = string.Empty;
        public string Nombre      { get; set; } = string.Empty;
        public string Modulo      { get; set; } = string.Empty;
        public bool   EstaVigente { get; set; }
    }

    public class AsignacionPermiso
    {
        public int      Id              { get; set; }
        public string   UsuarioId       { get; set; } = string.Empty;
        public string   RolId           { get; set; } = string.Empty;
        public string   PermisoId       { get; set; } = string.Empty;
        public string   AsignadoPor     { get; set; } = string.Empty;
        public DateTime FechaAsignacion { get; set; }
        public bool     EstaActivo      { get; set; }
        public DateTime? FechaRevocacion { get; set; }
        public string?  RevocadoPor     { get; set; }
    }

    public class IncompatibilidadPermiso
    {
        public string PermisoA { get; set; } = string.Empty;
        public string PermisoB { get; set; } = string.Empty;
    }

    public class BitacoraSeguridad
    {
        public int          Id              { get; set; }
        public string       Accion          { get; set; } = string.Empty;
        public string       UsuarioAfectado { get; set; } = string.Empty;
        public string       RolAfectado     { get; set; } = string.Empty;
        public List<string> Permisos        { get; set; } = new();
        public string       RealizadoPor    { get; set; } = string.Empty;
        public DateTime     Fecha           { get; set; }
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
