import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/avatar_catalog.dart';

/// Parametric water-spirit renderer — Dart port of the design's
/// `avatar-engine.jsx`. Builds an SVG string from a spec and draws it with
/// flutter_svg, so all 12 forms come from one renderer and scale to any size.
/// Aura glow and the bubble ring are drawn with Flutter widgets (flutter_svg
/// does not animate CSS or render conic gradients).

const String _dropPath =
    'M60,30 C60,30 30,68 30,87 C30,102 43,113 60,113 C77,113 90,102 90,87 C90,68 60,30 60,30 Z';
const String _faceDark = '#0A1B33';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

String _eyes(String style, String accent) {
  switch (style) {
    case 'happy':
      return '<g fill="none" stroke="$_faceDark" stroke-width="2.6" stroke-linecap="round">'
          '<path d="M45.5,80 Q50,85.5 54.5,80"/>'
          '<path d="M65.5,80 Q70,85.5 74.5,80"/></g>';
    case 'cool':
      return '<g>'
          '<ellipse cx="50" cy="81" rx="3.7" ry="2.7" fill="$_faceDark"/>'
          '<ellipse cx="70" cy="81" rx="3.7" ry="2.7" fill="$_faceDark"/>'
          '<path d="M45.5,77.8 h9 M65.5,77.8 h9" stroke="#fff" stroke-opacity="0.18" stroke-width="2" stroke-linecap="round"/>'
          '<circle cx="51.3" cy="80" r="1.7" fill="#fff" opacity="0.95"/>'
          '<circle cx="71.3" cy="80" r="1.7" fill="#fff" opacity="0.95"/></g>';
    case 'wise':
      return '<g>'
          '<ellipse cx="50" cy="81" rx="3.3" ry="4.2" fill="$_faceDark"/>'
          '<ellipse cx="70" cy="81" rx="3.3" ry="4.2" fill="$_faceDark"/>'
          '<circle cx="50" cy="81" r="2" fill="$accent" opacity="0.9"/>'
          '<circle cx="70" cy="81" r="2" fill="$accent" opacity="0.9"/>'
          '<circle cx="50.8" cy="79.4" r="1.7" fill="#fff" opacity="0.95"/>'
          '<circle cx="70.8" cy="79.4" r="1.7" fill="#fff" opacity="0.95"/></g>';
    case 'fierce':
      return '<g>'
          '<path d="M45,78.5 L54,80.5 L54,84 L46,84 Z" fill="$_faceDark"/>'
          '<path d="M75,78.5 L66,80.5 L66,84 L74,84 Z" fill="$_faceDark"/>'
          '<circle cx="50" cy="81.6" r="1.5" fill="$accent"/>'
          '<circle cx="70" cy="81.6" r="1.5" fill="$accent"/>'
          '<path d="M45,76 L54.5,78.2 M75,76 L65.5,78.2" stroke="$_faceDark" stroke-width="2" stroke-linecap="round"/></g>';
    case 'regal':
      return '<g>'
          '<path d="M45.7,82 Q47,77 53.2,78.4 Q55,82 53,84 Q48,84.6 45.7,82 Z" fill="$_faceDark"/>'
          '<path d="M74.3,82 Q73,77 66.8,78.4 Q65,82 67,84 Q72,84.6 74.3,82 Z" fill="$_faceDark"/>'
          '<circle cx="51.4" cy="79.8" r="1.7" fill="#fff" opacity="0.95"/>'
          '<circle cx="68.6" cy="79.8" r="1.7" fill="#fff" opacity="0.95"/></g>';
    default: // cute
      return '<g>'
          '<ellipse cx="50" cy="81" rx="4.1" ry="5" fill="$_faceDark"/>'
          '<ellipse cx="70" cy="81" rx="4.1" ry="5" fill="$_faceDark"/>'
          '<circle cx="51.4" cy="79.3" r="1.7" fill="#fff" opacity="0.95"/>'
          '<circle cx="71.4" cy="79.3" r="1.7" fill="#fff" opacity="0.95"/>'
          '<circle cx="48.6" cy="83" r="0.9" fill="#fff" opacity="0.7"/>'
          '<circle cx="68.6" cy="83" r="0.9" fill="#fff" opacity="0.7"/></g>';
  }
}

