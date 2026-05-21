using Agenda.Application.Common.Models;

namespace Agenda.Application.Perfiles.Comandos.DesvincularColaboradorRol
{
    public class DesvincularColaboradorRolService
    {
        private readonly List<RolSistema>    _roles;
        private readonly List<Colaborador>   _colaboradores;
        private readonly List<AsignacionRol> _asignaciones;

        public DesvincularColaboradorRolService(
            List<RolSistema>    roles,
            List<Colaborador>   colaboradores,
            List<AsignacionRol> asignaciones)
        {
            _roles         = roles;
            _colaboradores = colaboradores;
            _asignaciones  = asignaciones;
        }

        public ResultadoOperacion Desvincular(DesvincularRequest request)
        {
            if (!request.Confirmado)
                return ResultadoOperacion.Error(
                    "Se requiere confirmación para desvincular al colaborador del rol");

            var asignacion = _asignaciones.FirstOrDefault(a => a.Id == request.AsignacionId);
            if (asignacion == null)
                return ResultadoOperacion.Error(
                    "No se encontró la asignación indicada");

            var rol = _roles.FirstOrDefault(r => r.Id == asignacion.RolId);
            if (rol == null)
                return ResultadoOperacion.Error("No se encontró el rol asociado");

            var colaborador = _colaboradores
                .FirstOrDefault(c => c.Id == asignacion.ColaboradorId);

            _asignaciones.Remove(asignacion);

            return ResultadoOperacion.Exitoso(
                $"El colaborador '{colaborador?.NombreCompleto ?? asignacion.ColaboradorId}' " +
                $"fue desvinculado del rol '{rol.Nombre}' correctamente");
        }

        public List<ColaboradorRolDto> ObtenerColaboradoresPorRol(int rolId)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == rolId);
            if (rol == null) return new List<ColaboradorRolDto>();

            return _asignaciones
                .Where(a => a.RolId == rolId)
                .Select(a =>
                {
                    var colaborador = _colaboradores.FirstOrDefault(c => c.Id == a.ColaboradorId);
                    return new ColaboradorRolDto
                    {
                        AsignacionId   = a.Id,
                        ColaboradorId  = a.ColaboradorId,
                        NombreCompleto = colaborador?.NombreCompleto ?? string.Empty,
                        RolId          = rolId,
                        NombreRol      = rol.Nombre
                    };
                }).ToList();
        }
    }

    public class DesvincularRequest
    {
        public int  AsignacionId { get; set; }
        public bool Confirmado   { get; set; }
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

    public class AsignacionRol
    {
        public int      Id              { get; set; }
        public int      RolId           { get; set; }
        public string   ColaboradorId   { get; set; } = string.Empty;
        public DateTime FechaAsignacion { get; set; }
    }

    public class ColaboradorRolDto
    {
        public int    AsignacionId   { get; set; }
        public string ColaboradorId  { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public int    RolId          { get; set; }
        public string NombreRol      { get; set; } = string.Empty;
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
