import 'package:flutter/material.dart';
import '../core/theme.dart';

enum DynamicMode {
  off,
  softDrift,
  antiGravity,
  thinkWithMe,
  forestSky,
}

enum BlendModeType {
  normal,
  softBlur,
  dimMotion,
  monochrome,
  focusFade,
}

/// Metadata for Dynamic Mode display
class DynamicModeInfo {
  final DynamicMode mode;
  final String name;
  final String emoji;
  final String description;
  final IconData icon;

  const DynamicModeInfo({
    required this.mode,
    required this.name,
    required this.emoji,
    required this.description,
    required this.icon,
  });
}

/// Metadata for Blend Mode display
class BlendModeInfo {
  final BlendModeType mode;
  final String name;
  final String description;
  final IconData icon;

  const BlendModeInfo({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// Metadata for Theme display
class ThemeInfo {
  final AppThemeType type;
  final String name;
  final String emoji;
  final String description;
  final IconData icon;
  final List<Color> colors;

  const ThemeInfo({
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.icon,
    required this.colors,
  });
}

class VisualStateProvider extends ChangeNotifier {
  AppThemeType _theme = AppThemeType.nightFocus;
  DynamicMode _dynamicMode = DynamicMode.softDrift;
  BlendModeType _blendMode = BlendModeType.normal;
  bool _isMotionEnabled = true;
  
  // Session override state
  bool _sessionOverrideActive = false;
  AppThemeType? _savedTheme;
  DynamicMode? _savedDynamicMode;
  BlendModeType? _savedBlendMode;
  bool? _savedMotionEnabled;

  // Getters
  AppThemeType get theme => _theme;
  DynamicMode get dynamicMode => _dynamicMode;
  BlendModeType get blendMode => _blendMode;
  bool get isMotionEnabled => _isMotionEnabled;
  bool get isSessionOverrideActive => _sessionOverrideActive;

  // Static theme info list
  static const List<ThemeInfo> themeOptions = [
    ThemeInfo(
      type: AppThemeType.forestCalm,
      name: 'Forest Calm',
      emoji: '🌲',
      description: 'Heaven-like natural field',
      icon: Icons.park_outlined,
      colors: [Color(0xFFA3E635), Color(0xFF10B981), Color(0xFF022C22)],
    ),
    ThemeInfo(
      type: AppThemeType.nightFocus,
      name: 'Night Focus',
      emoji: '🌌',
      description: 'Deep cosmic concentration',
      icon: Icons.nights_stay_rounded,
      colors: [Color(0xFF22D3EE), Color(0xFF818CF8), Color(0xFF0F172A)],
    ),
    ThemeInfo(
      type: AppThemeType.sunriseStudy,
      name: 'Sunrise Focus',
      emoji: '🌅',
      description: 'Golden morning energy',
      icon: Icons.wb_sunny_rounded,
      colors: [Color(0xFFFBBF24), Color(0xFFF87171), Color(0xFF451A03)],
    ),
    ThemeInfo(
      type: AppThemeType.oceanSilence,
      name: 'Ocean Silence',
      emoji: '🌊',
      description: 'Deep oceanic peace',
      icon: Icons.water_drop_rounded,
      colors: [Color(0xFF38BDF8), Color(0xFF1D4ED8), Color(0xFF082F49)],
    ),
    ThemeInfo(
      type: AppThemeType.minimalDark,
      name: 'Minimal Dark',
      emoji: '⚫',
      description: 'Zero distraction slate',
      icon: Icons.circle_outlined,
      colors: [Color(0xFFF8FAFC), Color(0xFF64748B), Color(0xFF020617)],
    ),
  ];

  // Static dynamic mode info list
  static const List<DynamicModeInfo> dynamicModeOptions = [
    DynamicModeInfo(
      mode: DynamicMode.off,
      name: 'Off',
      emoji: '📴',
      description: 'Static background • Maximum calm',
      icon: Icons.pause_circle_outline,
    ),
    DynamicModeInfo(
      mode: DynamicMode.softDrift,
      name: 'Soft Drift',
      emoji: '🌬️',
      description: 'Very slow floating motion • Recommended',
      icon: Icons.air,
    ),
    DynamicModeInfo(
      mode: DynamicMode.antiGravity,
      name: 'Anti-Gravity Flow',
      emoji: '🌀',
      description: 'Floating particles with gentle attraction',
      icon: Icons.bubble_chart,
    ),
    DynamicModeInfo(
      mode: DynamicMode.thinkWithMe,
      name: 'Think With Me',
      emoji: '🧠',
      description: 'Abstract thinking visuals • Ideal for AI sessions',
      icon: Icons.psychology,
    ),
    DynamicModeInfo(
      mode: DynamicMode.forestSky,
      name: 'Forest Sky Motion',
      emoji: '🌿',
      description: 'Floating light & leaves • Gamified calm',
      icon: Icons.eco,
    ),
  ];

  // Static blend mode info list
  static const List<BlendModeInfo> blendModeOptions = [
    BlendModeInfo(
      mode: BlendModeType.normal,
      name: 'Normal',
      description: 'Full visual clarity',
      icon: Icons.visibility,
    ),
    BlendModeInfo(
      mode: BlendModeType.softBlur,
      name: 'Soft Blur',
      description: 'Slight background blur',
      icon: Icons.blur_on,
    ),
    BlendModeInfo(
      mode: BlendModeType.dimMotion,
      name: 'Dim Motion',
      description: 'Reduced motion opacity',
      icon: Icons.brightness_low,
    ),
    BlendModeInfo(
      mode: BlendModeType.monochrome,
      name: 'Monochrome Calm',
      description: 'Background becomes grayscale',
      icon: Icons.gradient,
    ),
    BlendModeInfo(
      mode: BlendModeType.focusFade,
      name: 'Focus Fade',
      description: 'Background fades during sessions',
      icon: Icons.center_focus_strong,
    ),
  ];

  void setTheme(AppThemeType theme) {
    _theme = theme;
    notifyListeners();
  }

  void setDynamicMode(DynamicMode mode) {
    _dynamicMode = mode;
    _isMotionEnabled = mode != DynamicMode.off;
    notifyListeners();
  }

  void setBlendMode(BlendModeType mode) {
    _blendMode = mode;
    notifyListeners();
  }

  void toggleMotion(bool enabled) {
    _isMotionEnabled = enabled;
    if (!enabled) _dynamicMode = DynamicMode.off;
    else if (_dynamicMode == DynamicMode.off) _dynamicMode = DynamicMode.softDrift;
    notifyListeners();
  }

  // Focus Shortcut - applies optimal focus settings
  void applyFocusMode() {
    _dynamicMode = DynamicMode.softDrift;
    _blendMode = BlendModeType.focusFade;
    _isMotionEnabled = true;
    notifyListeners();
  }

  /// Start session override - temporarily applies calm settings
  /// Saves current state to restore after session ends
  void startSessionOverride() {
    if (_sessionOverrideActive) return;
    
    // Save current state
    _savedTheme = _theme;
    _savedDynamicMode = _dynamicMode;
    _savedBlendMode = _blendMode;
    _savedMotionEnabled = _isMotionEnabled;
    
    // Apply calm session settings
    _dynamicMode = DynamicMode.softDrift;
    _blendMode = BlendModeType.focusFade;
    _isMotionEnabled = true;
    _sessionOverrideActive = true;
    
    notifyListeners();
  }

  /// End session override - restores original settings
  void endSessionOverride() {
    if (!_sessionOverrideActive) return;
    
    // Restore saved state
    if (_savedTheme != null) _theme = _savedTheme!;
    if (_savedDynamicMode != null) _dynamicMode = _savedDynamicMode!;
    if (_savedBlendMode != null) _blendMode = _savedBlendMode!;
    if (_savedMotionEnabled != null) _isMotionEnabled = _savedMotionEnabled!;
    
    // Clear saved state
    _savedTheme = null;
    _savedDynamicMode = null;
    _savedBlendMode = null;
    _savedMotionEnabled = null;
    _sessionOverrideActive = false;
    
    notifyListeners();
  }

  /// Get current theme info
  ThemeInfo get currentThemeInfo => 
    themeOptions.firstWhere((t) => t.type == _theme);

  /// Get current dynamic mode info
  DynamicModeInfo get currentDynamicModeInfo => 
    dynamicModeOptions.firstWhere((m) => m.mode == _dynamicMode);

  /// Get current blend mode info
  BlendModeInfo get currentBlendModeInfo => 
    blendModeOptions.firstWhere((b) => b.mode == _blendMode);
}
