import 'dart:io';

import '../../../core/services/api_service.dart';
import '../models/friend_model.dart';
import '../models/social_failure.dart';

/// Social service for friend management and social features
class SocialService {
  final ApiService _apiService;

  SocialService(this._apiService);

  /// Get user's friends list
  Future<List<Friend>> getFriends() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/friends/');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> friendsData = response.data!['friends'] ?? [];
        return friendsData.map((json) => Friend.fromJson(json)).toList();
      }

      throw SocialFailure.server(
        message: 'Failed to load friends',
        statusCode: response.statusCode,
      );
    } on ApiException catch (e) {
      throw SocialFailure.fromApiException(e);
    } on SocketException {
      throw const SocialFailure.network(message: 'Network connection failed');
    } catch (e) {
      throw SocialFailure.unknown(
        message: 'Unexpected error loading friends',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Get pending friend requests
  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/friends/requests/',
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> requestsData = response.data!['requests'] ?? [];
        return requestsData
            .map((json) => FriendRequest.fromJson(json))
            .toList();
      }

      throw Exception('Failed to load friend requests: ${response.statusCode}');
    } on ApiException catch (e) {
      throw Exception('API error loading requests: ${e.message}');
    } catch (e) {
      throw Exception('Error loading friend requests: $e');
    }
  }

  /// Get weekly leaderboard
  Future<List<WeeklyLeaderboardEntry>> getWeeklyLeaderboard() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/friends/leaderboard/weekly/',
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> leaderboardData =
            response.data!['leaderboard'] ?? [];
        return leaderboardData
            .map((json) => WeeklyLeaderboardEntry.fromJson(json))
            .toList();
      }

      throw Exception('Failed to load leaderboard: ${response.statusCode}');
    } on ApiException catch (e) {
      throw Exception('API error loading leaderboard: ${e.message}');
    } catch (e) {
      throw Exception('Error loading leaderboard: $e');
    }
  }

  /// Get social statistics
  Future<SocialStats> getSocialStats() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/friends/stats/',
      );

      if (response.isSuccess && response.data != null) {
        return SocialStats.fromJson(response.data!);
      }

      throw Exception('Failed to load social stats: ${response.statusCode}');
    } on ApiException catch (e) {
      throw Exception('API error loading stats: ${e.message}');
    } catch (e) {
      throw Exception('Error loading social stats: $e');
    }
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String username, String? message) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/friends/request/',
        data: {'username': username, if (message != null) 'message': message},
      );

      return response.isSuccess;
    } on ApiException catch (e) {
      throw SocialFailure.fromApiException(e);
    } on SocketException {
      throw const SocialFailure.network(message: 'Network connection failed');
    } catch (e) {
      throw SocialFailure.unknown(
        message: 'Unexpected error sending friend request',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Respond to friend request (accept/decline)
  Future<bool> respondToFriendRequest(
    String requestId, {
    required bool accept,
  }) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/friends/request/$requestId/',
        data: {'action': accept ? 'accept' : 'decline'},
      );

      return response.isSuccess;
    } on ApiException catch (e) {
      throw Exception('API error responding to request: ${e.message}');
    } catch (e) {
      throw Exception('Error responding to friend request: $e');
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/friends/$friendId/',
      );

      return response.isSuccess;
    } on ApiException catch (e) {
      throw Exception('API error removing friend: ${e.message}');
    } catch (e) {
      throw Exception('Error removing friend: $e');
    }
  }

  /// Send hydration reminder to friend
  Future<bool> sendHydrationReminder(String friendId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/friends/$friendId/remind/',
        data: {'type': 'hydration', 'message': 'Đã đến lúc uống nước rồi! 💧'},
      );

      return response.isSuccess;
    } on ApiException catch (e) {
      throw Exception('API error sending reminder: ${e.message}');
    } catch (e) {
      throw Exception('Error sending hydration reminder: $e');
    }
  }

  /// Search users by username
  Future<List<Friend>> searchUsers(String query) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/friends/search/',
        queryParams: {'q': query},
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> usersData = response.data!['users'] ?? [];
        return usersData.map((json) => Friend.fromJson(json)).toList();
      }

      throw SocialFailure.server(
        message: 'Failed to search users',
        statusCode: response.statusCode,
      );
    } on ApiException catch (e) {
      throw SocialFailure.fromApiException(e);
    } on SocketException {
      throw const SocialFailure.network(message: 'Network connection failed');
    } catch (e) {
      throw SocialFailure.unknown(
        message: 'Unexpected error searching users',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Get friend profile
  Future<Friend> getFriendProfile(String friendId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/friends/$friendId/',
      );

      if (response.isSuccess && response.data != null) {
        return Friend.fromJson(response.data!);
      }

      throw Exception('Failed to load friend profile: ${response.statusCode}');
    } on ApiException catch (e) {
      throw Exception('API error loading profile: ${e.message}');
    } catch (e) {
      throw Exception('Error loading friend profile: $e');
    }
  }

  /// Update friend status (for current user)
  Future<bool> updateStatus(FriendStatus status) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/friends/me/status/',
        data: {'status': status.value},
      );

      return response.isSuccess;
    } on ApiException catch (e) {
      throw Exception('API error updating status: ${e.message}');
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }
}
