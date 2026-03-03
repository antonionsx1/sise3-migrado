using System.Security.Claims;

namespace Sise.IdentityTestApi
{
    public interface ICurrentUserService
    {
        string EmpleadoId { get; }
        string Name { get; }

        Guid? Nonce { get; }
        string ApiUrl { get; }
        string Method { get; }
        ClaimsPrincipal Principal { get; }
    }
}
