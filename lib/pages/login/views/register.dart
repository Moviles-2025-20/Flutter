import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  final String uid;
  const RegisterView({super.key, required this.uid});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final List<String> categories = [
    "Música",
    "Deportes",
    "Tecnología",
    "Cine",
    "Lectura",
    "Viajes",
    "Comida"
  ];

  final List<String> days = [
    "Lunes",
    "Martes",
    "Miércoles",
    "Jueves",
    "Viernes",
    "Sábado",
    "Domingo",
  ];

  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RegisterViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Nombre
              TextFormField(
                decoration: const InputDecoration(labelText: "Nombre"),
                onChanged: (v) => viewModel.name = v,
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),

              /// Ciudad
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                onChanged: (v) => viewModel.email = v,
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),

              /// major
              TextFormField(
                decoration: const InputDecoration(labelText: "Major"),
                onChanged: (v) => viewModel.major = v,
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),

              /// Género
              DropdownButtonFormField<String>(
                value: viewModel.gender,
                items: ["Masculino", "Femenino", "Otro"]
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => viewModel.gender = v,
                decoration: const InputDecoration(labelText: "Género"),
                validator: (v) => v == null ? "Campo obligatorio" : null,
              ),

              /// Fecha de nacimiento
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      viewModel.birthDate = picked;
                    });
                  }
                },
                child: Text(viewModel.birthDate == null
                    ? "Seleccionar fecha de nacimiento"
                    : viewModel.birthDate.toString().split(" ")[0]),
              ),

              const SizedBox(height: 20),

              /// Categorías favoritas
              const Text("Categorías favoritas",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...categories.map((cat) {
                final selected = viewModel.favoriteCategories.contains(cat);
                return CheckboxListTile(
                  title: Text(cat),
                  value: selected,
                  onChanged: (_) {
                    setState(() {
                      viewModel.toggleCategory(cat);
                    });
                  },
                );
              }),

              const Divider(height: 40),

              /// Horarios disponibles
              const Text("Horarios disponibles",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Día disponible",
                  border: OutlineInputBorder(),
                ),
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
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _startTime = time);
                      },
                      child: Text(_startTime == null
                          ? "Hora inicio"
                          : "Inicio: ${_startTime!.format(context)}"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _endTime = time);
                      },
                      child: Text(_endTime == null
                          ? "Hora fin"
                          : "Fin: ${_endTime!.format(context)}"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedDay != null &&
                      _startTime != null &&
                      _endTime != null) {
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
                          content: Text("Selecciona día, hora inicio y hora fin")),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Agregar horario"),
              ),

              const SizedBox(height: 16),

              if (viewModel.freeTimeSlots.isNotEmpty) ...[
                const Text("Horarios agregados:"),
                ...viewModel.freeTimeSlots.asMap().entries.map((entry) {
                  final i = entry.key;
                  final slot = entry.value;
                  return ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text("${slot['day']} - ${slot['start']} a ${slot['end']}"),
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

              /// Botón Guardar
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await viewModel.saveUserData(widget.uid);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Datos guardados exitosamente")),
                      );
                      Navigator.pushReplacementNamed(context, '/home');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


