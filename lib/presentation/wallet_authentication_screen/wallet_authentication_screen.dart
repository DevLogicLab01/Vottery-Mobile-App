import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/wallet_connection_service.dart';

class WalletAuthenticationScreen extends StatefulWidget {
  const WalletAuthenticationScreen({super.key});

  @override
  State<WalletAuthenticationScreen> createState() =>
      _WalletAuthenticationScreenState();
}

class _WalletAuthenticationScreenState extends State<WalletAuthenticationScreen>
    with SingleTickerProviderStateMixin {
  final WalletConnectionService _walletService =
      WalletConnectionService.instance;

  WalletConnectionStatus _connectionStatus =
      WalletConnectionStatus.disconnected;
  String? _statusMessage;
  String? _errorMessage;
  String? _wcUri;
  bool _isConnecting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initWallet();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initWallet() async {
    await _walletService.initialize();
    if (mounted) {
      setState(() {
        _connectionStatus = _walletService.status;
      });
    }
  }

  Future<void> _connectWallet(String walletId) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _statusMessage = null;
      _wcUri = null;
    });

    Map<String, dynamic> result;

    switch (walletId) {
      case 'metamask':
        result = await _walletService.connectMetaMask();
        break;
      case 'walletconnect':
        result = await _walletService.connectWalletConnect();
        _wcUri = result['wc_uri'];
        break;
      case 'coinbase':
        result = await _walletService.connectCoinbaseWallet();
        break;
      default:
        result = await _walletService.connectMetaMask();
    }

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _connectionStatus = WalletConnectionStatus.connecting;
        _statusMessage = result['message'] ?? 'Awaiting wallet approval...';
        _isConnecting = false;
      });

      // Simulate completing connection for demo (in production: handle callback)
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await _walletService.completeConnection(
          address: '0x742d35Cc6634C0532925a3b8D4C9C3b5e2f1A8B2',
          walletType: walletId,
          chainId: 1,
        );
        setState(() {
          _connectionStatus = WalletConnectionStatus.connected;
          _statusMessage = 'Wallet connected successfully!';
        });
      }
    } else {
      setState(() {
        _connectionStatus = WalletConnectionStatus.failed;
        _errorMessage = result['error'] ?? 'Connection failed';
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    await _walletService.disconnect();
    if (mounted) {
      setState(() {
        _connectionStatus = WalletConnectionStatus.disconnected;
        _statusMessage = null;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Web3 Authentication',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _connectionStatus == WalletConnectionStatus.connected
          ? _buildConnectedView()
          : _buildConnectionView(),
    );
  }

  Widget _buildConnectionView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 2.h),
          _buildHeaderSection(),
          SizedBox(height: 3.h),
          if (_connectionStatus == WalletConnectionStatus.connecting)
            _buildConnectingState()
          else
            ..._buildWalletList(),
          SizedBox(height: 2.h),
          if (_errorMessage != null) _buildErrorCard(),
          SizedBox(height: 2.h),
          _buildSecurityNote(),
          SizedBox(height: 3.h),
          _buildAlternativeAuthSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withAlpha(102),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 10.w,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Connect Your Wallet',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Use your Web3 wallet as a decentralized\nalternative to email login',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWalletList() {
    final wallets = _walletService.getSupportedWallets();
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Choose your wallet',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ),
      SizedBox(height: 1.5.h),
      ...wallets.map((wallet) => _buildWalletCard(wallet)),
    ];
  }

  Widget _buildWalletCard(Map<String, dynamic> wallet) {
    final isMetaMask = wallet['id'] == 'metamask';
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isConnecting ? null : () => _connectWallet(wallet['id']),
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isMetaMask
                    ? const Color(0xFF6C63FF).withAlpha(128)
                    : const Color(0xFF2A2A3E),
                width: isMetaMask ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252540),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      wallet['icon'],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_balance_wallet,
                        color: const Color(0xFF6C63FF),
                        size: 6.w,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            wallet['name'],
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (isMetaMask) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withAlpha(51),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                'Popular',
                                style: GoogleFonts.inter(
                                  fontSize: 8.sp,
                                  color: const Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        wallet['description'],
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 4.w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingState() {
    return Column(
      children: [
        SizedBox(height: 2.h),
        const CircularProgressIndicator(
          color: Color(0xFF6C63FF),
          strokeWidth: 3,
        ),
        SizedBox(height: 2.h),
        Text(
          _statusMessage ?? 'Connecting...',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white70),
        ),
        if (_wcUri != null) ...[SizedBox(height: 2.h), _buildWCUriCard()],
        SizedBox(height: 2.h),
        TextButton(
          onPressed: () {
            setState(() {
              _connectionStatus = WalletConnectionStatus.disconnected;
              _statusMessage = null;
            });
          },
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white38),
          ),
        ),
      ],
    );
  }

  Widget _buildWCUriCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF3B82F6).withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            'WalletConnect URI',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _wcUri ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              color: Colors.white38,
            ),
          ),
          SizedBox(height: 1.h),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _wcUri ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URI copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.copy, color: Color(0xFF3B82F6), size: 16),
                SizedBox(width: 1.w),
                Text(
                  'Copy URI',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF38BA8).withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFF38BA8).withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF38BA8), size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage ?? 'Connection failed',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFFF38BA8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFA6E3A1), size: 18),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Non-custodial & Secure',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA6E3A1),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'We never store your private keys. Authentication uses cryptographic signatures only.',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.white38,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeAuthSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF2A2A3E))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text(
                'or continue with',
                style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white30),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFF2A2A3E))),
          ],
        ),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.email_outlined,
            color: Colors.white54,
            size: 18,
          ),
          label: Text(
            'Email / Password Login',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white54),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2A2A3E)),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedView() {
    final account = _walletService.connectedAccount;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: Column(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFA6E3A1), Color(0xFF3B82F6)],
              ),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 10.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Wallet Connected',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFA6E3A1).withAlpha(77)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Address', account?.shortAddress ?? '—'),
                Divider(color: Colors.white.withAlpha(13), height: 2.h),
                _buildInfoRow(
                  'Wallet',
                  account?.walletType.toUpperCase() ?? '—',
                ),
                Divider(color: Colors.white.withAlpha(13), height: 2.h),
                _buildInfoRow(
                  'Network',
                  _walletService.getChainName(account?.chainId ?? 1),
                ),
                Divider(color: Colors.white.withAlpha(13), height: 2.h),
                _buildInfoRow(
                  'Connected',
                  account != null
                      ? '${DateTime.now().difference(account.connectedAt).inMinutes}m ago'
                      : '—',
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Continue to Vottery',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          TextButton(
            onPressed: _disconnect,
            child: Text(
              'Disconnect Wallet',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFFF38BA8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white38),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}