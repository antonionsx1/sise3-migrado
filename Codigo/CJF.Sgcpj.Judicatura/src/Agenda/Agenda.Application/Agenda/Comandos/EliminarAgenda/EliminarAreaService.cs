using Agenda.Application.Common.Models;

namespace Agenda.Application.Areas.Comandos.EliminarArea
{
    public class EliminarAreaService
    {
        private readonly List<Area>            _areas;
        private readonly List<VinculacionArea> _vinculaciones;

        public EliminarAreaService(
            List<Area>            areas,
            List<VinculacionArea> vinculaciones)
        {
            _areas         = areas;
            _vinculaciones = vinculaciones;
        }

        public ResultadoInfoEliminar ObtenerInfoParaEliminar(int areaId)
        {
            var area = _areas.FirstOrDefault(a => a.Id == areaId);
            if (area == null)
                return ResultadoInfoEliminar.Error("No se encontró el área indicada");

            var numColaboradores = _vinculaciones.Count(v => v.AreaId == areaId);

            return ResultadoInfoEliminar.Exitoso(
                areaId,
                area.Nombre,
                numColaboradores,
                $"¿Está seguro que desea eliminar esta área que cuenta con {numColaboradores} colaborador(es)?");
        }

        public ResultadoOperacion EliminarArea(EliminarAreaRequest request)
        {
            if (!request.Confirmado)
                return ResultadoOperacion.Error(
                    "Se requiere confirmación para eliminar el área");

            var area = _areas.FirstOrDefault(a => a.Id == request.AreaId);
            if (area == null)
                return ResultadoOperacion.Error("No se encontró el área indicada");

            // Eliminar colaboradores vinculados al área
            var vinculaciones = _vinculaciones
                .Where(v => v.AreaId == request.AreaId)
                .ToList();

            int numColaboradoresEliminados = vinculaciones.Count;

            foreach (var vinculacion in vinculaciones)
                _vinculaciones.Remove(vinculacion);

            // Eliminar subáreas hijas si existen
            var subAreas = _areas.Where(a => a.AreaPadreId == request.AreaId).ToList();
            foreach (var subArea in subAreas)
            {
                _vinculaciones.RemoveAll(v => v.AreaId == subArea.Id);
                _areas.Remove(subArea);
            }

            _areas.Remove(area);

            var mensaje = numColaboradoresEliminados > 0
                ? $"Área '{area.Nombre}' eliminada correctamente junto con " +
                  $"{numColaboradoresEliminados} colaborador(es) vinculado(s)"
                : $"Área '{area.Nombre}' eliminada correctamente";

            return ResultadoOperacion.Exitoso(mensaje);
        }
    }

    public class EliminarAreaRequest
    {
        public int  AreaId     { get; set; }
        public bool Confirmado { get; set; }
    }

    public class Area
    {
        public int    Id          { get; set; }
        public string Nombre      { get; set; } = string.Empty;
        public int    TipoAreaId  { get; set; }
        public int?   AreaPadreId { get; set; }
    }

    public class VinculacionArea
    {
        public int    Id            { get; set; }
        public int    AreaId        { get; set; }
        public string ColaboradorId { get; set; } = string.Empty;
    }

    public class ResultadoInfoEliminar
    {
        public bool   Exito           { get; private set; }
        public string Mensaje         { get; private set; } = string.Empty;
        public int    AreaId          { get; private set; }
        public string NombreArea      { get; private set; } = string.Empty;
        public int    NumColaboradores { get; private set; }
        public string MensajeConfirmacion { get; private set; } = string.Empty;

        public static ResultadoInfoEliminar Exitoso(
            int areaId, string nombre, int numColaboradores, string mensajeConfirmacion) =>
            new ResultadoInfoEliminar
            {
                Exito                = true,
                AreaId               = areaId,
                NombreArea           = nombre,
                NumColaboradores     = numColaboradores,
                MensajeConfirmacion  = mensajeConfirmacion
            };

        public static ResultadoInfoEliminar Error(string mensaje) =>
            new ResultadoInfoEliminar { Exito = false, Mensaje = mensaje };
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
