using Agenda.Application.Common.Models;

namespace AgendaCJPF.Application.AgendaCJPF.Consulta.ObtenerMovimientosAudiencia
{
    public class ConsultaMovimientosAudienciaService
    {
        private readonly List<MovimientoAudiencia> _movimientos;

        public ConsultaMovimientosAudienciaService(List<MovimientoAudiencia> movimientos)
        {
            _movimientos = movimientos;
        }

        public ResultadoMovimientos ObtenerMovimientos(string neun, string textoBusqueda)
        {
            if (string.IsNullOrEmpty(neun))
                return new ResultadoMovimientos
                {
                    Exito   = false,
                    Mensaje = "El NEUN del expediente es requerido"
                };

            var query = _movimientos.Where(m => m.Neun == neun);

            // ERROR ERR-CJPF2-004: Operador lógico erróneo en filtro de búsqueda
            // Se usa && en lugar de || por lo que solo retorna movimientos que
            // contengan el texto en TODOS los campos simultáneamente,
            // cuando debería retornar si contiene el texto en CUALQUIER campo
            if (!string.IsNullOrEmpty(textoBusqueda))
            {
                query = query.Where(m =>
                    m.Neun.Contains(textoBusqueda) &&
                    m.Audiencia.Contains(textoBusqueda) &&
                    m.Estatus.Contains(textoBusqueda));
            }

            // Solo audiencias con movimientos
            query = query.Where(m => m.TieneMovimientos);

            var movimientos = query.Select(m => new MovimientoAudienciaDto
            {
                Neun            = m.Neun,
                NumAudiencia    = m.NumAudiencia,
                Audiencia       = m.Audiencia,
                Estatus         = m.Estatus,
                Detalle         = m.Movimientos.Select(d => new DetalleMovimientoDto
                {
                    FechaModificacion  = d.FechaModificacion.ToString("dd/MM/yyyy HH:mm"),
                    Observaciones      = d.Observaciones,
                    CatalogoObservacion = d.CatalogoObservacion,
                    UsuarioModifico    = d.UsuarioModifico,
                    Sistema            = d.Sistema
                }).ToList()
            }).ToList();

            return new ResultadoMovimientos
            {
                Exito       = true,
                Movimientos = movimientos
            };
        }
    }

    public class MovimientoAudiencia
    {
        public string               Neun            { get; set; } = string.Empty;
        public int                  NumAudiencia    { get; set; }
        public string               Audiencia       { get; set; } = string.Empty;
        public string               Estatus         { get; set; } = string.Empty;
        public bool                 TieneMovimientos { get; set; }
        public List<DetalleMovimiento> Movimientos  { get; set; } = new();
    }

    public class DetalleMovimiento
    {
        public DateTime FechaModificacion   { get; set; }
        public string   Observaciones       { get; set; } = string.Empty;
        public string   CatalogoObservacion { get; set; } = string.Empty;
        public string   UsuarioModifico     { get; set; } = string.Empty;
        public string   Sistema             { get; set; } = string.Empty;
    }

    public class MovimientoAudienciaDto
    {
        public string               Neun         { get; set; } = string.Empty;
        public int                  NumAudiencia { get; set; }
        public string               Audiencia    { get; set; } = string.Empty;
        public string               Estatus      { get; set; } = string.Empty;
        public List<DetalleMovimientoDto> Detalle { get; set; } = new();
    }

    public class DetalleMovimientoDto
    {
        public string FechaModificacion   { get; set; } = string.Empty;
        public string Observaciones       { get; set; } = string.Empty;
        public string CatalogoObservacion { get; set; } = string.Empty;
        public string UsuarioModifico     { get; set; } = string.Empty;
        public string Sistema             { get; set; } = string.Empty;
    }

    public class ResultadoMovimientos
    {
        public bool   Exito       { get; set; }
        public string Mensaje     { get; set; } = string.Empty;
        public List<MovimientoAudienciaDto> Movimientos { get; set; } = new();
    }
}
