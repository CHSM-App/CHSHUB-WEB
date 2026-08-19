import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/domain/models/poll_request.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class PollsScreen extends ConsumerStatefulWidget {
  final int? pollId;
  final int? notifyStatusId;
  const PollsScreen({super.key,  this.pollId, this.notifyStatusId,});


  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _searchController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearchVisible = false;
  String _searchQuery = '';
  List<PollRequest> _allPolls = [];
  List<PollRequest> _filteredPolls = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _searchAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _slideController.forward();

    // Search text listener
    _searchTextController.addListener(() {
      setState(() {
        _searchQuery = _searchTextController.text;
        _filterPolls();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPolls();
    });
  }

  void _fetchPolls() {
    try {
      final societyId =
          ref.watch(basicInfoViewModelProvider).societyID ?? 'C10001';

      final loginType = ref.watch(basicInfoViewModelProvider).loginType;
      final audience = loginType == "owner" ? 3 : 4;
      final userId = ref.watch(basicInfoViewModelProvider).ownerId ?? 0;

      ref
          .read(pollsViewModelProvider.notifier)
          .getSocietyPolls(userId, societyId, audience);
    } catch (e) {
      print('Error initiating poll fetch: $e');
    }
  }

  void _filterPolls() {
    if (_searchQuery.isEmpty) {
      _filteredPolls = List.from(_allPolls);
    } else {
      _filteredPolls = _allPolls.where((poll) {
        final topic = poll.topic?.toLowerCase() ?? '';
        final description = poll.description?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return topic.contains(query) || description.contains(query);
      }).toList();
    }
  }



  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });

    if (_isSearchVisible) {
      _searchController.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        _searchFocusNode.requestFocus();
      });
    } else {
      _searchController.reverse();
      _searchTextController.clear();
      _searchQuery = '';
      _filterPolls();
      _searchFocusNode.unfocus();
    }
  }



  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onOptionTap(PollRequest poll, PollOption tappedOption) async {
    final pollsNotifier = ref.read(pollsViewModelProvider.notifier);

    // Check if any option is already selected in oneVotePerUnit polls
    final unitVoted = poll.options.any((o) => o.isSelected);
    if (poll.oneVotePerUnit == 1 && unitVoted && !tappedOption.isSelected) {
      return;
    }

    // Update UI immediately
    setState(() {
      if (poll.allowMultipleVotes == 1) {
        tappedOption.isSelected = !tappedOption.isSelected;
      } else {
        for (var o in poll.options) {
          o.isSelected = (o.optionId == tappedOption.optionId);
        }
      }

      if (poll.oneVotePerUnit == 1) {
        for (var o in poll.options) {
          o.isDisabled = !o.isSelected;
        }
      } else {
        for (var o in poll.options) {
          o.isDisabled = false;
        }
      }
    });

    try {
      final currentUserId = ref.watch(basicInfoViewModelProvider).ownerId ?? 0;

      if (!tappedOption.isSelected && tappedOption.userVoteId != null) {
        final voteIds = tappedOption
            .getVotingIdList(); // current user's vote IDs
        for (final id in voteIds) {
          await pollsNotifier.deletePollVote(id, currentUserId);
        }
      }

      // ADD vote if option is now selected
      if (tappedOption.isSelected) {
        final body = {
          "userId": currentUserId,
          "societyId": poll.societyId,
          "optionId": tappedOption.optionId,
          "userType": "member",
          "allowMultipleVotes": poll.allowMultipleVotes,
          "oneVotePerUnit": poll.oneVotePerUnit,
          "Audience": ref.watch(basicInfoViewModelProvider).loginType == "owner"
              ? 3
              : 4,
        };

        await pollsNotifier.addPollVote(poll.pollId ?? 0, body);

        final state = ref.read(pollsViewModelProvider);
        if (state.data?['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vote updated"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Refresh poll list after voting changes
      final societyId =
          ref.watch(basicInfoViewModelProvider).societyID ?? 'C10001';
      final userId = ref.watch(basicInfoViewModelProvider).ownerId ?? 0;
      final loginType = ref.watch(basicInfoViewModelProvider).loginType;
      final audience = loginType == "owner" ? 3 : 4;

      await pollsNotifier.getSocietyPolls(userId, societyId, audience);
    } catch (e) {
      print("Vote action failed: $e");

      // Rollback UI if vote action failed
      setState(() {
        for (var o in poll.options) {
          o.isSelected =
              o.userVoteId != null &&
              o.getVotingIdList().contains(
                ref.watch(basicInfoViewModelProvider).ownerId ?? 0,
              );
          o.isDisabled = false;
        }
      });
    }
  }

  // String _getTimeAgo(String? dateString) {
  //   if (dateString == null || dateString.isEmpty) return 'Unknown';
  //   try {
  //     final date = DateTime.parse(dateString);
  //     final now = DateTime.now();
  //     final difference = now.difference(date);

  //     if (difference.inDays > 0) return '${difference.inDays}d ago';
  //     if (difference.inHours > 0) return '${difference.inHours}h ago';
  //     return '${difference.inMinutes}m ago';
  //   } catch (e) {
  //     return dateString;
  //   }
  // }

  String _getTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      final seconds = difference.inSeconds;

      if (seconds < 0) {
        // Future date
        final futureDiff = date.difference(now);

        if (futureDiff.inSeconds < 60) return "in ${futureDiff.inSeconds}s";
        if (futureDiff.inMinutes < 60) return "in ${futureDiff.inMinutes}m";
        if (futureDiff.inHours < 24) return "in ${futureDiff.inHours}h";
        if (futureDiff.inDays < 7) return "in ${futureDiff.inDays}d";
        if (futureDiff.inDays < 30) {
          return "in ${(futureDiff.inDays / 7).floor()}w";
        }
        if (futureDiff.inDays < 365) {
          return "in ${(futureDiff.inDays / 30).floor()}mo";
        }
        return "in ${(futureDiff.inDays / 365).floor()}y";
      }

      // Past date
      if (seconds < 60) return "${seconds}s ago";
      if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
      if (difference.inHours < 24) return "${difference.inHours}h ago";
      if (difference.inDays < 7) return "${difference.inDays}d ago";
      if (difference.inDays < 30) {
        return "${(difference.inDays / 7).floor()}w ago";
      }
      if (difference.inDays < 365) {
        return "${(difference.inDays / 30).floor()}mo ago";
      }
      return "${(difference.inDays / 365).floor()}y ago";
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchTextController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search polls by topic...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchTextController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pollsState = ref.watch(pollsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: BackButton(
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        title: _isSearchVisible
            ? null
            : const Text(
                'Society Polls',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search bar with slide animation
          SizeTransition(
            sizeFactor: _searchAnimation,
            child: FadeTransition(
              opacity: _searchAnimation,
              child: _buildSearchBar(),

            ),
          ),

          // Polls content
          Expanded(
            child: pollsState.getSocietyPolls.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
               error: (err, _) => ErrorStatePage(error: err, onRetry: _fetchPolls),
              data: (polls) {
                // Update all polls and filtered polls when data changes
                if (_allPolls != polls) {
                  _allPolls = polls;
                  _filterPolls();
                }

                final displayPolls = _isSearchVisible || _searchQuery.isNotEmpty
                    ? _filteredPolls
                    : _allPolls;

                if (displayPolls.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _fetchPolls(),
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🗳️ Polls-related icon
                                const Icon(
                                  Icons.how_to_vote_rounded,
                                  size: 80,
                                  color: Color(0xFF93C5FD),
                                ),
                                const SizedBox(height: 20),

                                // 📝 Message text
                                const Text(
                                  'No polls available right now',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // 💬 Sub-message
                                const Text(
                                  'Check back later to participate in new polls\nfrom your society.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchPolls(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: displayPolls.length,
                        itemBuilder: (context, index) {
                          return PollCard(
                            poll: displayPolls[index],
                            onOptionTap: _onOptionTap,
                            getTimeAgo: _getTimeAgo,
                            searchQuery: _searchQuery,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------- PollCard -----------------------

class PollCard extends StatelessWidget {
  final PollRequest poll;
  final Function(PollRequest, PollOption) onOptionTap;
  final String Function(String?) getTimeAgo;
  final String searchQuery;

  const PollCard({
    super.key,
    required this.poll,
    required this.onOptionTap,
    required this.getTimeAgo,
    this.searchQuery = '',
  });

  // Helper method to highlight search terms
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      );
    }

    final startIndex = lowerText.indexOf(lowerQuery);
    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFEB3B),
              color: Color(0xFF1E293B),
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowMultiple = poll.allowMultipleVotes == 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Single/Multiple + Expiry)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: allowMultiple
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFDEF7FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  allowMultiple ? 'Multiple' : 'Single',
                  style: TextStyle(
                    color: allowMultiple
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF0EA5E9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.timer, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    getTimeAgo(poll.expireDate),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title with highlighting
          _buildHighlightedText(poll.topic ?? 'Untitled Poll', searchQuery),

          const SizedBox(height: 8),

          // Description
          Text(
            poll.description ?? 'No description available',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 20),

          // Options List
          if (poll.options.isNotEmpty)
            ...poll.options.map((option) {
              final totalVotes = poll.totalVotes ?? 0;
              final optionVotes = option.votes ?? 0;
              final percentage = totalVotes > 0
                  ? (optionVotes / totalVotes * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PollOptionWidget(
                  option: option,
                  percentage: percentage,
                  isMultipleChoice: allowMultiple,
                  onTap: option.isDisabled
                      ? null
                      : () => onOptionTap(poll, option),
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'No options available for this poll',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Footer Row (Votes + SocietyID)
          Row(
            children: [
              if (poll.expiryDate != null) ...[
                Text(
                  'Expires: ${_formatDate(poll.expiryDate!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],

              const Spacer(),
              const Icon(Icons.how_to_vote, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                '${poll.totalVotes ?? 0} votes',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('d MMM yyyy').format(date); // 4 Oct 2025
  } catch (e) {
    return dateString; // fallback
  }
}

// ----------------------- PollOptionWidget -----------------------

class PollOptionWidget extends StatefulWidget {
  final PollOption option;
  final double percentage;
  final bool isMultipleChoice;
  final VoidCallback? onTap;

  const PollOptionWidget({
    super.key,
    required this.option,
    required this.percentage,
    required this.isMultipleChoice,
    required this.onTap,
  });

  @override
  State<PollOptionWidget> createState() => _PollOptionWidgetState();
}

class _PollOptionWidgetState extends State<PollOptionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;

  final List<Color> _optionColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFEC4899),
    const Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.percentage / 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
    
  }

  @override
  void didUpdateWidget(covariant PollOptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.percentage != widget.percentage) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.percentage / 100,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );

      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  

  Color _getOptionColor() {
    final optionId = widget.option.optionId ?? '0';
    final colorIndex = optionId.hashCode.abs() % _optionColors.length;
    return _optionColors[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    final optionColor = _getOptionColor();
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.option.isSelected ? _bounceAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.option.isSelected
                      ? optionColor
                      : const Color(0xFFE2E8F0),
                  width: widget.option.isSelected ? 2 : 1,
                ),
                color: widget.option.isDisabled
                    ? Colors.grey.shade200
                    : (widget.option.isSelected
                          ? optionColor.withOpacity(0.1)
                          : Colors.transparent),
              ),
              child: Column(
                children: [
                  // Progress Bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: const Color(0xFFF1F5F9),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: LinearGradient(
                                  colors: [
                                    optionColor,
                                    optionColor.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: widget.isMultipleChoice
                                ? BoxShape.rectangle
                                : BoxShape.circle,
                            borderRadius: widget.isMultipleChoice
                                ? BorderRadius.circular(4)
                                : null,
                            border: Border.all(
                              color: widget.option.isSelected
                                  ? optionColor
                                  : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                            color: widget.option.isSelected
                                ? optionColor
                                : Colors.transparent,
                          ),
                          child: widget.option.isSelected
                              ? Icon(
                                  widget.isMultipleChoice
                                      ? Icons.check
                                      : Icons.circle,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.option.text ?? 'Option',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: widget.option.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: widget.option.isDisabled
                                  ? Colors.grey
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.option.votes ?? 0}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: optionColor,
                              ),
                            ),
                            Text(
                              '${widget.percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

extension PollOptionHelper on PollOption {
  /// Convert userVoteId string like "4,10" to List<int>
  List<int> getVotingIdList() {
    if (userVoteId == null || userVoteId!.isEmpty) return [];
    return userVoteId!
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((id) => id != null)
        .map((e) => e!)
        .toList();
  }
}
