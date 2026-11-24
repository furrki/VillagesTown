import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/constants/layout_constants.dart';

class TownHero extends StatefulWidget {
  const TownHero({super.key, required this.won, required this.still});

  final bool won;
  final bool still;

  static const height = 200.0;
  static const wonHeight = 290.0;

  @override
  State<TownHero> createState() => _TownHeroState();
}

class _House {
  const _House(this.spot, this.at, this.reach, this.tone);

  final Offset spot;
  final double at;
  final double reach;
  final int tone;
}

class _Landmark {
  const _Landmark(this.label, this.spot, this.at, this.litAt);

  final String label;
  final Offset spot;
  final double at;
  final double litAt;
}

class _Rocket {
  const _Rocket(this.x, this.peak, this.launch, this.color);

  final double x;
  final double peak;
  final double launch;
  final Color color;
}

double _noise(int index, double seed) {
  final value = math.sin(index * seed) * 43758.5453;
  return value - value.floorToDouble();
}

Offset _bezier(List<Offset> arm, double t) {
  final u = 1 - t;
  return arm[0] * (u * u) + arm[1] * (2 * u * t) + arm[2] * (t * t);
}

class _Town {
  _Town(this.houses);

  final List<_House> houses;

  static const keep = Offset(0.5, 0.5);
  static const horizon = 0.22;
  static const arms = [
    [Offset(0.5, 0.5), Offset(0.3, 0.6), Offset(-0.05, 0.66)],
    [Offset(0.5, 0.5), Offset(0.72, 0.52), Offset(1.05, 0.5)],
    [Offset(0.5, 0.5), Offset(0.42, 0.78), Offset(0.25, 1.05)],
    [Offset(0.5, 0.5), Offset(0.6, 0.8), Offset(0.78, 1.05)],
    [Offset(0.5, 0.5), Offset(0.55, 0.36), Offset(0.62, 0.2)],
  ];
  static const landmarks = [
    _Landmark('Market', Offset(0.29, 0.43), 0.3, 1.62),
    _Landmark('Barracks', Offset(0.73, 0.4), 0.55, 1.9),
    _Landmark('Tavern', Offset(0.5, 0.8), 0.8, 2.18),
  ];

  static final _Town shared = _build();

  static _Town _build() {
    const w = 330.0;
    const h = 200.0;
    Offset px(Offset u) => Offset(u.dx * w, u.dy * h);
    final keepPx = px(keep);
    final blocked = [for (final l in landmarks) px(l.spot)];
    final placed = <Offset>[];
    final found = <(int, int, int, Offset)>[];
    for (var a = 0; a < arms.length; a++) {
      final arm = arms[a];
      final step = a == 4 ? 19.0 : 24.0;
      var length = 0.0;
      var next = 30.0;
      var k = 0;
      var prev = px(_bezier(arm, 0));
      for (var i = 1; i <= 400; i++) {
        final point = px(_bezier(arm, i / 400));
        length += (point - prev).distance;
        if (length >= next) {
          final tangent = point - prev;
          final normal = Offset(-tangent.dy, tangent.dx) / tangent.distance;
          var slot = 0;
          for (final side in const [-1.0, 1.0]) {
            for (final row in const [12.0, 27.0]) {
              slot++;
              final jitter = 3 * _noise(a * 97 + k * 13 + slot, 12.9898);
              final spot = point + normal * side * (row + jitter);
              final u = Offset(spot.dx / w, spot.dy / h);
              if (u.dx < 0.04 || u.dx > 0.96) continue;
              if (u.dy < horizon + 0.05 || u.dy > 0.97) continue;
              if ((spot - keepPx).distance < 34) continue;
              if (blocked.any((b) => (spot - b).distance < 28)) continue;
              if (placed.any((p) => (spot - p).distance < 14)) continue;
              placed.add(spot);
              found.add((k, a, slot, u));
            }
          }
          k++;
          next += step;
        }
        prev = point;
      }
    }
    found.sort((x, y) {
      if (x.$1 != y.$1) return x.$1.compareTo(y.$1);
      if (x.$3 ~/ 3 != y.$3 ~/ 3) return (x.$3 ~/ 3).compareTo(y.$3 ~/ 3);
      if (x.$2 != y.$2) return x.$2.compareTo(y.$2);
      return x.$3.compareTo(y.$3);
    });
    final far = found
        .map((f) => (px(f.$4) - keepPx).distance)
        .fold<double>(1, math.max);
    return _Town([
      for (var i = 0; i < found.length; i++)
        _House(
          found[i].$4,
          _TownHeroState.houseStart +
              _TownHeroState.houseSpan * i / found.length,
          (px(found[i].$4) - keepPx).distance / far,
          (_noise(i, 78.233) * 3).floor(),
        ),
    ]);
  }
}

