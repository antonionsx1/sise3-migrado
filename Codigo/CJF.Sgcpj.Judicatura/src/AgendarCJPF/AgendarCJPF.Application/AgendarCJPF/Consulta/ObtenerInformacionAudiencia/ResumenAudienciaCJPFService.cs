using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ObtenerResumenAudienciaCJPF
{
    // CORRECCIÓN ERR-RES-002: Estructura corregida
    // Se separan las responsabilidades en helpers independientes:
    // - ResumenAudienciaCJPFService: orquesta la consulta
    // - AsistentesHelper: lógica de asistentes
    // - IndicesHelper: lógica de índices
    public class ResumenAudienciaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;
        private readonly AsistentesHelper    _asistentesHelper;
        private readonly IndicesHelper       _indicesHelper;

        public ResumenAudienciaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias       = audiencias;
            _asistentesHelper = new AsistentesHelper();
            _indicesHelper    = new IndicesHelper();
        }

        public ResultadoOperacion<ResumenAudienciaDto> ObtenerResumen(int audienciaId)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null)
                return ResultadoOperacion<ResumenAudienciaDto>.Error(
                    "No se encontró la audiencia indicada");

            // CORRECCIÓN ERR-RES-003: Comentario corregido
            // Solo se puede consultar el resumen de audiencias en estado Celebrada
            if (audiencia.Estado != "Celebrada")
                return ResultadoOperacion<ResumenAudienciaDto>.Error(
                    "ERR-RES-003: Solo se puede consultar el resumen de audiencias Celebradas");

            var resumen = new ResumenAudienciaDto
            {
                Neun          = audiencia.Neun,
                TipoAudiencia = audiencia.TipoAudiencia,
                FechaInicio   = audiencia.FechaHoraInicio.ToString("dd/MM/yyyy HH:mm"),
                FechaFin      = audiencia.FechaHoraFin.ToString("dd/MM/yyyy HH:mm"),
                Resoluciones  = ObtenerResoluciones(audiencia),
                Asistentes    = _asistentesHelper.ObtenerAsistentes(audiencia),
                Indices       = _indicesHelper.ObtenerIndices(audiencia),
                Videos        = ObtenerVideos(audiencia)
            };

            return ResultadoOperacion<ResumenAudienciaDto>.Exitoso(resumen);
        }

        private List<ResolucionDto> ObtenerResoluciones(AudienciaCJPF audiencia) =>
            audiencia.Resoluciones.Select(r => new ResolucionDto
            {
                TipoResolucion = r.TipoResolucion,
                Descripcion    = r.Descripcion
            }).ToList();

        private List<VideoDto> ObtenerVideos(AudienciaCJPF audiencia) =>
            audiencia.Videos.Select(v => new VideoDto
            {
                Neun            = v.Neun,
                NumeroAudiencia = v.NumeroAudiencia,
                Parte           = v.Parte,
                FechaInicio     = v.FechaInicio.ToString("dd/MM/yyyy HH:mm"),
                FechaFin        = v.FechaFin.ToString("dd/MM/yyyy HH:mm"),
                DuracionMinutos = v.DuracionMinutos,
                UrlVideo        = v.UrlVideo
            }).ToList();
    }

    public class AsistentesHelper
    {
        // CORRECCIÓN ERR-RES-004: Operador lógico corregido
        // Se usa || para retornar asistentes que sean de CUALQUIERA de los tipos
        public List<AsistenteDto> ObtenerAsistentes(AudienciaCJPF audiencia) =>
            audiencia.Asistentes
                .Where(a => a.TipoAsistente == "Juez" ||
                            a.TipoAsistente == "Defensor")
                .Select(a => new AsistenteDto
                {
                    Identificador  = a.Identificador,
                    Nombre         = a.Nombre,
                    TipoAsistente  = a.TipoAsistente,
                    TipoAsistencia = a.TipoAsistencia,
                    HoraLlegada    = a.HoraLlegada.ToString("HH:mm")
                }).ToList();
    }

    public class IndicesHelper
    {
        // CORRECCIÓN ERR-RES-005: Comentario corregido
        // Obtener índices de audiencia (no de video)
        public List<IndiceDto> ObtenerIndices(AudienciaCJPF audiencia) =>
            audiencia.Indices.Select(i => new IndiceDto
            {
                Orador = i.Orador,
                Indice = i.Indice,
                Fecha  = i.Fecha.ToString("dd/MM/yyyy HH:mm")
            }).ToList();
    }

    public class ResumenAudienciaDto
    {
        public string              Neun          { get; set; } = string.Empty;
        public string              TipoAudiencia { get; set; } = string.Empty;
        public string              FechaInicio   { get; set; } = string.Empty;
        public string              FechaFin      { get; set; } = string.Empty;
        public List<ResolucionDto> Resoluciones  { get; set; } = new();
        public List<AsistenteDto>  Asistentes    { get; set; } = new();
        public List<IndiceDto>     Indices       { get; set; } = new();
        public List<VideoDto>      Videos        { get; set; } = new();
    }

    public class ResolucionDto
    {
        public string TipoResolucion { get; set; } = string.Empty;
        public string Descripcion    { get; set; } = string.Empty;
    }

    public class AsistenteDto
    {
        public string Identificador  { get; set; } = string.Empty;
        public string Nombre         { get; set; } = string.Empty;
        public string TipoAsistente  { get; set; } = string.Empty;
        public string TipoAsistencia { get; set; } = string.Empty;
        public string HoraLlegada    { get; set; } = string.Empty;
    }

    public class IndiceDto
    {
        public string Orador { get; set; } = string.Empty;
        public string Indice { get; set; } = string.Empty;
        public string Fecha  { get; set; } = string.Empty;
    }

    public class VideoDto
    {
        public string Neun            { get; set; } = string.Empty;
        public int    NumeroAudiencia { get; set; }
        public string Parte           { get; set; } = string.Empty;
        public string FechaInicio     { get; set; } = string.Empty;
        public string FechaFin        { get; set; } = string.Empty;
        public int    DuracionMinutos { get; set; }
        public string UrlVideo        { get; set; } = string.Empty;
    }

    public class ResultadoOperacion<T>
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;
        public T?     Datos   { get; private set; }

        public static ResultadoOperacion<T> Exitoso(T datos) =>
            new ResultadoOperacion<T> { Exito = true, Datos = datos };

        public static ResultadoOperacion<T> Error(string mensaje) =>
            new ResultadoOperacion<T> { Exito = false, Mensaje = mensaje };
    }

    public class AudienciaCJPF
    {
        public int      Id              { get; set; }
        public string   Neun            { get; set; } = string.Empty;
        public string   TipoAudiencia   { get; set; } = string.Empty;
        public string   Estado          { get; set; } = string.Empty;
        public DateTime FechaHoraInicio { get; set; }
        public DateTime FechaHoraFin    { get; set; }
        public List<Asistente>  Asistentes   { get; set; } = new();
        public List<Indice>     Indices      { get; set; } = new();
        public List<Resolucion> Resoluciones { get; set; } = new();
        public List<Video>      Videos       { get; set; } = new();
    }

    public class Asistente
    {
        public string   Identificador  { get; set; } = string.Empty;
        public string   Nombre         { get; set; } = string.Empty;
        public string   TipoAsistente  { get; set; } = string.Empty;
        public string   TipoAsistencia { get; set; } = string.Empty;
        public DateTime HoraLlegada    { get; set; }
    }

    public class Indice
    {
        public string   Orador { get; set; } = string.Empty;
        public string   Indice { get; set; } = string.Empty;
        public DateTime Fecha  { get; set; }
    }

    public class Resolucion
    {
        public string TipoResolucion { get; set; } = string.Empty;
        public string Descripcion    { get; set; } = string.Empty;
    }

    public class Video
    {
        public string   Neun            { get; set; } = string.Empty;
        public int      NumeroAudiencia { get; set; }
        public string   Parte           { get; set; } = string.Empty;
        public DateTime FechaInicio     { get; set; }
        public DateTime FechaFin        { get; set; }
        public int      DuracionMinutos { get; set; }
        public string   UrlVideo        { get; set; } = string.Empty;
    }
}
