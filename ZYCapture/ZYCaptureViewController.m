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

#define ShapeLayerlineWidth     5
#define ShapeLayerBgW           70.00
#define ShapeLayerWidth         ShapeLayerBgW - ShapeLayerlineWidth
#define LargeShapeLayerW        90.00
#define TouchViewW              60.00
#define EnlargeScale            LargeShapeLayerW/ShapeLayerBgW
#define ReductionScale          ShapeLayerBgW/LargeShapeLayerW

@interface ZYCaptureViewController ()<AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) CAShapeLayer *progressCircleLayer;
@property (nonatomic, strong) UIView *cirProgressBgView;
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
    _movieOutput.maxRecordedDuration = CMTimeMake(_maxRecordTime * 20, 20);
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
    _cirProgressBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ShapeLayerBgW, ShapeLayerBgW)];
    _cirProgressBgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    _cirProgressBgView.layer.cornerRadius = ShapeLayerBgW/2;
    _cirProgressBgView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height-100-ShapeLayerBgW/2);
    [self.view addSubview:_cirProgressBgView];
    
    
    _progressCircleLayer = [CAShapeLayer layer];
    //创建出圆形贝塞尔曲线
    UIBezierPath *circlePath;
    CGRect progressRect = CGRectMake(0, 0, ShapeLayerWidth, ShapeLayerWidth);
    _progressCircleLayer.frame = progressRect;
    
    circlePath = [UIBezierPath bezierPathWithOvalInRect:progressRect];
    _progressCircleLayer.position = CGPointMake(_cirProgressBgView.frame.size.width/2,
                                                _cirProgressBgView.frame.size.height/2);
    _progressCircleLayer.fillColor = [UIColor clearColor].CGColor;//填充颜色为ClearColor
    _progressCircleLayer.strokeStart = 0.0f;
    _progressCircleLayer.strokeEnd = 0.0f;
    
    //设置线条的宽度和颜色
    _progressCircleLayer.lineWidth = ShapeLayerlineWidth;
    _progressCircleLayer.strokeColor = [UIColor whiteColor].CGColor;
    
    
    //让贝塞尔曲线与CAShapeLayer产生联系
    _progressCircleLayer.path = circlePath.CGPath;
    
    CATransform3D transfrom = CATransform3DIdentity;
    _progressCircleLayer.transform = CATransform3DRotate(transfrom, -M_PI/2, 0, 0, 1);
    //添加并显示
    [_cirProgressBgView.layer addSublayer:_progressCircleLayer];
    
    touchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TouchViewW, TouchViewW)];
    touchView.backgroundColor = [UIColor whiteColor];
    touchView.center = _cirProgressBgView.center;
    [self.view addSubview:touchView];
    
    touchView.layer.cornerRadius = TouchViewW/2;
    touchView.layer.masksToBounds = true;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([touches anyObject].view == touchView) {
        // 开始录制
        [UIView animateWithDuration:0.3 animations:^{
            _cirProgressBgView.transform = CGAffineTransformScale(_cirProgressBgView.transform, EnlargeScale, EnlargeScale);
        } completion:^(BOOL finished) {
            [self startProgressAnimatin];
            
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
        }];
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
    
    // 停止动画
    [self endProgressAnimatin];
    [UIView animateWithDuration:0.3 animations:^{
        _cirProgressBgView.transform = CGAffineTransformScale(_cirProgressBgView.transform, ReductionScale, ReductionScale);
    }];
    
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




- (void)startProgressAnimatin {
    
    // 创建Animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @(0);
    animation.toValue = @(1);
    animation.duration = self.maxRecordTime;
    self.progressCircleLayer.autoreverses = NO;
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    
    [_progressCircleLayer addAnimation:animation forKey:@"strokeEnd"];
}
    
- (void)endProgressAnimatin {
    [_progressCircleLayer removeAnimationForKey:@"strokeEnd"];
}








@end
