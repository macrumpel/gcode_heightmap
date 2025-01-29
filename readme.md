Processing sketch to transform gcode file to adapt z axis according to a heightmap of a greayscale image.

Load the grayscale image – This will serve as the heightmap.
Read the G-code file – Extract X and Y coordinates.
Map brightness to Z values – Look up pixel brightness at the corresponding (X, Y) and use it to set the Z value.
Output modified G-code – Write a new G-code file with the adjusted Z-axis values.

How It Works

    Loads the G-code and extracts X, Y, and Z values.
    Maps X, Y to the grayscale image to get brightness.
    Uses brightness to modify the Z height dynamically.
    Writes the modified G-code to a new file.

Requirements

    Place your grayscale heightmap as "heightmap.png" in the Processing sketch folder.
    Adjust the coordinate ranges (map(x, 0, 100, 0, img.width)) to match your machine’s dimensions.
    The output will be saved as "output.gcode" in the sketch folder.