class _TownHeroState extends State<TownHero>
    with SingleTickerProviderStateMixin {
  static const houseStart = 0.08;
  static const houseSpan = 1.0;
  static const pop = 0.26;
  static const keepAt = 1.1;
  static const keepLands = 1.4;
  static const introEnd = 2.75;
  static const lightFrom = 0.3;
  static const lightSpan = 1.1;
  static const burstAt = 0.35;
  static const wonEnd = 2.9;
  static const rockets = [
    _Rocket(0.5, 0.1, 0.35, Color(0xFFFFC94D)),
    _Rocket(0.24, 0.16, 0.52, Color(0xFFFF7A59)),
    _Rocket(0.77, 0.12, 0.69, Color(0xFF7FD4FF)),
    _Rocket(0.36, 0.06, 0.86, Color(0xFFFFF1C1)),
    _Rocket(0.64, 0.18, 1.03, Color(0xFF9BE58A)),
    _Rocket(0.13, 0.08, 1.2, Color(0xFFFFC94D)),
    _Rocket(0.88, 0.07, 1.37, Color(0xFFFF7A59)),
  ];
  static const rise = 0.42;
  static const sparkLife = 1.05;

  final clock = ValueNotifier<double>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _lastTick = -1;
  double wonAt = double.infinity;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.won) wonAt = introEnd - wonEnd;
    if (widget.still || widget.won) {
      clock.value = introEnd;
    } else {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(TownHero old) {
    super.didUpdateWidget(old);
    if (widget.won && !old.won) {
      clock.value = math.max(clock.value, introEnd);
      wonAt = widget.still ? clock.value - wonEnd : clock.value;
      if (!widget.still && !_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    }
    if (!widget.won && old.won) {
      wonAt = double.infinity;
      _ticker.stop();
      clock.value = introEnd;
    }
    if (widget.still && _ticker.isActive) {
      _ticker.stop();
      if (wonAt.isFinite) wonAt = clock.value - wonEnd;
      clock.value = math.max(clock.value, introEnd);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    clock.dispose();
    super.dispose();
  }

  void _light(double now) {
    if (now - _lastTick < 0.125) return;
    _lastTick = now;
    LayoutConstants.impactFeedback();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : math.min(0.05, (now - _last).inMicroseconds / 1e6);
    _last = now;
    final before = clock.value;
    final after = before + dt;
    bool crossed(double at) => before < at && after >= at;

    if (!wonAt.isFinite) {
      for (final house in _Town.shared.houses) {
        if (crossed(house.at + pop * 0.7)) _light(after);
      }
      if (crossed(keepLands)) {
        _lastTick = after;
        LayoutConstants.impactFeedback(style: HapticStyle.heavy);
      }
      for (final landmark in _Town.landmarks) {
        if (crossed(landmark.litAt)) LayoutConstants.selectionFeedback();
      }
    } else {
      for (final house in _Town.shared.houses) {
        if (crossed(wonAt + lightFrom + house.reach * lightSpan)) {
          _light(after);
        }
      }
      for (final rocket in rockets) {
        if (crossed(wonAt + rocket.launch + rise)) _light(after);
      }
    }

    clock.value = after;
    final end = wonAt.isFinite ? wonAt + wonEnd : introEnd;
    if (after >= end) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: widget.still
            ? Duration.zero
            : const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: widget.won ? TownHero.wonHeight : TownHero.height,
        child: CustomPaint(
          painter: _TownPainter(
            this,
            DefaultTextStyle.of(context).style.fontFamily,
          ),
        ),
      ),
    );
  }
}

class _TownPainter extends CustomPainter {
  _TownPainter(this.state, this.font) : super(repaint: state.clock);

  final _TownHeroState state;
  final String? font;

