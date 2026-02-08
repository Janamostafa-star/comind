import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../domain/models/user_model.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/animated_background.dart';
import '../../providers/visual_state_provider.dart';
import '../../screens/auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final visualState = context.watch<VisualStateProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Live Preview Background - changes based on current visual state
          AnimatedBackground(
            primaryColor: theme.primaryColor.withValues(alpha: 0.3),
            secondaryColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
            particleCount: 20,
            intensity: 0.3,
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile Card
                _buildProfileCard(context, user),
                
                const SizedBox(height: 28),
                
                // 🎨 BLOCK 1: THEME
                _ThemeBlock(),
                
                const SizedBox(height: 32),
                
                // 🌌 BLOCK 2: DYNAMIC MODE
                _DynamicModeBlock(),
                
                const SizedBox(height: 32),
                
                // 🎛️ BLOCK 3: BLEND MODE
                _BlendModeBlock(),

                const SizedBox(height: 32),
                
                // Focus Shortcut + Session Override
                _FocusControls(),

                const SizedBox(height: 32),
                
                // Other Settings
                _buildSectionTitle(context, 'Preferences'),
                const SizedBox(height: 12),
                _buildSettingsGroup(context, [
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: appState.languageCode == 'ar' ? 'العربية' : (appState.languageCode == 'fr' ? 'Français' : 'English'),
                    onTap: () => _showLanguageDialog(context),
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage alerts',
                    onTap: () => _showNotificationsDialog(context),
                  ),
                ]),

                const SizedBox(height: 20),
                
                _buildSectionTitle(context, 'Account'),
                const SizedBox(height: 12),
                _buildSettingsGroup(context, [
                  _SettingsItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _showChangePasswordDialog(context, authProvider),
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy',
                    subtitle: 'Data & privacy settings',
                    onTap: () => _showPrivacyDialog(context),
                  ),
                ]),

                const SizedBox(height: 20),

                _buildSectionTitle(context, 'Support'),
                const SizedBox(height: 12),
                _buildSettingsGroup(context, [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    subtitle: 'Get help and support',
                    onTap: () => _showHelpCenterDialog(context),
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About YallaStudy',
                    subtitle: 'Version 2.0.0 Premium',
                    onTap: () => _showAbout(context),
                  ),
                ]),

                const SizedBox(height: 28),

                // Logout button
                _buildLogoutButton(context, authProvider),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel? user) {
    // If name is 'User' (default fallback), try to show something else or check if loading
    final name = user?.name ?? 'User';
    final email = user?.email ?? 'user@yallastudy.app';
    final isDefault = name == 'User';
    final displayName = isDefault ? 'Guest User' : name; // Or 'Loading...' handled by provider
    final avatarUrl = user?.avatarUrl;
    
    return GlassmorphismCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: avatarUrl != null
                      ? ClipOval(
                          child: avatarUrl.startsWith('data:')
                              ? Image.memory(
                                  base64Decode(avatarUrl.split(',').last),
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                )
                              : Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                        )
                      : Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                ),
                GestureDetector(
                  onTap: () => _showImageSourceDialog(context, context.read<AuthProvider>()),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white70),
              onPressed: () {
                 final authProvider = context.read<AuthProvider>();
                 _showEditProfileDialog(context, authProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: Theme.of(context).primaryColor, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
                onTap: item.onTap,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, authProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'YallaStudy',
      applicationVersion: '2.0.0 Premium',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary]),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 30),
      ),
      children: [
        const Text('The ultimate immersive study platform.\n\nDesigned to protect your focus.'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final appState = context.read<AppState>();
    String selectedLanguage = appState.languageCode;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Language', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'English', '🇺🇸', selectedLanguage == 'English', () {
                setState(() => selectedLanguage = 'English');
              }),
              const SizedBox(height: 8),
              _buildLanguageOption(context, 'العربية', '🇸🇦', selectedLanguage == 'العربية', () {
                setState(() => selectedLanguage = 'العربية');
              }),
              const SizedBox(height: 8),
              _buildLanguageOption(context, 'Français', '🇫🇷', selectedLanguage == 'Français', () {
                setState(() => selectedLanguage = 'Français');
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                appState.setLanguage(selectedLanguage);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language set to ${selectedLanguage == 'ar' ? 'العربية' : selectedLanguage == 'fr' ? 'Français' : 'English'}'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, String flag, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(language, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.white))),
            if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    bool studyReminders = true;
    bool sessionAlerts = true;
    bool achievements = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Notifications', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Study Reminders', style: TextStyle(color: Colors.white)),
                subtitle: Text('Daily study prompts', style: TextStyle(color: AppTheme.textSecondary)),
                value: studyReminders,
                activeThumbColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => studyReminders = v),
              ),
              SwitchListTile(
                title: const Text('Session Alerts', style: TextStyle(color: Colors.white)),
                subtitle: Text('Upcoming meeting notifications', style: TextStyle(color: AppTheme.textSecondary)),
                value: sessionAlerts,
                activeThumbColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => sessionAlerts = v),
              ),
              SwitchListTile(
                title: const Text('Achievements', style: TextStyle(color: Colors.white)),
                subtitle: Text('Forest milestones', style: TextStyle(color: AppTheme.textSecondary)),
                value: achievements,
                activeThumbColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => achievements = v),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Notification preferences saved'), backgroundColor: AppTheme.neonGreen),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                  );
                  return;
                }
                setState(() => isLoading = true);
                final success = await authProvider.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                setState(() => isLoading = false);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password changed successfully' : 'Failed to change password'),
                      backgroundColor: success ? AppTheme.neonGreen : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Change', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Settings', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Collection', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '• Study statistics are stored locally\n• Session data syncs with your account\n• We never sell your data',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text('Your Rights', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '• Export your data anytime\n• Delete your account and all data\n• Control what you share',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help Center', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpItem(context, Icons.play_circle_outline, 'Getting Started', 'Learn the basics'),
            const SizedBox(height: 12),
            _buildHelpItem(context, Icons.schedule, 'Scheduling Sessions', 'Create study meetings'),
            const SizedBox(height: 12),
            _buildHelpItem(context, Icons.park_outlined, 'Focus Forest', 'Grow your garden'),
            const SizedBox(height: 12),
            _buildHelpItem(context, Icons.contact_support_outlined, 'Contact Support', 'support@yallastudy.app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.user?.name ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                 if (nameController.text.trim().isEmpty) return;
                 
                 setState(() => isLoading = true);
                 await authProvider.updateProfile(name: nameController.text.trim());
                 setState(() => isLoading = false);
                 
                 if (context.mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: const Text('Profile updated'), backgroundColor: AppTheme.neonGreen),
                   );
                 }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }


  void _showImageSourceDialog(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery, authProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera, authProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source, AuthProvider authProvider) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await authProvider.updateProfileImage(file);
        
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: const Text('Profile image updated'), backgroundColor: AppTheme.neonGreen),
           );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================================
