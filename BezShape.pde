import java.util.ListIterator;

/**
 * Class to store a path composed of lines and Bezier curves.
 * Adapted from the Processing library IgnoCodeLib, https://processing.org/reference/libraries/
 */
public class BezShape {
  /** PApplet for callbacks to Processing drawing environment, etc. Used by constructors */
  protected PApplet parent;
  /** initial x-coordinate */
  protected float x;
  /** initial y-coordinate */
  protected float y;
  /** list of bezier vertices */
  private ArrayList<Vertex2DINF> curves;
  /** flags if shape is closed or not */
  protected boolean isClosed = false;
  /** flags we shoud draw control points and vertices */
  protected boolean isMarked = false;
  /** flag for line segment type, associated with LineVertex */
  public final static int LINE_SEGMENT = 1;
  /** flag for curve segment type, associated with BezVertex */
  public final static int CURVE_SEGMENT = 2;
  /** 
   *  KAPPA = (distance between Bezier anchor and its associated control point) / (circle radius)
   *  when a circle is divided into 4 sectors of 90 degrees.
   *  kappa = 4 * (√2 - 1) / 3
   *  see <a href="http://www.whizkidtech.redprince.net/bezier/circle/kappa/">http://www.whizkidtech.redprince.net/bezier/circle/kappa/</a>
   */
  public final static double KAPPA = 0.5522847498;
  /**
   * LAMBDA = KAPPA/√2, a value for weighting Bezier splines based on the length of line segments between anchor points
   * derived from the ratio of the chord of a quarter circle to KAPPA, LAMBDA = KAPPA * (1/√2)
   *
   */
  public final static float LAMBDA = 0.39052429175;


  /**
   * Creates a BezShape with initial point x,y, closed or open according to the value of isClosed.
   * Fill, stroke, and weight of shapes are set from their values in the Processing environment.
   * The Processing transformation matrix (set by calls to rotate, translate and scale) is saved
   * to the instance variable <code>ctm</code>, but no transform is performed.  Note that drawing
   * is affected by the current Processing transform.
   *  
   * @param parent   PApplet used for calls to the Processing environment, notably for drawing
   * @param x    x-coordinate of initial point
   * @param y    y-coordinate of initial point
   * @param isClosed   true if shape is closed, false if it is open
   */
  public BezShape(PApplet parent, float x, float y, boolean isClosed) {
    this.parent = parent;
    this.setStartPoint(x, y);
    this.curves = new ArrayList<Vertex2DINF>();
    this.isClosed = isClosed;
  }
  
  
  /**
   * Returns the x-coordinate of the initial point of the geometry of this shape.
   * @return   x-coordinate of initial vertex
   */
  public float x() {
    return x;
  }
  /**
   * Sets the x-coordinate of the initial point of the geometry of this shape.
   * @param newX   new x-coordinate of initial vertex
   */
  public void setX(float newX) {
    x = newX;
  }


  /**
   * Returns the y-coordinate of the initial point of the geometry of this shape.
   * @return   y-coordinate of initial vertex
   */
  public float y() {
    return y;
  }
  /**
   * Sets the y-coordinate of the initial point of the geometry of this shape.
   * @param newY   new y-coordinate of initial vertex
   */
  public void setY(float newY) {
    y = newY;
  }


  /**
   * @return   a LineVertex with start point coordinates of this shape 
   */
  public LineVertex startVertex() {
    return new LineVertex(this.x, this.y);
  }
  
  /**
   * Sets a new initial vertex for this BezShape.
   * @param newX
   * @param newY
   */
  public void setStartPoint(float newX, float newY) {
    this.setX(newX); 
    this.setY(newY); 
  }


  /**
   * @return  {@code true} if this shape is closed, {@code false} otherwise.
   */
  public boolean isClosed() {
    return isClosed;
  }
  /**
   * @param newIsClosed   {@code true} if this shape is closed, {@code false} otherwise
   */
  public void setIsClosed(boolean newIsClosed) {
    isClosed = newIsClosed;
  }
  
  /**
   * @return  {@code true} if this shape is marked with vertices and control points, {@code false} otherwise.
   */
  public boolean isMarked() {
    return isMarked;
  }
  /**
   * @param newIsMarked   {@code true} if this shape is marked with vertices and control points, {@code false} otherwise
   */
  public void setIsMarked(boolean newIsMarked) {
    isMarked = newIsMarked;
  }


  /*-------------------------------------------------------------------------------------------*/
  /*                                                                                           */
  /* METHODS TO APPEND POINTS AND ITERATE THROUGH THIS SHAPE                                   */ 
  /*                                                                                           */
  /*-------------------------------------------------------------------------------------------*/

  
  /**
   * Appends a Vertex2DINF to this BezShape
   * @param vt   a Vertex2DINF (line segment or curve segment)
   */
  public void append(Vertex2DINF vt) {
    curves.add(vt);
  }

  /**
   * Appends a BezVertex (cubic B•zier segment) to this BezShape.
   * @param cx1   x-coordinate of first control point 
   * @param cy1   y-coordinate of first control point
   * @param cx2   x-coordinate of second control point
   * @param cy2   y-coordinate of second control point
   * @param x     x-coordinate of terminal anchor point
   * @param y     y-coordinate of terminal anchor point
   */
  public void append(float cx1, float cy1, float cx2, float cy2, float x, float y) {
    this.append(new BezVertex(cx1, cy1, cx2, cy2, x, y));
  }


