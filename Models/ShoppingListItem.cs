using Postgrest.Attributes;
using Postgrest.Models;

namespace NineWest.Models;

[Table("shopping_list")]
public class ShoppingListItem : BaseModel
{
    [PrimaryKey("id", false)]
    public string Id { get; set; } = string.Empty;

    [Column("created_by")]
    public string CreatedBy { get; set; } = string.Empty;

    [Column("name")]
    public string Name { get; set; } = string.Empty;

    [Column("quantity")]
    public string? Quantity { get; set; }

    [Column("is_checked")]
    public bool IsChecked { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }
}
