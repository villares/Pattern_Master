// PATTERN MASTER
// Golan Levin, golan@flong.com
// Spring 2006 - January 2013


// TO DO
// Ogee Curves
// http://engineeringtraining.tpub.com/14069/css/14069_150.htm
// http://en.wikipedia.org/wiki/Generalised_logistic_function Richard's Curve
// http://en.wikipedia.org/wiki/Probit_function
// http://mathworld.wolfram.com/HeavisideStepFunction.html
//
// RESTORE MODE-SPECIFIC GRAPHICS!!!

// Imports for introspection, so we know the functions' arguments. 
import java.lang.*;
import java.lang.reflect.Method;
import java.lang.reflect.Type;

// Imports for PDF, to save a vector graphic of the function.
import processing.pdf.*;
boolean doSavePDF=false;

boolean bDrawProbe = true;
boolean bDrawGrayScale = true;
boolean bDrawNoiseHistories = true; 
boolean bDrawModeSpecificGraphics = true;
boolean bDrawAnimatingRadiusCircle = true;

color boundingBoxStrokeColor = color(180); 

//-----------------------------------------------------
float xscale = 300;
float yscale = 300;
float bandTh  = 60;
float margin0 = 10;
float margin1 = 5;
float margin2 = 90;
float xoffset = margin0 + bandTh + margin1;
float yoffset = margin0 + bandTh + margin1;

float param_a = 0.25;
float param_b = 0.75;
float param_c = 0.75;
float param_d = 0.25;
int   param_n = 3;

float probe_x = 0.5;
float probe_y = 0.5;
float animationConstant = 1000.0;

boolean useParameterA = true;
boolean useParameterB = true;
boolean useParameterC = true;
boolean useParameterD = true;
boolean useParameterN = true;

boolean visited = false;
boolean bClickedInGraph = false;
String functionName = "";

float noiseRawHistory[]; 
float noiseFilteredHistory[];
float sineRawHistory[]; 
float sineFilteredHistory[];

int FUNCTIONMODE = 0;
int NFUNCTIONS = 101; //!!!!!!!!!!!!!!!!!!!!!!!!!!

//-----------------------------------------------------
void keyPressed() {
  if (key == CODED) { 
    if ((keyCode == UP) || (keyCode == RIGHT)) { 
      FUNCTIONMODE = (FUNCTIONMODE+1)%NFUNCTIONS;
    } 
    else if ((keyCode == DOWN) || (keyCode == LEFT)) { 
      FUNCTIONMODE = (FUNCTIONMODE-1+NFUNCTIONS)%NFUNCTIONS;
    }
  } 
  if (key=='P') {
    doSavePDF = true;
  }
}

//-----------------------------------------------------
void setup() {
  int scrW = (int)(margin0 + bandTh + margin1 + xscale + margin0);
  int scrH = (int)(margin0 + bandTh + margin1 + yscale + margin2 + bandTh + margin0 + bandTh + margin1);
  size (scrW, scrH);// OPENGL);
  // println("App dimensions: " + scrW + " x " + scrH);

  noiseRawHistory      = new float[(int)xscale];
  noiseFilteredHistory = new float[(int)xscale];
  sineRawHistory       = new float[(int)xscale];
  sineFilteredHistory  = new float[(int)xscale];
  for (int i=0; i<xscale; i++) {
    noiseFilteredHistory[i] = noiseRawHistory[i] = 0.5;
    sineFilteredHistory[i]  = sineRawHistory[i]  = 0.5;
  }

  introspect();
}

//-----------------------------------------------------
void mouseMoved() {
  visited = true;
}

int whichButton = 0; 
void mousePressed() {
  bClickedInGraph = false;
  if ((mouseX >= xoffset) && (mouseX <= (xoffset + xscale)) && 
    (mouseY >= yoffset) && (mouseY <= (yoffset + yscale))) {

    if (mouseButton == LEFT) {
      whichButton = 1;
    } 
    else if (mouseButton == RIGHT) {
      whichButton = 2;
    } 
    else {
      whichButton = 0;
    }

    bClickedInGraph = true;
  }
}

void mouseReleased() {
  whichButton = 0;
}



