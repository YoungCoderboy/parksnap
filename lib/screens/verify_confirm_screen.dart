import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_log.dart';
import '../providers/vehicle_log_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

/// Screen 3: Verify & Confirm — editable fields pre-filled from Gemini, then save to DB.
class VerifyConfirmScreen extends StatefulWidget {
  final String imagePath;
  final GeminiResult? geminiResult;
  final String? geminiError;

  const VerifyConfirmScreen({
    super.key,
    required this.imagePath,
    this.geminiResult,
    this.geminiError,
  });

  @override
  State<VerifyConfirmScreen> createState() => _VerifyConfirmScreenState();
}

class _VerifyConfirmScreenState extends State<VerifyConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plateController;
  late TextEditingController _flatController;
  String _selectedVehicleType = 'Car';
  bool _isSaving = false;

  static const _vehicleTypes = ['Car', 'Bike', 'Truck', 'Other'];

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(
      text: widget.geminiResult?.plate ?? '',
    );
    _flatController = TextEditingController();
    if (widget.geminiResult?.type != null) {
      _selectedVehicleType = widget.geminiResult!.type;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _flatController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final log = VehicleLog(
      licensePlate: _plateController.text.trim().toUpperCase(),
      vehicleType: _selectedVehicleType,
      entryTimestamp: DateTime.now(),
      flatOrVisitorInfo: _flatController.text.trim(),
      status: 'Inside',
      imagePath: widget.imagePath,
      confidence: widget.geminiResult?.confidence ?? 0.0,
    );

    final success =
        await context.read<VehicleLogProvider>().addLog(log);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // Pop camera scanner screen + this screen, back to dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.statusInside, size: 18),
              const SizedBox(width: 8),
              Text('${log.licensePlate} logged successfully!'),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<VehicleLogProvider>().error ?? 'Failed to save'),
        ),
      );
    }
  }

  void _retake() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final confidence = widget.geminiResult?.confidence ?? 0.0;
    final hasError = widget.geminiError != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Verify & Confirm', style: AppTheme.headlineSm),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _retake,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Captured image
              _CapturedImageCard(imagePath: widget.imagePath),
              const SizedBox(height: 16),

              // Gemini status banner
              if (hasError)
                _GeminiErrorBanner(error: widget.geminiError!)
              else
                _ConfidenceBanner(confidence: confidence),

              const SizedBox(height: 20),

              // ── License Plate Field ──────────────────────────────────────
              _SectionLabel(label: 'LICENSE PLATE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                style: AppTheme.plateLg.copyWith(letterSpacing: 3),
                decoration: const InputDecoration(
                  labelText: 'Plate Number',
                  hintText: 'MH 12 AB 1234',
                  prefixIcon: Icon(
                    Icons.credit_card_rounded,
                    color: AppTheme.outline,
                    size: 20,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'License plate is required';
                  }
                  if (val.trim().length < 3) {
                    return 'Enter a valid plate number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Vehicle Type ─────────────────────────────────────────────
              _SectionLabel(label: 'VEHICLE TYPE'),
              const SizedBox(height: 10),
              Row(
                children: _vehicleTypes
                    .map((type) => _VehicleTypeChip(
                          label: type,
                          isSelected: _selectedVehicleType == type,
                          icon: _vehicleIcon(type),
                          onTap: () =>
                              setState(() => _selectedVehicleType = type),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              // ── Flat / Visitor Info ──────────────────────────────────────
              _SectionLabel(label: 'FLAT / VISITOR INFO'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _flatController,
                style: AppTheme.bodyLg.copyWith(color: AppTheme.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Flat No. / Purpose (optional)',
                  hintText: 'e.g. A-203 / Guest / Delivery',
                  prefixIcon: Icon(
                    Icons.apartment_rounded,
                    color: AppTheme.outline,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Summary card ─────────────────────────────────────────────
              _EntrySummaryCard(
                plateText: _plateController.text,
                vehicleType: _selectedVehicleType,
                entryTime: DateTime.now(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        isSaving: _isSaving,
        onSave: _saveLog,
        onRetake: _retake,
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

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _CapturedImageCard extends StatelessWidget {
  final String imagePath;
  const _CapturedImageCard({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 220,
        width: double.infinity,
        color: AppTheme.surfaceContainerLow,
        child: File(imagePath).existsSync()
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : const Icon(Icons.broken_image_rounded,
                color: AppTheme.outline, size: 48),
      ),
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  final double confidence;
  const _ConfidenceBanner({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.confidenceColor(confidence);
    final label = confidence >= 80
        ? 'HIGH CONFIDENCE'
        : confidence >= 50
            ? 'MEDIUM CONFIDENCE'
            : 'LOW CONFIDENCE — PLEASE VERIFY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gemini: $label (${confidence.toStringAsFixed(0)}%)',
              style: AppTheme.labelMd.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeminiErrorBanner extends StatelessWidget {
  final String error;
  const _GeminiErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI EXTRACTION FAILED',
                style: AppTheme.labelMd.copyWith(color: AppTheme.error),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Please fill in plate details manually below.',
            style: AppTheme.bodyMd,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.labelLg.copyWith(
        color: AppTheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _VehicleTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryContainer.withValues(alpha: 0.15)
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryContainer : AppTheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.outline,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.labelSm.copyWith(
                  color: isSelected ? AppTheme.primary : AppTheme.outline,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntrySummaryCard extends StatelessWidget {
  final String plateText;
  final String vehicleType;
  final DateTime entryTime;

  const _EntrySummaryCard({
    required this.plateText,
    required this.vehicleType,
    required this.entryTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENTRY SUMMARY',
            style: AppTheme.labelSm.copyWith(
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.login_rounded,
                  color: AppTheme.statusInside, size: 16),
              const SizedBox(width: 8),
              Text(
                'Entry: NOW',
                style: AppTheme.labelLg.copyWith(color: AppTheme.statusInside),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.radio_button_checked_rounded,
                  color: AppTheme.statusInside, size: 14),
              const SizedBox(width: 8),
              Text('Status: INSIDE',
                  style: AppTheme.labelMd.copyWith(color: AppTheme.statusInside)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onRetake;

  const _BottomActionBar({
    required this.isSaving,
    required this.onSave,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: const Border(
          top: BorderSide(color: AppTheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onRetake,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('RETAKE'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppTheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(isSaving ? 'SAVING...' : 'SAVE TO LOG'),
            ),
          ),
        ],
      ),
    );
  }
}
