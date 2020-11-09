//
//  GLHelper.h
//  SampleApp
//
//  Created by Rohan on 05/11/20.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLHelper : NSObject

+(GLubyte)createTextureFrom:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
