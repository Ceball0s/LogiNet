using loginet_backend.Models;

namespace loginet_backend.Dtos;

public record UserRegisterDto(string Nombre, string Email, string Password, Rol Rol);

public record UserLoginDto(string Email, string Password);

public record OrderCreateDto(string Cliente, string Direccion, int RepartidorId);

public record UpdateStatusDto(string Estado);

public record OrderListDto(
    int Id,
    string Cliente,
    string Direccion,
    string Estado,
    DateTime FechaCreacion,
    int? RepartidorId,
    RepartidorDto? Repartidor
);

public record RepartidorDto(int Id, string Nombre, string Email);
