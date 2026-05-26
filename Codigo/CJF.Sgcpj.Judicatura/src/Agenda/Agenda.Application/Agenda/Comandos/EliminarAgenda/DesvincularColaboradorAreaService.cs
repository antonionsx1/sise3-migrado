using Agenda.Application.Common.Models;

namespace Agenda.Application.Areas.Comandos.DesvincularColaboradorArea
{
    public class DesvincularColaboradorAreaService
    {
        private readonly List<Area>            _areas;
        private readonly List<VinculacionArea> _vinculaciones;
        private readonly List<Colaborador>     _colaboradores;

        public DesvincularColaboradorAreaService(
            List<Area>            areas,
            List<VinculacionArea> vinculaciones,
            List<Colaborador>     colaboradores)
        {
            _areas         = areas;
            _vinculaciones = vinculaciones;
            _colaboradores = colaboradores;
        }

        public ResultadoOperacion Desvincular(DesvincularColaboradorRequest request)
        {
            // CORRECCIÓN ERR-AREA-003: Manejo de errores corregido
            // Se valida la confirmación del usuario antes de ejecutar la desvinculación
            if (!request.Confirmado)
                return ResultadoOperacion.Error(
                    "ERR-AREA-003: Se requiere confirmación para desvincular al colaborador del área");

            var vinculacion = _vinculaciones
                .FirstOrDefault(v => v.Id == request.VinculacionId);

            if (vinculacion == null)
                return ResultadoOperacion.Error(
                    "No se encontró la vinculación indicada");

            var area = _areas.FirstOrDefault(a => a.Id == vinculacion.AreaId);
            if (area == null)
                return ResultadoOperacion.Error("No se encontró el área asociada");

            var colaborador = _colaboradores
                .FirstOrDefault(c => c.Id == vinculacion.ColaboradorId);

            _vinculaciones.Remove(vinculacion);

            return ResultadoOperacion.Exitoso(
                $"El colaborador '{colaborador?.NombreCompleto ?? vinculacion.ColaboradorId}' " +
                $"fue desvinculado del área '{area.Nombre}' correctamente");
        }

        public ResultadoInfoDesvincular ObtenerInfoParaDesvincular(int vinculacionId)
        {
            var vinculacion = _vinculaciones.FirstOrDefault(v => v.Id == vinculacionId);
            if (vinculacion == null)
                return ResultadoInfoDesvincular.Error("No se encontró la vinculación indicada");

            var area        = _areas.FirstOrDefault(a => a.Id == vinculacion.AreaId);
            var colaborador = _colaboradores.FirstOrDefault(c => c.Id == vinculacion.ColaboradorId);

            return ResultadoInfoDesvincular.Exitoso(
                vinculacionId,
                colaborador?.NombreCompleto ?? string.Empty,
                area?.Nombre ?? string.Empty);
        }

        public List<ColaboradorVinculadoDto> ObtenerColaboradoresPorArea(int areaId)
        {
            return _vinculaciones
                .Where(v => v.AreaId == areaId)
                .Select(v =>
                {
                    var colaborador = _colaboradores.FirstOrDefault(c => c.Id == v.ColaboradorId);
                    return new ColaboradorVinculadoDto
                    {
                        VinculacionId  = v.Id,
                        ColaboradorId  = v.ColaboradorId,
                        NombreCompleto = colaborador?.NombreCompleto ?? string.Empty,
                        Roles          = colaborador?.Roles ?? new List<string>()
                    };
                }).ToList();
        }
    }

    public class DesvincularColaboradorRequest
    {
        public int  VinculacionId { get; set; }
        public bool Confirmado    { get; set; }
    }

    public class Area
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class VinculacionArea
    {
        public int    Id            { get; set; }
        public int    AreaId        { get; set; }
        public string ColaboradorId { get; set; } = string.Empty;
    }

    public class Colaborador
    {
        public string       Id             { get; set; } = string.Empty;
        public string       NombreCompleto { get; set; } = string.Empty;
        public List<string> Roles          { get; set; } = new();
    }

    public class ColaboradorVinculadoDto
    {
        public int          VinculacionId  { get; set; }
        public string       ColaboradorId  { get; set; } = string.Empty;
        public string       NombreCompleto { get; set; } = string.Empty;
        public List<string> Roles          { get; set; } = new();
    }

    public class ResultadoInfoDesvincular
    {
        public bool   Exito             { get; private set; }
        public string Mensaje           { get; private set; } = string.Empty;
        public int    VinculacionId     { get; private set; }
        public string NombreColaborador { get; private set; } = string.Empty;
        public string NombreArea        { get; private set; } = string.Empty;

        public static ResultadoInfoDesvincular Exitoso(
            int vinculacionId, string nombreColaborador, string nombreArea) =>
            new ResultadoInfoDesvincular
            {
                Exito             = true,
                VinculacionId     = vinculacionId,
                NombreColaborador = nombreColaborador,
                NombreArea        = nombreArea
            };

        public static ResultadoInfoDesvincular Error(string mensaje) =>
            new ResultadoInfoDesvincular { Exito = false, Mensaje = mensaje };
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
