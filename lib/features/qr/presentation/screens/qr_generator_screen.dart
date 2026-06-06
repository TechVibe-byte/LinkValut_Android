import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../resources/data/models/resource_model.dart';

class QrGeneratorScreen extends StatelessWidget {
  final ResourceModel resource;

  const QrGeneratorScreen({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = 'linkvault:import?title=${Uri.encodeComponent(resource.title)}&url=${Uri.encodeComponent(resource.url)}&platform=${Uri.encodeComponent(resource.platformType)}&tags=${Uri.encodeComponent(resource.tags.join(","))}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share via QR'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                resource.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                resource.platformType,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 260.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Let another device scan this QR code to quickly import this resource into their LinkVault app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
