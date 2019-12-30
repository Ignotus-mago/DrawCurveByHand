// library for video recording
import com.hamoid.*;
// for PDF export
import processing.pdf.*;

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
    pdf.trokeWeight(1);
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

/* ------------- BEGIN CODE FROM CODING TRAIN ------------- */
/* see Coding Challenge on RDP Line Simplification at 
 * https://thecodingtrain.com/CodingChallenges/152-rdp-algorithm.html 
 */

void rdp(int startIndex, int endIndex, ArrayList<PVector> allPoints, ArrayList<PVector> rdpPoints) {
  int nextIndex = findFurthest(allPoints, startIndex, endIndex);
  if (nextIndex > 0) {
    if (startIndex != nextIndex) {
      rdp(startIndex, nextIndex, allPoints, rdpPoints);
    }
    rdpPoints.add(allPoints.get(nextIndex));
    if (endIndex != nextIndex) {
      rdp(nextIndex, endIndex, allPoints, rdpPoints);
    }
  }
}

int findFurthest(ArrayList<PVector> points, int a, int b) {
  float recordDistance = -1;
  PVector start = points.get(a);
  PVector end = points.get(b);
  int furthestIndex = -1;
  for (int i = a+1; i < b; i++) {
    PVector currentPoint = points.get(i);
    float d = lineDist(currentPoint, start, end);
    if (d > recordDistance) {
      recordDistance = d;
      furthestIndex = i;
    }
  }
  if (recordDistance > epsilon) {
    return furthestIndex;
  } else {
    return -1;
  }
}

float lineDist(PVector c, PVector a, PVector b) {
  PVector norm = scalarProjection(c, a, b);
  return PVector.dist(c, norm);
}

PVector scalarProjection(PVector p, PVector a, PVector b) {
  PVector ap = PVector.sub(p, a);
  PVector ab = PVector.sub(b, a);
  ab.normalize(); // Normalize the line
  ab.mult(ap.dot(ab));
  PVector normalPoint = PVector.add(a, ab);
  return normalPoint;
}

/* ------------- END CODE FROM CODING TRAIN ------------- */

/* ------------- SOME CODE PORTED FROM http://www.particleincell.com/2012/bezier-splines/ ------------- */
/* 
 * There's a handy mathematical explanation of the creation of a Bezier spline out at 
 * http://www.particleincell.com/2012/bezier-splines/ 
 * with some details at https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm
 *
 */

public void calculateCurve() {
  int n = drawPoints.size();
  float[] xCoords = new float[n];
  float[] yCoords = new float[n];
  int i = 0;
  for (PVector vec : drawPoints) {
      xCoords[i] = vec.x;
      yCoords[i] = vec.y;
      i++;
  }
  float[] xp1 = new float[n-1];
  float[] xp2 = new float[n-1];
  computeControlPoints(xCoords, xp1, xp2);
  float[] yp1 = new float[n-1];
  float[] yp2 = new float[n-1];
  computeControlPoints(yCoords, yp1, yp2);
  bezPoints = new BezShape(this,drawPoints.get(0).x, drawPoints.get(0).y, false);
  for (int k = 0; k < n - 1; k++) {
    bezPoints.append(xp1[k], yp1[k], xp2[k], yp2[k], drawPoints.get(k+1).x, drawPoints.get(k+1).y);
  }
}

public BezShape calculateCurve(ArrayList<PVector> framePoints) {
  int n = framePoints.size();
  float[] xCoords = new float[n];
  float[] yCoords = new float[n];
  int i = 0;
  for (PVector vec : framePoints) {
      xCoords[i] = vec.x;
      yCoords[i] = vec.y;
      i++;
  }
  float[] xp1 = new float[n-1];
  float[] xp2 = new float[n-1];
  computeControlPoints(xCoords, xp1, xp2);
  float[] yp1 = new float[n-1];
  float[] yp2 = new float[n-1];
  computeControlPoints(yCoords, yp1, yp2);
  BezShape bez = new BezShape(this,framePoints.get(0).x, framePoints.get(0).y, false);
  for (int k = 0; k < n - 1; k++) {
    bez.append(xp1[k], yp1[k], xp2[k], yp2[k], framePoints.get(k+1).x, framePoints.get(k+1).y);
  }
  return bez;
}

