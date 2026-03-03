using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.Extensions.Caching.StackExchangeRedis;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using PolyCache;
using PolyCache.Cache;

namespace Sise.IdentityTestApi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var authority = "https://localhost:44376/identity/";
            //var audience = "https://localhost:44376/";
            var audience = "https://localhost:44376/identity/resources";

            var builder = WebApplication.CreateBuilder(args);
            var confugration = new ConfigurationBuilder().AddEnvironmentVariables()
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true).Build();

            // Add services to the container.

            builder.Services.AddStackExchangeRedisCache(delegate (RedisCacheOptions options)
            {
                options.Configuration = "DistributedCacheConfig";
                options.ConfigurationOptions = new StackExchange.Redis.ConfigurationOptions();
                //options.ConfigurationOptions.Password = "Certum01#";
                options.ConfigurationOptions.EndPoints.Add("localhost:6379");
                options.ConfigurationOptions.Ssl = false;
            });
            builder.Services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
            builder.Services.AddSingleton<AzureADJwtBearerValidation>();
            builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();
            builder.Services.AddPolyCache(confugration);
            builder.Services.AddTransient<IStaticCacheManager, DistributedCacheManager>();
            builder.Services.AddScoped<SesionService>();
            builder.Services
                    //.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
                    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                    .AddJwtBearer(options =>
                    {
                        options.Audience = audience;
                        options.Authority = authority;
                        options.ForwardSignIn = OpenIdConnectDefaults.AuthenticationScheme;
                        options.ForwardSignOut = OpenIdConnectDefaults.AuthenticationScheme;
                    });//
                    //.AddOpenIdConnect(options =>
                    //{
                    //    options.SignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
                    //    options.SignOutScheme = OpenIdConnectDefaults.AuthenticationScheme;
                    //    options.Authority = authority;
                    //    options.ClientId = "sise-app";
                    //    options.ClientSecret = "secret-12345678910";
                    //    options.ResponseType = OpenIdConnectResponseType.Token;
                    //    options.SaveTokens = true;
                    //    options.MapInboundClaims = false;
                    //    //options.Configuration.GrantTypesSupported.Add("password");
                        
                    //    //options.Scope.Add("api://8814267c-25fc-459e-b0a6-f6d7ed056f12/games:all");
                    //    //options.Scope.Add("openid");
                    //    options.TokenValidationParameters.NameClaimType = JwtRegisteredClaimNames.Name;
                    //    options.TokenValidationParameters.RoleClaimType = "roles";
                    //})
                    //.AddCookie(CookieAuthenticationDefaults.AuthenticationScheme);

            builder.Services.AddControllers();
            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();


            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseAuthentication();
            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
