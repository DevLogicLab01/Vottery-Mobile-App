import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/enterprise_operations_service.dart';
import '../../widgets/custom_app_bar.dart';

class EnterpriseOperationsCenter extends StatefulWidget {
  const EnterpriseOperationsCenter({super.key});

  @override
  State<EnterpriseOperationsCenter> createState() =>
      _EnterpriseOperationsCenterState();
}

class _EnterpriseOperationsCenterState extends State<EnterpriseOperationsCenter> {
  static const List<String> _ssoProviders = <String>[
    'okta',
    'azure_ad',
    'saml2',
    'google',
    'google_workspace',
    'facebook',
    'apple',
  ];

  final _service = EnterpriseOperationsService.instance;

  String _tenantId = 'default-enterprise-tenant';
  bool _working = false;
  String _status = '';

  final _whiteLabelDomain = TextEditingController();
  final _whiteLabelBrand = TextEditingController(text: 'Vottery Enterprise');
  final _whiteLabelColor = TextEditingController(text: '#4f46e5');

  final _ssoProvider = TextEditingController(text: 'okta');
  final _ssoClientId = TextEditingController();
  final _ssoIssuer = TextEditingController();
  final _ssoSamlEntry = TextEditingController();

  final _bulkCsv = TextEditingController(
    text:
        'title,description,category\nQ2 Board Vote,Quarterly board decision,governance',
  );

  final _pricingDiscount = TextEditingController(text: '0');
  final _pricingVpDiscount = TextEditingController(text: '0');
  final _pricingFlatFee = TextEditingController(text: '0');
  final _pricingTerms = TextEditingController();

  final _whatsAppTo = TextEditingController();
  final _whatsAppMessage = TextEditingController();

  @override
  void dispose() {
    _whiteLabelDomain.dispose();
    _whiteLabelBrand.dispose();
    _whiteLabelColor.dispose();
    _ssoProvider.dispose();
    _ssoClientId.dispose();
    _ssoIssuer.dispose();
    _ssoSamlEntry.dispose();
    _bulkCsv.dispose();
    _pricingDiscount.dispose();
    _pricingVpDiscount.dispose();
    _pricingFlatFee.dispose();
    _pricingTerms.dispose();
    _whatsAppTo.dispose();
    _whatsAppMessage.dispose();
    super.dispose();
  }

