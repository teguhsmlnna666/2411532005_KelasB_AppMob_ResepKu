import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Data JSON tiruan dari dummyjson.com untuk pengujian tanpa internet.
final recipesJson = jsonEncode({
  'recipes': [
    {
      'id': 1,
      'name': 'Classic Margherita Pizza',
      'cuisine': 'Italian',
      'difficulty': 'Easy',
      'prepTimeMinutes': 20,
      'cookTimeMinutes': 15,
      'servings': 4,
      'caloriesPerServing': 300,
      'rating': 4.6,
      'image': 'https://cdn.dummyjson.com/recipe-images/1.webp',
      'ingredients': [
        'Pizza dough',
        'Tomato sauce',
        'Fresh mozzarella cheese',
        'Fresh basil leaves',
        'Olive oil',
      ],
      'instructions': [
        'Preheat the oven to 475°F (245°C).',
        'Roll out the pizza dough and spread tomato sauce evenly.',
        'Top with slices of fresh mozzarella and bake for 12-15 minutes.',
      ],
    },
    {
      'id': 2,
      'name': 'Vegetarian Stir-Fry',
      'cuisine': 'Asian',
      'difficulty': 'Medium',
      'prepTimeMinutes': 15,
      'cookTimeMinutes': 20,
      'servings': 3,
      'caloriesPerServing': 250,
      'rating': 4.7,
      'image': 'https://cdn.dummyjson.com/recipe-images/2.webp',
      'ingredients': ['Tofu', 'Broccoli', 'Carrots', 'Soy sauce'],
      'instructions': [
        'Heat oil in a wok over high heat.',
        'Stir-fry vegetables and tofu until tender-crisp.',
      ],
    },
  ],
  'total': 2,
  'skip': 0,
  'limit': 30,
});

/// Mock HTTP Client yang selalu berhasil mengembalikan data resep.
http.Client okClient() {
  return MockClient((request) async {
    return http.Response(
      recipesJson,
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

/// Mock HTTP Client yang mensimulasikan kegagalan koneksi / server error.
http.Client errClient() {
  return MockClient((request) async {
    return http.Response('Internal Server Error', 500);
  });
}