String _mouth(String style) {
  switch (style) {
    case 'open':
      return '<path d="M55.5,92 Q60,93.4 64.5,92 Q63,99 60,99 Q57,99 55.5,92 Z" fill="#13314F"/>';
    case 'smirk':
      return '<path d="M54,93.5 Q60,96 67,91" fill="none" stroke="$_faceDark" stroke-width="2" stroke-linecap="round"/>';
    case 'calm':
      return '<path d="M55.5,93 Q60,95.2 64.5,93" fill="none" stroke="$_faceDark" stroke-width="1.9" stroke-linecap="round"/>';
    default: // smile
      return '<path d="M54,92 Q60,98 66,92" fill="none" stroke="$_faceDark" stroke-width="2.1" stroke-linecap="round"/>';
  }
}

String _crown(bool grand, String accent) {
  if (grand) {
    return '<g>'
        '<path d="M40,38 L40,24 L48,32 L54,18 L60,30 L66,18 L72,32 L80,24 L80,38 Z" fill="#FBBF24" stroke="#B45309" stroke-width="0.8" stroke-linejoin="round"/>'
        '<rect x="40" y="37" width="40" height="6" rx="2" fill="#FBBF24" stroke="#B45309" stroke-width="0.6"/>'
        '<path d="M40,38 L40,24 L48,32 L54,18 L60,30 L66,18 L72,32 L80,24 L80,38 Z" fill="#FDE68A" opacity="0.35"/>'
        '<circle cx="54" cy="22" r="1.6" fill="#EF4444"/>'
        '<circle cx="60" cy="33" r="1.8" fill="$accent"/>'
        '<circle cx="66" cy="22" r="1.6" fill="#22D3EE"/>'
        '<rect x="42" y="39" width="36" height="1.4" fill="#FDE68A" opacity="0.8"/></g>';
  }
  return '<g>'
      '<path d="M44,38 L44,26 L52,33 L60,22 L68,33 L76,26 L76,38 Z" fill="#FBBF24" stroke="#B45309" stroke-width="0.8" stroke-linejoin="round"/>'
      '<path d="M44,38 L44,26 L52,33 L60,22 L68,33 L76,26 L76,38 Z" fill="#FDE68A" opacity="0.35"/>'
      '<circle cx="60" cy="27" r="1.8" fill="$accent"/>'
      '<circle cx="48" cy="28" r="1.1" fill="#fff" opacity="0.8"/>'
      '<circle cx="72" cy="28" r="1.1" fill="#fff" opacity="0.8"/></g>';
}

String _backFeatures(AquaAvatarSpec s) {
  final f = s.features;
  final accent = _hex(s.accent);
  final rim = _hex(s.rim);
  final b1 = _hex(s.body[1]);
  final au = _hex(s.aura ?? s.accent);
  final out = StringBuffer();
  if (f.contains('fins')) {
    out.write('<g fill="$b1" opacity="0.9">'
        '<path d="M31,78 Q18,74 14,82 Q22,84 31,88 Z"/>'
        '<path d="M89,78 Q102,74 106,82 Q98,84 89,88 Z"/></g>');
  }
  if (f.contains('wings')) {
    out.write('<g>'
        '<path d="M33,72 Q8,60 4,86 Q16,80 24,86 Q14,82 33,84 Z" fill="$accent" opacity="0.55"/>'
        '<path d="M87,72 Q112,60 116,86 Q104,80 96,86 Q106,82 87,84 Z" fill="$accent" opacity="0.55"/>'
        '<path d="M33,74 Q14,66 9,84 Q19,79 27,84 Z" fill="#fff" opacity="0.25"/>'
        '<path d="M87,74 Q106,66 111,84 Q101,79 93,84 Z" fill="#fff" opacity="0.25"/></g>');
  }
  if (f.contains('horns')) {
    out.write('<g fill="$accent">'
        '<path d="M44,40 Q34,24 30,12 Q42,20 48,36 Z"/>'
        '<path d="M76,40 Q86,24 90,12 Q78,20 72,36 Z"/>'
        '<path d="M44,40 Q37,28 33,18 Q40,24 47,37 Z" fill="#fff" opacity="0.3"/></g>');
  }
  if (f.contains('halo')) {
    out.write('<g>'
        '<ellipse cx="60" cy="26" rx="26" ry="8" fill="none" stroke="$au" stroke-width="3" opacity="0.85"/>'
        '<ellipse cx="60" cy="26" rx="26" ry="8" fill="none" stroke="#fff" stroke-width="1" opacity="0.6"/></g>');
  }
  if (f.contains('speed')) {
    out.write(
        '<g stroke="$rim" stroke-width="2.4" stroke-linecap="round" opacity="0.55">'
        '<path d="M14,72 h12"/><path d="M10,82 h16"/><path d="M16,92 h10"/></g>');
  }
  if (f.contains('ribbon')) {
    out.write('<path d="M26,86 Q40,76 60,82 Q80,88 96,80" fill="none" '
        'stroke="$accent" stroke-width="5" stroke-linecap="round" opacity="0.55"/>');
  }
  if (f.contains('wisps')) {
    out.write('<g fill="$au" opacity="0.6">'
        '<path d="M26,64 q-6,-6 -2,-12 q6,4 2,12 Z"/>'
        '<path d="M94,64 q6,-6 2,-12 q-6,4 -2,12 Z"/></g>');
  }
  return out.toString();
}

