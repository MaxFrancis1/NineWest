using NineWest.Models;
using Supabase;
using Supabase.Gotrue;
using static Postgrest.Constants;

namespace NineWest.Services;

public class SupabaseService
{
    private readonly Supabase.Client _client;

    public SupabaseService(IConfiguration configuration)
    {
        var url = configuration["Supabase:Url"]
            ?? throw new InvalidOperationException("Supabase:Url is not configured.");
        var key = configuration["Supabase:AnonKey"]
            ?? throw new InvalidOperationException("Supabase:AnonKey is not configured.");

        _client = new Supabase.Client(url, key, new SupabaseOptions
        {
            AutoRefreshToken = true,
            AutoConnectRealtime = false
        });
    }

    public async Task InitializeAsync() => await _client.InitializeAsync();

    public Supabase.Client Client => _client;

    // ── Auth ──────────────────────────────────────────────────────────────

    public async Task<Session?> SignInAsync(string email, string password) =>
        await _client.Auth.SignIn(email, password);

    public async Task<Session?> SignUpAsync(string email, string password) =>
        await _client.Auth.SignUp(email, password);

    public async Task SignOutAsync() => await _client.Auth.SignOut();

    public User? CurrentUser => _client.Auth.CurrentUser;
    public Session? CurrentSession => _client.Auth.CurrentSession;
    public bool IsAuthenticated => _client.Auth.CurrentUser is not null;

    // ── Shopping list ─────────────────────────────────────────────────────

    public async Task<List<ShoppingListItem>> GetShoppingListAsync()
    {
        var response = await _client
            .From<ShoppingListItem>()
            .Order("created_at", Ordering.Ascending)
            .Get();

        return response.Models;
    }

    public async Task<ShoppingListItem?> AddItemAsync(string name, string? quantity = null)
    {
        var item = new ShoppingListItem
        {
            Name = name.Trim(),
            Quantity = string.IsNullOrWhiteSpace(quantity) ? null : quantity.Trim(),
            CreatedBy = CurrentUser?.Id ?? string.Empty
        };

        var response = await _client.From<ShoppingListItem>().Insert(item);
        return response.Models.FirstOrDefault();
    }

    public async Task ToggleItemAsync(ShoppingListItem item)
    {
        item.IsChecked = !item.IsChecked;
        await _client.From<ShoppingListItem>().Update(item);
    }

    public async Task DeleteItemAsync(ShoppingListItem item) =>
        await _client.From<ShoppingListItem>().Delete(item);
}
