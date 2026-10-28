// Lectura tolerante de JSON: el servidor puede mandar números como texto o campos vacíos.

int asInt(dynamic v, [int d = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
int? asIntOrNull(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
double asDouble(dynamic v, [double d = 0]) => v is num ? v.toDouble() : double.tryParse('$v') ?? d;
double? asDoubleOrNull(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
String asString(dynamic v) => v == null ? '' : '$v';
String? asStringOrNull(dynamic v) => v == null ? null : '$v';
bool asBool(dynamic v) => v == true;
List<String> asStringList(dynamic v) => v is List ? v.map((e) => '$e').toList() : <String>[];
Map<String, dynamic> asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> asMapList(dynamic v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
