using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ReutilizacionDatosAudiencia
{
    public class ReutilizacionDatosAudienciaService
    {
        private readonly List<AudienciaCJPF>    _audiencias;
        private readonly List<ReglaVigencia>    _reglasVigencia;
        private readonly List<RegistroCopia>    _registrosCopia;

        public ReutilizacionDatosAudienciaService(
            List<AudienciaCJPF>  audiencias,
            List<ReglaVigencia>  reglasVigencia,
            List<RegistroCopia>  registrosCopia)
        {
            _audiencias      = audiencias;
            _reglasVigencia  = reglasVigencia;
            _registrosCopia  = registrosCopia;
        }

        public ResultadoReutilizacion ObtenerDatosParaReutilizar(
            int audienciaOrigenId, string usuarioId)
        {
            var audienciaOrigen = _audiencias.FirstOrDefault(a => a.Id == audienciaOrigenId);
            if (audienciaOrigen == null)
                return ResultadoReutilizacion.Error(
                    "La audiencia de origen no existe. No se puede reutilizar la información");

            var datosDisponibles = new List<DatoReutilizable>();
            var datosObsoletos   = new List<DatoObsoleto>();

            EvaluarCampos(audienciaOrigen, datosDisponibles, datosObsoletos);

            return ResultadoReutilizacion.Exitoso(
                audienciaOrigenId, datosDisponibles, datosObsoletos);
        }

        public ResultadoOperacion CopiarDatos(CopiarDatosRequest request)
        {
            var audienciaOrigen = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaOrigenId);
            if (audienciaOrigen == null)
                return ResultadoOperacion.Error(
                    "La audiencia de origen no existe. No se puede reutilizar la información");

            var audienciaDestino = _audiencias.FirstOrDefault(a => a.Id == request.AudienciaDestinoId);
            if (audienciaDestino == null)
                return ResultadoOperacion.Error("No se encontró la audiencia de destino");

            var camposCopiadosExitoso = new List<string>();
            var camposObsoletos       = new List<string>();

            foreach (var campo in request.CamposACopiar)
            {
                var regla = _reglasVigencia.FirstOrDefault(r => r.Campo == campo);

                if (regla != null && EsObsoleto(audienciaOrigen, campo, regla))
                {
                    camposObsoletos.Add(campo);
                    continue;
                }

                CopiarCampo(audienciaOrigen, audienciaDestino, campo);
                camposCopiadosExitoso.Add(campo);
            }

            if (camposCopiadosExitoso.Any())
            {
                _registrosCopia.Add(new RegistroCopia
                {
                    Id                = _registrosCopia.Count + 1,
                    AudienciaOrigenId = request.AudienciaOrigenId,
                    AudienciaDestinoId = request.AudienciaDestinoId,
                    CamposCopidos     = camposCopiadosExitoso,
                    UsuarioId         = request.UsuarioId,
                    FechaCopia        = DateTime.Now
                });
            }

            if (camposObsoletos.Any())
                return ResultadoOperacion.Exitoso(
                    $"Se copiaron {camposCopiadosExitoso.Count} campos. " +
                    $"Los siguientes requieren actualización: {string.Join(", ", camposObsoletos)}");

            return ResultadoOperacion.Exitoso(
                $"Se copiaron correctamente {camposCopiadosExitoso.Count} campos " +
                $"desde la audiencia {request.AudienciaOrigenId}");
        }

        private void EvaluarCampos(
            AudienciaCJPF audiencia,
            List<DatoReutilizable> disponibles,
            List<DatoObsoleto> obsoletos)
        {
            var camposEvaluables = new[]
            {
                "TipoAudiencia", "Sala", "JuezAsignado",
                "Participantes", "TipoAsunto", "Procedimiento"
            };

            foreach (var campo in camposEvaluables)
            {
                var regla = _reglasVigencia.FirstOrDefault(r => r.Campo == campo);
                if (regla != null && EsObsoleto(audiencia, campo, regla))
                    obsoletos.Add(new DatoObsoleto
                    {
                        Campo   = campo,
                        Motivo  = $"El dato supera los {regla.DiasVigencia} días de vigencia"
                    });
                else
                    disponibles.Add(new DatoReutilizable
                    {
                        Campo = campo,
                        Valor = ObtenerValorCampo(audiencia, campo)
                    });
            }
        }

        private bool EsObsoleto(AudienciaCJPF audiencia, string campo, ReglaVigencia regla) =>
            (DateTime.Today - audiencia.FechaHoraInicio.Date).TotalDays > regla.DiasVigencia;

        private void CopiarCampo(
            AudienciaCJPF origen, AudienciaCJPF destino, string campo)
        {
            switch (campo)
            {
                case "TipoAudiencia":  destino.TipoAudiencia  = origen.TipoAudiencia;  break;
                case "Sala":           destino.Sala            = origen.Sala;            break;
                case "JuezAsignado":   destino.JuezAsignado    = origen.JuezAsignado;    break;
            }
        }

        private string ObtenerValorCampo(AudienciaCJPF audiencia, string campo) =>
            campo switch
            {
                "TipoAudiencia" => audiencia.TipoAudiencia,
                "Sala"          => audiencia.Sala,
                "JuezAsignado"  => audiencia.JuezAsignado,
                _               => string.Empty
            };
    }

    public class CopiarDatosRequest
    {
        public int          AudienciaOrigenId  { get; set; }
        public int          AudienciaDestinoId { get; set; }
        public List<string> CamposACopiar      { get; set; } = new();
        public string       UsuarioId          { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int      Id              { get; set; }
        public string   TipoAudiencia   { get; set; } = string.Empty;
        public string   Sala            { get; set; } = string.Empty;
        public string   JuezAsignado    { get; set; } = string.Empty;
        public string   TipoAsunto      { get; set; } = string.Empty;
        public string   Estado          { get; set; } = string.Empty;
        public DateTime FechaHoraInicio { get; set; }
    }

    public class ReglaVigencia
    {
        public string Campo        { get; set; } = string.Empty;
        public int    DiasVigencia { get; set; }
    }

    public class RegistroCopia
    {
        public int          Id                 { get; set; }
        public int          AudienciaOrigenId  { get; set; }
        public int          AudienciaDestinoId { get; set; }
        public List<string> CamposCopidos      { get; set; } = new();
        public string       UsuarioId          { get; set; } = string.Empty;
        public DateTime     FechaCopia         { get; set; }
    }

    public class DatoReutilizable
    {
        public string Campo { get; set; } = string.Empty;
        public string Valor { get; set; } = string.Empty;
    }

    public class DatoObsoleto
    {
        public string Campo  { get; set; } = string.Empty;
        public string Motivo { get; set; } = string.Empty;
    }

    public class ResultadoReutilizacion
    {
        public bool                  Exito            { get; private set; }
        public string                Mensaje          { get; private set; } = string.Empty;
        public int                   AudienciaOrigenId { get; private set; }
        public List<DatoReutilizable> DatosDisponibles { get; private set; } = new();
        public List<DatoObsoleto>    DatosObsoletos   { get; private set; } = new();

        public static ResultadoReutilizacion Exitoso(
            int origenId,
            List<DatoReutilizable> disponibles,
            List<DatoObsoleto> obsoletos) =>
            new ResultadoReutilizacion
            {
                Exito             = true,
                AudienciaOrigenId = origenId,
                DatosDisponibles  = disponibles,
                DatosObsoletos    = obsoletos
            };

        public static ResultadoReutilizacion Error(string mensaje) =>
            new ResultadoReutilizacion { Exito = false, Mensaje = mensaje };
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
