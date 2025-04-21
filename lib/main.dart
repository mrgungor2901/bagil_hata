import 'package:flutter/material.dart';

void main() => runApp(BagilHataApp());

String truncateToTwoDecimals(double value) {
  String text = value.toString();
  if (text.contains('.')) {
    final parts = text.split('.');
    final decimal = parts[1].padRight(2, '0').substring(0, 2);
    return '${parts[0]}.${decimal}';
  } else {
    return '$text.00';
  }
}

class BagilHataApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BağılHata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
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

 void hesapla() {
  final double? dispenser = double.tryParse(dispenserController.text.replaceAll(',', '.'));
  final double? mastermetre = double.tryParse(mastermetreController.text.replaceAll(',', '.'));

  if (dispenser != null && mastermetre != null && mastermetre != 0) {
    final double hata = ((dispenser - mastermetre) / mastermetre) * 100;

    setState(() {
      hataYuzdesi = hata;
      uygunluk = (hata >= -1 && hata <= 1) ? "✅ Uygun" : "❌ Uygun Değil";
    });
  } else {
    setState(() {
      hataYuzdesi = null;
      uygunluk = "Geçerli değerler giriniz!";
    });
  }
  hesaplandi = true;

   // 🔄 Yeni işlem için sıfırla
  hasAutoMoved = false;
  
}
bool dispenserPassed = false;

@override
void initState() {
  super.initState();

  dispenserController.addListener(() {
    String raw = dispenserController.text.replaceAll('.', '');

    if (raw.length > 4) raw = raw.substring(0, 4);

    if (raw.length == 4 && !hasAutoMoved) {
      String formatted = raw.substring(0, 2) + '.' + raw.substring(2);
      dispenserController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );

      hasAutoMoved = true;

    
 // 👇 Önce mastermetre içeriğini sil
    mastermetreController.clear();

      // 👇 Master alanına fokus atıyoruz
    FocusScope.of(context).requestFocus(masterFocusNode);

 // 👇 Sonraki frame’de metni tam seç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mastermetreController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: mastermetreController.text.length,
      );
    });
  }
    // eğer kullanıcı geri silerse, sistem tekrar çalışabilir duruma gelsin
    if (raw.length < 4) {
      hasAutoMoved = false;
    }
  });

  mastermetreController.addListener(() {
    String raw = mastermetreController.text.replaceAll('.', '');

    if (raw.length > 4) raw = raw.substring(0, 4);

    if (raw.length == 4) {
      String formatted = raw.substring(0, 2) + '.' + raw.substring(2);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Bağıl Hata Hesaplayıcısı'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              margin: EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: dispenserController,
                      onTap: () {
                         if (hesaplandi) {
                          setState(() {
                          dispenserController.clear();
                          mastermetreController.clear();
                          hataYuzdesi = null;
                          uygunluk = null;
                          hesaplandi = false;
                        });
                        }
                        dispenserController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: dispenserController.text.length,
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          mastermetreController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: mastermetreController.text.length,
                          );
                        });
                      },
                      decoration: InputDecoration(labelText: 'Dispenser Hacmi (otomatik formatlanır)'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: mastermetreController,
                      focusNode: masterFocusNode,
                     onTap: () {
                        final text = mastermetreController.text;
                        mastermetreController.value = TextEditingValue(
                          text: text,
                          selection: TextSelection(baseOffset: 0, extentOffset: text.length),
                        );
                      },
                      decoration: InputDecoration(labelText: 'Mastermetre Hacmi'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: hesapla,
                      child: Center(child: Text('HESAPLA')),
                    ),
                  ],
                ),
              ),
            ),
            if (hataYuzdesi != null)
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: uygunluk!.contains("Uygun")
                      ? Colors.green[100]
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Bağıl Hata: ${truncateToTwoDecimals(hataYuzdesi!)} %',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      uygunluk ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: uygunluk!.contains("Uygun")
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
