import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  if (!Platform.isAndroid) return true;

  if (await Permission.manageExternalStorage.isGranted) return true;

  final status = await Permission.manageExternalStorage.request();
  return status.isGranted;
}
