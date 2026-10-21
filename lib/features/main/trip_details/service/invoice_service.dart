import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';

class InvoiceService {
  static Future<String?> saveInvoice(String tripId) async {
    final bytes = await TripsRepository().downloadInvoice(tripId);

    final cacheDir = await getTemporaryDirectory();
    final staged = File('${cacheDir.path}/invoice_$tripId.pdf');
    await staged.writeAsBytes(bytes, flush: true);

    try {
      return await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(sourceFilePath: staged.path, fileName: 'invoice_$tripId.pdf'),
      );
    } finally {
      if (await staged.exists()) {
        await staged.delete();
      }
    }
  }

  static Future<void> openInvoice(String tripId) async {
    final bytes = await TripsRepository().downloadInvoice(tripId);

    final cacheDir = await getTemporaryDirectory();
    final staged = File('${cacheDir.path}/invoice_$tripId.pdf');
    await staged.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(staged.path);
  }
}
