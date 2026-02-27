using Postgrest.Attributes;
using Postgrest.Models;

namespace NineWest.Models;

[Table("recipe_ingredients")]
public class RecipeIngredient : BaseModel
{
    [PrimaryKey("id", false)]
    public string Id { get; set; } = string.Empty;

    [Column("recipe_id")]
    public string RecipeId { get; set; } = string.Empty;

    [Column("name")]
    public string Name { get; set; } = string.Empty;

    [Column("quantity")]
    public string? Quantity { get; set; }

    [Column("unit")]
    public string? Unit { get; set; }

    [Column("sort_order")]
    public int SortOrder { get; set; }
}
