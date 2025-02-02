import controlP5.*;

PImage img;
String[] gcodeLines;
String inputFile = "input.gcode";
String outputFile = "gcode_out/output[heightmapped]_" + hour() + minute() + "-" + day() + month() + year() + ".gcode";

float minX = Float.MAX_VALUE, maxX = Float.MIN_VALUE;
float minY = Float.MAX_VALUE, maxY = Float.MIN_VALUE;
float imgWidth, imgHeight;

// ControlP5 GUI
ControlP5 cp5;
float zMin = 0, zMax = 10;  // Z-axis mapping range
float strokeMin = 0.5, strokeMax = 3;  // Stroke weight range
float brightnessThreshold = 128;  // Brightness threshold
float imageFade = 255;  // Image opacity (0 = fully transparent, 255 = fully opaque)
boolean ignoreWhite = false;  // Toggle for ignoring white pixels

void setup() {
  size(800, 600);  // Default canvas size
  img = loadImage("heightmap.png");
  gcodeLines = loadStrings(inputFile);

  // Error handling
  if (img == null) {
    println("Error: Could not load image. Please ensure 'heightmap.png' exists.");
    exit();
  }
  if (gcodeLines == null) {
    println("Error: Could not load G-code file. Please ensure 'input.gcode' exists.");
    exit();
  }

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

  // Compute aspect ratios and scale image to fit canvas while maintaining aspect ratio
  float gcodeAspect = (maxX - minX) / (maxY - minY);
  float imageAspect = float(img.width) / float(img.height);

  if (gcodeAspect > imageAspect) {
    // Fit to width
    imgWidth = width;
    imgHeight = imgWidth / imageAspect;
  } else {
    // Fit to height
    imgHeight = height;
    imgWidth = imgHeight * imageAspect;
  }

  // Resize the image to fit the canvas
  img.resize(int(imgWidth), int(imgHeight));

  // Adjust canvas size based on scaled image
  surface.setSize(int(imgWidth), int(imgHeight));

  println("Image Size: " + imgWidth + " x " + imgHeight);
  println("Adjusted G-code Range:");
  println("X Min: " + minX + " | X Max: " + maxX);
  println("Y Min: " + minY + " | Y Max: " + maxY);

  // Initialize ControlP5 GUI
  cp5 = new ControlP5(this);
  cp5.addSlider("zMin")
     .setPosition(10, 30)
     .setRange(0, 10)
     .setValue(0)
     .setLabel("Z Min");
  cp5.addSlider("zMax")
     .setPosition(10, 60)
     .setRange(0, 10)
     .setValue(5)
     .setLabel("Z Max");
  cp5.addSlider("strokeMin")
     .setPosition(10, 90)
     .setRange(0.1, 5)
     .setValue(0.5)
     .setLabel("Stroke Min");
  cp5.addSlider("strokeMax")
     .setPosition(10, 120)
     .setRange(0.1, 5)
     .setValue(3)
     .setLabel("Stroke Max");
  cp5.addSlider("brightnessThreshold")
     .setPosition(10, 150)
     .setRange(0, 255)
     .setValue(128)
     .setLabel("Brightness Threshold");
  cp5.addSlider("imageFade")
     .setPosition(10, 180)
     .setRange(0, 255)
     .setValue(255)
     .setLabel("Image Fade");
  cp5.addCheckBox("ignoreWhiteCheckbox")
     .setPosition(10, 210)
     .setSize(20, 20)
     .addItem("Ignore White", 0)
     .activate(ignoreWhite ? 0 : 2);  // Activate if ignoreWhite is true

  println("Press 'S' to save modified G-code.");
}

