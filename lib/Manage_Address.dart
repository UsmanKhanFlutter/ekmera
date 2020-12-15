import 'package:flutter/material.dart';
import 'CheckOut.dart';
import 'Helper/CustomRadio.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Helper/Constant.dart';
import 'Helper/AppBtn.dart';
import 'Add_Address.dart';
import 'Helper/Color.dart';
import 'package:http/http.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'Model/User.dart';

class ManageAddress extends StatefulWidget {
  final bool home;

  const ManageAddress({Key key, this.home}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateAddress();
  }
}

class StateAddress extends State<ManageAddress> with TickerProviderStateMixin {
  bool _isLoading = false, _isProgress = false;
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  bool _isNetworkAvail = true;
  List<RadioModel> addModel = new List<RadioModel>();

  @override
  void initState() {
    super.initState();

    if (widget.home) {
      setState(() {
        _isLoading = true;
      });
      _getAddress();
    } else {
      addAddressModel();
    }

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
                  addressList.clear();
                  addModel.clear();
                  _getAddress();
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

  Future<void> _getAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(getAddressApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        print('response***setting****$CUR_USERID**${response.body.toString()}');
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          addressList =
              (data as List).map((data) => new User.fromAddress(data)).toList();

          for (int i = 0; i < addressList.length; i++) {
            if (addressList[i].isDefault == "1") {
              selectedAddress = i;
              selAddress = addressList[i].id;
            }
          }

          addAddressModel();
        } else {
          //if (msg != 'Cart Is Empty !') setSnackbar(msg);
        }
        setState(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {
        //  setSnackbar(somethingMSg);
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(SHIPP_ADDRESS, context),
      backgroundColor: lightWhite,
      body: _isNetworkAvail
          ? Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? shimmer()
                      : addressList.length == 0
                          ? Center(child: Text(NOADDRESS))
                          : Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: BouncingScrollPhysics(),
                                      itemCount: addressList.length,
                                      itemBuilder: (context, index) {
                                        print(
                                            "default***b${addressList[index].isDefault}***${addressList[index].name}");

                                        return addressItem(index);
                                      }),
                                ),
                                showCircularProgress(_isProgress, primary),
                              ],
                            ),
                ),
                InkWell(
                  child: Container(
                      alignment: Alignment.center,
                      height: 55,
                      decoration: new BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [grad1Color, grad2Color],
                            stops: [0, 1]),
                      ),
                      child: Text(ADDADDRESS,
                          style: Theme.of(context).textTheme.subtitle1.copyWith(
                                color: white,
                              ))),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddAddress(
                                update: false,
                            index: addressList.length,
                              )),
                    );
                    setState(() {
                      addModel.clear();
                      addAddressModel();
                    });
                  },
                )
              ],
            )
          : noInternet(context),
    );
  }

  Future<void> setAsDefault(int index) async {
    //  print("index***********${widget.index}");
    try {
      var data = {
        USER_ID: CUR_USERID,
        ID: addressList[index].id,
        ISDEFAULT: "1",
      };

      print('response******param--${data.toString()}');
      Response response =
          await post(updateAddressApi, body: data, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      print('response***UpdateUser**$headers***${response.body.toString()}');
      bool error = getdata["error"];
      String msg = getdata["message"];

      if (!error) {
        var data = getdata["data"];

        for (User i in addressList) {
          i.isDefault = "0";
          print("after***before**${i.name}***${i.isDefault}");
        }

        addressList[index].isDefault = "1";

        /*if (widget.update) {
          User value = new User.fromAddress(data[0]);
          addressList[widget.index] = value;
        } 

        if (checkedDefault.toString() == "true") {
          for (User i in addressList) {
            i.isDefault = "0";
            print("after***before**${i.name}***${i.isDefault}");
          }
          selectedAddress = null;
          addressList[widget.index].isDefault = "1";
          selectedAddress = widget.index;
        }

        if (checkedDefault.toString() == "true") {
          for (User i in addressList) i.isDefault = "0";
        }
        Navigator.of(context).pop();*/
      } else {
        // setSnackbar(msg);
      }
      setState(() {
        _isProgress = false;
      });
    } on TimeoutException catch (_) {
      // setSnackbar(somethingMSg);
    }
  }

  addressItem(int index) {
    print(
        "default***${addressList[index].isDefault}***${addressList[index].name}**$selectedAddress");
    if (addressList[index].isDefault == "1") {
      selectedAddress = index;
      selAddress = addressList[index].id;
    }
    return Card(
        elevation: 0.2,
        child: new InkWell(
          //highlightColor: Colors.red,
          onTap: () {
            setState(() {
              selectedAddress = index;
              selAddress = addressList[index].id;
              addModel.forEach((element) => element.isSelected = false);
              addModel[index].isSelected = true;
            });
          },
          child: new RadioItem(addModel[index]),
        ));
  }

  Future<void> deleteAddress(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ID: addressList[index].id,
        };
        Response response =
            await post(deleteAddressApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        print('response***delete****$CUR_USERID**${response.body.toString()}');
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          selAddress = "";
          addressList.removeWhere((item) => item.id == addressList[index].id);

          addModel.clear();
          addAddressModel();
        } else {
          //  if (msg != 'Cart Is Empty !') setSnackbar(msg);
        }
        setState(() {
          _isProgress = false;
        });
      } on TimeoutException catch (_) {
        // setSnackbar(somethingMSg);
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  void addAddressModel() {
    for (int i = 0; i < addressList.length; i++) {
      addModel.add(RadioModel(
          isSelected: i == selectedAddress ? true : false,
          name: addressList[i].name + "," + addressList[i].mobile,
          add: addressList[i].address +
              ", " +
              addressList[i].area +
              ", " +
              addressList[i].city +
              ", " +
              addressList[i].state +
              ", " +
              addressList[i].country +
              "," +
              addressList[i].pincode,
          addItem: addressList[i],
          show: !widget.home,
          onSetDefault: () {
            setState(() {
              _isProgress = true;
            });
            setAsDefault(i);
          },
          onDeleteSelected: () {
            setState(() {
              _isProgress = true;
            });
            deleteAddress(i);
          },
          onEditSelected: () async {
          await  Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAddress(
                    update: true,
                    index: i,
                  ),
                ));
            setState(() {
              addModel.clear();
              addAddressModel();
            });
          }));
    }
  }

/*  setSnackbar(String msg) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: black),
      ),
      backgroundColor: white,
      elevation: 1.0,
    ));
  }*/

}
