import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/form_field_controller.dart';
import 'zoc_tokens.dart';

/// Visual variant of [ZocButton].
enum ZocButtonVariant { primary, secondary, ghost, danger }

/// Pill button. Sentence-case labels only.
/// [loading] shows a spinner before the label and blocks taps.
/// [expanded] fills the available width; [small] is 34 tall instead of 44.
/// Disabled when [onPressed] is null.
class ZocButton extends StatelessWidget {
  const ZocButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.variant = ZocButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.small = false,
    this.horizontalPadding,
  });

  final String label;
  final VoidCallback? onPressed;
  final ZocButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final bool small;

  /// Overrides the side padding (20, small: 12), e.g. three buttons in a row.
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (Color bg, Color fg, Color? border) = switch (variant) {
      ZocButtonVariant.primary => (ZocColors.brand, Colors.white, null),
      ZocButtonVariant.secondary => (
          ZocColors.surface,
          ZocColors.brand,
          ZocColors.brand
        ),
      ZocButtonVariant.ghost => (Colors.transparent, ZocColors.muted, null),
      ZocButtonVariant.danger => (ZocColors.bad, Colors.white, null),
    };
    final height = small ? 34.0 : 44.0;
    final dim = onPressed == null && !loading;
    final iconSize = small ? 14.0 : 15.0;

    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(small ? 34 : 64, height)),
        fixedSize: WidgetStatePropertyAll(Size.fromHeight(height)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
            horizontal: horizontalPadding ?? (small ? 12 : 20))),
        shape: WidgetStatePropertyAll(StadiumBorder(
            side: border == null
                ? BorderSide.none
                : BorderSide(color: border.withValues(alpha: dim ? .45 : 1)))),
        backgroundColor: WidgetStatePropertyAll(
            dim && bg.a > 0 ? bg.withValues(alpha: .45) : bg),
        foregroundColor:
            WidgetStatePropertyAll(dim ? fg.withValues(alpha: .6) : fg),
        overlayColor: WidgetStateProperty.resolveWith((s) {
          final base = variant == ZocButtonVariant.primary ||
                  variant == ZocButtonVariant.danger
              ? Colors.white
              : ZocColors.brand;
          if (s.contains(WidgetState.pressed)) {
            return base.withValues(alpha: .16);
          }
          if (s.contains(WidgetState.hovered) ||
              s.contains(WidgetState.focused)) {
            return base.withValues(alpha: .08);
          }
          return null;
        }),
        elevation: const WidgetStatePropertyAll(0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        textStyle: WidgetStatePropertyAll(
            ZocText.button(color: fg, size: small ? 13 : 14)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox.square(
                dimension: iconSize,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: fg.withValues(alpha: .8)),
              ),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, size: iconSize),
            ),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZocText.button(
                    color: dim ? fg.withValues(alpha: .6) : fg,
                    size: small ? 13 : 14)),
          ),
        ],
      ),
    );

    final shadowed = variant == ZocButtonVariant.primary && enabled
        ? DecoratedBox(
            decoration: const ShapeDecoration(
                shape: StadiumBorder(), shadows: ZocShadows.button),
            child: button)
        : button;
    return expanded
        ? SizedBox(width: double.infinity, child: shadowed)
        : shadowed;
  }
}

/// Input border of the kit: rounded 14, optional colored side and an outer
/// 3px [glow] ring (focus style). Usable in any `InputDecoration`.
class ZocInputBorder extends InputBorder {
  const ZocInputBorder({
    super.borderSide = BorderSide.none,
    this.glow,
    this.radius = ZocRadii.input,
  });

  final Color? glow;
  final double radius;

  /// No border (enabled state).
  static const idle = ZocInputBorder();

  /// 1px teal border + teal glow (focused).
  static const focused = ZocInputBorder(
      borderSide: BorderSide(color: ZocColors.brand),
      glow: ZocColors.brandLine);

  /// 1px red border (error).
  static const error =
      ZocInputBorder(borderSide: BorderSide(color: ZocColors.bad));

  /// 1px red border + red glow (focused with error).
  static const focusedError = ZocInputBorder(
      borderSide: BorderSide(color: ZocColors.bad), glow: Color(0x1ADC2626));

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  ZocInputBorder copyWith({BorderSide? borderSide}) => ZocInputBorder(
      borderSide: borderSide ?? this.borderSide, glow: glow, radius: radius);

