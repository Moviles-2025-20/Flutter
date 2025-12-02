import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../util/analytics_service.dart';
import '../../../util/quizConstant.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';
import '../model/optionModel.dart';
import '../model/questionModel.dart';
import '../viewmodel/quizViewModel.dart';

class QuizScreen extends StatefulWidget {
  final bool forceRetake;
  const QuizScreen({
    super.key,
    this.forceRetake = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // PAGINADO: Este es el controlador que maneja las páginas (como un carrusel)
  // Permite movernos entre las 5 preguntas con animaciones suaves
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Verificamos si el usuario ya completó el quiz
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Si no hay usuario, cargamos el quiz
        if (mounted) {
          context.read<QuizViewModel>().loadQuiz();
        }
        return;
      }

      try {
        // Intentamos obtener el último resultado desde las capas de caché
        final lastResult = await QuizStorageManager.getLatestResult(user.uid);

        if (!widget.forceRetake && lastResult != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => QuizResultScreen(
                result: {
                  'categories': lastResult.resultCategories,
                  'type': lastResult.resultType,
                  'scores': lastResult.scores,
                },
                scores: lastResult.scores,
              ),
            ),
          );
        } else {
          if (mounted) {
            context.read<QuizViewModel>().loadQuiz();
          }
        }

      } catch (e) {
        // Si hay error al cargar, simplemente mostramos el quiz
        print('Error loading cached result: $e');
        if (mounted) {
          context.read<QuizViewModel>().loadQuiz();
        }
      }
    });
  }


@override
void dispose() {
  // Limpiamos el PageController cuando se cierra la pantalla para evitar memory leaks
  _pageController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFDFBF7),
    appBar: AppBar(
      title: const Text('Mood Quiz',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF6389E2),
    ),
    body: Consumer<QuizViewModel>(
      builder: (context, vm, _) {
        // ESTADO DE CARGA: Mostramos spinner mientras se cargan las preguntas de Firebase
        if (vm.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading questions...'),
              ],
            ),
          );
        }

        // VALIDACIÓN: Si no hay preguntas, mostramos mensaje de error
        if (vm.questions.isEmpty) {
          return const Center(
            child: Text('No available questions'),
          );
        }

        return Column(
          children: [
            // INDICADOR DE PROGRESO: Muestra "Pregunta 1 de 5" y barra de progreso
            _buildProgressIndicator(vm),

            // PAGINADO: Este es el corazón del sistema de paginado
            // PageView.builder crea una "página" por cada pregunta
            // Es como tener 5 pantallas que puedes deslizar horizontalmente
            Expanded(
              child: PageView.builder(
                controller: _pageController, // Conectamos el controlador
                physics: const NeverScrollableScrollPhysics(), // Deshabilitamos el swipe manual
                // Solo permitimos cambiar de página con los botones
                itemCount: vm.questions.length, // Cuántas páginas hay (5)
                itemBuilder: (context, index) {
                  // Para cada índice, construimos la página de esa pregunta
                  return _buildQuestionPage(vm, vm.questions[index]);
                },
              ),
            ),

            // BOTONES DE NAVEGACIÓN: Anterior y Siguiente
            _buildNavigationButtons(vm),
          ],
        );
      },
    ),
  );
}


// ============ INDICADOR DE PROGRESO ============
  Widget _buildProgressIndicator(QuizViewModel vm) {
    const primaryBlue = Color(0xFF6389E2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Texto: "Question 2 of 5"
              Text(
                'Question ${vm.currentIndex + 1} of ${vm.questions.length}',
                style: const TextStyle(
                  fontSize: 18, // ⬆ más grande
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Porcentaje
              Text(
                '${((vm.currentIndex + 1) / vm.questions.length * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16, // ⬆ más grande
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14), // ⬆ más aire

          // Barra de progreso MÁS ALTA
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 10, // ✅ ESTO la hace más gruesa
              value: (vm.currentIndex + 1) / vm.questions.length,
              backgroundColor: Colors.grey[200],
              valueColor:
              const AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

// ============ PÁGINA DE UNA PREGUNTA ============
Widget _buildQuestionPage(QuizViewModel vm, Question question) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la pregunta
        Text(
          question.text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // OPCIONES: Mapeamos cada opción a una tarjeta interactiva
        ...question.options.map((option) {
          // Verificamos si esta opción está seleccionada comparando con la respuesta guardada
          final isSelected = vm.currentAnswer?.text == option.text;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOptionCard(
              option: option,
              isSelected: isSelected,
              onTap: () {
                // Cuando el usuario toca una opción:
                vm.answerQuestion(option); // Guardamos su respuesta
              },
            ),
          );
        }),
      ],
    ),
  );
}