String _frontFeatures(AquaAvatarSpec s) {
  final f = s.features;
  final accent = _hex(s.accent);
  final rim = _hex(s.rim);
  final out = StringBuffer();
  if (f.contains('leaf')) {
    out.write('<g>'
        '<path d="M60,32 Q58,18 50,12 Q54,24 58,32 Z" fill="#34D399"/>'
        '<path d="M60,32 Q63,20 72,16 Q66,26 62,33 Z" fill="#10B981"/>'
        '<path d="M50,12 Q55,22 59,31" stroke="#A7F3D0" stroke-width="0.8" fill="none" opacity="0.7"/></g>');
  }
  if (f.contains('quiff')) {
    out.write(
        '<path d="M60,30 Q50,18 60,12 Q66,18 72,16 Q70,26 62,34 Z" fill="$rim"/>');
  }
  if (f.contains('wavecrest')) {
    out.write('<g fill="$rim">'
        '<path d="M48,34 Q46,20 56,16 Q54,24 58,32 Z"/>'
        '<path d="M58,32 Q58,16 70,14 Q66,22 66,30 Z"/>'
        '<path d="M64,31 Q68,20 78,20 Q72,27 70,33 Z"/></g>');
  }
  if (f.contains('whiskers')) {
    out.write(
        '<g stroke="$accent" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.9">'
        '<path d="M34,86 Q18,84 10,90"/>'
        '<path d="M86,86 Q102,84 110,90"/></g>');
  }
  if (f.contains('fangs')) {
    out.write('<g fill="#fff">'
        '<path d="M56.5,95 l1.2,4 l1.2,-4 Z"/>'
        '<path d="M61.1,95 l1.2,4 l1.2,-4 Z"/></g>');
  }
  if (f.contains('gem')) {
    out.write('<g>'
        '<path d="M60,56 l4.5,4 l-4.5,5.5 l-4.5,-5.5 Z" fill="$accent"/>'
        '<path d="M60,56 l4.5,4 l-4.5,2 l-4.5,-2 Z" fill="#fff" opacity="0.7"/></g>');
  }
  if (f.contains('crown')) out.write(_crown(false, accent));
  if (f.contains('crown_grand')) out.write(_crown(true, accent));
  if (f.contains('dew')) {
    out.write('<g fill="$rim">'
        '<circle cx="30" cy="48" r="2.4" opacity="0.85"/>'
        '<circle cx="92" cy="56" r="2" opacity="0.8"/>'
        '<circle cx="86" cy="38" r="1.5" opacity="0.7"/></g>');
  }
  return out.toString();
}

