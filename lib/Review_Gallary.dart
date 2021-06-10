import 'package:eshop/Helper/Session.dart';
import 'package:flutter/material.dart';

import 'Product_Detail.dart';

class ReviewImage extends StatefulWidget {
  @override
  _ReviewImageState createState() => _ReviewImageState();
}

class _ReviewImageState extends State<ReviewImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(getTranslated(context, 'REVIEW_BY_CUST'), context),
      body: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          padding: EdgeInsets.all(20),
          children: List.generate(
            revImgList.length,
            (index) {
              return FadeInImage(
                image: NetworkImage(revImgList[index].img),
                placeholder: AssetImage(
                  "assets/images/sliderph.svg",
                ),
                fit: BoxFit.cover,
              );
            },
          )),
    );
  }
}
