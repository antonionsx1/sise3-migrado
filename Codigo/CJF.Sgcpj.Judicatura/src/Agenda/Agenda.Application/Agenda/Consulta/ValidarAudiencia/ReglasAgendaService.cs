using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.ValidacionesAgenda
{
    public class ReglasAgendaService
    {
        private readonly List<Audiencia>  _audiencias;
        private readonly List<DiaInhabil> _diasInhabiles;
        private readonly List<OrganoJurisdiccional> _organos;

        public ReglasAgendaService(
            List<Audiencia>            audiencias,
            List<DiaInhabil>           diasInhabiles,
            List<OrganoJurisdiccional> organos)
        {
            _audiencias    = audiencias;
            _diasInhabiles = diasInhabiles;
            _organos       = organos;
        }

        public ResultadoReglasAgenda AplicarReglas(ReglasAgendaRequest request)
        {
            var errores      = new List<string>();
            var advertencias = new List<string>();

            ValidarCamposObligatorios(request, errores);
            ValidarCalendario(request, errores);
            ValidarConflictos(request, errores, advertencias);
            ValidarOrgano(request, errores);

            if (errores.Any())
                return ResultadoReglasAgenda.ConErrores(errores, advertencias);

            var alternativas = GenerarAlternativas(request);
            return ResultadoReglasAgenda.Exitoso(alternativas, advertencias);
        }

        private void ValidarCamposObligatorios(
            ReglasAgendaRequest request, List<string> errores)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                errores.Add("El número de expediente es requerido");

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                errores.Add("El tipo de audiencia es requerido");

            if (string.IsNullOrEmpty(request.OrganoId))
                errores.Add("El órgano jurisdiccional es requerido");

            if (request.FechaHora == default)
                errores.Add("La fecha y hora son requeridas");
        }

        private void ValidarCalendario(
            ReglasAgendaRequest request, List<string> errores)
        {
            if (request.FechaHora.Date < DateTime.Today)
            {
                errores.Add("La fecha no puede ser anterior al día en curso");
                return;
            }

            // CORRECCIÓN ERR-VAL-001: Comentario corregido
            // Se validan días inhábiles configurados incluyendo festivos nacionales,
            // días de asueto locales y cualquier día configurado como inhábil en el sistema
            if (_diasInhabiles.Any(d => d.Fecha.Date == request.FechaHora.Date))
            {
                errores.Add("La fecha seleccionada corresponde a un día inhábil o de asueto");
                return;
            }

            if (request.FechaHora.DayOfWeek == DayOfWeek.Saturday ||
                request.FechaHora.DayOfWeek == DayOfWeek.Sunday)
                errores.Add("No se pueden agendar audiencias en fines de semana");

            bool horarioValido = request.FechaHora.Hour >= 9 &&
                                 request.FechaHora.Hour < 14;

            if (!horarioValido)
                errores.Add("El horario debe estar comprendido entre las 09:00 y las 14:00 hrs");
        }

        private void ValidarConflictos(
            ReglasAgendaRequest request,
            List<string> errores,
            List<string> advertencias)
        {
            bool conflictoHorario = _audiencias.Any(a =>
                a.FechaHora == request.FechaHora &&
                a.Estado != "Cancelada");

            if (conflictoHorario)
                errores.Add("Ya existe una audiencia programada en ese horario. " +
                    "Se sugerirán horarios alternativos disponibles");

            var ultimaAudiencia = _audiencias
                .Where(a => a.NumeroExpediente == request.NumeroExpediente &&
                            a.Estado != "Cancelada")
                .OrderByDescending(a => a.FechaHora)
                .FirstOrDefault();

            if (ultimaAudiencia != null && string.IsNullOrEmpty(ultimaAudiencia.Estado))
                advertencias.Add("La última audiencia del expediente no tiene estado marcado");
        }

        private void ValidarOrgano(
            ReglasAgendaRequest request, List<string> errores)
        {
            if (string.IsNullOrEmpty(request.OrganoId)) return;

            var organo = _organos.FirstOrDefault(o => o.Id == request.OrganoId);
            if (organo == null)
                errores.Add("El órgano jurisdiccional indicado no existe");
            else if (!organo.EstaActivo)
                errores.Add($"El órgano {organo.Nombre} no se encuentra activo");
        }

        private List<DateTime> GenerarAlternativas(ReglasAgendaRequest request)
        {
            var alternativas = new List<DateTime>();
            var base_ = request.FechaHora;

            for (int i = 1; alternativas.Count < 3 && i <= 8; i++)
            {
                var candidato = base_.AddHours(i);
                bool valido = candidato.Hour >= 9 &&
                              candidato.Hour < 14 &&
                              candidato.DayOfWeek != DayOfWeek.Saturday &&
                              candidato.DayOfWeek != DayOfWeek.Sunday &&
                              !_diasInhabiles.Any(d => d.Fecha.Date == candidato.Date) &&
                              !_audiencias.Any(a => a.FechaHora == candidato &&
                                                    a.Estado != "Cancelada");
                if (valido)
                    alternativas.Add(candidato);
            }

            return alternativas;
        }
    }

    public class ReglasAgendaRequest
    {
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   OrganoId         { get; set; } = string.Empty;
        public DateTime FechaHora        { get; set; }
        public string   TipoAsunto       { get; set; } = string.Empty;
    }

    public class ResultadoReglasAgenda
    {
        public bool           Exito        { get; private set; }
        public List<string>   Errores      { get; private set; } = new();
        public List<string>   Advertencias { get; private set; } = new();
        public List<DateTime> Alternativas { get; private set; } = new();

        public static ResultadoReglasAgenda Exitoso(
            List<DateTime> alternativas, List<string> advertencias) =>
            new ResultadoReglasAgenda
            {
                Exito = true, Alternativas = alternativas, Advertencias = advertencias
            };

        public static ResultadoReglasAgenda ConErrores(
            List<string> errores, List<string> advertencias) =>
            new ResultadoReglasAgenda
            {
                Exito = false, Errores = errores, Advertencias = advertencias
            };
    }

    public class DiaInhabil
    {
        public DateTime Fecha       { get; set; }
        public string   Descripcion { get; set; } = string.Empty;
        public string   Tipo        { get; set; } = string.Empty;
    }

    public class OrganoJurisdiccional
    {
        public string Id         { get; set; } = string.Empty;
        public string Nombre     { get; set; } = string.Empty;
        public bool   EstaActivo { get; set; }
    }
}
