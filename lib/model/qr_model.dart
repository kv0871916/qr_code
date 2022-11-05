import 'package:hive_flutter/hive_flutter.dart';
part 'qr_model.g.dart';

@HiveType(typeId: 0)
class QrResults extends HiveObject {
  @HiveField(0)
  final String? code;
  @HiveField(1)
  late final String? format;

  QrResults({this.code, this.format});

  factory QrResults.fromJson(Map<String, dynamic> json) {
    return QrResults(
      code: json['code'],
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'format': format,
    };
  }
}
