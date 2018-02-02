/*
 Copyright(C) 2013-2014 MotionPortrait, Inc. All Rights Reserved.
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it.
 */

#import "imagePick.h"
#import "imageUtil.h"
#import "messageBox.h"
#import <AVFoundation/AVFoundation.h>


@implementation imagePick {
    BOOL deviceiPad_;
    UIViewController *myView_;
    UIPopoverController *popover_;
    UIImagePickerController *imgPkr_;
}

@synthesize delegate = _delegate;


- (void)pickImage:(BOOL)isCameraImage view:(UIViewController *)view {
    
    deviceiPad_ = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)? YES: NO;

    myView_ = view;
    
    imgPkr_ = [[UIImagePickerController alloc]init];
    UIImagePickerControllerSourceType source;
    
    if(isCameraImage) {        // camera
        source = UIImagePickerControllerSourceTypeCamera;
        if(![UIImagePickerController isSourceTypeAvailable:source]){
            [messageBox showMessage:@"No compatible camera available" title:@"MP Sample"];
            [self pickDone:nil];
            return;
        }
        if([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
            [messageBox showMessage:@"Can't access camera. Please check your private setting" title:@"MP Sample"];
            [self pickDone:nil];
            return;
        }
        imgPkr_.sourceType = source;
        imgPkr_.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else { // photo lib
        source = UIImagePickerControllerSourceTypePhotoLibrary;
        if(![UIImagePickerController isSourceTypeAvailable:source]){
            [messageBox showMessage:@"No gallery available" title:@"MP Sample"];
            [self pickDone:nil];
            return;
        }
        imgPkr_.sourceType = source;
    }
    imgPkr_.delegate = (id)self;
    
    if(deviceiPad_) {
        popover_ = [[UIPopoverController alloc] initWithContentViewController:imgPkr_];
        popover_.delegate = (id)self;
        [popover_ presentPopoverFromRect:[view.view superview].frame
                                  inView:view.view
                permittedArrowDirections:0 /*UIPopoverArrowDirectionUp*/
                                animated:YES];
    } else
        [view presentViewController:imgPkr_ animated:YES completion: nil];
}

- (void)imagePickerController:(UIImagePickerController*)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    
    if(deviceiPad_) {
        NSMutableArray *lockViews=[[NSMutableArray alloc]init];
        [lockViews addObject:[myView_.view superview]];
        popover_.passthroughViews=lockViews;
        [popover_ dismissPopoverAnimated:YES];
        popover_ = nil;
        [self pickDone:[imageUtil fixrotation:image]];
    } else
        [myView_ dismissViewControllerAnimated:YES completion:^{
            [self pickDone:[imageUtil fixrotation:image]];
        }];
}

// cancel for iPad
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    popover_ = nil;
    [self pickDone:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
    if(deviceiPad_) {
        // in iOS7, popover has Cancel button,
        // and when that is pushed, this method is called.
        [popover_ dismissPopoverAnimated:YES];
        popover_ = nil;
    }else{
        [myView_ dismissViewControllerAnimated:YES completion:nil];
    }
    [self pickDone:nil];
}

- (void)pickDone:(UIImage *)img {
    if([_delegate respondsToSelector:@selector(imagePickDone:)])
        [_delegate imagePickDone:img];
}
@end
