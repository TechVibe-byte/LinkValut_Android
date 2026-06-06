import 'package:flutter/material.dart';
import 'auth_helper.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final List<String> _enteredPin = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (AuthHelper.isBiometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometrically();
      });
    }
  }

  void _authenticateBiometrically() async {
    final success = await AuthHelper.authenticateBiometrically();
    if (success) {
      widget.onUnlocked();
    }
  }

  void _onKeyPress(String value) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(value);
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    final enteredString = _enteredPin.join();
    final savedPin = AuthHelper.savedPin;

    if (enteredString == savedPin) {
      widget.onUnlocked();
    } else {
      setState(() {
        _enteredPin.clear();
        _errorMessage = "Incorrect PIN. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Enter PIN to unlock',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Pin indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final hasValue = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasValue ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            const Spacer(),
            // Numeric Keypad
            _buildKeypad(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((val) => _buildKeypadButton(val, theme)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AuthHelper.isBiometricEnabled
                ? IconButton(
                    icon: Icon(Icons.fingerprint, size: 28, color: theme.colorScheme.primary),
                    onPressed: _authenticateBiometrically,
                  )
                : const SizedBox(width: 64),
            _buildKeypadButton('0', theme),
            IconButton(
              icon: const Icon(Icons.backspace_outlined, size: 24),
              onPressed: _onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String label, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(12),
      width: 64,
      height: 64,
      child: OutlinedButton(
        onPressed: () => _onKeyPress(label),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
