//original code by this guy:

//Raven Kwok aka Guo, Ruiwen
//ravenkwok.com
//vimeo.com/ravenkwok
//flickr.com/photos/ravenkwok
 
 
/*things to experiments with:
-the conditions for when to draw on the screen (for now its just a condition on the alpha channels)
-the positions of where to draw on the screen  (for now its just a condition on the electrodes)
-particles parameters like their movement, their color (maybe try the alpha/beta ratio compared to its average? HSV color mode could be interesting), their size, etc
*/ 
 
//particles system
ArrayList<Particle> pts;


//width and height of the screen divided by the amount of electrodes on those directions
int w_step;
int h_step;
  
//rows and cols of the original data and the derivatives of the data 
int data_rows;
int data_cols;
int data_diff_rows;
int data_diff_cols;   

//tables from the .csvs, for the raw data and its derivative
Table data, data_diff;
//arrays to load the data
float[][] data_array, data_diff_array;
//arrays to load the average value of each feature, for the raw data and its derivative
float[] data_avg, data_diff_avg;
//array of (x,y) vectors which contains the associated spatial coordinates for each electrode
PVector[] nodes_positions_array = new PVector[16];
//counter for the frames
int frame_count;
//make calculations every frame_interval frames
int frame_interval = 1;
//index to access the data samples at a specific time
int index; 

//noise space coordinates, to add a little displacement on the electrodes position
int noise_x,noise_y = 0;

//make a still painting or not
boolean refresh_screen = true;
 
void setup() {
  
  //setup for the window, part of the original code
  fullScreen();
  smooth();
  frameRate(30);
  colorMode(RGB);
  rectMode(CENTER);
  background(255);//set background to white


  noStroke(); //draw without stroke
  
  
  frame_count = 0;  
  index = 0;         
  
  //raw data of all the normalized parameters (values from 0 to 1):
  //columns:   0 to 3: beta, alpha, theta, delta
  //           4 to 20: electrodes
  //rows: samples over time
  data = loadTable("sleeping_data_norm.csv","header");
  
  //raw data of the normalized derivatives of the parameters (values from 0 to 1)
  data_diff = loadTable("sleeping_data_diff_norm.csv","header");

  //cols and rows
  data_rows = data.getRowCount();
  data_cols = data.getColumnCount();
  data_diff_rows = data_diff.getRowCount();
  data_diff_cols = data_diff.getColumnCount();  
  
  //getting arrays from the .csv
  data_array = new float[data_rows][data_cols];
  data_diff_array = new float[data_diff_rows][data_diff_cols];
  
  data_avg = new float[data_cols];
  data_diff_avg = new float[data_diff_cols];
  
  
  //calculating average of every feature
  for (int i = 0; i < data_cols; i++){
    float sum = 0;
    for (int j = 0; j < data_rows; j++){
      data_array[j][i] = data.getRow(j).getFloat(i);
      sum += data_array[j][i];
    }
    sum/= data_rows;
    data_avg[i] = sum;
  }
  
  //calculating the average of the derivatives of the features
  for (int i = 0; i < data_diff_cols; i++){
    float sum = 0;
    for (int j = 0; j < data_diff_rows; j++){
      data_diff_array[j][i] = data_diff.getRow(j).getFloat(i);
      sum += data_diff_array[j][i];
    }
    sum/= data_diff_rows;
    data_diff_avg[i] = sum;
  }  

  
  //calculating the position for each electrode
  w_step = width/7; //7 steps in width
  h_step = height/3; //3 steps in height
  
  //hardcoding the positions 
  nodes_positions_array[0] = new PVector(w_step/2, h_step/2);
  nodes_positions_array[1] = new PVector(w_step/2 + w_step*2, h_step/2);
  nodes_positions_array[2] = new PVector(w_step/2 + w_step*3, h_step/2);
  nodes_positions_array[3] = new PVector(w_step/2 + w_step*4, h_step/2);
  nodes_positions_array[4] = new PVector(w_step/2 + w_step*6, h_step/2);
  nodes_positions_array[5] = new PVector(w_step/2, h_step/2 + h_step);
  nodes_positions_array[6] = new PVector(w_step/2 + w_step, h_step/2 + h_step);
  nodes_positions_array[7] = new PVector(w_step/2 + w_step*2, h_step/2 + h_step);
  nodes_positions_array[8] = new PVector(w_step/2 + w_step*3, h_step/2 + h_step);
  nodes_positions_array[9] = new PVector(w_step/2 + w_step*4, h_step/2 + h_step);
  nodes_positions_array[10] = new PVector(w_step/2 + w_step*5, h_step/2 + h_step);
  nodes_positions_array[11] = new PVector(w_step/2 + w_step*6, h_step/2 + h_step);
  nodes_positions_array[12] = new PVector(w_step/2, h_step/2 + h_step*2);
  nodes_positions_array[13] = new PVector(w_step/2 + w_step*2, h_step/2 + h_step*2);
  nodes_positions_array[14] = new PVector(w_step/2 + w_step*4, h_step/2 + h_step*2);
  nodes_positions_array[15] = new PVector(w_step/2 + w_step*6, h_step/2 + h_step*2);
  
  
  //part of the original code
  pts = new ArrayList<Particle>();

}
 