// ============ TARJETA DE OPCIÓN ============
Widget _buildOptionCard({
  required Option option,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Si está seleccionada, fondo azul claro, si no, blanco
        color: isSelected ? Color(0xFFEA9892).withOpacity(0.1) : Colors.white,
        border: Border.all(
          // Si está seleccionada, borde azul grueso, si no, gris delgado
          color: isSelected ? Color(0xFFEA9892) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Color(0xFFEA9892).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Círculo con check si está seleccionada
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Color(0xFFEA9892) : Colors.grey,
                width: 2,
              ),
              color: isSelected ? Color(0xFFEA9892) : Colors.transparent,
            ),
            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),

          // Texto de la opción
          Expanded(
            child: Text(
              option.text,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Color(0xFFEA9892) : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============ BOTONES DE NAVEGACIÓN ============
  Widget _buildNavigationButtons(QuizViewModel vm) {
    const primaryBlue = Color(0xFF6389E2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // -------- BOTÓN ANTERIOR --------
          if (!vm.isFirst)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  vm.previousQuestion();
                  _pageController.animateToPage(
                    vm.currentIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(
                  Icons.arrow_back,
                  size: 22,
                  color: primaryBlue,
                ),
                label: const Text(
                  'Last',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: primaryBlue, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          if (!vm.isFirst) const SizedBox(width: 12),

          // -------- BOTÓN SIGUIENTE / FINALIZAR --------
          Expanded(
            child: ElevatedButton.icon(
              onPressed: vm.currentAnswer == null
                  ? null
                  : () {
                if (vm.isLast) {
                  _showResults(vm);
                } else {
                  vm.nextQuestion();
                  _pageController.animateToPage(
                    vm.currentIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              icon: Icon(
                vm.isLast ? Icons.check_circle : Icons.arrow_forward,
                size: 22,
                color: Colors.white,
              ),
              label: Text(
                vm.isLast ? 'Finish' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: vm.currentAnswer == null
                    ? Colors.grey.shade300
                    : primaryBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: vm.currentAnswer == null ? 0 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


//  MOSTRAR RESULTADOS
Future<void> _showResults(QuizViewModel vm) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // PASO 1: Calculamos el resultado con el Isolate
    final result = await vm.calculateResult();

    AnalyticsService().logMoodQuizCompleted();
    final profileVM = context.read<ProfileViewModel>();
    // PASO 3: Guardamos en Firebase EN BACKGROUND
    vm.saveResult(
      userId: user.uid,
      result: result, profileVM: profileVM,
    ).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Results saved'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

    // Agregamos los scores al resultado para guardarlo completo
    final resultWithScores = {
      ...result,
      'scores': vm.scores,
    };

    if (!mounted) return;

    // PASO 2: Navegamos inmediatamente a la pantalla de resultados
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          result: resultWithScores,
          scores: vm.scores,
        ),
      ),
    );

    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠ Error saving: $error'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error calculating result: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}

// PANTALLA DE RESULTADOS
class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final Map<String, int> scores;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    final categories = List<String>.from(result['categories']);
    final resultType = result['type'].toString();
    final isMixed = categories.length > 1;

    return Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text('Your Result',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: const Color(0xFF6389E2),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ICONOS DINÁMICOS según categoría
            _buildCategoryIcons(categories),
            const SizedBox(height: 24),

            // Tipo de resultado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isMixed ? 'MIXED RESULT' : 'SINGLE RESULT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nombres de categorías
            ...categories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  QuizConstants.getCategoryName(cat),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: QuizConstants.categoryColors[cat],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // DESCRIPCIÓN según categoría
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF6389E2)),
              ),
              child: Text(
                isMixed
                    ? QuizConstants.getMixedDescription(categories)
                    : QuizConstants.categoryDescriptions[categories.first] ?? '',
                textAlign: TextAlign.center,

                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),

            const SizedBox(height: 32),

            // Scores
            const Text(
              'Your Scores',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...scores.entries.map((entry) {
              final label = QuizConstants.getCategoryName(entry.key);
              final score = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              QuizConstants.categoryIcons[entry.key],
                              size: 18,
                              color: QuizConstants.categoryColors[entry.key],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$score pts',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: score / 25,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        QuizConstants.categoryColors[entry.key] ??
                            Colors.blue,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 40),

            // BOTONES: Retake y Done
            // BOTONES: Retake y Done
            Row(
              children: [
                // 🔁 BOTÓN RETAKE
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      debugPrint('Offline desde la view');
                      await QuizStorageManager.clearAll(user.uid);

                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => QuizViewModel(),
                            child: const QuizScreen(forceRetake: true),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake Quiz'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFF6389E2),
                        width: 2,
                      ),
                      foregroundColor: const Color(0xFF6389E2),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ✅ BOTÓN DONE
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6389E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 3,
                      shadowColor: const Color(0xFF6389E2).withOpacity(0.35),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar iconos de categorías
  Widget _buildCategoryIcons(List<String> categories) {
    if (categories.length == 1) {
      // Una sola categoría - icono grande
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: QuizConstants.categoryColors[categories.first]?.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          QuizConstants.categoryIcons[categories.first],
          size: 80,
          color: QuizConstants.categoryColors[categories.first],
        ),
      );
    } else {
      // Múltiples categorías - iconos lado a lado
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QuizConstants.categoryColors[cat]?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                QuizConstants.categoryIcons[cat],
                size: 60,
                color: QuizConstants.categoryColors[cat],
              ),
            ),
          );
        }).toList(),
      );
    }
  }
}
