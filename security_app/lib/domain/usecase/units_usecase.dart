import 'package:security_app/domain/models/unit_spinner.dart';
import 'package:security_app/domain/repository/AllUnits_repo.dart';

class UnitsUsecase {
  final AllUnitsRepo allunitsRepo;

  UnitsUsecase(this.allunitsRepo);

  Future<List<UnitSpinner>> getAllUnits(String societyId) {
    return allunitsRepo.getAllUnits(societyId);
  }
}