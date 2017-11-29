//
//  LF_idCardModel.h
//  smartIDCardCropper
//
//  Created by slimdy on 2017/11/24.
//  Copyright © 2017年 slimdy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LF_idCardModel : NSObject
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *gender;
@property (nonatomic,copy) NSString *race;
@property (nonatomic,copy) NSString *birthYear;
@property (nonatomic,copy) NSString *birthMonth;
@property (nonatomic,copy) NSString *birthDay;
@property (nonatomic,copy) NSString *address;
@property (nonatomic,copy) NSString *idNumber;
@end
