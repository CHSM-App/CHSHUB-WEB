import '../../widgets/app_widgets.dart' show money, pick;
import 'json_utils.dart';

/// One flat's maintenance bill, in the shape the printed sheet needs.
///
/// The website's BillsPage builds the same figures inline; this holds them in
/// one place because the app renders them twice — once on screen and once into
/// the PDF — and the two must not drift.
class BillSheetData {
  const BillSheetData({
    required this.societyName,
    required this.registrationNo,
    required this.address,
    required this.ownerName,
    required this.flatNo,
    required this.wingName,
    required this.area,
    required this.billDate,
    required this.dueDate,
    required this.lines,
    required this.charges,
    required this.forward,
  });

  final String? societyName;
  final String? registrationNo;
  final String? address;

  final String? ownerName;
  final String? flatNo;
  final String? wingName;
  final String? area;
  final DateTime? billDate;
  final DateTime? dueDate;

  /// The charge heads that carry both a name and an amount on this row.
  final List<BillLine> lines;

  /// This run's own charges — the printed lines, added up.
  ///
  /// Neither stored column can stand in for them. total_amount means different
  /// things to the two procedures: gen_bill writes the month's charges alone,
  /// while sp_new_maintenance does `@total_amt = @total_amt + @amt_forward +
  /// @tax_interest` and folds arrears in, so adding amt_forward on top counted
  /// the dues twice. `due` is consistent between them but drops as payments
  /// settle against the bill — flat 102's February total read 31.49 over lines
  /// adding to 996.15 once it had part-paid.
  final double charges;

  /// Arrears carried forward. Shown only when non-zero, as the legacy
  /// Repeater3_ItemDataBound did: "Dues as of ...: 0.00" tells a resident with
  /// a clean ledger nothing, but any arrears must show — they are usually most
  /// of what is payable.
  final double forward;

  double get grandTotal => charges + forward;

  /// Pull one flat's sheet out of a `sp_maintanance_cal` row.
  ///
  /// [chargeColumns] are the {nameKey, amountKey} pairs the bills route derived
  /// from the row: the procedure pivots each society's own charge heads into
  /// col1_name/col1_amount, so the set varies by society and cannot be fixed
  /// here.
  factory BillSheetData.fromRow(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> chargeColumns,
  ) {
    final lines = <BillLine>[];
    for (final pair in chargeColumns) {
      final nameKey = pair['nameKey']?.toString();
      final amountKey = pair['amountKey']?.toString();
      if (nameKey == null || amountKey == null) continue;

      final name = pick(row, [nameKey]);
      final amount = row[amountKey];
      if (name == null || amount == null) continue;

      lines.add(BillLine(name, asDoubleOr(amount)));
    }

    final sqFt = pick(row, ['sq_ft', 'sqft', 'area']);

    return BillSheetData(
      societyName: pick(row, ['society_name', 'soc_name']),
      registrationNo: pick(row, ['registration_no', 'reg_no']),
      address: pick(row, ['address1', 'address']),
      ownerName: pick(row, ['owner_name', 'name', 'resident_name']),
      flatNo: pick(row, ['flat_no', 'unit_no', 'flat', 'flat_name']),
      wingName: pick(row, ['w_name', 'building_name', 'build_name', 'wing']),
      area: sqFt == null ? null : '$sqFt sq.ft',
      billDate: asDate(row['gen_date'] ?? row['bill_date']),
      dueDate: asDate(row['due_date']),
      lines: lines,
      charges: lines.fold<double>(0, (sum, l) => sum + l.amount),
      forward: asDoubleOr(row['amt_forward']),
    );
  }

  /// The six boxes above the charge table, laid out two per row.
  List<MapEntry<String, String>> get particulars => [
    MapEntry('Owner Name', ownerName ?? '—'),
    MapEntry('Flat No', flatNo ?? '—'),
    MapEntry('Wing Name', wingName ?? '—'),
    MapEntry('Bill Date', billDay),
    MapEntry('Area', area ?? '—'),
    MapEntry('Due Date', dueDay),
  ];

  String get billDay => billDate == null ? '—' : sheetDay(billDate);
  String get dueDay => dueDate == null ? '—' : sheetDay(dueDate);

  /// A label for files and dialogs: "A-101" or the flat alone.
  String get label =>
      [wingName, flatNo].where((e) => e != null && e.isNotEmpty).join('-');
}

class BillLine {
  const BillLine(this.name, this.amount);
  final String name;
  final double amount;
}

/// dd-MM-yyyy, as the legacy bill printed it.
///
/// Not a locale-following format: a bill dated 1 February would render "2/1"
/// under an en-US locale, which an Indian reader takes for 2 January. A bill is
/// a demand for money; its dates cannot depend on who opens it.
String sheetDay(DateTime? d) {
  if (d == null) return '—';
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(d.day)}-${pad(d.month)}-${d.year}';
}

/// The bill's money format, without the app's ₹ prefix — the sheet draws its
/// own "₹" so the PDF font and the screen agree.
String sheetAmount(double v) => money(v).replaceFirst('₹', '').trim();

const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];
const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _under100(int x) => x < 20
    ? _ones[x]
    : '${_tens[x ~/ 10]}${x % 10 != 0 ? ' ${_ones[x % 10]}' : ''}';

String _under1000(int x) {
  final hundreds = x >= 100
      ? '${_ones[x ~/ 100]} Hundred${x % 100 != 0 ? ' ' : ''}'
      : '';
  return '$hundreds${x % 100 != 0 ? _under100(x % 100) : ''}';
}

String _spell(int whole) {
  if (whole == 0) return 'Zero';
  final parts = <String>[];
  final crore = whole ~/ 10000000;
  final lakh = (whole % 10000000) ~/ 100000;
  final thousand = (whole % 100000) ~/ 1000;
  final rest = whole % 1000;

  if (crore != 0) parts.add('${_under1000(crore)} Crore');
  if (lakh != 0) parts.add('${_under1000(lakh)} Lakh');
  if (thousand != 0) parts.add('${_under1000(thousand)} Thousand');
  if (rest != 0) parts.add(_under1000(rest));
  return parts.join(' ');
}

/// Rupees in words, for the line the legacy bill closed with.
///
/// Indian numbering: thousand, lakh, crore — not the western million. Paise get
/// their own clause when non-zero, as NumberToWords() did: a bill of 1,765.38
/// reads "... Sixty Five Rupees and Thirty Eight Paise Only". Dropping them
/// understated every bill whose charges divided unevenly across flats, which is
/// most of them.
String amountInWords(double value) {
  final n = value.floor();
  final paise = ((value - n) * 100).round();
  if (n == 0 && paise == 0) return 'Zero Rupees Only';

  final words = '${_spell(n)} Rupees';
  return paise > 0 ? '$words and ${_spell(paise)} Paise Only' : '$words Only';
}
