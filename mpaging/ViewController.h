/*
 Copyright(C) 2011-2014 MotionPortrait, Inc. All Rights Reserved.
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it.
 */

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

@property (weak, nonatomic) IBOutlet UINavigationBar *naviBar;
@property (weak, nonatomic) IBOutlet UIButton *btAging;
@property (weak, nonatomic) IBOutlet UISlider *agingSlider;

@property (strong, nonatomic) IBOutlet UILabel *lbColor;
@property (strong, nonatomic) IBOutlet UISlider *colorSlider;


- (IBAction)agingButton:(id)sender;
- (IBAction)showAging:(id)sender;
- (IBAction)showColor:(id)sender;

@end
