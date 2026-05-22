using Agenda.Application.Common.Models;

namespace Agenda.Application.Productividad.Consulta.PanelProductividadEjecucion
{
    public class PanelProductividadEjecucionService
    {
        private readonly List<MesaEjecucion>     _mesas;
        private readonly List<UsuarioEjecucion>  _usuarios;
        private readonly List<AcuerdoCumplimiento> _acuerdos;

        public PanelProductividadEjecucionService(
            List<MesaEjecucion>       mesas,
            List<UsuarioEjecucion>    usuarios,
            List<AcuerdoCumplimiento> acuerdos)
        {
            _mesas    = mesas;
            _usuarios = usuarios;
            _acuerdos = acuerdos;
        }

        public List<PestanaMesaDto> ObtenerPestanas(int organoId)
        {
            var pestanas = _mesas
                .Where(m => m.OrganoId == organoId)
                .OrderBy(m => m.Orden)
                .Select(m => new PestanaMesaDto
                {
                    MesaId  = m.Id,
                    Nombre  = m.Nombre,
                    EsTitular = false
                }).ToList();

            pestanas.Add(new PestanaMesaDto
            {
                MesaId    = 0,
                Nombre    = "Titular",
                EsTitular = true
            });

            return pestanas;
        }

        public ResultadoPanelMesa ObtenerProductividadMesa(PanelMesaRequest request)
        {
            var usuariosMesa = _usuarios
                .Where(u => u.MesaId == request.MesaId || (request.EsTitular && u.EsTitular))
                .ToList();

            var panelesusuario = usuariosMesa.Select(u =>
                ConstruirPanelUsuario(u, request)).ToList();

            return ResultadoPanelMesa.Exitoso(panelesusuario);
        }

        private PanelUsuarioDto ConstruirPanelUsuario(
            UsuarioEjecucion usuario, PanelMesaRequest request)
        {
            var acuerdosPeriodo = _acuerdos
                .Where(a => a.UsuarioId == usuario.Id &&
                            ObtenerFechaInicio(a, usuario.Rol) >= request.FechaInicio &&
                            ObtenerFechaInicio(a, usuario.Rol) <= request.FechaFin)
                .ToList();

            var graficaVelas     = ConstruirGraficaVelas(acuerdosPeriodo, usuario.Rol);
            var graficaMeses     = ConstruirGraficaMeses(usuario.Id, usuario.Rol);
            var mesDetalle       = request.MesSeleccionado ?? DateTime.Today;
            var graficaSemana    = ConstruirGraficaSemana(usuario.Id, usuario.Rol, mesDetalle);

            return new PanelUsuarioDto
            {
                UsuarioId      = usuario.Id,
                NombreCompleto = usuario.NombreCompleto,
                NombreUsuario  = usuario.NombreUsuario,
                Rol            = usuario.Rol,
                Fotografia     = usuario.Fotografia,
                TituloGraficaVelas = ObtenerTituloVelas(usuario.Rol),
                EtiquetaInicio     = ObtenerEtiquetaInicio(usuario.Rol),
                EtiquetaFin        = ObtenerEtiquetaFin(usuario.Rol),
                GraficaVelas   = graficaVelas,
                GraficaMeses   = graficaMeses,
                GraficaSemana  = graficaSemana
            };
        }

        private List<VelaAcuerdoDto> ConstruirGraficaVelas(
            List<AcuerdoCumplimiento> acuerdos, string rol)
        {
            return acuerdos
                .Where(a => ObtenerFechaFin(a, rol).HasValue)
                .Select(a => new VelaAcuerdoDto
                {
                    NumeroExpediente = a.NumeroExpediente,
                    HoraInicio       = ObtenerFechaInicio(a, rol).ToString("HH:mm"),
                    HoraFin          = ObtenerFechaFin(a, rol)!.Value.ToString("HH:mm")
                })
                .OrderBy(v => v.HoraInicio)
                .ToList();
        }

        private List<BarraMesDto> ConstruirGraficaMeses(string usuarioId, string rol)
        {
            var hace12Meses  = DateTime.Today.AddMonths(-11);
            var inicioBarras = new DateTime(hace12Meses.Year, hace12Meses.Month, 1);

            return _acuerdos
                .Where(a => a.UsuarioId == usuarioId &&
                            ObtenerFechaFin(a, rol).HasValue &&
                            ObtenerFechaFin(a, rol)!.Value >= inicioBarras)
                .GroupBy(a => ObtenerFechaFin(a, rol)!.Value.ToString("MM/yyyy"))
                .Select(g => new BarraMesDto
                {
                    Mes      = g.Key,
                    Cantidad = g.Count()
                })
                .OrderBy(b => b.Mes)
                .ToList();
        }

