import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';

/// ToastUtils — delegates to AppToast for styled animated notifications.
/// Use this across the app for consistent toast messaging.
class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    AppToast.success(context, message);
  }

  static void showError(BuildContext context, String message) {
    AppToast.error(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    AppToast.info(context, message);
  }

  static void showWarning(BuildContext context, String message) {
    AppToast.warning(context, message);
  }
}
