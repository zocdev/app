import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/auth_session.dart';
import '/backend/api_requests/api_config.dart';
import '/backend/api_requests/api_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';

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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Termos de Uso e Política de Privacidade',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_status != null) ...[
                      Text('Publicamos a versão ${_status!['terms_version']}. '
                          'Para continuar usando o ZOC, leia e aceite os documentos.'),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => _openDocument('terms_url'),
                            child: const Text('Termos de Uso'),
                          ),
                          TextButton(
                            onPressed: () => _openDocument('privacy_url'),
                            child: const Text('Política de Privacidade'),
                          ),
                        ],
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Li e aceito os Termos de Uso e a '
                            'Política de Privacidade.'),
                        value: _checked,
                        onChanged: _saving
                            ? null
                            : (value) =>
                                setState(() => _checked = value == true),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: const TextStyle(color: Color(0xFFB42318))),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: _saving ? null : _logout,
                          child: const Text('Sair'),
                        ),
                        if (!_loading && _status == null)
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Tentar novamente'),
                          )
                        else
                          ElevatedButton(
                            onPressed: !_loading && _checked && !_saving
                                ? _accept
                                : null,
                            child: Text(_saving
                                ? 'Salvando...'
                                : 'Aceitar e continuar'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
