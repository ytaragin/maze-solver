import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/maze_creation_page.dart';
import 'pages/maze_solver_page.dart';
import 'services/tile_image_cache.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TileImageCache()..loadAll(),
      child: MaterialApp(
        title: 'Maze Tool',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/solve',
        routes: {
          '/create': (context) => const MazeCreationPage(),
          '/solve': (context) => const MazeSolverPage(),
        },
      ),
    );
  }
}