// Draw preview
void draw() {
  background(50);

  // Draw the scaled image with fade control
  tint(255, imageFade);  // Apply transparency to the image
  image(img, 0, 0, imgWidth, imgHeight);
  noTint();  // Reset tint for other elements

  // Draw a dark transparent box behind the GUI
  fill(0, 150);  // Black with 150/255 transparency
  noStroke();
  rect(5, 25, 200, 210);  // Adjust size and position as needed

  // Draw the G-code path with adjusted Z for pen plotter
  drawGcodePath(color(255, 255, 0));  // Yellow path

  // Display Z value when hovering over the image
  if (mouseX >= 0 && mouseX < imgWidth && mouseY >= 0 && mouseY < imgHeight) {
    float brightnessValue = brightness(img.get(mouseX, mouseY));
    float zValue = map(brightnessValue, 0, 255, zMin, zMax);

    fill(0);
    textSize(14);
    text("Z Value: " + nf(zValue, 0, 2), mouseX + 10, mouseY - 10);
  }

  // Display GUI text
  fill(255);
  textSize(14);
  text("Green: Adjusted G-code (Z controls pen pressure)", 10, height - 10);
}

// Function to draw G-code path with variable thickness
void drawGcodePath(color strokeColor) {
  stroke(strokeColor);

  float lastX = -1, lastY = -1;

  for (String line : gcodeLines) {
    if (line.startsWith("G1")) {
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
        float absolute_brightnessValue = brightnessValue;
        // Apply brightness threshold
        if (brightnessValue < brightnessThreshold) {
          brightnessValue = 0;  // Treat as dark
        } else {
          brightnessValue = 255;  // Treat as bright
        }

        // If "Ignore White" is enabled and pixel is white, skip drawing
        if (ignoreWhite && absolute_brightnessValue == 255) {
        if (x >= 0 && y >= 0) {
            // Map G-code coordinates to image coordinates
            imgX = int(map(x, minX, maxX, 0, imgWidth));
            imgY = int(map(y, minY, maxY, 0, imgHeight));
            lastX = imgX;
            lastY = imgY;
        }
          continue;
        }

        float newZ = map(brightnessValue, 0, 255, zMin, zMax);  // Use GUI-adjusted Z range
        float strokeW = map(newZ, zMin, zMax, strokeMax, strokeMin);  // Use GUI-adjusted stroke range

        strokeWeight(strokeW);

        if (lastX >= 0 && lastY >= 0) {
          // Draw the path line from the previous point to the current point
          line(lastX, lastY, imgX, imgY);
        }
        lastX = imgX;
        lastY = imgY;
      }
    } else if (line.startsWith("G0")) {
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
    if (line.startsWith("G1")) {
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
        imgY = img.height - imgY;  // Flip Y to match coordinate systems

        // Get brightness value from image at the mapped point
        float brightnessValue = brightness(img.get(imgX, imgY));

        // Apply brightness threshold
        if (brightnessValue < brightnessThreshold) {
          brightnessValue = 0;  // Treat as dark
        } else {
          brightnessValue = 255;  // Treat as bright
        }

        // If "Ignore White" is enabled and pixel is white, raise Z above zMax
        float newZ;
        if (ignoreWhite && brightnessValue == 255) {
          newZ = zMax + 2;  // Raise Z by 2 points above zMax
        } else {
          newZ = map(brightnessValue, 0, 255, zMin, zMax);  // Use GUI-adjusted Z range
        }

        // Save new line with modified Z
        String newLine = "G1 X" + x + " Y" + y + " Z" + nf(newZ, 0, 3);
        output.println(newLine);
      }
    } else if (line.startsWith("G0")) {
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
        imgY = img.height - imgY;  // Flip Y to match coordinate systems

        // Save G0 move with Z lifted
        String newLine = "G0 X" + x + " Y" + y + " Z8";
        output.println(newLine);
      }
    } else {
      output.println(line);
    }
  }

  output.flush();
  output.close();
  println("Modified G-code saved to " + outputFile);
}

// ControlP5 checkbox callback
public void controlEvent(ControlEvent event) {
  if (event.isFrom(cp5.get(CheckBox.class, "ignoreWhiteCheckbox"))) {
    ignoreWhite = event.getArrayValue()[0] == 1;  // Update ignoreWhite based on checkbox state
  }
}