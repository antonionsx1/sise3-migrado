using Agenda.Application.Common.Models;

namespace Agenda.Application.Areas.Comandos.EditarArea
{
    // CORRECCIÓN ERR-AREA-002: Estructura corregida
    // Se separan las responsabilidades en clases independientes:
    // - EditarAreaService: orquesta la edición
    // - PrecargaAreaHelper: obtiene datos actuales del área
    // - ValidacionCambiosHelper: detecta si hubo cambios reales
    // - CatalogosAreaHelper: provee catálogos necesarios para el formulario

    public class EditarAreaService
    {
        private readonly List<Area>           _areas;
        private readonly PrecargaAreaHelper   _precargaHelper;
        private readonly ValidacionCambiosHelper _validacionHelper;
        private readonly CatalogosAreaHelper  _catalogosHelper;

        public EditarAreaService(
            List<Area>        areas,
            List<TipoArea>    tiposArea,
            List<Colaborador> colaboradores)
        {
            _areas            = areas;
            _precargaHelper   = new PrecargaAreaHelper(areas, tiposArea);
            _validacionHelper = new ValidacionCambiosHelper();
            _catalogosHelper  = new CatalogosAreaHelper(areas, colaboradores);
        }

        public AreaFormulario ObtenerDatosParaEditar(int areaId) =>
            _precargaHelper.ObtenerFormulario(areaId);

        public ResultadoOperacion GuardarCambios(EditarAreaRequest request)
        {
            var area = _areas.FirstOrDefault(a => a.Id == request.AreaId);
            if (area == null)
                return ResultadoOperacion.Error("No se encontró el área indicada");

            if (string.IsNullOrEmpty(request.Nombre))
                return ResultadoOperacion.Error("El nombre del área es requerido");

            if (string.IsNullOrEmpty(request.ResponsableId))
                return ResultadoOperacion.Error("El responsable del área es requerido");

            if (!_validacionHelper.HuboCambios(area, request))
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

        public List<Area>        ObtenerAreasDisponibles(int tipoAreaId, int areaActualId) =>
            _catalogosHelper.ObtenerAreasDisponibles(tipoAreaId, areaActualId);

        public List<Colaborador> ObtenerColaboradores() =>
            _catalogosHelper.ObtenerColaboradores();
    }

    public class PrecargaAreaHelper
    {
        private readonly List<Area>     _areas;
        private readonly List<TipoArea> _tiposArea;

        public PrecargaAreaHelper(List<Area> areas, List<TipoArea> tiposArea)
        {
            _areas     = areas;
            _tiposArea = tiposArea;
        }

        public AreaFormulario ObtenerFormulario(int areaId)
        {
            var area = _areas.FirstOrDefault(a => a.Id == areaId);
            if (area == null) return new AreaFormulario();

            var tipoArea  = _tiposArea.FirstOrDefault(t => t.Id == area.TipoAreaId);
            var areaPadre = area.AreaPadreId.HasValue
                ? _areas.FirstOrDefault(a => a.Id == area.AreaPadreId.Value)
                : null;

            return new AreaFormulario
            {
                Id              = area.Id,
                TipoAreaId      = area.TipoAreaId,
                TipoAreaNombre  = tipoArea?.Nombre ?? string.Empty,
                Nombre          = area.Nombre,
                Descripcion     = area.Descripcion,
                ResponsableId   = area.ResponsableId,
                AreaPadreId     = area.AreaPadreId,
                AreaPadreNombre = areaPadre?.Nombre
            };
        }
    }

    public class ValidacionCambiosHelper
    {
        public bool HuboCambios(Area area, EditarAreaRequest request) =>
            area.Nombre        != request.Nombre        ||
            area.Descripcion   != request.Descripcion   ||
            area.ResponsableId != request.ResponsableId ||
            area.TipoAreaId    != request.TipoAreaId    ||
            area.AreaPadreId   != request.AreaPadreId;
    }

    public class CatalogosAreaHelper
    {
        private readonly List<Area>        _areas;
        private readonly List<Colaborador> _colaboradores;

        public CatalogosAreaHelper(List<Area> areas, List<Colaborador> colaboradores)
        {
            _areas         = areas;
            _colaboradores = colaboradores;
        }

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
        public int     Id              { get; set; }
        public int     TipoAreaId      { get; set; }
        public string  TipoAreaNombre  { get; set; } = string.Empty;
        public string  Nombre          { get; set; } = string.Empty;
        public string  Descripcion     { get; set; } = string.Empty;
        public string  ResponsableId   { get; set; } = string.Empty;
        public int?    AreaPadreId     { get; set; }
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
