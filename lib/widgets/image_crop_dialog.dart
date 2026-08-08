import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

String getFullImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final clean = url.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://') || clean.startsWith('data:')) {
    return clean;
  }
  const apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000/api');
  final serverBase = apiBase.replaceAll('/api', '');
  return '$serverBase${clean.startsWith('/') ? '' : '/'}$clean';
}

class CropImageDialog extends StatefulWidget {
  const CropImageDialog({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
  final CropController _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: size.width < 540 ? size.width * 0.9 : 500,
        height: size.height < 600 ? size.height * 0.85 : 560,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Crop Avatar Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Crop Box Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  aspectRatio: 1.0,
                  withCircleUi: true,
                  onCropped: (croppedBytes) {
                    Navigator.pop(context, croppedBytes);
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            // Dialog Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isCropping
                        ? null
                        : () {
                            setState(() => _isCropping = true);
                            _cropController.crop();
                          },
                    icon: _isCropping
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.crop, size: 18),
                    label: const Text('Crop & Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
