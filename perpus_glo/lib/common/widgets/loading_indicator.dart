import 'package:flutter/material.dart';

// loading_indicator.dart digunakan untuk menampilkan
// indikator pemuatan (loading indicator) di aplikasi.
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  
  const LoadingIndicator({
    Key? key, 
    this.size = 40, 
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? Theme.of(context).primaryColor,
          strokeWidth: 3,
        ),
      ),
    );
  }
}