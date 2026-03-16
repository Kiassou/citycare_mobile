class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String username;
  final String telephone;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.username,
    required this.telephone,
    required this.email,
    required this.role,
  });

  // Pour transformer la réponse de ton API Node.js en objet Flutter
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      // On ajoute ?? "" pour dire : "Si c'est null, mets une chaine vide"
      nom: json['nom'] ?? "Nom inconnu",
      prenom: json['prenom'] ?? "Utilisateur",
      username: json['username'] ?? "",
      telephone: json['telephone'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "citoyen",
    );
  }
}
