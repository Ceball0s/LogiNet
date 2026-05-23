using Microsoft.EntityFrameworkCore;
using loginet_backend.Models;

namespace loginet_backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Orden> Ordenes { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        // Seed default admin user (password will be hashed later)
        var admin = new Usuario
        {
            Id = 1,
            Nombre = "Admin",
            Email = "admin@loginet.com",
            ContrasenaHash = "", // placeholder, will be set at runtime
            Rol = Rol.Admin
        };
        modelBuilder.Entity<Usuario>().HasData(admin);
    }
}
