class ModelsModel {
  final String object;
  final List<Datum> data;

  ModelsModel({
    required this.object,
    required this.data,
  });

  factory ModelsModel.fromJson(Map<String, dynamic> parsedJson) {
    var list = parsedJson['data'] as List;
    List<Datum> dataList = list.map((i) => Datum.fromJson(i)).toList();
    return ModelsModel(object: parsedJson['object'], data: dataList);
  }
}

class Datum {
  String id;
  String object;
  int created;
  String ownedBy;

  Datum({
    required this.id,
    required this.object,
    required this.created,
    required this.ownedBy,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        object: json["object"],
        created: json["created"],
        ownedBy: json["owned_by"],
      );
}
