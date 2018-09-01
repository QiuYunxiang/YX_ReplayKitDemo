//
//  MBProgressHUD+Message.h
//  chedaibao
//
//  Created by 邱云翔 on 16/12/12.
//  Copyright © 2016年 jiawo. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (Message)
+ (void)showSuccess:(NSString *)success;
+ (void)showSuccess:(NSString *)success toView:(UIView *)view;

+ (void)showError:(NSString *)error;
+ (void)showError:(NSString *)error toView:(UIView *)view;

+ (MBProgressHUD *)showMessage:(NSString *)message;
+ (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view;

+ (void)hideHUD;
+ (void)hideHUDForView:(UIView *)view;
@end
