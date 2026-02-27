using Postgrest.Attributes;
using Postgrest.Models;

namespace NineWest.Models;

[Table("todos")]
public class TodoItem : BaseModel
{
    [PrimaryKey("id", false)]
    public string Id { get; set; } = string.Empty;

    [Column("group_id")]
    public string? GroupId { get; set; }

    [Column("created_by")]
    public string CreatedBy { get; set; } = string.Empty;

    [Column("title")]
    public string Title { get; set; } = string.Empty;

    [Column("is_completed")]
    public bool IsCompleted { get; set; }

    [Column("priority")]
    public int Priority { get; set; }

    [Column("due_date")]
    public DateTime? DueDate { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }
}