//====================================================
void drawPDF() {

  String pdfFilename = functionName;
  if (useParameterA) { 
    pdfFilename += "_a=" + nf(param_a, 1, 2);
  }
  if (useParameterB) { 
    pdfFilename += "_b=" + nf(param_b, 1, 2);
  }
  if (useParameterC) { 
    pdfFilename += "_c=" + nf(param_c, 1, 2);
  }
  if (useParameterD) { 
    pdfFilename += "_d=" + nf(param_d, 1, 2);
  }
  if (useParameterN) { 
    pdfFilename += "_n=" + nf(param_n, 1, 2);
  }
  pdfFilename += ".pdf";


  beginRecord(PDF, pdfFilename); 

  strokeJoin(MITER);
  strokeCap(ROUND);
  strokeWeight(1.0);
  noFill();
  stroke(0);
  rect(0, 0, width, height);

  background (255, 255, 255);
  stroke(128);
  fill(255);
  rect(xoffset, yoffset, xscale, yscale);
  drawModeSpecificGraphics();

  // draw the function's curve
  float x = 0;
  float y = 1 - function (x, param_a, param_b, param_c, param_d, param_n);
  float qx = xoffset + xscale * x;
  float qy = yoffset + yscale * y;
  float px = qx;
  float  py = qy;
  stroke(0);
  noFill();
  beginShape();
  vertex(px, py);
  for (float i=0; i<=xscale; i+=0.1) {
    x = (float)i/xscale;
    y = 1 - function (x, param_a, param_b, param_c, param_d, param_n);
    px = xoffset + (xscale * x);
    py = yoffset + (yscale * y);
    //line (qx, qy, px, py);
    vertex(px, py);
    qx = px;
    qy = py;
  }
  endShape();

  //---------------------------
  // draw the function's gray levels
  py = yoffset-(bandTh+margin1);
  qy = yoffset-margin1;
  beginShape(QUAD_STRIP);
  for (float j=0; j<=xscale; j++) {
    float j1 = j; 
    float x1 = j1/(float)xscale;
    float y1 = function (1-x1, param_a, param_b, param_c, param_d, param_n);
    float g1 = 255.0 * y1;
    float px1 = xoffset + xscale - j1;

    noStroke();
    fill(g1, g1, g1);
    vertex(px1, py); 
    vertex(px1, qy);
  }
  endShape();
  noFill();
  stroke(128);
  rect(xoffset, yoffset-(bandTh+margin1), xscale, bandTh);

  endRecord();
  strokeWeight (1); 
  doSavePDF=false;
}



//-----------------------------------------------------
void draw() {

  updateParameters(); 

  if (doSavePDF) {
    drawPDF();
    doSavePDF = false;
  }  
  else {

    background (255);

    //---------------------------
    // Draw the animating probe
    if (bDrawProbe) {
      drawAnimatingProbe();
    }
    //---------------------------
    // Draw the animating circle 
    if (bDrawAnimatingRadiusCircle) {
      drawAnimatingRadiusCircle();
    }
    //---------------------------
    // Extra mode-specific graphics for Bezier, etc.
    if (bDrawModeSpecificGraphics) {
      drawModeSpecificGraphics();
    }
    //---------------------------
    // Draw the function's curve
    drawMainFunctionCurve();

    //---------------------------
    // Draw the function's gray levels
    if (bDrawGrayScale) {
      drawGrayLevels();
    }
    //---------------------------
    // Draw a noise signal, and a filtered version.
    if (bDrawNoiseHistories) {
      drawNoiseHistories();
    }
    //---------------------------
    // Draw labels
    drawLabels();
  }
}

//-----------------------------------------------------
void updateParameters() {

  float acf = animationConstant;
  probe_x = abs(millis()%(2*(int)acf) - acf)/acf;

  if (mousePressed && bClickedInGraph) {
    if (visited) {
      if (whichButton == 1) {
        param_a =   (float)(mouseX - xoffset)/xscale;
        param_b = 1-(float)(mouseY - yoffset)/yscale;
        param_a = constrain(param_a, 0, 1); 
        param_b = constrain(param_b, 0, 1);
      } 
      else if (whichButton == 2) {
        param_c =   (float)(mouseX - xoffset)/xscale;
        param_d = 1-(float)(mouseY - yoffset)/yscale;
        param_c = constrain(param_c, 0, 1); 
        param_d = constrain(param_d, 0, 1);
      }
    }
  }
}


//-----------------------------------------------------
void drawMainFunctionCurve() {
  float x, y;
  float px, py;
  float qx, qy;

  noFill(); 
  stroke(boundingBoxStrokeColor);
  rect(xoffset, yoffset, xscale, yscale);

  x = 0;
  y = 1 - function (x, param_a, param_b, param_c, param_d, param_n);
  qx = xoffset + xscale * x;
  qy = yoffset + yscale * y;
  px = qx;
  py = qy;

  for (int i=0; i<=xscale; i++) {
    x = (float)i/xscale;
    y = 1 - function (x, param_a, param_b, param_c, param_d, param_n);

    stroke(0);
    if ((y < 0) || (y > 1)) {
      stroke(200);
    } 

    px = xoffset + round(xscale * x);
    py = yoffset + round(yscale * y);
    line (qx, qy, px, py);
    qx = px;
    qy = py;
  }
}


