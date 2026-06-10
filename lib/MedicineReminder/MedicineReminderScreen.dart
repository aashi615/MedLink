import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicineReminderScreen extends StatefulWidget {
  @override
  State<MedicineReminderScreen> createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends State<MedicineReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  @override
  void initState() {
    _initFCMToken();
    super.initState();
  }

  void _initFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('user_details')
          .doc('FCMToken')
          .set({'token': token}, SetOptions(merge: true));
      print("stored succesffully");
    }
  }



  static const String oneTime = "one-time";
  static const String recurring = "recurring";
  String _reminderType = oneTime;
  int? _selectedWeekday;

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      suffixIcon: icon != null ? Icon(icon, color: const Color(0xFF0B0B45)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildReminderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reminder Type",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0B0B45)),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text("One-Time"),
                value: oneTime,
                groupValue: _reminderType,
                onChanged: (value) => setState(() => _reminderType = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Recurring"),
                value: recurring,
                groupValue: _reminderType,
                onChanged: (value) => setState(() => _reminderType = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return _reminderType == recurring
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text("Select Day of Week", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0B0B45))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            return ChoiceChip(
              label: Text(days[index]),
              selected: _selectedWeekday == index,
              onSelected: (_) => setState(() => _selectedWeekday = index),
            );
          }),
        ),
      ],
    )
        : const SizedBox();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        backgroundColor: const Color(0xFF0B0B45),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildReminderTypeSelector(),
              const SizedBox(height: 20),
              const Text(
                "Reminder Title",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0B0B45)),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g., Take Vitamin D'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              if (_reminderType == oneTime) ...[
                const Text(
                  "Select Date",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0B0B45)),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: _inputDecoration('Choose a date', icon: Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      });
                    }
                  },
                  validator: (value) =>
                  _reminderType == oneTime && (value == null || value.isEmpty) ? 'Please select a date' : null,
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                "Select Time",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0B0B45)),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _timeController,
                readOnly: true,
                decoration: _inputDecoration('Choose a time', icon: Icons.access_time),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedTime ?? TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedTime = pickedTime;
                      _timeController.text = pickedTime.format(context);
                    });
                  }
                },
                validator: (value) => value == null || value.isEmpty ? 'Please select a time' : null,
              ),
              _buildWeekdaySelector(),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true) return;

                  final title = _titleController.text.trim();
                  final time = _timeController.text.trim();

                  if (title.isEmpty || time.isEmpty || selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in')),
                      );
                      return;
                    }

                    final reminderRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('MediReminders')
                        .doc();

                    final reminderData = {
                      'title': title,
                      'time': '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                      'type': _reminderType == oneTime ? 'one-time' : 'recurring',
                    };

                    if (_reminderType == oneTime) {
                      reminderData.addAll({
                        'date': _dateController.text.trim(),
                        'isSent': 'false',  // Store "false" as a string if isSent must be a string
                      });
                    } else {
                      if (_selectedWeekday == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a day of the week')),
                        );
                        return;
                      }
                      reminderData['dayOfWeek'] = _selectedWeekday.toString(); // Convert int to string
                    }

                    await reminderRef.set(reminderData);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reminder "$title" set successfully')),
                      );
                      setState(() {
                        _titleController.clear();
                        _dateController.clear();
                        _timeController.clear();
                        selectedDate = null;
                        selectedTime = null;
                        _selectedWeekday = null;
                        _reminderType = oneTime;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to set reminder')),
                      );
                    }
                  }
                },
                child: const Text("Set Reminder", style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
