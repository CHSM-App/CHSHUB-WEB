import 'package:security_app/domain/models/unit_spinner.dart';

abstract class AllUnitsRepo {
  Future<List<UnitSpinner>> getAllUnits(String societyId);
}