  static const _nightInk = Color(0xFF0C1224);
  static const _gold = Color(0xFFFFC94D);
  static const _glass = Color(0xFF6B5A3A);
  static const _lamp = Color(0xFFFFD36B);
  static const _walls = [
    Color(0xFFE3D3B0),
    Color(0xFFD4BE94),
    Color(0xFFC9B48E),
  ];
  static const _roofs = [
    Color(0xFFB4543A),
    Color(0xFF9C4630),
    Color(0xFF7E5A3A),
  ];
  static const _stone = Color(0xFFA49E8E);
  static const _stoneSide = Color(0xFF7F7A6C);
  static const _banner = Color(0xFF2196F3);
  static final _labels = <String, TextPainter>{};

  static final Path _houseSide = Path()
    ..moveTo(5, 0)
    ..lineTo(9, -3)
    ..lineTo(9, -12)
    ..lineTo(5, -9)
    ..close();
  static final Path _gable = Path()
    ..moveTo(-7.8, -9)
    ..lineTo(5.8, -9)
    ..lineTo(-1, -15.5)
    ..close();
  static final Path _roofSide = Path()
    ..moveTo(-1, -15.5)
    ..lineTo(3, -18.5)
    ..lineTo(9.6, -12.3)
    ..lineTo(5.8, -9)
    ..close();

  double night = 0;

  static double _unit(double value) => value.clamp(0.0, 1.0);

  TextPainter _label(String text) {
    return _labels.putIfAbsent('$text$font', () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: font,
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  Color _dim(Color color, [double lit = 0]) =>
      Color.lerp(color, _nightInk, 0.55 * night * (1 - lit))!;

  Paint _fill(Color color, [double alpha = 1]) =>
      Paint()..color = color.withValues(alpha: alpha);

  void _glow(Canvas canvas, Offset centre, double radius, double alpha) {
    if (alpha <= 0) return;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _lamp.withValues(alpha: 0.42 * alpha),
            _lamp.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  void _shadow(Canvas canvas, double width, double alpha) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(1.5, 0), width: width, height: 5),
      _fill(Colors.black, 0.25 * alpha),
    );
  }

