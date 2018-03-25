//
//  ZYCaptureViewController.m
//  AVFundationLearn
//
//  Created by Daniel on 2018/3/24.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "ZYCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZYCaptureDeviceManager.h"
#import "PlayerViewController.h"

@interface ZYCaptureViewController ()<AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) dispatch_queue_t videoQueue;

@property (nonatomic, strong) AVCaptureSession*captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *cameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) NSURL *videoUrl;

@end

@implementation ZYCaptureViewController {
    UIView *touchView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _captureSession = [AVCaptureSession new];
    
    // 设置分辨率
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    // 后置摄像头
    AVCaptureDevice *backCamera = [ZYCaptureDeviceManager deviceWithMediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    if (!backCamera) {
        NSLog(@"获取后置摄像头失败");
        return;
    }
    
    NSError *error;
    _cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    if (error) {
        NSLog(@"获取后置摄像头失败");
        return;
    }
    if ([_captureSession canAddInput:_cameraInput]) {
        [_captureSession addInput:_cameraInput];
    }
    
    // 麦克风
    AVCaptureDevice *audioDevice = [ZYCaptureDeviceManager deviceWithMediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified];
    if (!audioDevice) {
        NSLog(@"获取麦克风失败");
        return;
    }
    error = nil;
    _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"获取麦克风失败");
        return;
    }
    
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
    }
    
    // 添加输出
    _movieOutput = [AVCaptureMovieFileOutput new];
    _movieOutput.maxRecordedDuration = CMTimeMakeWithSeconds(self.maxRecordTime+1, 1);
    if ([_captureSession canAddOutput:_movieOutput]) {
        [_captureSession addOutput:_movieOutput];
    }
    
    // 视频防抖
    AVCaptureConnection *connection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoStabilizationSupported) {
        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    }
    
    // 预览层
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.frame = self.view.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer addSublayer:_previewLayer];
    
    
    _videoQueue = dispatch_queue_create("zy.videoQueue", NULL);
    
    [self setUI];
    
    dispatch_async(_videoQueue, ^{
        [_captureSession startRunning];
    });
}

- (void)setUI {
    touchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    touchView.backgroundColor = [UIColor whiteColor];
    touchView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height-120-60/2);
    [self.view addSubview:touchView];
    
    touchView.layer.cornerRadius = 30;
    touchView.layer.masksToBounds = true;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([touches anyObject].view == touchView) {
        // 开始录制
        AVCaptureConnection *connection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
        if (!_movieOutput.isRecording) {
            if (_videoUrl) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtURL:_videoUrl error:&error];
                if (error) {
                    NSLog(@"删除视频失败");
                    return;
                } else {
                    _videoUrl = nil;
                }
            }
            connection.videoOrientation = self.previewLayer.connection.videoOrientation;
            
            NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:@"myMovie.mov"];
            NSLog(@"output paht is : %@", outputFielPath);
            NSURL *outputUrl = [NSURL fileURLWithPath:outputFielPath];
            [self.movieOutput startRecordingToOutputFileURL:outputUrl recordingDelegate:self];
        } else {
            [_movieOutput stopRecording];
        }
    }
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([touches anyObject].view == touchView) {
        // 停止录制
        if (_movieOutput.isRecording) {
            [self.movieOutput stopRecording];
        }
    }
}

#pragma mark -- AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    NSLog(@"开始录制");
}
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    if (error) {
        NSLog(@"%@", [error.userInfo objectForKey:@"NSLocalizedFailureReason"]);
    }
    // 录制完成
    _videoUrl = outputFileURL;
    // 播放
    PlayerViewController *playVC = [PlayerViewController new];
    playVC.videoUrl = self.videoUrl;
    playVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:playVC animated:true completion:nil];
}

- (NSTimeInterval)maxRecordTime {
    if (!_maxRecordTime) {
        _maxRecordTime = 10;
    }
    return _maxRecordTime;
}
- (void)dealloc {
    dispatch_async(_videoQueue, ^{
        [_captureSession stopRunning];
    });
}




// 改变摄像头
- (void)changeCamera {
    
}













@end
