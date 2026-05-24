import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/friend_model.dart';
import '../providers/friends_provider.dart';

/// Friend search widget with search results
class FriendSearch extends ConsumerStatefulWidget {
  const FriendSearch({super.key});

  @override
  ConsumerState<FriendSearch> createState() => _FriendSearchState();
}

class _FriendSearchState extends ConsumerState<FriendSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Friend> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _debounceTimer; // For debouncing search input
  int _requestCounter = 0; // To track and ignore stale requests

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Clean up timer
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _buildSearchField(),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search instructions
          if (_searchQuery.isEmpty) _buildSearchInstructions(),

          // Search results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  /// Build search input field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      autofocus: true,
      style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Tìm bạn bè...',
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textTertiary,
        ),
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
      ),
    );
  }

  /// Build search instructions
  Widget _buildSearchInstructions() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_search,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Tìm kiếm bạn bè',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập tên người dùng để tìm kiếm và kết bạn',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build search results list
  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserSearchResult(user);
      },
    );
  }

  /// Build individual user search result
  Widget _buildUserSearchResult(Friend user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.cyanAccent.withValues(alpha: 0.1),
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.cyanAccent,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        title: Text(
          user.displayName,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '@${user.username}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: _buildAddFriendButton(user),
      ),
    );
  }

  /// Build add friend button
  Widget _buildAddFriendButton(Friend user) {
    return ElevatedButton(
      onPressed: () => _sendFriendRequest(user),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyanAccent,
        foregroundColor: AppColors.primaryBackground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        'Kết bạn',
        style: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBackground,
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.cyanAccent),
          SizedBox(height: 16),
          Text('Đang tìm kiếm...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// Build empty results state
  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy người dùng',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle search input changes with debouncing
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });

      // Cancel previous timer
      _debounceTimer?.cancel();

      if (query.isNotEmpty && query.length >= 2) {
        // Debounce search by 300ms
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && query == _searchController.text.trim()) {
            _performSearch(query);
          }
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  /// Perform search API call with race condition protection
  void _performSearch(String query) async {
    // Increment request counter to track this request
    final currentRequestId = ++_requestCounter;

    setState(() {
      _isSearching = true;
    });

    try {
      final notifier = ref.read(friendsNotifierProvider.notifier);
      final results = await notifier.searchFriends(query);

      // Only update results if this is still the latest request and query matches
      if (mounted &&
          currentRequestId == _requestCounter &&
          query == _searchController.text.trim()) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      // Only show error if this is still the latest request
      if (mounted && currentRequestId == _requestCounter) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Send friend request
  void _sendFriendRequest(Friend user) async {
    try {
      final notifier = ref.read(friendsNotifierProvider.notifier);
      final success = await notifier.sendFriendRequest(user.username);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi lời mời kết bạn tới ${user.displayName}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể gửi lời mời kết bạn'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Clear search and cancel pending requests
  void _clearSearch() {
    _debounceTimer?.cancel(); // Cancel pending debounced search
    _requestCounter++; // Invalidate any in-flight requests
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
    });
  }
}
