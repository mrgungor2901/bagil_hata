import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(HesaplamaKaydiAdapter());
  Hive.registerAdapter(AyarlarAdapter());

  await Hive.openBox<HesaplamaKaydi>('gecmis_kayitlar');
  await Hive.openBox<Ayarlar>('ayarlar');

  runApp(const BagilHataApp());
}


String truncateToTwoDecimals(double value) {
  String text = value.toString();
  if (text.contains('.')) {
    final parts = text.split('.');
    final decimal = parts[1].padRight(2, '0').substring(0, 2);
    return '${parts[0]}.$decimal';
  } else {
    return '$text.00';
  }
}
class HesaplamaKaydiAdapter extends TypeAdapter<HesaplamaKaydi> {
  @override
  final int typeId = 0;

  @override
  HesaplamaKaydi read(BinaryReader reader) {
    return HesaplamaKaydi(
      tarihSaat: reader.readString(),
      dispenser: reader.readString(),
      mastermetre: reader.readString(),
      hata: reader.readString(),
      sonuc: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, HesaplamaKaydi obj) {
    writer.writeString(obj.tarihSaat);
    writer.writeString(obj.dispenser);
    writer.writeString(obj.mastermetre);
    writer.writeString(obj.hata);
    writer.writeString(obj.sonuc);
  }
}

class HesaplamaKaydi {
  final String tarihSaat;
  final String dispenser;
  final String mastermetre;
  final String hata;
  final String sonuc;

  HesaplamaKaydi({
    required this.tarihSaat,
    required this.dispenser,
    required this.mastermetre,
    required this.hata,
    required this.sonuc,
  });
}

class AyarlarAdapter extends TypeAdapter<Ayarlar> {
  @override
  final int typeId = 1;

  @override
  Ayarlar read(BinaryReader reader) {
    return Ayarlar(
      toleransDegeri: reader.readDouble(),
      koyu_tema: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Ayarlar obj) {
    writer.writeDouble(obj.toleransDegeri);
    writer.writeBool(obj.koyu_tema);
  }
}

class Ayarlar {
  final double toleransDegeri;
  final bool koyu_tema;

  Ayarlar({
    this.toleransDegeri = 1.0,
    this.koyu_tema = false,
  });
}

class BagilHataApp extends StatefulWidget {
  const BagilHataApp({super.key});

  @override
  State<BagilHataApp> createState() => _BagilHataAppState();
}

class _BagilHataAppState extends State<BagilHataApp> {
  bool koyuTema = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final box = Hive.box<Ayarlar>('ayarlar');
      final ayarlar = box.get('ayarlar', defaultValue: Ayarlar())!;
      if (mounted) {
        setState(() {
          koyuTema = ayarlar.koyu_tema;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          koyuTema = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bağıl Hata Hesaplayıcısı',
      debugShowCheckedModeBanner: false,
      themeMode: koyuTema ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4), // Cyan accent
          brightness: Brightness.dark,
        ).copyWith(
          background: const Color(0xFF0A0E21),
          surface: const Color(0xFF1D1E33),
          primary: const Color(0xFF00BCD4),
          secondary: const Color(0xFF8C52FF),
        ),
      ),
      home: HomePage(onThemeChanged: _loadTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onThemeChanged;
  
  const HomePage({super.key, required this.onThemeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController dispenserController = TextEditingController();
  final TextEditingController mastermetreController = TextEditingController();
  final FocusNode masterFocusNode = FocusNode();

  double? hataYuzdesi;
  String? uygunluk;
  bool hasAutoMoved = false;
  bool hesaplandi = false;

  List<HesaplamaKaydi> gecmisKayitlar = [];
  double tolerans = 1.0;

  void hesapla() {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();
    
    final double? dispenser =
        double.tryParse(dispenserController.text.replaceAll(',', '.'));
    final double? mastermetre =
        double.tryParse(mastermetreController.text.replaceAll(',', '.'));

    if (dispenser != null && mastermetre != null && mastermetre != 0) {
      final double hata = ((dispenser - mastermetre) / mastermetre) * 100;
      final sonuc = (hata >= -tolerans && hata <= tolerans) ? "✅ Uygun" : "❌ Uygun Değil";
      final kayit = HesaplamaKaydi(
        tarihSaat: DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
        dispenser: dispenser.toString(),
        mastermetre: mastermetre.toString(),
        hata: truncateToTwoDecimals(hata),
        sonuc: sonuc,
      );

      Hive.box<HesaplamaKaydi>('gecmis_kayitlar').add(kayit);

      setState(() {
        hataYuzdesi = hata;
        uygunluk = sonuc;
        hesaplandi = true;
        gecmisKayitlar = Hive.box<HesaplamaKaydi>('gecmis_kayitlar')
            .values
            .toList()
            .reversed
            .toList();
      });
    } else {
      setState(() {
        uygunluk = "Geçerli değerler giriniz!";
        hataYuzdesi = null;
        hesaplandi = true;
        hasAutoMoved = false;
      });
    }
  }
  void loadKayitlar() {
    final box = Hive.box<HesaplamaKaydi>('gecmis_kayitlar');
    setState(() {
      gecmisKayitlar = box.values.toList().reversed.toList();
    });
  }

  void loadAyarlar() {
    try {
      final box = Hive.box<Ayarlar>('ayarlar');
      if (box.isEmpty) {
        box.put('ayarlar', Ayarlar());
      }
      final ayarlar = box.get('ayarlar', defaultValue: Ayarlar())!;
      setState(() {
        tolerans = ayarlar.toleransDegeri;
      });
    } catch (e) {
      // Web'de hata olursa varsayılan değeri kullan
      setState(() {
        tolerans = 1.0;
      });
    }
  }

  @override
  void dispose() {
    dispenserController.dispose();
    mastermetreController.dispose();
    masterFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadKayitlar();
    loadAyarlar(); 

    dispenserController.addListener(() {
      String raw = dispenserController.text.replaceAll('.', '');
      if (raw.length > 4) raw = raw.substring(0, 4);

      if (raw.length == 4 && !hasAutoMoved) {
        String formatted = '${raw.substring(0, 2)}.${raw.substring(2)}';
        dispenserController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );

        hasAutoMoved = true;
        mastermetreController.clear();
        FocusScope.of(context).requestFocus(masterFocusNode);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          mastermetreController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: mastermetreController.text.length,
          );
        });
      }
      if (raw.length < 4) hasAutoMoved = false;
    });

