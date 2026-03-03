using System;
using System.Configuration;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using System.Web.Http;
using IdentityServer3.Core.Configuration;
using IdentityServer3.Core.Logging;
using IdentityServer3.Core.Resources;
using IdentityServer3.Core.Services;
using IdentityServer3.Core.Services.Default;
using IdentityServer3.Core.Services.InMemory;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Owin;
using Microsoft.Owin.Cors;
using Microsoft.Owin.Security;
using Microsoft.Owin.Security.Jwt;
using Owin;
using Serilog;
using Sise.IdentityServer.Identity;
using static IdentityServer3.Core.Constants;

[assembly: OwinStartup(typeof(Sise.IdentityServer.Startup))]
namespace Sise.IdentityServer
{
    /// <summary>
    /// Configuracion del servicio
    /// </summary>
    public class Startup
    {
        /// <summary>
        /// Configura el servicio
        /// </summary>
        /// <param name="app">App builder</param>
        public void Configuration(IAppBuilder app)
        {
            Log.Logger = new LoggerConfiguration()
                           .MinimumLevel.Debug()
                           .WriteTo.Trace()
                           .CreateLogger();

            HttpConfiguration config = new HttpConfiguration();

            config.MapHttpAttributeRoutes();


            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

            app.Map("/identity", coreApp =>
            {
                var factory = new IdentityServerServiceFactory()
                    .UseInMemoryClients(Clients.Get())
                    .UseInMemoryScopes(Clients.GetScopes());

                factory.ClaimsProvider = new Registration<IClaimsProvider>(typeof(SiseClaimsProvider));

                var userService = new MembershipUserService();
                var refreshStore = new InMemoryRefreshTokenStore();
                var eventsService = new DefaultEventService();
                factory.UserService = new Registration<IUserService>(resolver => userService);
                //factory.RefreshTokenStore = new Registration<IRefreshTokenStore>(reslver => refreshStore);
                factory.RefreshTokenService = new Registration<IRefreshTokenService>(typeof(SiseRefreshTokenService));
                
                var options = new IdentityServerOptions
                {
                    SiteName = "IdentityServer3 - SISEUserService",
                    //IssuerUri = "https://192.168.68.63:44376/identity/",
                    IssuerUri = ConfigurationManager.AppSettings["issuerUri"],
                    SigningCertificate = Certificate.Get(),
                    Factory = factory,
                    RequireSsl = false,
                    AuthenticationOptions = new IdentityServer3.Core.Configuration.AuthenticationOptions
                    {
                        IdentityProviders = ConfigureAdditionalIdentityProviders,
                        LoginPageLinks = new LoginPageLink[] {
                            new LoginPageLink{
                                Text = "Register",
                                //Href = "~/localregistration"
                                Href = "localregistration"
                            }
                        }
                    },

                    EventsOptions = new EventsOptions
                    {
                        RaiseSuccessEvents = true,
                        RaiseErrorEvents = true,
                        RaiseFailureEvents = true,
                        RaiseInformationEvents = true
                    }
                };

                coreApp.UseIdentityServer(options);
            });

            var issuer = ConfigurationManager.AppSettings["authority"];
            var audienceId = ConfigurationManager.AppSettings["authority"];

            app.UseCors(CorsOptions.AllowAll);
            app.UseWebApi(config);
        }

        /// <summary>
        /// Configura providers adicionales si es necesario
        /// </summary>
        /// <param name="app">Ap builedr</param>
        /// <param name="signInAsType">Logearse como</param>
        public static void ConfigureAdditionalIdentityProviders(IAppBuilder app, string signInAsType)
        {
        }
    }
}