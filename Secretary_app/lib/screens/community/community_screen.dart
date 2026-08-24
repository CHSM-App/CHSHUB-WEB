import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../hub_scaffold.dart';
import 'facility_bookings_screen.dart';
import 'helpdesk_screen.dart';
import 'more_community_screen.dart';
import 'notices_screen.dart';
import 'visitors_screen.dart';

/// Resident-facing work.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    // Loaded here so the hub can badge the complaints that are waiting — the
    // count is the reason to open the screen at all.
    Future.microtask(
      () => ref.read(communityViewModelProvider.notifier).loadHelpdesk(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = ref
        .watch(communityViewModelProvider)
        .items(CommunityKeys.helpdesk)
        .length;

    return HubScaffold(
      title: 'Community',
      intro: 'Complaints, visitors, notices and everything residents see.',
      entries: [
        HubEntry(
          icon: Icons.support_agent_outlined,
          color: AppTheme.error,
          title: 'Helpdesk',
          subtitle: 'Resident complaints and replies',
          badge: open > 0 ? '$open' : null,
          builder: () => const HelpdeskScreen(),
        ),
        HubEntry(
          icon: Icons.how_to_reg_outlined,
          color: AppTheme.info,
          title: 'Visitors',
          subtitle: 'Gate entries and check-outs',
          builder: () => const VisitorsScreen(),
        ),
        HubEntry(
          icon: Icons.campaign_outlined,
          color: AppTheme.primary,
          title: 'Notices',
          subtitle: 'Publish announcements to residents',
          builder: () => const NoticesScreen(),
        ),
        HubEntry(
          icon: Icons.event_available_outlined,
          color: AppTheme.success,
          title: 'Facility bookings',
          subtitle: 'Clubhouse, hall and amenity bookings',
          builder: () => const FacilityBookingsScreen(),
        ),
        HubEntry(
          icon: Icons.forum_outlined,
          color: AppTheme.violet,
          title: 'Messages & more',
          subtitle: 'Polls, suggestions, events, meetings, documents',
          builder: () => const MoreCommunityScreen(),
        ),
      ],
    );
  }
}
