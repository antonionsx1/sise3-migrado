using Agenda.Application.Common.Models;

namespace Agenda.Application.Expedientes.Consulta.CapturaExpedientes
{
    // ERROR ERR-EXP-002: Estructura incorrecta
    // Toda la lógica de formularios, navegación, validación de campos,
    // obtención de catálogos y guardado está en una sola clase sin
    // separación de responsabilidades.
    // Debería separarse en:
    // - CapturaExpedientesService: orquesta el flujo
    // - FormularioHelper: construye y navega entre formularios
    // - ValidacionCamposHelper: valida tipos y formatos de campos
    // - CatalogosHelper: obtiene catálogos dinámicos
    public class CapturaExpedientesService
    {
        private readonly List<TipoAsunto>         _tiposAsunto;
        private readonly List<CampoFormulario>    _campos;
        private readonly List<CatalogoCampo>      _catalogos;
        private readonly List<ValorCapturado>     _valoresCapturados;

        public CapturaExpedientesService(
            List<TipoAsunto>      tiposAsunto,
            List<CampoFormulario> campos,
            List<CatalogoCampo>   catalogos,
            List<ValorCapturado>  valoresCapturados)
        {
            _tiposAsunto       = tiposAsunto;
            _campos            = campos;
            _catalogos         = catalogos;
            _valoresCapturados = valoresCapturados;
        }

        // Navegación y formularios mezclados con validación
        public ResultadoFormulario ObtenerFormulario(ObtenerFormularioRequest request)
        {
            var formulariosPadre = _campos
                .Where(c => c.CatTipoAsuntoId == request.CatTipoAsuntoId && c.Padre == 0)
                .OrderBy(c => c.Nivel)
                .ThenBy(c => c.Orden)
                .ToList();

            if (!formulariosPadre.Any())
                return ResultadoFormulario.Error("No se encontraron formularios para este tipo de asunto");

            var formularioActual = request.FormularioIndex < formulariosPadre.Count
                ? formulariosPadre[request.FormularioIndex]
                : formulariosPadre[0];

            var campos = ObtenerCamposFormulario(formularioActual.TipoAsuntoId, request.CatTipoAsuntoId);
            var catalogosCargados = CargarCatalogos(campos);

            return ResultadoFormulario.Exitoso(new FormularioDto
            {
                TipoAsuntoId    = formularioActual.TipoAsuntoId,
                Descripcion     = formularioActual.Descripcion,
                IndiceActual    = request.FormularioIndex,
                TotalFormularios = formulariosPadre.Count,
                TieneSiguiente  = request.FormularioIndex < formulariosPadre.Count - 1,
                TieneAnterior   = request.FormularioIndex > 0,
                Campos          = campos,
                Catalogos       = catalogosCargados
            });
        }

        // Validación mezclada con guardado
        public ResultadoOperacion GuardarCaptura(GuardarCapturaRequest request)
        {
            var errores = new Dictionary<string, string>();

            foreach (var valor in request.Valores)
            {
                var campo = _campos.FirstOrDefault(c => c.TipoAsuntoId == valor.CampoId);
                if (campo == null) continue;

                if (campo.EsObligatorio && string.IsNullOrWhiteSpace(valor.Valor))
                {
                    errores[campo.Descripcion] = "Este campo es requerido";
                    continue;
                }

                // Validación de formato mezclada con guardado
                if (!string.IsNullOrWhiteSpace(valor.Valor) &&
                    !string.IsNullOrEmpty(campo.CampoFormatoDescripcion))
                {
                    var errorFormato = ValidarFormato(valor.Valor, campo.CampoFormatoDescripcion, campo.Descripcion);
                    if (errorFormato != null)
                        errores[campo.Descripcion] = errorFormato;
                }
            }

            if (errores.Any())
                return ResultadoOperacion.ConErrores(errores);

            foreach (var valor in request.Valores)
            {
                var existente = _valoresCapturados.FirstOrDefault(v =>
                    v.NumeroExpediente == request.NumeroExpediente &&
                    v.CampoId == valor.CampoId);

                if (existente != null)
                    existente.Valor = valor.Valor;
                else
                    _valoresCapturados.Add(new ValorCapturado
                    {
                        NumeroExpediente = request.NumeroExpediente,
                        CampoId          = valor.CampoId,
                        Valor            = valor.Valor
                    });
            }

            return ResultadoOperacion.Exitoso("Captura guardada correctamente");
        }

        // Obtención de catálogos mezclada en el mismo servicio
        private List<CampoFormularioDto> ObtenerCamposFormulario(int padre, int catTipoAsuntoId)
        {
            return _campos
                .Where(c => c.Padre == padre && c.CatTipoAsuntoId == catTipoAsuntoId && c.StatusReg == 1)
                .OrderBy(c => c.Nivel)
                .ThenBy(c => c.Orden)
                .Select(c => new CampoFormularioDto
                {
                    TipoAsuntoId          = c.TipoAsuntoId,
                    Descripcion           = c.Descripcion,
                    TipoCampo             = c.TipoCampo,
                    CampoFormatoDescripcion = c.CampoFormatoDescripcion,
                    EsObligatorio         = c.EsObligatorio,
                    CatalogoClave         = c.Catalogo,
                    EsSubMenu             = c.Clase == "submenu"
                }).ToList();
        }

