using Agenda.Application.Common.Models;

namespace Agenda.Application.Perfiles.Consulta.VistaGeneralPerfiles
{
    public class VistaGeneralPerfilesService
    {
        private readonly List<RolSistema>        _roles;
        private readonly List<ColaboradorRol>    _colaboradoresRol;
        private readonly List<ModuloPermiso>     _modulos;
        private readonly List<PermisoRol>        _permisosRol;

        public VistaGeneralPerfilesService(
            List<RolSistema>     roles,
            List<ColaboradorRol> colaboradoresRol,
            List<ModuloPermiso>  modulos,
            List<PermisoRol>     permisosRol)
        {
            _roles            = roles;
            _colaboradoresRol = colaboradoresRol;
            _modulos          = modulos;
            _permisosRol      = permisosRol;
        }

        public List<RolDto> ObtenerRoles() =>
            _roles.Select(r => new RolDto
            {
                Id     = r.Id,
                Nombre = r.Nombre,
                TotalColaboradores = _colaboradoresRol.Count(c => c.RolId == r.Id)
            }).ToList();

        public ResultadoDetalleRol ObtenerDetalleRol(int rolId)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == rolId);
            if (rol == null)
                return ResultadoDetalleRol.Error("No se encontró el rol indicado");

            var colaboradores = _colaboradoresRol
                .Where(c => c.RolId == rolId)
                .Select(c => new ColaboradorRolDto
                {
                    Id             = c.Id,
                    ColaboradorId  = c.ColaboradorId,
                    NombreCompleto = c.NombreCompleto,
                    RolId          = rolId
                }).ToList();

            var modulos = _modulos.Select(m => new ModuloPermisoDto
            {
                Id     = m.Id,
                Nombre = m.Nombre,
                Permisos = m.Permisos.Select(p => new PermisoDto
                {
                    Id       = p.Id,
                    Nombre   = p.Nombre,
                    Asignado = _permisosRol.Any(pr =>
                        pr.RolId == rolId && pr.PermisoId == p.Id)
                }).ToList()
            }).ToList();

            return ResultadoDetalleRol.Exitoso(rol.Nombre, colaboradores, modulos);
        }

        public ResultadoOperacion GuardarPermisos(GuardarPermisosRolRequest request)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == request.RolId);
            if (rol == null)
                return ResultadoOperacion.Error("No se encontró el rol indicado");

            // Remover permisos actuales del rol
            _permisosRol.RemoveAll(p => p.RolId == request.RolId);

            // Agregar los nuevos permisos seleccionados
            foreach (var permisoId in request.PermisosSeleccionados)
            {
                _permisosRol.Add(new PermisoRol
                {
                    Id       = _permisosRol.Count + 1,
                    RolId    = request.RolId,
                    PermisoId = permisoId
                });
            }

            return ResultadoOperacion.Exitoso(
                $"Permisos del rol '{rol.Nombre}' actualizados correctamente");
        }
    }

    public class RolSistema
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class ColaboradorRol
    {
        public int    Id             { get; set; }
        public int    RolId          { get; set; }
        public string ColaboradorId  { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
    }

    public class ModuloPermiso
    {
        public int             Id       { get; set; }
        public string          Nombre   { get; set; } = string.Empty;
        public List<Permiso>   Permisos { get; set; } = new();
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

    public class RolDto
    {
        public int    Id                 { get; set; }
        public string Nombre             { get; set; } = string.Empty;
        public int    TotalColaboradores { get; set; }
    }

    public class ColaboradorRolDto
    {
        public int    Id             { get; set; }
        public string ColaboradorId  { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public int    RolId          { get; set; }
    }

    public class ModuloPermisoDto
    {
        public int               Id       { get; set; }
        public string            Nombre   { get; set; } = string.Empty;
        public List<PermisoDto>  Permisos { get; set; } = new();
    }

    public class PermisoDto
    {
        public int    Id       { get; set; }
        public string Nombre   { get; set; } = string.Empty;
        public bool   Asignado { get; set; }
    }

    public class GuardarPermisosRolRequest
    {
        public int       RolId                { get; set; }
        public List<int> PermisosSeleccionados { get; set; } = new();
    }

    public class ResultadoDetalleRol
    {
        public bool   Exito       { get; private set; }
        public string Mensaje     { get; private set; } = string.Empty;
        public string NombreRol   { get; private set; } = string.Empty;
        public List<ColaboradorRolDto> Colaboradores { get; private set; } = new();
        public List<ModuloPermisoDto>  Modulos       { get; private set; } = new();

        public static ResultadoDetalleRol Exitoso(
            string nombre,
            List<ColaboradorRolDto> colaboradores,
            List<ModuloPermisoDto>  modulos) =>
            new ResultadoDetalleRol
            {
                Exito         = true,
                NombreRol     = nombre,
                Colaboradores = colaboradores,
                Modulos       = modulos
            };

        public static ResultadoDetalleRol Error(string mensaje) =>
            new ResultadoDetalleRol { Exito = false, Mensaje = mensaje };
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
