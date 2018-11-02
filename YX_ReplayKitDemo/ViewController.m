//
//  ViewController.m
//  YX_ReplayKitDemo
//
//  Created by qiu on 2018/8/31.
//  Copyright © 2018年 qiu. All rights reserved.
//

#import "ViewController.h"
#import "YX_ReplayManager.h"
#import <ReplayKit/ReplayKit.h>
#import "MBProgressHUD+Message.h"
#import "RPPreviewViewController+MovieURL.h"

@interface ViewController ()<RPScreenRecorderDelegate>
/**
 录屏是否成功启动
 */
@property (nonatomic,assign) BOOL REC_StartOK;

/**
 是否是在允许录制的情况下在录制
 */
@property (nonatomic,assign) BOOL canRecord;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    UIButton *btn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [btn setBackgroundColor:[UIColor greenColor]];
    [btn addTarget:self action:@selector(photo_Available) forControlEvents:(UIControlEventTouchUpInside)];
    btn.frame = CGRectMake(100, 100, 100, 100);
    [self.view addSubview:btn];
    
    UIButton *btn_stop = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [btn_stop setBackgroundColor:[UIColor redColor]];
    [btn_stop addTarget:self action:@selector(handleStopBtn) forControlEvents:(UIControlEventTouchUpInside)];
    btn_stop.frame = CGRectMake(100, 300, 100, 100);
    [self.view addSubview:btn_stop];
    
    //
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 500, 100, 100)];
    view.backgroundColor = [UIColor orangeColor];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragView:)];
    [view addGestureRecognizer:pan];
    [self.view addSubview:view];
}

#pragma mark 一个小动画拖拽view
- (void)dragView:(UIPanGestureRecognizer *)pan {
    CGPoint point = [pan translationInView:self.view];
    pan.view.center = CGPointMake(pan.view.center.x + point.x, pan.view.center.y + point.y);
    [pan setTranslation:CGPointMake(0, 0) inView:self.view];
}

#pragma mark 点击了停止
- (void)handleStopBtn {
    [self stopREC_WithSave:YES alert:YES tryAgain:NO];
}

#pragma mark 相册权限
- (void)photo_Available {
    BOOL photo_able = [YX_ReplayManager detectionPhotoState:^{
        [self REC_Available];
    }];
    if (photo_able) {
        [self REC_Available];
    }
}

#pragma mark 录屏是否可用
- (void)REC_Available {
    dispatch_async(dispatch_get_main_queue(), ^{
        RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
        if ([recorder isAvailable] && [YX_ReplayManager systemVersionIsAvailable]) {
            if ([YX_ReplayManager systemVersionIsRisk]) {
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"您的系统版本小于10.2,如果录屏存在问题请使用版本较高的系统" preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *sureAct = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    [self REC_PermissionsAlert];
                }];
                [alertVC addAction:sureAct];
                [self presentViewController:alertVC animated:YES completion:nil];
            } else {
                [self REC_PermissionsAlert];
            }
        } else {
            [self alertWindowWithMessage:@"您的手机系统版本低于9.0，无法进行屏幕录制操作，请升级手机系统" actionName:nil];
        }
    });
}

#pragma mark 权限提示
- (void)REC_PermissionsAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请允许App录制屏幕且使用麦克风(选择第一项),否则无法进行录屏。录屏完成后如果出现访问相册提示请点击允许,否则无法保存录屏信息" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *sureAct = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [self performSelector:@selector(startREC) withObject:nil afterDelay:1.0];
        }];
        [alertVC addAction:sureAct];
        [self presentViewController:alertVC animated:YES completion:nil];
    });
}

#pragma mark 开始录制
- (void)startREC {
    self.canRecord = YES;
    __weak typeof (self)weakSelf = self;
    RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
    recorder.delegate = self;
    
    if ([recorder isRecording]) {
        NSLog(@"正在录制");
        [self stopREC_WithSave:NO alert:NO tryAgain:NO];
    }
    
        recorder.microphoneEnabled = YES;
        if (@available(iOS 10.0, *)) {
            [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
                if (!error) {
                    weakSelf.REC_StartOK = YES;
                    if (!weakSelf.canRecord) {
                        [weakSelf stopREC_WithSave:NO alert:NO tryAgain:YES];
                    }
                    NSLog(@"===启动成功");
                }
            }];
        } else {
            if (@available(iOS 9.0, *)) {
                [recorder startRecordingWithMicrophoneEnabled:YES handler:^(NSError * _Nullable error) {
                    if (!error) {
                        weakSelf.REC_StartOK = YES;
                        if (!weakSelf.canRecord) {
                            [weakSelf stopREC_WithSave:NO alert:NO tryAgain:YES];
                        }
                        NSLog(@"===启动成功");
                    }
                }];
            }
        }
    
    [MBProgressHUD showMessage:@"请等待5秒正在检测录屏是否启动成功"];
    [self performSelector:@selector(REC_StartResult) withObject:nil afterDelay:5.0];
}

