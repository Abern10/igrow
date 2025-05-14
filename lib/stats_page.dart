import 'package:flutter/material.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<Widget> draggableIcons = [];
  double health = 0.0;

  String getPlantImage() {
    if (health >= 0.85) {
      return 'assets/images/plant100.png';
    } else if (health >= 0.5) {
      return 'assets/images/plant50.png';
    } else if (health >= 0.25) {
      return 'assets/images/plant25.png';
    } else {
      return 'assets/images/plant0.png';
    }
  }

  void addDraggableIcon(IconData iconData, Color color) {
    setState(() {
      draggableIcons.add(Draggable(
        feedback: Icon(iconData, size: 50, color: color),
        child: Icon(iconData, size: 50, color: color),
        childWhenDragging: Opacity(opacity: 0.5, child: Icon(iconData, size: 50, color: color)),
        onDragEnd: (details) {
          setState(() {
            draggableIcons.removeLast();
            health = (health + 0.1).clamp(0.0, 1.0);
          });
        },
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: LinearProgressIndicator(
            value: health,
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            minHeight: 10,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Image.asset(
              getPlantImage(),
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          Positioned.fill(
            child: Stack(
              children: draggableIcons,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.local_drink, color: Colors.blue),
              onPressed: () => addDraggableIcon(Icons.local_drink, Colors.blue),
            ),
            IconButton(
              icon: Icon(Icons.shopping_bag, color: Colors.green),
              onPressed: () => addDraggableIcon(Icons.shopping_bag, Colors.green),
            ),
            IconButton(
              icon: Icon(Icons.grass, color: Colors.brown),
              onPressed: () => addDraggableIcon(Icons.grass, Colors.brown),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: StatsPage(),
  ));
}
