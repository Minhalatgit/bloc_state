import 'package:flutter/foundation.dart' show immutable;

@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        age = json['age'];

  @override
  String toString() {
    return "Name: $name Age: $age";
  }
}
