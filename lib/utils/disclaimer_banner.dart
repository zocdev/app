import 'package:flutter/material.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({
    super.key,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;

  static const String message =
      'O ZOC é uma ferramenta de referência financeira e de gestão. Os valores, cálculos e '
      'relatórios exibidos não constituem folha de pagamento, holerite, comprovante de ponto ou '
      'qualquer outro documento com validade legal, fiscal ou trabalhista. Consulte sempre o '
      'departamento responsável ou um profissional contábil/jurídico para fins oficiais.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        message,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 10.0,
          color: Colors.grey.shade600,
          height: 1.3,
        ),
      ),
    );
  }
}
