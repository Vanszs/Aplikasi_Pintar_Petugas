import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../widgets/gradient_background.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  Future<List<File>>? _soundFiles;
  String? _selectedSound;

  @override
  void initState() {
    super.initState();
    _soundFiles = _loadSoundFiles();
    _loadSelectedSound();
  }

  Future<List<File>> _loadSoundFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${directory.path}/sounds');
    if (!await soundsDir.exists()) {
      await soundsDir.create();
    }
    return soundsDir.listSync().whereType<File>().toList();
  }

  Future<void> _loadSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSound = prefs.getString('notification_sound');
    });
  }

  Future<void> _pickAndSaveSound() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      final file = File(result.files.single.path!);
      final directory = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${directory.path}/sounds');
      final newPath = '${soundsDir.path}/${result.files.single.name}';
      await file.copy(newPath);
      setState(() {
        _soundFiles = _loadSoundFiles();
      });
    }
  }

  Future<void> _setSelectedSound(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', path);
    setState(() {
      _selectedSound = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: const [
          Color(0xFFEFF6FF),
          Color(0xFFEDE9FE),
          Color(0xFFFDF2F8),
          Color(0xFFF0F9FF),
        ],
        child: FutureBuilder<List<File>>(
          future: _soundFiles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading sounds'));
            }

            final files = snapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(
                    'Notification Sounds',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
                ),
                if (files.isEmpty)
                  SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/empty.json',
                                width: 200,
                                height: 200,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Belum ada sound yang diunggah',
                                style: GoogleFonts.inter(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _pickAndSaveSound,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Sound'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final file = files[index];
                          final fileName = file.path.split('/').last;
                          final isSelected = file.path == _selectedSound;

                          return Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                fileName,
                                style: GoogleFonts.inter(),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5))
                                  : null,
                              onTap: () => _setSelectedSound(file.path),
                            ),
                          );
                        },
                        childCount: files.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<List<File>>(
        future: _soundFiles,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return FloatingActionButton(
              onPressed: _pickAndSaveSound,
              backgroundColor: const Color(0xFF4F46E5),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}