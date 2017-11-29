//
//  LF_IDCardRecognitionManager.m
//  LF_IDCardRecognitionManager
//
//  Created by slimdy on 2017/11/27.
//  Copyright © 2017年 slimdy. All rights reserved.
//

#include "LF_opencvStaticLib.hpp"
#import "LF_IDCardRecognitionManager.h"

#import "LF_paramModel.h"
#import "LF_idCardModel.h"
#import "MatAndUIImageTool.h"

std::vector<cv::Mat> _allImageMat;

@implementation LF_IDCardRecognitionManager
static LF_IDCardRecognitionManager *manager = nil;
+(instancetype)sharedManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
        
    });
    return manager;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return manager;
}
-(instancetype)mutableCopyWithZone:(NSZone *)zone
{
    return manager;
}
-(NSArray *) idCardCutIntoPieces:(UIImage*)beCutImage isCheckedImage:(BOOL) flag{
    if (flag){
        if (!_allImageMat.empty()) {
            return [self converFromVector:_allImageMat];
        }
    }
    cv::Mat image = [MatAndUIImageTool UIImageToCvMat:beCutImage];
    
    return  [self converFromVector:cutIntoPieces(image)];
}
-(BOOL)idCard:(UIImage *)OriginalImage isRightWith:(LF_paramModel *) param{
    self.allImage = nil;
    _allImageMat .clear();
    cv::Mat oimage = [MatAndUIImageTool UIImageToCvMat:OriginalImage];
    std::vector<cv::Mat> rightImage;
    bool res = checkImageIsRight(oimage,rightImage, param.idCardWidth,param.idCardHeight,param.headViewRect.origin.x, param.headViewRect.origin.y,param.headViewRect.size.width ,param.headViewRect.size.height);
    if (res && !rightImage.empty()) {
        _allImageMat = rightImage;
        self.allImage = [self converFromVector:rightImage];
        return YES;
    }else{
        return NO;
    }
    
}
-(LF_idCardModel*)idCardInformationByTesseractOcrDataPath:(NSString*)dataPath andImages:(NSArray *)images{
    if ( dataPath == nil) {
        return nil;
    }
    if ((images == nil || images.count == 0)&& images.count == 8) {
        return nil;
    }else{
        _allImageMat = [self converFromeArray:images];
    }
    
    LF_idCardModel *idcard = [[LF_idCardModel alloc] init];
    std::vector<std::string> information;
    int res = getTheIDInfoFrom(_allImageMat,information, [dataPath UTF8String]);
    if (res == 0) {
        return nil;
    }
    if (information.size() != 8) {
        return nil;
    }
    idcard.name = [NSString stringWithUTF8String:information[0].c_str()];
    idcard.gender = [NSString stringWithUTF8String:information[1].c_str()];
    idcard.race = [NSString stringWithUTF8String:information[2].c_str()];
    idcard.birthYear = [NSString stringWithUTF8String:information[3].c_str()];
    idcard.birthMonth = [NSString stringWithUTF8String:information[4].c_str()];
    idcard.birthDay = [NSString stringWithUTF8String:information[5].c_str()];
    idcard.address = [NSString stringWithUTF8String:information[6].c_str()];
    idcard.idNumber = [NSString stringWithUTF8String:information[7].c_str()];
    
    return idcard;
}
-(LF_idCardModel*)idCardInformationByTesseractOcrDataPath:(NSString*)dataPath{
    return [self idCardInformationByTesseractOcrDataPath:dataPath andImages:nil];
    //    if (_allImageMat.empty()||dataPath == nil){
    //        return nil;
    //    }
    //    LF_idCardModel *idcard = [[LF_idCardModel alloc] init];
    //    std::vector<std::string> information;
    //    int res = getTheIDInfoFrom(_allImageMat,information, [dataPath UTF8String]);
    //    if (res == 0) {
    //        return nil;
    //    }
    //
    //    idcard.name = [NSString stringWithCString:information[0].c_str() encoding:[NSString defaultCStringEncoding]];
    //    idcard.gender = [NSString stringWithCString:information[1].c_str() encoding:[NSString defaultCStringEncoding]];
    //    idcard.race = [NSString stringWithCString:information[2].c_str() encoding:[NSString defaultCStringEncoding]];
    //    idcard.birthYear = [NSString stringWithCString:information[3].c_str() encoding:[NSString defaultCStringEncoding]];
    //    idcard.birthMonth = [NSString stringWithCString:information[4].c_str() encoding:[NSString defaultCStringEncoding]];
    //    idcard.birthDay = [NSString stringWithCString:information[5].c_str() encoding:[NSString defaultCStringEncoding]];
    //    idcard.address = [NSString stringWithCString:information[6].c_str() encoding:[NSString defaultCStringEncoding]];
    //    idcard.idNumber = [NSString stringWithCString:information[7].c_str() encoding:[NSString defaultCStringEncoding]];
    //
    //    return idcard;
}
-(NSMutableArray *)converFromVector:(std::vector<cv::Mat>) vec{
    NSMutableArray *arr = [NSMutableArray array];
    for (auto i : vec) {
        UIImage *image = [MatAndUIImageTool imageWithCVMat :i];
        [arr addObject:image];
    }
    return arr;
}
-(std::vector<cv::Mat>)converFromeArray:(NSArray *) arr{
    std::vector<cv::Mat> vec;
    for (UIImage* image in  arr) {
        cv::Mat imageMat = [MatAndUIImageTool UIImageToCvMat:image];
        vec.push_back(imageMat);
    }
    return vec;
}
@end

