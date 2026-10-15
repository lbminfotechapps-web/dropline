import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/punch_header.dart';
import '../widgets/punch_time_card.dart';
import '../widgets/work_details_card.dart';
import '../widgets/punch_out_slide_bar.dart';

class PunchOutPage extends StatefulWidget {
  const PunchOutPage({super.key});

  @override
  State<PunchOutPage> createState() => _PunchOutPageState();
}

class _PunchOutPageState extends State<PunchOutPage> {
  final String projectName = 'TRIBECA';

  // Temporary static values for UI
  final String inTime = '09:41';
  final String workedDuration = '02:00';
  final String clockOutTime = '11:45';
  final String workType = 'EVENT';

  void _onAddWorkDetails() {
      context.push(AppRouter.addEvent);
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(const SnackBar(content: Text('Add Work Details clicked')));
  }

  void _onClockOut() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Clock Out action triggered')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 739;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      54 * scale,
                      48 * scale,
                      54 * scale,
                      30 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PunchHeader(
                              title: projectName,
                              scale: scale,
                              onBack: () => Navigator.pop(context),
                            ),

                            SizedBox(height: 121 * scale),

                            PunchTimeCard(
                              time: inTime,
                              height: 200 * scale,
                              fontSize: 116 * scale,
                              radius: 54 * scale,
                            ),

                            SizedBox(height: 76 * scale),

                            PunchTimeCard(
                              time: workedDuration,
                              height: 260 * scale,
                              fontSize: 164 * scale,
                              radius: 52 * scale,
                            ),

                            SizedBox(height: 78 * scale),

                            WorkDetailsCard(
                              title: 'ADD WORK DETAILS',
                              value: workType,
                              onTap: _onAddWorkDetails,
                              scale: scale,
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 80 * scale),
                          child: PunchOutSlideBar(
                            actionText: 'CLOCK OUT',
                            timeText: clockOutTime,
                            onCompleted: _onClockOut,
                            scale: scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
