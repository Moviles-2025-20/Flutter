import 'package:app_flutter/pages/badges/model/badge.dart';
import 'package:app_flutter/pages/badges/model/user_badge.dart';
import 'package:flutter/material.dart';

class BadgeDetailView extends StatelessWidget {
  final Badge_Medal badge;
  final UserBadge userBadge;

  const BadgeDetailView({
    Key? key,
    required this.badge,
    required this.userBadge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUnlocked = userBadge.isUnlocked;
    final isInProgress = !isUnlocked && userBadge.progress > 0;
    final isLocked = !isUnlocked && userBadge.progress == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          'Badge Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6389E2),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(isUnlocked, isInProgress),
              const SizedBox(height: 32),
              _buildInfo1Card(isUnlocked, isInProgress, isLocked),
              const SizedBox(height: 32),
              _buildInfoCard(),
              const SizedBox(height: 32),
              _buildProgressSection(isUnlocked, isInProgress),
              const SizedBox(height: 40),
            ],
        ),
      ),
    )
    );
  }

  // ============= HEADER =============
  Widget _buildHeader(bool isUnlocked, bool isInProgress) {
    return Column(
      children: [
        const SizedBox(height: 25),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? Colors.amber[100]
                : isInProgress
                    ? Colors.orange[100]
                    : Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: (isUnlocked
                        ? Colors.amber
                        : isInProgress
                            ? Colors.orange
                            : Colors.grey)
                    .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            isUnlocked
                ? Icons.emoji_events
                : isInProgress
                    ? Icons.schedule
                    : Icons.lock_outline,
            size: 70,
            color: isUnlocked
                ? Colors.amber
                : isInProgress
                    ? Colors.orange
                    : Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
       
      ],
    );
  }
 Widget _buildInfo1Card(bool isUnlocked, bool isInProgress, bool isLocked) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isUnlocked) {
      statusText = 'Unlocked!';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isInProgress) {
      statusText = 'In Progress';
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else {
      statusText = 'Locked';
      statusColor = Colors.grey;
      statusIcon = Icons.lock_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.2),
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(isUnlocked),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ============= INFO CARD (Requirement, Goal, Rarity) =============
  Widget _buildInfoCard() {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: const Color.fromARGB(255, 104, 104, 104),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),

            _buildInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Requirement',
              value: badge.criteriaType,
              iconColor: const Color(0xFF6389E2),
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.tag,
              label: 'Goal',
              value: '${badge.criteriaValue}',
              iconColor: const Color(0xFF6389E2),
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.star,
              label: 'Rarity',
              value: badge.rarity.capitalized(),
              iconColor: const Color(0xFF6389E2),
            ),
          ],
        )
      );
      
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      );

  }

  // ============= PROGRESS SECTION =============
  Widget _buildProgressSection(bool isUnlocked, bool isInProgress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (!isUnlocked) _buildProgressCard(isInProgress),
          if (isUnlocked) _buildUnlockedCard(),
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isInProgress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: userBadge.progress / (badge.criteriaValue as int),
              minHeight: 10,
              backgroundColor: const Color(0xFFFFCE9C),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF57C00),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activities Completed',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCE9C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${userBadge.progress}/${badge.criteriaValue}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF57C00),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC8E6C9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFA5D6A7),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You\'ve earned this badge!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Earned on ${userBadge.earnedAt?.toString().split(' ')[0] ?? 'today'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(bool isUnlocked) {
    if (isUnlocked) {
      return 'You have successfully unlocked this badge';
    } else if (userBadge.progress > 0) {
      return 'Keep going! You are close to unlocking this badge';
    } else {
      return 'Complete the requirements to unlock this badge';
    }
  }
  // ============= HELPERS =============
  Color _getBadgeHeaderColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF9E9E9E);
      case 'rare':
        return const Color(0xFF2196F3);
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'legendary':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF6389E2);
    }
  }
}

extension Capitalize on String {
  String capitalized() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();
}
