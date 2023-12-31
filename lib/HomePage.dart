import 'package:flutter/material.dart';
import 'Meditation.dart';
import 'Sutta.dart';
import 'Resources.dart';
import 'Quotes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() =>_HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> _sections = [Meditation(), Sutta(), Quotes(), Resources()];
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: Center(
        child: _sections[_selectedIndex]
        ),

      bottomNavigationBar: BottomNavigationBar(
        enableFeedback: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Meditation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lyrics),
            label: 'Metta Sutta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Daily Quotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Resources',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.amber[500],
        onTap: _onItemTapped,
      ),
    );
  }
}
