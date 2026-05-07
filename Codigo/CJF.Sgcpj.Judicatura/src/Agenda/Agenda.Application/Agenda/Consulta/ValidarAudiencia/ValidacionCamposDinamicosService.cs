using Agenda.Application.Common.Models;

namespace Agenda.Application.Expedientes.Consulta.ValidacionCamposDinamicos
{
    public class ValidacionCamposDinamicosService
    {
        private readonly List<PlantillaCampos>    _plantillas;
        private readonly List<DefinicionCampo>    _definiciones;
        private readonly List<ReglasCondicionales> _reglasCondicionales;

        public ValidacionCamposDinamicosService(
            List<PlantillaCampos>     plantillas,
            List<DefinicionCampo>     definiciones,
            List<ReglasCondicionales> reglasCondicionales)
        {
            _plantillas          = plantillas;
            _definiciones        = definiciones;
            _reglasCondicionales = reglasCondicionales;
        }

        public ResultadoValidacionDinamica Validar(ValidacionDinamicaRequest request)
        {
            var plantilla = _plantillas.FirstOrDefault(p =>
                p.TipoExpediente == request.TipoExpediente && p.EstaActiva);

            if (plantilla == null)
                return ResultadoValidacionDinamica.Error(
                    "No existe una plantilla activa para este tipo de expediente. " +
                    "La captura no puede continuar");

            var camposPlantilla = _definiciones
                .Where(d => d.PlantillaId == plantilla.Id)
                .ToList();

            var erroresPorCampo   = new Dictionary<string, List<string>>();
            var cambosCambiados   = new List<string>();

            foreach (var definicion in camposPlantilla)
            {
                var errores = new List<string>();

                request.Valores.TryGetValue(definicion.Clave, out var valor);

                // Verificar cambio de definición
                if (definicion.VersionAnterior != null &&
                    definicion.FechaActualizacion > request.FechaInicioCaptura)
                    cambosCambiados.Add(definicion.Clave);

                // Validar obligatoriedad
                if (EsObligatorio(definicion, request.Contexto) &&
                    string.IsNullOrWhiteSpace(valor))
                {
                    errores.Add($"El campo '{definicion.Etiqueta}' es obligatorio");
                }
                else if (!string.IsNullOrWhiteSpace(valor))
                {
                    // Validar tipo
                    var errorTipo = ValidarTipo(valor, definicion.Tipo);
                    if (errorTipo != null) errores.Add(errorTipo);

                    // Validar formato
                    if (!string.IsNullOrEmpty(definicion.Formato))
                    {
                        var errorFormato = ValidarFormato(valor, definicion.Formato, definicion.Etiqueta);
                        if (errorFormato != null) errores.Add(errorFormato);
                    }
                }

                if (errores.Any())
                    erroresPorCampo[definicion.Clave] = errores;
            }

            return ResultadoValidacionDinamica.Exitoso(erroresPorCampo, cambosCambiados);
        }

        private bool EsObligatorio(DefinicionCampo definicion, string contexto)
        {
            if (definicion.EsObligatorio) return true;

            var regla = _reglasCondicionales.FirstOrDefault(r =>
                r.CampoId == definicion.Id && r.Contexto == contexto);

            return regla?.EsObligatorioEnContexto ?? false;
        }

        private string? ValidarTipo(string valor, string tipo)
        {
            return tipo switch
            {
                "Entero"  => int.TryParse(valor, out _)
                    ? null : "El valor debe ser un número entero",
                "Decimal" => decimal.TryParse(valor, out _)
                    ? null : "El valor debe ser un número decimal",
                "Fecha"   => DateTime.TryParse(valor, out _)
                    ? null : "El valor debe ser una fecha válida (dd/MM/yyyy)",
                "Boolean" => (valor == "true" || valor == "false")
                    ? null : "El valor debe ser verdadero o falso",
                _ => null
            };
        }

        private string? ValidarFormato(string valor, string formato, string etiqueta)
        {
            if (formato == "Numero/AAAA")
            {
                var partes = valor.Split('/');
                if (partes.Length != 2 || !int.TryParse(partes[0], out _) ||
                    partes[1].Length != 4)
                    return $"El campo '{etiqueta}' debe tener el formato Número/AAAA";
            }

            if (formato == "Email" && !valor.Contains('@'))
                return $"El campo '{etiqueta}' debe ser un correo electrónico válido";

            return null;
        }
    }

    public class ValidacionDinamicaRequest
    {
        public string                      TipoExpediente     { get; set; } = string.Empty;
        public string                      Contexto           { get; set; } = string.Empty;
        public DateTime                    FechaInicioCaptura { get; set; }
        public Dictionary<string, string>  Valores            { get; set; } = new();
    }

    public class PlantillaCampos
    {
        public int    Id             { get; set; }
        public string TipoExpediente { get; set; } = string.Empty;
        public string Nombre         { get; set; } = string.Empty;
        public bool   EstaActiva     { get; set; }
    }

    public class DefinicionCampo
    {
        public int      Id                  { get; set; }
        public int      PlantillaId         { get; set; }
        public string   Clave               { get; set; } = string.Empty;
        public string   Etiqueta            { get; set; } = string.Empty;
        public string   Tipo                { get; set; } = string.Empty;
        public string   Formato             { get; set; } = string.Empty;
        public bool     EsObligatorio       { get; set; }
        public string?  VersionAnterior     { get; set; }
        public DateTime FechaActualizacion  { get; set; }
    }

    public class ReglasCondicionales
    {
        public int    CampoId               { get; set; }
        public string Contexto              { get; set; } = string.Empty;
        public bool   EsObligatorioEnContexto { get; set; }
    }

    public class ResultadoValidacionDinamica
    {
        public bool                              Exito           { get; private set; }
        public string                            Mensaje         { get; private set; } = string.Empty;
        public Dictionary<string, List<string>>  ErroresPorCampo { get; private set; } = new();
        public List<string>                      CamposCambiados { get; private set; } = new();
        public bool                              TieneErrores    => ErroresPorCampo.Any();

        public static ResultadoValidacionDinamica Exitoso(
            Dictionary<string, List<string>> errores,
            List<string> camposCambiados) =>
            new ResultadoValidacionDinamica
            {
                Exito           = true,
                ErroresPorCampo = errores,
                CamposCambiados = camposCambiados
            };

        public static ResultadoValidacionDinamica Error(string mensaje) =>
            new ResultadoValidacionDinamica { Exito = false, Mensaje = mensaje };
    }
}