public void computeControlPoints(float[] K, float[] p1, float[] p2) {
  int n = K.length - 1;
  if (n <= 0) return;

  /* rhs vector */
  float[] a = new float[n];
  float[] b = new float[n];
  float[] c = new float[n];
  float[] r = new float[n];
  
  /* leftmost segment */
  a[0] = 0;
  b[0] = 2;
  c[0] = 1;
  r[0] = K[0] + 2 * K[1];
  
  /* internal segments */
  for (int i = 1; i < n - 1; i++) {
    a[i] = 1;
    b[i] = 4;
    c[i] = 1;
    r[i] = 4 * K[i] + 2 * K[i+1];
  }
      
  /* rightmost segment */
  a[n-1] = 2;
  b[n-1] = 7;
  c[n-1] = 0;
  r[n-1] = 8 * K[n-1] + K[n];
  
  /* solves Ax = b with the Thomas algorithm, details at https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm */
  for (int i = 1; i < n; i++) {
    float m = a[i] / b[i-1];
    b[i] = b[i] - m * c[i - 1];
    r[i] = r[i] - m * r[i-1];
  }
 
  p1[n-1] = r[n-1] / b[n-1];
  for (int i = n - 2; i >= 0; --i) {
    p1[i] = (r[i] - c[i] * p1[i+1]) / b[i];
  }
    
  /* we have p1, now compute p2 */
  for (int i = 0;i  <n-1; i++) {
    p2[i] = 2 * K[i+1] - p1[i+1];
  }
  
  p2[n-1] = 0.5f * (K[n]+p1[n-1]);
}

/* ------------- END CODE FROM http://www.particleincell.com/2012/bezier-splines/ ------------- */

/* ------------- code for weighted Bezier path ------------- */

// the weighted curve adjusts the position of the control points  
// in ratio to the length of the line between the two anchor points
public void calculateWeightedCurve() {
  weightedBezPoints = bezPoints.clone();
  float weight = BezShape.LAMBDA;
  ListIterator<Vertex2DINF> it = weightedBezPoints.curveIterator();
  float x1, y1, x2, y2;
  x1 = weightedBezPoints.startVertex().x();
  y1 = weightedBezPoints.startVertex().y();
  int i = 0;
  BezVertex bz;
  while (it.hasNext()) {
    Vertex2DINF bez = it.next();
    if (bez.segmentType() == BezShape.CURVE_SEGMENT) {
      bz = (BezVertex) bez;
      // lines from anchors to control point:
      // (x1, y1), (bz.cx1(), bz.cy1())
      // (bz.x(), bz.y()), (bz.cx2(), bz.cy2())
      // distance between anchor points
      float d = dist(x1, y1, bz.x(), bz.y());
      PVector cxy1 = weightedControlVec(x1, y1, bz.cx1(), bz.cy1(), weight, d);
      bz.setCx1(cxy1.x);
      bz.setCy1(cxy1.y);
      PVector cxy2 = weightedControlVec(bz.x(), bz.y(), bz.cx2(), bz.cy2(), weight, d);
      bz.setCx2(cxy2.x);
      bz.setCy2(cxy2.y);
      // store the first anchor point for the next iteration
      x1 = bz.x();
      y1 = bz.y();
    }
    else if (bez.segmentType() == BezShape.LINE_SEGMENT) {
      x1 = bez.x();
      y1 = bez.y();
    }
    else {
      // error! should never arrive here
    }
    i++;
  }
}

// the weighted curve adjusts the position of the control points  
// in ratio to the length of the line between the two anchor points
public void calculateWeightedCurve(BezShape weightedBezPoints) {
  float weight = (float) BezShape.LAMBDA;
  ListIterator<Vertex2DINF> it = weightedBezPoints.curveIterator();
  float x1 = weightedBezPoints.startVertex().x();
  float y1 = weightedBezPoints.startVertex().y();
  BezVertex bz;
  while (it.hasNext()) {
    Vertex2DINF bez = it.next();
    if (bez.segmentType() == BezShape.CURVE_SEGMENT) {
      bz = (BezVertex) bez;
      // lines from anchors to control point:
      // (x1, y1), (bz.cx1(), bz.cy1())
      // (bz.x(), bz.y()), (bz.cx2(), bz.cy2())
      // distance between anchor points
      float d = dist(x1, y1, bz.x(), bz.y());
      PVector cxy1 = weightedControlVec(x1, y1, bz.cx1(), bz.cy1(), weight, d);
      bz.setCx1(cxy1.x);
      bz.setCy1(cxy1.y);
      PVector cxy2 = weightedControlVec(bz.x(), bz.y(), bz.cx2(), bz.cy2(), weight, d);
      bz.setCx2(cxy2.x);
      bz.setCy2(cxy2.y);
      // store the first anchor point for the next iteration
      x1 = bz.x();
      y1 = bz.y();
    }
    else if (bez.segmentType() == BezShape.LINE_SEGMENT) {
      x1 = bez.x();
      y1 = bez.y();
    }
    else {
      // error! should never arrive here
    }
  }
}

