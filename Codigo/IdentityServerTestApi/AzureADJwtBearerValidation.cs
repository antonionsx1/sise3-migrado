namespace Sise.IdentityTestApi
{
    using System.IdentityModel.Tokens.Jwt;
    using System.Security.Claims;
    using Microsoft.Extensions.Logging;
    using Microsoft.IdentityModel.Protocols.OpenIdConnect;
    using Microsoft.IdentityModel.Protocols;
    using Microsoft.IdentityModel.Tokens;
    using Microsoft.Extensions.Configuration;

    public class AzureADJwtBearerValidation
    {
        private IConfiguration _configuration;
        private ILogger _log;
        private const string scopeType = @"http://schemas.microsoft.com/identity/claims/scope";
        private ConfigurationManager<OpenIdConnectConfiguration> _configurationManager;
        private ClaimsPrincipal _claimsPrincipal;

        private string _wellKnownEndpoint = string.Empty;

        private string _audience = string.Empty;
        private string _urlLoginAuth = string.Empty;



        public AzureADJwtBearerValidation(IConfiguration configuration, ILoggerFactory loggerFactory)
        {
            _configuration = configuration;
            _log = loggerFactory.CreateLogger<AzureADJwtBearerValidation>();

            _urlLoginAuth = _configuration["SISE3:BackEnd:AADB2CLoginInstance"];
            _audience = _configuration["SISE3:BackEnd:AADB2CClientID"];

            _wellKnownEndpoint = $"{_urlLoginAuth}.well-known/openid-configuration";

        }

        public ClaimsPrincipal ValidateTokenAsync(string authorizationHeader)
        {
            if (string.IsNullOrEmpty(authorizationHeader))
            {
                return null;
            }

            if (!authorizationHeader.Contains("Bearer"))
            {
                return null;
            }

            var accessToken = authorizationHeader.Substring("Bearer ".Length);

            var oidcWellknownEndpoints = GetOIDCWellknownConfiguration();

            var tokenValidator = new JwtSecurityTokenHandler();

            var validationParameters = new TokenValidationParameters
            {
                RequireSignedTokens = true,
                ValidAudience = _audience,
                ValidateAudience = true,
                ValidateIssuer = true,
                ValidateIssuerSigningKey = false, // change to false
                ValidateLifetime = true,
                IssuerSigningKeys = oidcWellknownEndpoints.SigningKeys,
                ValidIssuer = oidcWellknownEndpoints.Issuer
            };

            try
            {
                SecurityToken securityToken;
                _claimsPrincipal = tokenValidator.ValidateToken(accessToken, validationParameters, out securityToken);
                return _claimsPrincipal;
            }
            catch (Exception ex)
            {
                _log.LogError(ex.ToString());
            }
            return null;
        }

        private OpenIdConnectConfiguration GetOIDCWellknownConfiguration()
        {
            _log.LogDebug($"Get OIDC well known endpoints {_wellKnownEndpoint}");
            _configurationManager = new ConfigurationManager<OpenIdConnectConfiguration>(
                 _wellKnownEndpoint, new OpenIdConnectConfigurationRetriever());

            return _configurationManager.GetConfigurationAsync().ConfigureAwait(false).GetAwaiter().GetResult();
        }

        public bool IsScopeValid(string scopeName)
        {
            if (_claimsPrincipal == null)
            {
                _log.LogWarning($"Scope invalid {scopeName}");
                return false;
            }

            var scopeClaim = _claimsPrincipal.HasClaim(x => x.Type == scopeType)
                ? _claimsPrincipal.Claims.First(x => x.Type == scopeType).Value
                : string.Empty;

            if (string.IsNullOrEmpty(scopeClaim))
            {
                _log.LogWarning($"Scope invalid {scopeName}");
                return false;
            }

            if (!scopeClaim.Equals(scopeName, StringComparison.OrdinalIgnoreCase))
            {
                _log.LogWarning($"Scope invalid {scopeName}");
                return false;
            }

            _log.LogDebug($"Scope valid {scopeName}");
            return true;
        }

        internal Task<ClaimsPrincipal> ValidateTokenAsync(object value)
        {
            throw new NotImplementedException();
        }
    }
}
