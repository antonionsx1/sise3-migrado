using Agenda.Application.Common.Models;
using Agenda.Domain.Entities;

namespace Agenda.Application.Agenda.Consulta.ValidacionesAgenda
{
    public class ValidacionesAgendaService
    {
        private readonly List<Audiencia>    _audiencias;
        private readonly List<DiaInhabil>   _diasInhabiles;
        private readonly List<SalaCJPF>     _salas;

        public ValidacionesAgendaService(
            List<Audiencia>  audiencias,
            List<DiaInhabil> diasInhabiles,
            List<SalaCJPF>   salas)
        {
            _audiencias    = audiencias;
            _diasInhabiles = diasInhabiles;
            _salas         = salas;
        }

        public ResultadoValidacion ValidarAgenda(ValidacionAgendaRequest request)
        {
            var errores = new List<string>();

            ValidarCamposObligatorios(request, errores);
            ValidarFechaHora(request, errores);
            ValidarDisponibilidadSala(request, errores);
            ValidarDisponibilidadHorario(request, errores);

            if (errores.Any())
                return ResultadoValidacion.ConErrores(errores);

            var sugerencias = ObtenerSugerenciasHorario(request);

            return ResultadoValidacion.Exitoso(sugerencias);
        }

        private void ValidarCamposObligatorios(
            ValidacionAgendaRequest request, List<string> errores)
        {
            if (string.IsNullOrEmpty(request.NumeroExpediente))
                errores.Add("El número de expediente es requerido");

            if (string.IsNullOrEmpty(request.TipoAudiencia))
                errores.Add("El tipo de audiencia es requerido");

            if (string.IsNullOrEmpty(request.Secretario))
                errores.Add("El secretario es requerido");

            if (string.IsNullOrEmpty(request.Partes))
                errores.Add("Las partes son requeridas");
        }

        private void ValidarFechaHora(
            ValidacionAgendaRequest request, List<string> errores)
        {
            if (request.FechaHora.Date < DateTime.Today)
            {
                errores.Add("La fecha no puede ser anterior al día en curso");
                return;
            }

            if (_diasInhabiles.Any(d => d.Fecha.Date == request.FechaHora.Date))
            {
                errores.Add("La fecha seleccionada corresponde a un día inhábil");
                return;
            }

            if (request.FechaHora.DayOfWeek == DayOfWeek.Saturday ||
                request.FechaHora.DayOfWeek == DayOfWeek.Sunday)
                errores.Add("No se pueden agendar audiencias en fin de semana");

            bool horarioValido = request.FechaHora.Hour >= 9 &&
                                 request.FechaHora.Hour < 14;

            if (!horarioValido)
                errores.Add("El horario debe estar entre las 09:00 y las 14:00 hrs");

            if (request.FechaHora.Date == DateTime.Today &&
                request.FechaHora.TimeOfDay <= DateTime.Now.TimeOfDay)
                errores.Add("La hora debe ser posterior a la hora actual");
        }

        private void ValidarDisponibilidadSala(
            ValidacionAgendaRequest request, List<string> errores)
        {
            if (string.IsNullOrEmpty(request.Sala)) return;

            var sala = _salas.FirstOrDefault(s => s.Id == request.Sala);
            if (sala == null)
            {
                errores.Add("La sala indicada no existe");
                return;
            }

            if (!sala.EstaActiva)
                errores.Add($"La sala {request.Sala} no se encuentra disponible");
        }

        private void ValidarDisponibilidadHorario(
            ValidacionAgendaRequest request, List<string> errores)
        {
            bool horarioOcupado = _audiencias.Any(a =>
                a.FechaHora == request.FechaHora &&
                a.Estado != "Cancelada");

            if (horarioOcupado)
                errores.Add("Ya existe una audiencia programada en ese horario");
        }

        private List<DateTime> ObtenerSugerenciasHorario(ValidacionAgendaRequest request)
        {
            var sugerencias = new List<DateTime>();
            var fecha = request.FechaHora;

            for (int i = 1; i <= 3; i++)
            {
                var candidato = fecha.AddHours(i);
                bool disponible = candidato.Hour >= 9 &&
                                  candidato.Hour < 14 &&
                                  !_audiencias.Any(a => a.FechaHora == candidato &&
                                                        a.Estado != "Cancelada");
                if (disponible)
                    sugerencias.Add(candidato);
            }

            return sugerencias;
        }
    }

    public class ValidacionAgendaRequest
    {
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   TipoAudiencia    { get; set; } = string.Empty;
        public string   Secretario       { get; set; } = string.Empty;
        public string   Partes           { get; set; } = string.Empty;
        public DateTime FechaHora        { get; set; }
        public string   Sala             { get; set; } = string.Empty;
        public string   TipoAsunto       { get; set; } = string.Empty;
    }

    public class ResultadoValidacion
    {
        public bool          Exito       { get; private set; }
        public List<string>  Errores     { get; private set; } = new();
        public List<DateTime> Sugerencias { get; private set; } = new();

        public static ResultadoValidacion Exitoso(List<DateTime> sugerencias) =>
            new ResultadoValidacion { Exito = true, Sugerencias = sugerencias };

        public static ResultadoValidacion ConErrores(List<string> errores) =>
            new ResultadoValidacion { Exito = false, Errores = errores };
    }

    public class DiaInhabil
    {
        public DateTime Fecha       { get; set; }
        public string   Descripcion { get; set; } = string.Empty;
    }

    public class SalaCJPF
    {
        public string Id        { get; set; } = string.Empty;
        public string Nombre    { get; set; } = string.Empty;
        public bool   EstaActiva { get; set; }
    }
}
