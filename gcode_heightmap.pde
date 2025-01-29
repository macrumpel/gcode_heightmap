PImage img;
String[] gcodeLines;
String inputFile = "input.gcode";  
String outputFile = "output.gcode";

float minX = Float.MAX_VALUE, maxX = Float.MIN_VALUE;
float minY = Float.MAX_VALUE, maxY = Float.MIN_VALUE;
float newWidth, newHeight, padX, padY;

void setup() {
  size(800, 800);  
  img = loadImage("heightmap.png");
  gcodeLines = loadStrings(inputFile);
  surface.setResizable(true);
    
  // Find G-code bounds
  for (String line : gcodeLines) {
    if (line.startsWith("G1") || line.startsWith("G0")) {
      String[] parts = line.split(" ");
      for (String part : parts) {
        if (part.startsWith("X")) {
          float x = float(part.substring(1));
          minX = min(minX, x);
          maxX = max(maxX, x);
        }
        if (part.startsWith("Y")) {
          float y = float(part.substring(1));
          minY = min(minY, y);
          maxY = max(maxY, y);
        }
      }
    }
  }

  // Print min/max values for reference
  println("G-code Range:");
  println("X Min: " + minX + " | X Max: " + maxX);
  println("Y Min: " + minY + " | Y Max: " + maxY);

  // Compute aspect ratios and fit
  float gcodeAspect = (maxX - minX) / (maxY - minY);
  float imageAspect = float(img.width) / float(img.height);
  println("gcode Aspect ratio = " + gcodeAspect );
  println("image Aspect ratio = " + imageAspect);

  if (gcodeAspect > imageAspect) {
    newWidth = img.width;
    newHeight = img.width / gcodeAspect;
    padX = 0;
    padY = (img.height - newHeight) / 2;
  } else {
    newHeight = img.height;
    newWidth = img.height * gcodeAspect;
    padX = (img.width - newWidth) / 2;
    padY = 0;
  }
  println(newWidth + "," + newHeight);
surface.setSize(int(newWidth+padX),int(newHeight+padY));
  println("Press 'S' to save modified G-code.");
}


// Draw preview
void draw() {
  background(50);
  image(img, 0, 0, width, height);  

  drawGcodePath(color(0, 255, 0));  // Green path with adjusted Z for pen plotter

  fill(255);
  textSize(14);
  text("Green: Adjusted G-code (Z controls pen pressure)", 10, height - 10);
}

// Function to draw G-code path with variable thickness
void drawGcodePath(color strokeColor) {
  stroke(strokeColor);
  
  float lastX = -1, lastY = -1;

  for (String line : gcodeLines) {
    if (line.startsWith("G1") || line.startsWith("G0")) {
      String[] parts = line.split(" ");
      float x = -1, y = -1;

      for (String part : parts) {
        if (part.startsWith("X")) x = float(part.substring(1));
        if (part.startsWith("Y")) y = float(part.substring(1));
      }

      if (x >= 0 && y >= 0) {
        int imgX = int(map(x, minX, maxX, padX, padX + newWidth - 1));
        int imgY = int(map(y, minY, maxY, padY, padY + newHeight - 1));
        imgY = img.height - 1 - imgY;  

        float brightnessValue = brightness(img.get(imgX, imgY));
        float newZ = map(brightnessValue, 0, 255, 0, 10);
        float strokeW = map(newZ, 0, 10, 3, 0.5);  // Inverted: Higher Z = Thinner line

        strokeWeight(strokeW);

        if (lastX >= 0 && lastY >= 0) {
          line(lastX, lastY, imgX, imgY);
        }
        lastX = imgX;
        lastY = imgY;
      }
    }
  }
}

// Save G-code when 'S' is pressed
void keyPressed() {
  if (key == 'S' || key == 's') {
    saveModifiedGCode();
  }
}

// Function to save modified G-code
void saveModifiedGCode() {
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
        int imgX = int(map(x, minX, maxX, padX, padX + newWidth - 1));
        int imgY = int(map(y, minY, maxY, padY, padY + newHeight - 1));
        imgY = img.height - 1 - imgY;

        float brightnessValue = brightness(img.get(imgX, imgY));
        float newZ = map(brightnessValue, 0, 255, 0, 10);

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
