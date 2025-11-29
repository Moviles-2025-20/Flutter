import 'package:app_flutter/pages/login/viewmodels/auth_viewmodel.dart';
import 'package:app_flutter/pages/profile/viewmodels/profile_viewmodel.dart';
import 'package:app_flutter/pages/wishMeLuck/view/wish_me_luck_stats_view.dart';
import 'package:app_flutter/pages/login/views/login.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_flutter/util/quizConstant.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadUserData();
    });
  }

  // ---------------------- Selección de foto ----------------------
  Future<void> _pickImage(ProfileViewModel viewModel) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Select from gallery"),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) await viewModel.updatePhotoInstantly(image.path);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a photo"),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) await viewModel.updatePhotoInstantly(image.path);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Editar perfil ----------------------
  void _showEditProfileDialog(BuildContext context, ProfileViewModel viewModel) {
    final nameController = TextEditingController(text: viewModel.currentUser?.profile.name);
    final majorController = TextEditingController(text: viewModel.currentUser?.profile.major ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: majorController,
              decoration: const InputDecoration(labelText: "Major", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final major = majorController.text;

              try {
                if (name.isNotEmpty) {
                  await viewModel.updateName(name);
                  await viewModel.updateMajor(major);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile updated successfully")),
                  );
                }
              } catch (e) {
                //  Captura la excepción lanzada con throw StateError
                if (context.mounted) {
                  Navigator.pop(context); // Cierra el diálogo incluso si hay error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        viewModel.error ?? "Error updating profile",
                        style: const TextStyle(color: Colors.white),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------------- Agregar categorías ----------------------
  void _showAddCategoryDialog(BuildContext context, ProfileViewModel viewModel) {
    final availableCategories = [
      "Sports",
      "Music",
      "Art",
      "Literature",
      "Gaming",
      "Science",
      "Technology",
      "Outdoor",
      "Know the world",
      "Movies",
      "Food",
      "Academic"
    ];

    showDialog(
      context: context,
      builder: (context) {
        List<String> selected = [];

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Add Favorite Categories"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: availableCategories.map((category) {
                  if (viewModel.currentUser!.preferences.favoriteCategories.contains(category)) {
                    return const SizedBox.shrink();
                  }
                  return CheckboxListTile(
                    title: Text(category),
                    value: selected.contains(category),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selected.add(category);
                        } else {
                          selected.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  try {
                    for (var category in selected) {
                      await viewModel.addFavoriteCategory(category);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Categories added successfully")),
                      );
                    }

                  } on StateError catch (e) {
                    //  Captura el error lanzado en el ViewModel (sin conexión, etc.)
                    if (context.mounted) {
                      Navigator.pop(context); // Cierra el diálogo
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }

                  } catch (e) {
                    // Cualquier otro error inesperado
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error adding categories")),
                      );
                    }
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------- Eliminar cuenta ----------------------
  void _showDeleteAccountDialog(
      BuildContext context,
      ProfileViewModel profileViewModel,
      AuthViewModel authViewModel,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final success = await profileViewModel.deleteAccount();
                if (success && context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                    '/', // Ruta principal (main.dart)
                        (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                    '/', // Fallback por si ocurre error
                        (route) => false,
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------- Build ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6389E2),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: Consumer2<ProfileViewModel, AuthViewModel>(
        builder: (context, profileViewModel, authViewModel, child) {
          if (!authViewModel.isLoading && authViewModel.user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushNamedAndRemoveUntil('/start', (route) => false);
            });
          }

          if (profileViewModel.isLoading && profileViewModel.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileViewModel.currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(profileViewModel.error ?? "Profile loading unsuccessful", textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => profileViewModel.loadUserData(), child: const Text("Try again")),
                ],
              ),
            );
          }

          final user = profileViewModel.currentUser!;
          final profile = user.profile;
          final preferences = user.preferences;

          // indoor/outdoor calc
          final int indoorScore = (preferences.indoorOutdoorScore ?? 50).clamp(0, 100);
          final double value = indoorScore / 100.0;

          const Color leftColor = Color(0xFF6F8DCD);
          const Color rightColor = Color(0xFFEA9892);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------- Header con foto ----------------------
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:getProfileImage(profile.photo),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _pickImage(profileViewModel),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF3C5BA9),
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (profile.major != null && profile.major!.isNotEmpty) Text("Major - ${profile.major}"),
                          Text("Age - ${profile.age}"),
                          if (profile.gender != null && profile.gender!.isNotEmpty) Text("Gender - ${profile.gender}"),
                          Text("Personality - ${profileViewModel.getPersonalityType()}"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ---------------------- Preferencias ----------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("My preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => _showAddCategoryDialog(context, profileViewModel),
                      child: const Chip(
                        label: Text("Browse More"),
                        backgroundColor: Colors.grey,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (preferences.favoriteCategories.isEmpty)
                  const Text("No likes", style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: preferences.favoriteCategories.map((category) {
                      return Chip(
                        label: Text(category, style: const TextStyle(color: Colors.white)),
                        backgroundColor: const Color(0xFFE3944F),
                        deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                        onDeleted: () => _showDeleteCategoryDialog(context, profileViewModel, category),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 30),

                // ---------------------- Indoor vs Outdoor ----------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Indoor vs Outdoor",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$indoorScore%",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text("Indoor", style: TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: value,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [leftColor, rightColor],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment(value * 2 - 1, 0),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    value < 0.5 ? Icons.home_outlined : Icons.park,
                                    size: 16,
                                    color: value < 0.5 ? leftColor : rightColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text("Outdoor", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value < 0.4
                      ? "You tend to prefer indoor activities"
                      : value > 0.6
                      ? "You tend to prefer outdoor activities"
                      : "You like a mix of indoor and outdoor activities",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 30),

                const ProfileQuizCategory(),

                const SizedBox(height: 30),

                // ---------------------- Botones ----------------------
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6389E2), minimumSize: const Size(double.infinity, 40)),
                  onPressed: () => _showEditProfileDialog(context, profileViewModel),
                  child: const Text("Change your profile information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFED6275), minimumSize: const Size(double.infinity, 40)),
                  onPressed: authViewModel.isLoading
                      ? null
                      : () async {
                    final connectivity = await Connectivity().checkConnectivity();
                    if (connectivity == ConnectivityResult.none) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("This action cannot be performed because there is no internet."),
                          ),
                        );
                      }
                      return;
                    }

                    await authViewModel.logout(context);

                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                      '/start/login',
                          (route) => false,
                    );


                  },

                  child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA9892), minimumSize: const Size(double.infinity, 40)),
                  onPressed: () async {
                    final connectivity = await Connectivity().checkConnectivity();
                    if (connectivity == ConnectivityResult.none) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("This action cannot be performed because there is no internet."),
                          ),
                        );
                      }
                      return;
                    }

                    _showDeleteAccountDialog(context, profileViewModel, authViewModel);
                  },
                  child: const Text(
                    "Delete your account",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, ProfileViewModel viewModel, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Category"),
        content: Text("Do you want to remove '$category' from your favorites?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await viewModel.removeFavoriteCategory(category);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'$category' removed successfully")),
                  );
                }

              } on StateError catch (e) {
                // Maneja el error lanzado en el ViewModel (por ejemplo: sin conexión)
                if (context.mounted) {
                  Navigator.pop(context); // Cierra el diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }

              } catch (e) {
                // Otros errores no controlados
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error removing category")),
                  );
                }
              }
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  ImageProvider getProfileImage(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return const AssetImage("assets/images/profileimg.png");
    } else if (photoPath.startsWith('http')) {
      return NetworkImage(photoPath);
    } else {
      return FileImage(File(photoPath));
    }
  }
}

