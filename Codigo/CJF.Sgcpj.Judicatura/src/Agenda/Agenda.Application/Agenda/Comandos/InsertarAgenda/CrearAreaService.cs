using Agenda.Application.Common.Models;

namespace Agenda.Application.Areas.Comandos.CrearArea
{
    public class CrearAreaService
    {
        private readonly List<Area>        _areas;
        private readonly List<TipoArea>    _tiposArea;
        private readonly List<Colaborador> _colaboradores;

        // Tipos que permiten asignar a un área existente
        private static readonly string[] TiposConAreaExistente =
            { "Actuaría", "Zona", "Ponencia" };

        public CrearAreaService(
            List<Area>        areas,
            List<TipoArea>    tiposArea,
            List<Colaborador> colaboradores)
        {
            _areas         = areas;
            _tiposArea     = tiposArea;
            _colaboradores = colaboradores;
        }

        public ResultadoOperacion CrearArea(CrearAreaRequest request)
        {
            if (string.IsNullOrEmpty(request.Nombre))
                return ResultadoOperacion.Error("El nombre del área es requerido");

            if (request.TipoAreaId <= 0)
                return ResultadoOperacion.Error("El tipo de área es requerido");

            if (string.IsNullOrEmpty(request.ResponsableId))
                return ResultadoOperacion.Error("El responsable del área es requerido");

            var tipoArea = _tiposArea.FirstOrDefault(t => t.Id == request.TipoAreaId);
            if (tipoArea == null)
                return ResultadoOperacion.Error("El tipo de área indicado no existe");

            // ERROR ERR-AREA-001: Operador lógico erróneo
            // Se usa && en lugar de || por lo que la validación del responsable
            // como colaborador nunca bloquea correctamente:
            // solo bloquea si el responsable está en el área Y tiene el mismo rol
            // cuando debería bloquear si está en cualquiera de esas condiciones
            bool responsableEsColaborador = _areas.Any(a =>
                a.ResponsableId == request.ResponsableId &&
                a.Id == request.AreaPadreId);

            if (responsableEsColaborador)
                return ResultadoOperacion.Error(
                    "ERR-AREA-001: El responsable no puede ser también colaborador en la misma área");

            // Validar que el área padre no sea del mismo tipo
            if (request.AreaPadreId.HasValue)
            {
                var areaPadre = _areas.FirstOrDefault(a => a.Id == request.AreaPadreId.Value);
                if (areaPadre != null && areaPadre.TipoAreaId == request.TipoAreaId)
                    return ResultadoOperacion.Error(
                        "El área padre no puede ser del mismo tipo que el área a crear");
            }

            // Validar que el tipo permita asignar área existente
            bool permiteAreaExistente = TiposConAreaExistente
                .Contains(tipoArea.Nombre, StringComparer.OrdinalIgnoreCase);

            if (request.AreaPadreId.HasValue && !permiteAreaExistente)
                return ResultadoOperacion.Error(
                    $"El tipo '{tipoArea.Nombre}' no permite asignar a un área existente");

            var nuevaArea = new Area
            {
                Id            = _areas.Count + 1,
                Nombre        = request.Nombre,
                Descripcion   = request.Descripcion,
                TipoAreaId    = request.TipoAreaId,
                ResponsableId = request.ResponsableId,
                AreaPadreId   = request.AreaPadreId
            };

            _areas.Add(nuevaArea);

            return ResultadoOperacion.Exitoso(
                $"Área '{nuevaArea.Nombre}' creada correctamente");
        }

        public List<Area> ObtenerAreasExistentes(int tipoAreaId) =>
            _areas.Where(a => a.TipoAreaId != tipoAreaId).ToList();
    }

    public class CrearAreaRequest
    {
        public string  Nombre        { get; set; } = string.Empty;
        public string  Descripcion   { get; set; } = string.Empty;
        public int     TipoAreaId    { get; set; }
        public string  ResponsableId { get; set; } = string.Empty;
        public int?    AreaPadreId   { get; set; }
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
        public int    AreaId    { get; set; }
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
