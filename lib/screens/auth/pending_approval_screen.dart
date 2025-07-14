import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/error_service.dart';
import '../../theme/app_theme.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('⏳ PendingApprovalScreen initialized');
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    debugPrint('⏳ PendingApprovalScreen disposed');
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: const SizedBox(),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          debugPrint('🔄 Refreshing user profile...');
                          try {
                            await userProvider.refreshUserProfile();
                            if (mounted) {
                              ErrorService.showSuccess(context, 'Profile refreshed successfully');
                            }
                          } catch (e) {
                            debugPrint('❌ Error refreshing profile: $e');
                            if (mounted) {
                              ErrorService.showError(context, 'Failed to refresh profile: $e');
                            }
                          }
                        },
                        tooltip: 'Refresh Status',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          debugPrint('🚪 User logout from pending approval');
                          try {
                            await userProvider.signOut();
                          } catch (e) {
                            debugPrint('❌ Error signing out: $e');
                            if (mounted) {
                              ErrorService.showError(context, 'Failed to sign out: $e');
                            }
                          }
                        },
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                  
                  // Main content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated pending icon
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.hourglass_empty,
                                  size: 60,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          'Account Pending Approval',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // User info card
                        if (user != null) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              user.email,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.business,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${user.department} Department',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                        
                        // Description
                        Text(
                          'Your account has been created successfully!\n\nAn administrator will review and assign your role shortly. You will receive access to the appropriate dashboard once approved.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: Awaiting Admin Approval',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            debugPrint('🔄 Manual refresh requested');
                            try {
                              await userProvider.refreshUserProfile();
                              if (mounted) {
                                ErrorService.showSuccess(context, 'Profile refreshed successfully');
                              }
                            } catch (e) {
                              debugPrint('❌ Error refreshing profile: $e');
                              if (mounted) {
                                ErrorService.showError(context, 'Failed to refresh profile: $e');
                              }
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Status'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            debugPrint('🚪 Sign out from pending approval screen');
                            try {
                              await userProvider.signOut();
                            } catch (e) {
                              debugPrint('❌ Error signing out: $e');
                              if (mounted) {
                                ErrorService.showError(context, 'Failed to sign out: $e');
                              }
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
