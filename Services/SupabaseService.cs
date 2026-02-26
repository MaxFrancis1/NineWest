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

    // ── Groups ────────────────────────────────────────────────────────────

    public async Task<List<Group>> GetMyGroupsAsync()
    {
        var response = await _client.From<Group>().Get();
        return response.Models;
    }

    public async Task<Group?> CreateGroupAsync(string name)
    {
        var group = new Group
        {
            Name = name.Trim(),
            CreatedBy = CurrentUser?.Id ?? string.Empty
        };
        var response = await _client.From<Group>().Insert(group);
        var created = response.Models.FirstOrDefault();

        if (created is not null)
        {
            // Auto-add creator as owner
            var member = new GroupMember
            {
                GroupId = created.Id,
                UserId = CurrentUser?.Id ?? string.Empty,
                Role = "owner"
            };
            await _client.From<GroupMember>().Insert(member);
        }
        return created;
    }

    public async Task<Group?> JoinGroupAsync(string inviteCode)
    {
        var response = await _client.From<Group>()
            .Filter("invite_code", Operator.Equals, inviteCode.Trim())
            .Get();
        
        var group = response.Models.FirstOrDefault();
        if (group is null) return null;

        var member = new GroupMember
        {
            GroupId = group.Id,
            UserId = CurrentUser?.Id ?? string.Empty,
            Role = "member"
        };
        await _client.From<GroupMember>().Insert(member);
        return group;
    }

    public async Task<List<GroupMember>> GetGroupMembersAsync(string groupId)
    {
        var response = await _client.From<GroupMember>()
            .Filter("group_id", Operator.Equals, groupId)
            .Get();
        return response.Models;
    }

    // ── Shopping list ─────────────────────────────────────────────────────

    public async Task<List<ShoppingListItem>> GetShoppingListAsync()
    {
        var response = await _client
            .From<ShoppingListItem>()
            .Order("created_at", Ordering.Ascending)
            .Get();

        return response.Models;
    }

    public async Task<ShoppingListItem?> AddItemAsync(string name, string? quantity = null, string? groupId = null)
    {
        var item = new ShoppingListItem
        {
            Name = name.Trim(),
            Quantity = string.IsNullOrWhiteSpace(quantity) ? null : quantity.Trim(),
            GroupId = groupId,
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

    // ── Recipes ───────────────────────────────────────────────────────────

    public async Task<List<Recipe>> GetRecipesAsync()
    {
        var response = await _client.From<Recipe>()
            .Order("created_at", Ordering.Descending)
            .Get();
        return response.Models;
    }

    public async Task<Recipe?> GetRecipeAsync(string id)
    {
        var response = await _client.From<Recipe>()
            .Filter("id", Operator.Equals, id)
            .Get();
        return response.Models.FirstOrDefault();
    }

    public async Task<Recipe?> AddRecipeAsync(Recipe recipe)
    {
        recipe.CreatedBy = CurrentUser?.Id ?? string.Empty;
        var response = await _client.From<Recipe>().Insert(recipe);
        return response.Models.FirstOrDefault();
    }

    public async Task UpdateRecipeAsync(Recipe recipe)
    {
        recipe.UpdatedAt = DateTime.UtcNow;
        await _client.From<Recipe>().Update(recipe);
    }

    public async Task DeleteRecipeAsync(Recipe recipe) =>
        await _client.From<Recipe>().Delete(recipe);

    // ── Recipe Ingredients ────────────────────────────────────────────────

    public async Task<List<RecipeIngredient>> GetRecipeIngredientsAsync(string recipeId)
    {
        var response = await _client.From<RecipeIngredient>()
            .Filter("recipe_id", Operator.Equals, recipeId)
            .Order("sort_order", Ordering.Ascending)
            .Get();
        return response.Models;
    }

    public async Task<RecipeIngredient?> AddRecipeIngredientAsync(RecipeIngredient ingredient)
    {
        var response = await _client.From<RecipeIngredient>().Insert(ingredient);
        return response.Models.FirstOrDefault();
    }

    public async Task DeleteRecipeIngredientAsync(RecipeIngredient ingredient) =>
        await _client.From<RecipeIngredient>().Delete(ingredient);

    // ── Meal Plans ────────────────────────────────────────────────────────

    public async Task<List<MealPlanEntry>> GetMealPlanAsync(DateTime weekStart, DateTime weekEnd)
    {
        var response = await _client.From<MealPlanEntry>()
            .Filter("meal_date", Operator.GreaterThanOrEqual, weekStart.ToString("yyyy-MM-dd"))
            .Filter("meal_date", Operator.LessThanOrEqual, weekEnd.ToString("yyyy-MM-dd"))
            .Order("meal_date", Ordering.Ascending)
            .Get();
        return response.Models;
    }

    public async Task<MealPlanEntry?> AddMealPlanEntryAsync(MealPlanEntry entry)
    {
        entry.CreatedBy = CurrentUser?.Id ?? string.Empty;
        var response = await _client.From<MealPlanEntry>().Insert(entry);
        return response.Models.FirstOrDefault();
    }

    public async Task DeleteMealPlanEntryAsync(MealPlanEntry entry) =>
        await _client.From<MealPlanEntry>().Delete(entry);

    // ── Todos ─────────────────────────────────────────────────────────────

    public async Task<List<TodoItem>> GetTodosAsync()
    {
        var response = await _client.From<TodoItem>()
            .Order("is_completed", Ordering.Ascending)
            .Order("priority", Ordering.Descending)
            .Order("created_at", Ordering.Descending)
            .Get();
        return response.Models;
    }

    public async Task<TodoItem?> AddTodoAsync(string title, int priority = 0, DateTime? dueDate = null, string? groupId = null)
    {
        var item = new TodoItem
        {
            Title = title.Trim(),
            Priority = priority,
            DueDate = dueDate,
            GroupId = groupId,
            CreatedBy = CurrentUser?.Id ?? string.Empty
        };
        var response = await _client.From<TodoItem>().Insert(item);
        return response.Models.FirstOrDefault();
    }

    public async Task ToggleTodoAsync(TodoItem item)
    {
        item.IsCompleted = !item.IsCompleted;
        await _client.From<TodoItem>().Update(item);
    }

    public async Task DeleteTodoAsync(TodoItem item) =>
        await _client.From<TodoItem>().Delete(item);
}
