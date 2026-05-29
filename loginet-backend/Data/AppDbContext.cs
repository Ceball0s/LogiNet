using Microsoft.EntityFrameworkCore;
using loginet_backend.Models;

namespace loginet_backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Orden> Ordenes { get; set; }
}
