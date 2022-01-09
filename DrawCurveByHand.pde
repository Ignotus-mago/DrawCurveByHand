// Development version of code example for IgnoCodeLib

// library for video recording
import com.hamoid.*;
// for PDF export
import processing.pdf.*;
// for SVG export
import processing.svg.*;

public ArrayList<PVector> allPoints = new ArrayList<PVector>();
public ArrayList<PVector> drawPoints = new ArrayList<PVector>();
public BezShape bezPoints;
public BezShape weightedBezPoints;
public BezShape brushShape;
float epsilon = 0;
float minEpsilon = 1;
float maxEpsilon = 40;
boolean isDrawWeighted = false;
PVector currentPoint;
float proximity = 12.0;

VideoExport videx;
boolean isRecordingVideo = false;

/**
 * @author Ignotus El Mago :: http://ignot.us :: https://github.com/Ignotus-mago
 */

public void settings() {
  size(1024, 768);
}

public void setup() {
  epsilon = 5.0f;
  currentPoint = new PVector(-1, -1);
  videx = new VideoExport(this);
  printHelpMessage();
}

public void draw() {
  background(255);
  if (!(allPoints.size() > 0)) {
    writeToScreen("Draw something!");
  }
  if (mousePressed) addPoint();
  RDPDraw();
  curveDraw();
  brushDraw();
  if (null != bezPoints) {
    printSizes(false);
  }
  if (isRecordingVideo) {
    videx.saveFrame();
  }
}

public void RDPDraw() {
  if (allPoints.size() > 0) {
    stroke(233, 144, 89, 64);
    strokeWeight(8);
    noFill();
    beginShape();
    for (PVector vec : allPoints) {
      vertex(vec.x, vec.y);
    }
    endShape();
  }
  if (drawPoints.size() > 0) {
    stroke(233, 89, 144);
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
    stroke(55, 199, 246);
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
  if (null != brushShape) {
    pushStyle();
    fill(76, 199, 144, 96);
    noStroke();
    brushShape.drawQuick();
    popStyle();
  }
}

public void keyPressed() {
  boolean mark;
  switch(key) {
    case 'p': 
    case 'P':
    // print sizes to console
      printSizes(true);
      break;
    case '=':
    case '+': 
      // increment epsilon
      if (epsilon < maxEpsilon) epsilon += 1;
      // println("-- epsilon = "+ epsilon);
      mark = bezPoints.isMarked();
      calculateDerivedPoints();
      bezPoints.setIsMarked(mark);
      weightedBezPoints.setIsMarked(mark);
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
      break;
    case 'M':
    case 'm':
      // mark control points on Bezier curve 
      if (null != bezPoints && bezPoints.size() > 0) {
        mark = !bezPoints.isMarked();
        bezPoints.setIsMarked(mark);
        weightedBezPoints.setIsMarked(mark);
      }
      break;
    case 'q':
    case 'Q':
      brushShape = quickBrushShape(drawPoints, 24.0);
      break;
    case 's':
    case 'S':
      saveToPDF();
      println("----- saved display to a PDF file");
      break;
    case 'W':
    case 'w':
      isDrawWeighted = !isDrawWeighted;
      break;
    //case 'C':
    //case 'c':
    //  if (null != bezPoints && bezPoints.size() > 0) {
    //    bezPoints.setIsClosed(!bezPoints.isClosed());
    //    weightedBezPoints.setIsClosed(bezPoints.isClosed());
    //  }
    //  break;
    case 'v':
      isRecordingVideo = !isRecordingVideo;
      /* */
      if (isRecordingVideo) {
        videx.setFrameRate(24);
        videx.startMovie();
      } 
      else {
        videx.endMovie();
      }
      println("----- video recording is "+ isRecordingVideo);
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
  println("P key prints information to the console");
  println("H key prints this help message.");
}

public void mousePressed() {
  allPoints.clear();
  brushShape = null;
  addPoint();
}

public void addPoint() {
  if (mouseX != currentPoint.x || mouseY != currentPoint.y) {
    // a quick way to thin points as you draw:
    // if (manhattanDistance(currentPoint.x, currentPoint.y, mouseX, mouseY) < 4) return;
    currentPoint = new PVector(mouseX, mouseY);
    allPoints.add(currentPoint); 
  }
}

public float manhattanDistance(float x1, float y1, float x2, float y2) {
  return abs(x2 - x1) + abs(y2 - y1);
} 

public void mouseReleased() {
  calculateDerivedPoints();
}

public void calculateDerivedPoints() {
  reducePoints();
  calculateCurve();
  calculateWeightedCurve();
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

/* ------------- SAVE TO PDF FILE ------------- */

public void saveToPDF() {
  PGraphics pdf = createGraphics(width, height, PDF, "draw.pdf");
  pdf.beginDraw();
  pdf.background(255,255,255);
  // RDPDraw for PGraphics
  if (allPoints.size() > 0) {
    pdf.stroke(233, 144, 89, 64);
    pdf.strokeWeight(8);
    pdf.noFill();
    pdf.beginShape();
    for (PVector vec : allPoints) {
      pdf.vertex(vec.x, vec.y);
    }
    pdf.endShape();
  }
  if (drawPoints.size() > 0) {
    pdf.stroke(233, 89, 144);
    pdf.strokeWeight(1);
    pdf.noFill();
    pdf.beginShape();
    for (PVector vec : drawPoints) {
      pdf.vertex(vec.x, vec.y);
    }
    pdf.endShape();
  }
  // curveDraw for PGraphics
  if (null != bezPoints && bezPoints.size() > 0) {
    pdf.pushStyle();
    pdf.stroke(55, 199, 246);
    pdf.strokeWeight(2);
    pdf.noFill();
    if (isDrawWeighted) {
      weightedBezPoints.drawQuick(pdf);
    }
    else {
      bezPoints.drawQuick(pdf);
    }
    pdf.popStyle();
  }
  // brushDraw for PGraphics
  if (null != brushShape) {
    pdf.pushStyle();
    pdf.fill(76, 199, 144, 96);
    pdf.noStroke();
    brushShape.drawQuick(pdf);
    pdf.popStyle();
  }
  pdf.dispose();
  pdf.endDraw();
}
