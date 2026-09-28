import 'package:flutter/material.dart';
import '../main.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Widget _buildContactCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $title...')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isSinhala ? 'උදව් සහ සහාය' : 'Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.support_agent, size: 80, color: Colors.green.shade600),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isSinhala ? 'අපව සම්බන්ධ කරගන්න' : 'Contact Us',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isSinhala 
                ? 'ඔබට ඇති ඕනෑම ගැටලුවක් සඳහා අපගේ සහායක කණ්ඩායම අමතන්න.' 
                : 'Get in touch with our support team for any assistance.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            _buildContactCard(
              context,
              icon: Icons.phone,
              title: isSinhala ? 'ප්‍රධාන කාර්යාලය (Hotline)' : 'Hotline',
              subtitle: '011-2345678',
              color: Colors.green,
            ),
            _buildContactCard(
              context,
              icon: Icons.message,
              title: isSinhala ? 'WhatsApp සහාය' : 'WhatsApp Support',
              subtitle: '077-1234567',
              color: Colors.teal,
            ),
            _buildContactCard(
              context,
              icon: Icons.email,
              title: isSinhala ? 'විද්‍යුත් තැපෑල (Email)' : 'Email Us',
              subtitle: 'support@teafarm.lk',
              color: Colors.blue,
            ),
            
            const SizedBox(height: 24),
            Text(
              isSinhala ? 'වැඩිදුර තොරතුරු' : 'More Information',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildContactCard(
              context,
              icon: Icons.eco,
              title: isSinhala ? 'ශ්‍රී ලංකා තේ මණ්ඩලය' : 'Sri Lanka Tea Board',
              subtitle: 'www.srilankateaboard.lk',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
