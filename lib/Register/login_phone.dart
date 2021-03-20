import 'package:appdevl/Register/otp_screen.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'package:flutter/material.dart';

class LoginPhone extends StatefulWidget {
  static const String id = 'login-phone';
  @override
  _LoginPhoneState createState() => _LoginPhoneState();
}

class _LoginPhoneState extends State<LoginPhone> {
  final _formPhoneValidate = GlobalKey<FormState>();
  final _phoneNo = TextEditingController();
  String intialPhone = '+7';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('welcome'),
            SizedBox(height: 10),
            Text(
              'Fill the form to become our guest',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Container(
              height: 65.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 4,
                    blurRadius: 10,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Row(
                children: [
                  CountryListPick(
                    appBar: AppBar(
                      iconTheme: IconThemeData(color: Colors.black),
                      backgroundColor: Colors.white,
                      title: Text(
                        'Pick your country',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    // To disable option set to false
                    theme: CountryTheme(
                      isShowFlag: true,
                      isShowTitle: false,
                      isShowCode: false,
                      isDownIcon: true,
                      showEnglishName: true,
                    ),
                    // Set default value
                    initialSelection: '+7',
                    onChanged: (CountryCode code) {
                      setState(() {
                        intialPhone = code.dialCode;
                      });
                    },
                    useUiOverlay: true,
                    useSafeArea: false,
                  ),
                  VerticalDivider(),
                  Flexible(
                    child: Form(
                      key: _formPhoneValidate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextFormField(
                          controller: _phoneNo,
                          keyboardType: TextInputType.number,
                          validator: (value) => (_phoneNo.text.isNotEmpty &&
                                  _phoneNo.text.length == 10)
                              ? null
                              : 'Input valid number',
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixText: intialPhone,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black,
                    child: IconButton(
                      icon: Icon(Icons.keyboard_arrow_right),
                      onPressed: () {
                        if (_formPhoneValidate.currentState.validate()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OTPScreen(
                                mobileNumber: _phoneNo.text,
                                codeCountry: intialPhone,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Next',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Spacer(),
            Center(
              child: Text(
                'Service Rules',
                style: TextStyle(
                  letterSpacing: 3,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dashed,
                ),
              ),
            ),
            SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}
