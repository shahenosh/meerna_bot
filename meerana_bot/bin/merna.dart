import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

// ===================== الإعدادات =====================
const String OWNER_JID = "almuftrs@syriatalk.info";
const String BOT_JID_STR = "tsunamei@syriatalk.info";
const String BOT_PASS = "tsunamei123";
const String BOT_NICK = "MeRnA";
const String STATUS_TEXT = "بوت ميرنا لطلبي اضف almuftrs";
// ===================================================

void main() async {
  // --- إضافة البورت الوهمي لخداع سيرفر Render المجاني ---
  var port = int.parse(Platform.environment['PORT'] ?? '8080');
  HttpServer.bind(InternetAddress.anyIPv4, port).then((server) {
    print("🌐 Fake Web Server started on port $port (Render Trick)");
  });
  // --------------------------------------------------

  MernaLegendBot().run();
}

class MernaLegendBot {
  late xmpp.Connection connection;
  String lastRoom = "";
  final Random _random = Random();

  List<Map<String, String>> riddlesList = [];
  List<String> futurePredictions = [];
  List<String> funnyPrizes = [];

  String currentAnswer = "";
  String targetNick = "";
  bool isRiddleActive = false;
  Timer? riddleTimer;

  final Map<String, int> horoIds = {
    "الحمل": 1, "الثور": 2, "الجوزاء": 3, "السرطان": 4, "الأسد": 5, "الاسد": 5,
    "العذراء": 6, "الميزان": 7, "العقرب": 8, "القوس": 9, "الجدي": 10, "الدلو": 11, "الحوت": 12
  };

  final List<String> userDescriptions = [
    "ياسمينة شامية بتنشر ريحة طيبة وين ما كانت 🌸",
    "قلبه أبيض من التلج ولسانه بينقط عسل مهضوم 🍯",
    "رايق وميوزك وبيحب كاسة المتة بفيّة الياسمين 🧉",
    "شخصية قوية ومهيبة والكل بيحسبله ألف حساب 👑",
    "روح الروم وضحكته بتعدي الكل بالإيجابية ✨",
    "فنان بالردود ودايماً حضوره إله نكهة خاصة 🍭"
  ];

  void run() {
    _initFiles();
    _loadRoom();
    var jid = xmpp.Jid.fromFullJid(BOT_JID_STR);
    final settings = xmpp.XmppAccountSettings(
        BOT_JID_STR, jid.local, jid.domain, BOT_PASS, 5222,
        host: "syriatalk.info");
    settings.resource = BOT_NICK;
    connection = xmpp.Connection(settings);
    connection.connect();
    connection.connectionStateStream.listen((state) {
      if (state == xmpp.XmppConnectionState.Authenticated) {
        print("✅ ميرنا أونلاين بـ Dart صافي!");
        _updatePresence();
        _setup();
        if (lastRoom.isNotEmpty)
          Timer(Duration(seconds: 2), () => _join(lastRoom));
      }
    });
  }

  void _initFiles() {
    try {
      File fRiddles = File('riddles.txt');
      if (fRiddles.existsSync()) {
        riddlesList = fRiddles.readAsLinesSync().where((l) => l.contains('|')).map((l) {
          var parts = l.split('|');
          return {"q": parts[0].trim(), "a": parts[1].trim()};
        }).toList();
      }
      File fFuture = File('future.txt');
      if (fFuture.existsSync()) futurePredictions = fFuture.readAsLinesSync().where((l) => l.isNotEmpty).toList();
      File fPrizes = File('prizes.txt');
      if (fPrizes.existsSync()) funnyPrizes = fPrizes.readAsLinesSync().where((l) => l.isNotEmpty).toList();
    } catch (e) { print("❌ خطأ بالملفات: $e"); }
  }