//-----------------------------------------------------
void drawAnimatingProbe() {

  // inspired by @marcinignac & @soulwire 
  // from http://codepen.io/vorg/full/Aqyre 

    float x = constrain(probe_x, 0, 1);
  float y = probe_y = 1 - function (x, param_a, param_b, param_c, param_d, param_n);
  float px = xoffset + round(xscale * x);
  float py = yoffset + round(yscale * y);
  float qy = yoffset + yscale;

  // draw bounding box
  noFill();
  stroke(boundingBoxStrokeColor);
  rect(margin0, yoffset, bandTh, yscale);

  // draw probe element
  stroke(255, 128, 128);
  line (px, qy, px, py);
  stroke(128, 128, 255);
  line (px, py, xoffset, py);
  fill(0);
  noStroke();
  ellipseMode (CENTER);
  ellipse(margin0+bandTh/2.0, py, 11, 11);
}


//-----------------------------------------------------
void drawAnimatingRadiusCircle() {
  // Draw a circle whose radius is linked to the function value. 
  // Inspired by @marcinignac & @soulwire: http://codepen.io/vorg/full/Aqyre   

    float blooperCx = margin0+bandTh/2.0;
  float blooperCy = margin0+bandTh/2.0;
  float val = function (probe_x, param_a, param_b, param_c, param_d, param_n);
  float blooperR = bandTh * val;

  smooth(); 
  float grayBg = map(val, 0, 1, 220, 255);
  fill (grayBg); 
  ellipse (blooperCx, blooperCy, bandTh, bandTh);

  noStroke();
  fill (160);
  float grayFg = map(val, 0, 1, 127, 160);
  fill (grayFg);
  ellipse (blooperCx, blooperCy, blooperR, blooperR);
}

//-----------------------------------------------------
void drawGrayLevels() {

  smooth();
  for (int j=0; j<=xscale; j++) {
    float x = (float)j / (float)xscale;
    float y = function (1.0-x, param_a, param_b, param_c, param_d, param_n);
    float g = 255.0 * y;

    float py = yoffset-(bandTh+margin1);
    float qy = yoffset-margin1;
    float px = xoffset + xscale - j;

    stroke(g, g, g);
    line (px, py, px, qy);
  }

  // draw the bounding box
  noFill();
  stroke(boundingBoxStrokeColor);
  rect(xoffset, yoffset-(bandTh+margin1), xscale, bandTh);
}


//-----------------------------------------------------
void drawNoiseHistories() {

  float nhy = margin0 + bandTh + margin1 + yscale + margin2;
  float shy = margin0 + bandTh + margin1 + yscale + margin2 + bandTh + margin1;
  int nData = (int)xscale; 

  // update noise history
  for (int i=0; i<(nData-1); i++) {
    noiseRawHistory[i] = noiseRawHistory[i+1];
  }
  noiseRawHistory[nData-1] = noise(millis()/ (nData/2.0)); 

  // update sine history
  for (int i=0; i<(nData-1); i++) {
    sineRawHistory[i] = sineRawHistory[i+1];
  }
  sineRawHistory[nData-1] = 0.5 + (0.45 * cos(PI * millis()/animationConstant));   


  // draw bounding rectangles
  noFill(); 
  stroke(boundingBoxStrokeColor);
  rect (xoffset, nhy, xscale, bandTh);
  rect (xoffset, shy, xscale, bandTh);

  // draw raw noise history
  noFill(); 
  stroke(180); 
  beginShape(); 
  for (int i=0; i<nData; i++) {
    float x = xoffset + i;
    float valRaw = 1.0 - constrain(noiseRawHistory[i], 0, 1);
    float y = nhy + bandTh * valRaw;
    vertex(x, y);
  }
  endShape(); 

  // draw filtered noise history
  noFill(); 
  stroke(0); 
  beginShape(); 
  for (int i=0; i<nData; i++) {
    float x = xoffset + i;
    float valRaw = noiseRawHistory[i];
    float valFiltered = 1.0 - function (valRaw, param_a, param_b, param_c, param_d, param_n);
    valFiltered = constrain(valFiltered, 0, 1); 
    float y = nhy + bandTh * valFiltered;
    vertex(x, y);
  }
  endShape();

  //----------------
  // draw raw sine history
  noFill(); 
  stroke(180); 
  beginShape(); 
  for (int i=0; i<nData; i++) {
    float x = xoffset + i;
    float valRaw = 1.0 - constrain(sineRawHistory[i], 0, 1);
    float y = shy + bandTh * valRaw;
    vertex(x, y);
  }
  endShape(); 

  // draw filtered sine history
  noFill(); 
  stroke(0); 
  beginShape(); 
  for (int i=0; i<nData; i++) {
    float x = xoffset + i;
    float valRaw = sineRawHistory[i];
    float valFiltered = 1.0 - function (valRaw, param_a, param_b, param_c, param_d, param_n);
    valFiltered = constrain(valFiltered, 0, 1); 
    float y = shy + bandTh * valFiltered;
    vertex(x, y);
  }
  endShape();
}


