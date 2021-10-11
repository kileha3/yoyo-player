import 'package:flutter/material.dart';

Widget topChip(Widget data, Color background,Function fun) {
  return InkWell(
    onTap: fun as void Function()?,
    child: Container(
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5,3,5,3),
        child: data,
      ),
    ),
  );
}
