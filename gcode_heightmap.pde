PImage img;
String[] gcodeLines;
String inputFile = "input.gcode";  
String outputFile = "output.gcode";

float minX = Float.MAX_VALUE, maxX = Float.MIN_VALUE;
float minY = Float.MAX_VALUE, maxY = Float.MIN_VALUE;
float imgWidth, imgHeight;

void setup() {
  img = loadImage("heightmap.png");
  gcodeLines = loadStrings(inputFile);

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

  // Compute aspect ratios and fit image to canvas size while maintaining aspect ratio
  float gcodeAspect = (maxX - minX) / (maxY - minY);
  float imageAspect = float(img.width) / float(img.height);
  println("G-code Aspect: " + gcodeAspect + ", Image Aspect: " + imageAspect);
  // Scale image to fit the canvas while maintaining aspect ratio
  if (gcodeAspect > imageAspect) {
    imgWidth = img.width;  // Make the image fit the canvas width
    imgHeight = img.height;
  } else {
    imgHeight = img.height;  // Make the image fit the canvas height
    imgWidth = img.width;
  }

  // Adjust canvas size based on image
  surface.setSize(int(imgWidth), int(imgHeight));

  println("Image Size: " + imgWidth + " x " + imgHeight);
  println("Adjusted G-code Range:");
  println("X Min: " + minX + " | X Max: " + maxX);
  println("Y Min: " + minY + " | Y Max: " + maxY);
  
  println("Press 'S' to save modified G-code.");
}

// Draw preview
void draw() {
  background(50);

  // Draw the image scaled properly (without distortion)
  image(img, 0, 0, imgWidth, imgHeight);

  // Now we draw the G-code path (green)
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
        // Map G-code coordinates to image coordinates
        int imgX = int(map(x, minX, maxX, 0, imgWidth));
        int imgY = int(map(y, minY, maxY, 0, imgHeight));

        // Get brightness from the image at the mapped position
        float brightnessValue = brightness(img.get(imgX, imgY));
        float newZ = map(brightnessValue, 0, 255, 0, 10);  // Map brightness to Z value
        float strokeW = map(newZ, 0, 10, 3, 0.5);  // Higher Z = thinner line

        strokeWeight(strokeW);

        if (lastX >= 0 && lastY >= 0) {
          // Draw the path line from the previous point to the current point
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
        // Map G-code coordinates to image coordinates
        int imgX = int(map(x, minX, maxX, 0, imgWidth));
        int imgY = int(map(y, minY, maxY, 0, imgHeight));

        // Get brightness value from image at the mapped point
        float brightnessValue = brightness(img.get(imgX, imgY));
        float newZ = map(brightnessValue, 0, 255, 0, 5);

        // Save new line with modified Z
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