public PVector weightedControlVec(float ax, float ay, float cx, float cy, float w, float d) {
  // divide the weighted distance between anchor points by the distance from anchor point to control point
  float t = w * d * 1/(dist(ax, ay, cx, cy));
  // plug into parametric line equation
  float x = ax + (cx - ax) * t;
  float y = ay + (cy - ay) * t;
  return new PVector(x, y);
}


// ------------- CODE FOR BRUSH SHAPE ------------- //

// simulate a brushstroke as a vector shape
public BezShape quickBrushShape(ArrayList<PVector> points, float brushWidth) {
  ArrayList<PVector> pointsLeft = new ArrayList<PVector>();
  ArrayList<PVector> pointsRight = new ArrayList<PVector>();
  if (!(points.size() > 0)) return null;
  // handle the first point
  PVector v1 = points.get(0);
  pointsLeft.add(v1.copy());
  pointsRight.add(v1.copy());
  for (int i = 1; i < points.size() - 1; i++) {
    PVector v2 = points.get(i);
    PVector v3 = points.get(i+1);
    // get the normals to the lines (v1, v2) and (v2, v3) at the point v2
    PVector norm1 = normalAtPoint(v1, v2, 1, 1);
    PVector norm2 = normalAtPoint(v2, v3, 0, 1);
    // add the normals together and take the average
    norm1.add(norm2).mult(0.5);
    // normalize (probably not necessary, eh?)
    norm1.sub(v2).normalize();
    // add points on either side of v2 at distance brushWidth/2
    pointsLeft.add(scaledNormalAtPoint(v2, norm1, -brushWidth/2));
    pointsRight.add(scaledNormalAtPoint(v2, norm1, brushWidth/2));
    v1 = v2;
  }
  // handle the last point
  v1 = points.get(points.size() -1);
  pointsLeft.add(v1.copy());
  pointsRight.add(v1.copy());
  // reverse one of the arrays
  reverseArray(pointsLeft, 0, pointsLeft.size() - 1);
  // generate Bezier splines
  BezShape bezLeft = calculateCurve(pointsLeft);
  BezShape bezRight = calculateCurve(pointsRight);
  if (isDrawWeighted) {
    calculateWeightedCurve(bezLeft);
    calculateWeightedCurve(bezRight);
  }
  // append points in bezLeft to bezRight
  ListIterator<Vertex2DINF> it = bezLeft.curveIterator();
  while (it.hasNext()) {
    bezRight.append(it.next());
  }
  bezRight.setIsClosed(true);
  // return the brushstroke shape in bezRight
  return bezRight;
}

// returns a normal to a line at a point on the line at parametric distance u, normalized if d = 1
public PVector normalAtPoint(PVector a1, PVector a2, float u, float d) {
  float ax1 = a1.x;
  float ay1 = a1.y;
  float ax2 = a2.x;
  float ay2 = a2.y;
  // determine the proportions of change on x and y axes for the line segment 
  float f = (ax2 - ax1);
  float g = (ay2 - ay1);
  // get the point on the line segment at u
  float pux = ax1 + f * u;
  float puy = ay1 + g * u;
  // prepare to calculate normalized parametric equations
  float root = sqrt(f*f + g*g);
  float inv = 1/root;
  // plug distance d into normalized parametric equations for normal to line segment
  float x = pux - g * inv * d;
  float y = puy + f * inv * d;
  return new PVector(x, y);
}

// we're using this to scale normalizd normals at a determined point, but the "normal" could be any vector
// PVector anchor   the point from which the normal extends
// PVector normal   a normalized vector
// float   d        distance from anchor to the returned vector
public PVector scaledNormalAtPoint(PVector anchor, PVector normal, float d) {
  return new PVector(anchor.x + normal.x * d, anchor.y + normal.y * d);
}

public void reverseArray(ArrayList arr, int l, int r) {
  Object temp;
  while (l < r) {
    temp = arr.get(l);
    arr.set(l, arr.get(r));
    arr.set(r, temp);
    l++;
    r--;
  }
}
