using Agenda.Application.Common.Models;

namespace Agenda.Application.Areas.Consulta.ObtenerAreasOrganismo
{
    public class VistaGeneralAreasService
    {
        private readonly List<TipoArea>     _tiposArea;
        private readonly List<Area>         _areas;
        private readonly List<Colaborador>  _colaboradores;

        // Organismos que pueden usar el tipo "Ponencia"
        private static readonly string[] OrganismosPonencia =
        {
            "Tribunales Colegiados de Circuito",
            "Tribunales Colegiados de Apelacion",
            "Pleno Regional"
        };

        public VistaGeneralAreasService(
            List<TipoArea>    tiposArea,
            List<Area>        areas,
            List<Colaborador> colaboradores)
        {
            _tiposArea     = tiposArea;
            _areas         = areas;
            _colaboradores = colaboradores;
        }

        public ResultadoVistaGeneral ObtenerVista(string organismoNombre)
        {
            var tiposDisponibles = ObtenerTiposArea(organismoNombre);

            return new ResultadoVistaGeneral
            {
                TiposArea    = tiposDisponibles,
                Areas        = new List<AreaDto>(),
                Colaboradores = new List<ColaboradorDto>()
            };
        }

        public ResultadoSeleccionTipo ObtenerAreasPorTipo(int tipoAreaId)
        {
            var areas = _areas
                .Where(a => a.TipoAreaId == tipoAreaId)
                .ToList();

            var areasDto = ConstruirAreasJerarquicas(areas);

            return new ResultadoSeleccionTipo
            {
                Areas        = areasDto,
                HayRegistros = areasDto.Any()
            };
        }

        public ResultadoColaboradores ObtenerColaboradoresPorArea(int areaId)
        {
            var area = _areas.FirstOrDefault(a => a.Id == areaId);
            if (area == null)
                return ResultadoColaboradores.Error("No se encontró el área indicada");

            var colaboradores = _colaboradores
                .Where(c => c.AreaId == areaId)
                .ToList();

            // Validar que el responsable no sea también colaborador
            var colaboradoresValidos = colaboradores
                .Where(c => c.UsuarioId != area.ResponsableId)
                .Select(c => new ColaboradorDto
                {
                    Id          = c.Id,
                    NombreCompleto = c.NombreCompleto,
                    Perfil      = c.Perfil,
                    AreaId      = c.AreaId
                }).ToList();

            return ResultadoColaboradores.Exitoso(colaboradoresValidos);
        }

        private List<TipoAreaDto> ObtenerTiposArea(string organismoNombre)
        {
            return _tiposArea
                .Where(t => t.Nombre != "Ponencia" ||
                            OrganismosPonencia.Any(o =>
                                organismoNombre.Contains(o, StringComparison.OrdinalIgnoreCase)))
                .Select(t => new TipoAreaDto
                {
                    Id     = t.Id,
                    Nombre = t.Nombre
                }).ToList();
        }

        private List<AreaDto> ConstruirAreasJerarquicas(List<Area> areas)
        {
            var areasPadre = areas.Where(a => a.AreaPadreId == null).ToList();
            var resultado  = new List<AreaDto>();

            foreach (var padre in areasPadre)
            {
                var hijos = areas
                    .Where(a => a.AreaPadreId == padre.Id)
                    .Select(a => new AreaDto
                    {
                        Id           = a.Id,
                        Nombre       = a.Nombre,
                        Descripcion  = a.Descripcion,
                        Responsable  = a.Responsable,
                        ResponsableId = a.ResponsableId,
                        TieneHijos   = false,
                        Hijos        = new List<AreaDto>()
                    }).ToList();

                resultado.Add(new AreaDto
                {
                    Id            = padre.Id,
                    Nombre        = padre.Nombre,
                    Descripcion   = padre.Descripcion,
                    Responsable   = padre.Responsable,
                    ResponsableId = padre.ResponsableId,
                    TieneHijos    = hijos.Any(),
                    Hijos         = hijos
                });
            }

            return resultado;
        }
    }

    public class TipoArea
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class Area
    {
        public int     Id            { get; set; }
        public string  Nombre        { get; set; } = string.Empty;
        public string  Descripcion   { get; set; } = string.Empty;
        public int     TipoAreaId    { get; set; }
        public int?    AreaPadreId   { get; set; }
        public string  Responsable   { get; set; } = string.Empty;
        public string  ResponsableId { get; set; } = string.Empty;
    }

    public class Colaborador
    {
        public int    Id             { get; set; }
        public string UsuarioId      { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string Perfil         { get; set; } = string.Empty;
        public int    AreaId         { get; set; }
    }

    public class TipoAreaDto
    {
        public int    Id     { get; set; }
        public string Nombre { get; set; } = string.Empty;
    }

    public class AreaDto
    {
        public int           Id            { get; set; }
        public string        Nombre        { get; set; } = string.Empty;
        public string        Descripcion   { get; set; } = string.Empty;
        public string        Responsable   { get; set; } = string.Empty;
        public string        ResponsableId { get; set; } = string.Empty;
        public bool          TieneHijos    { get; set; }
        public List<AreaDto> Hijos         { get; set; } = new();
    }

    public class ColaboradorDto
    {
        public int    Id             { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string Perfil         { get; set; } = string.Empty;
        public int    AreaId         { get; set; }
    }

    public class ResultadoVistaGeneral
    {
        public List<TipoAreaDto>   TiposArea     { get; set; } = new();
        public List<AreaDto>       Areas         { get; set; } = new();
        public List<ColaboradorDto> Colaboradores { get; set; } = new();
    }

    public class ResultadoSeleccionTipo
    {
        public List<AreaDto> Areas        { get; set; } = new();
        public bool          HayRegistros { get; set; }
    }

    public class ResultadoColaboradores
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;
        public List<ColaboradorDto> Colaboradores { get; private set; } = new();

        public static ResultadoColaboradores Exitoso(List<ColaboradorDto> colaboradores) =>
            new ResultadoColaboradores { Exito = true, Colaboradores = colaboradores };

        public static ResultadoColaboradores Error(string mensaje) =>
            new ResultadoColaboradores { Exito = false, Mensaje = mensaje };
    }
}
