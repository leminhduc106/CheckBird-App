import 'package:check_bird/screens/about/widgets/member_info.dart';
import 'package:check_bird/screens/about/widgets/play_video_url.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  static const routeName = '/about-screen';

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Team info card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Techlosophy",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Our core values are to bring about happiness to everyone!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Video section with modern styling
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PlayVideoURL(
                  videoPlayerController: VideoPlayerController.networkUrl(
                    Uri.parse(
                        'https://res.cloudinary.com/dgci6plhk/video/upload/v1640971476/KNM_-_K19_HCMUS_Value_of_Life_gese1d.mp4'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Team section header
            Text(
              "Meet Our Team",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "The talented individuals behind CheckBird",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            
            // Team leader
            const MemberInformation(
                image: "assets/images/Phuoc.jpg",
                name: "Nguyen Ngoc Phuoc",
                id: "19127519",
                isLeader: true),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: MemberInformation(
                    image: "assets/images/duy.jpg",
                    name: "Ho Van Duy",
                    id: "19127373",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MemberInformation(
                    image: "assets/images/ha.jpg",
                    name: "Pham Le Ha",
                    id: "19127385",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: MemberInformation(
                    image: "assets/images/giang.jpg",
                    name: "Nguyen Truong Giang",
                    id: "19127384",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MemberInformation(
                    image: "assets/images/duc.jpg",
                    name: "Le Minh Duc",
                    id: "19127369",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
