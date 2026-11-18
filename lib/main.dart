import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const App());

const red = Color(0xFFD50000);

const roles = <String, List<String>>{
  'villager': ['القروي', 'ليس لك قدرة خاصة. في النهار ناقش وصوّت لإقصاء من تشك أنه ذئب.'],
  'wolf': ['الذئب', 'في الليل تستيقظ مع بقية الذئاب وتختارون ضحية. في النهار تظاهر أنك قروي. تفوزون إذا صار عددكم مثل القرويين أو أكثر.'],
  'seer': ['العرّافة', 'كل ليلة تشير للراوي على لاعب، فيخبرك سرّاً هل هو ذئب أم لا.'],
  'witch': ['الساحرة', 'معك جرعتان تُستعملان مرة واحدة: جرعة تنقذ ضحية الذئاب، وجرعة تقتل من تشك فيه.'],
  'hunter': ['الصياد', 'إذا قُتلت أو أُقصيت، تطلق رصاصة أخيرة وتقتل لاعباً تختاره.'],
  'cupid': ['كيوبيد', 'في الليلة الأولى تربط لاعبين كعاشقين. إذا مات أحدهما مات الآخر.'],
};

// ---------- الخلفية: دماء ----------
class BloodBg extends StatelessWidget {
  const BloodBg({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BloodPainter(), size: Size.infinite);
}

class _BloodPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A0000), Colors.black],
          stops: [0, 0.45],
        ).createShader(r),
    );
    final rnd = Random(7);
    final blood = Paint()..color = const Color(0xFF8B0000);
    c.drawRect(Rect.fromLTWH(0, 0, s.width, 22), blood);
    for (var i = 0; i < 9; i++) {
      final w = 10 + rnd.nextDouble() * 12;
      final x = (i + rnd.nextDouble() * 0.6) * s.width / 9;
      final h = 50 + rnd.nextDouble() * s.height * 0.22;
      c.drawRRect(RRect.fromLTRBR(x, 0, x + w, h, Radius.circular(w / 2)), blood);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- رأس الذئب ----------
class WolfHead extends StatelessWidget {
  final double size;
  const WolfHead({super.key, this.size = 160});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _WolfPainter());
}

class _WolfPainter extends CustomPainter {
  static const _l = <Offset>[
    Offset(72, 48), Offset(55, 0), Offset(38, 60), Offset(18, 95), Offset(30, 120),
    Offset(22, 150), Offset(55, 150), Offset(72, 185), Offset(88, 195),
  ];
  static const _eye = <Offset>[Offset(56, 98), Offset(86, 108), Offset(62, 111)];

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 200;
    Offset t(Offset p) => Offset(p.dx * k, p.dy * k);
    Offset m(Offset p) => Offset(200 - p.dx, p.dy);

    final head = <Offset>[
      const Offset(100, 55), ..._l, const Offset(100, 198), ..._l.reversed.map(m),
    ].map(t).toList();
    final path = Path()..addPolygon(head, true);
    c.drawPath(path, Paint()..color = const Color(0xFF1C1C1C));
    c.drawPath(
      path,
      Paint()
        ..color = red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * k
        ..strokeJoin = StrokeJoin.round,
    );

    final eyes = Path()
      ..addPolygon(_eye.map(t).toList(), true)
      ..addPolygon(_eye.map(m).map(t).toList(), true);
    c.drawPath(
      eyes,
      Paint()
        ..color = const Color(0xFFFF2828)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * k),
    );
    c.drawPath(eyes, Paint()..color = const Color(0xFFFF4040));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Lalezar',
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(primary: red, surface: Color(0xFF140000)),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: red,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        builder: (c, w) => Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(fit: StackFit.expand, children: [const BloodBg(), w!]),
        ),
        home: const Home(),
      );
}

class Home extends StatelessWidget {
  const Home({super.key});
  Widget btn(BuildContext c, String t, Widget page) => Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 260,
          height: 56,
          child: FilledButton(
            onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
            child: Text(t, style: const TextStyle(fontSize: 22)),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const WolfHead(size: 150),
              const SizedBox(height: 8),
              const Text('لوقارو', style: TextStyle(fontSize: 60, color: red)),
              const SizedBox(height: 24),
              btn(context, 'أنا الراوي', const Setup()),
              btn(context, 'أنا لاعب', const Scan()),
            ]),
          ),
        ),
      );
}

class Player {
  final String name, role;
  bool dead = false;
  Player(this.name, this.role);
  String get code => 'WW|$name|$role';
}

// ---------- الراوي: الإعداد ----------
class Setup extends StatefulWidget {
  const Setup({super.key});
  @override
  State<Setup> createState() => _SetupState();
}

