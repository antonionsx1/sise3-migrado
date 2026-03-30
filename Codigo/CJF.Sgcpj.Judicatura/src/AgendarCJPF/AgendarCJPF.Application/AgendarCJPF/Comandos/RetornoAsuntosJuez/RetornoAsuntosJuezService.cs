using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.RetornoAsuntosJuez
{
    public class RetornoAsuntosJuezService
    {
        private readonly List<AudienciaCJPF> _audiencias;
        private readonly List<JuezCJPF>      _jueces;

        public RetornoAsuntosJuezService(
            List<AudienciaCJPF> audiencias,
            List<JuezCJPF>      jueces)
        {
            _audiencias = audiencias;
            _jueces     = jueces;
        }

        public ResultadoOperacion ReturnarAsuntos(ReturnarAsuntosRequest request)
        {
            // CORRECCIÓN ERR-RET-001: Manejo de errores corregido
            // Se valida que el usuario sea Administrador antes de ejecutar el returno
            if (request.RolUsuario != "Administrador")
                return ResultadoOperacion.Error(
                    "ERR-RET-001: Solo el Administrador puede realizar el returno de asuntos");

            if (string.IsNullOrEmpty(request.JuezOrigenId))
                return ResultadoOperacion.Error("Debe seleccionar el juez de origen");

            if (string.IsNullOrEmpty(request.JuezDestinoId))
                return ResultadoOperacion.Error("Debe seleccionar el juez destino");

            if (request.JuezOrigenId == request.JuezDestinoId)
                return ResultadoOperacion.Error(
                    "El juez de origen y destino no pueden ser el mismo");

            // CORRECCIÓN ERR-RET-002: Manejo de errores corregido
            // Se valida que el usuario haya confirmado el returno antes de ejecutarlo
            if (!request.Confirmado)
                return ResultadoOperacion.Error(
                    "ERR-RET-002: Se requiere confirmación para realizar el returno de asuntos");

            if (string.IsNullOrEmpty(request.CausaPrecisa))
                return ResultadoOperacion.Error("Debe indicar la causa precisa del returno");

            if (string.IsNullOrEmpty(request.FirmaElectronica))
                return ResultadoOperacion.Error("La firma electrónica es requerida");

            var juezDestino = _jueces.FirstOrDefault(j =>
                j.Id == request.JuezDestinoId && j.EstaActivo);

            if (juezDestino == null)
                return ResultadoOperacion.Error("El juez destino no se encuentra activo");

            var audienciasATransferir = _audiencias
                .Where(a => a.JuezAsignado == request.JuezOrigenId &&
                            a.Estado != "Celebrada" &&
                            a.Estado != "Cancelada")
                .ToList();

            if (!audienciasATransferir.Any())
                return ResultadoOperacion.Error(
                    "No se encontraron audiencias activas para el juez de origen");

            foreach (var audiencia in audienciasATransferir)
            {
                audiencia.JuezAnterior  = audiencia.JuezAsignado;
                audiencia.JuezAsignado  = request.JuezDestinoId;
                audiencia.MotivoRetorno = request.CausaPrecisa;
                audiencia.FechaRetorno  = DateTime.Now;
            }

            return ResultadoOperacion.Exitoso(
                $"Se retornaron {audienciasATransferir.Count} audiencias del juez " +
                $"{request.JuezOrigenId} al juez {juezDestino.Nombre} exitosamente");
        }

        public List<JuezCJPF> ObtenerJuecesOrigen() => _jueces;

        public List<JuezCJPF> ObtenerJuecesDestino() =>
            _jueces.Where(j => j.EstaActivo).ToList();
    }

    public class ReturnarAsuntosRequest
    {
        public string JuezOrigenId         { get; set; } = string.Empty;
        public string JuezDestinoId        { get; set; } = string.Empty;
        public bool   Confirmado           { get; set; }
        public string CausaPrecisa         { get; set; } = string.Empty;
        public string FirmaElectronica     { get; set; } = string.Empty;
        public string UsuarioAdministrador { get; set; } = string.Empty;
        public string RolUsuario           { get; set; } = string.Empty;
    }

    public class AudienciaCJPF
    {
        public int      Id               { get; set; }
        public string   NumeroExpediente { get; set; } = string.Empty;
        public string   JuezAsignado     { get; set; } = string.Empty;
        public string?  JuezAnterior     { get; set; }
        public string   Estado           { get; set; } = string.Empty;
        public string?  MotivoRetorno    { get; set; }
        public DateTime? FechaRetorno    { get; set; }
    }

    public class JuezCJPF
    {
        public string Id         { get; set; } = string.Empty;
        public string Nombre     { get; set; } = string.Empty;
        public bool   EstaActivo { get; set; }
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
