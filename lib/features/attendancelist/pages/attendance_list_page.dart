import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/attendancelist/data/model/attendance_record.dart';
import 'package:dropline/features/attendancelist/pages/attendenace_details_page.dart';
import 'package:dropline/features/attendancelist/pages/widget/attendance_card.dart';
import 'package:dropline/features/attendancelist/pages/widget/detail_action.dart';
import 'package:flutter/material.dart';

class AttendanceListPage extends StatefulWidget {
  const AttendanceListPage({super.key});

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

class _AttendanceListPageState extends State<AttendanceListPage> {
  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  bool _showSearch = false;
  String _searchText = '';

  // ============================================================
  // DATA
  // ============================================================

  final List<AttendanceRecord> _records = [
    AttendanceRecord(
      date: '21 Sep 2026',
      siteName: 'Green Valley Construction',
      inTime: '08:30 AM',
      outTime: '05:30 PM',
      note: 'Foundation work completed.',
      hasPhoto: true,
      hasRecording: true,
    ),
    AttendanceRecord(
      date: '22 Sep 2026',
      siteName: 'Sunrise Tower Site',
      inTime: '08:30 AM',
      outTime: '',
      note: 'Site work in progress.',
      hasPhoto: true,
      hasRecording: true,
    ),
    AttendanceRecord(
      date: '20 Sep 2026',
      siteName: 'Metro Residency',
      inTime: '09:00 AM',
      outTime: '05:45 PM',
      note: 'Material checking completed.',
      hasPhoto: true,
      hasRecording: true,
    ),
    AttendanceRecord(
      date: '19 Sep 2026',
      siteName: 'Lake View Project',
      inTime: '08:45 AM',
      outTime: '05:15 PM',
      note: 'Site inspection completed.',
      hasPhoto: false,
      hasRecording: true,
    ),
  ];

  // ============================================================
  // FILTER
  // ============================================================

  List<AttendanceRecord> get _filteredRecords {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _records;
    }

    return _records.where((record) {
      return record.siteName.toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openAddAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendancePage()),
    );
  }

