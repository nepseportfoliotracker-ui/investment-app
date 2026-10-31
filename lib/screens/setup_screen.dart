import 'package:flutter/material.dart';

import '../api.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, this.initial, required this.onSaved});

  final HubConfig? initial;
  final ValueChanged<HubConfig> onSaved;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _url = TextEditingController(
    text: widget.initial?.url ?? 'http://',
  );
  late final _token = TextEditingController(text: widget.initial?.token ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final config = HubConfig(url: _url.text.trim(), token: _token.text.trim());
    try {
      await HubApi.health(config.url);
      await HubApi(config).portfolio();
      await config.save();
      if (!mounted) return;
      widget.onSaved(config);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to hub')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Enter the address of the investment hub and its access token. '
                'On the same Wi-Fi use the PC address, e.g. http://192.168.1.20:8080. '
                'Otherwise use the server address.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Hub URL',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || !v.trim().startsWith('http'))
                    ? 'Must start with http:// or https://'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _token,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Access token',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