//-----------------------
void drawLabels() {
  float grayEnable = 64;
  float grayDisable = 192;

  fill(grayEnable);
  text(functionName, xoffset, yoffset+yscale+15);
  if (useParameterA) {
    fill (grayEnable); 
    text("a: " + nf(param_a, 1, 3), xoffset, yoffset+yscale+28);
  } 
  else {
    fill (grayDisable);
    text("a: -----", xoffset, yoffset+yscale+28);
  }
  if (useParameterB) {
    fill (grayEnable);
    text("b: " + nf(param_b, 1, 3), xoffset, yoffset+yscale+41);
  } 
  else {
    fill (grayDisable);
    text("b: -----", xoffset, yoffset+yscale+41);
  }

  if (useParameterC) {
    fill (grayEnable);
    text("c: " + nf(param_c, 1, 3), xoffset, yoffset+yscale+54);
  } 
  else {
    fill (grayDisable);
    text("c: -----", xoffset, yoffset+yscale+54);
  }

  if (useParameterD) {
    fill (grayEnable);
    text("d: " + nf(param_d, 1, 3), xoffset, yoffset+yscale+67);
  } 
  else {
    fill (grayDisable);
    text("d: -----", xoffset, yoffset+yscale+67);
  }

  if (useParameterN) {
    fill (grayEnable);
    text("n: " + param_n, xoffset, yoffset+yscale+80);
  } 
  else {
    fill (grayDisable);
    text("n: -----", xoffset, yoffset+yscale+80);
  }
}

