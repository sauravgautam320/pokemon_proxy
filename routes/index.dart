import 'dart:convert';
import 'dart:async';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

// Simple in-memory cache
final Map<String, CachedResponse> _cache = {};

class CachedResponse {
  final String data;
  final DateTime expiry;

  CachedResponse(this.data, this.expiry);
}

Future<Response> onRequest(RequestContext context) async {
  const cacheKey = 'pokemon_data';
  final now = DateTime.now();

  // Check cache first
  if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.expiry.isAfter(now)) {
    return Response.json(body: jsonDecode(_cache[cacheKey]!.data));
  }

  // Fetch from API if not in cache or expired
  final apiResponse = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=100'));
  if (apiResponse.statusCode == 200) {
    final List<dynamic> results = jsonDecode(apiResponse.body)['results'];
    final List<Map<String, dynamic>> detailedPokemons = [];

    for (var pokemon in results) {
      final detailsResponse = await http.get(Uri.parse(pokemon['url']));
      if (detailsResponse.statusCode == 200) {
        final Map<String, dynamic> jsonDetails = jsonDecode(detailsResponse.body) as Map<String, dynamic>;
        final List<String> types = (jsonDetails['types'] as List<dynamic>)
            .map((type) => type['type']['name'] as String)
            .toList();
        detailedPokemons.add({
          'name': jsonDetails['name'],
          'url': pokemon['url'],
          'id': _extractId(pokemon['url']),
          'types': types,
        });
      }
    }

    final responseData = jsonEncode({'results': detailedPokemons});
    _cache[cacheKey] = CachedResponse(responseData, now.add(const Duration(hours: 1)));

    return Response.json(body: jsonDecode(responseData));
  }

  // Handle API errors
  return Response(body: apiResponse.body, statusCode: apiResponse.statusCode);
}

int _extractId(String url) {
  final uri = Uri.parse(url);
  final segments = uri.pathSegments;
  return int.parse(segments[segments.length - 2]);
}
