import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/report_provider.dart';
import '../widgets/gradient_background.dart';

class OfficerReportFormScreen extends ConsumerStatefulWidget {
  const OfficerReportFormScreen({super.key});

  @override
  ConsumerState<OfficerReportFormScreen> createState() => _OfficerReportFormScreenState();
}

class _OfficerReportFormScreenState extends ConsumerState<OfficerReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailController = TextEditingController();
  final _customJenisLaporanController = TextEditingController();
  final _reporterNameController = TextEditingController();
  
  String _selectedJenisLaporan = 'kemalingan';
  String _selectedRW = '01';
  final List<String> _jenisLaporanOptions = ['kemalingan', 'kebakaran', 'tawuran', 'lainnya'];
  // Format dengan awalan nol untuk angka 1-9
  final List<String> _rwOptions = List.generate(14, (index) => index < 9 ? '0${index + 1}' : '${index + 1}');
  
  bool _isSubmitting = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _detailController.dispose();
    _customJenisLaporanController.dispose();
    _reporterNameController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    // Hide keyboard first for better UX
    FocusManager.instance.primaryFocus?.unfocus();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final String jenisLaporan = _selectedJenisLaporan == 'lainnya'
          ? _customJenisLaporanController.text
          : _selectedJenisLaporan;
      
      // Make sure phone number is properly formatted (remove any prefix if user added it)
      String phoneNumber = _phoneController.text.trim();
      if (phoneNumber.startsWith('+62')) {
        phoneNumber = phoneNumber.substring(3);
      } else if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
      
      // Show debug logs to check values before sending
      debugPrint('Sending report with name: ${_reporterNameController.text}');
      debugPrint('Sending report with detail: ${_detailController.text}');
      
      final success = await ref.read(reportProvider.notifier).sendPetugasReport(
        name: _reporterNameController.text,
        address: _addressController.text,
        phone: phoneNumber,
        jenisLaporan: jenisLaporan,
        detailLaporan: _detailController.text,
        rwNumber: _selectedRW,
      );
      
      if (!mounted) return;
      
      if (success) {
        // Success animation before popping
        setState(() {
          _isSubmitting = false;
        });
        
        // Show success dialog with animation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  size: 72,
                ).animate().scale(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                ),
                const SizedBox(height: 16),
                Text(
                  'Laporan Terkirim',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Laporan anda berhasil dikirim dan akan segera diproses.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Return to previous screen
                },
                child: Text(
                  'Kembali',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = ref.read(reportProvider).errorMessage ?? 'Gagal mengirim laporan';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access bottom and top safe area padding for proper layout
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    final topSafePadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: GradientBackground(
        colors: const [
          Color(0xFFEFF6FF),  // Light blue
          Color(0xFFEDE9FE),  // Light purple
          Color(0xFFFDF2F8),  // Light pink
          Color(0xFFF0F9FF),  // Lightest blue
        ],
        child: Column(
          children: [
            // Top safe area
            Container(
              height: topSafePadding,
              color: const Color(0xFFEFF6FF),
            ),
            // Custom app bar
            _buildAppBar(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      _buildReporterNameSection().animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      _buildJenisLaporanSection().animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      _buildAddressSection().animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      _buildPhoneSection().animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      _buildDetailSection().animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      _buildRWSelector().animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      _buildNameSection().animate(delay: 700.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 32),
                      if (_errorMessage != null) _buildErrorMessage().animate().fadeIn(duration: 300.ms),
                      _buildSubmitButton().animate(delay: 800.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom safe area
            Container(
              height: bottomSafePadding,
              color: const Color(0xFFF0F9FF),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Buat Laporan Petugas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Laporkan Kejadian',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan data laporan secara lengkap untuk penanganan lebih cepat.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildJenisLaporanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Laporan',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: _jenisLaporanOptions.map((option) {
              return RadioListTile<String>(
                title: Text(
                  option == 'lainnya' 
                      ? 'Lainnya' 
                      : option[0].toUpperCase() + option.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: _selectedJenisLaporan == option 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
                value: option,
                groupValue: _selectedJenisLaporan,
                activeColor: const Color(0xFF6366F1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onChanged: (value) {
                  if (value == null) return;
                  
                  setState(() {
                    _selectedJenisLaporan = value;
                  });
                  
                  // Add haptic feedback
                  HapticFeedback.selectionClick();
                },
              );
            }).toList(),
          ),
        ),
        if (_selectedJenisLaporan == 'lainnya')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextFormField(
              controller: _customJenisLaporanController,
              decoration: InputDecoration(
                labelText: 'Jenis Laporan Lainnya',
                hintText: 'Masukkan jenis laporan',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              validator: (value) {
                if (_selectedJenisLaporan == 'lainnya' && (value == null || value.isEmpty)) {
                  return 'Jenis laporan harus diisi';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alamat Kejadian',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Alamat Lengkap',
              hintText: 'Masukkan alamat kejadian',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF6366F1)),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat harus diisi';
              }
              return null;
            },
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nomor Telepon',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Nomor Telepon',
            hintText: 'Masukkan nomor telepon',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF6366F1)),
            prefixText: '+62 ',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nomor telepon harus diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Kejadian',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailController,
          decoration: InputDecoration(
            labelText: 'Detail Kejadian',
            hintText: 'Jelaskan detail kejadian',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF6366F1)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Detail kejadian harus diisi';
            }
            return null;
          },
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildRWSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RW Kejadian',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.home_work_outlined, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRW,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6366F1)),
                    items: _rwOptions
                        .map((rw) => DropdownMenuItem(
                              value: rw,
                              child: Text(
                                'RW $rw',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ))
                        .toList(),                                  onChanged: (value) {
                      if (value == null) return;
                      
                      setState(() {
                        _selectedRW = value;
                      });
                      
                      // Add haptic feedback
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Pelapor',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reporterNameController,
          decoration: InputDecoration(
            labelText: 'Nama Lengkap',
            hintText: 'Masukkan nama pelapor',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6366F1)),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama pelapor harus diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReporterNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Pelapor',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reporterNameController,
          decoration: InputDecoration(
            labelText: 'Nama Pelapor',
            hintText: 'Masukkan nama pelapor',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            prefixIcon: const Icon(Icons.person_outlined, color: Color(0xFF6366F1)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama pelapor harus diisi';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(100)),
      ),
      child: Text(
        _errorMessage ?? '',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.red[800],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: const Color(0xFF6366F1).withAlpha(150),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mengirim...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded),
                  const SizedBox(width: 12),
                  Text(
                    'Kirim Laporan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .shimmer(delay: 1000.ms, duration: 1500.ms, color: Colors.white24);
  }
}
