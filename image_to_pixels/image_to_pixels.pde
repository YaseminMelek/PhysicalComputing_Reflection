import java.util.ArrayList;
import processing.serial.*;
Serial myPort;

PImage img1, img2, img3, img4, img5, edge_img1, edge_img2, edge_img3, edge_img4, edge_img5, edge_img6, edge_img7, edge_img8, edge_img9, edge_img10;

int pixel_grid_width = 24;
int pixel_grid_height = 8;
int pixel_grid_length = 193;
int pixel_index = 0;
int draw_index = 0;
int img_track = 0;
int edge_img_track = 0;
  
float red_val_row = 0;
float green_val_row = 0;
float blue_val_row = 0;
float red_val_section = 0;
float blue_val_section = 0;
float green_val_section = 0;
float interp = 0.5;

int section_w;
int section_h;
boolean matched = false;
boolean next = false;
boolean image_to_color = true;
boolean edge = false;
boolean transition = false;

ArrayList<Integer[]> neopixel_color_array = new ArrayList<Integer[]>(); 
ArrayList<PImage> image_array = new ArrayList<PImage>();
ArrayList<PImage> edge_image_array = new ArrayList<PImage>();

int[] dims = new int[2];

// edge detection 
float[][] kernel = {{ -1, -1, -1},
                    { -1,  8, -1},
                    { -1, -1, -1}};

