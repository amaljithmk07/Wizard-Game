import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/socket_service.dart';
import '../../providers/player_provider.dart';
import '../server_list/server_list_screen.dart';

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialName = ref.read(playerNameProvider);
    _controller = TextEditingController(
      text: initialName.toLowerCase() == 'amal' ? '' : initialName,
    );

    // Initialize socket connection only if NOT in Demo Mode
    if (!AppConfig.isDemoMode) {
      SocketService().connect();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    ref.read(playerNameProvider.notifier).setName(name);

    if (!AppConfig.isDemoMode) {
      SocketService().emit('set_player_name', {'name': name});
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ServerListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              // Cards Logo Icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F5F9),
                ),
                child: const Icon(
                  Icons.style_outlined,
                  size: 48,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'WIZARD',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A simple card game\nfor friends',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),

              const Spacer(),

              // Input Field Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter your name',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your name (e.g. Player 1)',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel,
                                color: Color(0xFF94A3B8), size: 20),
                            onPressed: () {
                              setState(() {
                                _controller.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() {}),
                  onSubmitted: (_) => _onContinue(),
                ),
              ),
              const SizedBox(height: 20),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _controller.text.trim().isNotEmpty ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