class ProfileQuizCategory extends StatelessWidget {
  const ProfileQuizCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        final categories = vm.quizCategories;
        if (categories.isEmpty) return const SizedBox.shrink();

        final isMixed = categories.length > 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12), // ⬇ antes 14
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(categories, isMixed),
            ),
            borderRadius: BorderRadius.circular(14), // ⬇ antes 16
            boxShadow: [
              BoxShadow(
                color: _getPrimaryColor(categories).withOpacity(0.22),
                blurRadius: 8, // ⬇ antes 10
                offset: const Offset(0, 4), // ⬇ antes (0,5)
              ),
            ],
          ),
          child: Column(
            children: [
              _buildIconsSection(categories, isMixed),
              const SizedBox(height: 8), // ⬇ antes 10

              Text(
                'Mood Quiz Result',
                style: TextStyle(
                  fontSize: 10.5, // ⬇ antes 11
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  letterSpacing: 1.05,
                ),
              ),
              const SizedBox(height: 5),

              Text(
                isMixed
                    ? categories
                    .map((c) => QuizConstants.getCategoryName(c))
                    .join(' & ')
                    : QuizConstants.getCategoryName(categories.first),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, // ⬇ antes 18
                  fontWeight: FontWeight.bold,
                  color: _getPrimaryColor(categories),
                ),
              ),

              if (isMixed) ...[
                const SizedBox(height: 5),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'Mixed Personality',
                    style: TextStyle(
                      fontSize: 9.5, // ⬇ antes 10
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------- ICONOS ----------
  Widget _buildIconsSection(List<String> categories, bool isMixed) {
    if (!isMixed) {
      return Container(
        padding: const EdgeInsets.all(12), // ⬇ antes 14
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(
          QuizConstants.categoryIcons[categories.first],
          size: 36, // ⬇ antes 42
          color: QuizConstants.categoryColors[categories.first],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: categories.take(2).map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              padding: const EdgeInsets.all(10), // ⬇ antes 12
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                QuizConstants.categoryIcons[cat],
                size: 26, // ⬇ antes 30
                color: QuizConstants.categoryColors[cat],
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  // ---------- COLORES ----------
  List<Color> _getGradientColors(List<String> categories, bool isMixed) {
    if (!isMixed) {
      final baseColor = QuizConstants.categoryColors[categories.first]!;
      return [
        baseColor.withOpacity(0.2),
        baseColor.withOpacity(0.05),
      ];
    }
    return [
      QuizConstants.categoryColors[categories[0]]!.withOpacity(0.15),
      QuizConstants.categoryColors[categories[1]]!.withOpacity(0.15),
    ];
  }

  Color _getPrimaryColor(List<String> categories) {
    return QuizConstants.categoryColors[categories.first] ?? Colors.blue;
  }
}

















