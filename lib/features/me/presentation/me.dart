import 'package:flutter/material.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/features/companies/presentation/start_work.dart';
import 'package:dropline/features/project_setup/presentation/pages/project_setup_pages.dart';
import 'package:dropline/features/newproject/presentation/new_project.dart';

/// The site overview, with proportions taken from the supplied screen reference.
class MePage extends StatefulWidget {
  const MePage({super.key, this.onStartWork});

  final VoidCallback? onStartWork;

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _lime = Color(0xFFB5FF65);
  String _category = 'All';
  String _query = '';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / 210;
            Text text(
              String value,
              double size, {
              Color? color,
              bool bold = false,
            }) => Text(
              value,
              style: TextStyle(
                fontSize: size * s,
                color: color ?? const Color(0xFFF0F4FC),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: .15 * s,
              ),
            );
            Widget panel({required Widget child, double? height}) => Container(
              height: height == null ? null : height * s,
              padding: EdgeInsets.symmetric(horizontal: 7 * s),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(6 * s),
              ),
              child: child,
            );
            Widget shortcut(IconData icon, String title, String subtitle) =>
                Expanded(
                  child: panel(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(icon, size: 14 * s, color: _muted),
                        SizedBox(width: 6 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              text(title, 7.5, bold: true),
                              SizedBox(height: 4 * s),
                              text(subtitle, 5.6, color: _muted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
            final showProject =
                _category != 'Personal' &&
                'Laxmi Gauri'.toLowerCase().contains(_query.toLowerCase());
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 10 * s, 10 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      text('Dropline · Site', 13, bold: true),
                      Column(
                        children: [
                          Container(
                            width: 22 * s,
                            height: 22 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _muted),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: _muted,
                              size: 15 * s,
                            ),
                          ),
                          SizedBox(height: 2 * s),
                          text('ME', 5, color: _muted),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * s),
                  text('Hello, Rahul', 15, bold: true),
                  SizedBox(height: 7 * s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 80 * s,
                        height: 20 * s,
                        child: panel(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _language,
                              isExpanded: true,
                              dropdownColor: _surface,
                              icon: Icon(
                                Icons.expand_more,
                                size: 10 * s,
                                color: _muted,
                              ),
                              items: ['English', 'Hindi']
                                  .map(
                                    (language) => DropdownMenuItem(
                                      value: language,
                                      child: text(language, 6),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _language = value!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * s),
                  panel(
                    height: 37,
                    child: Row(
                      children: [
                        Container(
                          width: 25 * s,
                          height: 25 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _muted),
                          ),
                          child: Icon(
                            Icons.work_outline,
                            size: 15 * s,
                            color: _muted,
                          ),
                        ),
                        SizedBox(width: 8 * s),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text('My work, My Money', 8.8, bold: true),
                            SizedBox(height: 3 * s),
                            text(
                              'Shifts, rates & payments',
                              6.5,
                              color: _muted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 7 * s),
                  Row(
                    children: [
                      shortcut(Icons.person_outline, 'My card', 'View & share'),
                      SizedBox(width: 6 * s),
                      shortcut(
                        Icons.article_outlined,
                        'My certificates',
                        'View & manage',
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * s),
                  Row(
                    children: [
                      shortcut(
                        Icons.article_outlined,
                        'My reports',
                        'Photos, notes & audio',
                      ),
                      SizedBox(width: 6 * s),
                      shortcut(
                        Icons.account_tree_outlined,
                        'Handovers',
                        'View handovers',
                      ),
                    ],
                  ),
                  SizedBox(height: 14 * s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      text('My projects', 13, bold: true),
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<Map<String, Object?>>(
                            builder: (_) => const NewProjectPage(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(6 * s),
                        child: Container(
                          width: 43 * s,
                          height: 19 * s,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _lime,
                            borderRadius: BorderRadius.circular(6 * s),
                          ),
                          child: text(
                            '+ New',
                            6.5,
                            color: _background,
                            bold: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 7 * s),
                  SizedBox(
                    height: 23 * s,
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: TextStyle(fontSize: 7 * s, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search projects',
                        hintStyle: TextStyle(fontSize: 6.5 * s, color: _muted),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8 * s),
                        filled: true,
                        fillColor: _background,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6 * s),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6 * s),
                          borderSide: const BorderSide(color: _muted),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  Row(
                    children: ['All', 'Business', 'Personal']
                        .map(
                          (category) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: category == 'Personal' ? 0 : 4 * s,
                              ),
                              child: SizedBox(
                                height: 20 * s,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: _category == category
                                        ? _lime
                                        : _surface,
                                    side: BorderSide(
                                      color: _category == category
                                          ? _lime
                                          : _border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        6 * s,
                                      ),
                                    ),
                                  ),
                                  onPressed: () =>
                                      setState(() => _category = category),
                                  child: text(
                                    category,
                                    6.5,
                                    color: _category == category
                                        ? _background
                                        : _muted,
                                    bold: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 10 * s),
                  if (showProject)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push(AppRouter.projectSetup),
                      child: panel(
                        height: 42,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  text('Laxmi Gauri', 10, bold: true),
                                  SizedBox(height: 5 * s),
                                  text('PlasterCo · Admin', 5.8, color: _muted),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * s,
                                vertical: 2 * s,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(9 * s),
                              ),
                              child: text('Business', 5, color: _muted),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 13 * s,
                              color: _muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!showProject)
                    SizedBox(
                      height: 42 * s,
                      child: Center(
                        child: text('No projects found', 7, color: _muted),
                      ),
                    ),
                  SizedBox(height: 15 * s),
                  SizedBox(
                    height: 27 * s,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: _background,
                        disabledBackgroundColor: _lime,
                        disabledForegroundColor: _background,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7 * s),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              StartWorkPage(onStartWork: widget.onStartWork),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 11 * s),
                          SizedBox(width: 4 * s),
                          Text(
                            'Start work',
                            style: TextStyle(
                              fontSize: 7 * s,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // SizedBox(height: 3 * s),
                  // Center(child: text('Laxmi Gauri', 5, color: _muted)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
