import 'package:flutter/material.dart';

TextStyle timeTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: MediaQuery.of(context).size.height / 9,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );
}

TextStyle topTextStyle = TextStyle(
  fontSize: 25,
  color: Colors.black.withOpacity(0.5),
  fontWeight: FontWeight.bold,
);

TextStyle bottomTextStyle = const TextStyle(
  fontSize: 16,
  color: Colors.black,
  fontWeight: FontWeight.bold,
);

TextStyle settingTextStyle = const TextStyle(
  fontSize: 15,
  color: Colors.black,
  fontWeight: FontWeight.bold,
);

TextStyle alertButtonTextStyle = const TextStyle(
  fontSize: 13,
  color: Colors.black,
  fontWeight: FontWeight.bold,
);

InputDecoration settingTextField = const InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.all(5),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.black,
      width: 1.5,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.black,
      width: 2.5,
    ),
  ),
);
