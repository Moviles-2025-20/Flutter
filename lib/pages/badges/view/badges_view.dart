import 'package:app_flutter/pages/badges/model/badge.dart';
import 'package:app_flutter/pages/badges/model/user_badge.dart';
import 'package:app_flutter/pages/badges/view/badge_detail_view.dart';
import 'package:app_flutter/pages/badges/viewModel/badges_view_model.dart';
import 'package:app_flutter/util/badges_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiver/strings.dart';

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
  int _selectedTab = 0; // 0=All, 1=Unlocked, 2=Locked

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
      await _viewModel.loadUserBadges();
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
        centerTitle: true,
        elevation: 0,
      ),
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
                  // Header con progreso
                  _buildProgressHeader(),
                  const SizedBox(height: 24),

                  // Tabs: All, Unlocked, Locked
                  _buildTabs(),
                  const SizedBox(height: 20),

                  // Contenido según tab seleccionado
                  if (_selectedTab == 0) _buildAllBadgesView(),
                  if (_selectedTab == 1) _buildUnlockedView(),
                  if (_selectedTab == 2) _buildLockedView(),
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

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 202, 202, 202).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$unlocked/$total',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color:  Color(0xFFE3944F),
                      ),
                    ),
                    const Text(
                      'Badges Unlocked',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(179, 0, 0, 0),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: total > 0 ? progress / 100 : 0,
                minHeight: 20,
                backgroundColor: const Color.fromARGB(255, 190, 190, 190).withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFE3944F),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$progress% Complete',
              style: const TextStyle(
                fontSize: 12,
                color: Color.fromARGB(255, 99, 99, 99),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          _buildTabButton('All', 0),
          _buildTabButton('Unlocked', 1),
          _buildTabButton('Locked', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6389E2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllBadgesView() {
    return _buildRaritySection();
  }

  Widget _buildUnlockedView() {
    if (_viewModel.unlockedBadgeMedals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lock_outline,
        title: 'No badges unlocked yet',
        subtitle: 'Complete activities to unlock badges',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _viewModel.unlockedBadgeMedals.length,
      itemBuilder: (context, index) {
        final userBadge = _viewModel.unlockedBadgeMedals[index];
        final badge = _viewModel.getBadgeMedalById(userBadge.badgeId);
        if (badge == null) return const SizedBox.shrink();

        return _buildBadgeCard(badge: badge, userBadge: userBadge);
      },
    );
  }

  Widget _buildLockedView() {
    final lockedBadges = _viewModel.allBadgeMedals
        .where((b) => !_viewModel.unlockedBadgeMedals.any((ub) => ub.badgeId == b.id))
        .toList();

    if (lockedBadges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'All unlocked!',
        subtitle: 'You\'ve unlocked all available badges',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: lockedBadges.length,
      itemBuilder: (context, index) {
        final badge = lockedBadges[index];
        final userBadge = _viewModel.getUserBadgeProgress(badge.id) ??
            UserBadge(
              id: '${_viewModel.userId}_${badge.id}',
              userId: _viewModel.userId,
              badgeId: badge.id,
              isUnlocked: false,
              progress: 0,
              earnedAt: null,
            );

        return _buildBadgeCard(badge: badge, userBadge: userBadge);
      },
    );
  }

  Widget _buildRaritySection() {
    final rarities = ['common', 'rare', 'epic', 'legendary'];
    final colors = {
      'common': Colors.grey,
      'rare': Colors.blue,
      'epic': Colors.purple,
      'legendary': const Color.fromARGB(255, 255, 213, 0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rarities.map((rarity) {
        final badgesByRarity = _viewModel.allBadgeMedals
            .where((badge) => badge.rarity == rarity)
            .toList();

        if (badgesByRarity.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors[rarity],
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: colors[rarity]!.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    rarity.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: badgesByRarity.length,
              itemBuilder: (context, index) {
                final badge = badgesByRarity[index];
                final userBadge = _viewModel.getUserBadgeProgress(badge.id) ??
                    UserBadge(
                      id: '${_viewModel.userId}_${badge.id}',
                      userId: _viewModel.userId,
                      badgeId: badge.id,
                      isUnlocked: false,
                      progress: 0,
                      earnedAt: null,
                    );

                return _buildBadgeCard(badge: badge, userBadge: userBadge);
              },
            ),
            const SizedBox(height: 32),
          ],
        );
      }).toList(),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Card base
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isUnlocked
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : isInProgress
                        ?  const Color.fromARGB(255, 255, 255, 255)
                        : const Color.fromARGB(255, 255, 255, 255),
                border: Border.all(
                  color: isUnlocked
                      ? Colors.amber.withOpacity(0.3)
                      : isInProgress
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              child: isLocked
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    )
                  : null,
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? Colors.amber.withOpacity(0.2)
                          : isInProgress
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.grey[100],
                    ),
                    child: Center(
                      child: isUnlocked
                          ? const Icon(Icons.emoji_events, color: Colors.amber, size: 40)
                          : isInProgress
                              ? Icon(Icons.schedule,
                                  color: Colors.orange[600], size: 36)
                              : Icon(Icons.lock_outline,
                                  color: Colors.grey[500], size: 36),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nombre
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isLocked ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progreso o estado
                  if (isInProgress)
                    Column(
                      children: [
                        SizedBox(
                          width: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: userBadge.progress /
                                  (badge.criteriaValue as int),
                              minHeight: 4,
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.orange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                         Text(
                          '${userBadge.progress}/${badge.criteriaValue}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 6),
                         Text(
                          badge.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 134, 134, 134),
                          ),
                        ),
                        
                      ],
                    )
                  else if (isUnlocked)
                   Column(
                    children: [Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color.fromARGB(255, 0, 172, 55), size: 20),
                        const SizedBox(width: 3),
                        Text(
                          'Unlocked',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 0, 172, 55),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                      Text(
                          badge.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 134, 134, 134),
                          ),
                        ),
                    ],
                   )
                    
                    
                  else
                    Column(
                      children: [
                        Text(
                          '0/${badge.criteriaValue}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          badge.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 134, 134, 134),
                          ),
                        ),
                      ],
                    )
                    
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showBadgeDetails(Badge_Medal badge, UserBadge userBadge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BadgeDetailView(
          badge: badge,
          userBadge: userBadge,
        ),
      ),
    );
  } 

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}