//-----------------------------------------------------
void drawModeSpecificGraphics() {

  int whichFunction = FUNCTIONMODE%nFunctionMethods;  
  Method whichMethod = functionMethodArraylist.get(whichFunction); 
  String methodName = whichMethod.getName(); 

  Type[] params = whichMethod.getGenericParameterTypes();
  int nParams = params.length;

  // determine if the current function has an integer argument.
  String lastParamString = params[nParams-1].toString();
  boolean bHasIntegerArgument = (lastParamString.equals("int"));

  float x, y;
  float xa, yb;
  float xc, yd;
  float K = 12;

  noFill();
  stroke(180, 180, 255);

  switch (nParams) {
  case 2:
    if (methodName.equals("function_AdjustableFwhmHalfGaussian")) {
      x = xoffset + param_a * xscale;
      y = yoffset + yscale * (1.0 - function_AdjustableFwhmHalfGaussian (param_a, param_a));
      line (x, yoffset+yscale, x, y); 
      line (xoffset, y, x, y);
    }
    break;
    
  case 3:
    if (bHasIntegerArgument == false) {
      // through a point
      x = xoffset + param_a * xscale;
      y = yoffset + (1-param_b) * yscale;
      line(x-K, y, x+K, y); 
      line(x, y-K, x, y+K);

      if (methodName.equals("function_QuadraticBezier")) {
        line (xoffset, yoffset + yscale, x, y);
        line (xoffset + xscale, yoffset, x, y);
      }
    }
    break;

  case 4:
    if (methodName.equals("function_CircularFillet")) {
      x = xoffset + arcCenterX * xscale;
      y = yoffset + (1-arcCenterY) * yscale;
      float d = 2.0 * arcRadius * xscale;
      ellipseMode(CENTER);
      ellipse(x, y, d, d);

      x = xoffset + param_a * xscale;
      y = yoffset + (1-param_b) * yscale;
      line(x-K, y, x+K, y); 
      line(x, y-K, x, y+K);
    }
    break;

  case 5: // (including x itself)
    if (bHasIntegerArgument == false) {
      // two crosses
      xa = xoffset + param_a * xscale;
      yb = yoffset + (1-param_b) * yscale;
      xc = xoffset + param_c * xscale;
      yd = yoffset + (1-param_d) * yscale;
      line(xa-K, yb, xa+K, yb); 
      line(xa, yb-K, xa, yb+K); 
      line(xc-K, yd, xc+K, yd); 
      line(xc, yd-K, xc, yd+K);

      if (methodName.equals("function_CubicBezier")) {
        line (xoffset, yoffset + yscale, xa, yb);
        line (xc, yd, xa, yb);
        line (xoffset + xscale, yoffset, xc, yd);
      }
    }
    break;
  }



  /*
  "function_AdjustableFwhmHalfGaussian"
   "function_AdjustableSigmaHalfGaussian"
   "function_DoubleLinear"
   "function_DoubleCircleSeat"
   "function_DoubleEllipticSeat"
   "function_DoubleCubicSeat"
   "function_DoubleCubicSeatSimplified"
   "function_DoubleOddPolynomialSeat"
   "function_DoubleExponentialSeat"
   "function_DoubleCircleSigmoid"
   "function_DoubleEllipticSigmoid"
   "function_RaisedInvertedCosine"
   "function_BlinnWyvillCosineApproximation"
   "function_DoubleQuadraticSigmoid"
   "function_DoublePolynomialSigmoid"
   "function_DoubleExponentialSigmoid"
   "function_ExponentialEmphasis"
   "function_NiftyQuartic"
   "function_NormalizedLogisticSigmoid"
   "function_CircularFillet"
   "function_CircularArcThroughAPoint"
   "function_CubicBezierThrough2Points"
   "function_ParabolaThroughAPoint"
   "function_QuadraticBezier"
   "function_CubicBezier"
   "function_Identity"
   "function_CircularEaseIn"
   "function_CircularEaseOut"
   "function_SmoothStep"
   "function_SmootherStep"
   "function_MaclaurinCos"
   "function_CatmullRomInterpolate"
   "function_HermiteAdvanced"
   "function_NormalizedErf"
   "function_NormalizedInverseErf"
   "function_SimpleHalfGaussian"
   "function_HalfGaussianThroughAPoint"
   "function_PennerEaseInBack"
   "function_PennerEaseOutBack"
   "function_PennerEaseInOutBack"
   "function_CircularEaseInOut"
   "function_PennerEaseInQuadratic"
   "function_PennerEaseOutQuadratic"
   "function_PennerEaseInOutQuadratic"
   "function_PennerEaseInCubic"
   "function_PennerEaseOutCubic"
   "function_PennerEaseInOutCubic"
   "function_PennerEaseInQuartic"
   "function_PennerEaseOutQuartic"
   "function_PennerEaseInOutQuartic"
   "function_PennerEaseInQuintic"
   "function_PennerEaseOutQuintic"
   "function_PennerEaseInOutQuintic"
   "function_PennerEaseInElastic"
   "function_PennerEaseOutElastic"
   "function_PennerEaseInOutElastic"
   "function_PennerEaseInExpo"
   "function_PennerEaseOutExpo"
   "function_PennerEaseInOutExpo"
   "function_PennerEaseInSine"
   "function_PennerEaseOutSine"
   "function_PennerEaseInOutSine"
   "function_PennerEaseInBounce"
   "function_PennerEaseOutBounce"
   "function_PennerEaseInOutBounce"
   "function_HalfLanczosSincWindow"
   "function_HalfNuttallWindow"
   "function_HalfBlackmanNuttallWindow"
   "function_HalfBlackmanHarrisWindow"
   "function_HalfExactBlackmanWindow"
   "function_HalfGeneralizedBlackmanWindow"
   "function_HalfFlatTopWindow"
   "function_HalfBartlettHannWindow"
   "function_BartlettWindow"
   "function_CosineWindow"
   "function_TukeyWindow"
   "function_AdjustableSigmaGaussian"
   "function_LanczosSincWindow"
   "function_NuttallWindow"
   "function_BlackmanNuttallWindow"
   "function_BlackmanHarrisWindow"
   "function_ExactBlackmanWindow"
   "function_GeneralizedBlackmanWindow"
   "function_FlatTopWindow"
   "function_BartlettHannWindow"
   "function_HannWindow"
   "function_HammingWindow"
   "function_Staircase"
   "function_Gompertz"
   "function_NormalizedLogit"
   "function_GeneralSigmoidLogitCombo"
   "function_GeneralizedLinearMap"
   "function_AdjustableCenterCosineWindow"
   "function_AdjustableCenterEllipticWindow"
   "function_ExponentialSmoothedStaircase"
   "function_Inverse"
   "function_SlidingAdjustableSigmaGaussian"
   "function_Hermite"
   */
}

