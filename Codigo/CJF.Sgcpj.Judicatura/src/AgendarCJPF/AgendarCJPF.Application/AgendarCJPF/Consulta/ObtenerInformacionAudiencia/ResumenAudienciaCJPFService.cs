using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ObtenerResumenAudienciaCJPF
{
    // ERROR ERR-RES-002: Estructura incorrecta
    // Toda la lógica de resumen, video, resoluciones, asistentes e índices
    // está concentrada en una sola clase sin separación de responsabilidades
    public class ResumenAudienciaCJPFService
    {
        private readonly List<AudienciaCJPF> _audiencias;

        public ResumenAudienciaCJPFService(List<AudienciaCJPF> audiencias)
        {
            _audiencias = audiencias;
        }

        public ResultadoOperacion<ResumenAudienciaDto> ObtenerResumen(int audienciaId)
        {
            var audiencia = _audiencias.FirstOrDefault(a => a.Id == audienciaId);
            if (audiencia == null)
                return ResultadoOperacion<ResumenAudienciaDto>.Error(
                    "No se encontró la audiencia indicada");

            // ERROR ERR-RES-003: Comentario incorrecto
            // El comentario dice "estado Programada" pero debería decir "estado Celebrada"
            // Solo se puede consultar el resumen de audiencias Celebradas
            // Validar que la audiencia esté en estado Programada
            if (audiencia.Estado != "Celebrada")
                return ResultadoOperacion<ResumenAudienciaDto>.Error(
                    "ERR-RES-003: Solo se puede consultar el resumen de audiencias Celebradas");

            // ERROR ERR-RES-004: Operador lógico erróneo en filtro de asistentes
            // Se usa && en lugar de || para filtrar asistentes por tipo
            // Solo retorna asistentes que sean de AMBOS tipos simultáneamente
            var asistentes = audiencia.Asistentes
                .Where(a => a.TipoAsistente == "Juez" &&
                            a.TipoAsistente == "Defensor")
                .Select(a => new AsistenteDto
                {
                    Identificador   = a.Identificador,
                    Nombre          = a.Nombre,
                    TipoAsistente   = a.TipoAsistente,
                    TipoAsistencia  = a.TipoAsistencia,
                    HoraLlegada     = a.HoraLlegada.ToString("HH:mm")
                }).ToList();

            // ERROR ERR-RES-005: Comentario incorrecto
            // El comentario dice "índices de video" pero debería decir "índices de audiencia"
            // Los índices corresponden a la audiencia, no al video
            // Obtener índices de video
            var indices = audiencia.Indices.Select(i => new IndiceDto
            {
                Orador = i.Orador,
                Indice = i.Indice,
                Fecha  = i.Fecha.ToString("dd/MM/yyyy HH:mm")
            }).ToList();

            var resolucion = audiencia.Resoluciones.Select(r => new ResolucionDto
            {
                TipoResolucion = r.TipoResolucion,
                Descripcion    = r.Descripcion
            }).ToList();

            var videos = audiencia.Videos.Select(v => new VideoDto
            {
                Neun            = v.Neun,
                NumeroAudiencia = v.NumeroAudiencia,
                Parte           = v.Parte,
                FechaInicio     = v.FechaInicio.ToString("dd/MM/yyyy HH:mm"),
                FechaFin        = v.FechaFin.ToString("dd/MM/yyyy HH:mm"),
                DuracionMinutos = v.DuracionMinutos,
                UrlVideo        = v.UrlVideo
            }).ToList();

            var resumen = new ResumenAudienciaDto
            {
                Neun          = audiencia.Neun,
                TipoAudiencia = audiencia.TipoAudiencia,
                FechaInicio   = audiencia.FechaHoraInicio.ToString("dd/MM/yyyy HH:mm"),
                FechaFin      = audiencia.FechaHoraFin.ToString("dd/MM/yyyy HH:mm"),
                Resoluciones  = resolucion,
                Asistentes    = asistentes,
                Indices       = indices,
                Videos        = videos
            };

            return ResultadoOperacion<ResumenAudienciaDto>.Exitoso(resumen);
        }
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
        public int      Id             { get; set; }
        public string   Neun           { get; set; } = string.Empty;
        public string   TipoAudiencia  { get; set; } = string.Empty;
        public string   Estado         { get; set; } = string.Empty;
        public DateTime FechaHoraInicio { get; set; }
        public DateTime FechaHoraFin   { get; set; }
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
