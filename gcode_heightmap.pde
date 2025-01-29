PImage img;
String[] gcodeLines;
String inputFile = "input.gcode";  // Change to your G-code file
String outputFile = "output.gcode";

float minX = Float.MAX_VALUE, maxX = Float.MIN_VALUE;
float minY = Float.MAX_VALUE, maxY = Float.MIN_VALUE;

void setup() {
  img = loadImage("heightmap.png");  // Load grayscale heightmap
  gcodeLines = loadStrings(inputFile);  // Read G-code file

  // First pass: Find min/max X and Y values in G-code
  for (String line : gcodeLines) {
    if (line.startsWith("G1") || line.startsWith("G0")) {
      String[] parts = line.split(" ");
      for (String part : parts) {
        if (part.startsWith("X")) {
          float x = float(part.substring(1));
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
        if (part.startsWith("Y")) {
          float y = float(part.substring(1));
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
  }

  // Ensure valid range
  if (minX == Float.MAX_VALUE || maxX == Float.MIN_VALUE || minY == Float.MAX_VALUE || maxY == Float.MIN_VALUE) {
    println("No valid X/Y values found in G-code!");
    return;
  }

  println("Detected G-code range: X[" + minX + " to " + maxX + "], Y[" + minY + " to " + maxY + "]");

  // Calculate aspect ratios
  float gcodeAspect = (maxX - minX) / (maxY - minY);
  float imageAspect = float(img.width) / float(img.height);

  // Determine scaling and padding
  float newWidth, newHeight, padX = 0, padY = 0;
  if (gcodeAspect > imageAspect) {
    // G-code is wider → Fit width, adjust height
    newWidth = img.width;
    newHeight = img.width / gcodeAspect;
    padY = (img.height - newHeight) / 2;
  } else {
    // G-code is taller → Fit height, adjust width
    newHeight = img.height;
    newWidth = img.height * gcodeAspect;
    padX = (img.width - newWidth) / 2;
  }

  // Second pass: Modify G-code with new Z values
  PrintWriter output = createWriter(outputFile);

  for (String line : gcodeLines) {
    if (line.startsWith("G1") || line.startsWith("G0")) {
      String[] parts = line.split(" ");
      float x = -1, y = -1, z = -1;

      for (String part : parts) {
        if (part.startsWith("X")) x = float(part.substring(1));
        if (part.startsWith("Y")) y = float(part.substring(1));
        if (part.startsWith("Z")) z = float(part.substring(1));
      }

      if (x >= 0 && y >= 0) {
        // Map G-code coordinates to image pixels while maintaining aspect ratio
        int imgX = int(map(x, minX, maxX, padX, padX + newWidth - 1));
        int imgY = int(map(y, minY, maxY, padY, padY + newHeight - 1));
        imgY = img.height - 1 - imgY;  // Flip Y-axis to match coordinate system

        // Get brightness and convert to Z height
        float brightnessValue = brightness(img.get(imgX, imgY));
        float newZ = map(brightnessValue, 0, 255, 0, 10);  // Adjust Z height range

        // Write new G-code line with adjusted Z
        String newLine = "G1 X" + x + " Y" + y + " Z" + nf(newZ, 0, 3);
        output.println(newLine);
      } else {
        output.println(line);
      }
    } else {
      output.println(line);
    }
  }

  output.flush();
  output.close();
  println("Modified G-code saved to " + outputFile);
}
