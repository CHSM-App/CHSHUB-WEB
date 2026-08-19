import 'package:society_app/domain/models/facilities.dart';
import 'package:society_app/domain/repository/facilities_repository.dart';

class FacilitiesUsecase {
  final FacilitiesRepository repository;
  
  FacilitiesUsecase(this.repository);

  Future<List<Facilities>> getFacilities(String societyId) async {
    return await repository.getFacilities(societyId);
  }

  Future<List<Facilities>> getBookedAmenities(int flatId) async {
    return await repository.getBookedFacilities(flatId);
  }

  Future<List<Facilities>> getAvailableSlots(int facilityId, String date) async {
    return await repository.getAvailableSlots(facilityId, date);
  }

  Future<dynamic> bookFacility(Facilities facility) async {
    return await repository.bookFacility(facility);
  }
}
