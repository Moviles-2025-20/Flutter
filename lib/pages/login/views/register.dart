import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  final String uid;
  const RegisterView({super.key, required this.uid});


  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  // Controllers para campos que pueden venir de Auth
  late TextEditingController _nameController;
  late TextEditingController _emailController;



  final List<String> categories = [
    "Music",
    "Sports",
    "Academic",
    "Technology",
    "Movies",
    "Literature",
    "Know the world",
    "Food",
    "Art",
    "Gaming",
    "Science",
    "Outdoor"
  ];

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  User? firebaseUser;
  int _indoorOutdoorScore = 50;


  @override
  void initState() {
    super.initState();
    firebaseUser = FirebaseAuth.instance.currentUser;

    _nameController = TextEditingController(text: firebaseUser?.displayName ?? '');
    _emailController = TextEditingController(text: firebaseUser?.email ?? '');

    // Inicializar el ViewModel
    final viewModel = Provider.of<RegisterViewModel>(context, listen: false);
    viewModel.name = firebaseUser?.displayName ?? '';
    viewModel.email = firebaseUser?.email ?? '';
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RegisterViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3b5998), // Azul estilo Facebook
        title: const Text("Register", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFFFF8E1),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Name"),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (v) => viewModel.name = v,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Name is required";
                  }

                  // Bloquear emojis
                  final emojiRegex = RegExp(
                      r'[\u{1F600}-\u{1F64F}'
                      r'\u{1F300}-\u{1F5FF}'
                      r'\u{1F680}-\u{1F6FF}'
                      r'\u{2600}-\u{26FF}'
                      r'\u{2700}-\u{27BF}]',
                      unicode: true);

                  if (emojiRegex.hasMatch(v)) {
                    return "Name must not contain an emoji";
                  }

                  if (v.trim().split(" ").every((word) => word.isEmpty)) {
                    return "Name cannot be only spaces";
                  }

                  return null;
                },
              ),


              const SizedBox(height: 12),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration("Email"),
                onChanged: (v) => viewModel.email = v,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email is required";
                  }

                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return "Enter a valid email address";
                  }
                  return null;
                },

              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: _inputDecoration("Major"),
                onChanged: (v) => viewModel.major = v,
                validator: (v) => v!.isEmpty ? "Mandatory field" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: viewModel.gender,
                items: ["Male", "Female", "Other"]
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => viewModel.gender = v,
                decoration: _inputDecoration("Gender"),
                validator: (v) => v == null ? "Mandatory field" : null,
              ),

              const SizedBox(height: 16),

              /// Fecha de nacimiento
              ElevatedButton(
                style: _blueButtonStyle(),
                onPressed: () async {
                  final now = DateTime.now();
                  final maxDate = DateTime(now.year - 10, now.month, now.day); // edad mínima 10
                  final minDate = DateTime(now.year - 120, now.month, now.day); // edad máxima 120

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(now.year - 20),
                    firstDate: minDate,
                    lastDate: maxDate,
                  );
                  if (picked != null) {
                    setState(() {
                      viewModel.birthDate = picked;
                    });
                  }
                },
                child: Text(viewModel.birthDate == null
                    ? "Choose Birth Date"
                    : viewModel.birthDate.toString().split(" ")[0]),
              ),

              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Do you usually prefer indoor or outdoor activities?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _indoorOutdoorScore.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: _indoorOutdoorScore <= 50 ? "Indoor" : "Outdoor",
                    onChanged: (val) {
                      setState(() {
                        _indoorOutdoorScore = val.toInt();
                      });
                      viewModel.indoorOutdoorScore = _indoorOutdoorScore;
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Indoor"),
                      Text("Outdoor"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              /// Likes como chips naranjas
              const Text("Preferences",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final selected =
                  viewModel.favoriteCategories.contains(cat);
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: Colors.orange,
                    onSelected: (_) {
                      setState(() {
                        viewModel.toggleCategory(cat);
                      });
                    },
                  );
                }).toList(),
              ),

              const Divider(height: 40),

              /// Free time slots
              const Text("Free time slots",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                decoration: _inputDecoration("Free day"),
                value: _selectedDay,
                items: days
                    .map((day) =>
                    DropdownMenuItem(value: day, child: Text(day)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDay = v),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: _blueButtonStyle(),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _startTime = time);
                      },
                      child: Text(_startTime == null
                          ? "Start"
                          : "Start: ${_startTime!.format(context)}"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: _blueButtonStyle(),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _endTime = time);
                      },
                      child: Text(_endTime == null
                          ? "End"
                          : "End: ${_endTime!.format(context)}"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                style: _blueButtonStyle(),
                onPressed: () {
                  if (_selectedDay != null &&
                      _startTime != null &&
                      _endTime != null) {

                    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
                    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

                    if (endMinutes - startMinutes < 30) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("The end time must be at least 30 minutes after the start")),
                      );
                      return;
                    }
                    viewModel.freeTimeSlots.add({
                      "day": _selectedDay!,
                      "start": _startTime!.format(context),
                      "end": _endTime!.format(context),
                    });
                    setState(() {
                      _startTime = null;
                      _endTime = null;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text("Select day, start time, and end time")),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Add free time slot"),
              ),

              if (viewModel.freeTimeSlots.isNotEmpty) ...[
                const Text("Added Free Time Slots:"),
                ...viewModel.freeTimeSlots.asMap().entries.map((entry) {
                  final i = entry.key;
                  final slot = entry.value;
                  return ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text("${slot['day']} - ${slot['start']} to ${slot['end']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          viewModel.freeTimeSlots.removeAt(i);
                        });
                      },
                    ),
                  );
                }),
              ],


              const SizedBox(height: 30),

              /// Botones estilo perfil
              ElevatedButton(
                style: _pinkButtonStyle(),
                onPressed: () async {
                  //  Ejecuta todas las validaciones del formulario
                  if (!_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fix the highlighted errors before saving."),
                      ),
                    );
                    return;
                  }

                  try {
                    await viewModel.saveUserData(widget.uid);
                    if (!mounted) return;

                    context.read<AuthViewModel>().markUserAsNotFirstTime();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Data saved successfully"),
                      ),
                    );

                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      ModalRoute.withName('/start/login'),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                      ),
                    );
                  }
                },
                child: const Text("Save"),
              ),

            ],
          ),
        ),
      ),
    );
  }

  /// Estilos personalizados
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _blueButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3b5998),
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
  ButtonStyle _pinkButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFED6275), // Rosado
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }


}