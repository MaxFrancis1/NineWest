using Postgrest.Attributes;
using Postgrest.Models;

namespace NineWest.Models;

[Table("group_members")]
public class GroupMember : BaseModel
{
    [PrimaryKey("id", false)]
    public string Id { get; set; } = string.Empty;

    [Column("group_id")]
    public string GroupId { get; set; } = string.Empty;

    [Column("user_id")]
    public string UserId { get; set; } = string.Empty;

    [Column("role")]
    public string Role { get; set; } = string.Empty;

    [Column("joined_at")]
    public DateTime JoinedAt { get; set; }
}
