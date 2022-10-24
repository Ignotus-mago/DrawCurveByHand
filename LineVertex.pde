/**
 * Stores a line vertex consisting of a single point.
 *
 * Adapted from the Processing library IgnoCodeLib, https://processing.org/reference/libraries/
 * The library has disappeared from the Processing contributed libraries page. An issue has been posted to 
 * try to resolve why it disappeared -- possibly because my website has migrated.
 * You can find it at https://paulhertz.net/ignocodelib/ and https://github.com/Ignotus-mago/IgnoCodeLib3
 *
 */
public class LineVertex implements Vertex2DINF {
  /** x-coordinate of anchor point */
  protected float x;
  /** y-coordinate of anchor point */
  protected float y;
  /** path segment type */
  public final static int segmentType = BezShape.LINE_SEGMENT;

  public LineVertex(float x, float y) {
    this.x = x;
    this.y = y;
  }

  public LineVertex() {
    this(0, 0);
  }

  @Override
  public float x() {
    return x;
  }
  public void setX(float newX) {
    x = newX;
  }

  @Override
  public float y() {
    return y;
  }
  public void setY(float newY) {
    y = newY;
  }

  @Override
  public int segmentType() {
    return LineVertex.segmentType;
  }

  @Override
  public float[] coords() {
    float[] knots = new float[2];
    knots[0] = x;
    knots[1] = y;
    return knots;
  }

  @Override
  public LineVertex clone() {
    return new LineVertex(this.x, this.y);
  }

  @Override
  public void draw(PApplet parent) {
    parent.vertex(x, y);
  }

   @Override
   public void draw(PGraphics pg) {
     pg.vertex(x, y);
  }
  
  public void mark() {
    int w = 6;
    pushStyle();
    noStroke();
    fill(160);
    square(x - w/2, y - w/2, w);
    popStyle();
  }

  public void mark(PGraphics pg) {
    int w = 6;
    pg.pushStyle();
    pg.noStroke();
    pg.fill(160);
    pg.square(x - w/2, y - w/2, w);
    pg.popStyle();
  }

}
