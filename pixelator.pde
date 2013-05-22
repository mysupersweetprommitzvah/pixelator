import processing.video.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

Capture video;
AudioInput audio;
Minim minim;
FFT fft;

int numPixelsWide, numPixelsHigh;
int blockSize = 20;
int minBlockSize;
int maxBlockSize;
color movColors[];
float currMaxVal;

float amplitude = 1.0;

boolean invert = false;
boolean posterize = false;
boolean gray = false;
boolean rainbow = false;
int rainbowCount = 0;

boolean red = true;
boolean green = true;
boolean blue = true;

void setup() {
  width = displayWidth;
  height = displayHeight;
  
  minBlockSize = displayWidth / 80;
  maxBlockSize = displayWidth / 4;
  size(width, height, P2D);
  noStroke();
  
  video = new Capture(this, width, height);
  video.start();  
  
  minim = new Minim(this);
  audio = minim.getLineIn(Minim.STEREO, int(1024));
  fft = new FFT(audio.bufferSize(), audio.sampleRate());
  fft.window(FFT.HAMMING);
}

void captureEvent(Capture c) {
  c.read();
}

// Display values from movie
void draw() {
  if (rainbowCount == 0){
    red = int(random(2)) == 1;
    blue = int(random(2)) == 1;
    green = int(random(2)) == 1;
    if (!red && !blue && !green){
      red = true;
      green = true;
      blue = true;
    }
    rainbowCount = int(random(3, 20));
  }
  else {
    rainbowCount--;
  }
  
  currMaxVal = 0;
  fft.forward(audio.mix);
  for(int i = 0; i<256 ; i++){
    if ( fft.getBand(i) > currMaxVal ){
      currMaxVal = fft.getBand(i);
    }
  }
  
  blockSize = int((ceil(currMaxVal) + 1) * amplitude);
  
  if (blockSize < minBlockSize){
    blockSize = minBlockSize;
  }
  if (blockSize > maxBlockSize){
    blockSize = maxBlockSize;
  }
  
  numPixelsWide = ceil(video.width * 1.0 / blockSize);
  numPixelsHigh = ceil(video.height * 1.0 / blockSize);
  
  video.loadPixels();
  movColors = new color[numPixelsWide * numPixelsHigh];
  int count = 0;
  for (int j = 0; j < numPixelsHigh; j++) {
    for (int i = 0; i < numPixelsWide; i++) {
      int x = i * blockSize;
      int y = j * blockSize;
      
      if (x > width){
        x = width;
      }
      
      if (y > height){
        y = height;
      }
      color c = video.get(x, y);
      int r = c >> 16 & 0xFF;  // Faster way of getting red(argb)
      int g = c >> 8 & 0xFF;   // Faster way of getting green(argb)
      int b = c & 0xFF;        // Faster way of getting blue(argb)
      
      if (rainbow) {
        if (!red){
          r = 0;
        }
        if (!green){
          g = 0;
        }
        if (!blue){
          b = 0;
        }
      }

      movColors[count] = color(r, g, b);
      count++;
    }
  }
  
  background(0);

  for (int j = 0; j < numPixelsHigh; j++) {
    for (int i = 0; i < numPixelsWide; i++) {
      fill(movColors[j*numPixelsWide + i]);
      rect(i*blockSize, j*blockSize, blockSize, blockSize);
    }
  }
  
  if (invert){
    filter(INVERT);
  }
  if (posterize){
    filter(POSTERIZE, 4);
  }
  if (gray) {
    filter(GRAY);
  }
 

}
void keyReleased() {
  if (key == 'i'){
    invert = !invert;
  }
  else if (key == 'p'){
    posterize = !posterize;
  }
  
  else if (key == 'g'){
    gray = !gray;
  }
  
  else if (key == 'r'){
    rainbow = !rainbow;
  }
  
  else if (keyCode == UP){
    amplitude += 0.1;
  }
  
  else if (keyCode == DOWN){
    amplitude -= 0.1;
  }
  
  else if (keyCode == LEFT){
    amplitude = 1;
  }
}

void stop() {
  audio.close();
  video.stop();
  minim.stop();
  super.stop();
}