  void _openEditAttendance(AttendanceRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttendancePage(record: record)),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _toggleSearch() {
    if (_showSearch) {
      _closeSearch();
      return;
    }

    setState(() {
      _showSearch = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _searchController.clear();

    FocusScope.of(context).unfocus();

    setState(() {
      _searchText = '';
      _showSearch = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),

      body: SafeArea(
        child: Column(
          children: [
            // ===================================================
            // HEADER
            // ===================================================
            _buildHeader(records.length),

            // ===================================================
            // SEARCH FIELD
            // ===================================================
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showSearch
                  ? Padding(
                      key: const ValueKey('search'),
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildSearchBar(),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-search')),
            ),

            const SizedBox(height: 12),

            // ===================================================
            // LIST
            // ===================================================
            Expanded(
              child: records.isEmpty
                  ? _buildNoResult()
                  : ListView(
                      physics: const BouncingScrollPhysics(),

                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),

                      children: [
                        // =======================================
                        // CURRENT / TODAY
                        // =======================================
                        if (_searchText.isEmpty) ...[
                          _buildCurrentAttendance(),

                          const SizedBox(height: 10),
                        ],

                        // =======================================
                        // HISTORY
                        // =======================================
                        ...records.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildAttendanceRow(record: record),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),

      // =========================================================
      // SEARCH + ADD
      // =========================================================
      bottomNavigationBar: SafeArea(top: false, child: _buildBottomBar()),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Attendance',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: Appcolors.darkColor,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Appcolors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  size: 14,
                  color: Appcolors.primaryColor,
                ),

                const SizedBox(width: 5),

                Text(
                  '$count Records',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Appcolors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E6E3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,

          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },

          textInputAction: TextInputAction.search,

          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Appcolors.darkColor,
          ),

          decoration: InputDecoration(
            hintText: 'Search site name...',

            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA29E)),

            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Appcolors.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Appcolors.primaryColor,
              ),
            ),

            suffixIcon: IconButton(
              onPressed: _closeSearch,
              icon: const Icon(Icons.close_rounded, color: Color(0xFF68716D)),
            ),

            border: InputBorder.none,

            contentPadding: const EdgeInsets.symmetric(vertical: 17),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT ATTENDANCE
  // ============================================================

  Widget _buildCurrentAttendance() {
    return Container(
      height: 148,
      padding: const EdgeInsets.all(8),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFE1E7E4)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          // =====================================================
          // TODAY
          // =====================================================
          Container(
            width: 64,
            height: double.infinity,

            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E1),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.today_rounded, color: Color(0xFFF3B51B), size: 23),

                SizedBox(height: 7),

                Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Appcolors.darkColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // CENTER
          // =====================================================
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _modernPunchBox(
                          title: 'IN',
                          time: '',
                          completed: false,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: _modernPunchBox(
                          title: 'OUT',
                          time: '',
                          completed: false,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: _modernCounterBox(
                        icon: Icons.photo_camera_rounded,
                        count: 2,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: _modernCounterBox(
                        icon: Icons.mic_rounded,
                        count: 1,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: _modernCounterBox(
                        icon: Icons.description_outlined,
                        count: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // SAVE
          // =====================================================
          _modernSaveButton(onTap: _openAddAttendance),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE LIST CARD
  // ============================================================

  Widget _buildAttendanceRow({required AttendanceRecord record}) {
    final bool hasOut = record.outTime.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openEditAttendance(record),

        borderRadius: BorderRadius.circular(20),

        child: Container(
          height: 148,

          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: const Color(0xFFE1E7E4)),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Row(
            children: [
              // =================================================
              // DATE
              // =================================================
              _modernDateBox(record.date),

              const SizedBox(width: 8),

              // =================================================
              // CENTER
              // =================================================
              Expanded(
                child: Column(
                  children: [
                    // =============================================
                    // SITE NAME
                    // =============================================
                    Container(
                      height: 30,

                      padding: const EdgeInsets.symmetric(horizontal: 9),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6F4),

                        borderRadius: BorderRadius.circular(9),
                      ),

                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.siteName.toUpperCase(),

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Appcolors.darkColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // =============================================
                    // IN / OUT
                    // =============================================
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _modernPunchBox(
                              title: 'IN',

                              time: _timeOnly(record.inTime),

                              completed: record.inTime.trim().isNotEmpty,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Expanded(
                            child: _modernPunchBox(
                              title: 'OUT',

                              time: _timeOnly(record.outTime),

                              completed: hasOut,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // =============================================
                    // ATTACHMENTS
                    // =============================================
                    Row(
                      children: [
                        Expanded(
                          child: _modernCounterBox(
                            icon: Icons.photo_camera_rounded,

                            count: record.hasPhoto ? 2 : 0,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: _modernCounterBox(
                            icon: Icons.mic_rounded,

                            count: record.hasRecording ? 1 : 0,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: _modernCounterBox(
                            icon: Icons.description_outlined,

                            count: record.note.trim().isNotEmpty ? 1 : 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =================================================
              // DETAIL ACTION / SAVE
              // =================================================
              hasOut
                  ? DetailAction(inTime: record.inTime, outTime: record.outTime)
                  : _modernSaveButton(
                      onTap: () {
                        _openEditAttendance(record);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE BOX
  // ============================================================

  Widget _modernDateBox(String date) {
    final parsed = _parseDate(date);

    String weekDay = '--';
    String day = '--';
    String month = '--';

    if (parsed != null) {
      const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];

      weekDay = weekdays[parsed.weekday - 1];

      day = parsed.day.toString().padLeft(2, '0');

      month = months[parsed.month - 1];
    }

    return Container(
      width: 64,
      height: double.infinity,

      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F2),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            weekDay,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: Color(0xFF7A827E),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            day,
            style: const TextStyle(
              fontSize: 29,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Appcolors.darkColor,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),

            decoration: BoxDecoration(
              color: Appcolors.primaryColor.withOpacity(0.10),

              borderRadius: BorderRadius.circular(10),
            ),

            child: Text(
              month,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Appcolors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IN / OUT BOX
  // ============================================================

  Widget _modernPunchBox({
    required String title,
    required String time,
    required bool completed,
  }) {
    final Color color = completed
        ? const Color(0xFF16A766)
        : const Color(0xFFF3B51B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),

      decoration: BoxDecoration(
        color: color.withOpacity(0.09),

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: color.withOpacity(0.20)),
      ),

      child: Row(
        children: [
          const SizedBox(width: 5),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),

                const SizedBox(height: 1),

                FittedBox(
                  fit: BoxFit.scaleDown,

                  alignment: Alignment.centerLeft,

                  child: Text(
                    time.isEmpty ? '--:--' : time,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Appcolors.darkColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUNTER
  // ============================================================

  Widget _modernCounterBox({required IconData icon, required int count}) {
    return Container(
      height: 29,

      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(icon, size: 14, color: const Color(0xFF68716D)),

          const SizedBox(width: 5),

          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Appcolors.darkColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _modernSaveButton({required VoidCallback onTap}) {
    return Material(
      color: Appcolors.primaryColor,

      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(14),

        child: const SizedBox(
          width: 62,
          height: double.infinity,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(Icons.edit_rounded, color: Colors.white, size: 20),

              SizedBox(height: 6),

              Text(
                'Save',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFFF6F8F7),

      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),

      child: Container(
        padding: const EdgeInsets.all(6),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: const Color(0xFFE1E6E3)),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            // ===================================================
            // SEARCH
            // ===================================================
            Expanded(
              child: Material(
                color: _showSearch
                    ? Appcolors.primaryColor.withOpacity(0.10)
                    : const Color(0xFFF5F7F6),

                borderRadius: BorderRadius.circular(14),

                child: InkWell(
                  onTap: _toggleSearch,

                  borderRadius: BorderRadius.circular(14),

                  child: SizedBox(
                    height: 50,

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          _showSearch
                              ? Icons.close_rounded
                              : Icons.search_rounded,

                          size: 22,

                          color: Appcolors.primaryColor,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          _showSearch ? 'Close' : 'Search Site Name',

                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Appcolors.darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ===================================================
            // ADD
            // ===================================================
            Material(
              color: Appcolors.primaryColor,

              borderRadius: BorderRadius.circular(14),

              child: InkWell(
                onTap: _openAddAttendance,

                borderRadius: BorderRadius.circular(14),

                child: const SizedBox(
                  width: 56,
                  height: 50,

                  child: Icon(Icons.add_rounded, size: 30, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY SEARCH
  // ============================================================

  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              color: Appcolors.primaryColor.withOpacity(0.08),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.search_off_rounded,
              size: 28,
              color: Appcolors.primaryColor,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'No site found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Appcolors.darkColor,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'No attendance found for "$_searchText"',
            style: const TextStyle(fontSize: 11, color: Color(0xFF818985)),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: _closeSearch,
            child: const Text(
              'Clear Search',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Appcolors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIME DISPLAY
  // ============================================================

  String _timeOnly(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    return value.trim().split(' ').first;
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(String value) {
    try {
      final parts = value.trim().split(' ');

      if (parts.length != 3) {
        return null;
      }

      const months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };

      final month = months[parts[1]];

      if (month == null) {
        return null;
      }

      return DateTime(int.parse(parts[2]), month, int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }
}
