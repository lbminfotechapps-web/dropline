import 'package:flutter/material.dart';

class MyCheckSheetsPage extends StatelessWidget {
  const MyCheckSheetsPage({
    super.key,
    required this.projectName,
    required this.companyName,
  });

  final String projectName;
  final String companyName;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF102633),
    appBar: AppBar(
      title: const Text('My check sheets'),
      backgroundColor: const Color(0xFF102633),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$projectName · $companyName',
              style: const TextStyle(color: Color(0xFF9FBFD1), fontSize: 13),
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 40,
                      color: Color(0xFF9FBFD1),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No check sheets assigned',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
