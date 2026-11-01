import '/ui/zoc_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'not_ativities_model.dart';
export 'not_ativities_model.dart';

class NotAtivitiesWidget extends StatefulWidget {
  const NotAtivitiesWidget({super.key});

  @override
  State<NotAtivitiesWidget> createState() => _NotAtivitiesWidgetState();
}

class _NotAtivitiesWidgetState extends State<NotAtivitiesWidget> {
  late NotAtivitiesModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotAtivitiesModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZocHeroIcon(Icons.playlist_add_check_rounded),
              const SizedBox(height: 20),
              Text('Nenhuma atividade por aqui',
                  style: ZocText.h2(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Seus registros de atividade aparecerão aqui.',
                  style: ZocText.sub(), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
