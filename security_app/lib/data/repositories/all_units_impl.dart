import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/domain/models/unit_spinner.dart';
import 'package:security_app/domain/repository/AllUnits_repo.dart';

class AllUnitsImpl implements AllUnitsRepo {
  final ApiService _api;

  AllUnitsImpl(this._api);

  @override
  Future<List<UnitSpinner>> getAllUnits(String societyId) {
    return _api.getAllUnits(societyId);
  }
} 