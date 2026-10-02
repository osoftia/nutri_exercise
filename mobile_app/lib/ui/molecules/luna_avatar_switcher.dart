import 'package:flutter/material.dart';

/// Lets the user compare the interactive blueprint with a Luna-generated render.
///
/// Generated image files are optional during development. If a requested image
/// is not bundled yet, the render panel shows a clear placeholder instead of a
/// broken-image icon; the blueprint remains available in either mode.
class LunaAvatarSwitcher extends StatefulWidget {
  const LunaAvatarSwitcher({
    super.key,
    required this.blueprint,
    this.trailing,
    this.height = 320,
  });

  /// The existing interactive body visualization.
  final Widget blueprint;

  /// Optional controls kept alongside either body visualization.
  final Widget? trailing;

  /// Height of the body visualization viewport.
  final double height;

  @override
  State<LunaAvatarSwitcher> createState() => _LunaAvatarSwitcherState();
}

class _LunaAvatarSwitcherState extends State<LunaAvatarSwitcher> {
  bool _showLunaRender = false;
  String _variant = 'male';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('luna_avatar_style_toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Photorealistic Luna render'),
          subtitle: const Text('Switch between the render and body blueprint'),
          value: _showLunaRender,
          onChanged: (value) => setState(() => _showLunaRender = value),
        ),
        if (_showLunaRender)
          Align(
            alignment: Alignment.centerLeft,
            child: DropdownButton<String>(
              key: const Key('luna_avatar_variant_selector'),
              value: _variant,
              onChanged: (variant) {
                if (variant != null) setState(() => _variant = variant);
              },
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male avatar')),
                DropdownMenuItem(value: 'female', child: Text('Female avatar')),
              ],
            ),
          ),
        SizedBox(
          height: widget.height,
          child: Row(
            children: [
              Expanded(
                child: _showLunaRender ? _renderImage() : widget.blueprint,
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ],
    );
  }

  Widget _renderImage() {
    final assetPath = 'assets/images/luna_avatars/$_variant.png';
    return Image.asset(
      assetPath,
      key: const Key('luna_avatar_image'),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _PendingAvatarAsset(
        key: const Key('luna_avatar_asset_pending'),
        variant: _variant,
      ),
    );
  }
}

class _PendingAvatarAsset extends StatelessWidget {
  const _PendingAvatarAsset({super.key, required this.variant});

  final String variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x733B82F6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_search_outlined,
            size: 44,
            color: const Color(0xFF93C5FD),
          ),
          const SizedBox(height: 12),
          Text(
            '${variant[0].toUpperCase()}${variant.substring(1)} Luna render',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Add $variant.png to assets/images/luna_avatars/',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
