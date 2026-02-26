using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using NineWest;
using NineWest.Auth;
using NineWest.Services;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri(builder.HostEnvironment.BaseAddress) });

builder.Services.AddAuthorizationCore();
builder.Services.AddSingleton<SupabaseService>();
builder.Services.AddScoped<SupabaseAuthStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp =>
    sp.GetRequiredService<SupabaseAuthStateProvider>());

var host = builder.Build();

var supabase = host.Services.GetRequiredService<SupabaseService>();
await supabase.InitializeAsync();

await host.RunAsync();
