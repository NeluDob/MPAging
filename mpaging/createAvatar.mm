/*
 Copyright(C) 2013-2014 MotionPortrait, Inc. All Rights Reserved.
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it.
 */

#import "createAvatar.h"
#import "messageBox.h"
#import "imageUtil.h"
#include "mpsynth.h"


@implementation createAvatar {
    NSString *agingSkin_;
    NSString *agingMask_;

    int usrImageW_, usrImageH_;
    unsigned char *usrImage_;
    UIActivityIndicatorView  *indicator_;
    UIPopoverController *popover_;
}

@synthesize delegate = _delegate;

- (id)init {
    return self;
}

- (void)createAvatar:(UIImage *)image skin:(NSString *)pathSkin maskOut:(NSString *)pathMask {
    
    agingSkin_ = [[NSString alloc] initWithString:pathSkin];
    agingMask_ = [[NSString alloc] initWithString:pathMask];
    
    usrImageW_ = image.size.width;
    usrImageH_ = image.size.height;
    
    CGImageRef inCgImage = [image CGImage];
    size_t bytesPerRow = CGImageGetBytesPerRow(inCgImage);
    CGDataProviderRef inDataProvider = CGImageGetDataProvider(inCgImage);
    CFDataRef inData = CGDataProviderCopyData(inDataProvider);
    UInt8 *inPixels = (UInt8*)CFDataGetBytePtr(inData);
    
    if((usrImage_ = (unsigned char *)malloc(usrImageW_ * usrImageH_ * 3)) == NULL) {
        CFRelease(inData);
        return;
    }
    for(int y=0; y!=usrImageH_; ++y){
        for(int x = 0; x!=usrImageW_; ++x){
            UInt8* buf = inPixels + y * bytesPerRow + x * 4;
            usrImage_[(y*usrImageW_+x)*3+0] = buf[0];
            usrImage_[(y*usrImageW_+x)*3+1] = buf[1];
            usrImage_[(y*usrImageW_+x)*3+2] = buf[2];
        }
    }
    
    CFRelease(inData);
    [NSThread detachNewThreadSelector:@selector(createFaceData) toTarget:self withObject:nil];
}

-(void) createFaceData {
    
    motionportrait::MpSynth *synth = new motionportrait::MpSynth();
    motionportrait::mpFaceObject faceObject;
    
    //
    // initialize Synthesizer
    //
    NSString *str = [[[NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/resource/res"];
    int stat = synth->Init([str UTF8String]);
    if(stat) {
        [messageBox showMessage:@"Cannot initialize recogintion machine." title:@"Internal error"];
        return;
    }
    
    //
    // detect face
    //
    motionportrait::MpSynth::Img inImg;;
    inImg.w = usrImageW_;
    inImg.h = usrImageH_;
    inImg.rgb = usrImage_;
    inImg.alpha = NULL;
    stat = synth->Detect(inImg);
    if(stat) {
        [messageBox showMessage:@"Facial recognition is not possible with this photo." title:@"Cannot make avatar"];
        
    } else {
        
        // get Mpfp - MP Feature Point
        motionportrait::MpSynth::Mpfp mpfp;
        synth->GetMpfp(mpfp);
        
        //
        // synthesize
        //
        synth->SetParami(motionportrait::MpSynth::OUTPUT_FORMAT, motionportrait::MpSynth::FORMAT_BIN) ;
        synth->SetParami(motionportrait::MpSynth::TEX_SIZE, 512) ;
        synth->SetParami(motionportrait::MpSynth::MODEL_SIZE, 256) ;
        synth->SetParamf(motionportrait::MpSynth::FACE_SIZE, 0.6) ;
        synth->SetParamf(motionportrait::MpSynth::FACE_POS, 0.5) ;
        synth->SetParami(motionportrait::MpSynth::CROP_MARGIN, 1);
        synth->SetMpfp(mpfp);
        stat = synth->Synth(inImg, &faceObject);
        
        if(stat) {
            [messageBox showMessage:@"avatar synthesize faild." title:@"Cannot make avatar"];
        } else {
            //
            // gen aging mask
            //
            NSString *skinY = [agingSkin_ stringByAppendingString:@"/young_skin"];
            NSString *skinO = [agingSkin_ stringByAppendingString:@"/old_skin"];
            NSString *maskY = [agingMask_ stringByAppendingString:@"_young"];
            NSString *maskO = [agingMask_ stringByAppendingString:@"_old"];
            synth->SetMpfp(mpfp);
            stat |= synth->GenAgingMask(inImg, [skinY UTF8String], [maskY UTF8String]);
            synth->SetMpfp(mpfp);
            stat |= synth->GenAgingMask(inImg, [skinO UTF8String], [maskO UTF8String]);
        }
    }
    
    delete synth;
    free(usrImage_);
    
    [self createAvatarDone:(stat == 0)? faceObject : NULL];
}

- (void)createAvatarDone:(motionportrait::mpFaceObject)faceObject {
    if ([_delegate respondsToSelector:@selector(genAvatarDone:)])
        [_delegate genAvatarDone:faceObject];
}


@end
