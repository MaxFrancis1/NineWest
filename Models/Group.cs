using Postgrest.Attributes;
using Postgrest.Models;

namespace NineWest.Models;

[Table("groups")]
public class Group : BaseModel
{
    [PrimaryKey("id", false)]
    public string Id { get; set; } = string.Empty;

    [Column("name")]
    public string Name { get; set; } = string.Empty;

    [Column("invite_code")]
    public string InviteCode { get; set; } = string.Empty;

    [Column("created_by")]
    public string CreatedBy { get; set; } = string.Empty;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }
}
