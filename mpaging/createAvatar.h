/*
 Copyright(C) 2013-2014 MotionPortrait, Inc. All Rights Reserved.
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it.
 */

#import <Foundation/Foundation.h>
#include "mptypes.h"


@protocol createAvatarDelegate
- (void)genAvatarDone:(motionportrait::mpFaceObject)faceObject;
@end

@interface createAvatar : NSObject {
    id _delegate;  
}

@property (nonatomic) id delegate;


- (id)init;
- (void)createAvatar:(UIImage *)image skin:(NSString *)pathSkin maskOut:(NSString *)pathMask;

@end