  @override
  ShapeBorder scale(double t) => ZocInputBorder(
      borderSide: borderSide.scale(t), glow: glow, radius: radius * t);

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(borderSide.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ZocInputBorder) {
      return ZocInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        glow: Color.lerp(a.glow, glow, t),
        radius: lerpDouble(a.radius, radius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ZocInputBorder) return b.lerpFrom(this, t);
    return super.lerpTo(b, t);
  }

  @override
  void paint(Canvas canvas, Rect rect,
      {double? gapStart,
      double gapExtent = 0.0,
      double gapPercentage = 0.0,
      TextDirection? textDirection}) {
    final rr = _rrect(rect);
    if (glow != null && glow!.a > 0) {
      canvas.drawRRect(
          rr.inflate(1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = glow!);
    }
    if (borderSide.style != BorderStyle.none && borderSide.width > 0) {
      canvas.drawRRect(rr.deflate(borderSide.width / 2), borderSide.toPaint());
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ZocInputBorder &&
      other.borderSide == borderSide &&
      other.glow == glow &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(borderSide, glow, radius);
}

/// Builds the kit `InputDecoration` (fill, borders, icon colors, error style).
/// Use it for custom fields that can't use [ZocTextField].
InputDecoration zocInputDecoration({
  String? hintText,
  IconData? icon,
  Widget? suffixIcon,
  EdgeInsetsGeometry? contentPadding,
}) {
  final iconColor = WidgetStateColor.resolveWith((s) {
    if (s.contains(WidgetState.error)) return ZocColors.bad;
    if (s.contains(WidgetState.focused)) return ZocColors.brand;
    return ZocColors.faint;
  });
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: ZocColors.inputFill,
    hoverColor: Colors.transparent,
    hintText: hintText,
    hintStyle: ZocText.body(color: ZocColors.faint),
    errorStyle: ZocText.caption(color: ZocColors.bad),
    errorMaxLines: 2,
    contentPadding: contentPadding ??
        EdgeInsets.fromLTRB(icon == null ? 14 : 0, 13, 14, 13),
    prefixIcon: icon == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, size: 17)),
    prefixIconConstraints: const BoxConstraints(minHeight: 44),
    prefixIconColor: iconColor,
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minHeight: 44, minWidth: 40),
    suffixIconColor: ZocColors.faint,
    border: ZocInputBorder.idle,
    enabledBorder: ZocInputBorder.idle,
    disabledBorder: ZocInputBorder.idle,
    focusedBorder: ZocInputBorder.focused,
    errorBorder: ZocInputBorder.error,
    focusedErrorBorder: ZocInputBorder.focusedError,
  );
}

/// Text field with label above, optional leading [icon], password eye toggle
/// ([password]: true) and error text below. Takes the existing FlutterFlow
/// controller / focus node / validator (`model.xValidator.asValidator(context)`).
class ZocTextField extends StatefulWidget {
  const ZocTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.icon,
    this.password = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.suffix,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final IconData? icon;
  final bool password;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  /// Custom trailing widget (ignored when [password] is true).
  final Widget? suffix;

  @override
  State<ZocTextField> createState() => _ZocTextFieldState();
}

class _ZocTextFieldState extends State<ZocTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final suffix = widget.password
        ? IconButton(
            tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 17),
            splashRadius: 18,
            color: ZocColors.faint,
          )
        : widget.suffix;
    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      obscureText: widget.password && _obscure,
      maxLines: widget.password ? 1 : widget.maxLines,
      style: ZocText.body(),
      cursorColor: ZocColors.brand,
      decoration: zocInputDecoration(
          hintText: widget.hintText, icon: widget.icon, suffixIcon: suffix),
    );
    if (widget.label == null) return field;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label!, style: ZocText.label()),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}

/// Styled wrapper around `FlutterFlowDropDown` (dropdown_button2): label
/// above, optional leading [icon], 44 tall, fill like inputs, chevron.
/// Same data params as `FlutterFlowDropDown`; [dropDownKey] goes to the inner
/// dropdown (tests tap it; also used by `optionsHasValueKeys`).
class ZocSelect<T> extends StatelessWidget {
  const ZocSelect({
    super.key,
    required this.options,
    this.optionLabels,
    this.controller,
    this.multiSelectController,
    this.onChanged,
    this.onMultiSelectChanged,
    this.label,
    this.icon,
    this.hintText,
    this.searchHintText = 'Buscar...',
    this.isSearchable = false,
    this.isMultiSelect = false,
    this.disabled = false,
    this.maxHeight = 240,
    this.dropDownKey,
    this.optionsHasValueKeys = false,
  });

