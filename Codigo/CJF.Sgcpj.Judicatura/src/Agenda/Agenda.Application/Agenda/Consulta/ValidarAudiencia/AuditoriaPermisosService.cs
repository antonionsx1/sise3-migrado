using Agenda.Application.Common.Models;

namespace Agenda.Application.Seguridad.Consulta.AuditoriaPermisos
{
    // CORRECCIÓN ERR-PER-001: Estructura corregida
    // Se separan las responsabilidades en clases independientes:
    // - AuditoriaPermisosService: orquesta consulta y exportación
    // - AccesoAuditoriaHelper: valida permisos de auditoría
    // - ExportacionAuditoriaHelper: genera el contenido exportable

    public class AuditoriaPermisosService
    {
        private readonly List<RegistroAuditoria>  _registros;
        private readonly AccesoAuditoriaHelper    _accesoHelper;
        private readonly ExportacionAuditoriaHelper _exportHelper;

        public AuditoriaPermisosService(
            List<RegistroAuditoria> registros,
            List<PermisoAuditoria>  permisosAuditoria)
        {
            _registros    = registros;
            _accesoHelper = new AccesoAuditoriaHelper(permisosAuditoria);
            _exportHelper = new ExportacionAuditoriaHelper();
        }

        public ResultadoAuditoria ConsultarCambios(
            FiltroAuditoriaPermisosRequest filtro, string auditorId)
        {
            if (!_accesoHelper.TieneAcceso(auditorId))
                return ResultadoAuditoria.Denegado(
                    "No cuenta con permiso de auditoría para consultar esta información");

            var query = _registros.AsEnumerable();

            if (filtro.FechaInicio.HasValue)
                query = query.Where(r => r.Fecha.Date >= filtro.FechaInicio.Value.Date);

            if (filtro.FechaFin.HasValue)
                query = query.Where(r => r.Fecha.Date <= filtro.FechaFin.Value.Date);

            if (!string.IsNullOrEmpty(filtro.RolId))
                query = query.Where(r => r.RolAfectado == filtro.RolId);

            if (!string.IsNullOrEmpty(filtro.Modulo))
                query = query.Where(r => r.Modulo == filtro.Modulo);

            var resultados = query.Select(r => new CambioPermisosDto
            {
                Id              = r.Id,
                TipoCambio      = r.TipoCambio,
                UsuarioAfectado = r.UsuarioAfectado,
                RolAfectado     = r.RolAfectado,
                Permiso         = r.Permiso,
                Modulo          = r.Modulo,
                EjecutadoPor    = r.EjecutadoPor,
                Fecha           = r.Fecha.ToString("dd/MM/yyyy HH:mm")
            }).ToList();

            if (!resultados.Any())
                return ResultadoAuditoria.SinResultados();

            return ResultadoAuditoria.Exitoso(resultados);
        }

        public ResultadoExportacion ExportarEvidencia(
            FiltroAuditoriaPermisosRequest filtro, string auditorId, string formato)
        {
            if (!_accesoHelper.TieneAcceso(auditorId))
                return ResultadoExportacion.Error("Acceso denegado para exportar evidencia");

            var resultado = ConsultarCambios(filtro, auditorId);
            if (!resultado.Exito)
                return ResultadoExportacion.Error(resultado.Mensaje);

            return _exportHelper.Exportar(resultado.Cambios, formato);
        }
    }

    public class AccesoAuditoriaHelper
    {
        private readonly List<PermisoAuditoria> _permisos;

        public AccesoAuditoriaHelper(List<PermisoAuditoria> permisos)
        {
            _permisos = permisos;
        }

        public bool TieneAcceso(string auditorId) =>
            _permisos.Any(p => p.UsuarioId == auditorId && p.PuedeAuditar);
    }

    public class ExportacionAuditoriaHelper
    {
        public ResultadoExportacion Exportar(
            List<CambioPermisosDto> cambios, string formato)
        {
            var encabezado = new List<string>
            {
                "ID", "Tipo Cambio", "Usuario Afectado", "Rol",
                "Permiso", "Módulo", "Ejecutado Por", "Fecha"
            };

            var filas = cambios.Select(c => new List<string>
            {
                c.Id.ToString(), c.TipoCambio, c.UsuarioAfectado,
                c.RolAfectado, c.Permiso, c.Modulo, c.EjecutadoPor, c.Fecha
            }).ToList();

            return ResultadoExportacion.Exitoso(encabezado, filas, formato);
        }
    }

    public class FiltroAuditoriaPermisosRequest
    {
        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin    { get; set; }
        public string    RolId       { get; set; } = string.Empty;
        public string    Modulo      { get; set; } = string.Empty;
    }

    public class RegistroAuditoria
    {
        public int      Id              { get; set; }
        public string   TipoCambio      { get; set; } = string.Empty;
        public string   UsuarioAfectado { get; set; } = string.Empty;
        public string   RolAfectado     { get; set; } = string.Empty;
        public string   Permiso         { get; set; } = string.Empty;
        public string   Modulo          { get; set; } = string.Empty;
        public string   EjecutadoPor    { get; set; } = string.Empty;
        public DateTime Fecha           { get; set; }
    }

    public class PermisoAuditoria
    {
        public string UsuarioId    { get; set; } = string.Empty;
        public bool   PuedeAuditar { get; set; }
    }

    public class CambioPermisosDto
    {
        public int    Id              { get; set; }
        public string TipoCambio      { get; set; } = string.Empty;
        public string UsuarioAfectado { get; set; } = string.Empty;
        public string RolAfectado     { get; set; } = string.Empty;
        public string Permiso         { get; set; } = string.Empty;
        public string Modulo          { get; set; } = string.Empty;
        public string EjecutadoPor    { get; set; } = string.Empty;
        public string Fecha           { get; set; } = string.Empty;
    }

    public class ResultadoAuditoria
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;
        public List<CambioPermisosDto> Cambios { get; private set; } = new();

        public static ResultadoAuditoria Exitoso(List<CambioPermisosDto> cambios) =>
            new ResultadoAuditoria { Exito = true, Cambios = cambios };

        public static ResultadoAuditoria SinResultados() =>
            new ResultadoAuditoria
            {
                Exito   = true,
                Mensaje = "No se encontraron cambios en el rango indicado"
            };

        public static ResultadoAuditoria Denegado(string mensaje) =>
            new ResultadoAuditoria { Exito = false, Mensaje = mensaje };

        public static ResultadoAuditoria Error(string mensaje) =>
            new ResultadoAuditoria { Exito = false, Mensaje = mensaje };
    }

    public class ResultadoExportacion
    {
        public bool               Exito      { get; private set; }
        public string             Mensaje    { get; private set; } = string.Empty;
        public List<string>       Encabezado { get; private set; } = new();
        public List<List<string>> Filas      { get; private set; } = new();
        public string             Formato    { get; private set; } = string.Empty;

        public static ResultadoExportacion Exitoso(
            List<string> encabezado, List<List<string>> filas, string formato) =>
            new ResultadoExportacion
            {
                Exito      = true,
                Encabezado = encabezado,
                Filas      = filas,
                Formato    = formato
            };

        public static ResultadoExportacion Error(string mensaje) =>
            new ResultadoExportacion { Exito = false, Mensaje = mensaje };
    }
}
