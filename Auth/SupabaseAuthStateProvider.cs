using Microsoft.AspNetCore.Components.Authorization;
using NineWest.Services;
using System.Security.Claims;

namespace NineWest.Auth;

public class SupabaseAuthStateProvider : AuthenticationStateProvider
{
    private readonly SupabaseService _supabase;

    public SupabaseAuthStateProvider(SupabaseService supabase)
    {
        _supabase = supabase;
    }

    public override Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        var user = _supabase.CurrentUser;

        if (user is null)
        {
            var anonymous = new ClaimsPrincipal(new ClaimsIdentity());
            return Task.FromResult(new AuthenticationState(anonymous));
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id ?? string.Empty),
            new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
            new Claim(ClaimTypes.Name, user.Email ?? string.Empty)
        };

        var identity = new ClaimsIdentity(claims, "supabase");
        var principal = new ClaimsPrincipal(identity);

        return Task.FromResult(new AuthenticationState(principal));
    }

    public void NotifyAuthStateChanged() =>
        NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
}