/// Build the full `<svg>` document string for a spec.
String buildAvatarSvg(AquaAvatarSpec spec, {bool silhouette = false}) {
  final body0 = silhouette ? '#2C4566' : _hex(spec.body[0]);
  final body1 = silhouette ? '#0F1E36' : _hex(spec.body[1]);
  final rim = silhouette ? '#3A5C84' : _hex(spec.rim);
  final accent = silhouette ? '#3A5C84' : _hex(spec.accent);

  final face = silhouette
      ? '<text x="60" y="92" text-anchor="middle" font-size="22" font-weight="800" fill="$rim" opacity="0.7" font-family="system-ui">?</text>'
      : '${spec.blush ? '<g fill="#FB7185" opacity="0.4"><ellipse cx="44" cy="89" rx="4" ry="2.4"/><ellipse cx="76" cy="89" rx="4" ry="2.4"/></g>' : ''}'
          '${_eyes(spec.eyes, accent)}${_mouth(spec.mouth)}${_frontFeatures(spec)}';

  return '<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">'
      '<defs>'
      '<linearGradient id="body" x1="0" y1="0" x2="0" y2="1">'
      '<stop offset="0%" stop-color="$body0"/>'
      '<stop offset="100%" stop-color="$body1"/></linearGradient>'
      '<radialGradient id="sheen" cx="38%" cy="34%" r="55%">'
      '<stop offset="0%" stop-color="#fff" stop-opacity="0.5"/>'
      '<stop offset="100%" stop-color="#fff" stop-opacity="0"/></radialGradient>'
      '</defs>'
      '${silhouette ? '' : _backFeatures(spec)}'
      '<path d="$_dropPath" fill="url(#body)" stroke="$rim" stroke-width="1.4"/>'
      '<path d="M30,87 C30,102 43,113 60,113 C77,113 90,102 90,87 C84,98 72,103 60,103 C48,103 36,98 30,87 Z" fill="$body1" opacity="${silhouette ? 0.4 : 0.55}"/>'
      '<ellipse cx="50" cy="58" rx="20" ry="26" fill="url(#sheen)"/>'
      '<path d="M45,46 Q38,60 46,74" stroke="#fff" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="${silhouette ? 0.15 : 0.45}"/>'
      '$face'
      '</svg>';
}

/// One water-spirit drawn in a square field. Adds a soft aura glow behind
/// high-tier forms (flutter_svg can't animate the design's conic aura).
class AquaAvatar extends StatelessWidget {
  final AquaAvatarSpec spec;
  final double size;
  final bool silhouette;

  const AquaAvatar({
    super.key,
    required this.spec,
    this.size = 120,
    this.silhouette = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!silhouette && spec.aura != null)
            Container(
              width: size * 0.55,
              height: size * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: spec.aura!.withValues(alpha: 0.45),
                    blurRadius: size * 0.22,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          SvgPicture.string(
            buildAvatarSvg(spec, silhouette: silhouette),
            width: size,
            height: size,
          ),
        ],
      ),
    );
  }
}

/// Circular framed bubble with a tier-colored ring + glow (profile style).
class AvatarBubble extends StatelessWidget {
  final AquaAvatarSpec spec;
  final double size;
  final bool silhouette;
  final bool ring;

  const AvatarBubble({
    super.key,
    required this.spec,
    this.size = 76,
    this.silhouette = false,
    this.ring = true,
  });

  @override
  Widget build(BuildContext context) {
    final tier = spec.tierStyle;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring ? size * 0.045 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: silhouette
            ? null
            : SweepGradient(
                startAngle: 210 * math.pi / 180,
                colors: [...tier.ring, tier.ring.first],
              ),
        color: silhouette ? Colors.white.withValues(alpha: 0.1) : null,
        boxShadow: silhouette
            ? null
            : [BoxShadow(color: tier.glow, blurRadius: size * 0.28)],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(0, -0.24),
            colors: silhouette
                ? const [Color(0xFF16243C), Color(0xFF0B1322)]
                : const [Color(0xFF14365C), Color(0xFF081325)],
          ),
          border: Border.all(color: const Color(0xFF0B1120), width: 2),
        ),
        child: Center(
          child: AquaAvatar(
            spec: spec,
            size: size * 0.92,
            silhouette: silhouette,
          ),
        ),
      ),
    );
  }
}