// 🎨 BLOCK 1: THEME - Horizontal scroll cards like Spotify themes
// ============================================================================
class _ThemeBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visualState = context.watch<VisualStateProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Text('🎨', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Colors & Mood',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Horizontal scroll cards
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: VisualStateProvider.themeOptions.length,
            itemBuilder: (context, index) {
              final item = VisualStateProvider.themeOptions[index];
              final isSelected = visualState.theme == item.type;
              
              return GestureDetector(
                onTap: () => visualState.setTheme(item.type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 140,
                  margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.12) 
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? item.colors[0] : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: item.colors[0].withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated gradient circle with icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(isSelected ? 14 : 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [item.colors[0], item.colors[1]],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: item.colors[0].withValues(alpha: 0.5),
                              blurRadius: 12,
                            )
                          ] : null,
                        ),
                        child: Icon(item.icon, color: Colors.white, size: isSelected ? 26 : 24),
                      ),
                      const SizedBox(height: 12),
                      
                      // Theme name
                      Text(
                        item.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Color palette preview bar
                      Container(
                        height: 6,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: item.colors,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideX(begin: 0.15);
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 🌌 BLOCK 2: DYNAMIC MODE - Vertical list with animated thumbnails
// ============================================================================
class _DynamicModeBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visualState = context.watch<VisualStateProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with motion toggle
        Row(
          children: [
            const Text('🌌', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dynamic Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Background Motion',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Motion toggle
            Switch(
              value: visualState.isMotionEnabled,
              onChanged: (v) => visualState.toggleMotion(v),
              activeThumbColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Vertical list
        ...VisualStateProvider.dynamicModeOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final mode = entry.value;
          final isSelected = visualState.dynamicMode == mode.mode;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => visualState.setDynamicMode(mode.mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withValues(alpha: 0.12) 
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.white.withValues(alpha: 0.05),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                    )
                  ] : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(mode.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  title: Text(
                    mode.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    mode.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected 
                      ? Icon(Icons.check_circle_rounded, 
                          color: Theme.of(context).primaryColor, size: 24)
                      : Icon(mode.icon, 
                          color: Colors.white.withValues(alpha: 0.3), size: 20),
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)),
          );
        }).toList(),
      ],
    );
  }
}

// ============================================================================
// 🎛️ BLOCK 3: BLEND MODE - Segmented control with live preview
// ============================================================================
class _BlendModeBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visualState = context.watch<VisualStateProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Text('🎛️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blend Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Focus Filter • For distraction-sensitive users',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Current mode info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(visualState.currentBlendModeInfo.icon, 
                  color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current: ${visualState.currentBlendModeInfo.name}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      visualState.currentBlendModeInfo.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Blend mode chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VisualStateProvider.blendModeOptions.map((mode) {
            final isSelected = visualState.blendMode == mode.mode;
            return GestureDetector(
              onTap: () => visualState.setBlendMode(mode.mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode.icon, 
                      size: 16,
                      color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mode.name,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// 🎯 FOCUS CONTROLS - Focus shortcut + Session override
// ============================================================================
class _FocusControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visualState = context.watch<VisualStateProvider>();
    
    return Column(
      children: [
        // Focus Mode Button
        GestureDetector(
          onTap: () {
            visualState.applyFocusMode();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Focus Mode Activated 🧘', style: TextStyle(color: Colors.black)),
                  ],
                ),
                backgroundColor: Theme.of(context).primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, color: Colors.black, size: 24),
                SizedBox(width: 10),
                Text(
                  'ACTIVATE FOCUS MODE',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Session Override Status
        if (visualState.isSessionOverrideActive)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.amber),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Override Active',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Original settings will restore after session',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => visualState.endSessionOverride(),
                  child: const Text('Restore', style: TextStyle(color: Colors.amber)),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Info text
        Text(
          '"I control how much the app stimulates my brain."',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Helper class for settings items
// ============================================================================
class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
