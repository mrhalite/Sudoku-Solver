//
//  OpenCVWrapper.h
//  cam_test
//
//  Created by 남상규 on 2018. 6. 28..
//  Copyright © 2018년 NeoLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (NSMutableArray *) getSukokuImage: (UIImage *)sourceImage;
+ (NSMutableArray *) getSlicedSukokuNumImages: (UIImage *)sourceImage imageSize: (int)imageSize cutOffset: (int)cutOffset;
+ (NSMutableArray *) getNumImage: (UIImage *)sourceImage imageSize: (int)imageSize;

@end
