using Postgrest.Attributes;
using Postgrest.Models;

namespace NineWest.Models;

[Table("meal_plans")]
public class MealPlanEntry : BaseModel
{
    [PrimaryKey("id", false)]
    public string Id { get; set; } = string.Empty;

    [Column("group_id")]
    public string? GroupId { get; set; }

    [Column("created_by")]
    public string CreatedBy { get; set; } = string.Empty;

    [Column("recipe_id")]
    public string? RecipeId { get; set; }

    [Column("meal_date")]
    public DateTime MealDate { get; set; }

    [Column("meal_type")]
    public string MealType { get; set; } = string.Empty;

    [Column("custom_title")]
    public string? CustomTitle { get; set; }

    [Column("notes")]
    public string? Notes { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }
}
