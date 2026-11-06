import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle_log.dart';
import '../theme/app_theme.dart';

/// Card widget displaying a single VehicleLog entry in the dashboard list.
class VehicleLogCard extends StatelessWidget {
  final VehicleLog log;
  final VoidCallback? onCheckOut;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const VehicleLogCard({
    super.key,
    required this.log,
    this.onCheckOut,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInside = log.status == 'Inside';
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd MMM');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isInside
                ? AppTheme.statusInside.withValues(alpha: 0.4)
                : AppTheme.outlineVariant,
            width: isInside ? 1.5 : 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left status accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isInside
                      ? AppTheme.statusInside
                      : AppTheme.statusExited,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Image thumbnail
              if (log.imagePath.isNotEmpty && File(log.imagePath).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image.file(
                    File(log.imagePath),
                    width: 70,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 80,
                  color: AppTheme.surfaceContainerLow,
                  child: Icon(
                    _vehicleIcon(log.vehicleType),
                    color: AppTheme.outline,
                    size: 28,
                  ),
                ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // License plate + status chip
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.licensePlate,
                              style: AppTheme.plateDisplay,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusChip(isInside: isInside),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Vehicle type + flat info
                      Row(
                        children: [
                          Icon(
                            _vehicleIcon(log.vehicleType),
                            size: 12,
                            color: AppTheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.vehicleType,
                            style: AppTheme.labelMd,
                          ),
                          if (log.flatOrVisitorInfo.isNotEmpty) ...[
                            Text(
                              '  •  ',
                              style: AppTheme.labelMd,
                            ),
                            Flexible(
                              child: Text(
                                log.flatOrVisitorInfo,
                                style: AppTheme.labelMd.copyWith(
                                  color: AppTheme.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Time info
                      Row(
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 11,
                            color: AppTheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${dateFormatter.format(log.entryTimestamp)} ${timeFormatter.format(log.entryTimestamp)}',
                            style: AppTheme.labelSm,
                          ),
                          if (isInside) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.timer_outlined,
                              size: 11,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              log.timeInsideString,
                              style: AppTheme.labelSm.copyWith(
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Actions column
              if (isInside && onCheckOut != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ExitButton(onPressed: onCheckOut!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'truck':
        return Icons.local_shipping_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final bool isInside;
  const _StatusChip({required this.isInside});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isInside ? AppTheme.statusInsideBg : AppTheme.statusExitedBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInside
              ? AppTheme.statusInside.withValues(alpha: 0.5)
              : AppTheme.statusExited.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        isInside ? 'INSIDE' : 'EXITED',
        style: AppTheme.labelSm.copyWith(
          color: isInside ? AppTheme.statusInside : AppTheme.statusExited,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ExitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.secondaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.secondary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppTheme.secondary,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              'EXIT',
              style: AppTheme.labelSm.copyWith(
                color: AppTheme.secondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
