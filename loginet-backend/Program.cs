using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Text.Json.Serialization;
using BCrypt.Net;
using loginet_backend.Data;
using loginet_backend.Models;
using loginet_backend.Dtos;
using loginet_backend.Services;

var builder = WebApplication.CreateBuilder(args);

// Allow enums to be serialized/deserialized as strings (e.g. "Repartidor" instead of 1)
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter()));

// Load configuration (appsettings.json)
builder.Configuration.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);

// Add services
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<TokenService>();

// JWT authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"];
var key = Encoding.ASCII.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("Admin", policy => policy.RequireClaim("role", "Admin"));
    options.AddPolicy("Repartidor", policy => policy.RequireClaim("role", "Repartidor"));
});

var app = builder.Build();

// Ensure database is created
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

app.MapGet("/", () => "LogiNet Backend is running");

// Auth endpoints
app.MapPost("/auth/register", async (UserRegisterDto dto, AppDbContext db) =>
{
    if (await db.Usuarios.AnyAsync(u => u.Email == dto.Email))
        return Results.BadRequest(new { message = "Email already registered" });

    var user = new Usuario
    {
        Nombre = dto.Nombre,
        Email = dto.Email,
        ContrasenaHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
        Rol = dto.Rol
    };
    db.Usuarios.Add(user);
    await db.SaveChangesAsync();
    return Results.Ok(new { message = "User registered" });
});

app.MapPost("/auth/login", async (UserLoginDto dto, AppDbContext db, TokenService tokenService) =>
{
    var user = await db.Usuarios.FirstOrDefaultAsync(u => u.Email == dto.Email);
    if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.ContrasenaHash))
        return Results.Unauthorized();

    var token = tokenService.GenerateToken(user);
    return Results.Ok(new { token });
}).AllowAnonymous();

// Repartidores endpoint (Admin)
app.MapGet("/repartidores", async (AppDbContext db) =>
{
    var repartidores = await db.Usuarios
        .Where(u => u.Rol == Rol.Repartidor)
        .Select(u => new { u.Id, u.Nombre, u.Email })
        .ToListAsync();
    return Results.Ok(repartidores);
}).RequireAuthorization("Admin");

// Orders endpoints (Admin)
app.MapGet("/ordenes", async (AppDbContext db) =>
    await db.Ordenes.Include(o => o.Repartidor).ToListAsync())
    .RequireAuthorization("Admin");

app.MapPost("/ordenes", async (OrderCreateDto dto, AppDbContext db) =>
{
    var order = new Orden
    {
        Cliente = dto.Cliente,
        Direccion = dto.Direccion,
        Estado = "Pendiente",
        RepartidorId = dto.RepartidorId
    };
    db.Ordenes.Add(order);
    await db.SaveChangesAsync();
    return Results.Created($"/ordenes/{order.Id}", order);
}).RequireAuthorization("Admin");

// Orders for Repartidor
app.MapGet("/ordenes/mis-entregas", async (AppDbContext db, HttpContext http) =>
{
    var userId = int.Parse(http.User.FindFirst("sub")?.Value ?? "0");
    var orders = await db.Ordenes.Where(o => o.RepartidorId == userId).ToListAsync();
    return Results.Ok(orders);
}).RequireAuthorization("Repartidor");

app.MapPut("/ordenes/{id}/estado", async (int id, UpdateStatusDto dto, AppDbContext db, HttpContext http) =>
{
    var order = await db.Ordenes.FindAsync(id);
    if (order == null) return Results.NotFound();
    var userId = int.Parse(http.User.FindFirst("sub")?.Value ?? "0");
    if (order.RepartidorId != userId) return Results.Forbid();
    order.Estado = dto.Estado;
    await db.SaveChangesAsync();
    return Results.Ok(order);
}).RequireAuthorization("Repartidor");

app.Run();
