class Form1728PProgram {
  final String id;
  final String name;

  Form1728PProgram({
    required this.id,
    required this.name,
  });

  factory Form1728PProgram.fromJson(Map<String, dynamic> json) {
    return Form1728PProgram(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

enum Form1728PCategory {
  faith,
  family,
  community,
  life,
  patriotic;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
} 