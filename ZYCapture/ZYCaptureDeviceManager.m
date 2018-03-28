//
//  ZYCaptureDeviceManager.m
//  AVFundationLearn
//
//  Created by Daniel on 2018/3/24.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "ZYCaptureDeviceManager.h"

@implementation ZYCaptureDeviceManager

+ (AVCaptureDevice *)deviceWithMediaType:(AVMediaType)mediaType
                                position:(AVCaptureDevicePosition)position {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
#pragma clang diagnostic pop
    
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}


@end
