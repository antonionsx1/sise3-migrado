using Agenda.Application.Common.Models;

namespace Agenda.Application.Expedientes.Comandos.GuardarExpediente
{
    public class GuardarExpedienteService
    {
        private readonly List<CampoFormulario> _campos;
        private readonly List<ValorCapturado>  _valoresCapturados;

        public GuardarExpedienteService(
            List<CampoFormulario> campos,
            List<ValorCapturado>  valoresCapturados)
        {
            _campos            = campos;
            _valoresCapturados = valoresCapturados;
        }

        public ResultadoOperacion Guardar(GuardarExpedienteRequest request)
        {
            if (!request.Confirmado)
                return ResultadoOperacion.Error(
                    "Se requiere confirmación para guardar el expediente");

            if (string.IsNullOrEmpty(request.NumeroExpediente))
                return ResultadoOperacion.Error("El número de expediente es requerido");

            if (request.Valores == null || !request.Valores.Any())
                return ResultadoOperacion.Error(
                    "No se han completado los formularios. Capture la información requerida antes de guardar");

            var erroresPorCampo = ValidarCampos(request);
            if (erroresPorCampo.Any())
                return ResultadoOperacion.ConErrores(
                    "No se han completado los formularios correctamente",
                    erroresPorCampo);

            PersistirValores(request);

            return ResultadoOperacion.Exitoso(
                "Los datos se han Guardado correctamente");
        }

        private Dictionary<string, string> ValidarCampos(GuardarExpedienteRequest request)
        {
            var errores = new Dictionary<string, string>();

            // Validar campos obligatorios
            var camposObligatorios = _campos
                .Where(c => c.CatTipoAsuntoId == request.CatTipoAsuntoId &&
                            c.EsObligatorio && c.StatusReg == 1)
                .ToList();

            foreach (var campo in camposObligatorios)
            {
                var valor = request.Valores
                    .FirstOrDefault(v => v.CampoId == campo.TipoAsuntoId);

                if (valor == null || string.IsNullOrWhiteSpace(valor.Valor))
                    errores[campo.Descripcion] = "Este campo es requerido";
            }

            // Validar campos en conjunto (dependencias)
            var gruposDependencia = _campos
                .Where(c => c.CatTipoAsuntoId == request.CatTipoAsuntoId &&
                            c.GrupoDependencia > 0 && c.StatusReg == 1)
                .GroupBy(c => c.GrupoDependencia)
                .ToList();

            foreach (var grupo in gruposDependencia)
            {
                var camposGrupo = grupo.ToList();
                var valoresGrupo = camposGrupo.Select(c =>
                    request.Valores.FirstOrDefault(v => v.CampoId == c.TipoAsuntoId)?.Valor)
                    .ToList();

                bool algunoCapturado = valoresGrupo.Any(v => !string.IsNullOrWhiteSpace(v));
                bool todosCapturados = valoresGrupo.All(v => !string.IsNullOrWhiteSpace(v));

                if (algunoCapturado && !todosCapturados)
                {
                    foreach (var campo in camposGrupo)
                    {
                        var valorCampo = request.Valores
                            .FirstOrDefault(v => v.CampoId == campo.TipoAsuntoId)?.Valor;

                        if (string.IsNullOrWhiteSpace(valorCampo))
                            errores[campo.Descripcion] =
                                "Este campo debe capturarse en conjunto con los demás del grupo";
                    }
                }
            }

            return errores;
        }

        private void PersistirValores(GuardarExpedienteRequest request)
        {
            foreach (var valor in request.Valores)
            {
                var existente = _valoresCapturados.FirstOrDefault(v =>
                    v.NumeroExpediente == request.NumeroExpediente &&
                    v.CampoId == valor.CampoId);

                if (existente != null)
                {
                    existente.Valor            = valor.Valor;
                    existente.FechaModificacion = DateTime.Now;
                }
                else
                {
                    _valoresCapturados.Add(new ValorCapturado
                    {
                        NumeroExpediente  = request.NumeroExpediente,
                        CampoId           = valor.CampoId,
                        Valor             = valor.Valor,
                        FechaCaptura      = DateTime.Now,
                        FechaModificacion = DateTime.Now
                    });
                }
            }
        }
    }

    public class GuardarExpedienteRequest
    {
        public string              NumeroExpediente { get; set; } = string.Empty;
        public int                 CatTipoAsuntoId  { get; set; }
        public bool                Confirmado       { get; set; }
        public List<ValorCampoDto> Valores          { get; set; } = new();
    }

    public class ValorCampoDto
    {
        public int    CampoId { get; set; }
        public string Valor   { get; set; } = string.Empty;
    }

    public class CampoFormulario
    {
        public int    TipoAsuntoId   { get; set; }
        public int    CatTipoAsuntoId { get; set; }
        public string Descripcion    { get; set; } = string.Empty;
        public bool   EsObligatorio  { get; set; }
        public int    GrupoDependencia { get; set; }
        public int    StatusReg      { get; set; }
    }

    public class ValorCapturado
    {
        public string   NumeroExpediente  { get; set; } = string.Empty;
        public int      CampoId           { get; set; }
        public string   Valor             { get; set; } = string.Empty;
        public DateTime FechaCaptura      { get; set; }
        public DateTime FechaModificacion { get; set; }
    }

    public class ResultadoOperacion
    {
        public bool                       Exito          { get; private set; }
        public string                     Mensaje        { get; private set; } = string.Empty;
        public Dictionary<string, string> ErroresCampos  { get; private set; } = new();

        public static ResultadoOperacion Exitoso(string mensaje) =>
            new ResultadoOperacion { Exito = true, Mensaje = mensaje };

        public static ResultadoOperacion ConErrores(
            string mensaje, Dictionary<string, string> errores) =>
            new ResultadoOperacion
            {
                Exito         = false,
                Mensaje       = mensaje,
                ErroresCampos = errores
            };

        public static ResultadoOperacion Error(string mensaje) =>
            new ResultadoOperacion { Exito = false, Mensaje = mensaje };
    }
}
