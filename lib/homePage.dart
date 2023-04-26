import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'camera.dart';

Route _createRoute(page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end);
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                height:
                    MediaQuery.of(context).orientation == Orientation.landscape
                        ? 900
                        : MediaQuery.of(context).size.height,

                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffffff),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 500,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Image.asset("assets/1.png"),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'SMART EYE',
                          style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoSlab'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Your Safety Net',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoSlab'),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 230,
                          height: 50,
                          child: ElevatedButton(
                            child: Text(
                              'Start',
                              style: TextStyle(fontSize: 17),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context)
                                  .push(_createRoute(CameraTestScreen()
                                      // page
                                      ));
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 100)
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
