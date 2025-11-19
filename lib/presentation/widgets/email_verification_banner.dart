import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../injection_container.dart' as di;

class EmailVerificationBanner extends StatefulWidget {
  final bool isEmailVerified;
  final String? userEmail;

  const EmailVerificationBanner({
    super.key,
    required this.isEmailVerified,
    this.userEmail,
  });

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isResending = false;
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    // Don't show banner if email is verified or dismissed
    if (widget.isEmailVerified || _isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        border: Border.all(
          color: const Color(0xFFFFB84D),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF8C00),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Email Belum Terverifikasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _isDismissed = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Verifikasi email lo buat akses penuh semua fitur${widget.userEmail != null ? ' di ${widget.userEmail}' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isResending ? null : _resendVerificationEmail,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF8C00),
                side: const BorderSide(color: Color(0xFFFF8C00)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isResending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
                      ),
                    )
                  : const Text(
                      'Kirim Ulang Email Verifikasi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final authDataSource = di.sl<AuthRemoteDataSource>();
      await authDataSource.resendVerificationEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verifikasi udah dikirim! Cek inbox lo ya 📧'),
            backgroundColor: Color(0xFF84994F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gagal kirim email verifikasi';

        if (e.toString().contains('timeout')) {
          errorMessage = 'Koneksi timeout. Coba lagi ya';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Sesi lo udah expired. Login ulang dulu';
        } else if (e.toString().contains('429')) {
          errorMessage = 'Terlalu banyak request. Tunggu sebentar ya';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }
}
