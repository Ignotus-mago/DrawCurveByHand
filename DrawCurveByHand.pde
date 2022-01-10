/**
 * How to transform a gesture made by dragging the mouse into a Bezier curve:
 *    1. Draw a line, curvy or crooked as you like. Capture points with mouseX, mouseY. (tan line)
 *    2. Reduce the total number of points with the Ramer-Douglas-Peucker algorithm (red line)
 *  ` 3. Turn the reduced point set into a Bezier spline, a smooth, continuous curve that 
 *       can be represented with Bezier curves. (blue line)
 *       You can also create a weighted Bezier, which may fit the drawn line a little better.
 *    4. Offset the curve to either side to simulate a brushstroke. (transparent green)
 * 
 *    This version of the code declares classes Vertex2DINF, LineVertex, BezVertex and BezShape.
 *    A second version uses the same classes from my Processing library IgnoCodeLib. 
 * 
 *    @author Paul Hertz, Chicago, 2022 <ignotusATgmailDOTcom>, https://github.com/Ignotus-mago
 *
 *    Click and drag to draw.
 *    + and - keys change epsilon / amount of point reduction 
 *    M key shows/hides Bezier anchor and control points.
 *    Q key draws a brush stroke.
 *    W key shifts between Bezier Spline and Weighted Bezier.
 *    I key prints information to the console
 *    P key saves to PDF format
 *    V key saves to SVG format
 *    H key prints this help message.
 *
 */

// for PDF export
import processing.pdf.*;
// for SVG export
import processing.svg.*;

public ArrayList<PVector> allPoints = new ArrayList<PVector>();
public ArrayList<PVector> drawPoints = new ArrayList<PVector>();
public BezShape bezPoints;
public BezShape weightedBezPoints;
public BezShape brushShape;
public PGraphics buffer;
boolean isRefreshBuffer = false;
boolean isShowBrush = false;
float epsilon = 0;
float minEpsilon = 1;
float maxEpsilon = 40;
boolean isDrawWeighted = false;
PVector currentPoint;
color dragColor = color(233, 144, 89, 64);    // tan
color rdpColor = color(233, 89, 144);         // red
color curveColor = color(55, 199, 246);       // blue
color brushColor = color(76, 199, 144, 96);   // tranparent green

public void settings() {
  // we may get greater speed with the P2D renderer
  size(1024, 768, P2D);
}

public void setup() {
  epsilon = 5.0f;
  currentPoint = new PVector(-1, -1);
  printHelpMessage();
}

public void draw() {
  background(255);
  if (!(allPoints.size() > 0)) {
    writeToScreen("Draw something!");
  }
  if (mousePressed) {
    addPoint();
    isRefreshBuffer = true;
  }
  if (isRefreshBuffer) {
    // recalculate everything, including the image in the buffer, whenever necessary
    freshDraw();
    isRefreshBuffer = false;
  }
  // most of the time through the draw loop, we don't redo all our calculations, 
  // we just draw the buffer to the screen. We call freshDraw() only when the drawing changes.
  if (null != buffer) image(buffer, 0, 0);
  if (null != bezPoints) {
    printSizes(false);
  }
}

public void freshDraw() {
  RDPDraw();
  curveDraw();
  brushDraw();
  buffer = drawToPGraphics();
}

public void RDPDraw() {
  if (allPoints.size() > 0) {
    stroke(dragColor);
    strokeWeight(8);
    noFill();
    beginShape();
    for (PVector vec : allPoints) {
      vertex(vec.x, vec.y);
    }
    endShape();
  }
  if (drawPoints.size() > 0) {
    stroke(rdpColor);
    strokeWeight(1);
    noFill();
    beginShape();
    for (PVector vec : drawPoints) {
      vertex(vec.x, vec.y);
    }
    endShape();
  }
}

public void curveDraw() {
  if (null != bezPoints && bezPoints.size() > 0) {
    pushStyle();
    stroke(curveColor);
    strokeWeight(2);
    noFill();
    if (isDrawWeighted) {
      weightedBezPoints.drawQuick();
    }
    else {
      bezPoints.drawQuick();
    }
    popStyle();
  }
}

public void brushDraw() {
  if (null != brushShape && isShowBrush) {
    pushStyle();
    fill(brushColor);
    noStroke();
    brushShape.drawQuick();
    popStyle();
  }
}

public void keyPressed() {
  boolean mark;
  switch(key) {
    case '=':
    case '+': 
      // increment epsilon
      if (epsilon < maxEpsilon) epsilon += 1;
      // println("-- epsilon = "+ epsilon);
      mark = bezPoints.isMarked();
      calculateDerivedPoints();
      bezPoints.setIsMarked(mark);
      weightedBezPoints.setIsMarked(mark);
      isRefreshBuffer = true;
      break;
    case '-':
    case '_': 
      // decrement epsilon
      if (epsilon > minEpsilon) epsilon -= 1;
      // println("-- epsilon = "+ epsilon);
      mark = bezPoints.isMarked();
      calculateDerivedPoints();
      bezPoints.setIsMarked(mark);
      weightedBezPoints.setIsMarked(mark);
      isRefreshBuffer = true;
      break;
    case 'i':
    case 'I':
      printSizes(true);
      break;
    case 'p': 
    case 'P':
      saveToPDF("drawPDF.pdf");
      println("----- saved graphics to a PDF file");
      break;
    case 'M':
    case 'm':
      // mark control points on Bezier curve 
      if (null != bezPoints && bezPoints.size() > 0) {
        mark = !bezPoints.isMarked();
        bezPoints.setIsMarked(mark);
        weightedBezPoints.setIsMarked(mark);
      }
      isRefreshBuffer = true;
      break;
    case 'q':
    case 'Q':
      isShowBrush = !isShowBrush;
      if (isShowBrush) {
        brushShape = quickBrushShape(drawPoints, 24.0);
      }
      isRefreshBuffer = true;
      break;
    case 's':
    case 'S':
      break;
      // 
    case 'W':
    case 'w':
      isDrawWeighted = !isDrawWeighted;
      if (isShowBrush) {
        brushShape = quickBrushShape(drawPoints, 24.0);
      }
      isRefreshBuffer = true;
      break;
    //case 'C':
    //case 'c':
    //  if (null != bezPoints && bezPoints.size() > 0) {
    //    bezPoints.setIsClosed(!bezPoints.isClosed());
    //    weightedBezPoints.setIsClosed(bezPoints.isClosed());
    //  }
    //  break;
    case 'v':
      saveToSVG("drawSVG.svg");
      println("----- saved graphics to an SVG file");
      break;
    case 'H':
    case 'h':
      // print help message to console
      printHelpMessage();
      break;
  }
}

