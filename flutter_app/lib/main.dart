import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';

const cardBorderRadius = 10.0;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  Map<int, Product>? products;
  Product? scannedProduct;
  bool productNotFound = false;
  bool showProfile = false;

  @override
  void initState() {
    super.initState();
    readProducts().then(
      (value) => products = value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: buildHome(context),
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.green.shade300,
          secondary: Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget buildHome(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          if (showProfile) {
            showProfile = false;
          } else if (scannedProduct != null) {
            scannedProduct = null;
          } else {
            return true;
          }
          return false;
        } finally {
          setState(() {});
        }
      },
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: buildAppBar(context),
          body: buildBody(context),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          InkWell(
            onTap: () {
              if (mounted && !showProfile) {
                setState(() {
                  scannedProduct = products?.values
                      .toList()[Random().nextInt(products?.length ?? 0)];
                });
              }
            },
            child: SizedBox(
              width: 140,
              child: Image.asset("assets/m-check-logo.png"),
            ),
          ),
        ],
      ),
      actions: [
        if (scannedProduct != null && !showProfile)
          IconButton(
            icon: Image.asset("assets/barcode_scan.png"),
            onPressed: () {
              scanBarcodeNormal();
            },
          ),
        if (!showProfile)
          IconButton(
            color: const Color(0xFF222222),
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              if (mounted) {
                setState(() {
                  showProfile = true;
                });
              }
            },
          ),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget buildBody(BuildContext context) {
    if (showProfile) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Image.asset('assets/profile.png'),
        ),
      );
    }
    return Column(
      children: [
        if (scannedProduct == null) const SizedBox(height: 40),
        if (scannedProduct == null)
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.7,
                  child: Image.asset('assets/talking_man.png'),
                ),
              )
            ],
          ),
        if (scannedProduct == null)
          Expanded(
            child: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: FittedBox(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.qr_code), //
                    onPressed: () => scanBarcodeNormal(),
                  ),
                ),
              ),
            ),
          ),
        if (scannedProduct == null)
          const SizedBox(
            height: 40,
          ),
        if (scannedProduct != null)
          Expanded(
            child: ListView.builder(
              itemCount: 2 + (scannedProduct?.suggestions.length ?? 0),
              itemBuilder: buildItem,
            ),
          ),
      ],
    );
  }

  Widget buildItem(BuildContext context, int index) {
    if (index == 0) {
      return buildProductItem(context, scannedProduct!, null);
    }
    if (index == 1) {
      if (scannedProduct?.suggestions.isEmpty != false) {
        return Padding(
          padding: const EdgeInsets.all(30),
          child: Image.asset("assets/congrats.png"),
        );
      }
      return const Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 0),
        child: Card(
          elevation: 5,
          color: Color(0xFF5CA747),
          // Colors.green.shade300, // Color(0xFF5CA747)
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Text(
              "Sustainable Alternative",
              textScaleFactor: 1.4,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    final suggestion = scannedProduct!.suggestions[index - 2];
    return buildProductItem(context, suggestion.product, suggestion.kmSaved);
  }

  Widget buildProductItem(BuildContext context, Product product, int? kmSaved) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius)),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardBorderRadius),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 14, 0),
                child: Text(
                  product.name,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaleFactor: 1.7,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child:
                            Image.network(product.image, fit: BoxFit.scaleDown),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Card(
                        color: Colors.green.shade100,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(9))),
                        margin: EdgeInsets.zero,
                        child: SizedBox(
                          width: 70,
                          child: Column(
                            children: [
                              //Image.asset("assets/m-check-logo.png"),
                              const SizedBox(height: 20),
                              SvgPicture.asset(
                                "assets/klima${product.iCo2Rating ?? 5}.svg",
                              ),
                              if (product == scannedProduct)
                                const SizedBox(height: 12),
                              if (product != scannedProduct)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: Image.asset(
                                          "assets/car.png",
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text("$kmSaved km saved"),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    var number = int.tryParse(barcodeScanRes);
    if (number == null) number == -1;
    scannedProduct = products?[number];
    productNotFound = number != -1 && scannedProduct == null;

    if (!mounted) return;
    setState(() {});
  }

  Future<Map<int, Product>> readProducts() async {
    final result = <int, Product>{};
    var csvData = await rootBundle.loadString('assets/products.csv');
    var lines = const CsvToListConverter().convert(csvData);
    for (final line in lines.skip(1)) {
      if (line[0] is String) continue;
      final id = line[0] as int;
      if (line[5] is String) continue;
      result[id] = Product(
        id: id,
        name: line[1] as String,
        image: line[4] as String,
        co2Rating: line[5],
        co2CarRating: line[6],
        animalRating: line[7],
      );
    }
    csvData = await rootBundle.loadString('assets/suggestions.csv');
    lines = const CsvToListConverter().convert(csvData);
    for (final line in lines.skip(1)) {
      if (line.isEmpty) continue;
      final idWorse = line[0] as int;
      final idBetter = line[1] as int;
      final kmSaved = (line[2] as double).round();
      if (idWorse == idBetter) continue;
      result[idWorse]!.suggestions.add(Suggestion(result[idBetter]!, kmSaved));
    }
    for (final product in result.values.toList()) {
      if (product.suggestions.isEmpty) {
        // result.remove(product.id);
      }
    }
    return result;
  }
}

class Product {
  final int id;
  final String name;
  final String image;
  final double? co2Rating;
  final double? co2CarRating;
  final double? animalRating;
  final suggestions = <Suggestion>[];

  Product({
    required this.id,
    required this.name,
    required this.image,
    required co2Rating,
    required co2CarRating,
    required animalRating,
  })  : co2Rating = co2Rating is double ? co2Rating : null,
        co2CarRating = co2CarRating is double ? co2CarRating : null,
        animalRating = animalRating is double ? animalRating : null;

  int? get iCo2Rating => co2Rating?.round();

  int? get ico2CarRating => co2CarRating?.round();

  int? get iAnimalRating => animalRating?.round();

  @override
  String toString() {
    return "Product($id, $name, $image, $co2Rating, $co2CarRating, "
        "$animalRating, [${suggestions.map((it) => it.product.id).join(", ")}])";
  }
}

class Suggestion {
  final Product product;
  final int kmSaved;

  Suggestion(this.product, this.kmSaved);
}
