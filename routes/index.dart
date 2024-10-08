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
  // Get query parameters for pagination
  final queryParams = context.request.uri.queryParameters;
  final limit = int.tryParse(queryParams['limit'] ?? '1032') ??
      200; // Default to 50 if not provided
  final offset = int.tryParse(queryParams['offset'] ?? '0') ??
      0; // Default to 0 if not provided

  final cacheKey = 'pokemon_data_${limit}_$offset';
  final now = DateTime.now();

  // Check cache first
  if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.expiry.isAfter(now)) {
    return Response.json(body: jsonDecode(_cache[cacheKey]!.data));
  }

  // Fetch from PokeAPI if not in cache or expired
  final apiResponse = await http.get(Uri.parse(
      'https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$offset'));
  if (apiResponse.statusCode == 200) {
    final List pokemons = jsonDecode(apiResponse.body)['results'];
    final List<Map<String, dynamic>> detailedPokemons = [];

    for (var pokemon in pokemons) {
      final detailsResponse = await http.get(Uri.parse(pokemon['url']));
      if (detailsResponse.statusCode == 200) {
        final jsonDetails = jsonDecode(detailsResponse.body);

        final types = (jsonDetails['types'] as List)
            .map((type) => type['type']['name'] as String)
            .toList();

        final moves = (jsonDetails['moves'] as List)
            .take(20) // Take first 3 moves for simplicity
            .map((move) => move['move']['name'] as String)
            .toList();

        final stats = (jsonDetails['stats'] as List)
            .map((stat) =>
                {'name': stat['stat']['name'], 'base_stat': stat['base_stat']})
            .toList();

        final speciesUrl = jsonDetails['species']['url'];
        final speciesResponse = await http.get(Uri.parse(speciesUrl));
        Map<String, dynamic> evolutionData = {};
        if (speciesResponse.statusCode == 200) {
          final speciesDetails = jsonDecode(speciesResponse.body);
          final evolutionChainUrl = speciesDetails['evolution_chain']['url'];
          final evolutionChainResponse =
              await http.get(Uri.parse(evolutionChainUrl));
          if (evolutionChainResponse.statusCode == 200) {
            final evolutionChainDetails =
                jsonDecode(evolutionChainResponse.body);
            evolutionData = _parseEvolutionChain(evolutionChainDetails);
          }
        }

        detailedPokemons.add({
          'name': jsonDetails['name'],
          'url': pokemon['url'],
          'id': _extractId(pokemon['url']),
          'types': types,
          'moves': moves,
          'stats': stats,
          'evolution_data': evolutionData,
        });
      }
    }

    final responseData = jsonEncode({'results': detailedPokemons});
    _cache[cacheKey] =
        CachedResponse(responseData, now.add(const Duration(hours: 1)));

    return Response.json(body: jsonDecode(responseData));
  }

  // Handle API errors
  return Response(body: apiResponse.body, statusCode: apiResponse.statusCode);
}

Map<String, dynamic> _parseEvolutionChain(
    Map<String, dynamic> evolutionChainDetails) {
  Map<String, dynamic> evolutionData = {};
  var currentStage = evolutionChainDetails['chain'];

  List<Map<String, dynamic>> stages = [];
  while (currentStage != null) {
    stages.add({
      'species_name': currentStage['species']['name'],
      'species_id':
          _extractId(currentStage['species']['url']), // Extract species_id
      'evolves_to': currentStage['evolves_to']
          .map((e) => {
                'species_name': e['species']['name'],
                'species_id': _extractId(
                    e['species']['url']) // Extract species_id for evolutions
              })
          .toList()
    });
    currentStage = currentStage['evolves_to'].isNotEmpty
        ? currentStage['evolves_to'][0]
        : null;
  }

  evolutionData['stages'] = stages;
  return evolutionData;
}

int _extractId(String url) {
  final uri = Uri.parse(url);
  final segments = uri.pathSegments;
  return int.parse(segments[segments.length - 2]);
}
