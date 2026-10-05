import 'package:flutter/material.dart';

import 'package:cocoa_supply/bloc/task/task_event.dart';
import 'package:cocoa_supply/theme/app_colors.dart';

/// สำเร็จ / ไม่สำเร็จ after a form is submitted.
///
/// The form used to close the moment the answer was handed to TaskBloc,
/// before anything had actually been sent, so a farmer never learned that a
/// submission was sitting unsent on their phone. This shows what really
/// happened, and says plainly whether the answer is safe:
///
/// - sent: saved on the server.
/// - savedOffline: not sent, but kept on this phone and sent automatically
///   later -- nothing to redo.
/// - failed: neither sent nor kept -- the only case where they must try again.
class SubmitResultView extends StatelessWidget {
  final SubmitResult result;
  final VoidCallback onDone;

  const SubmitResultView({super.key, required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ok = result.outcome == SubmitOutcome.sent;
    final kept = result.outcome == SubmitOutcome.savedOffline;

    final String title = ok ? 'บันทึกสำเร็จ' : 'ส่งไม่สำเร็จ';
    final String message;
    if (ok) {
      message = 'ส่งข้อมูลเข้าระบบเรียบร้อยแล้ว';
    } else if (kept) {
      message = 'ข้อมูลบันทึกไว้ในเครื่องแล้ว ระบบจะส่งให้อีกครั้งเมื่อมีสัญญาณ ไม่ต้องกรอกใหม่';
    } else {
      message = 'ไม่สามารถบันทึกข้อมูลได้ กรุณาลองใหม่อีกครั้ง';
    }

    final Color color = ok
        ? const Color(0xFF4A7C59)
        : kept
            ? const Color(0xFFE6A23C)
            : Colors.red.shade700;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : (kept ? Icons.cloud_off_rounded : Icons.error_rounded),
              size: 88,
              color: color,
            ),
            const SizedBox(height: 24),
            Text(title, style: textTheme.headlineSmall?.copyWith(color: color), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, style: textTheme.bodyLarge, textAlign: TextAlign.center),
            // The server's own reason, when there was one -- a farmer (or the
            // researcher they call) needs it to know what to fix.
            if (!ok && result.serverError != null) ...[
              const SizedBox(height: 12),
              Text(
                'เหตุผลจากระบบ: ${result.serverError}',
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'กลับหน้ารายการงาน',
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
