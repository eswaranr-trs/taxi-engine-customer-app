import 'package:fluttertoast/fluttertoast.dart';

DateTime? _lastBackPressAt;

bool shouldExitOnBack() {
  final now = DateTime.now();
  if (_lastBackPressAt == null || now.difference(_lastBackPressAt!) > const Duration(seconds: 2)) {
    _lastBackPressAt = now;
    Fluttertoast.showToast(
      msg: 'Press back again to exit',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    return false;
  }
  return true;
}
