using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.ValidacionesTCA
{
    public class ValidacionesTCAService
    {
        private readonly List<Audiencia>           _audiencias;
        private readonly List<CatalogoTCA>         _catalogos;
        private readonly List<ReglaValidacionTCA>  _reglas;

        public ValidacionesTCAService(
            List<Audiencia>          audiencias,
            List<CatalogoTCA>        catalogos,
            List<ReglaValidacionTCA> reglas)
        {
            _audiencias = audiencias;
            _catalogos  = catalogos;
            _reglas     = reglas;
        }

        public ResultadoValidacionTCA Validar(SolicitudAgendarTCARequest request)
        {
            var erroresPorCampo = new Dictionary<string, string>();

            ValidarObligatoriedad(request, erroresPorCampo);
            ValidarFormato(request, erroresPorCampo);
            ValidarConsistencia(request, erroresPorCampo);
            ValidarCatalogos(request, erroresPorCampo);

            if (erroresPorCampo.Any())
                return ResultadoValidacionTCA.ConErrores(erroresPorCampo);

            return ResultadoValidacionTCA.Exitoso();
        }

        private void ValidarObligatoriedad(
            SolicitudAgendarTCARequest request,
            Dictionary<string, string> errores)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                errores["NumeroExpediente"] = "El número de expediente es requerido";

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                errores["TipoAudiencia"] = "El tipo de audiencia es requerido";

            if (string.IsNullOrEmpty(request.Secretario))
                errores["Secretario"] = "El secretario es requerido";

            if (string.IsNullOrEmpty(request.Partes))
                errores["Partes"] = "Las partes son requeridas";

            if (request.FechaHora == default)
                errores["FechaHora"] = "La fecha y hora son requeridas";

            if (request.TipoAsunto == "Procedimientos Federales Penales en Segunda Instancia" ||
                request.TipoAsunto == "Procedimientos Federales Administrativos y Civiles en Segunda Instancia")
            {
                if (string.IsNullOrEmpty(request.Procedimiento))
                    errores["Procedimiento"] = "El procedimiento es requerido para este tipo de asunto";
            }
        }

        private void ValidarFormato(
            SolicitudAgendarTCARequest request,
            Dictionary<string, string> errores)
        {
            if (!string.IsNullOrEmpty(request.NumeroExpediente))
            {
                var partes = request.NumeroExpediente.Split('/');
                if (partes.Length != 2 || !int.TryParse(partes[0], out _) ||
                    partes[1].Length != 4)
                    errores["NumeroExpediente"] =
                        "El formato del expediente debe ser número/AAAA";
            }

            // CORRECCIÓN ERR-VTCA-001: Operador lógico corregido
            // Se usa && para validar correctamente el rango 09:00 - 14:00
            if (request.FechaHora != default)
            {
                bool horarioValido = request.FechaHora.Hour >= 9 &&
                                     request.FechaHora.Hour < 14;

                if (!horarioValido)
                    errores["FechaHora"] =
                        "ERR-VTCA-001: El horario debe estar entre las 09:00 y las 14:00 hrs";
            }
        }

        private void ValidarConsistencia(
            SolicitudAgendarTCARequest request,
            Dictionary<string, string> errores)
        {
            if (request.FechaHora.Date < DateTime.Today)
            {
                errores["FechaHora"] = "La fecha no puede ser anterior al día en curso";
                return;
            }

            if (request.FechaHora.DayOfWeek == DayOfWeek.Saturday ||
                request.FechaHora.DayOfWeek == DayOfWeek.Sunday)
                errores["FechaHora"] = "No se pueden agendar audiencias en fin de semana";

            bool horarioOcupado = _audiencias.Any(a =>
                a.FechaHora == request.FechaHora &&
                a.Estado != "Cancelada");

            if (horarioOcupado)
                errores["FechaHora"] = "Ya existe una audiencia programada en ese horario";
        }

        private void ValidarCatalogos(
            SolicitudAgendarTCARequest request,
            Dictionary<string, string> errores)
        {
            if (!string.IsNullOrEmpty(request.TipoAudiencia))
            {
                bool tipoValido = _catalogos.Any(c =>
                    c.Tipo == "TipoAudiencia" &&
                    c.Valor == request.TipoAudiencia &&
                    c.EstaActivo);

                if (!tipoValido)
                    errores["TipoAudiencia"] =
                        "El tipo de audiencia no existe en el catálogo o no está vigente";
            }
        }

        public BorradorTCA GuardarBorrador(SolicitudAgendarTCARequest request) =>
            new BorradorTCA
            {
                Id               = Guid.NewGuid().ToString(),
                NumeroExpediente = request.NumeroExpediente,
                TipoAudiencia    = request.TipoAudiencia,
                Secretario       = request.Secretario,
                Partes           = request.Partes,
                FechaHora        = request.FechaHora,
                FechaGuardado    = DateTime.Now
            };
    }

    public class SolicitudAgendarTCARequest
    {
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAsunto       { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Secretario       { get; set; } = string.Empty;
        public string   Partes           { get; set; } = string.Empty;
        public DateTime FechaHora        { get; set; }
        public string?  Procedimiento    { get; set; }
    }

    public class ResultadoValidacionTCA
    {
        public bool                       Exito           { get; private set; }
        public Dictionary<string, string> ErroresPorCampo { get; private set; } = new();

        public static ResultadoValidacionTCA Exitoso() =>
            new ResultadoValidacionTCA { Exito = true };

        public static ResultadoValidacionTCA ConErrores(Dictionary<string, string> errores) =>
            new ResultadoValidacionTCA { Exito = false, ErroresPorCampo = errores };
    }

    public class BorradorTCA
    {
        public string   Id               { get; set; } = string.Empty;
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Secretario       { get; set; } = string.Empty;
        public string   Partes           { get; set; } = string.Empty;
        public DateTime FechaHora        { get; set; }
        public DateTime FechaGuardado    { get; set; }
    }

    public class CatalogoTCA
    {
        public string Tipo       { get; set; } = string.Empty;
        public string Valor      { get; set; } = string.Empty;
        public bool   EstaActivo { get; set; }
    }

    public class ReglaValidacionTCA
    {
        public string Campo   { get; set; } = string.Empty;
        public string Regla   { get; set; } = string.Empty;
        public string Mensaje { get; set; } = string.Empty;
    }
}
