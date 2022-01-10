/**
 * Interface for line and curve vertices. Classes that implement this interface must implement
 * all the methods listed below. 
 *
 * Adapted from the Processing library IgnoCodeLib, https://processing.org/reference/libraries/
 * The library has disappeared from the Processing contributed libraries page. An issue has been posted to 
 * try to resolve why it disappeared -- possibly because my website has migrated.
 * You can find it at https://paulhertz.net/ignocodelib/ and https://github.com/Ignotus-mago/IgnoCodeLib3
 *
 */
public interface Vertex2DINF {
  /**
   * @return x-coordinate as a float
   */
  public float x();
  /**
   * @return y-coordinate as a float
   */
  public float y();
  /**
   * @return type of segment, either BezShape.LINE_SEGMENT or BezShape.CURVE_SEGMENT
   */
  public int segmentType();
  /**
   * @return coordinates as an array of float
   */
  public float[] coords();
  /**
   * @return a deep copy of a Vertex2DINF
   */
  public Vertex2DINF clone();
  /** 
   * Draws a path to the display. It is only valid to call this within a 
   * Processing beginShape/endShape pair where  an initial 
   * vertex has been set with a call to vertex(). 
   * @param parent   the PApplet that handles drawing
   */
  public void draw(PApplet parent);
  /**
   * Draws a path to an offscreen buffer. It is only valid to call this within a 
   * Processing beginShape/endShape pair where  an initial 
   * vertex has been set with a call to vertex(). 
   * @param pg   a PGraphics instance
   */
  public void draw(PGraphics pg);
  /**
   * Draws marks at vertices and control points.
   */
  public void mark();
}
