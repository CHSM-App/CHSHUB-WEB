import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/facilities.dart';
import 'package:society_app/domain/repository/facilities_repository.dart';

class FacilitiesImpl implements FacilitiesRepository {
  final ApiService apiService;

  FacilitiesImpl(this.apiService);



  @override
  Future<List<Facilities>> getFacilities(String societyId) async {
    try {
      final response = await apiService.getFacilities(societyId);
      return response;
    } catch (e) {
      throw Exception('Failed to load facilities: $e');
    }
  }

  
  @override
  Future<List<Facilities>> getBookedFacilities(int flatId) async {
  try {
      final response = await apiService.getBookedFacilities(flatId);
      return response;
    } catch (e) {
      throw Exception('Failed to load booked amenities: $e');
    }
  }

  @override
  Future<List<Facilities>> getAvailableSlots(int facilityId, String preDate) async {
    try {
      final response = await apiService.getFacilitySlots(facilityId, preDate);
      return response;
    } catch (e) {
      throw Exception('Failed to load available slots: $e');
    }
  }


  @override
  Future<dynamic> bookFacility(Facilities facility, ) async {
    try {
      final response = await apiService.bookFacility(facility);
      return response;
    } catch (e) {
      throw Exception('Failed to book facility: $e');
    }
  }
  
}