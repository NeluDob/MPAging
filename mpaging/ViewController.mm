/*
 Copyright(C) 2011-2014 MotionPortrait, Inc. All Rights Reserved.
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it.
 */

#import "ViewController.h"
#import "imagePick.h"
#import "createAvatar.h"
#import "messageBox.h"

#include <time.h>
#include <sys/timeb.h>
#include "mprender.h"
#include "mpface.h"
#include "mpsynth.h"
#include "mpctlanimation.h"
#include "mpctlitem.h"


#define NAME_AGING_MASK  "agingmask"

#define BG_R (0.4f)
#define BG_G (0.4f)
#define BG_B (0.4f)

#define INDICATOR_SIZE (50.0)

@interface ViewController () {
    
    // MP instance
    motionportrait::MpRender *render_;
    motionportrait::MpFace   *face_;
    
    // MP controller
    motionportrait::MpCtlAnimation *ctlAnim_;
    motionportrait::MpCtlItem      *ctlBeard_;
    
    // aging mask
    motionportrait::MpCtlItem::ItemId    agingMaskY_;
    motionportrait::MpCtlItem::ItemId    agingMaskO_;
    NSString *pathAgingMask_;
    
    BOOL dispMenu_;
    
    NSString *resourceTop_;
    
    UIActivityIndicatorView  *indicator_;
    imagePick *imgPick_;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (long)getmsec;
- (void)loadFace:(NSString *)file;
- (void)loadFaceObject:(motionportrait::mpFaceObject)faceObject;
- (void)loadYourAvatar:(NSValue*)value;
- (void)loadAgingMask:(NSString *)path;
- (void)loadItem:(NSString *)path ctl:(motionportrait::MpCtlItem *)ctl item:(motionportrait::MpCtlItem::ItemId *)item;
- (void)hideMenu:(BOOL)hide;
- (void)genAvatarDone:(motionportrait::mpFaceObject)faceObject;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // general initialization for OpenGLES 1.*
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    if (!self.context) {
        [messageBox showMessage:@"can't create ES context" title:@"MP Sample"];
        exit(1);
    }
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    dispMenu_ = true;
    
