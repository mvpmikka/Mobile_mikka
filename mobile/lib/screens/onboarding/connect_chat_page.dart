import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/app_colors.dart';

const _cafeLocation = LatLng(41.313, 69.244);

const _bullets = [
  (
    icon: Icons.chat_bubble_outline,
    title: 'Live Chats',
    description: 'Plan meetups in real-time with your friends.',
  ),
  (
    icon: Icons.location_on_outlined,
    title: 'Location Sharing',
    description: 'Show exactly where you are with one tap.',
  ),
  (
    icon: Icons.groups_outlined,
    title: 'Group Meetups',
    description: 'Organize gatherings with your closest circle.',
  ),
];

/// Onboarding page 4 — a chat-message preview, a small real map centered on
/// a sample meetup spot, and a "Mikka" branded card listing the chat/
/// location/meetup features (same card style as RewardsPage).
class ConnectChatPage extends StatelessWidget {
  const ConnectChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Connect and Chat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay close to the people who matter, wherever they are.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          const _ChatBubblePreview(),
          const SizedBox(height: 14),
          const _MeetupMapPreview(),
          const SizedBox(height: 20),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/icon/app_icon.png', height: 24),
              const SizedBox(width: 8),
              const Text(
                'Mikka',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect and Chat',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          for (final bullet in _bullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(bullet.icon, color: AppColors.orange, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bullet.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bullet.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (bullet != _bullets.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ChatBubblePreview extends StatelessWidget {
  const _ChatBubblePreview();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: const Text(
              'Shall we meet here?',
              style: TextStyle(fontSize: 14, color: AppColors.darkText),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small, non-interactive real map centered on a sample meetup spot, with
/// a label chip and a cluster of decorative "gathered friends" avatars
/// overlaid on top — illustrative, not tied to live data.
class _MeetupMapPreview extends StatelessWidget {
  const _MeetupMapPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _cafeLocation,
                  zoom: 15.5,
                ),
                markers: {
                  const Marker(
                    markerId: MarkerId('central-park-cafe'),
                    position: _cafeLocation,
                    infoWindow: InfoWindow(title: 'Central Park Cafe'),
                  ),
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: AppColors.orange, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Central Park Cafe',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 18,
              child: _FriendCluster(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCluster extends StatelessWidget {
  const _FriendCluster();

  static const _colors = [Color(0xFF3B82C4), Color(0xFF6BAE75), AppColors.orange];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < _colors.length; i++)
            Positioned(
              left: i * 22.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
