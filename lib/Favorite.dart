import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

import 'package:shimmer/shimmer.dart';

import 'Helper/AppBtn.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Login.dart';
import 'Model/Section_Model.dart';
import 'Product_Detail.dart';

class Favorite extends StatefulWidget {
  Function update;

  Favorite(this.update);

  @override
  State<StatefulWidget> createState() => StateFav();
}

bool _isProgress = false, _isFavLoading = true;
int offset = 0;
int total = 0;
bool isLoadingmore = true;
List<Section_Model> favList = [];

class StateFav extends State<Favorite> with TickerProviderStateMixin {
  ScrollController controller = new ScrollController();
  List<Section_Model> tempList = [];
  String msg = noFav;
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();

    offset = 0;
    total = 0;

    _getFav();
    controller.addListener(_scrollListener);
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    buttonController.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: TRY_AGAIN_INT_LBL,
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  _getFav();
                } else {
                  await buttonController.reverse();
                  // setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: lightWhite,
        body: _isNetworkAvail
            ? Stack(
          children: <Widget>[
            _showContent(),
            showCircularProgress(_isProgress, primary),
          ],
        )
            : noInternet(context));
  }

  Widget listItem(int index) {
    //print("desc*****${productList[index].desc}");
    int selectedPos = 0;
    for (int i = 0;
    i < favList[index].productList[0].prVarientList.length;
    i++) {
      if (favList[index].varientId ==
          favList[index].productList[0].prVarientList[i].id) selectedPos = i;

      print(
          "selected pos***$selectedPos***${favList[index].productList[0].prVarientList[i].id}");
    }

    double price = double.parse(
        favList[index].productList[0].prVarientList[selectedPos].disPrice);
    if (price == 0)
      price = double.parse(
          favList[index].productList[0].prVarientList[selectedPos].price);

    return Card(
      elevation: 0.1,
      child: InkWell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            favList[index].productList[0].availability == "0"
                ? Text(OUT_OF_STOCK_LBL,
                style: Theme.of(context)
                    .textTheme
                    .subtitle1
                    .copyWith(color: Colors.red))
                : Container(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Hero(
                      tag: "$index${favList[index].productList[0].id}",
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: CachedNetworkImage(
                            imageUrl: favList[index].productList[0].image,
                            height: 80.0,
                            width: 80.0,
                            placeholder: (context, url) => placeHolder(80),
                          ))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    favList[index].productList[0].name,
                                    style: TextStyle(color: lightBlack,fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                int.parse(favList[index]
                                    .productList[0]
                                    .prVarientList[selectedPos]
                                    .disPrice) !=
                                    0
                                    ? CUR_CURRENCY +
                                    "" +
                                    favList[index]
                                        .productList[0]
                                        .prVarientList[selectedPos]
                                        .price
                                    : "",
                                style: Theme.of(context)
                                    .textTheme
                                    .overline
                                    .copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0.7),
                              ),
                              Text(
                                " " + CUR_CURRENCY + " " + price.toString(),
                                style: TextStyle(
                                    color: fontColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PopupMenuButton(
                                padding: EdgeInsets.zero,
                                onSelected: (result)
                                async {
                                  if(result==0)
                                  {
                                    _removeFav(index);
                                  }
                                  if(result==1)
                                  {
                                    addToCart(index);
                                  }
                                  if(result==2)
                                  {
                                    var str =
                                        "${favList[index].productList[0].name}\n\n$appName\n\nYou can find our app from below url\n\nAndroid:\n"
                                        "$androidLink$packageName\n\n iOS:\n$iosLink$iosPackage";


                                    final response = await get(favList[index].productList[0].image);

                                    final Directory temp = await getTemporaryDirectory();
                                    final File imageFile = File('${temp.path}/tempImage');
                                    imageFile.writeAsBytesSync(response.bodyBytes);
                                    Share.shareFiles(['${temp.path}/tempImage'], text: str,);
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry>[
                                  const PopupMenuItem(
                                    value: 0,
                                    child: ListTile(
                                      dense:true,
                                      contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                                      leading: Icon(Icons.close,color: fontColor,size: 20,),
                                      title: Text('Remove'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 1,
                                    child: ListTile(
                                      dense:true,
                                      contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),

                                      leading: Icon(Icons.shopping_cart,color: fontColor,size: 20),
                                      title: Text('Add to Cart'),
                                    ),
                                  ),
                                  const PopupMenuItem(

                                    value: 2,
                                    child: ListTile(
                                      dense:true,
                                      contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),

                                      leading: Icon(Icons.share_outlined,color: fontColor,size: 20),
                                      title: Text('Share'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
        splashColor: primary.withOpacity(0.2),
        onTap: () {
          Product model = favList[index].productList[0];
          Navigator.push(
            context,
            PageRouteBuilder(
                transitionDuration: Duration(seconds: 1),
                pageBuilder: (_, __, ___) => ProductDetail(
                  model: model,
                  updateParent: updateFav,
                  updateHome: widget.update,
                  secPos: 0,
                  index: index,
                  list: true,
                  //  title: productList[index].name,
                )),
          );
        },
      ),
    );
  }

  updateFav() {
    setState(() {});
  }

  Future<void> _getFav() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (CUR_USERID != null) {
          var parameter = {
            USER_ID: CUR_USERID,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString(),
          };
          Response response =
          await post(getFavApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);
          print('response***fav****par***${parameter.toString()}');
          print('response***fav****${response.body.toString()}');
          bool error = getdata["error"];
          String msg = getdata["message"];

          print('section get***favorite get');
          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => new Section_Model.fromFav(data))
                  .toList();
              if (offset == 0) favList.clear();
              favList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            if (msg != 'No Favourite(s) Product Are Added') setSnackbar(msg);
            isLoadingmore = false;
          }

          if (mounted)
            setState(() {
              _isFavLoading = false;
            });
        } else {
          setState(() {
            _isFavLoading = false;
            msg = goToLogin;
          });

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Login()),
          );
        }
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        setState(() {
          _isFavLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Future<void> addToCart(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        setState(() {
          _isProgress = true;
        });
        var parameter = {
          PRODUCT_VARIENT_ID: favList[index].productList[0].prVarientList[0].id,
          USER_ID: CUR_USERID,
          QTY: (int.parse(
              favList[index].productList[0].prVarientList[0].cartCount) +
              1)
              .toString(),
        };

        print('param****${parameter.toString()}');

        Response response =
        await post(manageCartApi, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        print(
            'response***slider**${favList[index].varientId}*${response.body
                .toString()}***$headers');

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          String qty = data['total_quantity'];
          CUR_CART_COUNT = data['cart_count'];
          favList[index].productList[0].prVarientList[0].cartCount =
              qty.toString();

          widget.update();
        } else {
          setSnackbar(msg);
        }
        setState(() {
          _isProgress = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        setState(() {
          _isProgress = false;
        });
      }
    }
    else
    {
      setState(() {
        _isNetworkAvail=false;
      });
    }
  }

  setSnackbar(String msg) {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: black),
      ),
      backgroundColor: white,
      elevation: 1.0,
    ));
  }

  removeFromCart(int index, bool remove) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        setState(() {
          _isProgress = true;
        });

        var parameter = {
          USER_ID: CUR_USERID,
          QTY: remove
              ? "0"
              : (int.parse(favList[index]
              .productList[0]
              .prVarientList[0]
              .cartCount) -
              1)
              .toString(),
          PRODUCT_VARIENT_ID: favList[index].productList[0].prVarientList[0].id
        };

        Response response =
        await post(manageCartApi, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        print('response***slider**${response.body.toString()}***$headers');

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          String qty = data['total_quantity'];
          CUR_CART_COUNT = data['cart_count'];

          if (remove)
            favList.removeWhere(
                    (item) => item.varientId == favList[index].varientId);
          else {
            favList[index].productList[0].prVarientList[0].cartCount =
                qty.toString();
          }

          widget.update();
        } else {
          setSnackbar(msg);
        }
        setState(() {
          _isProgress = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        setState(() {
          _isProgress = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  _removeFav(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_ID: favList[index].productId,
        };
        Response response =
        await post(removeFavApi, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        print('response***fav****par***${parameter.toString()}');
        print('response***fav****remove${response.body.toString()}');
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          favList.removeWhere((item) =>
          item.productList[0].prVarientList[0].id ==
              favList[index].productList[0].prVarientList[0].id);
        } else {
          setSnackbar(msg);
        }

        setState(() {});
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          print("load more****limit *****$offset****$total");
          if (offset < total) _getFav();
        });
      }
    }
  }

  _showContent() {
    return _isFavLoading
        ? shimmer()
        : favList.length == 0
        ? Center(child: Text(msg))
        : ListView.builder(
      shrinkWrap: true,
      controller: controller,
      itemCount:
      (offset < total) ? favList.length + 1 : favList.length,
      physics: BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        print(
            "load more****$offset***$total***${favList.length}***$isLoadingmore**$index");
        return (index == favList.length && isLoadingmore)
            ? Center(child: CircularProgressIndicator())
            : listItem(index);
      },
    );
  }
}