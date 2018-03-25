//
//  ZYCaptureDeviceManager.h
//  AVFundationLearn
//
//  Created by Daniel on 2018/3/24.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ZYCaptureDeviceManager : NSObject

+ (AVCaptureDevice *)deviceWithMediaType:(AVMediaType)mediaType
                                position:(AVCaptureDevicePosition)position;
@end
