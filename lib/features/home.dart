import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/attendancelist/pages/attendance_list_page.dart';
import 'package:dropline/features/pdf_editor_page.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================================================
      // SIMPLE GRAY BACKGROUND
      // ============================================================
      backgroundColor: const Color(0xFFF3F5F4),

      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // TOP HEADER
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  // ------------------------------------------------
                  // LOGO
                  // ------------------------------------------------
                  Image.asset(
                    'assets/images/app_logo.jpeg',
                    height: 48,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(),

                  // ------------------------------------------------
                  // PROFILE
                  // ------------------------------------------------
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E4E2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Appcolors.darkColor,
                      size: 23,
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // BODY
            // ======================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // WELCOME HEADER
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFE3E7E5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ------------------------------------------------
                          // ICON
                          // ------------------------------------------------
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: Appcolors.darkColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Image.asset(
                              'assets/images/dropline_launcher.png',
                              width: 42,
                              height: 42,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(width: 15),

                          // ------------------------------------------------
                          // TEXT
                          // ------------------------------------------------
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Appcolors.darkColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manage your work from one place.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF737A76),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // QUICK ACCESS TITLE
                    // ==================================================
                    Row(
                      children: [
                        Container(
                          height: 20,
                          width: 4,
                          decoration: BoxDecoration(
                            color: Appcolors.primaryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Appcolors.darkColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // ATTENDANCE
                    // ==================================================
                    _DashboardMenuCard(
                      icon: Icons.access_time_filled_rounded,
                      title: 'Attendance',
                      subtitle:
                          'Check in, check out and manage your attendance',
                      onTap: () {
                        debugPrint('Attendance clicked');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceListPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    _DashboardMenuCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'View Report',
                      subtitle: 'View your attendance and work reports',
                      onTap: () {
                        debugPrint('View Report clicked');
                      },
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // TODAY STATUS CARD
                    // ==================================================
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PdfEditorPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Appcolors.darkColor,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 43,
                              width: 43,
                              decoration: BoxDecoration(
                                color: Appcolors.primaryColor,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),

                            const SizedBox(width: 13),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready for the day?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Keep your attendance up to date.',
                                    style: TextStyle(
                                      color: Color(0xFFB8C2BF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // FOOTER
                    // ==================================================
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 5,
                            width: 5,
                            decoration: const BoxDecoration(
                              color: Appcolors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'BUILT FOR THE FIELD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                              color: Color(0xFF9AA19E),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            height: 5,
                            width: 5,
                            decoration: const BoxDecoration(
                              color: Appcolors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD MENU CARD
// ============================================================================

class _DashboardMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: Appcolors.primaryColor.withOpacity(0.08),
        highlightColor: Appcolors.primaryColor.withOpacity(0.03),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE1E5E3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // ==========================================================
              // ICON
              // ==========================================================
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Appcolors.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: Appcolors.primaryColor, size: 29),
              ),

              const SizedBox(width: 16),

              // ==========================================================
              // TEXT
              // ==========================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Appcolors.darkColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Color(0xFF737A76),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ==========================================================
              // ARROW
              // ==========================================================
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Appcolors.darkColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
