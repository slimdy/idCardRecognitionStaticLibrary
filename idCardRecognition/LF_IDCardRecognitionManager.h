//
//  LF_IDCardRecognitionManager.h
//  LF_IDCardRecognitionManager
//
//  Created by slimdy on 2017/11/27.
//  Copyright © 2017年 slimdy. All rights reserved.
//

#import <UIKit/UIKit.h>


@class LF_paramModel;
@class LF_idCardModel;
@interface LF_IDCardRecognitionManager : NSObject
@property (nonatomic,strong)NSArray *allImage;

+(instancetype)sharedManager;
-(BOOL)idCard:(UIImage *)OriginalImage isRightWith:(LF_paramModel *) param;
-(LF_idCardModel*)idCardInformationByTesseractOcrDataPath:(NSString*)dataPath;
-(LF_idCardModel*)idCardInformationByTesseractOcrDataPath:(NSString*)dataPath andImages:(NSArray*)images;
-(NSArray *) idCardCutIntoPieces:(UIImage*)beCutImage isCheckedImage:(BOOL) flag;
@end