#pragma mark 5秒之后判断录屏启动状态，防止某些版本出现未知问题无法启动REC,只要5秒之后 REC_StartOK 为NO 就认为启动失败
- (void)REC_StartResult {
    RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
    [MBProgressHUD hideHUD];
    if (!self.REC_StartOK) {
        if (recorder.isRecording) {
            [self stopREC_WithSave:NO alert:NO tryAgain:NO];
        } else {
            [self alertWindowWithMessage:@"屏幕录制启动失败,可能由于您未及时点击允许录屏和使用麦克风或者您当前的系统版本过低,建议再次发起或者升级系统，建议系统版本在10.3以上" actionName:nil];
        }
    } else {
        NSLog(@"已经开始录屏");
    }
    self.REC_StartOK = NO;
    self.canRecord = NO;
}

#pragma mark 结束录制
- (void)stopREC_WithSave:(BOOL)save alert:(BOOL)alert tryAgain:(BOOL)tryAgain {
    NSLog(@"结束开始");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            NSLog(@"结束回调");
            if (error && alert && !tryAgain) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self alertWindowWithMessage:error.description actionName:nil];
                    [self detailREC_VideoNotFound];
                });
                return ;
            }
            
            if (tryAgain) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD showError:@"您没有在5秒内允许录屏和使用麦克风,请再次发起" toView:nil];
                    return;
                });
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([previewViewController respondsToSelector:@selector(movieURL)]) {
                    NSURL *videoURL = [previewViewController.movieURL copy];
                    if (!videoURL) {
                        [self detailREC_VideoNotFound];
                    } else {
                        if (save) {
                            BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([videoURL path]);
                            if (compatible)
                            {
                                UISaveVideoAtPathToSavedPhotosAlbum([videoURL path], self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
                            }
                        }
                    }
                }
            });
            
            
        }];
    });
}

//保存视频完成之后的回调
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError: (NSError *)error contextInfo: (void *)contextInfo {
    if (error) {
        NSLog(@"保存视频失败%@", error.description);
        [self alertWindowWithMessage:@"保存相册失败" actionName:nil];
    }
    else {
        //取出这个视频
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]]; //按创建日期获取
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        PHAsset *phasset = [assetsFetchResults lastObject];
        if (phasset) {
            if (phasset.mediaType == PHAssetMediaTypeVideo) {
                //是视频文件
                PHImageManager *manager = [PHImageManager defaultManager];
                [manager requestAVAssetForVideo:phasset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    
                    //此处再次判断这个视频文件的时间防止误传,以5分钟为界限
                    if (![self videoTimeCheck:asset.creationDate.dateValue]) {
                        [self alertWindowWithMessage:@"获取不到刚才的录屏文件，请重试，如果多次出现请更换手机" actionName:nil];
                        return ;
                    }
                    
                    NSURL *videoURL = urlAsset.URL;
                    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
                    NSTimeInterval time = [date timeIntervalSince1970] * 1000;
                    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
                    NSString *fileName = [NSString stringWithFormat:@"%@_%@",@"tmp",timeString];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD showMessage:@"正在压缩视频,请稍后"];
                        NSString *outPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[fileName stringByAppendingString:@".mp4"]];
                        [YX_ReplayManager compressQuailtyWithInputURL:videoURL outputURL:[NSURL fileURLWithPath:outPath] blockHandler:^(AVAssetExportSession *session) {
                            if (session.status==AVAssetExportSessionStatusCompleted) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [MBProgressHUD hideHUD];
                                    //视频已处理好可以对其进行操作
                                    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:outPath]];
                                    if (data) {
                                        [self alertWindowWithMessage:@"视频已经处理好" actionName:nil];
                                    }
                                    
                                });
                            }else{
                                [MBProgressHUD hideHUD];
                                [self alertWindowWithMessage:[NSString stringWithFormat:@"压缩视频文件出错%@",session.error] actionName:nil];
                            }
                        }];
                    });
                    
                }];
            } else {
                [self alertWindowWithMessage:@"未成功保存视频" actionName:nil];
            }
        } else {
            [self alertWindowWithMessage:@"未成功保存视频" actionName:nil];
        }
    }
}

#pragma mark 处理视频不存在的情况
- (void)detailREC_VideoNotFound {
    [self alertWindowWithMessage:@"录屏失败,如果您的系统版本低于10.2,请升级系统版本再试;如果您的系统版本为11.4或者更高且之前成功录制过视频请重启手机重试" actionName:nil];
}

#pragma mark 弹窗
- (void)alertWindowWithMessage:(NSString *)message actionName:(NSString *)actName {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
        if (actName) {
            SEL actionSEL = NSSelectorFromString(actName);
            //            if ([self respondsToSelector:@selector(actionSEL)]) {
            [self performSelector:actionSEL];
            //            }
        }
    }];
    [alertVC addAction:sureAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark 判断取出的视频文件是不是在规定时间之内录制的
- (BOOL)videoTimeCheck:(NSDate *)videoDate {
    //
    if (!videoDate) {
        //特殊情况备注
        return YES;
    }
    
    //判断是否在5分钟之内录制
    BOOL timeOK = [YX_ReplayManager GetTimeChange:videoDate];
    return timeOK;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
