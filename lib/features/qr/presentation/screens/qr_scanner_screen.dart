import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../resources/presentation/providers/resource_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final TextEditingController _importController = TextEditingController();
  bool _isScanning = true;

  void _onDetect(String rawValue) {
    if (!_isScanning) return;
    if (rawValue.startsWith('linkvault:import')) {
      setState(() {
        _isScanning = false;
      });
      _processImport(rawValue);
    } else {
      _showError('Invalid LinkVault QR Code format.');
    }
  }

  void _processImport(String data) {
    try {
      final uri = Uri.parse(data);
      final title = uri.queryParameters['title'] ?? 'Imported Resource';
      final url = uri.queryParameters['url'] ?? '';
      final platform = uri.queryParameters['platform'] ?? 'Custom';
      final tagsStr = uri.queryParameters['tags'] ?? '';
      final tags = tagsStr.isEmpty ? <String>[] : tagsStr.split(',');

      if (url.isEmpty) {
        _showError('Invalid QR Code: URL is empty.');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Resource?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: $title', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('URL: $url'),
              const SizedBox(height: 8),
              Text('Platform: $platform'),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tags: ${tags.join(", ")}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isScanning = true;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<ResourceProvider>(context, listen: false).addResource(
                  title: title,
                  url: url,
                  platformType: platform,
                  tags: tags,
                  notes: '',
                );
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported "$title"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop(); // Go back from scanner
                }
              },
              child: const Text('Import'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Failed to parse QR Code: ${e.toString()}');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isScanning = true;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import QR Code'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Direct camera scanning requires NDK hardware compilation. You can simulate QR scanning by pasting raw QR content below!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Paste QR Code Content',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _importController,
              decoration: const InputDecoration(
                hintText: 'e.g., linkvault:import?url=https://flutter.dev&title=Flutter',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final text = _importController.text.trim();
                if (text.isNotEmpty) {
                  _onDetect(text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter QR code content'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Simulate QR Import'),
            ),
            const SizedBox(height: 32),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to construct QR Content:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Format: linkvault:import?url=URL&title=TITLE&platform=PLATFORM&tags=TAG1,TAG2',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
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
}
