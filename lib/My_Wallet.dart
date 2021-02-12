import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:http/http.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'Helper/AppBtn.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/PaymentRadio.dart';
import 'Helper/Session.dart';
import 'Helper/SimBtn.dart';
import 'Helper/String.dart';
import 'Helper/Stripe_Service.dart';
import 'Model/Transaction_Model.dart';

class MyWallet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateWallet();
  }
}

class StateWallet extends State<MyWallet> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  ScrollController controller = new ScrollController();
  List<TransactionModel> tempList = [];
  TextEditingController amtC, msgC;
  List<String> paymentMethodList = [];
  List<String> paymentIconList = [
    'assets/images/cod.png',
    'assets/images/paypal.png',
    'assets/images/payu.png',
    'assets/images/rozerpay.png',
    'assets/images/paystack.png',
    'assets/images/flutterwave.png',
    'assets/images/stripe.png',
  ];
  List<RadioModel> payModel = new List<RadioModel>();
  bool paypal, razorpay, paumoney, paystack, flutterwave = true, stripe;
  String razorpayId,
      paystackId,
      stripeId,
      stripeSecret,
      stripeMode = "test",
      stripeCurCode,
      stripePayId,
      flutterwaveId = 'FLWPUBK_TEST-1ffbaed6ee3788cd2bcbb898d3b90c59-X',
      flutterwaveSec = 'FLWSECK_TEST25c36edcfcaa';
  int selectedMethod;
  String payMethod;
  StateSetter dialogState;
  bool _isProgress = false;
  Razorpay _razorpay;
  List<TransactionModel> tranList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedMethod = null;
    payMethod = null;
    new Future.delayed(Duration.zero, () {
      paymentMethodList = [
        getTranslated(context, 'COD_LBL'),
        getTranslated(context, 'PAYPAL_LBL'),
        getTranslated(context, 'PAYUMONEY_LBL'),
        getTranslated(context, 'RAZORPAY_LBL'),
        getTranslated(context, 'PAYSTACK_LBL'),
        getTranslated(context, 'FLUTTERWAVE_LBL'),
        getTranslated(context, 'STRIPE_LBL'),
      ];
      _getpaymentMethod();
    });

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
    amtC = new TextEditingController();
    msgC = new TextEditingController();
    getTransaction();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(getTranslated(context, 'MYWALLET'), context),
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer()
                : Stack(
                    children: <Widget>[
                      showContent(),
                      showCircularProgress(_isProgress, colors.primary),
                    ],
                  )
            : noInternet(context));
  }

  Widget paymentItem(int index) {
    return new InkWell(
      onTap: () {
        if (mounted)
          dialogState(() {
            selectedMethod = index;
            payMethod = paymentMethodList[selectedMethod];
            payModel.forEach((element) => element.isSelected = false);
            payModel[index].isSelected = true;
          });
      },
      child: new RadioItem(payModel[index]),
    );
  }

  Future<Null> sendRequest(String payId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        /*       USER_ID: CUR_USERID,
    ORDER_ID: orderID,
    TYPE: payMethod,
    TXNID: tranId,
    AMOUNT: totalPrice.toString(),
    STATUS: status,
    MSG: msg*/
        var parameter = {
          USER_ID: CUR_USERID,
          AMOUNT: amtC.text.toString(),
          TRANS_TYPE: WALLET,
          TYPE: CREDIT,
          MSG: msgC.text ?? " ",
          TXNID: '',
          ORDER_ID: payId,
          STATUS: "Success",

          // PAYMENT_ADD: bankDetailC.text.toString()
        };
        Response response =
            await post(addTransactionApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        print("trans api resoponse***$parameter**${response.body.toString()}");

        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          CUR_BALANCE = double.parse(getdata["data"]).toStringAsFixed(2);
        }
        if (mounted) setState(() {});
        setSnackbar(msg);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));

        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
          _isLoading = false;
        });
    }

    return null;
  }

  _showDialog() async {
    bool payWarn = false;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            dialogState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              content: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                            child: Text(
                              getTranslated(context, 'ADD_MONEY'),
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(color: colors.fontColor),
                            )),
                        Divider(color: colors.lightBlack),
                        Form(
                            key: _formkey,
                            child: new Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      validator: (val) => validateField(
                                          val,
                                          getTranslated(
                                              context, 'FIELD_REQUIRED')),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      decoration: InputDecoration(
                                        hintText:
                                            getTranslated(context, "AMOUNT"),
                                        hintStyle: Theme.of(this.context)
                                            .textTheme
                                            .subtitle1
                                            .copyWith(
                                                color: colors.lightBlack,
                                                fontWeight: FontWeight.normal),
                                      ),
                                      controller: amtC,
                                    )),
                                Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                                    child: TextFormField(
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      decoration: new InputDecoration(
                                        hintText: getTranslated(context, 'MSG'),
                                        hintStyle: Theme.of(this.context)
                                            .textTheme
                                            .subtitle1
                                            .copyWith(
                                                color: colors.lightBlack,
                                                fontWeight: FontWeight.normal),
                                      ),
                                      controller: msgC,
                                    )),
                                //Divider(),
                                Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(20.0, 10, 20.0, 5),
                                  child: Text(
                                    getTranslated(context, 'SELECT_PAYMENT'),
                                    style:
                                        Theme.of(context).textTheme.subtitle2,
                                  ),
                                ),
                                Divider(),
                                payWarn
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: Text(
                                          getTranslated(context, 'payWarning'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .caption
                                              .copyWith(color: Colors.red),
                                        ),
                                      )
                                    : Container(),
                                paypal == null
                                    ? Center(child: CircularProgressIndicator())
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: paymentMethodList.length,
                                        itemBuilder: (context, index) {
                                          if (index == 1 && paypal)
                                            return paymentItem(index);
                                          else if (index == 2 && paumoney)
                                            return paymentItem(index);
                                          else if (index == 3 && razorpay)
                                            return paymentItem(index);
                                          else if (index == 4 && paystack)
                                            return paymentItem(index);
                                          else if (index == 5 && flutterwave)
                                            return paymentItem(index);
                                          else if (index == 6 && stripe)
                                            return paymentItem(index);
                                          else
                                            return Container();
                                        }),
                              ],
                            ))
                      ])),
              actions: <Widget>[
                new FlatButton(
                    child: Text(
                      getTranslated(context, 'CANCEL'),
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          .copyWith(
                              color: colors.lightBlack,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                new FlatButton(
                    child: Text(
                      getTranslated(context, 'SEND'),
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          .copyWith(
                              color: colors.fontColor,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final form = _formkey.currentState;
                      if (form.validate() && amtC.text != '0') {
                        form.save();
                        if (payMethod == null) {
                          dialogState(() {
                            payWarn = true;
                          });
                        } else {
                          if (payMethod.trim() ==
                              getTranslated(context, 'STRIPE_LBL').trim()) {
                            stripePayment(int.parse(amtC.text));
                          } else if (payMethod.trim() ==
                              getTranslated(context, 'RAZORPAY_LBL').trim())
                            razorpayPayment(double.parse(amtC.text));
                          else if (payMethod.trim() ==
                              getTranslated(context, 'PAYSTACK_LBL').trim())
                            paystackPayment(context, int.parse(amtC.text));

                          Navigator.pop(context);
                        }
                      }
                    })
              ],
            );
          });
        });
  }

  stripePayment(int price) async {
    if (mounted)
      setState(() {
        _isProgress = true;
      });

    print("stripe****${price * 100}***$stripeCurCode");

    var response = await StripeService.payWithNewCard(
        amount: (price * 100).toString(), currency: stripeCurCode);

    if (mounted)
      setState(() {
        _isProgress = false;
      });
    setSnackbar(response.message);
  }

  paystackPayment(BuildContext context, int price) async {
    if (mounted)
      setState(() {
        _isProgress = true;
      });

    String email = await getPrefrence(EMAIL);

    Charge charge = Charge()
      ..amount = price
      ..reference = _getReference()
      ..email = email;

    try {
      CheckoutResponse response = await PaystackPlugin.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );
      if (response.status) {
        sendRequest(response.reference);
      } else {
        setSnackbar(response.message);
        if (mounted)
          setState(() {
            _isProgress = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => _isProgress = false);
      rethrow;
    }
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    //placeOrder(response.paymentId);
    print("razorpay response***${response.toString()}");
    sendRequest(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setSnackbar(response.message);
    if (mounted)
      setState(() {
        _isProgress = false;
      });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("EXTERNAL_WALLET: " + response.walletName);
  }

  razorpayPayment(double price) async {
    String contact = await getPrefrence(MOBILE);
    String email = await getPrefrence(EMAIL);

    double amt = price * 100;

    if (contact != '' && email != '') {
      if (mounted)
        setState(() {
          _isProgress = true;
        });

      var options = {
        KEY: razorpayId,
        AMOUNT: amt.toString(),
        NAME: CUR_USERNAME,
        'prefill': {CONTACT: contact, EMAIL: email},
        'external': {
          'wallets': ['paytm']
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint(e);
      }
    } else {
      if (email == '')
        setSnackbar(getTranslated(context, 'emailWarning'));
      else if (contact == '')
        setSnackbar(getTranslated(context, 'phoneWarning'));
    }
  }

  listItem(int index) {
    Color back;
    if (tranList[index].type == "credit") {
      back = Colors.green;
    } else
      back = Colors.red;
    return Card(
      elevation: 0,
      margin: EdgeInsets.all(5.0),
      child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          getTranslated(context, 'AMOUNT') +
                              " : " +
                              CUR_CURRENCY +
                              " " +
                              tranList[index].amt,
                          style: TextStyle(
                              color: colors.fontColor,
                              fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Text(tranList[index].date),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(getTranslated(context, 'ID_LBL') +
                            " : " +
                            tranList[index].id),
                        Spacer(),
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: back,
                              borderRadius: new BorderRadius.all(
                                  const Radius.circular(4.0))),
                          child: Text(
                            (tranList[index].type),
                            style: TextStyle(color: colors.white),
                          ),
                        )
                      ],
                    ),

                    tranList[index].msg != null &&
                            tranList[index].msg.isNotEmpty
                        ? Text(getTranslated(context, 'MSG') +
                            " : " +
                            tranList[index].msg)
                        : Container(),
                  ]))),
    );
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
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  getTransaction();
                } else {
                  await buttonController.reverse();
                  setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  Future<Null> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
          TRANS_TYPE: WALLET
        };

        Response response =
            await post(getWalTranApi, headers: headers, body: parameter)
                .timeout(Duration(seconds: timeOut));

        print("response****${response.body.toString()}");

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => new TransactionModel.fromJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else
      setState(() {
        _isNetworkAvail = false;
      });

    return null;
  }

  Future<Null> getRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };

        Response response =
            await post(getWalTranApi, headers: headers, body: parameter)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => new TransactionModel.fromReqJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else
      setState(() {
        _isNetworkAvail = false;
      });

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

  @override
  void dispose() {
    buttonController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<Null> _refresh() {
    setState(() {
      _isLoading = true;
    });
    offset = 0;
    total = 0;
    tranList.clear();
    return getTransaction();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset < total) getTransaction();
        });
      }
    }
  }

  Future<void> _getpaymentMethod() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          TYPE: PAYMENT_METHOD,
        };
        Response response =
            await post(getSettingApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print("response*****${response.body.toString()}");
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];

          if (!error) {
            var data = getdata["data"];

            var payment = data["payment_method"];

            paypal = payment["paypal_payment_method"] == "1" ? true : false;
            paumoney =
                payment["payumoney_payment_method"] == "1" ? true : false;
            flutterwave =
                payment["flutterwave_payment_method"] == "1" ? true : false;
            razorpay = payment["razorpay_payment_method"] == "1" ? true : false;
            paystack = payment["paystack_payment_method"] == "1" ? true : false;
            stripe = payment["stripe_payment_method"] == "1" ? true : false;

            if (razorpay) razorpayId = payment["razorpay_key_id"];
            if (paystack) {
              paystackId = payment["paystack_key_id"];

              PaystackPlugin.initialize(publicKey: paystackId);
            }
            if (stripe) {
              stripeId = payment['stripe_publishable_key'];
              stripeSecret = payment['stripe_secret_key'];
              stripeCurCode = payment['stripe_currency_code'];
              stripeMode = payment['stripe_mode'] ?? 'test';
              StripeService.secret = stripeSecret;
              StripeService.init();
            }
            for (int i = 0; i < paymentMethodList.length; i++) {
              payModel.add(RadioModel(
                  isSelected: i == selectedMethod ? true : false,
                  name: paymentMethodList[i],
                  img: paymentIconList[i]));
            }
          }
        }
        if (mounted)
          setState(() {
            _isLoading = false;
          });
        if (dialogState != null) dialogState(() {});
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  showContent() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          controller: controller,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: colors.fontColor,
                          ),
                          Text(
                            " " + getTranslated(context, 'CURBAL_LBL'),
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2
                                .copyWith(
                                    color: colors.fontColor,
                                    fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(CUR_CURRENCY + " " + CUR_BALANCE,
                          style: Theme.of(context).textTheme.headline6.copyWith(
                              color: colors.fontColor,
                              fontWeight: FontWeight.bold)),
                      SimBtn(
                        size: 0.8,
                        title: getTranslated(context, "ADD_MONEY"),
                        onBtnSelected: () {
                          _showDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            tranList.length == 0
                ? getNoItem(context)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: (offset < total)
                        ? tranList.length + 1
                        : tranList.length,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return (index == tranList.length && isLoadingmore)
                          ? Center(child: CircularProgressIndicator())
                          : listItem(index);
                    },
                  ),
          ]),
        ));
  }
}