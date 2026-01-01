# maze_tool

A Flutter-based maze solver with both a graphical UI application and command-line interface for working with mazes.

## Features

- Load mazes from CSV files
- Solve mazes using graph-based pathfinding
- Render mazes as PNG images with optional solution overlay
- Interactive Flutter GUI for maze visualization
- Command-line tool for batch processing

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Dart SDK (comes with Flutter)

### Running the Flutter Application

To run the graphical maze tool application:

```bash
flutter run
```

For specific platforms:
```bash
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d chrome     # Web browser
```

### Building for Web Deployment

To build the application for deployment to a website:

```bash
flutter build web
```

The build output will be in the `build/web/` directory, which contains all the HTML, CSS, and JavaScript files needed to run the app in a browser. You can deploy this folder to any static web hosting service (GitHub Pages, Netlify, Vercel, Firebase Hosting, etc.).

If deploying to a subdirectory (e.g., `/maze`), use the `--base-href` flag:

```bash
flutter build web --base-href /maze/
```

### Using the Command Line Tool

The command-line `maze_tool` can load, analyze, solve, and render mazes from CSV files.

#### Basic Usage

```bash
dart run bin/maze_tool.dart [options] <maze.csv>
```

#### Options

- `-h, --help` - Display usage information
- `-s, --solve` - Solve the maze and output solution
- `-i, --info` - Display maze information and statistics
- `-g, --graph` - Display maze graph structure
- `-r, --render` - Render maze to PNG image
- `-o, --output <file>` - Output file (default: `<input>.sol` for solve, `<input>.png` for render)
- `--solution <file>` - Solution file to overlay on rendered image (default: `<input>.sol`)
- `-t, --tiles <path>` - Path to tiles folder for rendering (default: `tiles`)
- `--tile-size <size>` - Size of each tile in pixels (default: `50`)

#### Examples

Solve a maze:
```bash
dart run bin/maze_tool.dart -s maze1.csv
```

Display maze information:
```bash
dart run bin/maze_tool.dart -i maze1.csv
```

Render maze to PNG with solution:
```bash
dart run bin/maze_tool.dart -s -r maze1.csv
```

Render with custom output and tile size:
```bash
dart run bin/maze_tool.dart -r -o my_maze.png --tile-size 100 maze1.csv
```

## Project Structure

- `lib/` - Core Flutter application and shared libraries
- `bin/` - Command-line tool entry point
- `tiles/` - Tile images for maze rendering
- `mazes/` - Sample maze CSV files

## Development

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
