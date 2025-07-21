import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/jenis_laporan_provider.dart';
import '../widgets/gradient_background.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  bool _useAccountData = true;
  final _formKey = GlobalKey<FormState>();
  
  final _addressController = TextEditingController();
  final _customJenisLaporanController = TextEditingController();
  
  String _selectedJenisLaporan = 'kemalingan';
  String _selectedRW = '01'; // Memastikan ini adalah format dengan awalan nol
  List<String> _jenisLaporanOptions = ['kemalingan', 'kebakaran', 'tawuran', 'lainnya'];
  // Format dengan awalan nol untuk angka 1-9
  final List<String> _rwOptions = List.generate(14, (index) => index < 9 ? '0${index + 1}' : '${index + 1}');
  
  bool _isSubmitting = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadJenisLaporan();
    });
  }
  
  Future<void> _loadJenisLaporan() async {
    await ref.read(jenisLaporanProvider.notifier).loadJenisLaporan();
    final jenisLaporanState = ref.read(jenisLaporanProvider);
    if (jenisLaporanState.jenisLaporanList.isNotEmpty) {
      setState(() {
        _jenisLaporanOptions = ref.read(jenisLaporanProvider.notifier).getJenisLaporanOptions();
        // Set default to first option if current selection is not available
        if (!_jenisLaporanOptions.contains(_selectedJenisLaporan)) {
          _selectedJenisLaporan = _jenisLaporanOptions.first;
        }
      });
    }
  }
  
  void _loadUserData() {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user != null) {
      _addressController.text = user.address;
    }
  }
  
  @override
  void dispose() {
    _addressController.dispose();
    _customJenisLaporanController.dispose();
    super.dispose();
  }
  
  Future<void> _submitReport() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      
      try {
        final reportNotifier = ref.read(reportProvider.notifier);
        
        // Get final jenis laporan value
        String jenisLaporan = _selectedJenisLaporan;
        if (_selectedJenisLaporan == 'lainnya' && _customJenisLaporanController.text.isNotEmpty) {
          jenisLaporan = _customJenisLaporanController.text;
        }
        
        // Custom address only if not using account data
        String? customAddress;
        if (!_useAccountData) {
          // Memastikan RW dalam format yang benar (dengan awalan nol jika perlu)
          customAddress = '${_addressController.text} RW $_selectedRW';
        }
        
        // Debug what data is being sent
        print('Submitting report with useAccountData=$_useAccountData');
        print('Jenis Laporan: $jenisLaporan');
        if (!_useAccountData) {
          print('Custom address: $customAddress');
        }
        
        final result = await reportNotifier.sendReport(
          address: !_useAccountData ? customAddress : null,
          jenisLaporan: jenisLaporan,
          useAccountData: _useAccountData
        );
        
        if (result) {
          if (mounted) {
            _showSuccessDialog();
          }
        } else {
          final reportState = ref.read(reportProvider);
          setState(() {
            _errorMessage = reportState.errorMessage ?? 'Gagal mengirim laporan';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 12),
              Text(
                'Berhasil',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: Text(
            'Laporan berhasil dikirim. Petugas akan segera merespons.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final topSafePadding = MediaQuery.of(context).padding.top;
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    // Show loading state if no user data
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: GradientBackground(
        colors: const [
          Color(0xFFEFF6FF),  // Light blue
          Color(0xFFFDF2F8),  // Light pink
        ],
        child: Column(
          children: [
            // Solid top safe area
            Container(
              height: topSafePadding,
              color: const Color(0xFFEFF6FF),
            ),
            
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
                    ),
                    iconSize: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Buat Laporan',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Use Account Data Switch
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gunakan Alamat dari Akun',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Laporan akan menggunakan alamat dari profil Anda',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: _useAccountData,
                                      onChanged: (value) {
                                        setState(() {
                                          _useAccountData = value;
                                        });
                                      },
                                      activeColor: const Color(0xFF6366F1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Nama dan nomor telepon akan selalu menggunakan data akun Anda',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                          
                          const SizedBox(height: 24),
                          
                          // Jenis Laporan Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jenis Laporan',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Jenis Laporan Dropdown
                                DropdownButtonFormField<String>(
                                  value: _selectedJenisLaporan,
                                  decoration: InputDecoration(
                                    labelText: 'Pilih Jenis Laporan',
                                    labelStyle: GoogleFonts.inter(
                                      color: const Color(0xFF6B7280),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.report_outlined,
                                      color: Color(0xFF6366F1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                  items: _jenisLaporanOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value[0].toUpperCase() + value.substring(1)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedJenisLaporan = newValue;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Jenis laporan harus dipilih';
                                    }
                                    return null;
                                  },
                                ),
                                
                                // Custom Jenis Laporan field (when 'lainnya' is selected)
                                if (_selectedJenisLaporan == 'lainnya') ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _customJenisLaporanController,
                                    decoration: InputDecoration(
                                      labelText: 'Jenis Laporan Lainnya',
                                      labelStyle: GoogleFonts.inter(
                                        color: const Color(0xFF6B7280),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF6366F1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (_selectedJenisLaporan == 'lainnya' && 
                                          (value == null || value.isEmpty)) {
                                        return 'Jenis laporan tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                          
                          const SizedBox(height: 24),
                          
                          // Custom Address Form (only if not using account data)
                          if (!_useAccountData)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alamat Laporan',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Address Field and RW dropdown in one row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Address text field (larger part)
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: _addressController,
                                          decoration: InputDecoration(
                                            labelText: 'Alamat',
                                            labelStyle: GoogleFonts.inter(
                                              color: const Color(0xFF6B7280),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.location_on_outlined,
                                              color: Color(0xFFEC4899),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF6366F1),
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (!_useAccountData && (value == null || value.isEmpty)) {
                                              return 'Alamat tidak boleh kosong';
                                            }
                                            return null;
                                          },
                                          maxLines: 2,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // RW Dropdown (smaller part)
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade400),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Center(
                                            child: DropdownButton<String>(
                                              value: _selectedRW,
                                              isExpanded: true,
                                              underline: Container(),
                                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                                              hint: Text(
                                                'RW',
                                                style: GoogleFonts.inter(
                                                  color: const Color(0xFF6B7280),
                                                ),
                                              ),
                                              items: _rwOptions.map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  // Memastikan RW ditampilkan dengan format yang benar
                                                  child: Text('RW $value'),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setState(() {
                                                    _selectedRW = newValue;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                          
                          if (!_useAccountData)
                            const SizedBox(height: 24),
                          
                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF87171),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFF87171),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 500.ms),
                          
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Kirim Laporan',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
                          
                          SizedBox(height: 20 + bottomSafePadding),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Solid bottom safe area
            Container(
              height: bottomSafePadding,
              color: const Color(0xFFF0F9FF),
            ),
          ],
        ),
      ),
    );
  }
}
