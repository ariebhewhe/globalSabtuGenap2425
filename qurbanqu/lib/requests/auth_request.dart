class RegisterRequest {
  String email;
  String password;
  String name;
  String phone;
  String address;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.address,
  });
}

class LoginRequest {
  String email;
  String password;

  LoginRequest({required this.email, required this.password});
}
