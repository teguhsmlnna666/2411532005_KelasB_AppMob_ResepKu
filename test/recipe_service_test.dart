import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';

void main() {
  group('Recipe Model Test', () {
    test('rating integer dibaca sebagai double dan field kosong memiliki nilai bawaan', () {
      final json = {
        'id': 1,
        'name': 'Nasi Goreng',
        'rating': 5,
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.rating, 5.0);
      expect(recipe.instructions, isEmpty);
      expect(recipe.ingredients, isEmpty);
    });
  });

  group('RecipeService Test', () {
    test('fetchRecipes mengembalikan List<Recipe> dari respons palsu', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/recipes');
        
        return http.Response(
          jsonEncode({
            'recipes': [
              {
                'id': 1,
                'name': 'Nasi Goreng',
                'rating': 5,
                'ingredients': ['Nasi', 'Telur'],
                'instructions': ['Masak nasi', 'Tambahkan telur'],
              },
              {
                'id': 2,
                'name': 'Mie Goreng',
                'rating': 4.5,
                'ingredients': ['Mie', 'Sayuran'],
                'instructions': ['Rebus mie', 'Tambahkan bumbu'],
              },
            ],
            'total': 2,
            'skip': 0,
            'limit': 50,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RecipeService(client: client);

      try {
        final recipes = await service.fetchRecipes();

        expect(recipes, isA<List<Recipe>>());
        expect(recipes.length, 2);
        expect(recipes[0].name, 'Nasi Goreng');
        expect(recipes[1].name, 'Mie Goreng');
      } finally {
        service.close();
      }
    });

    test('fetchRecipes melempar RecipeServiceException jika status 404', () async {
      final client = MockClient((request) async {
        return http.Response(
          'Not Found',
          404,
        );
      });

      final service = RecipeService(client: client);

      try {
        expect(
          service.fetchRecipes(),
          throwsA(isA<RecipeServiceException>()),
        );
      } finally {
        service.close();
      }
    });
  });
}