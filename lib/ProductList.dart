import 'dart:async';
import 'dart:convert';
import 'package:eshop/Helper/AppBtn.dart';
import 'package:eshop/Helper/SimBtn.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Model/Section_Model.dart';
import 'Product_Detail.dart';
import 'Search.dart';

class ProductList extends StatefulWidget {
  final String name, id;
  final Function updateHome;

  const ProductList({Key key, this.id, this.name, this.updateHome})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProduct();
}

class StateProduct extends State<ProductList> with TickerProviderStateMixin {
  bool _isLoading = true, _isProgress = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<Product> productList = [];
  List<Product> tempList = [];
  String sortBy = 'p.id', orderBy = "DESC";
  int offset = 0;
  int total = 0;
  String totalProduct;
  bool isLoadingmore = true;
  ScrollController controller = new ScrollController();
  var filterList;
  List<String> attnameList;
  List<String> attsubList;
  List<String> attListId;
  bool _isNetworkAvail = true;
  List<String> selectedId = [];
  bool _isFirstLoad = true;
  String filter = "";
  String selId = "";
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  new GlobalKey<RefreshIndicatorState>();
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  bool listType = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    getProduct("0");

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
    controller.removeListener(() {});
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getAppbar(),

        key: _scaffoldKey,
        body: _isNetworkAvail
            ? _isLoading
            ? shimmer()
            : productList.length == 0
            ? getNoItem(context)
            : Stack(
          children: <Widget>[
            _showForm(),
            showCircularProgress(_isProgress, colors.primary),
          ],
        )
            : noInternet(context));
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  offset = 0;
                  total = 0;
                  getProduct("0");
                } else {
                  await buttonController.reverse();
                   if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  noIntBtn(BuildContext context) {
    double width = deviceWidth;
    return Container(
        padding: EdgeInsetsDirectional.only(bottom: 10.0, top: 50.0),
        child: Center(
            child: RaisedButton(
              color: colors.primary,
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => super.widget));
              },
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
              child: Ink(
                child: Container(
                  constraints: BoxConstraints(maxWidth: width / 1.2, minHeight: 45),
                  alignment: Alignment.center,
                  child: Text(getTranslated(context, 'TRY_AGAIN_INT_LBL'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(color: colors.white, fontWeight: FontWeight.normal)),
                ),
              ),
            )));
  }

  Widget listItem(int index) {
    totalProduct = productList[index].total;

    double price = double.parse(productList[index].prVarientList[0].disPrice);
    if (price == 0)
      price = double.parse(productList[index].prVarientList[0].price);

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
            Widget>[
          productList[index].availability == "0"
              ? Text(getTranslated(context, 'OUT_OF_STOCK_LBL'),
              style: Theme.of(context)
                  .textTheme
                  .subtitle2
                  .copyWith(color: Colors.red,fontWeight: FontWeight.bold))
              : Container(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Hero(
                  tag: "$index${productList[index].id}",
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.0),
                      child: FadeInImage(
                        image: NetworkImage(productList[index].image),
                        height: 80.0,
                        width: 80.0,
                        placeholder: placeHolder(80),
                      )),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          productList[index].name,
                          style: TextStyle(
                              color: colors.lightBlack, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: colors.primary,
                              size: 12,
                            ),
                            Text(
                              " " + productList[index].rating,
                              style: Theme.of(context).textTheme.overline,
                            ),
                            Text(
                              " (" + productList[index].noOfRating + ")",
                              style: Theme.of(context).textTheme.overline,
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(
                              double.parse(productList[index]
                                  .prVarientList[0]
                                  .disPrice) !=
                                  0
                                  ? CUR_CURRENCY +
                                  "" +
                                  productList[index].prVarientList[0].price
                                  : "",
                              style: Theme.of(context)
                                  .textTheme
                                  .overline
                                  .copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  letterSpacing: 0),
                            ),
                            Text(" " + CUR_CURRENCY + " " + price.toString(),
                                style: Theme.of(context).textTheme.subtitle1),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ]),
        onTap: () {
          Product model = productList[index];
          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                  model: model,
                  updateParent: updateProductList,
                  index: index,
                  secPos: 0,
                  updateHome: widget.updateHome,
                  list: true,
                )),
          );
        },
      ),
    );
  }

  updateProductList() {
     if (mounted) setState(() {});
  }

  Future<Null> getProduct(String top) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          CATID: widget.id,
          SORT: sortBy,
          ORDER: orderBy,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          TOP_RETAED: top
        };
        if (selId != null && selId != "") {
          parameter[ATTRIBUTE_VALUE_ID] = selId;
        }
        if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

        Response response =
        await post(getProductApi, headers: headers, body: parameter)
            .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            total = int.parse(getdata["total"]);

            if (_isFirstLoad) {
              filterList = getdata["filters"];
              _isFirstLoad = false;
            }

            if ((offset) < total) {
              tempList.clear();

              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => new Product.fromJson(data))
                  .toList();

              productList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            if (msg != "Products Not Found !") setSnackbar(msg);
            isLoadingmore = false;
          }
          if (mounted)
             if (mounted) setState(() {
              _isLoading = false;
            });
        }
      } on TimeoutException catch (_) {
        setSnackbar( getTranslated(context,'somethingMSg'));
         if (mounted) setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      {
         if (mounted) setState(() {
          _isNetworkAvail = false;
        });
      }
    }

    return null;
  }

  setSnackbar(String msg) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.black),
      ),
      backgroundColor: colors.white,
      elevation: 1.0,
    ));
  }

  getAppbar() {
    return AppBar(
      title: Text(
        widget.name,
        style: TextStyle(
          color: colors.fontColor,
        ),
      ),

      elevation: 5,
      leading: Builder(builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4.0),
                child: Icon(Icons.keyboard_arrow_left, color: colors.primary),
              ),
            ),
          ),
        );
      }),
      actions: <Widget>[
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Search(
                          updateHome: widget.updateHome, menuopen: false),
                    ));
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.search,
                  color: colors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        filterList != null && filterList.length > 0
            ? Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: shadow(),
            child: Card(
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    if (filterList.length != 0) return filterDialog();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.tune,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                )))
            : Container(),
        Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: shadow(),
            child: Card(
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    if (productList.length != 0) return sortDialog();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.filter_list,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                ))),
        Container(
            margin: EdgeInsetsDirectional.only(top: 10, bottom: 10, end: 10),
            decoration: shadow(),
            child: Card(
                elevation: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          listType ? Icons.grid_view : Icons.list,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      onTap: () {
                        productList.length != 0
                            ?   setState(() {
                          listType = !listType;
                        })
                            : null;
                      }),
                ))),
      ],
    );
  }

  Widget productItem(int index, bool pad) {
    String offPer;
    double price = double.parse(productList[index].prVarientList[0].disPrice);
    if (price == 0) {
      price = double.parse(productList[index].prVarientList[0].price);
    } else {
      double off =
          double.parse(productList[index].prVarientList[0].price) - price;

      offPer = ((off * 100) /
          double.parse(productList[index].prVarientList[0].price))
          .toStringAsFixed(2);
    }

    double width = deviceWidth * 0.5;

    return Card(
      elevation: 0.2,
      margin: EdgeInsetsDirectional.only(bottom: 5, end: pad ? 5 : 0),
      child: InkWell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      child: Hero(
                        tag: "$index${productList[index].id}",
                        child: FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: NetworkImage(productList[index].image),
                          height: double.maxFinite,
                          width: double.maxFinite,
                          placeholder: placeHolder(width),
                        ),
                      )),
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child:
                    productList[index].availability == "0"?
                        Text(getTranslated(context, 'OUT_OF_STOCK_LBL'),
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2
                            .copyWith(color: Colors.red,fontWeight: FontWeight.bold))
                        : Container(),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: colors.primary,
                            size: 10,
                          ),
                          Text(
                            productList[index].rating,
                            style: Theme.of(context)
                                .textTheme
                                .overline
                                .copyWith(letterSpacing: 0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 5.0, top: 5, bottom: 5),
              child: Text(
                productList[index].name,
                style: Theme.of(context)
                    .textTheme
                    .caption
                    .copyWith(color:colors.lightBlack),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(" " + CUR_CURRENCY + " " + price.toString(),
                style: TextStyle(
                    color: colors.fontColor, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 5.0, bottom: 5, top: 3),
              child: double.parse(productList[index].prVarientList[0].disPrice) !=
                  0
                  ? Row(
                children: <Widget>[
                  Text(
                    double.parse(productList[index]
                        .prVarientList[0]
                        .disPrice) !=
                        0
                        ? CUR_CURRENCY +
                        "" +
                        productList[index].prVarientList[0].price
                        : "",
                    style: Theme.of(context).textTheme.overline.copyWith(
                        decoration: TextDecoration.lineThrough,
                        letterSpacing: 0),
                  ),
                  Text(" | " + "-$offPer%",
                      style: Theme.of(context)
                          .textTheme
                          .overline
                          .copyWith(
                          color: colors.primary, letterSpacing: 0)),
                ],
              )
                  : Container(
                height: 5,
              ),
            )
          ],
        ),
        onTap: () {
          Product model = productList[index];
          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                  model: model,
                  updateParent: updateProductList,
                  index: index,
                  secPos: 0,
                  updateHome: widget.updateHome,
                  list: true,
                )),
          );
        },
      ),
    );
  }

  void sortDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ButtonBarTheme(
            data: ButtonBarThemeData(
              alignment: MainAxisAlignment.center,
            ),
            child: new AlertDialog(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0))),
                contentPadding: const EdgeInsets.all(0.0),
                content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: EdgeInsetsDirectional.only(top: 19.0, bottom: 16.0),
                        child: Text(
                          getTranslated(context, 'SORT_BY'),
                          style: Theme.of(context).textTheme.headline6,
                        )),
                    Divider(color: colors.lightBlack),
                    TextButton(
                        child: Text(getTranslated(context, 'TOP_RATED'),
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                .copyWith(color: colors.lightBlack)),
                        onPressed: () {
                          sortBy = '';
                          orderBy = 'DESC';
                           if (mounted) setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                          getProduct("1");
                          Navigator.pop(context, 'option 1');
                        }),
                    Divider(color: colors.lightBlack),
                    TextButton(
                        child: Text(getTranslated(context, 'F_NEWEST'),
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                .copyWith(color: colors.lightBlack)),
                        onPressed: () {
                          sortBy = 'p.date_added';
                          orderBy = 'DESC';
                           if (mounted) setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                          getProduct("0");
                          Navigator.pop(context, 'option 1');
                        }),
                    Divider(color: colors.lightBlack),
                    TextButton(
                        child: Text(
                          getTranslated(context, 'F_OLDEST'),
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1
                              .copyWith(color: colors.lightBlack),
                        ),
                        onPressed: () {
                          sortBy = 'p.date_added';
                          orderBy = 'ASC';
                           if (mounted) setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                          getProduct("0");
                          Navigator.pop(context, 'option 2');
                        }),
                    Divider(color: colors.lightBlack),
                    TextButton(
                        child: new Text(
                          getTranslated(context, 'F_LOW'),
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1
                              .copyWith(color: colors.lightBlack),
                        ),
                        onPressed: () {
                          sortBy = 'pv.price';
                          orderBy = 'ASC';
                           if (mounted) setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                          getProduct("0");
                          Navigator.pop(context, 'option 3');
                        }),
                    Divider(color: colors.lightBlack),
                    Padding(
                        padding: EdgeInsetsDirectional.only(bottom: 5.0),
                        child: TextButton(
                            child: new Text(
                              getTranslated(context, 'F_HIGH'),
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(color: colors.lightBlack),
                            ),
                            onPressed: () {
                              sortBy = 'pv.price';
                              orderBy = 'DESC';
                               if (mounted) setState(() {
                                _isLoading = true;
                                total = 0;
                                offset = 0;
                                productList.clear();
                              });
                              getProduct("0");
                              Navigator.pop(context, 'option 4');
                            })),
                  ]),
                )),
          );
        });
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
         if (mounted) setState(() {
          isLoadingmore = true;

          if (offset < total) getProduct("0");
        });
      }
    }
  }

  Future<void> addToCart(int index) async {
    try {
       if (mounted) setState(() {
        _isProgress = true;
      });
      var parameter = {
        USER_ID: CUR_USERID,
        PRODUCT_VARIENT_ID: productList[index].prVarientList[0].id,
        QTY: (int.parse(productList[index].prVarientList[0].cartCount) + 1)
            .toString(),
      };
      Response response =
      await post(manageCartApi, body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];

        String qty = data['total_quantity'];
        CUR_CART_COUNT = data['cart_count'];

        productList[index].prVarientList[0].cartCount = qty.toString();
      } else {
        setSnackbar(msg);
      }
       if (mounted) setState(() {
        _isProgress = false;
      });
      widget.updateHome();
    } on TimeoutException catch (_) {
      setSnackbar( getTranslated(context,'somethingMSg'));
       if (mounted) setState(() {
        _isProgress = false;
      });
    }
  }

  Future<void> removeFromCart(int index) async {
    try {
       if (mounted) setState(() {
        _isProgress = true;
      });

      var parameter = {
        PRODUCT_VARIENT_ID: productList[index].prVarientList[0].id,
        USER_ID: CUR_USERID,
        QTY: (int.parse(productList[index].prVarientList[0].cartCount) - 1)
            .toString()
      };
      Response response =
      await post(manageCartApi, body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        String qty = data["total_quantity"];
        CUR_CART_COUNT = data['cart_count'];
        productList[index].prVarientList[0].cartCount = qty.toString();
      } else {
        setSnackbar(msg);
      }
       if (mounted) setState(() {
        _isProgress = false;
      });

      widget.updateHome();
    } on TimeoutException catch (_) {
      setSnackbar( getTranslated(context,'somethingMSg'));
       if (mounted) setState(() {
        _isProgress = false;
      });
    }
  }

  Future<Null> _refresh() {
     if (mounted) setState(() {
      _isLoading = true;
      isLoadingmore = true;
      offset = 0;
      total = 0;
      productList.clear();
    });
    return getProduct("0");
  }

  _showForm() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: listType
            ? ListView.builder(
          controller: controller,
          itemCount: (offset < total)
              ? productList.length + 1
              : productList.length,
          physics: AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return (index == productList.length && isLoadingmore)
                ? Center(child: CircularProgressIndicator())
                : listItem(index);
          },
        )
            : GridView.count(
            padding: EdgeInsetsDirectional.only(top: 5),
            crossAxisCount: 2,
            controller: controller,
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(
              (offset < total)
                  ? productList.length + 1
                  : productList.length,
                  (index) {
                return (index == productList.length && isLoadingmore)
                    ? Center(child: CircularProgressIndicator())
                    : productItem(index, index % 2 == 0 ? true : false);
              },
            )));
  }

  void filterDialog() {
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (builder) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                    padding: const EdgeInsetsDirectional.only(top: 30.0),
                    child: AppBar(
                      title: Text(
                        getTranslated(context, 'FILTER'),
                        style: TextStyle(
                          color: colors.fontColor,
                        ),
                      ),
                      elevation: 5,
                      leading: Builder(builder: (BuildContext context) {
                        return Container(
                          margin: EdgeInsets.all(10),
                          decoration: shadow(),
                          child: Card(
                            elevation: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => Navigator.of(context).pop(),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(end: 4.0),
                                child:
                                Icon(Icons.keyboard_arrow_left, color: colors.primary),
                              ),
                            ),
                          ),
                        );
                      }),
                      actions: [
                        Container(
                          margin: EdgeInsetsDirectional.only(end: 10.0),
                          alignment: Alignment.center,
                          child: InkWell(
                              child: Text(getTranslated(context, 'FILTER_CLEAR_LBL'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      .copyWith(
                                      fontWeight: FontWeight.normal,
                                      color: colors.fontColor)),
                              onTap: () {
                                 if (mounted) setState(() {
                                  selectedId.clear();
                                });
                              }),
                        ),
                      ],
                    )),
                Expanded(
                    child: Container(
                        color: colors.lightWhite,
                        padding: EdgeInsetsDirectional.only(start: 7.0, end: 7.0, top: 7.0),
                        child: Card(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Container(
                                          color: colors.lightWhite,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            padding: EdgeInsetsDirectional.only(top: 10.0),
                                            itemCount: filterList.length,
                                            itemBuilder: (context, index) {
                                              attsubList = filterList[index]
                                              ['attribute_values']
                                                  .split(',');

                                              attListId = filterList[index]
                                              ['attribute_values_id']
                                                  .split(',');

                                              if (filter == "") {
                                                filter = filterList[0]["name"];
                                              }

                                              return InkWell(
                                                  onTap: () {
                                                     if (mounted) setState(() {
                                                      filter =
                                                      filterList[index]['name'];
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsetsDirectional.only(
                                                        start: 20,
                                                        top: 10.0,
                                                        bottom: 10.0),
                                                    decoration: BoxDecoration(
                                                        color: filter ==
                                                            filterList[index]
                                                            ['name']
                                                            ? colors.white
                                                            : colors.lightWhite,
                                                        borderRadius: BorderRadius.only(
                                                            topLeft: Radius.circular(7),
                                                            bottomLeft:
                                                            Radius.circular(7))),
                                                    alignment: Alignment.centerLeft,
                                                    child: new Text(
                                                      filterList[index]['name'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle1
                                                          .copyWith(
                                                          color: filter ==
                                                              filterList[index]
                                                              ['name']
                                                              ? colors.fontColor
                                                              : colors.lightBlack,
                                                          fontWeight:
                                                          FontWeight.normal),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ));
                                            },
                                          ))),
                                  Expanded(
                                      flex: 3,
                                      child: ListView.builder(
                                          shrinkWrap: true,
                                          padding: EdgeInsetsDirectional.only(top: 10.0),
                                          scrollDirection: Axis.vertical,
                                          itemCount: filterList.length,
                                          itemBuilder: (context, index) {
                                            if (filter == filterList[index]["name"]) {
                                              attsubList = filterList[index]
                                              ['attribute_values']
                                                  .split(',');

                                              attListId = filterList[index]
                                              ['attribute_values_id']
                                                  .split(',');
                                              return Container(
                                                  child: ListView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                      NeverScrollableScrollPhysics(),
                                                      itemCount: attListId.length,
                                                      itemBuilder: (context, i) {
                                                        return CheckboxListTile(
                                                          dense: true,
                                                          title: Text(attsubList[i],
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .subtitle1
                                                                  .copyWith(
                                                                  color: colors.lightBlack,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .normal)),
                                                          value: selectedId
                                                              .contains(attListId[i]),
                                                          activeColor: colors.primary,
                                                          controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                          onChanged: (bool val) {
                                                             if (mounted) setState(() {
                                                              if (val == true) {
                                                                selectedId
                                                                    .add(attListId[i]);
                                                              } else {
                                                                selectedId.remove(
                                                                    attListId[i]);
                                                              }
                                                            });
                                                          },
                                                        );
                                                      }));
                                            } else {
                                              return Container();
                                            }
                                          })),
                                ])))),
                Container(
                  color: colors.white,
                  child: Row(children: <Widget>[
                    Padding(
                        padding: EdgeInsetsDirectional.only(start: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(total.toString()),
                            Text(getTranslated(context,'PRODUCTS_FOUND_LBL')),
                          ],
                        )),
                    Spacer(),
                    SimBtn(
                        size: 0.4,
                        title: getTranslated(context, 'APPLY'),
                        onBtnSelected: () {
                          if (selectedId != null) {
                            selId = selectedId.join(',');
                          }

                           if (mounted) setState(() {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                          getProduct("0");
                          Navigator.pop(context, 'Product Filter');
                        }),
                  ]),
                )
              ]);
            });
      },
    );
  }
}
