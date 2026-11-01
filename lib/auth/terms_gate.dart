import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/auth_session.dart';
import '/backend/api_requests/api_config.dart';
import '/backend/api_requests/api_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/ui/zoc_ui.dart';

/// Checks the server version before mounting pages that can start monitoring.
/// No local version or acceptance cache: restored sessions use the same check.
class TermsGate extends StatefulWidget {
  const TermsGate({super.key, required this.child});

  final Widget child;

  @override
  State<TermsGate> createState() => _TermsGateState();
}

class _TermsGateState extends State<TermsGate> {
  Map? _status;
  bool _loading = true;
  bool _saving = false;
  bool _checked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<ApiCallResponse> _request({String? version}) =>
      ApiManager.instance.makeApiCall(
        callName: version == null ? 'TermsStatus' : 'AcceptTerms',
        apiUrl: '${getBaseApiUrl()}/api/v1/onboarding/'
            '${version == null ? 'status' : 'terms'}',
        callType: version == null ? ApiCallType.GET : ApiCallType.POST,
        headers: const {'Accept': 'application/json'},
        body: version == null ? null : jsonEncode({'version': version}),
        bodyType: version == null ? BodyType.NONE : BodyType.JSON,
        decodeUtf8: true,
      );

  Map _readStatus(ApiCallResponse response) {
    final data = response.jsonBody;
    if (!response.succeeded ||
        data is! Map ||
        data['terms_pending'] is! bool ||
        data['terms_version'] is! String ||
        (data['terms_version'] as String).isEmpty) {
      throw const FormatException('Invalid terms status');
    }
    if (data['terms_pending'] == true) {
      for (final key in ['terms_url', 'privacy_url']) {
        final uri = Uri.tryParse('${data[key]}');
        if (uri == null ||
            !['http', 'https'].contains(uri.scheme) ||
            uri.host.isEmpty) {
          throw const FormatException('Missing legal document URL');
        }
      }
    }
    return data;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _status = null;
      _checked = false;
      _error = null;
    });
    try {
      final status = _readStatus(await _request());
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Não foi possível carregar os termos. Verifique sua conexão e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept() async {
    if (!_checked || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await _request(version: _status!['terms_version']);
      if (!mounted) return;
      if (response.statusCode == 409) {
        await _load();
        if (mounted) {
          setState(() => _error =
              'Os termos foram atualizados. Leia a nova versão antes de aceitar.');
        }
        return;
      }
      final status = _readStatus(response);
      if (status['terms_pending'] != false) {
        throw const FormatException('Acceptance not confirmed');
      }
      setState(() => _status = status);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Não foi possível registrar o aceite. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openDocument(String key) async {
    try {
      if (await launchUrl(Uri.parse(_status![key]),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _error =
          'Não foi possível abrir o documento. Verifique seu navegador e tente novamente.');
    }
  }

  Future<void> _logout() async {
    GoRouter.of(context).prepareAuthEvent();
    GoRouter.of(context).clearRedirectLocation();
    await AuthSession.logout();
    FFAppState().UserData = null;
    FFAppState().email = '';
    FFAppState().password = '';
    FFAppState().isPopupVisible = false;
    FFAppState().dataSave = [];
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _status?['terms_pending'] == false) return widget.child;

    final status = _status;
    return PopScope(
      canPop: false,
      child: ZocAuthScaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZocTitle(
              'Termos de Uso e Privacidade',
              badge: status == null
                  ? null
                  : ZocBadge('Versão ${status['terms_version']}'),
              subtitle: status == null && !_loading
                  ? null
                  : 'Atualizamos nossos documentos. Leia e aceite para '
                      'continuar usando o ZOC.',
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: ZocColors.brand),
                  ),
                ),
              )
            else if (status != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _DocLink(
                      icon: Icons.description_outlined,
                      label: 'Termos de Uso',
                      onTap: () => _openDocument('terms_url'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DocLink(
                      icon: Icons.verified_user_outlined,
                      label: 'Política de Privacidade',
                      onTap: () => _openDocument('privacy_url'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ZocCheckRow(
                label: 'Li e aceito os Termos de Uso e a '
                    'Política de Privacidade.',
                value: _checked,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _checked = value),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              ZocNotice(_error!, kind: ZocNoticeKind.error),
            ],
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                ZocButton(
                  'Sair',
                  variant: ZocButtonVariant.ghost,
                  onPressed: _saving ? null : _logout,
                ),
                if (!_loading && status == null)
                  ZocButton('Tentar novamente',
                      icon: Icons.refresh_rounded, onPressed: _load)
                else
                  ZocButton(
                    _saving ? 'Salvando...' : 'Aceitar e continuar',
                    loading: _saving,
                    onPressed:
                        !_loading && _checked && !_saving ? _accept : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Link card that opens a legal document in the browser.
class _DocLink extends StatelessWidget {
  const _DocLink(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ZocRadii.item);
    return Material(
      color: ZocColors.surface2,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 17, color: ZocColors.brand),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(label,
                      style: ZocText.strong().copyWith(fontSize: 13))),
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new_rounded,
                  size: 15, color: ZocColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}
