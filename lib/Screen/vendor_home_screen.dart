import 'package:appdevl/providers/store_provider.dart';
import 'package:appdevl/widget/products/future_products.dart';
import 'package:appdevl/widget/vendorCategory.dart';
import 'package:appdevl/widget/vendor_appbar.dart';
import 'package:appdevl/widget/vendor_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VendorHomeScreen extends StatelessWidget {
  static const String id = 'vendor-screen';

  @override
  Widget build(BuildContext context) {
    var _store = Provider.of<StoreProvider>(context);

    return Scaffold(
        body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                VendorAppBar(),
              ];
            },
            body: ListView(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                VendorBanner(),
                VendorCategories(),
                SizedBox(height: 120.0),
                FeatureProducts(),
              ],
            )));
  }
}
