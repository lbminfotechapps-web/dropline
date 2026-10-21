import 'dart:convert';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/utility/widgets/app_toast.dart';
import 'package:dropline/features/event/data/services/event_submission_preview_service.dart';
import 'package:dropline/features/event/domain/entities/event_draft_scope.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

Future<void> finishLocationSetup(
  BuildContext context, {
  required LocationFlowArgs flowArgs,
}) async {
  try {
    final EventDraftScope currentScope = flowArgs.scope;

    debugPrint('FINISH SETUP - TIME SLOT: ${currentScope.timeSlotId}');

    // ====================================
    // LOAD CURRENT SLOT'S COMPLETE EVENT
    // ====================================

    final payload = await sl<EventSubmissionPreviewService>().previewOnly(
      scope: currentScope,
      projectName: flowArgs.projectName,
    );

    // ====================================
    // PRINT COMPLETE JSON
    // ====================================

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

    debugPrintSynchronously('========== COMPLETE EVENT JSON START ==========');

    for (var i = 0; i < jsonString.length; i += 800) {
      final end = i + 800 < jsonString.length ? i + 800 : jsonString.length;

      debugPrintSynchronously(jsonString.substring(i, end));
    }

    debugPrintSynchronously('========== COMPLETE EVENT JSON END ==========');

    // ====================================
    // OPEN SELECT LOCATION SCREEN
    // ====================================

    if (!context.mounted) return;

    await context.push(
      AppRouter.selectLocation,
      extra: LocationFlowArgs(
        scope: currentScope,
        projectName: flowArgs.projectName,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('FINISH SETUP ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!context.mounted) return;

    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(SnackBar(content: Text('Unable to prepare event data: $e')));
      AppToast.error('Unable to prepare event data: $e');
  }
}
