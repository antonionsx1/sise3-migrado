using PolyCache.Cache;

namespace Sise.IdentityTestApi
{
    public class SesionService
    {
        private readonly IStaticCacheManager _staticCacheManager;
        private readonly ICurrentUserService _currentUserService;
        private readonly CacheKey _cacheKey;
        const string cacheSesionPrefix = "sesion_";
        private const int TtlCache = 180;
        public SesionService(IStaticCacheManager staticCacheManager, ICurrentUserService currentUserService)
        {
            _staticCacheManager = staticCacheManager;
            _currentUserService = currentUserService;
            if (currentUserService != null && currentUserService.EmpleadoId != null)
            {
                _cacheKey = new CacheKey("sesion_" + currentUserService.EmpleadoId.ToString());
            }


        }
        
        public Sesion? _sesion;
        public Sesion? SesionActual => GetSesionRedis();

        private Sesion? GetSesionRedis()
        {
            if (_sesion == null)
            {
                var sesiones = _staticCacheManager.GetAsync<List<Sesion>>(_cacheKey).ConfigureAwait(false).GetAwaiter().GetResult();
                if (_cacheKey != null)
                {
                    if (sesiones != null)
                    {
                        _sesion = sesiones.FirstOrDefault(s => s.Nonce == _currentUserService.Nonce.ToString());
                        return _sesion;
                    }
                }
            }
            else
            {
                return _sesion;
            }
            return null;
        }

        public async Task<bool> IniciarSesion(Sesion sesion)
        {
            bool resultado = false;
            var llaveCache = new CacheKey(LlaveCache(cacheSesionPrefix, sesion.EmpleadoId.ToString()));

            var sesiones = await _staticCacheManager.GetAsync<List<Sesion>>(llaveCache);
            sesion.ExpiracionUtc = DateTime.UtcNow.AddMinutes(TtlCache);
            if (sesiones == null)
            {
                sesiones = new List<Sesion>();
            }
            else
            {
                sesiones.RemoveAll(sesion => sesion.ExpiracionUtc < DateTime.UtcNow);
            }
            sesiones.Add(sesion);
            llaveCache.CacheTime = TtlCache;
            await _staticCacheManager.SetAsync(llaveCache, sesiones);
            resultado = true;

            return resultado;
        }

        private static string LlaveCache(string cachePrexi, string sesionId)
        {
            return cachePrexi + sesionId;
        }
    }

}
