import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactTab extends StatelessWidget {
  const ContactTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ဆက်သွယ်ရန်'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Our Office',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('ရန်ကုန်-မန္တလေးလမ်းဟောင်း,ချမ်းမြသာစည်လေယာဥ်ကွင်းဟောင်းအနီး'),
                  
                    onTap: () {
                      // TODO: You can add a map link here if you want
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('+95 09978904943'),
                    onTap: () => _launchUrl('tel:09978904943'),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('+95 09973310696'),
                    onTap: () => _launchUrl('tel:09973310696'),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('info@kzlshop.com'),
                    onTap: () => _launchUrl('mailto:info@kzlshop.com'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect with us',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _buildSocialButton(
                      icon: Icons.facebook,
                      onPressed: () =>
                          _launchUrl('https://www.facebook.com/share/1EBF5kgme9'),
                    ),
                    _buildSocialButton(
                      icon: Icons.message, // Placeholder for Viber
                      onPressed: () =>
                          _launchUrl('https://www.viber.com/+9509978904943'),
                    ),
                    _buildSocialButton(
                      icon: Icons.music_note, // Placeholder for TikTok
                      onPressed: () =>
                          _launchUrl('https://www.tiktok.com/@moegyi1132'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 40),
      onPressed: onPressed,
      color: Colors.blue, // You can customize the color
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }
}
