import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../domain/match_suggestion.dart';

/// AI match suggestions. The app only talks to the EcoLoop backend; the AI
/// service behind it is never called directly.
class MatchesRepository {
  final ApiClient _api;

  MatchesRepository(this._api);

  Future<List<MatchSuggestion>> getMine() async {
    final items = _decode(await _api.get('/api/matches')) as List<dynamic>;
    return items.map((e) => MatchSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns the listing id and the other owner's id for opening the chat.
  Future<({String listingId, String otherBusinessId})> connect(String suggestionId) async {
    final data = _decode(await _api.post('/api/matches/$suggestionId/connect')) as Map<String, dynamic>;
    return (listingId: data['chatListingId'].toString(), otherBusinessId: data['otherBusinessId'].toString());
  }

  Future<void> dismiss(String suggestionId) async {
    _decode(await _api.post('/api/matches/$suggestionId/dismiss'));
  }

  Future<void> findMatches(String listingId) async {
    _decode(await _api.post('/api/matches/listings/$listingId/run'));
  }

  Future<List<MatchActivity>> getActivity() async {
    final items = _decode(await _api.get('/api/matches/activity')) as List<dynamic>;
    return items.map((e) => MatchActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MatchWorkflowStatus?> status(String listingId) async {
    final data = _decode(await _api.get('/api/matches/listings/$listingId/status'));
    return data == null ? null : MatchWorkflowStatus.fromJson(data as Map<String, dynamic>);
  }

  static dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode}).';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) message = body['message'].toString();
      } catch (_) {}
      throw ApiException(statusCode: response.statusCode, message: message);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }
}