        private Dictionary<string, List<OpcionCatalogo>> CargarCatalogos(
            List<CampoFormularioDto> campos)
        {
            var resultado = new Dictionary<string, List<OpcionCatalogo>>();
            foreach (var campo in campos.Where(c => !string.IsNullOrEmpty(c.CatalogoClave)))
            {
                var opciones = _catalogos
                    .Where(c => c.Clave == campo.CatalogoClave)
                    .Select(c => new OpcionCatalogo { Id = c.Id, Descripcion = c.Descripcion })
                    .ToList();
                resultado[campo.CatalogoClave] = opciones;
            }
            return resultado;
        }

        private string? ValidarFormato(string valor, string formato, string etiqueta)
        {
            return formato.ToUpper() switch
            {
                "NUMERO"  => int.TryParse(valor, out _)
                    ? null : $"El campo '{etiqueta}' debe ser un número",
                "DECIMAL" => decimal.TryParse(valor, out _)
                    ? null : $"El campo '{etiqueta}' debe ser un número decimal",
                "FECHA"   => DateTime.TryParse(valor, out _)
                    ? null : $"El campo '{etiqueta}' debe ser una fecha válida",
                _         => null
            };
        }
    }

    public class ObtenerFormularioRequest
    {
        public int CatTipoAsuntoId  { get; set; }
        public int FormularioIndex  { get; set; }
    }

    public class GuardarCapturaRequest
    {
        public string              NumeroExpediente { get; set; } = string.Empty;
        public List<ValorCampoDto> Valores          { get; set; } = new();
    }

    public class ValorCampoDto
    {
        public int    CampoId { get; set; }
        public string Valor   { get; set; } = string.Empty;
    }

    public class TipoAsunto
    {
        public int    CatTipoAsuntoId { get; set; }
        public string Descripcion     { get; set; } = string.Empty;
    }

    public class CampoFormulario
    {
        public int    TipoAsuntoId           { get; set; }
        public int    CatTipoAsuntoId        { get; set; }
        public int    Padre                  { get; set; }
        public int    Nivel                  { get; set; }
        public int    Orden                  { get; set; }
        public string Descripcion            { get; set; } = string.Empty;
        public string TipoCampo              { get; set; } = string.Empty;
        public string CampoFormatoDescripcion { get; set; } = string.Empty;
        public string Clase                  { get; set; } = string.Empty;
        public string Catalogo               { get; set; } = string.Empty;
        public bool   EsObligatorio          { get; set; }
        public int    StatusReg              { get; set; }
    }

    public class CatalogoCampo
    {
        public int    Id          { get; set; }
        public string Clave       { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
    }

    public class ValorCapturado
    {
        public string NumeroExpediente { get; set; } = string.Empty;
        public int    CampoId          { get; set; }
        public string Valor            { get; set; } = string.Empty;
    }

    public class FormularioDto
    {
        public int                              TipoAsuntoId     { get; set; }
        public string                           Descripcion      { get; set; } = string.Empty;
        public int                              IndiceActual     { get; set; }
        public int                              TotalFormularios { get; set; }
        public bool                             TieneSiguiente   { get; set; }
        public bool                             TieneAnterior    { get; set; }
        public List<CampoFormularioDto>         Campos           { get; set; } = new();
        public Dictionary<string, List<OpcionCatalogo>> Catalogos { get; set; } = new();
    }

    public class CampoFormularioDto
    {
        public int    TipoAsuntoId            { get; set; }
        public string Descripcion             { get; set; } = string.Empty;
        public string TipoCampo              { get; set; } = string.Empty;
        public string CampoFormatoDescripcion { get; set; } = string.Empty;
        public bool   EsObligatorio           { get; set; }
        public string CatalogoClave           { get; set; } = string.Empty;
        public bool   EsSubMenu               { get; set; }
    }

    public class OpcionCatalogo
    {
        public int    Id          { get; set; }
        public string Descripcion { get; set; } = string.Empty;
    }

    public class ResultadoFormulario
    {
        public bool         Exito      { get; private set; }
        public string       Mensaje    { get; private set; } = string.Empty;
        public FormularioDto? Formulario { get; private set; }

        public static ResultadoFormulario Exitoso(FormularioDto formulario) =>
            new ResultadoFormulario { Exito = true, Formulario = formulario };

        public static ResultadoFormulario Error(string mensaje) =>
            new ResultadoFormulario { Exito = false, Mensaje = mensaje };
    }

    public class ResultadoOperacion
    {
        public bool                       Exito   { get; private set; }
        public string                     Mensaje { get; private set; } = string.Empty;
        public Dictionary<string, string> Errores { get; private set; } = new();

        public static ResultadoOperacion Exitoso(string mensaje) =>
            new ResultadoOperacion { Exito = true, Mensaje = mensaje };

        public static ResultadoOperacion ConErrores(Dictionary<string, string> errores) =>
            new ResultadoOperacion { Exito = false, Errores = errores };
    }
}