  final List<T> options;
  final List<String>? optionLabels;
  final FormFieldController<T?>? controller;
  final FormFieldController<List<T>?>? multiSelectController;
  final void Function(T?)? onChanged;
  final void Function(List<T>?)? onMultiSelectChanged;
  final String? label;
  final IconData? icon;
  final String? hintText;
  final String searchHintText;
  final bool isSearchable;
  final bool isMultiSelect;
  final bool disabled;
  final double maxHeight;
  final Key? dropDownKey;
  final bool optionsHasValueKeys;

  @override
  Widget build(BuildContext context) {
    final dropDown = FlutterFlowDropDown<T>(
      key: dropDownKey,
      controller: controller,
      multiSelectController: multiSelectController,
      options: options,
      optionLabels: optionLabels,
      onChanged: onChanged,
      onMultiSelectChanged: onMultiSelectChanged,
      height: 44,
      maxHeight: maxHeight,
      textStyle: ZocText.body(),
      searchTextStyle: ZocText.body(),
      searchHintTextStyle: ZocText.body(color: ZocColors.faint),
      searchCursorColor: ZocColors.brand,
      hintText: hintText,
      searchHintText: searchHintText,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: ZocColors.faint, size: 20),
      // Also the menu color (FlutterFlowDropDown uses one fill for both).
      fillColor: ZocColors.inputFill,
      elevation: 2,
      borderColor: Colors.transparent,
      borderWidth: 0,
      borderRadius: ZocRadii.input,
      margin: EdgeInsetsDirectional.fromSTEB(icon == null ? 14 : 0, 0, 10, 0),
      hidesUnderline: true,
      disabled: disabled,
      isSearchable: isSearchable,
      isMultiSelect: isMultiSelect,
      optionsHasValueKeys: optionsHasValueKeys,
    );
    final box = Container(
      height: 44,
      decoration: BoxDecoration(
        color: ZocColors.inputFill,
        borderRadius: BorderRadius.circular(ZocRadii.input),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, size: 17, color: ZocColors.faint),
            ),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(hoverColor: Colors.transparent),
              child: dropDown,
            ),
          ),
        ],
      ),
    );
    if (label == null) return Opacity(opacity: disabled ? .6 : 1, child: box);
    return Opacity(
      opacity: disabled ? .6 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label!, style: ZocText.label()),
          const SizedBox(height: 6),
          box,
        ],
      ),
    );
  }
}

/// Row with bold [title], muted [help] and a switch on the right. The whole
/// row is tappable.
class ZocToggleRow extends StatelessWidget {
  const ZocToggleRow({
    super.key,
    required this.title,
    this.help,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? help;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ZocRadii.input);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: Material(
        color: ZocColors.surface2,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: ZocText.strong()),
                      if (help != null) ...[
                        const SizedBox(height: 2),
                        Text(help!, style: ZocText.caption()),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ZocSwitch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact 38×22 pill switch.
class ZocSwitch extends StatelessWidget {
  const ZocSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 38,
          height: 22,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: (value ? ZocColors.brand : ZocColors.control)
                .withValues(alpha: onChanged == null ? .5 : 1),
            borderRadius: BorderRadius.circular(ZocRadii.pill),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 1),
                      blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Checkbox + label. Uses a Material `Checkbox` (tests find it by type).
/// Disabled when [onChanged] is null. Pass [label] or [child].
class ZocCheckRow extends StatelessWidget {
  const ZocCheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.child,
  }) : assert(label != null || child != null);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: Checkbox(
                  value: value,
                  onChanged:
                      onChanged == null ? null : (v) => onChanged!(v == true),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: ZocColors.brand,
                  checkColor: Colors.white,
                  splashRadius: 14,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  side: WidgetStateBorderSide.resolveWith((s) => s
                          .contains(WidgetState.selected)
                      ? const BorderSide(color: ZocColors.brand, width: 1.5)
                      : const BorderSide(color: ZocColors.control, width: 1.5)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: child ??
                    Text(label!, style: ZocText.body().copyWith(fontSize: 13)),
              ),
            ],
          ),
        ),
      );
}

/// Pill segmented control (e.g. Dia / Semana / Mês).
class ZocSegmented extends StatelessWidget {
  const ZocSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: ZocColors.surface,
          borderRadius: BorderRadius.circular(ZocRadii.pill),
          boxShadow: ZocShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++)
              Material(
                color: i == selected ? ZocColors.brand : Colors.transparent,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onChanged == null ? null : () => onChanged!(i),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    child: Text(
                      labels[i],
                      style: ZocText.button(
                          size: 13,
                          color:
                              i == selected ? Colors.white : ZocColors.muted),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
