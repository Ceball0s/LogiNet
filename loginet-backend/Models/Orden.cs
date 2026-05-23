using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace loginet_backend.Models;

public class Orden
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public string Cliente { get; set; } = string.Empty;

    [Required]
    public string Direccion { get; set; } = string.Empty;

    [Required]
    public string Estado { get; set; } = "Pendiente"; // Pendiente, EnCamino, Entregado

    public int? RepartidorId { get; set; }

    [ForeignKey("RepartidorId")]
    public Usuario? Repartidor { get; set; }
}
