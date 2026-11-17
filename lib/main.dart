import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const App());

const red = Color(0xFFD50000);

// الدور: [الاسم، الوظيفة]
const roles = <String, List<String>>{
  'villager': ['القروي', 'ليس لك قدرة خاصة. في النهار ناقش وصوّت لإقصاء من تشك أنه ذئب.'],
  'wolf': ['الذئب', 'في الليل تستيقظ مع بقية الذئاب وتختارون ضحية. في النهار تظاهر أنك قروي. تفوزون إذا صار عددكم مثل القرويين أو أكثر.'],
  'seer': ['العرّافة', 'كل ليلة تشير للراوي على لاعب، فيخبرك سرّاً هل هو ذئب أم لا.'],
  'witch': ['الساحرة', 'معك جرعتان تُستعملان مرة واحدة: جرعة تنقذ ضحية الذئاب، وجرعة تقتل من تشك فيه.'],
  'hunter': ['الصياد', 'إذا قُتلت أو أُقصيت، تطلق رصاصة أخيرة وتقتل لاعباً تختاره.'],
  'cupid': ['كيوبيد', 'في الليلة الأولى تربط لاعبين كعاشقين. إذا مات أحدهما مات الآخر.'],
};

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(primary: red, surface: Colors.black),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: red),
        ),
        builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
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
            child: Text(t, style: const TextStyle(fontSize: 20)),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('لوقارو', style: TextStyle(fontSize: 56, color: red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            btn(context, 'أنا الراوي', const Setup()),
            btn(context, 'أنا لاعب', const Scan()),
          ]),
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
          Text('الأدوار: $total من ${names.length}', style: const TextStyle(color: red, fontSize: 18)),
          for (final k in roles.keys)
            ListTile(
              title: Text(roles[k]![0]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: counts[k]! > 0 ? () => setState(() => counts[k] = counts[k]! - 1) : null,
                ),
                Text('${counts[k]}', style: const TextStyle(fontSize: 18)),
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
              Text(p.name, style: const TextStyle(fontSize: 24, color: red)),
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
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('اضغط على اسم اللاعب ليظهر رمز بطاقته، ثم يمسحه من هاتفه.'),
          ),
          for (final p in widget.ps)
            ListTile(
              title: Text(p.name,
                  style: TextStyle(fontSize: 20, decoration: p.dead ? TextDecoration.lineThrough : null)),
              subtitle: Text(roles[p.role]![0], style: const TextStyle(color: red)),
              trailing: Switch(value: p.dead, onChanged: (v) => setState(() => p.dead = v)),
              onTap: () => showQr(p),
            ),
        ]),
      );
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
              border: Border.all(color: red, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.name, style: const TextStyle(fontSize: 22, color: Colors.white54)),
              const SizedBox(height: 32),
              if (shown) ...[
                Text(r[0], style: const TextStyle(fontSize: 48, color: red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text(r[1], textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, height: 1.6)),
              ] else
                const Text('اضغط مع الاستمرار\nلرؤية بطاقتك',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 26, color: red)),
            ]),
          ),
        ),
      ),
    );
  }
}