//===============================================================
void drawModeSpecificGraphicsOLD() {
  float x, y;
  float xa, yb;
  float xc, yd;
  float K = 12;

  noFill();
  stroke(180, 180, 255);

  switch (FUNCTIONMODE) {


  case 22: // cubic bezier
    xa = xoffset + param_a * xscale;
    yb = yoffset + (1-param_b) * yscale;
    xc = xoffset + param_c * xscale;
    yd = yoffset + (1-param_d) * yscale;
    line (xoffset, yoffset + yscale, xa, yb);
    line (xc, yd, xa, yb);
    line (xoffset + xscale, yoffset, xc, yd);
    break;


  case 17: // circular fillet
    x = xoffset + arcCenterX * xscale;
    y = yoffset + (1-arcCenterY) * yscale;
    float d = 2.0 * arcRadius * xscale;
    ellipseMode(CENTER);
    ellipse(x, y, d, d);

    x = xoffset + param_a * xscale;
    y = yoffset + (1-param_b) * yscale;
    line(x-K, y, x+K, y); 
    line(x, y-K, x, y+K); 
    break;

  case 34: // function_AdjustableHalfGaussian
    x = xoffset + param_a * xscale;
    y = yoffset + yscale * (1.0 - function_AdjustableFwhmHalfGaussian (param_a, param_a));
    line (x, yoffset+yscale, x, y); 
    line (xoffset, y, x, y); 
    break;

  case 35: // function_AdjustableSigmaHalfGaussian
    x = xoffset + param_a * xscale;
    y = yoffset + yscale * (1.0 - function_AdjustableSigmaHalfGaussian (param_a, param_a));
    line (x, yoffset+yscale, x, y); 
    line (xoffset, y, x, y); 
    break;
  }
}

//===============================================================
float function (float x, float a, float b, float c, float d, int n) {
  float out = 0; 
  nFunctionMethods = functionMethodArraylist.size(); 
  if (nFunctionMethods > 0) {
    int whichFunction = FUNCTIONMODE%nFunctionMethods;  
    Method whichMethod = functionMethodArraylist.get(whichFunction); 

    Type[] params = whichMethod.getGenericParameterTypes();
    int nParams = params.length;

    // determine if the current function has an integer argument.
    boolean bHasFinalIntegerArgument = false;
    for (int p=0; p<nParams; p++) {
      String paramString = params[p].toString();
      if (paramString.equals("int")) {
        bHasFinalIntegerArgument = true;
      }
    }

    // Invoke() the current shaping function, 
    // with the correct number and type(s) of arguments. 
    // Note: we don't have any 1-argument functions with an integer arg.
    // Note: we don't have any 6-argument functions without an integer arg.
    try {
      Float F = 0.0;

      if (bHasFinalIntegerArgument) {
        switch(nParams) {
        case 2: 
          F = (Float) whichMethod.invoke(this, x, n);
          break;

        case 3: 
          F = (Float) whichMethod.invoke(this, x, a, n);
          break;

        case 4: 
          F = (Float) whichMethod.invoke(this, x, a, b, n);
          break;

        case 5: 
          F = (Float) whichMethod.invoke(this, x, a, b, c, n);
          break;

        case 6: 
          F = (Float) whichMethod.invoke(this, x, a, b, c, d, n);
          break;
        }
      }

      else if (bHasFinalIntegerArgument == false) {
        switch(nParams) {
        case 1: 
          F = (Float) whichMethod.invoke(this, x); 
          break;

        case 2: 
          F = (Float) whichMethod.invoke(this, x, a);
          break;

        case 3: 
          F = (Float) whichMethod.invoke(this, x, a, b);
          break;

        case 4: 
          F = (Float) whichMethod.invoke(this, x, a, b, c);
          break;

        case 5: 
          F = (Float) whichMethod.invoke(this, x, a, b, c, d);
          break;
        }
      }
      out = F.floatValue();
    } 

    catch (Exception e) {
      // Print out what went wrong.
      println("Problem calling method: " + whichMethod.getName());
      println(e +  ": " + e.getMessage() );
      e.printStackTrace(); 
      Throwable cause = e.getCause();
      println (cause.getMessage());
    }
  }

  return out;
}

/*
// For reference: this is how our old dispatcher was structured, before introspection.
 float functionOLD (float x, float a, float b, float c, float d, int n) {
 float out = 0;
 switch (FUNCTIONMODE) {
 case 0: // etcetera etcetera
 out = function_DoubleLinear (x, a, b);  
 break;
 } 
 return out;
 }
 */

