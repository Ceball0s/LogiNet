using System.ComponentModel.DataAnnotations;

namespace loginet_backend.Models;

public enum Rol
{
    Admin,
    Repartidor
}

public class Usuario
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string Nombre { get; set; } = string.Empty;
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    [Required]
    public string ContrasenaHash { get; set; } = string.Empty;
    [Required]
    public Rol Rol { get; set; }
}