  void _house(Canvas canvas, _House house, double lit, double alpha) {
    _shadow(canvas, 22, alpha);
    _glow(canvas, const Offset(-1, -6), 20, lit);
    canvas.drawRect(
      const Rect.fromLTRB(-7, -9, 5, 0),
      _fill(_dim(_walls[house.tone], lit * 0.6), alpha),
    );
    canvas.drawPath(
      _houseSide,
      _fill(
        _dim(Color.lerp(_walls[house.tone], Colors.black, 0.24)!, lit * 0.4),
        alpha,
      ),
    );
    canvas.drawPath(_gable, _fill(_dim(_roofs[house.tone], lit * 0.3), alpha));
    canvas.drawPath(
      _roofSide,
      _fill(
        _dim(Color.lerp(_roofs[house.tone], Colors.black, 0.2)!, lit * 0.3),
        alpha,
      ),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-4.8, -6.8, 3, 3),
      _fill(Color.lerp(_dim(_glass), _lamp, lit)!, alpha),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0.6, -5.2, 2.8, 5.2),
      _fill(_dim(const Color(0xFF5A4030)), alpha),
    );
  }

  void _crenels(
    Canvas canvas,
    double left,
    double right,
    double top,
    Paint paint,
  ) {
    final step = (right - left) / 5;
    for (var i = 0; i < 5; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(left + i * step, top - 2.6, step, 2.6),
        paint,
      );
    }
  }

  void _block(Canvas canvas, Rect rect, double lit, double alpha) {
    final face = _fill(_dim(_stone, lit * 0.5), alpha);
    canvas.drawRect(rect, face);
    canvas.drawRect(
      Rect.fromLTRB(rect.right - 2.4, rect.top, rect.right, rect.bottom),
      _fill(_dim(_stoneSide, lit * 0.4), alpha),
    );
    _crenels(canvas, rect.left, rect.right, rect.top, face);
  }

  void _keep(Canvas canvas, double t, double lit, double alpha) {
    _shadow(canvas, 46, alpha);
    _glow(canvas, const Offset(0, -18), 44, lit);
    _block(canvas, const Rect.fromLTRB(-19, -30, -10, 0), lit, alpha);
    _block(canvas, const Rect.fromLTRB(10, -30, 19, 0), lit, alpha);
    _block(canvas, const Rect.fromLTRB(-12, -20, 12, 0), lit, alpha);
    _block(canvas, const Rect.fromLTRB(-7, -40, 7, -20), lit, alpha);
    canvas.drawPath(
      Path()
        ..moveTo(-4, 0)
        ..lineTo(-4, -6)
        ..arcToPoint(const Offset(4, -6), radius: const Radius.circular(4))
        ..lineTo(4, 0)
        ..close(),
      _fill(_dim(const Color(0xFF3B3226)), alpha),
    );
    final slit = _fill(Color.lerp(_dim(_glass), _lamp, lit)!, alpha);
    for (final x in const [-15.5, 13.5, -1.2]) {
      canvas.drawRect(Rect.fromLTWH(x, x == -1.2 ? -34 : -23, 2.4, 4.5), slit);
    }
    canvas.drawLine(
      const Offset(4.5, -42),
      const Offset(4.5, -56),
      Paint()
        ..color = _dim(const Color(0xFF4A3B2A)).withValues(alpha: alpha)
        ..strokeWidth = 1.2,
    );
    final wave = math.sin(t * 7) * 1.6;
    canvas.drawPath(
      Path()
        ..moveTo(4.5, -56)
        ..quadraticBezierTo(9, -57 + wave, 15, -53.5 + wave * 0.6)
        ..quadraticBezierTo(9, -51 + wave, 4.5, -50.5)
        ..close(),
      _fill(_dim(_banner, lit), alpha),
    );
  }

  void _market(Canvas canvas, double t, double lit, double alpha) {
    _shadow(canvas, 30, alpha);
    _glow(canvas, const Offset(0, -8), 26, lit);
    canvas.drawRect(
      const Rect.fromLTRB(-11, -10, 11, 0),
      _fill(_dim(_walls[0], lit * 0.6), alpha),
    );
    canvas.drawRect(
      const Rect.fromLTRB(-7, -7, 7, -1),
      _fill(Color.lerp(_dim(_glass), _lamp, lit)!, alpha),
    );
    for (var i = 0; i < 6; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(-11 + i * 22 / 6, -10)
          ..lineTo(-13 + i * 26 / 6, -14.5)
          ..lineTo(-13 + (i + 1) * 26 / 6, -14.5)
          ..lineTo(-11 + (i + 1) * 22 / 6, -10)
          ..close(),
        _fill(
          _dim(
            i.isEven ? const Color(0xFFD9453A) : const Color(0xFFF4ECDD),
            lit * 0.5,
          ),
          alpha,
        ),
      );
    }
    if (lit <= 0) return;
    for (var c = 0; c < 3; c++) {
      final age = t - c * 0.09;
      if (age <= 0 || age >= 0.8) continue;
      final at = Offset(
        (c - 1) * 8 * (0.4 + age),
        -16 - 46 * age + 52 * age * age,
      );
      canvas.drawCircle(at, 2.8, _fill(_gold, 1 - age / 0.8));
    }
    canvas.drawCircle(const Offset(0, -21), 4.2 * lit, _fill(_gold, alpha));
    canvas.drawCircle(
      const Offset(0, -21),
      4.2 * lit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF8A6418).withValues(alpha: alpha),
    );
  }

  void _barracks(Canvas canvas, double raised, double lit, double alpha) {
    _shadow(canvas, 30, alpha);
    _glow(canvas, const Offset(0, -8), 26, lit);
    _block(canvas, const Rect.fromLTRB(-12, -14, 12, 0), lit, alpha);
    canvas.drawRect(
      const Rect.fromLTRB(-3, -7, 3, 0),
      _fill(
        Color.lerp(_dim(const Color(0xFF3B3226)), _lamp, lit * 0.8)!,
        alpha,
      ),
    );
    canvas.drawLine(
      const Offset(-8, -16),
      const Offset(-8, -34),
      Paint()
        ..color = _dim(const Color(0xFF4A3B2A)).withValues(alpha: alpha)
        ..strokeWidth = 1.2,
    );
    final top = -18 - 16 * raised;
    canvas.drawPath(
      Path()
        ..moveTo(-8, top)
        ..lineTo(3, top)
        ..lineTo(3, top + 9)
        ..lineTo(-2.5, top + 6.5)
        ..lineTo(-8, top + 9)
        ..close(),
      _fill(_dim(_banner, lit), alpha),
    );
  }

  void _tavern(Canvas canvas, double age, double lit, double alpha) {
    _shadow(canvas, 28, alpha);
    _glow(canvas, const Offset(0, -8), 26, lit);
    canvas.drawRect(
      const Rect.fromLTRB(-10, -12, 10, 0),
      _fill(_dim(const Color(0xFFCDB58C), lit * 0.6), alpha),
    );
    final beam = Paint()
      ..color = _dim(const Color(0xFF5A4030)).withValues(alpha: alpha)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(-10, -6), const Offset(10, -6), beam);
    canvas.drawLine(const Offset(-10, -12), const Offset(-4, -6), beam);
    canvas.drawLine(const Offset(10, -12), const Offset(4, -6), beam);
    canvas.drawPath(
      Path()
        ..moveTo(-12, -12)
        ..lineTo(12, -12)
        ..lineTo(0, -21)
        ..close(),
      _fill(_dim(_roofs[2], lit * 0.3), alpha),
    );
    canvas.drawRect(
      const Rect.fromLTRB(5, -22, 8, -15),
      _fill(_dim(_stoneSide), alpha),
    );
    final glass = _fill(Color.lerp(_dim(_glass), _lamp, lit)!, alpha);
    canvas.drawRect(const Rect.fromLTWH(-7, -4.6, 3.4, 3.4), glass);
    canvas.drawRect(const Rect.fromLTWH(3.6, -4.6, 3.4, 3.4), glass);
    final swing = lit <= 0
        ? 0.0
        : 0.6 * math.exp(-3 * age) * math.sin(age * 12);
    canvas.save();
    canvas.translate(-13, -10);
    canvas.rotate(swing);
    canvas.drawRect(
      const Rect.fromLTWH(-3, 1.5, 6, 4.5),
      _fill(_dim(_gold, lit), alpha),
    );
    canvas.restore();
    if (lit <= 0) return;
    for (var i = 0; i < 3; i++) {
      final puff = age - i * 0.22;
      if (puff <= 0 || puff >= 1) continue;
      canvas.drawCircle(
        Offset(6.5 + puff * 7, -24 - puff * 22),
        2 + puff * 4,
        _fill(const Color(0xFFE8E4DC), 0.55 * (1 - puff)),
      );
    }
  }

  void _pill(Canvas canvas, Offset base, String text, double shown) {
    if (shown <= 0) return;
    final label = _label(text);
    final scale = Curves.easeOutBack.transform(shown);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: label.width + 14,
        height: label.height + 8,
      ),
      const Radius.circular(9),
    );
    canvas.save();
    canvas.translate(base.dx, base.dy + 13);
    canvas.scale(scale);
    canvas.drawRRect(rect, _fill(Colors.black, 0.58 * shown));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _gold.withValues(alpha: 0.85 * shown),
    );
    label.paint(canvas, Offset(-label.width / 2, -label.height / 2));
    canvas.restore();
  }

  void _scenery(Canvas canvas, Size size, double unit) {
    final horizon = size.height * _Town.horizon;
    final sky = Rect.fromLTWH(0, 0, size.width, horizon + 2);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              const Color(0xFF3B4C6E),
              const Color(0xFF070B1E),
              night,
            )!,
            Color.lerp(
              const Color(0xFF9A93A0),
              const Color(0xFF1B2140),
              night,
            )!,
          ],
        ).createShader(sky),
    );
    if (night > 0) {
      for (var i = 0; i < 26; i++) {
        canvas.drawCircle(
          Offset(
            _noise(i, 12.9898) * size.width,
            _noise(i, 39.425) * horizon * 0.92,
          ),
          0.6 + 0.9 * _noise(i, 78.233),
          _fill(Colors.white, night * (0.35 + 0.55 * _noise(i, 4.1414))),
        );
      }
    }
    final hills = Path()..moveTo(0, horizon + 4);
    for (var i = 0; i < 4; i++) {
      final x0 = size.width * i / 4;
      final x1 = size.width * (i + 1) / 4;
      hills.quadraticBezierTo(
        (x0 + x1) / 2,
        horizon - (6 + 7 * _noise(i, 3.7)) * unit,
        x1,
        horizon + 2,
      );
    }
    hills
      ..lineTo(size.width, horizon + 12)
      ..lineTo(0, horizon + 12)
      ..close();
    canvas.drawPath(hills, _fill(_dim(const Color(0xFF34503A))));
    final ground = Rect.fromLTRB(0, horizon + 2, size.width, size.height);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _dim(const Color(0xFF486A3C)),
            _dim(const Color(0xFF2A4126)),
          ],
        ).createShader(ground),
    );
    final tuft = _fill(_dim(const Color(0xFF2E4A2A)), 0.7);
    for (var i = 0; i < 40; i++) {
      final v = _Town.horizon + 0.06 + 0.9 * _noise(i, 91.17);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(_noise(i, 17.31) * size.width, v * size.height),
          width: 6 * unit,
          height: 2 * unit,
        ),
        tuft,
      );
    }
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8 * unit
      ..color = _dim(const Color(0xFF6E5B40));
    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5 * unit
      ..color = _dim(const Color(0xFFA48D68));
    for (final paint in [edge, road]) {
      for (final arm in _Town.arms) {
        Offset px(Offset u) => Offset(u.dx * size.width, u.dy * size.height);
        final a = px(arm[0]);
        final c = px(arm[1]);
        final b = px(arm[2]);
        canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy),
          paint,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = state.clock.value;
    final won = state.wonAt.isFinite ? t - state.wonAt : -1.0;
    final still = state.widget.still;
    night = won < 0 ? 0 : Curves.easeInOut.transform(_unit(won / 0.6));
    final unit =
        size.height / TownHero.height * (size.width / 330).clamp(0.82, 1.0);
    Offset px(Offset u) => Offset(u.dx * size.width, u.dy * size.height);
    double depth(Offset u) => unit * (0.6 + 0.55 * u.dy);
    final keep = px(_Town.keep);
    final burst = won - _TownHeroState.burstAt;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    canvas.save();
    canvas.clipRRect(frame);
    _scenery(canvas, size, unit);

    if (burst > 0) {
      final shine = still ? 1.0 : _unit(burst / 0.4);
      final turn = 0.4 * (1 - math.exp(-burst * 2));
      final centre = keep - Offset(0, 24 * unit);
      final reach = size.width * 0.62;
      final ray = Paint()
        ..shader = RadialGradient(
          colors: [
            _gold.withValues(alpha: 0.2 * shine),
            _gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: reach));
      for (var i = 0; i < 12; i++) {
        final a = turn + i * math.pi / 6;
        const half = 0.1;
        canvas.drawPath(
          Path()
            ..moveTo(centre.dx, centre.dy)
            ..lineTo(
              centre.dx + math.cos(a - half) * reach,
              centre.dy + math.sin(a - half) * reach,
            )
            ..lineTo(
              centre.dx + math.cos(a + half) * reach,
              centre.dy + math.sin(a + half) * reach,
            )
            ..close(),
          ray,
        );
      }
    }

    final items = <(double, void Function())>[];
    for (final house in _Town.shared.houses) {
      final raw = _unit((t - house.at) / _TownHeroState.pop);
      if (raw <= 0) continue;
      final lit = won < 0
          ? 0.0
          : _unit(
              (won -
                      _TownHeroState.lightFrom -
                      house.reach * _TownHeroState.lightSpan) /
                  0.25,
            );
      final base = px(house.spot);
      items.add((
        base.dy,
        () {
          final grow = 1 + 0.28 * math.sin(math.pi * lit) + 0.12 * lit;
          canvas.save();
          canvas.translate(
            base.dx,
            base.dy - (1 - Curves.easeOutCubic.transform(raw)) * 18 * unit,
          );
          canvas.scale(
            depth(house.spot) * Curves.easeOutBack.transform(raw) * grow,
          );
          _house(canvas, house, lit, _unit(raw * 3));
          canvas.restore();
        },
      ));
    }

    final allLit = won < 0 ? 0.0 : _unit((won - 0.1) / 0.3);
    for (var i = 0; i < _Town.landmarks.length; i++) {
      final mark = _Town.landmarks[i];
      final raw = _unit((t - mark.at) / 0.3);
      if (raw <= 0) continue;
      final age = t - mark.litAt;
      final lit = math.max(allLit, _unit(age / 0.3));
      final base = px(mark.spot);
      items.add((
        base.dy,
        () {
          final s =
              depth(mark.spot) *
              Curves.easeOutBack.transform(raw) *
              (1 + 0.14 * math.sin(math.pi * _unit(age / 0.3)) + 0.1 * allLit);
          canvas.save();
          canvas.translate(base.dx, base.dy);
          canvas.scale(s * 1.15);
          switch (i) {
            case 0:
              _market(canvas, age, lit, _unit(raw * 3));
            case 1:
              _barracks(
                canvas,
                Curves.easeOutCubic.transform(_unit(age / 0.5)),
                lit,
                _unit(raw * 3),
              );
            default:
              _tavern(canvas, age, lit, _unit(raw * 3));
          }
          canvas.restore();
        },
      ));
    }

    final keepRaw = _unit(
      (t - _TownHeroState.keepAt) /
          (_TownHeroState.keepLands - _TownHeroState.keepAt),
    );
    if (keepRaw > 0) {
      items.add((
        keep.dy,
        () {
          final drop = (1 - Curves.easeInCubic.transform(keepRaw)) * 60 * unit;
          final squash = t < _TownHeroState.keepLands + 0.25
              ? 1 -
                    0.1 *
                        math.sin(
                          math.pi *
                              _unit((t - _TownHeroState.keepLands) / 0.25),
                        )
              : 1.0;
          final glow = burst > 0 ? (still ? 1.0 : _unit(burst / 0.3)) : 0.0;
          canvas.save();
          canvas.translate(keep.dx, keep.dy - drop);
          canvas.scale(
            unit * 1.15 * (1 + 0.16 * allLit),
            unit * 1.15 * squash * (1 + 0.16 * allLit),
          );
          _keep(canvas, t, math.max(glow, allLit * 0.6), _unit(keepRaw * 4));
          canvas.restore();
        },
      ));
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    for (final item in items) {
      item.$2();
    }

    final landed = t - _TownHeroState.keepLands;
    if (landed > 0 && landed < 0.5 && won < 0) {
      final p = landed / 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: keep,
          width: (40 + 90 * p) * unit,
          height: (10 + 22 * p) * unit,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFE8DCC0).withValues(alpha: 0.7 * (1 - p)),
      );
    }

    for (var i = 0; i < _Town.landmarks.length; i++) {
      final mark = _Town.landmarks[i];
      final shown = math.max(allLit, _unit((t - mark.litAt) / 0.3));
      _pill(canvas, px(mark.spot), mark.label, shown);
    }
    canvas.restore();

    if (won < 0 || still) return;
    for (var r = 0; r < _TownHeroState.rockets.length; r++) {
      final rocket = _TownHeroState.rockets[r];
      final age = won - rocket.launch;
      if (age <= 0) continue;
      final from = Offset(rocket.x * size.width, size.height * 0.62);
      final peak = Offset(rocket.x * size.width, rocket.peak * size.height);
      if (age < _TownHeroState.rise) {
        final p = Curves.easeOutCubic.transform(age / _TownHeroState.rise);
        final head = Offset.lerp(from, peak, p)!;
        final tail = Offset.lerp(from, peak, math.max(0, p - 0.25))!;
        canvas.drawLine(
          tail,
          head,
          Paint()
            ..shader = LinearGradient(
              colors: [rocket.color.withValues(alpha: 0), rocket.color],
            ).createShader(Rect.fromPoints(tail, head))
            ..strokeWidth = 2,
        );
        canvas.drawCircle(head, 2.2, _fill(Colors.white));
        continue;
      }
      final spark = age - _TownHeroState.rise;
      if (spark >= _TownHeroState.sparkLife) continue;
      final fade = 1 - spark / _TownHeroState.sparkLife;
      if (spark < 0.18) {
        canvas.drawCircle(
          peak,
          (10 + 40 * spark) * unit,
          _fill(Colors.white, 0.5 * (1 - spark / 0.18)),
        );
      }
      for (var i = 0; i < 26; i++) {
        final a = i * math.pi * 2 / 26 + _noise(r, 5.1) * 0.4;
        final speed = (62 + 34 * _noise(i + r * 31, 78.233)) * unit;
        final at =
            peak +
            Offset(math.cos(a), math.sin(a)) *
                speed *
                spark *
                (1 - 0.35 * spark) +
            Offset(0, 42 * unit * spark * spark);
        canvas.drawCircle(
          at,
          (1.4 + 1.6 * fade) * unit,
          _fill(i.isEven ? rocket.color : const Color(0xFFFFF6DA), fade * fade),
        );
      }
    }
    if (burst > 0 && burst < 1.4) {
      final fade = 1 - burst / 1.4;
      canvas.drawCircle(
        keep - Offset(0, 24 * unit),
        40 + 300 * burst,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _gold.withValues(alpha: 0.7 * fade * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_TownPainter old) => true;
}