  void _setup() {
    xmpp.MessageHandler.getInstance(connection).messagesStream.listen((msg) async {
      if (msg == null || msg.body == null || msg.fromJid?.resource == BOT_NICK) return;

      final body = msg.body!.trim();
      final senderNick = msg.fromJid?.resource ?? "عضو";
      final isGroup = (msg.type == xmpp.MessageStanzaType.GROUPCHAT);

      if (body.startsWith("حزورة ")) {
        if (isRiddleActive) return;
        String target = body.replaceFirst("حزورة ", "").trim();
        if (target.isNotEmpty && riddlesList.isNotEmpty) {
          var riddle = riddlesList[_random.nextInt(riddlesList.length)];
          currentAnswer = riddle['a']!;
          targetNick = target;
          isRiddleActive = true;
          _send(msg.fromJid!, "🤔 حزيره لـ [$targetNick]:\n📝 ${riddle['q']}\n━━━━━━━━━━━━━\n⏱️ معك 30 ثانية!", isGroup);
          riddleTimer = Timer(Duration(seconds: 30), () {
            if (isRiddleActive) {
              _send(msg.fromJid!, "⏰ خلص الوقت لـ [$targetNick]! الجواب: [$currentAnswer] 😋", isGroup);
              _resetRiddle();
            }
          });
          return;
        }
      }

      if (isRiddleActive && body == currentAnswer && senderNick == targetNick) {
          riddleTimer?.cancel();
          String prize = funnyPrizes.isNotEmpty ? funnyPrizes[_random.nextInt(funnyPrizes.length)] : "بوسة 💋";
          _send(msg.fromJid!, "🎉 مبروك [$senderNick] جوابك صح!\n🎁 ربحت: $prize", isGroup);
          _resetRiddle();
          return;
      }

      if (body.toLowerCase() == "بوت") { _send(msg.fromJid!, "يا عيون البوت.. شو بدك 🌸", isGroup); }
      else if (body.startsWith("نكز ")) { _send(msg.fromJid!, "👉 [$senderNick] ينكز [${body.replaceFirst("نكز ", "").trim()}].. وين غطست؟ 🌸", isGroup); }
      else if (body == "حظي") { _send(msg.fromJid!, "✨ [$senderNick] حظك اليوم هو: ${_random.nextInt(101)}% 🍀", isGroup); }
      else if (body.startsWith("وصف ")) { _send(msg.fromJid!, "📝 وصف [${body.replaceAll("وصف ", "").trim()}]: ${userDescriptions[_random.nextInt(userDescriptions.length)]}", isGroup); }
      else if (body.startsWith("برج ")) { _send(msg.fromJid!, "⏳ ثواني...\n" + await _fetchFromElabraj(body.replaceAll("برج ", "").trim()), isGroup); }
      else if (body.startsWith("تفسير ")) { _send(msg.fromJid!, "⏳ ثواني...\n" + await _fetchDream(body.replaceAll("تفسير ", "").trim()), isGroup); }
      else if (body == "تست") { _send(msg.fromJid!, "📢 شغال ليرة ذهب ✅", isGroup); }
      else if (msg.fromJid?.userAtDomain == OWNER_JID) {
        if (body.startsWith("اذهب ")) { lastRoom = body.split(" ")[1]; _saveRoom(lastRoom); _join(lastRoom); }
        else if (body == "ريستارت") exit(0);
      }
    });
  }

  void _resetRiddle() { currentAnswer = ""; targetNick = ""; isRiddleActive = false; riddleTimer?.cancel(); }

  Future<String> _fetchDream(String dream) async {
    try {
      final url = Uri.parse("https://www.tafsir-ahlam.com/search?q=" + Uri.encodeComponent(dream));
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      var doc = parse(utf8.decode(res.bodyBytes));
      return doc.querySelector('.entry-summary p')?.text.trim() ?? "ما لقيت تفسير.";
    } catch (e) { return "❌ خطأ اتصال."; }
  }

  Future<String> _fetchFromElabraj(String sign) async {
    int? id = horoIds[sign];
    if (id == null) return "اكتب اسم البرج صح.";
    try {
      final url = Uri.parse("https://www.elabraj.net/ar/horoscope/daily/" + id.toString());
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      var doc = parse(utf8.decode(res.bodyBytes));
      String text = doc.querySelector('.horoscope-daily-text')?.text.trim() ?? "فشل سحب البرج.";
      return text.replaceAll("مهنياً:", "\n\n🔹 مهنياً:").replaceAll("عاطفياً:", "\n\n🔹 عاطفياً:").replaceAll("صحياً:", "\n\n🔹 صحياً:");
    } catch (e) { return "❌ خطأ أبراج."; }
  }

  void _updatePresence() { var p = xmpp.PresenceStanza(); p.status = STATUS_TEXT; connection.writeStanza(p); }
  void _join(String r) => connection.write("<presence to='$r/$BOT_NICK'><x xmlns='http://jabber.org/protocol/muc'/></presence>");
  void _send(xmpp.Jid to, String txt, bool gp) {
    final s = xmpp.MessageStanza(xmpp.AbstractStanza.getRandomId(), gp ? xmpp.MessageStanzaType.GROUPCHAT : xmpp.MessageStanzaType.CHAT);
    s.toJid = gp ? xmpp.Jid.fromFullJid(to.local + "@" + to.domain) : to;
    s.body = txt;
    connection.writeStanza(s);
  }
  void _saveRoom(String r) => File("room.txt").writeAsStringSync(r);
  void _loadRoom() { if (File("room.txt").existsSync()) lastRoom = File("room.txt").readAsStringSync(); }
}
