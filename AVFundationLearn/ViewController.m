//
//  ViewController.m
//  AVFundationLearn
//
//  Created by WeiLuezh on 2018/3/17.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "FileOutCaptureViewController.h"
#import "ZYCaptureViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
 
    
    
}


- (IBAction)fileOutCaptureClick:(id)sender {
    [self presentViewController:[FileOutCaptureViewController new]
                       animated:true completion:nil];
}


- (IBAction)zyCapture:(id)sender {
    ZYCaptureViewController *capVC = [ZYCaptureViewController new];
    capVC.maxRecordTime = 3;
    [self presentViewController:capVC
                       animated:true completion:nil];
}




- (void)speakWithString:(NSString *)string {
    AVSpeechSynthesizer *synthesizer = [AVSpeechSynthesizer new];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:string];
    // 语言类别, 不能识别返回nil
    AVSpeechSynthesisVoice *voiceType = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    if (!voiceType) {
        NSLog(@"language indentifier is wrong");
    }
    utterance.voice = voiceType;
    // utterance.rate *= 1.2;
    [synthesizer speakUtterance:utterance];
}

- (IBAction)speakClick:(id)sender {
    _textField.text.length?[self speakWithString:_textField.text]:NSLog(@"error: no content");
}


@end
