import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Image logoWidget(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    //width: 240,
    //height: 500,
    color: Colors.white,
  );
}

TextField resuableTextfield(String text, IconData icon, bool isPasswordType,
    TextEditingController controller) {
  return TextField(
    controller: controller,
    obscureText: isPasswordType,
    enableSuggestions: !isPasswordType,
    autocorrect: !isPasswordType,
    cursorColor: Colors.white,
    style: TextStyle(color: Colors.white.withOpacity(0.9)),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.white70,
      ),
      labelText: text,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      fillColor: Colors.white.withOpacity(0.3),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none)),
    ),
    keyboardType: isPasswordType
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
  );
}

Container signInSignUpButton(BuildContext context, bool islogin, Function onTap,
    {bool isDoctor = false}) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: () async {
        // Set the global variable indicating whether the user is a doctor or not
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDoctor', isDoctor);
        onTap();
      },
      child: Text(
        islogin
            ? "LOG IN"
            : isDoctor
                ? 'SIGN UP AS DOCTOR'
                : 'SIGN UP AS USER',
        style: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.black26;
            }
            return Colors.white;
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
    ),
  );
}

//errorr     meassangeee
class ErrorMessageWidget extends StatefulWidget {
  final String errorMessage;

  const ErrorMessageWidget({super.key, required this.errorMessage});

  @override
  State<ErrorMessageWidget> createState() => _ErrorMessageWidgetState();
}

class _ErrorMessageWidgetState extends State<ErrorMessageWidget> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.errorMessage.isNotEmpty,
      child: Text(
        widget.errorMessage,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14.0,
        ),
      ),
    );
  }
}
