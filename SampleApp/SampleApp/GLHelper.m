//
//  GLHelper.m
//  SampleApp
//
//  Created by Rohan on 05/11/20.
//

#import "GLHelper.h"

@implementation GLHelper

+(GLubyte)createTextureFrom:(UIImage *)image {
  CGImageRef imageRef = [image CGImage];
  int width = CGImageGetWidth(imageRef);
  int height = CGImageGetHeight(imageRef);
  
  GLubyte* textureData = (GLubyte *)malloc(width * height * 4); // if 4 components per pixel (RGBA)

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  NSUInteger bytesPerPixel = 4;
  NSUInteger bytesPerRow = bytesPerPixel * width;
  NSUInteger bitsPerComponent = 8;
  CGContextRef context = CGBitmapContextCreate(textureData, width, height,
                                               bitsPerComponent, bytesPerRow, colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

  CGColorSpaceRelease(colorSpace);

  CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
  CGContextRelease(context);
  
  GLuint textureID;
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glGenTextures(1, &textureID);

  glBindTexture(GL_TEXTURE_2D, textureID);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
  
  return textureID;
}

@end
