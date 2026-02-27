using Postgrest.Attributes;
using Postgrest.Models;

namespace NineWest.Models;

[Table("recipes")]
public class Recipe : BaseModel
{
    [PrimaryKey("id", false)]
    public string Id { get; set; } = string.Empty;

    [Column("group_id")]
    public string? GroupId { get; set; }

    [Column("created_by")]
    public string CreatedBy { get; set; } = string.Empty;

    [Column("title")]
    public string Title { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    [Column("servings")]
    public int? Servings { get; set; }

    [Column("prep_time_minutes")]
    public int? PrepTimeMinutes { get; set; }

    [Column("cook_time_minutes")]
    public int? CookTimeMinutes { get; set; }

    [Column("instructions")]
    public string? Instructions { get; set; }

    [Column("image_url")]
    public string? ImageUrl { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; }
}
