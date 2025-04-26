import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Locationscreen extends StatefulWidget {
  const Locationscreen({super.key});

  @override
  State<Locationscreen> createState() => _LocationscreenState();
}

class _LocationscreenState extends State<Locationscreen> {
  String myPosition = '';
  Future<Position>? position;

  Future<Position> getPosition() async {
    // await Geolocator.requestPermission();
    await Geolocator.isLocationServiceEnabled();
    await Future.delayed(const Duration(seconds: 3));
    Position position = await Geolocator.getCurrentPosition();
    return position;
  }

  @override
  void initState() {
    super.initState();
    position = getPosition();
    // getPosition().then((Position myPos) {
    //   setState(() {
    //     // myPosition = myPosition;
    //     myPosition =
    //         "Latitude: ${myPos.latitude.toString()} - Longtitude: ${myPos.longitude.toString()}";
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    // final myWidget = myPosition == '' ? const CircularProgressIndicator() : Text(myPosition);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Location - Dika yonanda putra'),
      ),
      body: Center(
        child: FutureBuilder(
          future: position,
          builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return const Text('Something terrible happened!');
              }
              return Text(snapshot.data.toString());
            } else {
              return const Text('');
            }
          },
        ),
      ),
    );
  }
}