        private List<BarraSemanaDto> ConstruirGraficaSemana(
            string usuarioId, string rol, DateTime mes)
        {
            var inicioMes = new DateTime(mes.Year, mes.Month, 1);
            var finMes    = inicioMes.AddMonths(1).AddDays(-1);

            return _acuerdos
                .Where(a => a.UsuarioId == usuarioId &&
                            ObtenerFechaFin(a, rol).HasValue &&
                            ObtenerFechaFin(a, rol)!.Value.Date >= inicioMes &&
                            ObtenerFechaFin(a, rol)!.Value.Date <= finMes)
                .GroupBy(a =>
                    $"Semana {((ObtenerFechaFin(a, rol)!.Value.Day - 1) / 7) + 1}")
                .Select(g => new BarraSemanaDto
                {
                    Semana   = g.Key,
                    Cantidad = g.Count()
                })
                .OrderBy(b => b.Semana)
                .ToList();
        }

        private DateTime ObtenerFechaInicio(AcuerdoCumplimiento a, string rol) => rol switch
        {
            "Secretario"       => a.FechaCreacion,
            "Oficial Judicial" => a.FechaRecepcion,
            _                  => a.FechaRevision ?? a.FechaCreacion
        };

        private DateTime? ObtenerFechaFin(AcuerdoCumplimiento a, string rol) => rol switch
        {
            "Secretario"       => a.FechaRevision,
            "Oficial Judicial" => a.FechaCreacion,
            _                  => a.FechaAutorizacion
        };

        private string ObtenerTituloVelas(string rol) => rol switch
        {
            "Secretario"       => "Tiempo de revisión",
            "Oficial Judicial" => "Tiempo de elaboración",
            _                  => "Tiempo de autorización"
        };

        private string ObtenerEtiquetaInicio(string rol) => rol switch
        {
            "Secretario"       => "Elaboración",
            "Oficial Judicial" => "Recepción",
            _                  => "Revisión"
        };

        private string ObtenerEtiquetaFin(string rol) => rol switch
        {
            "Secretario"       => "Revisión",
            "Oficial Judicial" => "Elaboración",
            _                  => "Autorización"
        };
    }

    public class PanelMesaRequest
    {
        public int       MesaId         { get; set; }
        public bool      EsTitular      { get; set; }
        public DateTime  FechaInicio    { get; set; } = DateTime.Today;
        public DateTime  FechaFin       { get; set; } = DateTime.Today;
        public DateTime? MesSeleccionado { get; set; }
    }

    public class MesaEjecucion
    {
        public int    Id       { get; set; }
        public int    OrganoId { get; set; }
        public string Nombre   { get; set; } = string.Empty;
        public int    Orden    { get; set; }
    }

    public class UsuarioEjecucion
    {
        public string Id             { get; set; } = string.Empty;
        public int    MesaId         { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string NombreUsuario  { get; set; } = string.Empty;
        public string Rol            { get; set; } = string.Empty;
        public string Fotografia     { get; set; } = string.Empty;
        public bool   EsTitular      { get; set; }
    }

    public class AcuerdoCumplimiento
    {
        public int      Id               { get; set; }
        public string   UsuarioId        { get; set; } = string.Empty;
        public string   NumeroExpediente { get; set; } = string.Empty;
        public DateTime FechaRecepcion   { get; set; }
        public DateTime FechaCreacion    { get; set; }
        public DateTime? FechaRevision   { get; set; }
        public DateTime? FechaAutorizacion { get; set; }
    }

    public class PestanaMesaDto
    {
        public int    MesaId    { get; set; }
        public string Nombre    { get; set; } = string.Empty;
        public bool   EsTitular { get; set; }
    }

    public class PanelUsuarioDto
    {
        public string              UsuarioId          { get; set; } = string.Empty;
        public string              NombreCompleto     { get; set; } = string.Empty;
        public string              NombreUsuario      { get; set; } = string.Empty;
        public string              Rol                { get; set; } = string.Empty;
        public string              Fotografia         { get; set; } = string.Empty;
        public string              TituloGraficaVelas { get; set; } = string.Empty;
        public string              EtiquetaInicio     { get; set; } = string.Empty;
        public string              EtiquetaFin        { get; set; } = string.Empty;
        public List<VelaAcuerdoDto> GraficaVelas      { get; set; } = new();
        public List<BarraMesDto>   GraficaMeses       { get; set; } = new();
        public List<BarraSemanaDto> GraficaSemana     { get; set; } = new();
    }

    public class VelaAcuerdoDto
    {
        public string NumeroExpediente { get; set; } = string.Empty;
        public string HoraInicio       { get; set; } = string.Empty;
        public string HoraFin          { get; set; } = string.Empty;
    }

    public class BarraMesDto
    {
        public string Mes      { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class BarraSemanaDto
    {
        public string Semana   { get; set; } = string.Empty;
        public int    Cantidad { get; set; }
    }

    public class ResultadoPanelMesa
    {
        public bool                  Exito    { get; private set; }
        public string                Mensaje  { get; private set; } = string.Empty;
        public List<PanelUsuarioDto> Usuarios { get; private set; } = new();

        public static ResultadoPanelMesa Exitoso(List<PanelUsuarioDto> usuarios) =>
            new ResultadoPanelMesa { Exito = true, Usuarios = usuarios };

        public static ResultadoPanelMesa Error(string mensaje) =>
            new ResultadoPanelMesa { Exito = false, Mensaje = mensaje };
    }
}
