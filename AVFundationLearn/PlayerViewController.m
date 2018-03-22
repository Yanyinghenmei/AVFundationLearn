//
//  PlayerViewController.m
//  AVFundationLearn
//
//  Created by WeiLuezh on 2018/3/22.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "PlayerViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerViewController ()
@property (nonatomic, strong)AVPlayer *player;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    
    UIView *playView = [[UIView alloc] initWithFrame:CGRectMake(45, 100, self.view.frame.size.width-90, self.view.frame.size.height-200)];
    [self.view addSubview:playView];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = playView.bounds;
    [playView.layer addSublayer:playerLayer];
    
    [self.player play];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] initWithURL:_videoUrl];
    }
    return _player;
}

- (void)dealloc {
    _player = nil;
}

@end
