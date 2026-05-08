using Agenda.Application.Common.Models;

namespace Agenda.Application.Seguridad.Comandos.ReglasHerenciaPerfiles
{
    public class ReglasHerenciaPerfilesService
    {
        private readonly List<PerfilSistema>   _perfiles;
        private readonly List<PrivilegioSistema> _privilegios;

        public ReglasHerenciaPerfilesService(
            List<PerfilSistema>    perfiles,
            List<PrivilegioSistema> privilegios)
        {
            _perfiles    = perfiles;
            _privilegios = privilegios;
        }

        public ResultadoOperacion DefinirHerencia(DefinirHerenciaRequest request)
        {
            var perfilHijo = _perfiles.FirstOrDefault(p => p.Id == request.PerfilHijoId);
            if (perfilHijo == null)
                return ResultadoOperacion.Error("No se encontró el perfil hijo indicado");

            var perfilPadre = _perfiles.FirstOrDefault(p => p.Id == request.PerfilPadreId);
            if (perfilPadre == null)
                return ResultadoOperacion.Error("No se encontró el perfil padre indicado");

            if (request.PerfilHijoId == request.PerfilPadreId)
                return ResultadoOperacion.Error("Un perfil no puede heredar de sí mismo");

            if (DetectaCiclo(request.PerfilHijoId, request.PerfilPadreId))
                return ResultadoOperacion.Error(
                    "Se detectó un ciclo de herencia no permitido. " +
                    "La configuración fue rechazada para mantener la integridad del modelo");

            perfilHijo.PerfilPadreId = request.PerfilPadreId;

            return ResultadoOperacion.Exitoso(
                $"Herencia definida: perfil '{perfilHijo.Nombre}' hereda de '{perfilPadre.Nombre}'");
        }

        public ResultadoPrivilegios ObtenerPrivilegios(int perfilId)
        {
            var perfil = _perfiles.FirstOrDefault(p => p.Id == perfilId);
            if (perfil == null)
                return ResultadoPrivilegios.Error("No se encontró el perfil indicado");

            var heredados    = ObtenerPrivilegiosHeredados(perfilId);
            var propios      = _privilegios.Where(p => p.PerfilId == perfilId).ToList();
            var sobrescritos = propios
                .Where(p => heredados.Any(h => h.Accion == p.Accion))
                .ToList();

            return ResultadoPrivilegios.Exitoso(heredados, propios, sobrescritos);
        }

        public ResultadoOperacion EliminarPerfilPadre(int perfilPadreId)
        {
            var hijosDependientes = _perfiles
                .Where(p => p.PerfilPadreId == perfilPadreId)
                .ToList();

            if (hijosDependientes.Any())
            {
                var nombresHijos = string.Join(", ", hijosDependientes.Select(h => h.Nombre));
                return ResultadoOperacion.Error(
                    $"El perfil tiene perfiles hijos dependientes: {nombresHijos}. " +
                    "Debe reasignarlos antes de eliminar el perfil padre");
            }

            var perfil = _perfiles.FirstOrDefault(p => p.Id == perfilPadreId);
            if (perfil == null)
                return ResultadoOperacion.Error("No se encontró el perfil indicado");

            _perfiles.Remove(perfil);

            return ResultadoOperacion.Exitoso(
                $"Perfil '{perfil.Nombre}' eliminado correctamente");
        }

        private bool DetectaCiclo(int perfilHijoId, int perfilPadreId)
        {
            var visitados = new HashSet<int>();
            var actual    = perfilPadreId;

            while (actual != 0)
            {
                if (actual == perfilHijoId) return true;
                if (visitados.Contains(actual)) break;

                visitados.Add(actual);
                var perfilActual = _perfiles.FirstOrDefault(p => p.Id == actual);
                actual = perfilActual?.PerfilPadreId ?? 0;
            }

            return false;
        }

        private List<PrivilegioSistema> ObtenerPrivilegiosHeredados(int perfilId)
        {
            var heredados = new List<PrivilegioSistema>();
            var perfil    = _perfiles.FirstOrDefault(p => p.Id == perfilId);
            var padreId   = perfil?.PerfilPadreId ?? 0;

            while (padreId != 0)
            {
                var privilegiosPadre = _privilegios
                    .Where(p => p.PerfilId == padreId)
                    .ToList();

                foreach (var priv in privilegiosPadre)
                    if (!heredados.Any(h => h.Accion == priv.Accion))
                        heredados.Add(priv);

                var perfilPadre = _perfiles.FirstOrDefault(p => p.Id == padreId);
                padreId = perfilPadre?.PerfilPadreId ?? 0;
            }

            return heredados;
        }
    }

    public class DefinirHerenciaRequest
    {
        public int    PerfilHijoId  { get; set; }
        public int    PerfilPadreId { get; set; }
        public string UsuarioId     { get; set; } = string.Empty;
    }

    public class PerfilSistema
    {
        public int    Id           { get; set; }
        public string Nombre       { get; set; } = string.Empty;
        public int    PerfilPadreId { get; set; }
        public bool   EstaActivo   { get; set; }
    }

    public class PrivilegioSistema
    {
        public int    Id       { get; set; }
        public int    PerfilId { get; set; }
        public string Accion   { get; set; } = string.Empty;
        public string Modulo   { get; set; } = string.Empty;
        public bool   Activo   { get; set; }
    }

    public class ResultadoPrivilegios
    {
        public bool   Exito   { get; private set; }
        public string Mensaje { get; private set; } = string.Empty;
        public List<PrivilegioSistema> Heredados    { get; private set; } = new();
        public List<PrivilegioSistema> Propios      { get; private set; } = new();
        public List<PrivilegioSistema> Sobrescritos { get; private set; } = new();

        public static ResultadoPrivilegios Exitoso(
            List<PrivilegioSistema> heredados,
            List<PrivilegioSistema> propios,
            List<PrivilegioSistema> sobrescritos) =>
            new ResultadoPrivilegios
            {
                Exito        = true,
                Heredados    = heredados,
                Propios      = propios,
                Sobrescritos = sobrescritos
            };

        public static ResultadoPrivilegios Error(string mensaje) =>
            new ResultadoPrivilegios { Exito = false, Mensaje = mensaje };
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