    resourceTop_ = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];

    agingMaskY_ = 0;
    agingMaskO_ = 0;
    
    // MpRender::Init() must be called before any MP functions
    render_ = new motionportrait::MpRender();
    render_->Init();
    
    render_->EnableDrawBackground(true);       // draw original photo as background
    
    // initialize MpFace instance
    face_ = new motionportrait::MpFace();
    
    // get controllers
    ctlAnim_ = face_->GetCtlAnimation();
    ctlBeard_ = face_->GetCtlItem(motionportrait::MpFace::ITEM_TYPE_BEARD);

    // Now you can load your face.
    NSString *str = [resourceTop_ stringByAppendingFormat:@"resource/face/face0.bin"];
    [self loadFace:str];
    
    // load aging mask
    str = [resourceTop_ stringByAppendingFormat:@"resource/aging/mask0"];
    [self loadAgingMask:str];
    
    // load expression
    str = [resourceTop_ stringByAppendingFormat:@"resource/aging/faceanim_HourFace.txt"];
    ctlAnim_->SetExprData((char *)[str UTF8String]);
    
    // prepare buttons
    [self.view addSubview:_btAging];
    [self.view addSubview:_agingSlider];
    [self.view addSubview:_lbColor];
    [self.view addSubview:_colorSlider];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (render_) {
        delete render_;
    }
    if (face_) {
        delete face_;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (long)getmsec
{
    static bool first = true;
    static double start;
    double now;
    struct timeb time;
    
    ftime(&time);
    now = (double)time.time * 1000 + time.millitm;
    if(first) {
        start = now;
        first = false;
    }
    return (long)(now - start);
}

// If you have no face, just load face specified by "file".
// If you have face already, you need to destory items, wig, glasses and beard.
// And then you can load new face.
- (void)loadFace:(NSString *)file {
    
    [EAGLContext setCurrentContext:self.context];

    //
    // close items
    //
    if (agingMaskY_) {
        ctlBeard_->Destroy(agingMaskY_);
        agingMaskY_ = 0;
    }
    if (agingMaskO_) {
        ctlBeard_->Destroy(agingMaskO_);
        agingMaskO_ = 0;
    }
    
    //
    // load face
    //
    int ret = face_->Load([file UTF8String]);
    if (ret) {
        [messageBox showMessage:[[NSString alloc] initWithFormat :
                          @"can't load specified face modle(%s)", [file UTF8String]]
                   title:@"MP Sample"];
        exit(1);
    }
    
    //
    // set face to renderer
    //
    render_->SetFace(face_);
    
    // set neck rotation parameters
    ctlAnim_->SetParamf(motionportrait::MpCtlAnimation::NECK_X_MAX_ROT, 2.0f);
    ctlAnim_->SetParamf(motionportrait::MpCtlAnimation::NECK_Y_MAX_ROT, 2.0f);
    ctlAnim_->SetParamf(motionportrait::MpCtlAnimation::NECK_Z_MAX_ROT, 0.3f);
}

- (void)loadFaceObject:(motionportrait::mpFaceObject)faceObject
{
    
    [EAGLContext setCurrentContext:self.context];

    //
    // close items
    //
    if (agingMaskY_) {
        ctlBeard_->Destroy(agingMaskY_);
        agingMaskY_ = 0;
    }
    if (agingMaskO_) {
        ctlBeard_->Destroy(agingMaskO_);
        agingMaskO_ = 0;
    }
    
    //
    // load face
    //
    int ret = face_->Load(faceObject);
    motionportrait::MpSynth::DestroyFaceBin(faceObject);
    if (ret) {
        [messageBox showMessage:@"can't load specified face object"
                          title:@"MP Sample"];
        exit(1);
    }
    
    //
    // set face to renderer
    //
    render_->SetFace(face_);
    
    // set neck rotation parameters
    ctlAnim_->SetParamf(motionportrait::MpCtlAnimation::NECK_X_MAX_ROT, 2.0f);
    ctlAnim_->SetParamf(motionportrait::MpCtlAnimation::NECK_Y_MAX_ROT, 2.0f);
    ctlAnim_->SetParamf(motionportrait::MpCtlAnimation::NECK_Z_MAX_ROT, 0.3f);
}

- (void)loadYourAvatar:(NSValue*)value {
    motionportrait::mpFaceObject faceObject = (motionportrait::mpFaceObject)[value pointerValue];

    //
    // load face
    //
    [self loadFaceObject:faceObject];
    
    //
    // load aging mask
    //
    [self loadAgingMask: pathAgingMask_];
    
    //
    //
    // load expression
    NSString *str = [resourceTop_ stringByAppendingFormat:@"resource/aging/faceanim_HourFace.txt"];
    ctlAnim_->SetExprData((char *)[str UTF8String]);
    
    _agingSlider.value = 0.5;
    _colorSlider.value = 1.0;
}

- (void)loadAgingMask:(NSString *)path {
    
    NSString *maskY = [path stringByAppendingFormat:@"_young"];
    NSString *maskO = [path stringByAppendingFormat:@"_old"];
    [self loadItem:maskY ctl:ctlBeard_ item:&agingMaskY_];
    [self loadItem:maskO ctl:ctlBeard_ item:&agingMaskO_];
    ctlBeard_->SetAlpha(agingMaskY_, 0.0f);
    ctlBeard_->SetAlpha(agingMaskO_, 0.0f);
}

- (void)loadItem:(NSString *)path ctl:(motionportrait::MpCtlItem *)ctl item:(motionportrait::MpCtlItem::ItemId *)item
{
    //
    // clean up previous item
    //
    if (*item) {
        ctl->UnsetItem(*item);
        ctl->Destroy(*item);
        *item = 0;
    }
    if (path == NULL) return;
    
    //
    // create item
    //
    *item = ctl->Create((char *)[path UTF8String]);
    if (*item == 0) {
        [messageBox showMessage:[[NSString alloc] initWithFormat :
                          @"can't load item(%s)", [path UTF8String]]
                   title:@"MP Sample"];
        exit(1);
    }
    
    //
    // bind item to avatar
    //
    ctl->SetItem(*item);
}

- (void)hideMenu:(BOOL)hide {
    _btAging.hidden = hide;
    _agingSlider.hidden = hide;
    _lbColor.hidden = hide;
    _colorSlider.hidden = hide;
}

- (void)genAvatarDone:(motionportrait::mpFaceObject)faceObject
{
    if(faceObject) {
        [self performSelectorOnMainThread:@selector(loadYourAvatar:)
                               withObject:[NSValue valueWithPointer:faceObject] waitUntilDone:NO];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideIndicator];
    });
}


#pragma mark - GLKView and GLKViewController delegate methods
- (void)update
{
}

