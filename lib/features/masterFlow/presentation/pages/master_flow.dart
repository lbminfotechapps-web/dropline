import 'package:dropline/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const bgColor = Color(0xFF09283A);
const cardColor = Color(0xFF0D3046);
const borderColor = Color(0xFF28516B);
const mutedColor = Color(0xFF93B5CC);
const accentColor = Color(0xFFB5FF76);

class MasterFlowsScreen extends StatefulWidget {
  const MasterFlowsScreen({super.key});

  @override
  State<MasterFlowsScreen> createState() => _MasterFlowsScreenState();
}

class _MasterFlowsScreenState extends State<MasterFlowsScreen> {
  final List<String> flows = [];

  Future<void> _createFlow() async {
    final name = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CreateMasterFlowScreen()),
    );

    if (!mounted || name == null) return;

    setState(() => flows.add(name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Master flows',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laxmi Gauri · Apex Build',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (flows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'No master flows yet.',
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ),
              ...flows.map(
                (flow) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _outlinedCard(
                    child: Text(
                      flow,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _outlinedCard(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master flow',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Activities in order, with references and companies.',
                      style: TextStyle(color: mutedColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _primaryButton('+ New master flow', _createFlow),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityControllers {
  final name = TextEditingController();
  final reference = TextEditingController();
  String? company;

  void dispose() {
    name.dispose();
    reference.dispose();
  }
}

class CreateMasterFlowScreen extends StatefulWidget {
  const CreateMasterFlowScreen({super.key});

  @override
  State<CreateMasterFlowScreen> createState() => _CreateMasterFlowScreenState();
}

class _CreateMasterFlowScreenState extends State<CreateMasterFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _flowName = TextEditingController();

  final List<ActivityControllers> activities = [ActivityControllers()];

  final companies = ['Apex Build', 'ABC Contractors', 'XYZ Enterprises'];

  void _addActivity() {
    setState(() => activities.add(ActivityControllers()));
  }

  void _removeActivity(int index) {
    if (activities.length == 1) return;
    final item = activities.removeAt(index);
    setState(() {});
    item.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    final name = _flowName.text.trim();

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => ChooseAreasScreen(flowName: name)),
    // );
    context.push(
      AppRouter.areas,
      // Uri(
      //   path: AppRouter.areas,
      //   queryParameters: {'projectName': widget.projectName},
      // ).toString(),
      // extra: result,
    );
  }

  @override
  void dispose() {
    _flowName.dispose();
    for (final item in activities) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Master flow',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 10, 16, 20),
                  children: [
                    const Text(
                      'Laxmi Gauri · Draft',
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Flow name',
                      style: TextStyle(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _input(
                      controller: _flowName,
                      hint: 'Apartment finishes',
                      requiredField: true,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(
                      activities.length,
                      (index) => _activityCard(index),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _addActivity,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        side: const BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '+ Add activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 16, 8),
                child: _primaryButton('Next: choose areas', _next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityCard(int index) {
    final activity = activities[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: mutedColor),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: mutedColor, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Activity',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Reference',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (activities.length > 1) const SizedBox(width: 28),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _input(
                        controller: activity.name,
                        hint: 'Activity name',
                        requiredField: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _input(
                        controller: activity.reference,
                        hint: 'Ref.',
                      ),
                    ),
                    if (activities.length > 1)
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 6),
                        icon: const Icon(
                          Icons.close,
                          color: mutedColor,
                          size: 18,
                        ),
                        onPressed: () => _removeActivity(index),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  initialValue: activity.company,
                  dropdownColor: cardColor,
                  hint: const Text(
                    'Select company',
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                  iconEnabledColor: mutedColor,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _decoration('Select company'),
                  items: companies
                      .map(
                        (company) => DropdownMenuItem(
                          value: company,
                          child: Text(company),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => activity.company = value);
                  },
                  validator: (value) => value == null ? 'Select company' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// class ChooseAreasScreen extends StatelessWidget {
//   final String flowName;

//   const ChooseAreasScreen({super.key, required this.flowName});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         title: const Text('Choose areas'),
//         backgroundColor: bgColor,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Text(
//           'Choose areas for $flowName',
//           style: const TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }
// }

InputDecoration _decoration(String hint) {
  return InputDecoration(
    hintText: hint,
    labelStyle: TextStyle(color: Colors.white),
    hintStyle: const TextStyle(color: mutedColor, fontSize: 12),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: accentColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}

Widget _input({
  required TextEditingController controller,
  required String hint,
  bool requiredField = false,
}) {
  return TextFormField(
    controller: controller,
    style: const TextStyle(color: Colors.white, fontSize: 12),
    decoration: _decoration(hint),
    validator: requiredField
        ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
        : null,
  );
}

Widget _outlinedCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: cardColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

Widget _primaryButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    ),
  );
}