class _SetupState extends State<Setup> {
  final names = <String>[];
  final counts = {for (final k in roles.keys) k: 0};
  final ctl = TextEditingController();
  int get total => counts.values.fold(0, (a, b) => a + b);

  void add() {
    final n = ctl.text.trim();
    if (n.isNotEmpty) setState(() { names.add(n); ctl.clear(); });
  }

  void deal() {
    final pool = [for (final e in counts.entries) ...List.filled(e.value, e.key)]..shuffle(Random());
    final ps = [for (var i = 0; i < names.length; i++) Player(names[i], pool[i])];
    Navigator.push(context, MaterialPageRoute(builder: (_) => Board(ps)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إعداد اللعبة')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
            controller: ctl,
            onSubmitted: (_) => add(),
            decoration: InputDecoration(
              labelText: 'اسم اللاعب',
              suffixIcon: IconButton(icon: const Icon(Icons.add, color: red), onPressed: add),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final n in names) Chip(label: Text(n), onDeleted: () => setState(() => names.remove(n))),
          ]),
          const Divider(height: 32),
          Text('الأدوار: $total من ${names.length}', style: const TextStyle(color: red, fontSize: 20)),
          for (final k in roles.keys)
            ListTile(
              title: Text(roles[k]![0]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: counts[k]! > 0 ? () => setState(() => counts[k] = counts[k]! - 1) : null,
                ),
                Text('${counts[k]}', style: const TextStyle(fontSize: 20)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => counts[k] = counts[k]! + 1),
                ),
              ]),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: names.length >= 3 && total == names.length ? deal : null,
            child: const Text('وزّع البطاقات'),
          ),
        ]),
      );
}

// ---------- الراوي: اللوحة ----------
class Board extends StatefulWidget {
  final List<Player> ps;
  const Board(this.ps, {super.key});
  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  void showQr(Player p) => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(p.name, style: const TextStyle(fontSize: 26, color: red)),
              const SizedBox(height: 12),
              QrImageView(data: p.code, size: 240, backgroundColor: Colors.white),
              const SizedBox(height: 8),
              const Text('يمسحه اللاعب صاحب الاسم فقط'),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: p.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الكود، أرسله للاعب سرّاً')));
                },
                child: const Text('نسخ الكود'),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('لوحة الراوي (سرّية)')),
        body: ListView(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('دليل الراوي: ماذا أقول؟'),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GuidePage({for (final p in widget.ps) p.role}))),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('اضغط على اسم اللاعب ليظهر رمز بطاقته. والمفتاح لتعليم من مات.'),
          ),
          for (final p in widget.ps)
            ListTile(
              title: Text(p.name,
                  style: TextStyle(fontSize: 22, decoration: p.dead ? TextDecoration.lineThrough : null)),
              subtitle: Text(roles[p.role]![0], style: const TextStyle(color: red)),
              trailing: Switch(value: p.dead, onChanged: (v) => setState(() => p.dead = v)),
              onTap: () => showQr(p),
            ),
        ]),
      );
}

// ---------- الراوي: الدليل ----------
class Step {
  final String title, say, todo;
  const Step(this.title, this.say, this.todo);
}

List<Step> buildSteps(Set<String> r, bool first) => [
      if (first)
        const Step('قبل البدء',
            'سنلعب لوقارو. كل واحد يفتح بطاقته سرّاً ولا يُريها لأحد. ومن يموت يسكت ولا يتكلم.',
            'تأكد أن كل لاعب شاف بطاقته وأخفاها.'),
      const Step('الليل: الجميع ينام',
          'حلّ الليل على القرية. الجميع يغمض عينيه وينام، ولا أحد يفتح عينيه.',
          'انتظر حتى يسكت الجميع.'),
      if (first && r.contains('cupid'))
        const Step('كيوبيد',
            'يستيقظ كيوبيد ويشير إلى عاشقين. ثم ينام كيوبيد.',
            'المس كتف العاشقين بهدوء ليعرفا بعضهما، ثم ينامان.'),
      if (r.contains('seer'))
        const Step('العرّافة',
            'تستيقظ العرّافة وتشير إلى لاعب تريد معرفة هويته. ثم تنام العرّافة.',
            'هزّ رأسك: نعم إن كان ذئباً، ولا إن لم يكن.'),
      const Step('الذئاب',
          'يستيقظ الذئاب ويشيرون بصمت إلى الضحية. ثم ينام الذئاب.',
          'تذكّر من اختاروه، ولا تعلّمه ميتاً الآن.'),
      if (r.contains('witch'))
        const Step('الساحرة',
            'تستيقظ الساحرة. هذا ضحية الذئاب، هل تنقذه؟ وهل تقتل أحداً؟ ثم تنام الساحرة.',
            'أشر لها على ضحية الذئاب. كل جرعة تُستعمل مرة واحدة فقط في اللعبة.'),
      Step('النهار: من مات؟',
          'طلع النهار، الجميع يفتح عينيه. في هذه الليلة مات: (اذكر الاسم، أو قل: لم يمت أحد).',
          'علّم القتلى في لوحة الراوي.'
          '${r.contains('hunter') ? ' إذا كان الصياد بينهم يطلق رصاصته الآن.' : ''}'
          '${r.contains('cupid') ? ' إذا مات أحد العاشقين يموت الآخر.' : ''}'),
      const Step('النقاش والتصويت',
          'ناقشوا: من تشكّون أنه ذئب؟ ثم صوّتوا برفع اليد. من يأخذ أكثر الأصوات يخرج من اللعبة.',
          'علّم المُقصى في اللوحة. اتفقوا قبل اللعب هل يكشف دوره أم لا.'),
      const Step('هل انتهت اللعبة؟',
          'إذا ما بقي أي ذئب فاز القرويون. وإذا صار الذئاب مثل القرويين أو أكثر فاز الذئاب.',
          'غير ذلك: اضغط «ليلة جديدة».'),
    ];

