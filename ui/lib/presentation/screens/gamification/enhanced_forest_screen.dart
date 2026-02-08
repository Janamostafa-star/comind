import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../widgets/procedural_tree.dart';

class EnhancedForestScreen extends StatefulWidget {
  const EnhancedForestScreen({super.key});

  @override
  State<EnhancedForestScreen> createState() => _EnhancedForestScreenState();
}

class _EnhancedForestScreenState extends State<EnhancedForestScreen>
    with TickerProviderStateMixin {
  late AnimationController _windController;
  late AnimationController _growthController;
  late AnimationController _particleController;
  late AnimationController _bobController;
  
  int _selectedIslandIndex = 0;
  double _cameraZoom = 1.0;
  Offset _cameraOffset = Offset.zero;
  
  final List<Map<String, dynamic>> _islands = [
    {
      'name': 'Barren Land',
      'unlocked': true, // Level 0 start
      'trees': 0,
      'level': 0,
      'icon': Icons.terrain_rounded,
      'color': const Color(0xFF8D6E63),
      'terrain': 'barren',
    },
    {
      'name': 'Sprouting Meadow',
      'unlocked': false,
      'trees': 4,
      'level': 2,
      'icon': Icons.grass_rounded,
      'color': const Color(0xFF4ADE80),
      'terrain': 'meadow',
    },
    {
      'name': 'Young Grove',
      'unlocked': false,
      'trees': 8,
      'level': 5,
      'icon': Icons.park_outlined,
      'color': const Color(0xFF66BB6A),
      'terrain': 'grove',
    },
    {
      'name': 'Lush Forest',
      'unlocked': false,
      'trees': 12,
      'level': 10,
      'icon': Icons.forest_rounded,
      'color': const Color(0xFF2E7D32),
      'terrain': 'forest',
    },
    {
      'name': 'Golden Peaks',
      'unlocked': false,
      'trees': 20,
      'level': 20,
      'icon': Icons.landscape_rounded,
      'color': const Color(0xFFFFD700),
      'terrain': 'mountain',
    },
    {
      'name': 'Nebula Garden',
      'unlocked': false,
      'trees': 50,
      'level': 50,
      'icon': Icons.auto_awesome,
      'color': const Color(0xFF9D4EDD),
      'terrain': 'space',
    },
    {
      'name': 'Celestial Void',
      'unlocked': false,
      'trees': 100, // Hard to reach
      'level': 100,
      'icon': Icons.nights_stay_rounded,
      'color': const Color(0xFF1A1A2E),
      'terrain': 'void',
    },
  ];

  final List<Map<String, dynamic>> _treeTypes = [
    {'name': 'Oak', 'icon': Icons.park_rounded, 'color': const Color(0xFF4ADE80), 'type': 'oak', 'cost': 5}, // Added cost
    {'name': 'Sakura', 'icon': Icons.filter_vintage_rounded, 'color': const Color(0xFFFF9FF3), 'type': 'sakura', 'cost': 10},
    {'name': 'Pine', 'icon': Icons.nature_rounded, 'color': const Color(0xFF2DD4BF), 'type': 'pine', 'cost': 8},
    {'name': 'Willow', 'icon': Icons.grass_rounded, 'color': const Color(0xFF60A5FA), 'type': 'willow', 'cost': 15},
  ];

  @override
  void initState() {
    super.initState();
    _windController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _growthController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _windController.dispose();
    _growthController.dispose();
    _particleController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final stats = appState.forest;
    final seeds = stats?.seeds ?? 0;
    final selectedIsland = _islands[_selectedIslandIndex];
    // Use real persistent trees from backend logic
    final treeCount = (stats?.treesPlanted ?? 0).clamp(0, 12); 


    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Sky gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                  Theme.of(context).cardColor,
                ],
              ),
            ),
          ),

          // Animated clouds/particles
          ...List.generate(20, (index) => _buildFloatingParticle(index)),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header (Fixed) - Swapped Layout
                _buildHeader(seeds, stats?.currentStreakDays ?? 0),
                
                // Content Body
                Expanded(
                  child: ListView( // Changed to ListView for better scrolling
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      const SizedBox(height: 10),
                      
                      // Interactive Field - Prominent placement
                      _buildInteractiveField(selectedIsland, treeCount),
                      
                      const SizedBox(height: 20),
                      
                      // Island/Level Selector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20), 
                        child: Text(
                          'Your Journey', 
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          )
                        )
                      ),
                      _buildIslandSelector(),
                      
                      // Bottom stats moving here to avoid crowding the list
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildBottomStats(stats),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int seeds, int streak) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final displayName = user?.name ?? 'Student';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Seeds on Left (as requested)
          _buildSeedsCounter(seeds),
          
          // User Avatar & Title on Right
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        'SKY GARDEN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.park_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level ${_islands[_selectedIslandIndex]['level']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // User Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: user?.avatarUrl != null
                      ? (user!.avatarUrl!.startsWith('data:')
                          ? Image.memory(
                              base64Decode(user.avatarUrl!.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(displayName),
                            )
                          : Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(displayName),
                            ))
                      : _buildAvatarPlaceholder(displayName),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStats(dynamic stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.timer_rounded,
              value: '${(stats?.totalFocusMinutes ?? 0) ~/ 60}',
              unit: 'hrs',
              label: 'Total Focus',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_rounded,
              value: '${stats?.currentStreakDays ?? 0}',
              unit: 'days',
              label: 'Streak',
              color: const Color(0xFFFF9F1C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedsCounter(int seeds) {
    return AnimatedBuilder(
      animation: _growthController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.2 + (_growthController.value * 0.1)),
                const Color(0xFFFFA500).withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4 + (_growthController.value * 0.2)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2 + (_growthController.value * 0.1)),
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco_rounded,
                color: const Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$seeds',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'seeds',
                style: TextStyle(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveField(Map<String, dynamic> island, int treeCount) {
    // Check if island is locked
    if (island['unlocked'] == false) {
      return _buildLockedField(island);
    }

    // Return the grid directly - Level 0 should show empty pots, not a lock screen
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Forest field with soil rows
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (island['color'] as Color).withValues(alpha: 0.1),
                  const Color(0xFF2D4A3E).withValues(alpha: 0.3),
                  const Color(0xFF1A2F1A).withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (island['color'] as Color).withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: (island['color'] as Color).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Row 1 - 4 pots
                _buildSoilRowWithPots(0, 4, treeCount),
                const SizedBox(height: 20),
                // Row 2 - 4 pots
                _buildSoilRowWithPots(4, 4, treeCount),
                const SizedBox(height: 20),
                // Row 3 - 4 pots
                _buildSoilRowWithPots(8, 4, treeCount),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildLockedField(Map<String, dynamic> island) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 60, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            '${island['name']} Locked',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Reach Level ${island['level']} to unlock\nthis field and discover new trees!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }


  Widget _buildSoilRowWithPots(int startIndex, int count, int treeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4A3728).withValues(alpha: 0.3),
            const Color(0xFF5D4037).withValues(alpha: 0.5),
            const Color(0xFF3E2723).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6D4C41).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(count, (i) {
          final index = startIndex + i;
          final hasTree = index < treeCount;
          return hasTree 
            ? _buildTreeInPot(_treeTypes[index % _treeTypes.length], index)
            : _buildEmptyPot(index);
        }),
      ),
    );
  }

  Widget _buildTreeInPot(Map<String, dynamic> treeType, int index) {
    return AnimatedBuilder(
      animation: _windController,
      builder: (context, child) {
        final sway = math.sin(_windController.value * math.pi * 2 + index) * 2;
        
        return GestureDetector(
          onTap: () => _showTreeInfo(treeType),
          child: SizedBox(
            width: 70,
            height: 100,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Pot
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 50,
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFD4A574),
                          Color(0xFFB8860B),
                          Color(0xFF8B4513),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E2723).withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                // Tree with sway animation
                Positioned(
                  bottom: 30,
                  child: Transform.translate(
                    offset: Offset(sway, 0),
                    child: ProceduralTree(
                      type: treeType['type'] as String,
                      growth: 1.0,
                      size: 45,
                    ),
                  ),
                ),
                // Glow
                Positioned(
                  bottom: 35,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (treeType['color'] as Color).withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPot(int index) {
    return GestureDetector(
      onTap: () => _showPlantDialog(index),
      child: SizedBox(
        width: 70,
        height: 100,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Empty pot
            Positioned(
              bottom: 0,
              child: Container(
                width: 50,
                height: 35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFD4A574).withValues(alpha: 0.5),
                      const Color(0xFFB8860B).withValues(alpha: 0.5),
                      const Color(0xFF8B4513).withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723).withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Plus icon
            Positioned(
              bottom: 45,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 1500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTerrainBackground(String terrain) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _getTerrainColors(terrain),
        ),
      ),
      child: CustomPaint(
        painter: _TerrainPainter(terrain),
        size: Size.infinite,
      ),
    );
  }

  List<Color> _getTerrainColors(String terrain) {
    switch (terrain) {
      case 'meadow':
        return [
          const Color(0xFF87CEEB).withValues(alpha: 0.3),
          const Color(0xFF90EE90).withValues(alpha: 0.2),
          const Color(0xFF228B22).withValues(alpha: 0.1),
        ];
      case 'mountain':
        return [
          const Color(0xFFFFD700).withValues(alpha: 0.2),
          const Color(0xFFFFA500).withValues(alpha: 0.15),
          const Color(0xFF8B4513).withValues(alpha: 0.1),
        ];
      default:
        return [
          Colors.transparent,
          Colors.transparent,
        ];
    }
  }

  Widget _buildAnimatedTree(Map<String, dynamic> treeType, int index) {
    return AnimatedBuilder(
      animation: _windController,
      builder: (context, child) {
        final sway = math.sin(_windController.value * math.pi * 2 + index) * 3;
        final growth = 0.7 + (math.sin(_growthController.value * math.pi * 2 + index) * 0.1);
        
        return Transform.translate(
          offset: Offset(sway, 0),
          child: Transform.scale(
            scale: growth,
            child: GestureDetector(
              onTap: () => _showTreeInfo(treeType),
              child: Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Procedural tree
                    ProceduralTree(
                      type: treeType['type'] as String,
                      growth: 1.0,
                      size: 50,
                    ),
                    // Glow effect
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (treeType['color'] as Color).withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlantableSlot(int index) {
    return GestureDetector(
      onTap: () => _showPlantDialog(index),
      child: Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.white.withValues(alpha: 0.3),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Plant',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 4 + 2;
    final delay = random.nextDouble();
    final startX = random.nextDouble();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            final progress = (_particleController.value + delay) % 1.0;
            final screenHeight = constraints.maxHeight > 0 ? constraints.maxHeight : 800.0;
            final screenWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
            final y = progress * screenHeight;
            final x = startX * screenWidth;
            final opacity = (math.sin(progress * math.pi * 2) * 0.5 + 0.5) * 0.6;
            
            return Transform.translate(
              offset: Offset(x, y),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: opacity),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: opacity * 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIslandSelector() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _islands.length,
        itemBuilder: (context, index) {
          final island = _islands[index];
          final isSelected = _selectedIslandIndex == index;
          final isUnlocked = island['unlocked'] as bool;

          return GestureDetector(
            onTap: isUnlocked 
                ? () => setState(() => _selectedIslandIndex = index)
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Reach Level ${island['level']} to unlock ${island['name']}!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF2C2C2E), // Dark card color
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              margin: EdgeInsets.only(right: index < _islands.length - 1 ? 12 : 0),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: isUnlocked
                            ? [
                                (island['color'] as Color).withValues(alpha: 0.3),
                                (island['color'] as Color).withValues(alpha: 0.2),
                              ]
                            : [
                                Colors.grey.withValues(alpha: 0.2),
                                Colors.grey.withValues(alpha: 0.1),
                              ],
                      )
                    : null,
                color: isSelected ? null : (isUnlocked ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.3)), // Darker for locked
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (isUnlocked ? (island['color'] as Color) : Colors.grey).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked ? (island['icon'] as IconData) : Icons.lock_rounded,
                    color: isUnlocked
                        ? (isSelected ? (island['color'] as Color) : Colors.white.withValues(alpha: 0.7))
                        : Colors.white.withValues(alpha: 0.2), // Dimmer lock icon
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    island['name'] as String,
                    style: TextStyle(
                      color: isUnlocked
                          ? (isSelected ? (island['color'] as Color) : Colors.white.withValues(alpha: 0.7))
                          : Colors.white.withValues(alpha: 0.3), // Dimmer text
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPanel(dynamic stats, int seeds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_rounded,
                  value: '${(stats?.totalFocusMinutes ?? 0) ~/ 60}',
                  unit: 'hrs',
                  label: 'Total Focus',
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: '${stats?.currentStreakDays ?? 0}',
                  unit: 'days',
                  label: 'Streak',
                  color: const Color(0xFFFF9F1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (stats?.seeds ?? 0) > 0 ? () => _showPlantDialog(0) : null,
              icon: const Icon(Icons.eco_rounded),
              label: Text('Plant Tree (5 seeds)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTreeInfo(Map<String, dynamic> treeType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text('${treeType['name']} Tree', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(treeType['icon'] as IconData, color: treeType['color'] as Color, size: 48),
            const SizedBox(height: 16),
            Text(
              'This tree represents your focus and dedication. Keep studying to grow more!',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPlantDialog(int slotIndex) {
    final appState = context.read<AppState>();
    final seeds = appState.forest?.seeds ?? 0;
    
    if (seeds < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least 5 seeds to plant a tree!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Plant a Tree', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose a tree type to plant (Cost: 5 seeds)',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            ..._treeTypes.map((tree) => ListTile(
              leading: Icon(tree['icon'] as IconData, color: tree['color'] as Color),
              title: Text(tree['name'] as String, style: const TextStyle(color: Colors.white)),
              onTap: () {
                // Plant tree logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${tree['name']} tree planted!')),
                );
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrainPainter extends CustomPainter {
  final String terrain;

  _TerrainPainter(this.terrain);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw field surface
    final surfacePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), 
        const Radius.circular(20)
      ));
    canvas.drawPath(surfacePath, paint);

    // Light rays effect
    final rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 5; i++) {
      final rayPath = Path()
        ..moveTo(size.width * (0.2 * i), 0)
        ..lineTo(size.width * (0.2 * i + 0.1), 0)
        ..lineTo(size.width * (0.2 * i + 0.3), size.height)
        ..lineTo(size.width * (0.2 * i + 0.1), size.height)
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PerspectiveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 10; i++) {
        final y = size.height * (i / 10);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical grid lines (vantage point effect)
    for (int i = 0; i <= 10; i++) {
        final x = size.width * (i / 10);
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
