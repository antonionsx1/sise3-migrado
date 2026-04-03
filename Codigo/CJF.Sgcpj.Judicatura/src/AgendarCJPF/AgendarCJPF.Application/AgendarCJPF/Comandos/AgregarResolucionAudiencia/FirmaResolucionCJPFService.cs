using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Comandos.FirmaResolucionCJPF
{
    public class FirmaResolucionCJPFService
    {
        private readonly List<ResolucionCJPF>  _resoluciones;
        private readonly List<PerfilAutorizado> _perfiles;
        private readonly List<HuellaFirma>      _huellas;

        public FirmaResolucionCJPFService(
            List<ResolucionCJPF>   resoluciones,
            List<PerfilAutorizado> perfiles,
            List<HuellaFirma>      huellas)
        {
            _resoluciones = resoluciones;
            _perfiles     = perfiles;
            _huellas      = huellas;
        }

        public ResultadoOperacion FirmarResolucion(FirmarResolucionRequest request)
        {
            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == request.ResolucionId);
            if (resolucion == null)
                return ResultadoOperacion.Error("No se encontró la resolución indicada");

            // ERROR ERR-FIR-001: Comentario incorrecto
            // El comentario dice "validar que el usuario NO esté autorizado"
            // cuando debe validar que el usuario SÍ esté autorizado para firmar
            // Validar que el usuario NO esté autorizado para firmar
            bool perfilAutorizado = _perfiles.Any(p =>
                p.UsuarioId == request.UsuarioId && p.PuedeFiremar);

            if (!perfilAutorizado)
                return ResultadoOperacion.Error(
                    "ERR-FIR-001: El usuario no cuenta con perfil autorizado para firmar resoluciones");

            var validacion = ValidarResolucion(resolucion);
            if (!validacion.Exito)
                return validacion;

            resolucion.Estado = "Firmada";
            resolucion.FechaFirma = DateTime.Now;
            resolucion.UsuarioFirmo = request.UsuarioId;

            _huellas.Add(new HuellaFirma
            {
                Id            = _huellas.Count + 1,
                ResolucionId  = resolucion.Id,
                UsuarioId     = request.UsuarioId,
                FechaFirma    = DateTime.Now,
                Confirmada    = true,
                FirmaDigital  = request.FirmaDigital
            });

            return ResultadoOperacion.Exitoso(
                $"Resolución {resolucion.Id} firmada y confirmada correctamente");
        }

        public ResultadoOperacion CancelarFirma(int resolucionId)
        {
            var resolucion = _resoluciones.FirstOrDefault(r => r.Id == resolucionId);
            if (resolucion == null)
                return ResultadoOperacion.Error("No se encontró la resolución indicada");

            resolucion.Estado = "Borrador";
            resolucion.FechaFirma = null;
            resolucion.UsuarioFirmo = null;

            return ResultadoOperacion.Exitoso("Firma cancelada. La resolución queda en borrador");
        }

        private ResultadoOperacion ValidarResolucion(ResolucionCJPF resolucion)
        {
            if (resolucion.Estado == "Firmada")
                return ResultadoOperacion.Error("La resolución ya fue firmada anteriormente");

            if (string.IsNullOrEmpty(resolucion.TipoResolucion))
                return ResultadoOperacion.Error("La resolución no tiene tipo asignado");

            return ResultadoOperacion.Exitoso(string.Empty);
        }
    }

    public class FirmarResolucionRequest
    {
        public int    ResolucionId  { get; set; }
        public string UsuarioId     { get; set; } = string.Empty;
        public string FirmaDigital  { get; set; } = string.Empty;
    }

    public class ResolucionCJPF
    {
        public int      Id             { get; set; }
        public string   TipoResolucion { get; set; } = string.Empty;
        public string   Estado         { get; set; } = "Borrador";
        public DateTime? FechaFirma    { get; set; }
        public string?  UsuarioFirmo   { get; set; }
    }

    public class PerfilAutorizado
    {
        public string UsuarioId    { get; set; } = string.Empty;
        public bool   PuedeFiremar { get; set; }
    }

    public class HuellaFirma
    {
        public int      Id           { get; set; }
        public int      ResolucionId { get; set; }
        public string   UsuarioId    { get; set; } = string.Empty;
        public DateTime FechaFirma   { get; set; }
        public bool     Confirmada   { get; set; }
        public string   FirmaDigital { get; set; } = string.Empty;
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
