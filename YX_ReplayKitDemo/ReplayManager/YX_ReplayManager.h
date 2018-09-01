//
//  YX_ReplayManager.h
//  YX_ReplayKitDemo
//
//  Created by qiu on 2018/8/31.
//  Copyright © 2018年 qiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

@interface YX_ReplayManager : NSObject

/**
 系统版本是否可用
 
 @return yes or no
 */
+ (BOOL)systemVersionIsAvailable;

/**
 系统版本是否存在支持风险(ReplayKit虽然在9.0以后都支持，但是个别系统版本会出现奇怪的情况，同样的代码运行在不同版本的手机上较低版本的手机可能无法初始化，录制黑屏等情况，所以再次加一次判断，此处仅提示，不做强制要求，目前比较稳定的系统在10.3+)
 
 @return yes or no
 */
+ (BOOL)systemVersionIsRisk;

/**
 相册权限检测

 @param authorizedResultBlock 获得权限后回调
 @return 是否已经获得权限
 */
+ (BOOL)detectionPhotoState:(void(^)(void))authorizedResultBlock;

/**
 视频压缩

 @param inputURL 输入源路径
 @param outputURL 输出源路径
 @param handler 回调
 */
+ (void)compressQuailtyWithInputURL:(NSURL*)inputURL
                          outputURL:(NSURL*)outputURL
                       blockHandler:(void (^)(AVAssetExportSession *))handler;

@end