  Future<void> _run(String successMessage, Future<bool> Function() runner) async {
    setState(() {
      _working = true;
      _status = '';
    });
    try {
      final ok = await runner();
      setState(() => _status = ok ? successMessage : 'Failed to complete action.');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String? _validateSsoInputs() {
    final provider = _ssoProvider.text.trim().toLowerCase();
    if (provider.isEmpty) return 'Failed: SSO provider is required.';
    if (!_ssoProviders.contains(provider)) {
      return 'Failed: Unsupported provider "$provider".';
    }
    if ((provider == 'okta' || provider == 'azure_ad' || provider == 'saml2') &&
        _ssoIssuer.text.trim().isEmpty) {
      return 'Failed: Issuer/domain is required for $provider.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Enterprise Operations Center',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: TextEditingController(text: _tenantId),
                onChanged: (v) => _tenantId = v,
                decoration: const InputDecoration(
                  labelText: 'Tenant ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'White-Label'),
                Tab(text: 'SSO'),
                Tab(text: 'Bulk Elections'),
                Tab(text: 'Pricing'),
                Tab(text: 'WhatsApp'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _whiteLabelTab(),
                  _ssoTab(),
                  _bulkTab(),
                  _pricingTab(),
                  _whatsAppTab(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                _status.isEmpty ? 'No operation yet.' : _status,
                style: TextStyle(
                  color: _status.toLowerCase().startsWith('failed')
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whiteLabelTab() {
    return _formCard([
      _field(_whiteLabelDomain, 'Custom Domain'),
      _field(_whiteLabelBrand, 'Brand Name'),
      _field(_whiteLabelColor, 'Primary Color'),
      _button('Save White-Label Config', () {
        _run('White-label configuration saved.', () async {
          final res = await _service.saveWhiteLabelConfig(
            tenantId: _tenantId,
            customDomain: _whiteLabelDomain.text.trim(),
            brandName: _whiteLabelBrand.text.trim(),
            primaryColor: _whiteLabelColor.text.trim(),
            hideVotteryBranding: true,
          );
          return res != null;
        });
      }),
    ]);
  }

  Widget _ssoTab() {
    return _formCard([
      DropdownButtonFormField<String>(
        value: _ssoProvider.text.trim().toLowerCase(),
        decoration: const InputDecoration(
          labelText: 'Provider',
          border: OutlineInputBorder(),
        ),
        items: _ssoProviders
            .map((provider) =>
                DropdownMenuItem<String>(value: provider, child: Text(provider)))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          _ssoProvider.text = value;
        },
      ),
      _field(_ssoClientId, 'Client ID'),
      _field(_ssoIssuer, 'Issuer URL'),
      _field(_ssoSamlEntry, 'SAML Entry Point'),
      _button('Save Enterprise SSO', () {
        final validationError = _validateSsoInputs();
        if (validationError != null) {
          setState(() => _status = validationError);
          return;
        }
        _run('SSO configuration saved.', () async {
          final res = await _service.saveSsoConfig(
            tenantId: _tenantId,
            provider: _ssoProvider.text.trim().toLowerCase(),
            clientId: _ssoClientId.text.trim(),
            issuer: _ssoIssuer.text.trim(),
            samlEntryPoint: _ssoSamlEntry.text.trim(),
            enabled: true,
          );
          return res != null;
        });
      }),
      _button('Start Enterprise SSO Login', () {
        final validationError = _validateSsoInputs();
        if (validationError != null) {
          setState(() => _status = validationError);
          return;
        }
        _run('Redirected to enterprise SSO login.', () async {
          return _service.initiateEnterpriseSso(
            provider: _ssoProvider.text.trim().toLowerCase(),
            issuerOrDomain: _ssoIssuer.text.trim(),
          );
        });
      }),
    ]);
  }

  Widget _bulkTab() {
    return _formCard([
      TextField(
        controller: _bulkCsv,
        minLines: 8,
        maxLines: 12,
        decoration: const InputDecoration(
          labelText: 'CSV',
          border: OutlineInputBorder(),
        ),
      ),
      _button('Create Elections from CSV', () {
        _run('Bulk election creation completed.', () async {
          final rows = await _service.createBulkElectionsFromCsv(
            csvText: _bulkCsv.text,
          );
          return rows.isNotEmpty;
        });
      }),
    ]);
  }

  Widget _pricingTab() {
    return _formCard([
      _field(_pricingDiscount, 'Participation Discount %',
          keyboardType: TextInputType.number),
      _field(_pricingVpDiscount, 'Bulk VP Discount %',
          keyboardType: TextInputType.number),
      _field(_pricingFlatFee, 'Flat Fee Unlimited Elections',
          keyboardType: TextInputType.number),
      _field(_pricingTerms, 'License Terms'),
      _button('Save Pricing Model', () {
        _run('Pricing model saved.', () async {
          final res = await _service.saveVolumePricing(
            tenantId: _tenantId,
            participationDiscountPercent:
                num.tryParse(_pricingDiscount.text.trim()) ?? 0,
            bulkVpDiscountPercent:
                num.tryParse(_pricingVpDiscount.text.trim()) ?? 0,
            flatFeeUnlimitedElections:
                num.tryParse(_pricingFlatFee.text.trim()) ?? 0,
            licenseTerms: _pricingTerms.text.trim(),
          );
          return res != null;
        });
      }),
    ]);
  }

  Widget _whatsAppTab() {
    return _formCard([
      _field(_whatsAppTo, 'Recipient (E.164)'),
      TextField(
        controller: _whatsAppMessage,
        minLines: 4,
        maxLines: 6,
        decoration: const InputDecoration(
          labelText: 'Message',
          border: OutlineInputBorder(),
        ),
      ),
      _button('Send WhatsApp', () {
        _run('WhatsApp message sent.', () async {
          return _service.sendWhatsAppNotification(
            to: _whatsAppTo.text.trim(),
            message: _whatsAppMessage.text.trim(),
          );
        });
      }),
    ]);
  }

  Widget _formCard(List<Widget> children) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .expand((w) => [w, SizedBox(height: 2.h)])
                .toList()
              ..removeLast(),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return FilledButton(
      onPressed: _working ? null : onPressed,
      child: _working
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

