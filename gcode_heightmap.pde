PImage img;
String[] gcodeLines;
String inputFile = "input.gcode";  // Change to your file name
String outputFile = "output.gcode"; 

void setup() {
  img = loadImage("heightmap.png");  // Load grayscale image
  
  gcodeLines = loadStrings(inputFile);  // Read G-code file
  
  PrintWriter output = createWriter(outputFile);  

  for (String line : gcodeLines) {
    if (line.startsWith("G1") || line.startsWith("G0")) {  // Process only movement commands
      String[] parts = line.split(" ");
      float x = -1, y = -1, z = -1;

      for (String part : parts) {
        if (part.startsWith("X")) x = float(part.substring(1));
        if (part.startsWith("Y")) y = float(part.substring(1));
        if (part.startsWith("Z")) z = float(part.substring(1));
      }

      if (x >= 0 && y >= 0) {  
        // Map X, Y from G-code to image pixel space
        int imgX = int(map(x, 0, 200, 0, img.width));  // Adjust the range as needed
        int imgY = int(map(y, 0, 250, 0, img.height)); 
        imgY = img.height - imgY;  // Flip Y to match coordinate systems

        // Get brightness (0-255) and map it to Z height
        float brightnessValue = brightness(img.get(imgX, imgY));
        float newZ = map(brightnessValue, 0, 255, 0, 5);  // Adjust Z mapping range
        
        // Reconstruct G-code line with updated Z
        String newLine = "G1 X" + x + " Y" + y + " Z" + nf(newZ, 0, 3);
        output.println(newLine);
      } else {
        output.println(line);  // Pass through other lines
      }
    } else {
      output.println(line);  // Pass through non-movement commands
    }
  }
  
  output.flush();
  output.close();
  println("Modified G-code saved to " + outputFile);
}
