import 'package:gpt_chatbot/models/models_model.dart';
import 'package:gpt_chatbot/services/api_service.dart';
import 'package:flutter/cupertino.dart';

class ModelsProvider with ChangeNotifier {
  String currentModel = "gpt-3.5-turbo-0125";

  String get getCurrentModel {
    return currentModel;
  }

  void setCurrentModel(String newModel) {
    currentModel = newModel;
    notifyListeners();
  }

  List<Datum> modelsList = [];

  List<Datum> get getModelsList {
    return modelsList;
  }

  Future<List<Datum>> getAllModels() async {
    modelsList = await ApiService.getModels();
    return modelsList;
  }
}