import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/error_formatter.dart';
import '../../domain/models/paged_rows.dart';

/// One named, independently-loading collection.
///
/// The screens in this app are almost all "a list, a search box and a few
/// actions", and several screens show more than one list at once (the receipt
/// form needs residents *and* that flat's outstanding bills). Giving every
/// collection its own AsyncValue keeps one failing list from blanking the
/// others.
typedef Rows = AsyncValue<RowList>;

const Rows rowsLoading = AsyncValue.loading();

/// Base state: a map of named collections plus a command status.
///
/// `isLoading`/`error` describe the last *command* (save, delete, generate) —
/// the per-collection AsyncValues describe the reads. They are separate because
/// a failed save must not wipe the list that is still on screen.
class ListState {
  final Map<String, Rows> collections;
  final bool isLoading;
  final String? error;

  /// Set by a command that succeeded, for a snackbar. Cleared on the next one.
  final String? message;

  const ListState({
    this.collections = const {},
    this.isLoading = false,
    this.error,
    this.message,
  });

  Rows rows(String key) => collections[key] ?? rowsLoading;

  /// The rows of [key], or an empty list while loading or after an error —
  /// what a builder wants when it is already showing its own empty state.
  ///
  /// `valueOrNull`, not `value`: on an AsyncError the latter rethrows, so a
  /// screen that read this to decide what to draw crashed on the very error it
  /// meant to render a message about.
  List<Map<String, dynamic>> items(String key) =>
      collections[key]?.valueOrNull?.items ?? const [];

  bool isBusy(String key) => collections[key]?.isLoading ?? true;

  ListState copyWith({
    Map<String, Rows>? collections,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return ListState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  ListState withCollection(String key, Rows value) {
    return copyWith(collections: {...collections, key: value});
  }

  /// Several collections at once.
  ///
  /// Not [withCollection] in a loop: each call spreads the *original* map, so
  /// the last write would drop the others.
  ListState withCollections(Map<String, Rows> values) {
    return copyWith(collections: {...collections, ...values});
  }
}

/// Shared plumbing for the feature ViewModels.
///
/// `load` and `run` are the two shapes every method in this app takes; writing
/// them once means a new screen adds a one-line method rather than another
/// copy of the same try/catch.
abstract class ListViewModel extends StateNotifier<ListState> {
  ListViewModel() : super(const ListState());

  /// Guards drainable/double-submittable commands per key.
  final Set<String> _inFlight = {};

  /// Fetch into a named collection.
  ///
  /// Keeps the previous rows visible while refreshing (`copyWithPrevious`), so
  /// pull-to-refresh does not flash an empty list.
  Future<void> load(String key, Future<RowList> Function() fetch) async {
    final previous = state.collections[key];
    state = state.withCollection(
      key,
      previous == null
          ? rowsLoading
          : const AsyncValue<RowList>.loading().copyWithPrevious(previous),
    );

    try {
      state = state.withCollection(key, AsyncValue.data(await fetch()));
    } catch (e, st) {
      // formatError is applied at read time by the widgets via errorText();
      // the raw error and stack are kept so nothing is lost.
      state = state.withCollection(key, AsyncValue.error(e, st));
    }
  }

  /// Load several collections at once, each tracking its own status.
  ///
  /// The loading marks go on in one write rather than one per key: each
  /// `withCollection` spreads the map it was called on, so two of them racing
  /// would leave only the later key marked.
  Future<void> loadAll(Map<String, Future<RowList> Function()> fetches) async {
    state = state.withCollections({
      for (final key in fetches.keys)
        key: state.collections[key] == null
            ? rowsLoading
            : const AsyncValue<RowList>.loading().copyWithPrevious(
                state.collections[key]!,
              ),
    });

    // Each fetch settles into its own key as it lands. `load` would re-mark
    // the key as loading first, undoing the batch above.
    //
    // The result is awaited into a local before `state` is touched. Written as
    // `state = state.withCollection(k, AsyncValue.data(await fetch()))`, Dart
    // evaluates the receiver `state` *before* suspending on the await, so two
    // fetches racing here would both spread the same pre-await map and the
    // slower one would erase the faster one's rows.
    await Future.wait(
      fetches.entries.map((e) async {
        Rows result;
        try {
          result = AsyncValue.data(await e.value());
        } catch (err, st) {
          result = AsyncValue.error(err, st);
        }
        state = state.withCollection(e.key, result);
      }),
    );
  }

  /// Run a command (save, delete, generate).
  ///
  /// Returns true on success. [onSuccess] runs before the state is cleared, so
  /// it is the place to refetch whatever the command changed.
  Future<bool> run(
    Future<void> Function() body, {
    String? guard,
    String? successMessage,
    Future<void> Function()? onSuccess,
  }) async {
    final key = guard ?? 'default';
    if (_inFlight.contains(key)) return false;
    _inFlight.add(key);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearMessage: true,
    );

    try {
      await body();
      await onSuccess?.call();
      state = state.copyWith(isLoading: false, message: successMessage);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: formatError(e));
      return false;
    } finally {
      _inFlight.remove(key);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  void clearMessage() => state = state.copyWith(clearMessage: true);
}

/// The message to show for a failed collection.
String errorText(Object error) => formatError(error);