  /**
   * Appends a LineVertex (line segment) to this BezShape.
   * @param x
   * @param y
   */
  public void append(float x, float y) {
    this.append(new LineVertex(x, y));
  }
  
  /**
   * Returns an iterator over the geometry of this shape. Preferred method for accessing geometry.
   * Does not include the initial point, call x() and y() or  startVertex() for that. 
   * @return an iterator over the Vertex2DINF segments that comprise the geometry of this shape
   */
  public ListIterator <Vertex2DINF> curveIterator() {
    return curves.listIterator();
  }
  
  /**
   * Returns size of number of vertices (BezVertex and LineVertex) in curves.
   * @return size of curves ArrayList.
   */
  public int size() {
    return curves.size();
  }
  
  /**
   * Returns number of points (anchor points and control points) in curves.
   * Dosn't count the start point.
   * @return total numbr of points in curves ArrayList data.
   */
  public int pointCount() {
    int count = 0;
    ListIterator<Vertex2DINF> it = curveIterator();
    while (it.hasNext()) {
      Vertex2DINF bez = it.next();
      if (bez.segmentType() == CURVE_SEGMENT) {
        count += 3;
      }
      else if (bez.segmentType() == LINE_SEGMENT) {
        count += 1;
      }
      else {
        // error! should never arrive here
      }
    }
    return count;
  }
  
  /**
   * Creates a deep copy of this BezShape.
   * @see java.lang.Object#clone
   */
  public BezShape clone() {
    BezShape copyThis = new BezShape(parent, this.x, this.y, false);
    copyThis.setIsClosed(this.isClosed());
    ListIterator<Vertex2DINF> it = curveIterator();
    while (it.hasNext()) {
      Vertex2DINF bez = it.next();
      copyThis.append(bez.clone());
    }
    return copyThis;
  }


  /*-------------------------------------------------------------------------------------------*/
  /*                                                                                           */
  /* METHODS TO DRAW TO DISPLAY                                                                */ 
  /*                                                                                           */
  /*-------------------------------------------------------------------------------------------*/


  /** 
   * Draws this shape to the display. Calls beginShape and endShape on its own.
   * Uses current fill, stroke and weight from Processing environment.
   */
  public void drawQuick() {
    parent.beginShape();
    // equivalent to startPoint.draw(this.parent);
    parent.vertex(this.x, this.y);
    ListIterator<Vertex2DINF> it = curveIterator();
    int i = 0;
    while (it.hasNext()) {
      Vertex2DINF bez = it.next();
      bez.draw(parent); 
      if (isMarked) {
         if (bez.segmentType() == CURVE_SEGMENT) {
          pushStyle();
          noFill();
          stroke(192);
          strokeWeight(1);
          BezVertex bz = (BezVertex)bez;
          if (i > 0) {
            line(curves.get(i-1).x(), curves.get(i-1).y(), bz.cx1(), bz.cy1());
            line(bz.x(), bz.y(), bz.cx2(), bz.cy2());
          }
          else {
            int w = 6;
            pushStyle();
            noStroke();
            fill(160);
            square(x - w/2, y - w/2, w);
            popStyle();
            line(x, y, bz.cx1(), bz.cy1());
            line(bz.x(), bz.y(), bz.cx2(), bz.cy2());
          }
          popStyle();
        }
        bez.mark();
      }
      i++;
    }
    if (isClosed()) {
      parent.endShape(PApplet.CLOSE);
    }
    else {
      parent.endShape();
    }
  }
  
  /** 
   * Draws this shape to a PGraphics passed as an argument. Calls beginShape and endShape on its own.
   * Uses current fill, stroke and weight from Processing environment.
   */
  public void drawQuick(PGraphics pg) {
    pg.beginShape();
    // equivalent to startPoint.draw(this.parent);
    pg.vertex(this.x, this.y);
    ListIterator<Vertex2DINF> it = curveIterator();
    int i = 0;
    while (it.hasNext()) {
      Vertex2DINF bez = it.next();
      bez.draw(pg); 
      if (isMarked) {
         if (bez.segmentType() == CURVE_SEGMENT) {
          pushStyle();
          noFill();
          stroke(192);
          strokeWeight(1);
          BezVertex bz = (BezVertex)bez;
          if (i > 0) {
            line(curves.get(i-1).x(), curves.get(i-1).y(), bz.cx1(), bz.cy1());
            line(bz.x(), bz.y(), bz.cx2(), bz.cy2());
          }
          else {
            int w = 6;
            pushStyle();
            noStroke();
            fill(160);
            square(x - w/2, y - w/2, w);
            popStyle();
            line(x, y, bz.cx1(), bz.cy1());
            line(bz.x(), bz.y(), bz.cx2(), bz.cy2());
          }
          popStyle();
        }
        bez.mark();
      }
      i++;
    }
    if (isClosed()) {
      pg.endShape(PApplet.CLOSE);
    }
    else {
      pg.endShape();
    }
  }


}