public void printHelpMessage() {
  println("This code reduces the number of points in a line you draw on screen"); 
  println("and then creates curves from the reduced points.");
  println("It uses the Ramer-Douglas-Peucker algorithm as implemented by Daniel Shiffman.");
  println("Click and drag to draw.");
  println("+ and - keys change epsilon / amount of reduction");
  println("M key shows/hides Bezier anchor and control points.");
  println("Q key draws a brush stroke.");
  println("W key shifts between Bezier Spline and Weighted Bezier.");
  println("I key prints information to the console");
  println("P key saves to PDF format");
  println("V key saves to SVG format");
  println("H key prints this help message.");
}

public void mousePressed() {
  // clear the slate to begin a new drawing
  allPoints.clear();
  drawPoints.clear();
  bezPoints = null;
  brushShape = null;
  // add the first point
  addPoint();
}

public void addPoint() {
  if (mouseX != currentPoint.x || mouseY != currentPoint.y) {
    currentPoint = new PVector(mouseX, mouseY);
    allPoints.add(currentPoint); 
  }
}

public void mouseReleased() {
  calculateDerivedPoints();
  freshDraw();
}

public void calculateDerivedPoints() {
  reducePoints();
  calculateCurve();
  calculateWeightedCurve();
  if (isShowBrush) {
    brushShape = quickBrushShape(drawPoints, 24.0);
  }
}

public void printSizes(boolean useConsole) {
  int allSize = allPoints.size();
  int drawSize = drawPoints.size();
  float percent = (drawSize * 100.0f)/allSize;
  
  String msg = ("For epsilon of "+ nf(epsilon, 0, 2) +": all points: "+ allSize +", reduced points: "+ 
           drawSize +", "+ nf(percent, 0, 2) +"% reduction, Curve points: "+ (bezPoints.pointCount() + 1));
  msg += isDrawWeighted ? ", Weighted Bezier" : ", Bezier Spline";
  if (useConsole) {
    println(msg);
  }
  else {
    writeToScreen(msg);
  }
}

public void writeToScreen(String msg) {
    pushStyle();
    fill(96);
    textSize(18);
    text(msg, 16, 756);
    popStyle();
}

public void reducePoints() {
  drawPoints.clear();
  int total = allPoints.size();
  PVector start = allPoints.get(0);
  PVector end = allPoints.get(total-1);
  drawPoints.add(start);
  rdp(0, total-1, allPoints, drawPoints);
  // put in a midpoint when there are only two points in the reduced points
  if (drawPoints.size() == 1) {
    PVector midPoint = start.copy().add(end).div(2.0f);
    drawPoints.add(midPoint);
  }
  drawPoints.add(end);
}

/* ------------- PGraphics Output ------------- */

// example of how to draw to a PGraphics
public PGraphics drawToPGraphics() {
  PGraphics pix = createGraphics(width, height);
  pix.beginDraw();
  pix.background(255,255,255);
  // RDPDraw for PGraphics
  if (allPoints.size() > 0) {
    pix.stroke(dragColor);
    pix.strokeWeight(8);
    pix.noFill();
    pix.beginShape();
    for (PVector vec : allPoints) {
      pix.vertex(vec.x, vec.y);
    }
    pix.endShape();
  }
  if (drawPoints.size() > 0) {
    pix.stroke(rdpColor);
    pix.strokeWeight(1);
    pix.noFill();
    pix.beginShape();
    for (PVector vec : drawPoints) {
      pix.vertex(vec.x, vec.y);
    }
    pix.endShape();
  }
  // curveDraw for PGraphics
  if (null != bezPoints && bezPoints.size() > 0) {
    pix.pushStyle();
    pix.stroke(curveColor);
    pix.strokeWeight(2);
    pix.noFill();
    if (isDrawWeighted) {
      weightedBezPoints.drawQuick(pix);
    }
    else {
      bezPoints.drawQuick(pix);
    }
    pix.popStyle();
  }
  // brushDraw for PGraphics
  if (null != brushShape) {
    pix.pushStyle();
    pix.fill(brushColor);
    pix.noStroke();
    brushShape.drawQuick(pix);
    pix.popStyle();
  }
  pix.endDraw();
  return pix;
}

/* ------------- SAVE TO PDF FILE ------------- */

public void saveToPDF(String pdfFileName) {
  beginRecord(PDF, pdfFileName);
  RDPDraw();
  curveDraw();
  brushDraw();
  endRecord();
}

/* ------------- SAVE TO SVG FILE ------------- */

// output to an SVG file. In P3, this method throws "textMode(SHAPE) is not supported by this renderer."
// Don't worry, this apparent error does not seem to affect the output. 
public void saveToSVG(String svgFileName) {
  beginRecord(SVG, svgFileName);
  RDPDraw();
  curveDraw();
  brushDraw();
  endRecord();
}
