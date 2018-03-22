//
//  FileOutCaptureViewController.m
//  AVFundationLearn
//
//  Created by WeiLuezh on 2018/3/17.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "FileOutCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PlayerViewController.h"

@interface FileOutCaptureViewController ()<AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong)UIImageView *bgImgView;

//后台任务标识
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, strong)AVCaptureSession *recordSession;
@property (nonatomic, strong)AVCaptureDevice *backCamera;

@property (nonatomic, strong)AVCaptureDeviceInput *backCameraInput;
@property (nonatomic, strong)AVCaptureDeviceInput *audiolInput;
@property (nonatomic, strong)AVCaptureMovieFileOutput *captureMovieOutput;

// 预览层
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;

// 视频路径
@property (nonatomic, strong)NSURL *videoUrl;

// 开始按钮
@property (nonatomic, strong)UIView *startBtn;
@end

@implementation FileOutCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    _bgImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_bgImgView];
    _bgImgView.backgroundColor = [UIColor orangeColor];
    
    [self setUI];
    
    _recordSession = [AVCaptureSession new];
    if (!_recordSession) {
        NSLog(@"AVCaptureSession 初始化失败");
        return;
    }
    // 设置分辨率
    if ([_recordSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        _recordSession.sessionPreset = AVCaptureSessionPresetHigh;
    } else {
        return;
    }
    // 后置摄像头作为输入
    if ([_recordSession canAddInput:self.backCameraInput]) {
        [_recordSession addInput:self.backCameraInput];
    }
    // 添加音频输入
    if ([_recordSession canAddInput:self.audiolInput]) {
        [_recordSession addInput:self.audiolInput];
    }
    // 讲输出设备添加到会话
    _captureMovieOutput = [AVCaptureMovieFileOutput new];
    if ([_recordSession canAddOutput:_captureMovieOutput]) {
        [_recordSession addOutput:_captureMovieOutput];
        
        // 设置视频防抖
        AVCaptureConnection *connection = [_captureMovieOutput connectionWithMediaType:AVMediaTypeAudio];
        if ([connection isVideoStabilizationSupported]) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
    }
    
    // 创建预览层, 用于实时展示摄像头状态
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_recordSession];
    self.previewLayer.frame = self.bgImgView.bounds;
    // 填充模式
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.bgImgView.layer addSublayer:self.previewLayer];
    
    [_recordSession startRunning];
}

// 开始录制
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([[touches anyObject] view] == self.startBtn) {
        // 根据设备获取连接
        AVCaptureConnection *connection = [self.captureMovieOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // 根据连接获得设备输出数据
        
        // 如果不在录制中
        if (![self.captureMovieOutput isRecording]) {
            
            if (self.videoUrl) {
                [[NSFileManager defaultManager] removeItemAtURL:self.videoUrl error:nil];
            }
            
            // 预览图层和视频方向保持一致
            connection.videoOrientation = [self.previewLayer connection].videoOrientation;
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingString:@"myMovie.mov"];
            NSLog(@"video path is : %@", outputFilePath);
            NSURL *fileUrl = [NSURL fileURLWithPath:outputFilePath];
            NSLog(@"file url is : %@", fileUrl);
            
            [self.captureMovieOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
        }
        // 在录制中->停止录制
        else {
            [self.captureMovieOutput stopRecording];
        }
    }
}

// 停止录制
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([[touches anyObject] view] == self.startBtn) {
        [self.captureMovieOutput stopRecording];
    }
}

#pragma mark -- AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    NSLog(@"开始录制");
}
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    NSLog(@"录制完成");
    self.videoUrl = outputFileURL;
    
    
    // 播放
    PlayerViewController *playVC = [PlayerViewController new];
    playVC.videoUrl = self.videoUrl;
    playVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:playVC animated:true completion:nil];
}

/*==============================================================*/

- (void)setUI {
    CGFloat bottomH = 100;
    CGFloat bottomY = self.view.frame.size.height - bottomH;
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, bottomY, self.view.frame.size.width, bottomH)];
    [self.view addSubview:bottomView];
    bottomView.backgroundColor = [UIColor blackColor];
    
    _startBtn = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    _startBtn.center = CGPointMake(bottomView.frame.size.width/2,
                                   bottomView.frame.size.height/2);
    _startBtn.backgroundColor = [UIColor whiteColor];
    [bottomView addSubview:_startBtn];
}


- (AVCaptureDeviceInput *)audiolInput {
    if (!_audiolInput) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audiolInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (error) {
            NSLog(@"获取音频设备失败");
        }
    }
    return _audiolInput;
}

- (AVCaptureDeviceInput *)backCameraInput {
    if (!_backCameraInput) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        NSError *error;
        _backCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败");
        }
    }
    return _backCameraInput;
}

@end
