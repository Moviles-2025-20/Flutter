import 'package:app_flutter/pages/badges/model/badge.dart';
import 'package:app_flutter/pages/badges/model/user_badge.dart';
import 'package:app_flutter/pages/badges/viewModel/badges_view_model.dart';
import 'package:app_flutter/util/badges_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BadgeView extends StatefulWidget {
  final String userId;
  const BadgeView({Key? key, required this.userId}) : super(key: key);

  @override
  State<BadgeView> createState() => _BadgeViewState();
}

class _BadgeViewState extends State<BadgeView> {
  late BadgeMedalViewModel _viewModel;
  late BadgeRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _repository = BadgeRepository();
    _viewModel = BadgeMedalViewModel(
      userId: _auth.currentUser!.uid,
      badgeRepository: _repository,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.loadAllBadgeMedals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          "Badges",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6389E2),
        centerTitle: true ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.errorMessage != null) {
            return Center(
              child: Text(
                _viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressHeader(),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Unlocked',
                    badges: _viewModel.unlockedBadgeMedals,
                    isUnlocked: true,
                  ),
                  const SizedBox(height: 24),
                  _buildRaritySection(),
                  const SizedBox(height: 24),
                  _buildSecretSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = _viewModel.getOverallProgress();
    final unlocked = _viewModel.unlockedBadgeMedals.length;
    final total = _viewModel.allBadgeMedals.length;

    return Card(
      color: const Color.fromARGB(255, 237, 98, 117),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'General Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
                Text(
                  '$unlocked/$total',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? progress / 100 : 0,
                minHeight: 8,
                color: const Color.fromARGB(255, 237, 98, 117),          // ← Color de la barra llena
                backgroundColor: Color.fromARGB(255, 253, 253, 253),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$progress% completed',
              style: TextStyle(
                fontSize: 14,
                color: const Color.fromARGB(255, 252, 230, 230),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<UserBadge> badges,
    required bool isUnlocked,
  }) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final userBadge = badges[index];
            final badge = _viewModel.getBadgeMedalById(userBadge.badgeId);
            if (badge == null) return const SizedBox.shrink();

            return _buildBadgeCard(
              badge: badge,
              userBadge: userBadge,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRaritySection() {
    final rarities = ['common', 'rare', 'epic', 'legendary'];
    final colors = {
      'common': Colors.grey,
      'rare': Colors.blue,
      'epic': Colors.purple,
      'legendary': Colors.orange,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rarities.map((rarity) {
        // Obtener TODAS las medallas de esta rareza
        final badgesByRarity = _viewModel.allBadgeMedals
            .where((badge) => badge.rarity == rarity)
            .toList();

        if (badgesByRarity.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[rarity],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rarity.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: badgesByRarity.length,
              itemBuilder: (context, index) {
                final badge = badgesByRarity[index];

                // Obtener el progreso del usuario para esta medalla
                final userBadge = _viewModel.getUserBadgeProgress(badge.id);

                // Si no tiene progreso, crear uno por defecto
                final displayUserBadge = userBadge ??
                    UserBadge(
                      id: '${_viewModel.userId}_${badge.id}',
                      userId: _viewModel.userId,
                      badgeId: badge.id,
                      isUnlocked: false,
                      progress: 0,
                      earnedAt: null,
                      synced: 0,
                    );

                return _buildBadgeCard(
                  badge: badge,
                  userBadge: displayUserBadge,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSecretSection() {
    final secretBadges = _viewModel.getSecretLockedBadgeMedals();
    if (secretBadges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secret Badges',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: secretBadges.length,
          itemBuilder: (context, index) {
            return _buildLockedBadgeCard();
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard({
    required Badge_Medal badge,
    required UserBadge userBadge,
  }) {
    final isUnlocked = userBadge.isUnlocked;
    final isLocked = !isUnlocked && userBadge.progress == 0;
    final isInProgress = !isUnlocked && userBadge.progress > 0;

    return GestureDetector(
      onTap: () => _showBadgeDetails(badge, userBadge),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnlocked
                ? Colors.amber
                : isInProgress
                    ? Colors.orange[400]!
                    : Colors.grey[300]!,
            width: isUnlocked || isInProgress ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Fondo oscuro para medallas bloqueadas
            if (isLocked)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),

            // Contenido
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono principal
                if (isUnlocked)
                  const Icon(Icons.stars, color: Colors.amber, size: 24)
                else if (isInProgress)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: Colors.orange[600],
                      size: 24,
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.lock_outline, color: Colors.grey),
                  ),

                const SizedBox(height: 8),

                // Nombre de la medalla
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLocked ? Colors.grey[600] : Colors.black,
                  ),
                ),

                // Progreso
                if (isInProgress)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        Text(
                          '${userBadge.progress}/${badge.criteriaValue}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: userBadge.progress /
                                  (badge.criteriaValue as int),
                              minHeight: 3,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange[400]!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedBadgeCard() {
    return Card(
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.help_outline, color: Colors.grey, size: 32),
      ),
    );
  }

  void _showBadgeDetails(Badge_Medal badge, UserBadge userBadge) {
    final isUnlocked = userBadge.isUnlocked;
    final isInProgress = !isUnlocked && userBadge.progress > 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.amber[100]
                          : isInProgress
                              ? Colors.orange[100]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isUnlocked
                          ? Icons.star
                          : isInProgress
                              ? Icons.schedule
                              : Icons.lock_outline,
                      size: 40,
                      color: isUnlocked
                          ? Colors.amber
                          : isInProgress
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          badge.rarity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isUnlocked)
                          const SizedBox(height: 4),
                        if (isUnlocked)
                          Text(
                            'Unlocked',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (isInProgress)
                          const SizedBox(height: 4),
                        if (isInProgress)
                          Text(
                            'In progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                badge.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Mostrar progreso o estado desbloqueado
              if (isUnlocked)
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked ${userBadge.earnedAt?.toString().split(' ')[0] ?? 'today'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You haven\'t complete the requirements.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: userBadge.progress /
                            (badge.criteriaValue as int),
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isInProgress ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${userBadge.progress}/${badge.criteriaValue}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}