    mastermetreController.addListener(() {
      String raw = mastermetreController.text.replaceAll('.', '');
      if (raw.length > 4) raw = raw.substring(0, 4);

      if (raw.length == 4) {
        String formatted = '${raw.substring(0, 2)}.${raw.substring(2)}';
        mastermetreController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });

    masterFocusNode.addListener(() {
      if (masterFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          mastermetreController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: mastermetreController.text.length,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF0A0E21), const Color(0xFF1D1E33), const Color(0xFF0A0E21)]
                : [const Color(0xFF72C6EF), const Color(0xFF004E92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        const Expanded(
                          child: Text(
                            'Bağıl Hata Hesaplayıcısı',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AyarlarPage()),
                            );
                            loadAyarlar();
                            widget.onThemeChanged();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '±${tolerans.toStringAsFixed(1)}% bağıl hata toleransı aralığında değerlendirme yapılır.',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1D1E33).withOpacity(0.8)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark 
                              ? const Color(0xFF00BCD4).withOpacity(0.3)
                              : Colors.white30,
                          width: 1.5,
                        ),
                        boxShadow: isDark ? [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ] : [],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: dispenserController,
                            label: 'Dispenser Hacmi (örn: 12.34)',
                            onTapClear: () {
                              if (hesaplandi) {
                                setState(() {
                                  dispenserController.clear();
                                  mastermetreController.clear();
                                  hataYuzdesi = null;
                                  uygunluk = null;
                                  hesaplandi = false;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: mastermetreController,
                            focusNode: masterFocusNode,
                            label: 'Mastermetre Hacmi',
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: hesapla,
                                  icon: const Icon(Icons.calculate),
                                  label: const Text("HESAPLA"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark 
                                        ? const Color(0xFF00BCD4)
                                        : Colors.white,
                                    foregroundColor: isDark 
                                        ? const Color(0xFF0A0E21)
                                        : Colors.blueAccent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: isDark ? 8 : 2,
                                    shadowColor: isDark 
                                        ? const Color(0xFF00BCD4).withOpacity(0.5)
                                        : Colors.black26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.white),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Hesaplama Mantığı'),
                                      content: const Text(
                                        '[(Dispenser - Mastermetre) / Mastermetre] x 100\n'
                                        '±1% aralıkta ise uygun kabul edilir.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Kapat"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => DraggableScrollableSheet(
                                  initialChildSize: 0.7,
                                  minChildSize: 0.5,
                                  maxChildSize: 0.95,
                                  builder: (_, controller) => Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1D1E33) : Colors.white,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      border: isDark ? Border.all(
                                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                                        width: 1,
                                      ) : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark 
                                                ? const Color(0xFF0A0E21)
                                                : Colors.blue[50],
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Geçmiş Hesaplamalar',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? const Color(0xFF00BCD4) : Colors.black87,
                                                ),
                                              ),
                                              if (gecmisKayitlar.isNotEmpty)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                                                  tooltip: 'Tümünü Sil',
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => AlertDialog(
                                                        title: const Text('Emin misiniz?'),
                                                        content: const Text(
                                                          'Tüm geçmiş kayıtları silmek istediğinizden emin misiniz?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('İptal'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              await Hive.box<HesaplamaKaydi>('gecmis_kayitlar').clear();
                                                              if (context.mounted) {
                                                                setState(() {
                                                                  gecmisKayitlar.clear();
                                                                });
                                                                Navigator.pop(context);
                                                                Navigator.pop(context);
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text('Tüm kayıtlar silindi'),
                                                                    duration: Duration(seconds: 2),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            child: const Text(
                                                              'Sil',
                                                              style: TextStyle(color: Colors.red),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: gecmisKayitlar.isEmpty
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.history, 
                                                        size: 64, 
                                                        color: isDark ? const Color(0xFF4A5568) : Colors.grey,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        "Henüz geçmiş kaydı yok.",
                                                        style: TextStyle(
                                                          fontSize: 16, 
                                                          color: isDark ? const Color(0xFF9CA3AF) : Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : ListView.builder(
                                                  controller: controller,
                                                  itemCount: gecmisKayitlar.length,
                                                  itemBuilder: (_, index) {
                                                    final k = gecmisKayitlar[index];
                                                    final box = Hive.box<HesaplamaKaydi>('gecmis_kayitlar');
                                                    final key = box.keys.toList().reversed.toList()[index];
                                                    
                                                    return Dismissible(
                                                      key: Key(key.toString()),
                                                      direction: DismissDirection.endToStart,
                                                      background: Container(
                                                        color: Colors.red,
                                                        alignment: Alignment.centerRight,
                                                        padding: const EdgeInsets.only(right: 20),
                                                        child: const Icon(
                                                          Icons.delete,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      onDismissed: (_) async {
                                                        await box.delete(key);
                                                        if (context.mounted) {
                                                          setState(() {
                                                            gecmisKayitlar.removeAt(index);
                                                          });
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Kayıt silindi'),
                                                              duration: Duration(seconds: 1),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Card(
                                                        margin: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                        elevation: isDark ? 4 : 2,
                                                        color: isDark ? const Color(0xFF0A0E21) : Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                          side: isDark ? BorderSide(
                                                            color: const Color(0xFF00BCD4).withOpacity(0.2),
                                                            width: 1,
                                                          ) : BorderSide.none,
                                                        ),
                                                        child: ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundColor: k.sonuc.contains('Uygun Değil')
                                                                ? Colors.red[100]
                                                                : Colors.green[100],
                                                            child: Icon(
                                                              k.sonuc.contains('Uygun Değil')
                                                                  ? Icons.close
                                                                  : Icons.check,
                                                              color: k.sonuc.contains('Uygun Değil')
                                                                  ? Colors.red
                                                                  : Colors.green,
                                                            ),
                                                          ),
                                                          title: Text(
                                                            '${k.hata}%  •  ${k.sonuc}',
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          subtitle: Text(
                                                            '${k.dispenser} / ${k.mastermetre}\n${k.tarihSaat}',
                                                          ),
                                                          isThreeLine: true,
                                                          trailing: const Icon(Icons.arrow_back, color: Colors.grey),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, color: Colors.white),
                            label: const Text('Geçmiş', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    if (hataYuzdesi != null) ...[
                      const SizedBox(height: 30),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: uygunluk == "❌ Uygun Değil" ? Colors.red[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Bağıl Hata: ${truncateToTwoDecimals(hataYuzdesi!)} %',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              uygunluk!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: uygunluk == "❌ Uygun Değil" ? Colors.red[800] : Colors.green[800],
                              ),
                            ),
                            if (uygunluk == "✅ Uygun")
                              const Text("🎉", style: TextStyle(fontSize: 32)),
                            if (uygunluk == "❌ Uygun Değil")
                              const Text("🧯", style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final metin =
                                        'Bağıl Hata: ${truncateToTwoDecimals(hataYuzdesi!)} %\nDurum: $uygunluk';
                                    await Clipboard.setData(ClipboardData(text: metin));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Sonuç panoya kopyalandı"),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Kopyala'),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    final metin =
                                        'Bağıl Hata: ${truncateToTwoDecimals(hataYuzdesi!)} %\nDurum: $uygunluk';
                                    Share.share(metin);
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Paylaş'),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    VoidCallback? onTapClear,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: () {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
        if (onTapClear != null) onTapClear();
      },
      style: TextStyle(
        fontSize: 16, 
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF9CA3AF) : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 15,
          color: isDark ? const Color(0xFF00BCD4) : Colors.blue[900],
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: isDark 
                  ? const Color(0xFF00BCD4).withOpacity(0.5)
                  : Colors.white.withOpacity(0.8),
              offset: const Offset(0, 0),
              blurRadius: isDark ? 8 : 4,
            ),
          ],
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: isDark 
            ? const Color(0xFF0A0E21).withOpacity(0.6)
            : Colors.white.withOpacity(0.95),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark ? BorderSide(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            width: 1,
          ) : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark ? BorderSide(
            color: const Color(0xFF00BCD4).withOpacity(0.2),
            width: 1,
          ) : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark ? BorderSide(
            color: const Color(0xFF00BCD4),
            width: 2,
          ) : BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  late double tolerans;
  late bool koyuTema;

  @override
  void initState() {
    super.initState();
    try {
      final box = Hive.box<Ayarlar>('ayarlar');
      final ayarlar = box.get('ayarlar', defaultValue: Ayarlar())!;
      tolerans = ayarlar.toleransDegeri;
      koyuTema = ayarlar.koyu_tema;
    } catch (e) {
      // Web'de hata olursa varsayılan değerleri kullan
      tolerans = 1.0;
      koyuTema = false;
    }
  }

  Future<void> kaydet() async {
    final box = Hive.box<Ayarlar>('ayarlar');
    await box.put('ayarlar', Ayarlar(toleransDegeri: tolerans, koyu_tema: koyuTema));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void sifirla() {
    setState(() {
      tolerans = 1.0;
      koyuTema = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.blueAccent,
        foregroundColor: isDark ? const Color(0xFF00BCD4) : Colors.white,
        elevation: isDark ? 4 : 0,
        shadowColor: isDark ? const Color(0xFF00BCD4).withOpacity(0.3) : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF0A0E21), const Color(0xFF1D1E33), const Color(0xFF0A0E21)]
                : [const Color(0xFF72C6EF), const Color(0xFF004E92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tolerans Değeri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mevcut değer: ±${tolerans.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? const Color(0xFF00BCD4) : Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tolerans,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    label: '±${tolerans.toStringAsFixed(2)}%',
                    activeColor: isDark ? const Color(0xFF00BCD4) : Colors.blueAccent,
                    inactiveColor: isDark 
                        ? const Color(0xFF00BCD4).withOpacity(0.2)
                        : Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        tolerans = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Min: 0.1%', 
                        style: TextStyle(
                          color: isDark ? const Color(0xFF9CA3AF) : Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Max: 5.0%', 
                        style: TextStyle(
                          color: isDark ? const Color(0xFF9CA3AF) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bağıl hata bu değer aralığında ise "Uygun" kabul edilecektir.',
                    style: TextStyle(
                      fontSize: 13, 
                      color: isDark ? const Color(0xFF9CA3AF) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1D1E33).withOpacity(0.8)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  width: 1.5,
                ) : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? const Color(0xFF00BCD4).withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: isDark ? 20 : 10,
                    spreadRadius: isDark ? 2 : 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Koyu Tema',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Uygulamayı koyu temada kullan',
                            style: TextStyle(
                              fontSize: 13, 
                              color: isDark ? const Color(0xFF9CA3AF) : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: koyuTema,
                        onChanged: (value) {
                          setState(() {
                            koyuTema = value;
                          });
                        },
                        activeColor: const Color(0xFF00BCD4),
                        activeTrackColor: const Color(0xFF00BCD4).withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: kaydet,
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: sifirla,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Sıfırla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1D1E33).withOpacity(0.6)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? const Color(0xFF00BCD4).withOpacity(0.3)
                      : Colors.blue[200]!,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline, 
                    color: isDark ? const Color(0xFF00BCD4) : Colors.blueAccent, 
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tolerans Örnekleri',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ±0.5%: Çok hassas ölçümler için\n'
                    '• ±1.0%: Standart kullanım (varsayılan)\n'
                    '• ±2.0%: Geniş tolerans aralığı\n'
                    '• ±3.0%+: Test ve geliştirme için',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
