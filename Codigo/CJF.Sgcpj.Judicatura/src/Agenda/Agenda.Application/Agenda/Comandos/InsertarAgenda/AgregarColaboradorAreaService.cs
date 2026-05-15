using Agenda.Application.Common.Models;

namespace Agenda.Application.Areas.Comandos.AgregarColaboradorArea
{
    public class AgregarColaboradorAreaService
    {
        private readonly List<Area>              _areas;
        private readonly List<Colaborador>       _colaboradores;
        private readonly List<VinculacionArea>   _vinculaciones;

        public AgregarColaboradorAreaService(
            List<Area>            areas,
            List<Colaborador>     colaboradores,
            List<VinculacionArea> vinculaciones)
        {
            _areas         = areas;
            _colaboradores = colaboradores;
            _vinculaciones = vinculaciones;
        }

        public ResultadoBusqueda BuscarColaboradores(int areaId, string textoBusqueda)
        {
            var area = _areas.FirstOrDefault(a => a.Id == areaId);
            if (area == null)
                return ResultadoBusqueda.Error("No se encontró el área indicada");

            var yaVinculados = _vinculaciones
                .Where(v => v.AreaId == areaId)
                .Select(v => v.ColaboradorId)
                .ToHashSet();

            var query = _colaboradores.AsEnumerable();

            // Excluir ya vinculados y al responsable del área
            query = query.Where(c =>
                !yaVinculados.Contains(c.Id) &&
                c.Id != area.ResponsableId);

            if (!string.IsNullOrWhiteSpace(textoBusqueda))
                query = query.Where(c =>
                    c.NombreCompleto.Contains(textoBusqueda, StringComparison.OrdinalIgnoreCase));

            var resultados = query.Select(c => new ColaboradorSeleccionDto
            {
                Id            = c.Id,
                NombreCompleto = c.NombreCompleto,
                Roles         = c.Roles,
                Seleccionado  = false
            }).ToList();

            return ResultadoBusqueda.Exitoso(resultados);
        }

        public ResultadoOperacion AgregarColaboradores(AgregarColaboradoresRequest request)
        {
            if (request.ColaboradoresIds == null || !request.ColaboradoresIds.Any())
                return ResultadoOperacion.Error(
                    "Debe seleccionar al menos un colaborador para agregar al área");

            var area = _areas.FirstOrDefault(a => a.Id == request.AreaId);
            if (area == null)
                return ResultadoOperacion.Error("No se encontró el área indicada");

            var agregados = new List<string>();

            foreach (var colaboradorId in request.ColaboradoresIds)
            {
                var colaborador = _colaboradores.FirstOrDefault(c => c.Id == colaboradorId);
                if (colaborador == null) continue;

                // Validar que el responsable no sea colaborador y viceversa
                if (colaborador.Id == area.ResponsableId)
                    return ResultadoOperacion.Error(
                        $"El colaborador '{colaborador.NombreCompleto}' es responsable del área " +
                        "y no puede ser vinculado como colaborador de la misma");

                bool yaVinculado = _vinculaciones.Any(v =>
                    v.AreaId == request.AreaId && v.ColaboradorId == colaboradorId);

                if (!yaVinculado)
                {
                    _vinculaciones.Add(new VinculacionArea
                    {
                        Id            = _vinculaciones.Count + 1,
                        AreaId        = request.AreaId,
                        ColaboradorId = colaboradorId,
                        FechaVinculacion = DateTime.Now
                    });
                    agregados.Add(colaborador.NombreCompleto);
                }
            }

            if (!agregados.Any())
                return ResultadoOperacion.Error(
                    "Los colaboradores seleccionados ya están vinculados al área");

            var mensajeArea = area.Nombre;
            var mensajeColaboradores = agregados.Count == 1
                ? $"Se agregó un colaborador al área {mensajeArea}."
                : $"Se agregaron {agregados.Count} colaboradores al área {mensajeArea}.";

            return ResultadoOperacion.Exitoso(mensajeColaboradores);
        }

        public List<ColaboradorVinculadoDto> ObtenerColaboradoresVinculados(int areaId)
        {
            var vinculaciones = _vinculaciones
                .Where(v => v.AreaId == areaId)
                .ToList();

            return vinculaciones.Select(v =>
            {
                var colaborador = _colaboradores.FirstOrDefault(c => c.Id == v.ColaboradorId);
                return new ColaboradorVinculadoDto
                {
                    Id             = v.Id,
                    ColaboradorId  = v.ColaboradorId,
                    NombreCompleto = colaborador?.NombreCompleto ?? string.Empty,
                    Roles          = colaborador?.Roles ?? new List<string>()
                };
            }).ToList();
        }
    }

    public class AgregarColaboradoresRequest
    {
        public int         AreaId           { get; set; }
        public List<string> ColaboradoresIds { get; set; } = new();
    }

    public class Area
    {
        public int    Id            { get; set; }
        public string Nombre        { get; set; } = string.Empty;
        public string ResponsableId { get; set; } = string.Empty;
    }

    public class Colaborador
    {
        public string       Id             { get; set; } = string.Empty;
        public string       NombreCompleto { get; set; } = string.Empty;
        public List<string> Roles          { get; set; } = new();
    }

    public class VinculacionArea
    {
        public int      Id               { get; set; }
        public int      AreaId           { get; set; }
        public string   ColaboradorId    { get; set; } = string.Empty;
        public DateTime FechaVinculacion { get; set; }
    }

    public class ColaboradorSeleccionDto
    {
        public string       Id             { get; set; } = string.Empty;
        public string       NombreCompleto { get; set; } = string.Empty;
        public List<string> Roles          { get; set; } = new();
        public bool         Seleccionado   { get; set; }
    }

    public class ColaboradorVinculadoDto
    {
        public int          Id             { get; set; }
        public string       ColaboradorId  { get; set; } = string.Empty;
        public string       NombreCompleto { get; set; } = string.Empty;
        public List<string> Roles          { get; set; } = new();
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
