# DrawReduceMakeCurves
 
Draw, reduce points, make Bezier curves.

This code reduces the number of points in a line you draw on screen and then creates curves from the reduced points. It uses the Ramer-Douglas-Peucker algorithm. The curves can be either Bezier Splines or Weighted Bezier curves. The weighted curve adjusts the position of the Bezier control points in ratio to the length of the line between the two anchor points. It's not as "curvy" as a spline modeled with Bezier curves, but it may be a better fit to the drawn line. 

New features: 1. create a brush shape from the reduced point set, 2. output display to a PDF (or other PGraphics).

Adapted from Daniel Shiffman's Coding Challenge https://thecodingtrain.com/CodingChallenges/152-rdp-algorithm.html and from various other sources mentioned in comments, including my Processing library IgnoCodeLib. 