/*
  case 2:
 out = function_DoubleEllipticSeat (x, a, b); 
 break;
 case 3:
 out = function_DoubleCubicSeat (x, a, b);
 break;
 case 4: 
 out = function_DoubleCubicSeatSimplified (x, a, b);
 break;
 case 5: 
 out = function_DoubleOddPolynomialSeat (x, a, b, n);   
 break;
 case 6:
 out = function_DoubleExponentialSeat (x, a);
 break;
 case 7:
 out = function_DoubleCircleSigmoid (x, a);
 break;
 case 8: 
 out = function_DoubleEllipticSigmoid (x, a, b);
 break;
 case 9: 
 out = function_RaisedInvertedCosine (x);
 break;
 case 10: 
 out = function_BlinnWyvillCosineApproximation (x);
 break;
 case 11:
 out = function_DoubleQuadraticSigmoid (x);
 break;
 case 12:
 out = function_DoublePolynomialSigmoid  (x, a, b, n);
 break;
 case 13:
 out = function_DoubleExponentialSigmoid (x, a);
 break;
 case 14:
 out = function_ExponentialEmphasis (x, a);
 break;
 case 15:
 out = function_NiftyQuartic (x, a, b); 
 break;
 
 case 16:
 out = function_NormalizedLogisticSigmoid (x, a);  
 break;
 case 17:
 out = function_CircularFillet (x, a, b, d);
 break;
 case 18:
 out = function_CircularArcThroughAPoint (x, a, b);  
 break;
 
 case 19:
 out = function_CubicBezierThrough2Points (x, a, b, c, d);
 break;
 case 20:
 out = function_ParabolaThroughAPoint (x, a, b);
 break;
 case 21:
 out = function_QuadraticBezier (x, a, b);
 break;
 case 22:
 out = function_CubicBezier (x, a, b, c, d);
 break;
 case 23: 
 out = function_Identity(x);
 break;
 case 24: 
 out =  function_CircularEaseIn(x);
 break;
 case 25:
 out =  function_CircularEaseOut(x);
 break;
 
 case 26:
 out = function_SmoothStep(x); 
 break;
 case 27:
 out = function_SmootherStep(x); 
 break;
 case 28:
 out = function_MaclaurinCos(x); 
 break;
 
 case 29: 
 out = function_CatmullRomInterpolate (x, a, b);
 break;
 case 30: 
 out = function_HermiteAdvanced (x, a, b);
 break;
 case 31: 
 out = function_NormalizedErf(x); 
 break;
 case 32:
 out = function_NormalizedInverseErf(x); 
 break;
 
 case 33: 
 out = function_SimpleHalfGaussian (x); 
 break;
 case 34: 
 out = function_AdjustableFwhmHalfGaussian (x, a); 
 break;
 case 35: 
 out = function_AdjustableSigmaHalfGaussian (x, a); 
 break;
 case 36:
 out = function_HalfGaussianThroughAPoint (x, a, b); 
 break;
 
 case 37:
 out = function_PennerEaseInBack (x); 
 break;
 case 38: 
 out = function_PennerEaseOutBack (x); 
 break; 
 case 39:
 out = function_PennerEaseInOutBack (x); 
 break;
 case 40: 
 out = function_CircularEaseInOut (x);
 break;
 
 case 41: 
 out = function_PennerEaseInQuadratic (x); 
 break;
 case 42: 
 out = function_PennerEaseOutQuadratic (x); 
 break; 
 case 43: 
 out = function_PennerEaseInOutQuadratic (x); 
 break;  
 
 case 44:
 out = function_PennerEaseInCubic (x); 
 break;
 case 45:
 out = function_PennerEaseOutCubic (x); 
 break;
 case 46: 
 out = function_PennerEaseInOutCubic (x); 
 break;
 
 case 47: 
 out = function_PennerEaseInQuartic (x); 
 break;
 case 48: 
 out = function_PennerEaseOutQuartic (x); 
 break;
 case 49: 
 out = function_PennerEaseInOutQuartic (x); 
 break;
 
 case 50: 
 out = function_PennerEaseInQuintic (x); 
 break; 
 case 51: 
 out = function_PennerEaseOutQuintic (x); 
 break; 
 case 52: 
 out = function_PennerEaseInOutQuintic (x); 
 break; 
 
 case 53: 
 out = function_PennerEaseInElastic (x); 
 break;
 case 54:
 out = function_PennerEaseOutElastic (x); 
 break;
 case 55:
 out = function_PennerEaseInOutElastic (x); 
 break;
 
 
 
 case 56: 
 out = function_PennerEaseInExpo (x); 
 break;
 case 57: 
 out = function_PennerEaseOutExpo (x); 
 break;
 case 58: 
 out = function_PennerEaseInOutExpo (x); 
 break;
 
 case 59: 
 out = function_PennerEaseInSine (x); 
 break;
 case 60: 
 out = function_PennerEaseOutSine (x); 
 break;
 case 61: 
 out = function_PennerEaseInOutSine (x); 
 break;
 
 
 case 62: 
 out = function_PennerEaseInBounce (x); 
 break;
 case 63: 
 out = function_PennerEaseOutBounce (x); 
 break;
 case 64: 
 out = function_PennerEaseInOutBounce (x); 
 break;
 
 
 case 65: 
 out = function_HalfLanczosSincWindow (x); 
 break;
 case 66:
 out = function_HalfNuttallWindow (x); 
 break;
 case 67:
 out = function_HalfBlackmanNuttallWindow (x); 
 break;
 case 68:
 out = function_HalfBlackmanHarrisWindow (x); 
 break;
 case 69: 
 out = function_HalfExactBlackmanWindow (x); 
 break;
 case 70:
 out = function_HalfGeneralizedBlackmanWindow (x, a); 
 break;
 case 71: 
 out = function_HalfFlatTopWindow (x); 
 break;
 case 72: 
 out = function_HalfBartlettHannWindow (x); 
 break;
 
 case 73: 
 out = function_BartlettWindow (x); 
 break;
 case 74: 
 out = function_CosineWindow (x);
 break;
 case 75: 
 out = function_TukeyWindow (x, a); 
 break;
 
 
 case 76: 
 out = function_AdjustableSigmaGaussian (x, a); 
 break;
 case 77: 
 out = function_LanczosSincWindow (x); 
 break;
 case 78: 
 out = function_NuttallWindow (x); 
 break;
 case 79: 
 out = function_BlackmanNuttallWindow (x); 
 break;
 case 80: 
 out = function_BlackmanHarrisWindow (x); 
 break;
 case 81: 
 out = function_ExactBlackmanWindow (x); 
 break;
 case 82: 
 out = function_GeneralizedBlackmanWindow (x, a); 
 break;
 case 83: 
 out = function_FlatTopWindow (x); 
 break;
 case 84: 
 out = function_BartlettHannWindow (x); 
 break;
 case 85: 
 out = function_HannWindow (x); 
 break;  
 case 86: 
 out = function_HammingWindow (x); 
 break;
 case 87: 
 out = functionGeneralizedTriangleWindow (x, a); 
 break;
 case 88: 
 out = functionPoissonWindow (x, a); 
 break;
 case 89: 
 out = functionHannPoissonWindow (x, a); 
 break;
 case 90: 
 param_n = 7;
 out = function_Staircase (x, param_n); 
 break;
 case 91: 
 out = function_Gompertz (x, a); 
 break;
 
 case 92: 
 out = function_NormalizedLogit (x, a); 
 break;
 case 93: 
 out = function_NormalizedLogisticSigmoid (x, a); 
 break;
 case 94: 
 out = function_GeneralSigmoidLogitCombo (x, a, b); 
 break;  
 
 case 95: 
 out = function_GeneralizedLinearMap (x, a, b, c, d);
 break;
 case 96:
 out = function_AdjustableCenterCosineWindow (x, a);
 break;
 case 97: 
 out = function_AdjustableCenterEllipticWindow (x, a);
 break;
 case 98: 
 param_n = 7;
 out = function_ExponentialSmoothedStaircase (x, a, param_n);
 break;
 
 case 99: 
 out = function_Inverse (x); 
 break;
 case 100: 
 out = function_SlidingAdjustableSigmaGaussian (x, a, b); 
 break;
 }
 return out;
 }
 
 */

