import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_code/model/qr_model.dart';

class QrResultsProvider extends ChangeNotifier {
  Box? box;
  openBox(Box? b) async {
    box = b;
    notifyListeners();
  }

  List<QrResults> get qrResultsbox {
    final qrResults = box?.get('qrResults', defaultValue: <QrResults>[]);

    return <QrResults>[
      if (qrResults != null && qrResults.isNotEmpty) ...qrResults
    ];
  }

  final List<QrResults> _qrResults = [];

  List<QrResults> get qrResults => _qrResults;

  void addQrResults(QrResults qr) {
    for (var e in _qrResults) {
      if (e.code == qr.code) {
        return;
      }
    }
    for (var e in qrResultsbox) {
      if (e.code == qr.code) {
        return;
      }
    }
    _qrResults.add(qr);
    notifyListeners();
    updatebox(qr: qr);
  }

  void removeQrResults(QrResults qr) {
    _qrResults.remove(qr);
    notifyListeners();
    updatebox(qr: qr);
  }

  void clearQrResults() {
    _qrResults.clear();
    notifyListeners();
    updatebox();
  }

  updatebox({QrResults? qr}) {
    if (qr != null) {
      box?.put('qrResults', qrResultsbox..add(qr));
    } else {
      box?.put('qrResults', []);
    }

    notifyListeners();
  }
}
