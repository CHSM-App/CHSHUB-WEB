import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'noc_certificate_screen.dart';
import 'noc_request_screen.dart';

/// NOC — the requests members raise, and the certificates they produce.
///
/// One screen with two tabs rather than two entries on the dashboard. They are
/// two halves of one thing: a certificate exists only because a request was
/// approved, and the secretary moves between them constantly — "has Sharma's
/// NOC been signed yet" is answered in one tab and "what number did we give
/// it" in the other. Listing them separately made the secretary guess which of
/// two similarly named tiles held the thing they were looking for.
///
/// The website's NOC page is laid out the same way, so the two do not have to
/// be learned twice.
class NocScreen extends ConsumerStatefulWidget {
  const NocScreen({super.key});

  @override
  ConsumerState<NocScreen> createState() => _NocScreenState();
}

class _NocScreenState extends ConsumerState<NocScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      // The segmented bar reads the controller's index, so a swipe of the tab
      // view moves the pills too.
      ..addListener(() => setState(() {}));

    // Both lists load up front: the counts on the tabs are what tell the
    // secretary which half needs them, and a count that only appears after
    // the tab is opened cannot do that.
    Future.microtask(() {
      final vm = ref.read(communityViewModelProvider.notifier);
      vm.loadNocRequests();
      vm.loadNocCertificates();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// How many requests are waiting on somebody — the badge worth showing.
  ///
  /// Not every request: a settled one needs nothing, and counting it would
  /// leave a number on the tab that never falls.
  int get _openRequests {
    final rows = ref
        .watch(communityViewModelProvider)
        .items(CommunityKeys.nocRequests);

    return rows.where((r) {
      final status = r['status'];
      final code = status is int ? status : int.tryParse('$status') ?? 0;
      return code == NocStage.pending.code ||
          code == NocStage.approved.code ||
          code == NocStage.ready.code;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final certificates = ref
        .watch(communityViewModelProvider)
        .items(CommunityKeys.nocCertificates)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOC'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(SegmentedTabBar.height),
          child: SegmentedTabBar(
            tabs: [
              SegmentTab(
                label: 'Requests',
                icon: Icons.mark_email_unread_outlined,
                count: _openRequests,
              ),
              SegmentTab(
                label: 'Certificates',
                icon: Icons.verified_outlined,
                count: certificates,
              ),
            ],
            selectedIndex: _tabs.index,
            onSelected: _tabs.animateTo,
          ),
        ),
      ),
      // Only the certificates tab issues one directly. A certificate is
      // normally the outcome of an approved request; this covers the member
      // who asked at the desk and never raised one.
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton.extended(
              onPressed: _issueNew,
              icon: const Icon(Icons.add),
              label: const Text('New NOC'),
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: const [
          NocRequestScreen(embedded: true),
          NocCertificateScreen(embedded: true),
        ],
      ),
    );
  }

  Future<void> _issueNew() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NocCertificateFormScreen()));
    if (!mounted) return;
    await ref.read(communityViewModelProvider.notifier).loadNocCertificates();
  }
}
