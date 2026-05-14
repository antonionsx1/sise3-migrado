using Agenda.Application.Common.Models;

namespace Agenda.Application.Areas.Comandos.EditarArea
{
    // ERROR ERR-AREA-002: Estructura incorrecta
    // La lógica de validación de cambios, precarga de datos y guardado
    // están todas concentradas en una sola clase sin separación de responsabilidades.
    // Debería separarse en:
    // - EditarAreaService: orquesta la edición
    // - PrecargaAreaHelper: obtiene datos actuales del área
    // - ValidacionCambiosHelper: detecta si hubo cambios reales
    public class EditarAreaService
    {
        private readonly List<Area>        _areas;
        private readonly List<TipoArea>    _tiposArea;
        private readonly List<Colaborador> _colaboradores;

        public EditarAreaService(
            List<Area>        areas,
            List<TipoArea>    tiposArea,
            List<Colaborador> colaboradores)
        {
            _areas         = areas;
            _tiposArea     = tiposArea;
            _colaboradores = colaboradores;
        }

        // Precarga mezclada con edición
        public AreaFormulario ObtenerDatosParaEditar(int areaId)
        {
            var area = _areas.FirstOrDefault(a => a.Id == areaId);
            if (area == null) return new AreaFormulario();

            var tipoArea = _tiposArea.FirstOrDefault(t => t.Id == area.TipoAreaId);
            var areaPadre = area.AreaPadreId.HasValue
                ? _areas.FirstOrDefault(a => a.Id == area.AreaPadreId.Value)
                : null;

            return new AreaFormulario
            {
                Id            = area.Id,
                TipoAreaId    = area.TipoAreaId,
                TipoAreaNombre = tipoArea?.Nombre ?? string.Empty,
                Nombre        = area.Nombre,
                Descripcion   = area.Descripcion,
                ResponsableId = area.ResponsableId,
                AreaPadreId   = area.AreaPadreId,
                AreaPadreNombre = areaPadre?.Nombre
            };
        }

        public ResultadoOperacion GuardarCambios(EditarAreaRequest request)
        {
            var area = _areas.FirstOrDefault(a => a.Id == request.AreaId);
            if (area == null)
                return ResultadoOperacion.Error("No se encontró el área indicada");

            if (string.IsNullOrEmpty(request.Nombre))
                return ResultadoOperacion.Error("El nombre del área es requerido");

            if (string.IsNullOrEmpty(request.ResponsableId))
                return ResultadoOperacion.Error("El responsable del área es requerido");

            // Validación de cambios mezclada con guardado
            bool huboCambios =
                area.Nombre        != request.Nombre        ||
                area.Descripcion   != request.Descripcion   ||
                area.ResponsableId != request.ResponsableId ||
                area.TipoAreaId    != request.TipoAreaId    ||
                area.AreaPadreId   != request.AreaPadreId;

            if (!huboCambios)
                return ResultadoOperacion.Error(
                    "No se detectaron cambios en la información del área");

            if (request.AreaPadreId.HasValue)
            {
                var areaPadre = _areas.FirstOrDefault(a => a.Id == request.AreaPadreId.Value);
                if (areaPadre != null && areaPadre.TipoAreaId == request.TipoAreaId)
                    return ResultadoOperacion.Error(
                        "El área padre no puede ser del mismo tipo que el área a editar");
            }

            area.Nombre        = request.Nombre;
            area.Descripcion   = request.Descripcion;
            area.TipoAreaId    = request.TipoAreaId;
            area.ResponsableId = request.ResponsableId;
            area.AreaPadreId   = request.AreaPadreId;

            return ResultadoOperacion.Exitoso(
                $"Área '{area.Nombre}' actualizada correctamente");
        }

        // Catálogos mezclados en el mismo servicio
        public List<Area> ObtenerAreasDisponibles(int tipoAreaId, int areaActualId) =>
            _areas.Where(a => a.TipoAreaId != tipoAreaId && a.Id != areaActualId).ToList();

        public List<Colaborador> ObtenerColaboradores() => _colaboradores;
    }

    public class EditarAreaRequest
    {
        public int    AreaId        { get; set; }
        public string Nombre        { get; set; } = string.Empty;
        public string Descripcion   { get; set; } = string.Empty;
        public int    TipoAreaId    { get; set; }
        public string ResponsableId { get; set; } = string.Empty;
        public int?   AreaPadreId   { get; set; }
    }

    public class AreaFormulario
    {
        public int     Id             { get; set; }
        public int     TipoAreaId     { get; set; }
        public string  TipoAreaNombre { get; set; } = string.Empty;
        public string  Nombre         { get; set; } = string.Empty;
        public string  Descripcion    { get; set; } = string.Empty;
        public string  ResponsableId  { get; set; } = string.Empty;
        public int?    AreaPadreId    { get; set; }
        public string? AreaPadreNombre { get; set; }
    }

    public class Area
    {
        public int    Id            { get; set; }
        public string Nombre        { get; set; } = string.Empty;
        public string Descripcion   { get; set; } = string.Empty;
        public int    TipoAreaId    { get; set; }
        public string ResponsableId { get; set; } = string.Empty;
        public int?   AreaPadreId   { get; set; }
    }

    public class TipoArea
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class Colaborador
    {
        public string UsuarioId { get; set; } = string.Empty;
        public string Nombre    { get; set; } = string.Empty;
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