/////////////////////////////////////////////////////////////////////////
//
// Notes for introspection 
// Documentation here: 
// http://docs.oracle.com/javase/1.5.0/docs/api/java/lang/Object.html
// http://docs.oracle.com/javase/1.5.0/docs/api/java/lang/reflect/Method.html
// http://docs.oracle.com/javase/1.5.0/docs/api/java/lang/Class.html
//
// Be sure to import the following: 
// import java.lang.*;
// import java.lang.reflect.Method;
// import java.lang.reflect.Type;
//
// Other notes:
// Method.invoke(..) // allows calling of a function!
// String rts = m.getReturnType().toString(); // assumed to be float, for us.

ArrayList<Method> functionMethodArraylist; 
int nFunctionMethods;

void introspect() {
  // Examine the current class, extract the names of the functions,  
  // then compile an ArrayList containing all the shaper functions. 
  functionMethodArraylist = new ArrayList<Method>();
  nFunctionMethods = 0; 

  try {
    // This fetches the class name for the current (PApplet) class, 
    // which happens to contain all of the functions. For Processing, if the functions
    // were instead inside an inner class (say, "FunctionManager", we would  
    // add the following to the fullClassName: // + "$" + "FunctionManager";
    String fullClassName = this.getClass().getName(); 
    Class myClassName = Class.forName(fullClassName);

    int funcCount = 0; 
    Method[] methods = myClassName.getMethods();

    if (methods.length>0) {
      // count (specifically) the shaper functions.
      // copy into local arraylist data structure
      for (int i=0; i<methods.length; i++) {
        Method m = methods[i];
        String methodName = m.getName(); 
        if (methodName.startsWith ("function_")) { 
          println ('"' + methodName + '"'); 
          funcCount++;
          functionMethodArraylist.add(m);
        }
      }
      nFunctionMethods = functionMethodArraylist.size(); 
      println("nFunctionMethods = " + nFunctionMethods);
    }
  }
  catch (Exception e) {
    println (e);
  }
}

