//
//  MatAndUIImageTool.h
//  idCardRecognition
//
//  Created by slimdy on 2017/11/28.
//  Copyright © 2017年 slimdy. All rights reserved.
//
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif
#ifdef __OBJC__
#import <opencv2/opencv.hpp>
#endif
#import <UIKit/UIKit.h>

@interface MatAndUIImageTool : NSObject
+(UIImage *)imageWithCVMat:(const cv::Mat&)image;
+(cv::Mat) UIImageToCvMat:(UIImage *)image;
//@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;
@end
