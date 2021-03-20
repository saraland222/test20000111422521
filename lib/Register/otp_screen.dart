import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:quiver/async.dart';
import 'package:sk_numberpad/sk_numberpad.dart';

import '../Screen/landing_screen.dart';
import '../Screen/mainScreen.dart';
import '../providers/location_provider.dart';
import '../services/user_services.dart';

class OTPScreen extends StatefulWidget {
  static const String id = 'otp-phone';
  final String mobileNumber;
  final String codeCountry;
  OTPScreen({
    Key key,
    this.mobileNumber,
    this.codeCountry,
  }) : super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController _pinEditingController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  UserServices _userServices = UserServices();
  LocationProvider locationData = LocationProvider();

  bool isSubmited = false;
  bool isCodeSent = false;
  bool isLoginLoading = false;
  String _verificationId;

  String screen = 'login';
  int _start = 60;
  int _current = 60;

  void startTimer() {
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start),
      new Duration(seconds: 1),
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds;
      });
    });

    sub.onDone(() {
      sub.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    _onVerifyCode();
    startTimer();
  }

  @override
  void dispose() {
    startTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0.0,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('verification'),
                SizedBox(height: 10),
                Text(
                  'We sent you an SMS code',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text('On number: '),
                    Text(
                      '${widget.codeCountry + widget.mobileNumber}',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ],
                ),
                SizedBox(height: 120),
                isLoginLoading
                    ? Center(child: CircularProgressIndicator())
                    : PinCodeTextField(
                        appContext: context,
                        length: 6,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          inactiveFillColor: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          fieldHeight: 60,
                          fieldWidth: 50,
                          activeFillColor: Colors.white,
                        ),
                        animationDuration: Duration(milliseconds: 300),
                        // backgroundColor: Colors.blue.shade50,
                        enableActiveFill: true,
                        controller: _pinEditingController,
                        onCompleted: (v) {
                          print("Completed");
                        },
                        onChanged: (value) {
                          print(value);
                        },
                        beforeTextPaste: (text) {
                          print("Allowing to paste $text");
                          //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                          //but you can show anything you want here, like your pop up saying wrong paste format or etc
                          return true;
                        },
                      ),
                isSubmited
                    ? Center(child: Text('Loading...'))
                    : Center(
                        child: _current == 0
                            ? TextButton(
                                onPressed: () async {
                                  _onVerifyCode();
                                  startTimer();
                                },
                                child: Text('Code not received?'),
                              )
                            : Text("Try Again | $_current"),
                      ),
              ],
            ),
          ),
          Expanded(
            child: SkNumberPad(
              bgColor: Colors.white,
              textColor: Colors.black,
              selectedNo: (value) {
                // print(value);
                setState(() {
                  _pinEditingController.text = value;
                });
              },
              doneSelected: (value) async {
                if (_pinEditingController.text.length == 6) {
                  setState(() {
                    isSubmited = true;
                  });
                  try {
                    PhoneAuthCredential phoneAuthCredential =
                        PhoneAuthProvider.credential(
                            verificationId: _verificationId,
                            smsCode: _pinEditingController.text);
                    final User user = (await _firebaseAuth
                            .signInWithCredential(phoneAuthCredential))
                        .user;

                    if (user != null) {
                      _userServices.getUserById(user.uid).then((snapshot) {
                        if (snapshot.exists) {
                          //user already exists
                          if (this.screen == 'login') {
                            setState(() {
                              isSubmited = false;
                            });
                            //need to check user data already exists in db or not
                            if (snapshot.data()['address'] != null) {
                              Navigator.pushReplacementNamed(
                                  context, MainScreen.id);
                            }
                            Navigator.pushReplacementNamed(
                                context, LandingScreen.id);
                          } else {
                            updateUser(id: user.uid, number: user.phoneNumber);
                            Navigator.pushReplacementNamed(
                                context, MainScreen.id);
                          }
                          //user data already exists
                        } else {
                          setState(() {
                            isSubmited = false;
                          });
                          //user data does not exits
                          createUserData(
                              id: user.uid, number: user.phoneNumber);
                          Navigator.pushReplacementNamed(
                              context, LandingScreen.id);
                        }
                      });
                    } else {
                      print('login falied');
                    }
                  } catch (e) {
                    setState(() {
                      isSubmited = false;
                    });
                    print(e.toString());
                    Navigator.of(context).pop();
                  }
                  print(value);
                  print('Done Selected');
                }
              },
            ),
          )
        ],
      ),
    );
  }

  void _onVerifyCode() async {
    setState(() {
      isLoginLoading = true;
      isCodeSent = true;
    });
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) async {
      await _firebaseAuth
          .signInWithCredential(phoneAuthCredential)
          .then((UserCredential value) {
        if (value.user != null) {
          _userServices.getUserById(value.user.uid).then((snapshot) {
            if (snapshot.exists) {
              //user already exists
              if (this.screen == 'login') {
                //need to check user data already exists in db or not
                if (snapshot.data()['address'] != null) {
                  Navigator.pushReplacementNamed(context, MainScreen.id);
                }
                Navigator.pushReplacementNamed(context, LandingScreen.id);
              } else {
                updateUser(id: value.user.uid, number: value.user.phoneNumber);
                Navigator.pushReplacementNamed(context, MainScreen.id);
              }
              //user data already exists
            } else {
              //user data does not exits
              createUserData(
                  id: value.user.uid, number: value.user.phoneNumber);
              Navigator.pushReplacementNamed(context, LandingScreen.id);
            }
          });
        } else {
          AlertDialog(
            title: Text('Invalid OTP'),
            content: Text('Error validating OTP, try again'),
          );
        }
      }).catchError((error) {
        AlertDialog(
          title: Text('Sorry'),
          content: Text('Something has gone wrong, please try later'),
        );
      });
    };
    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      AlertDialog(
          title: Text('Something Wrong!'),
          content: Text(authException.message));
      setState(() {
        isLoginLoading = false;
        isCodeSent = false;
      });
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      _verificationId = verificationId;
      setState(() {
        isLoginLoading = false;
        _verificationId = verificationId;
      });
    };
    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      setState(() {
        _verificationId = verificationId;
      });
    };

    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: widget.codeCountry + widget.mobileNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  // void _onFormSubmitted() async {
  //   AuthCredential _authCredential = PhoneAuthProvider.credential(
  //     verificationId: _verificationId,
  //     smsCode: _pinEditingController.text,
  //   );
  //   try {
  //     UserCredential result =
  //         await _firebaseAuth.signInWithCredential(_authCredential);

  //     User user = result.user;

  //     if (user != null) {
  //       FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(user.uid)
  //           .get()
  //           .then((data) {
  //         if (data.exists) {
  //           Navigator.pushNamed(context, CheckPageRoute);
  //         } else {
  //           updateToFirestore(user);
  //         }
  //       });
  //     } else {
  //       _dialogService.showDialog(
  //         title: 'Warning!',
  //         description: 'Wrong code ! Please enter the last code received.',
  //       );
  //     }
  //   } on PlatformException catch (err) {
  //     _dialogService.showDialog(
  //       title: 'Warning!',
  //       description: err.message,
  //     );
  //   } catch (err) {
  //     _dialogService.showDialog(
  //       title: 'Warning!',
  //       description: err,
  //     );
  //   }
  // }

  // void updateToFirestore(User user) async {
  //   print('insert data');
  //   DocumentReference ref =
  //       FirebaseFirestore.instance.collection('users').doc(user.uid);

  //   return ref.set(
  //     {
  //       'ProfileId': user.uid,
  //       'ActiveIndicator': true,
  //       'SocialName': user.displayName,
  //       'FirstName': null,
  //       'LastName': null,
  //       'PhoneCountryCode': widget.codeCountry,
  //       'ProfilePhoneNumber': user.phoneNumber,
  //       'Location': widget.countryName,
  //       'Email': user.email,
  //       'Image': user.photoURL,
  //       'Role': 'member',
  //       'CreateDateTime': DateTime.now().millisecondsSinceEpoch,
  //       'UpdateDateTime': DateTime.now().millisecondsSinceEpoch,
  //     },
  //   ).whenComplete(() {
  //     Navigator.pushNamed(context, CheckPageRoute);
  //   });
  // }

  updateUser({
    String id,
    String number,
  }) async {
    try {
      _userServices.updateUserData({
        'id': id,
        'number': number,
        'latitude': locationData.latitude ?? 0.0,
        'lognitude': locationData.longitude ?? 0.0,
        'address': locationData.selecteAddress,
        'loaction': locationData.selecteAddress
      });
      return true;
    } catch (e) {
      print('Error $e');
      return false;
    }
  }

  createUserData({
    String id,
    String number,
  }) {
    _userServices.createUserData({
      'id': id,
      'number': number,
      'latitude': locationData.latitude ?? 0.0,
      'lognitude': locationData.longitude ?? 0.0,
      'address': locationData.selecteAddress,
      'loaction': locationData.selecteAddress
    });
  }
}