class GuidePage extends StatefulWidget {
  final Set<String> roles;
  const GuidePage(this.roles, {super.key});
  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  bool first = true;
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final steps = buildSteps(widget.roles, first);
    final s = steps[i];
    final last = i == steps.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(first ? 'الدورة الأولى' : 'ليلة جديدة')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الخطوة ${i + 1} من ${steps.length}', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text(s.title, style: const TextStyle(fontSize: 36, color: red)),
          const SizedBox(height: 24),
          const Text('قل بصوت عالٍ:', style: TextStyle(color: red)),
          Text(s.say, style: const TextStyle(fontSize: 24, height: 1.6)),
          const SizedBox(height: 24),
          const Text('وأنت افعل:', style: TextStyle(color: red)),
          Text(s.todo, style: const TextStyle(fontSize: 20, height: 1.6, color: Colors.white70)),
          const Spacer(),
          Row(children: [
            if (i > 0)
              OutlinedButton(onPressed: () => setState(() => i--), child: const Text('السابق')),
            const Spacer(),
            FilledButton(
              onPressed: () => setState(() {
                if (last) {
                  first = false;
                  i = 0;
                } else {
                  i++;
                }
              }),
              child: Text(last ? 'ليلة جديدة' : 'التالي'),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ---------- اللاعب: المسح ----------
class Scan extends StatefulWidget {
  const Scan({super.key});
  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  bool done = false;
  final ctl = TextEditingController();

  bool open(String v) {
    final parts = v.trim().split('|');
    if (done || parts.length != 3 || parts[0] != 'WW' || !roles.containsKey(parts[2])) return false;
    done = true;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => CardPage(parts[1], parts[2])));
    return true;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('امسح رمز بطاقتك')),
        body: Column(children: [
          Expanded(
            child: MobileScanner(
              errorBuilder: (c, e, w) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر فتح الكاميرا\n${e.errorCode.name}\n${e.errorDetails?.message ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: red, fontSize: 16),
                  ),
                ),
              ),
              onDetect: (cap) {
                final v = cap.barcodes.isEmpty ? null : cap.barcodes.first.rawValue;
                if (v != null) open(v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: ctl,
                  decoration: const InputDecoration(labelText: 'أو الصق الكود هنا'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (!open(ctl.text)) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('الكود غير صحيح')));
                  }
                },
                child: const Text('افتح'),
              ),
            ]),
          ),
        ]),
      );
}

// ---------- اللاعب: البطاقة ----------
class CardPage extends StatefulWidget {
  final String name, role;
  const CardPage(this.name, this.role, {super.key});
  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool shown = false;
  @override
  Widget build(BuildContext context) {
    final r = roles[widget.role]!;
    return Scaffold(
      body: SafeArea(
        child: Listener(
          onPointerDown: (_) => setState(() => shown = true),
          onPointerUp: (_) => setState(() => shown = false),
          onPointerCancel: (_) => setState(() => shown = false),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xAA000000),
              border: Border.all(color: red, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.name, style: const TextStyle(fontSize: 24, color: Colors.white54)),
              const SizedBox(height: 24),
              if (shown) ...[
                if (widget.role == 'wolf') const WolfHead(size: 130),
                Text(r[0], style: const TextStyle(fontSize: 52, color: red)),
                const SizedBox(height: 20),
                Text(r[1], textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, height: 1.6)),
              ] else
                const Text('اضغط مع الاستمرار\nلرؤية بطاقتك',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 28, color: red)),
            ]),
          ),
        ),
      ),
    );
  }
}
