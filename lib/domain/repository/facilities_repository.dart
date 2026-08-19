

import 'package:society_app/domain/models/facilities.dart';
// import 'package:society_app/domain/models/facilities_slot.dart';

abstract class FacilitiesRepository {
  Future<List<Facilities>> getFacilities(String societyId);

  Future<List<Facilities>> getBookedFacilities(int flatId,);

  Future<List<Facilities>> getAvailableSlots(int facilityId, String date,);

  Future<dynamic> bookFacility(Facilities facility);
}

