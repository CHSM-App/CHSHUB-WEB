import 'package:society_app/domain/models/noc_request.dart';

/// The member's side of a no-objection certificate.
///
/// A member may ask, and may watch where their request has got to. Everything
/// else — the wording, who must approve it, when the signed letter can be
/// collected — is the society's, and lives in the committee's own apps.
abstract class NocRepository {
  /// Raise a request. Returns the server's reply, carrying the new
  /// `request_id`.
  Future<dynamic> insertNocRequest(NocRequest request);

  /// The flat's requests, newest first.
  ///
  /// Keyed by flat rather than by member: a NOC belongs to the home, so the
  /// household sees a request whichever of them raised it.
  Future<List<NocRequest>> getNocRequests(int flatId);
}
