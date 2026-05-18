using Agenda.Application.Common.Models;

namespace Agenda.Application.Perfiles.Comandos.AgregarColaboradorRol
{
    public class AgregarColaboradorRolService
    {
        private readonly List<RolSistema>     _roles;
        private readonly List<Colaborador>    _colaboradores;
        private readonly List<AsignacionRol>  _asignaciones;

        public AgregarColaboradorRolService(
            List<RolSistema>    roles,
            List<Colaborador>   colaboradores,
            List<AsignacionRol> asignaciones)
        {
            _roles         = roles;
            _colaboradores = colaboradores;
            _asignaciones  = asignaciones;
        }

        public ResultadoBusqueda BuscarColaboradores(int rolId, string textoBusqueda)
        {
            var rol = _roles.FirstOrDefault(r => r.Id == rolId);
            if (rol == null)
                return ResultadoBusqueda.Error("No se encontró el rol indicado");

            var yaAsignados = _asignaciones
                .Where(a => a.RolId == rolId)
                .Select(a => a.ColaboradorId)
                .ToHashSet();

            var query = _colaboradores.AsEnumerable();

            query = query.Where(c => !yaAsignados.Contains(c.Id));

            if (!string.IsNullOrWhiteSpace(textoBusqueda))
                query = query.Where(c =>
                    c.NombreCompleto.Contains(textoBusqueda, StringComparison.OrdinalIgnoreCase));

            var resultados = query.Select(c => new ColaboradorSeleccionDto
            {
                Id             = c.Id,
                NombreCompleto = c.NombreCompleto,
                Seleccionado   = false
            }).ToList();

            return ResultadoBusqueda.Exitoso(resultados);
        }

        public ResultadoOperacion AgregarColaboradores(AgregarColaboradoresRolRequest request)
        {
            if (request.ColaboradoresIds == null || !request.ColaboradoresIds.Any())
                return ResultadoOperacion.Error(
                    "Debe seleccionar al menos un colaborador para agregar al rol");

            var rol = _roles.FirstOrDefault(r => r.Id == request.RolId);
            if (rol == null)
                return ResultadoOperacion.Error("No se encontró el rol indicado");

            var agregados = new List<string>();

            foreach (var colaboradorId in request.ColaboradoresIds)
            {
                var colaborador = _colaboradores.FirstOrDefault(c => c.Id == colaboradorId);
                if (colaborador == null) continue;

                bool yaAsignado = _asignaciones.Any(a =>
                    a.RolId == request.RolId && a.ColaboradorId == colaboradorId);

                if (!yaAsignado)
                {
                    _asignaciones.Add(new AsignacionRol
                    {
                        Id            = _asignaciones.Count + 1,
                        RolId         = request.RolId,
                        ColaboradorId = colaboradorId,
                        FechaAsignacion = DateTime.Now
                    });
                    agregados.Add(colaborador.NombreCompleto);
                }
            }

            if (!agregados.Any())
                return ResultadoOperacion.Error(
                    "Los colaboradores seleccionados ya están asignados al rol");

            var mensaje = agregados.Count == 1
                ? $"Se agregó {agregados[0]} al rol {rol.Nombre}"
                : $"Se agregaron {agregados.Count} colaboradores al rol {rol.Nombre}";

            return ResultadoOperacion.Exitoso(mensaje);
        }

        public List<ColaboradorAsignadoDto> ObtenerColaboradoresAsignados(int rolId)
        {
            return _asignaciones
                .Where(a => a.RolId == rolId)
                .Select(a =>
                {
                    var colaborador = _colaboradores.FirstOrDefault(c => c.Id == a.ColaboradorId);
                    return new ColaboradorAsignadoDto
                    {
                        AsignacionId   = a.Id,
                        ColaboradorId  = a.ColaboradorId,
                        NombreCompleto = colaborador?.NombreCompleto ?? string.Empty,
                        FechaAsignacion = a.FechaAsignacion.ToString("dd/MM/yyyy")
                    };
                }).ToList();
        }
    }

    public class AgregarColaboradoresRolRequest
    {
        public int          RolId            { get; set; }
        public List<string> ColaboradoresIds { get; set; } = new();
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

    public class ColaboradorSeleccionDto
    {
        public string Id             { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public bool   Seleccionado   { get; set; }
    }

    public class ColaboradorAsignadoDto
    {
        public int    AsignacionId   { get; set; }
        public string ColaboradorId  { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string FechaAsignacion { get; set; } = string.Empty;
    }

    public class ResultadoBusqueda
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;
        public List<ColaboradorSeleccionDto> Colaboradores { get; private set; } = new();

        public static ResultadoBusqueda Exitoso(List<ColaboradorSeleccionDto> colaboradores) =>
            new ResultadoBusqueda { Exito = true, Colaboradores = colaboradores };

        public static ResultadoBusqueda Error(string mensaje) =>
            new ResultadoBusqueda { Exito = false, Mensaje = mensaje };
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
