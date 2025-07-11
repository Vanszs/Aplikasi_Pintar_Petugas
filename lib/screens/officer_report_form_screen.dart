import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';
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
  final _customJenisLaporanController = TextEditingController();
  
  String _selectedJenisLaporan = 'kemalingan';
  String _selectedRW = '01';
  final List<String> _jenisLaporanOptions = ['kemalingan', 'kebakaran', 'tawuran', 'lainnya'];
  // Format dengan awalan nol untuk angka 1-9
  final List<String> _rwOptions = List.generate(14, (index) => index < 9 ? '0${index + 1}' : '${index + 1}');
  
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isSirine = false;
  
  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _customJenisLaporanController.dispose();
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
      final authState = ref.read(authProvider);
      final user = authState.user;
      final userName = user?.name ?? 'Petugas';
      debugPrint('Auth state: isAuthenticated=${authState.isAuthenticated}, user=${user?.toJson()}');
      debugPrint('Sending report with name: $userName');
      
      final success = await ref.read(reportProvider.notifier).sendPetugasReport(
        name: userName,
        address: _addressController.text,
        phone: phoneNumber,
        jenisLaporan: jenisLaporan,
        rwNumber: _selectedRW,
        isSirine: _isSirine,
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
            Padding(
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
                            color: Colors.black.withOpacity(0.05),
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
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        _buildHeaderCard().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),
                        
                        // Form Sections
                        _buildModernJenisLaporanSection().animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 20),
                        _buildModernAddressSection().animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 20),
                        _buildModernPhoneSection().animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 20),
                        _buildModernRWSelector().animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 20),
                        _buildSirineToggle().animate(delay: 450.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 32),
                        
                        // Error Message
                        if (_errorMessage != null) 
                          _buildModernErrorMessage().animate().fadeIn(duration: 300.ms),
                        
                        // Submit Button
                        _buildModernSubmitButton().animate(delay: 500.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                        SizedBox(height: bottomSafePadding + 20),
                      ],
                    ),
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

  // Modern UI Components
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.report_outlined,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporkan Kejadian',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Isi formulir dengan lengkap untuk penanganan optimal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernJenisLaporanSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Jenis Laporan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          ...(_jenisLaporanOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isLast = index == _jenisLaporanOptions.length - 1;
            
            return Container(
              decoration: BoxDecoration(
                border: !isLast ? Border(bottom: BorderSide(color: Colors.grey[100]!)) : null,
              ),
              child: RadioListTile<String>(
                title: Text(
                  option == 'lainnya' ? 'Lainnya' : option[0].toUpperCase() + option.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: _selectedJenisLaporan == option ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedJenisLaporan == option ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                  ),
                ),
                value: option,
                groupValue: _selectedJenisLaporan,
                activeColor: const Color(0xFF6366F1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedJenisLaporan = value;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            );
          }).toList()),
          if (_selectedJenisLaporan == 'lainnya')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: TextFormField(
                controller: _customJenisLaporanController,
                decoration: InputDecoration(
                  labelText: 'Jenis Laporan Lainnya',
                  hintText: 'Masukkan jenis laporan',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
                ),
                validator: (value) {
                  if (_selectedJenisLaporan == 'lainnya' && (value == null || value.isEmpty)) {
                    return 'Jenis laporan harus diisi';
                  }
                  return null;
                },
              ),
            ),
          if (_selectedJenisLaporan != 'lainnya') const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModernAddressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Alamat Kejadian',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Alamat Lengkap',
              hintText: 'Masukkan alamat kejadian dengan detail...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              prefixIcon: const Icon(Icons.home_outlined, color: Color(0xFF6366F1)),
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
        ],
      ),
    );
  }

  Widget _buildModernPhoneSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Nomor Telepon',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Nomor Telepon',
              hintText: 'Masukkan nomor telepon aktif',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '+62',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
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
      ),
    );
  }

  Widget _buildModernRWSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_work_outlined,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'RW Kejadian',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRW,
                isExpanded: true,
                menuMaxHeight: 250,
                itemHeight: 48,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6366F1)),
                items: _rwOptions
                    .map((rw) => DropdownMenuItem(
                          value: rw,
                          child: Text(
                            'RW $rw',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedRW = value;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSirineToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.speaker, color: _isSirine ? Color(0xFFEF4444) : Color(0xFF6366F1), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aktifkan Sirine', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text('Nyalakan sirine saat laporan dikirim', style: GoogleFonts.inter(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Switch(
              key: ValueKey(_isSirine),
              value: _isSirine,
              activeColor: Color(0xFFEF4444),
              inactiveThumbColor: Color(0xFF6366F1),
              onChanged: (val) {
                setState(() => _isSirine = val);
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isSubmitting 
          ? LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade500],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
        boxShadow: _isSubmitting ? [] : [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSubmitting ? null : _submitReport,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Mengirim Laporan...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Kirim Laporan',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
