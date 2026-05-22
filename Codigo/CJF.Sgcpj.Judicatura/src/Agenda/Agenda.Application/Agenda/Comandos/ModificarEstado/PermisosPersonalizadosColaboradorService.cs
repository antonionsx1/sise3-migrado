using Agenda.Application.Common.Models;

namespace Agenda.Application.Perfiles.Comandos.PermisosPersonalizados
{
    public class PermisosPersonalizadosColaboradorService
    {
        private readonly List<RolSistema>           _roles;
        private readonly List<Colaborador>          _colaboradores;
        private readonly List<PermisoRol>           _permisosRol;
        private readonly List<PermisoPersonalizado> _permisosPersonalizados;

        public PermisosPersonalizadosColaboradorService(
            List<RolSistema>           roles,
            List<Colaborador>          colaboradores,
            List<PermisoRol>           permisosRol,
            List<PermisoPersonalizado> permisosPersonalizados)
        {
            _roles                  = roles;
            _colaboradores          = colaboradores;
            _permisosRol            = permisosRol;
            _permisosPersonalizados = permisosPersonalizados;
        }

        public ResultadoPermisosColaborador ObtenerPermisosColaborador(
            int rolId, string colaboradorId)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == rolId);
            if (rol == null)
                return ResultadoPermisosColaborador.Error("No se encontró el rol indicado");

            var colaborador = _colaboradores.FirstOrDefault(c => c.Id == colaboradorId);
            if (colaborador == null)
                return ResultadoPermisosColaborador.Error("No se encontró el colaborador indicado");

            var permisosBase = _permisosRol
                .Where(p => p.RolId == rolId)
                .Select(p => p.PermisoId)
                .ToHashSet();

            var personalizados = _permisosPersonalizados
                .Where(p => p.ColaboradorId == colaboradorId && p.RolId == rolId)
                .ToList();

            var permisosActivos = personalizados.Any()
                ? personalizados.Select(p => p.PermisoId).ToHashSet()
                : permisosBase;

            return ResultadoPermisosColaborador.Exitoso(
                colaborador.NombreCompleto, rol.Nombre, permisosActivos.ToList());
        }

        public ResultadoOperacion GuardarPermisosPersonalizados(
            GuardarPermisosRequest request)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == request.RolId);
            if (rol == null)
                return ResultadoOperacion.Error("No se encontró el rol indicado");

            var colaborador = _colaboradores
                .FirstOrDefault(c => c.Id == request.ColaboradorId);
            if (colaborador == null)
                return ResultadoOperacion.Error("No se encontró el colaborador indicado");

            // CORRECCIÓN ERR-PER-002: Manejo de errores corregido
            // Se valida si hubo cambios reales antes de guardar
            if (!TieneCambiosSinGuardar(request.ColaboradorId, request.RolId, request.PermisosIds))
                return ResultadoOperacion.Error(
                    "ERR-PER-002: No se detectaron cambios en los permisos. " +
                    "Modifique los permisos antes de guardar");

            // CORRECCIÓN ERR-PER-003: Operador lógico corregido
            // Se usa || para validar correctamente si la lista es nula O vacía
            if (request.PermisosIds == null || !request.PermisosIds.Any())
                return ResultadoOperacion.Error(
                    "ERR-PER-003: Debe seleccionar al menos un permiso o cancelar la edición");

            _permisosPersonalizados.RemoveAll(p =>
                p.ColaboradorId == request.ColaboradorId && p.RolId == request.RolId);

            foreach (var permisoId in request.PermisosIds)
            {
                _permisosPersonalizados.Add(new PermisoPersonalizado
                {
                    Id                = _permisosPersonalizados.Count + 1,
                    ColaboradorId     = request.ColaboradorId,
                    RolId             = request.RolId,
                    PermisoId         = permisoId,
                    FechaModificacion = DateTime.Now
                });
            }

            return ResultadoOperacion.Exitoso(
                $"Los privilegios de '{colaborador.NombreCompleto}' han sido almacenados exitosamente");
        }

        public bool TieneCambiosSinGuardar(
            string colaboradorId, int rolId, List<int> permisosActuales)
        {
            var guardados = _permisosPersonalizados
                .Where(p => p.ColaboradorId == colaboradorId && p.RolId == rolId)
                .Select(p => p.PermisoId)
                .OrderBy(id => id)
                .ToList();

            var actuales = permisosActuales.OrderBy(id => id).ToList();
            return !guardados.SequenceEqual(actuales);
        }
    }

    public class GuardarPermisosRequest
    {
        public int       RolId         { get; set; }
        public string    ColaboradorId { get; set; } = string.Empty;
        public List<int> PermisosIds   { get; set; } = new();
    }

    public class RolSistema
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class Colaborador
    {
        public string Id             { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
    }

    public class PermisoRol
    {
        public int RolId     { get; set; }
        public int PermisoId { get; set; }
    }

    public class PermisoPersonalizado
    {
        public int      Id                { get; set; }
        public string   ColaboradorId     { get; set; } = string.Empty;
        public int      RolId             { get; set; }
        public int      PermisoId         { get; set; }
        public DateTime FechaModificacion { get; set; }
    }

    public class ResultadoPermisosColaborador
    {
        public bool      Exito             { get; private set; }
        public string    Mensaje           { get; private set; } = string.Empty;
        public string    NombreColaborador { get; private set; } = string.Empty;
        public string    NombreRol         { get; private set; } = string.Empty;
        public List<int> PermisosActivos   { get; private set; } = new();

        public static ResultadoPermisosColaborador Exitoso(
            string nombreColaborador, string nombreRol, List<int> permisos) =>
            new ResultadoPermisosColaborador
            {
                Exito             = true,
                NombreColaborador = nombreColaborador,
                NombreRol         = nombreRol,
                PermisosActivos   = permisos
            };

        public static ResultadoPermisosColaborador Error(string mensaje) =>
            new ResultadoPermisosColaborador { Exito = false, Mensaje = mensaje };
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