void setup() {
  size(1300, 800);
  
  img1 = loadImage("molecules.jpg");
  img2 = loadImage("cell.jpg");
  img3 = loadImage("cell.jpg");
  img4 = loadImage("cell1.jpg");
  img5 = loadImage("cell3.jpg");
  
  image_array.add(img1);
  image_array.add(img2);
  image_array.add(img3);
  image_array.add(img4);
  image_array.add(img5);
  
  edge_img1 = loadImage("circ1.png");
  edge_img2 = loadImage("circ2.png");
  edge_img3 = loadImage("circ3.png");
  edge_img4 = loadImage("circ4.png");
  edge_img5 = loadImage("circ5.png");
  edge_img6 = loadImage("sine.jpg");
  edge_img7 = loadImage("1.jpg");
  edge_img8 = loadImage("0.jpg");
  edge_img9 = loadImage("hex2.png");
  edge_img10 = loadImage("hex1.jpg");
  
  edge_image_array.add(edge_img1);
  edge_image_array.add(edge_img2);
  edge_image_array.add(edge_img3);
  edge_image_array.add(edge_img4);
  edge_image_array.add(edge_img5);
  edge_image_array.add(edge_img6);
  edge_image_array.add(edge_img7);
  edge_image_array.add(edge_img8);
  edge_image_array.add(edge_img9);
  edge_image_array.add(edge_img10);

  myPort  =  new Serial (this, "COM4",  9600);
  
}
// location = x + y * width
void draw() {
  if(image_to_color) {
   if(image_array.size() > img_track) {
      prepare_image(image_array.get(img_track));
      for(int y = 0; y < pixel_grid_height; y++) {
        for(int x = 0; x < pixel_grid_width; x++) {
          get_average_color(x,y,image_array.get(img_track));
         }
        }
      draw_pixels();
      send_pixels();
      image_to_color = false;
   }
  } 
  if (myPort.available() > 0) {  
    String str = myPort.readStringUntil('.');
    if(str != null) {
          println(str); 
      if(str.equals("edge.")) {
      println(str); 
      edge = true;
     }
     else if(str.equals("color.")) {
       println(str); 
       image_to_color = true;
       draw_index = 0;
       pixel_index = 0;
     }
    } 
   }
   if(edge == true) {
      if(edge_image_array.size() > edge_img_track) {
       edge_detection(edge_image_array.get(edge_img_track));
       delay(200);
      }
      else if(edge_image_array.size() == edge_img_track){
        edge_img_track = 0;
        edge = false;
      }
   }
}


 void get_average_color(int x_pos,int y_pos, PImage img) {
    section_w = dims[0];
    section_h = dims[1];
    int start_point_x = section_w * x_pos;
    int start_point_y = section_h * y_pos;
  
    for(int y = start_point_y; y < start_point_y + section_h ; y++) {
      for(int x = start_point_x; x < start_point_x + section_w; x++) {
        int pix = x + y * img.width;
        float r = red(img.pixels[pix]);
        float g = green(img.pixels[pix]);
        float b = blue(img.pixels[pix]);
        red_val_row += r;
        green_val_row += g;
        blue_val_row += b;
        
        if(x == start_point_x + section_w - 1) {
          red_val_row /= section_w;
          green_val_row /= section_w;
          blue_val_row /= section_w;
          
          red_val_section += red_val_row;
          green_val_section += green_val_row;
          blue_val_section += blue_val_row;
        }
        
      }
      if(y == start_point_y + section_h - 1) {
        red_val_section /= section_h;
        green_val_section /= section_h;
        blue_val_section /= section_h;
                
        int red_val_int = int(red_val_section);
        int green_val_int = int(green_val_section);
        int blue_val_int = int(blue_val_section);
        
        Integer[] color_array = {pixel_index, red_val_int, green_val_int, blue_val_int};
        neopixel_color_array.add(color_array);
        pixel_index++;
      }
    }
  }
  
  void edge_detection(PImage img) {
  matched = false;
  // EDGE DETECTION ALGORITHM FROM https://processing.org/examples/edgedetection.html
  ArrayList<Integer> neopixel_array = new ArrayList<Integer>(); 
  PImage gray_img = img.copy();
  gray_img.filter(GRAY);
  PImage edge_img = createImage(gray_img.width, gray_img.height, RGB);
  for (int y = 1; y < gray_img.height - 1; y++) {
    for (int x = 1; x < gray_img.width - 1; x++) {
      float sum = 0;
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          int pos = (y + ky) * gray_img.width + (x + kx);
          float color_val = blue(gray_img.pixels[pos]);
          sum += kernel[ky+1][kx+1] * color_val;
        }
      }
      edge_img.pixels[y * edge_img.width + x] = color(sum);
    }
  }

 edge_img.updatePixels();
 image(edge_img,0, 0);
    
    for (int y = 0; y < edge_img.height; y++) {
      for(int x = 0; x < edge_img.width; x++) {
        int pix = x + y * edge_img.width;
        if(red(edge_img.pixels[pix]) != 0.0) {
          float mapped_x = map(x, 0, edge_img.width, 0, pixel_grid_width);
          float mapped_y = map(y, 0, edge_img.height, 0, pixel_grid_height);
          int mapped_loc = int(mapped_x) + int(mapped_y) * pixel_grid_width;
          for(int i = 0; i < neopixel_array.size(); i++) {
             if(neopixel_array.get(i) == mapped_loc) {
                matched = true;
                break;
             }
             else {
               matched = false;
             }
          }
          
          if(matched == false) {
              neopixel_array.add(mapped_loc);
          }    
          //println(x + " " + y + " " + int(mapped_x) + " " + int(mapped_y) + " " + int(mapped_loc));
          }
        } 
      }
    neopixel_array.add(256);
    println(neopixel_array);
    for(int i = 0; i < neopixel_array.size(); i++) {
       myPort.write(neopixel_array.get(i));
     //  println(neopixel_array.get(i));
    }
    edge_img_track++;
  }
  
  void draw_pixels() {  
    for(int y = 0; y < pixel_grid_height * 50; y += 50) {
      for(int x = 0; x < pixel_grid_width * 50; x += 50) {
        noStroke();
        fill(neopixel_color_array.get(draw_index)[1], neopixel_color_array.get(draw_index)[2], neopixel_color_array.get(draw_index)[3]);
        rect(x,y, 50, 50);
        neopixel_color_array.get(draw_index);
        draw_index++;
      }
    }
  }
  
  void prepare_image(PImage img) {
    img.loadPixels();
    section_w = img.width / pixel_grid_width;
    section_h = img.height / pixel_grid_height;
    dims[0] = section_w;
    dims[1] = section_h;
  }
  /*
  void transition() {
    for(int i = 0; i < neopixel_color_array.size(); i++) {
      float new_red = lerp(neopixel_color_array.get(i)[1], neopixel_color_array_next.get(i)[1], interp);
      float new_green = lerp(neopixel_color_array.get(i)[2], neopixel_color_array_next.get(i)[2], interp);
      float new_blue = lerp(neopixel_color_array.get(i)[3], neopixel_color_array_next.get(i)[3], interp);
      neopixel_color_array.get(i)[1] = int(new_red);
      neopixel_color_array.get(i)[2] = int(new_green);
      neopixel_color_array.get(i)[3] = int(new_blue);      
    }
  }*/
  
  void send_pixels() {
    for(int i = 0; i < 192; i++) {
      String s_index = Integer.toString(neopixel_color_array.get(i)[0]);
      String s_red = Integer.toString(neopixel_color_array.get(i)[1]);
      String s_blue = Integer.toString(neopixel_color_array.get(i)[3]);
      String s_green = Integer.toString(neopixel_color_array.get(i)[2]);
      String s_total = s_index + " " + s_red + " " + s_green + " " +s_blue + ";";

   
      myPort.write(s_total);
      if(i % 10 == 0) {
        println(s_total);
      }
     delay(10);
  }
   img_track++;
   neopixel_color_array.clear();
 }
