import 'package:flutter/material.dart';

class CreatorMenu extends StatefulWidget {
  const CreatorMenu({
    super.key,
  });

  @override
  State<CreatorMenu> createState() => _CreatorMenuState();
}

class _CreatorMenuState extends State<CreatorMenu> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: null,
              child: Text('Countdown Configurator'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null,
              child: Text('Slideshow Configurator'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null,
              child: Text('Voting Configurator'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null,
              child: Text('Amazon Wishlist Configurator'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null,
              child: Text('Account'),
            ),
          ],
        ),
      ),
    );
  }
}