// drawing MP face function(mpDraw)
// "mpAnimate" computes facial expressions at the time given(cTime).
// And draw it by "mpDraw"
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [EAGLContext setCurrentContext:self.context];
    
    int width = 0;
    int height = 0;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH,  &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    int screen = width;
    int xofst = 0;
    if(!dispMenu_) {
        screen = (int)(height * 0.9f);
        xofst = -(screen - width) / 2;
    }
    
    //
    // set viewport to MpRender
    //
    motionportrait::mpRect viewport;
    viewport.x = xofst;
    viewport.y = 0;
    viewport.width  = screen;
    viewport.height = screen;
    render_->SetViewport(viewport);
    
    motionportrait::MpCtlAnimation *anim = face_->GetCtlAnimation();
    long cTime = [self getmsec];
    
    glClearColor(BG_R, BG_G, BG_B, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //
    // update unconcious animation
    //
    anim->Update(cTime);

    //
    // render
    //
    render_->Draw();
}

- (IBAction)agingButton:(id)sender {
    UIActionSheet *sheet;
    
    sheet =[[UIActionSheet alloc]
            initWithTitle:@"Create avatar"
            delegate:(id)self
            cancelButtonTitle:@"Cancel"
            destructiveButtonTitle:nil
            otherButtonTitles:@"Camera", @"Gallery", nil];
    [sheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == [actionSheet cancelButtonIndex])
        return;
    
    BOOL isCameraImage = (buttonIndex == 0)? YES : NO;
    imgPick_ = [imagePick alloc];
    imgPick_.delegate = (id)self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [imgPick_ pickImage:isCameraImage view:self];
    });
}

- (void)imagePickDone:(UIImage *)image {
    imgPick_ = nil;
    
    if(image) {
        createAvatar *genAvatar_;
        genAvatar_ = [[createAvatar alloc]init];
        genAvatar_.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showIndicator];
        });
        pathAgingMask_ = [NSTemporaryDirectory() stringByAppendingFormat:@NAME_AGING_MASK];
        NSString *pathSkin = [resourceTop_ stringByAppendingFormat:@"resource/aging"];
        
        [genAvatar_ createAvatar:image skin:pathSkin maskOut:pathAgingMask_];
    }
}

- (void)showIndicator {
    CGRect r = [[UIScreen mainScreen] bounds];
    
    indicator_ = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator_.frame = CGRectMake(r.size.width/2-INDICATOR_SIZE/2, r.size.height/2-INDICATOR_SIZE/2,
                                  INDICATOR_SIZE, INDICATOR_SIZE);
    
    [self.view addSubview:indicator_];
    [indicator_ startAnimating];
    [self.view bringSubviewToFront:indicator_];
}

- (void)hideIndicator {
    [indicator_ stopAnimating];
    indicator_ = nil;
}

- (IBAction)showAging:(id)sender {
    
    if (agingMaskY_ == 0 || agingMaskO_ == 0) return;
    
    float curAge = [_agingSlider value];
    
    float gainY = (curAge < 0.5f) ? (0.5f - curAge) * 2.0f : 0.0f;
    float gainO   = (curAge < 0.5f) ? 0.0f : (curAge - 0.5f) * 2.0f;
    
    //
    // set aging mask alpha
    //
    ctlBeard_->SetAlpha(agingMaskY_, gainY);
    ctlBeard_->SetAlpha(agingMaskO_, gainO);
    
    //
    // expression gain
    //
    float gains[32];
    for (int i=0; i < 32; i++) gains[i] = 0.0f;
    static const int SLOT_YOUNG = 14;
    static const int SLOT_OLD   = 13;
    gains[SLOT_YOUNG] = gainY;
    gains[SLOT_OLD]   = gainO;
    int msec = 10;
    float weight = 1.0f;
    
    ctlAnim_->Express(msec, gains, weight);
}

- (IBAction)showColor:(id)sender {
    if (agingMaskY_ == 0 || agingMaskO_ == 0) return;
    
    float col = [_colorSlider value];
    ctlBeard_->SetColor(agingMaskO_, col, col, col);
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch *aTouch = [touches anyObject];
    if(aTouch.tapCount == 2) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        dispMenu_ = (dispMenu_)? false : true;
        [self hideMenu:!dispMenu_];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    motionportrait::mpVector2 pos;
    CGRect r = [[UIScreen mainScreen] bounds];
    
    for(UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self.view];
        pos.x = location.x / r.size.width;
        pos.y = 1.0f - location.y / r.size.height;
        ctlAnim_->LookAt(0, pos, 1.0f);
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    motionportrait::mpVector2 pos = {0.5f, 0.5f};
    ctlAnim_->LookAt(500, pos, 1.0f);
}

@end
