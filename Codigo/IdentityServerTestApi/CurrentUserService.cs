using System.Security.Claims;

namespace Sise.IdentityTestApi
{
    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly AzureADJwtBearerValidation _azureADJwtBearerValidation;

        public CurrentUserService(IHttpContextAccessor httpContextAccessor, AzureADJwtBearerValidation azureADJwtBearerValidation)
        {
            _httpContextAccessor = httpContextAccessor;
            _azureADJwtBearerValidation = azureADJwtBearerValidation;
            GetPrincipal();
        }

        public string EmpleadoId => _httpContextAccessor.HttpContext?.User?.Claims.FirstOrDefault(s => s.Type.ToString() == "extension_EmpleadoId")?.Value;
        public string Name => _httpContextAccessor.HttpContext?.User?.Claims.FirstOrDefault(s => s.Type.ToString() == "name")?.Value;

        public ClaimsPrincipal Principal => _httpContextAccessor.HttpContext.User;

        public Guid? Nonce => GetNonce();

        private Guid? GetNonce()
        {
            var nonce = _httpContextAccessor.HttpContext?.User?.Claims.FirstOrDefault(s => s.Type.ToString() == "nonce");
            if (nonce == null)
            {
                return null;
            }
            return Guid.Parse(nonce.Value);
        }

        public string ApiUrl => _httpContextAccessor.HttpContext.Request.Path;

        public string Method => _httpContextAccessor.HttpContext.Request.Method;

        private ClaimsPrincipal? GetPrincipal()
        {
            ClaimsPrincipal principal = new ClaimsPrincipal();
            if (_httpContextAccessor != null &&
                _httpContextAccessor.HttpContext != null &&
                _httpContextAccessor.HttpContext?.User?.Claims.FirstOrDefault(s => s.Type.ToString() == "extension_EmpleadoId") == null)
            {
                principal = _azureADJwtBearerValidation.ValidateTokenAsync(_httpContextAccessor.HttpContext.Request.Headers["Authorization"]);
                if (principal != null)
                {
                    _httpContextAccessor.HttpContext.User = principal;
                }
            }
            return principal;
        }
    }
}