void draw() {
  if (refresh_screen)
    background(255);
  
  //get a new sample evey frame_interval:
  if (frame_count % frame_interval == 0){
    index++;

    //if this condition is met, then we are drawing things! we should check other conditions also!
    //event: any feature is bigger than its average value on the dream
    boolean event = false;
    for (int i = 0; i<20; i++){
      if (data_array[index][i]>data_avg[i]){
      event = true;
      break;
      }
    }
    if (event) { 
      //loop through the electrodes data features:
      for (int f = 4; f < data_cols; f++){
        
        //if the energy of the electrode at that time is bigger than its average
        if (data_array[index][f]>data_avg[f] ) {

          //draw particles on the position of the electrode based on beta/alpha
          int part_amount = floor( ( data_array[index][0] / data_array[index][1] )); 
          //positions of the particle
          int pos_x = floor(nodes_positions_array[f-4].x);
          int pos_y = floor(nodes_positions_array[f-4].y);
          //adding perlin noise to the position
          float noise = noise(noise_x,noise_y);
          pos_x += (noise-0.5)*w_step;
          pos_y += (noise-0.5)*h_step;
          //moving in the noise space
          noise_x++;
          noise_y++;
          //adding particles
          for (int i = 0; i < part_amount; i++) {
            Particle newP = new Particle(pos_x, pos_y, i+pts.size(), i+pts.size());
            pts.add(newP);
          }
        }
      }
    }
  }
 
 //everything else is part of the original sketch
  for (int i=0; i<pts.size(); i++) {
    Particle p = pts.get(i);
    p.update();
    p.display();
  }
 
  for (int i=pts.size()-1; i>-1; i--) {
    Particle p = pts.get(i);
    if (p.dead) {
      pts.remove(i);
    }
  }
 
 //update the frame_count
  frame_count++;
}

 
void keyPressed() {
  if (key == 'c') {
    for (int i=pts.size()-1; i>-1; i--) {
      Particle p = pts.get(i);
      pts.remove(i);
    }
    background(255);
    refresh_screen = !refresh_screen;
  }
}
 
class Particle{
  PVector loc, vel, acc;
  int lifeSpan, passedLife;
  boolean dead;
  float alpha, weight, weightRange, decay, xOffset, yOffset;
  color c;
   
  Particle(float x, float y, float xOffset, float yOffset){
    loc = new PVector(x,y);
     
    float randDegrees = random(360);
    vel = new PVector(cos(radians(randDegrees)), sin(radians(randDegrees)));
    vel.mult(random(5));
     
    acc = new PVector(0,0);
    lifeSpan = int(random(30, 90));
    decay = random(0.75, 0.9);
    
    int hue = 0;
    
    //if (x < (width/2)) {
      //hue = 75;  
    //};
    int r, b;
    if (floor(x) < (width/2)){
      b = 200;
      r = floor( random(100) );
    }
    else { 
      r = 255;
      b = floor( random(100) );
    }
    c = color(r,random(150),b);
    weightRange = random(3,50);
     
    this.xOffset = xOffset;
    this.yOffset = yOffset;
  }
   
  void update(){
    if(passedLife>=lifeSpan){
      dead = true;
    }else{
      passedLife++;
    }
     
    alpha = float(lifeSpan-passedLife)/lifeSpan * 70+50;
    weight = float(lifeSpan-passedLife)/lifeSpan * weightRange;
     
    acc.set(0,0);
     
    float rn = (noise((loc.x+frameCount+xOffset)*0.01, (loc.y+frameCount+yOffset)*0.01)-0.5)*4*PI;
    float mag = noise((loc.y+frameCount)*0.01, (loc.x+frameCount)*0.01);
    PVector dir = new PVector(cos(rn),sin(rn));
    acc.add(dir);
    acc.mult(mag);
     
    float randDegrees = random(360);
    PVector randV = new PVector(cos(radians(randDegrees)), sin(radians(randDegrees)));
    randV.mult(0.5);
    acc.add(randV);
     
    vel.add(acc);
    vel.mult(decay);
    vel.limit(3);
    loc.add(vel);
  }
   
  void display(){
    //strokeWeight(weight+1.5);
    //stroke(0, alpha);
    //c = color(hue, sat, 100);
    point(loc.x, loc.y);
     
    strokeWeight(weight);
    stroke(c);
    point(loc.x, loc.y);
  }
}