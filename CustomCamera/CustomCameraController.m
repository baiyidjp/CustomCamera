//
//  CustomCameraController.m
//  CustomCamera
//
//  Created by tztddong on 16/7/1.
//  Copyright © 2016年 dongjiangpeng. All rights reserved.
//

#import "CustomCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define KWIDTH  [UIScreen mainScreen].bounds.size.width
#define KHEIGHT [UIScreen mainScreen].bounds.size.height

typedef enum : NSUInteger {
    BUTTONTAG_CAMERA,//切换摄像头
    BUTTONTAG_TAKEPIC,//拍照
    BUTTONTAG_FLASH,//闪光灯
    BUTTONTAG_CLOSE,//关闭
} BUTTONTAG;

@interface CustomCameraController ()<UIGestureRecognizerDelegate>
/**
 *  捕获设备(摄像头 音频...)
 */
@property(nonatomic,strong)AVCaptureDevice *captureDevice;
/**
 *  将输入输出结合在一起的
 */
@property(nonatomic,strong)AVCaptureSession *captureSession;
/**
 *  输入设备
 */
@property(nonatomic,strong)AVCaptureDeviceInput *captureInput;
/**
 *  输出设备
 */
@property(nonatomic,strong)AVCaptureStillImageOutput *stillImageOutput;
/**
 *  预览图层
 */
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
/**
 *  显示预览的view
 */
@property(nonatomic,strong)UIView *cameraView;
/**
 *  闪光灯按钮
 */
@property(nonatomic,strong)UIButton *flashBtnBtn;
/**
 *  切换前后摄像头按钮
 */
@property(nonatomic,strong)UIButton *cameraBtn;
/**
 *  拍照
 */
@property(nonatomic,strong)UIButton *takePicBtn;
/**
 *  关闭
 */
@property(nonatomic,strong)UIButton *closeBtn;
/**
 *  聚焦圈
 */
@property (nonatomic,weak) UIView *focusCircle;
/**
 *  手形图
 */
@property(nonatomic,strong)UIImageView * imageV;
/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 *  最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;

@end

@implementation CustomCameraController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.effectiveScale = self.beginGestureScale = 1.0f;
    [self configViews];
    [self getAuthorization];
}

//获取授权
- (void)getAuthorization{
    /*
     AVAuthorizationStatusNotDetermined = 0,// 未进行授权选择
     
     AVAuthorizationStatusRestricted,　　　　// 未授权，且用户无法更新，如家长控制情况下
     
     AVAuthorizationStatusDenied,　　　　　　 // 用户拒绝App使用
     
     AVAuthorizationStatusAuthorized,　　　　// 已授权，可使用
     */
    //此处获取摄像头授权
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
    {
        case AVAuthorizationStatusAuthorized:       //已授权，可使用    The client is authorized to access the hardware supporting a media type.
        {
            NSLog(@"授权摄像头使用成功");
            [self setSession];
            break;
        }
        case AVAuthorizationStatusNotDetermined:    //未进行授权选择     Indicates that the user has not yet made a choice regarding whether the client can access the hardware.
        {
            //则再次请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(granted){    //用户授权成功
                    [self setSession];
                    return;
                } else {        //用户拒绝授权
                    [self dismissViewControllerAnimated:YES completion:nil];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"出错了"
                                                                        message:@"用户拒绝授权摄像头的使用权,返回上一页.请打开\n设置-->隐私/通用等权限设置"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"确定"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
            }];
            break;
        }
        default:                                    //用户拒绝授权/未授权
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"出错了"
                                                                message:@"拒绝授权,返回上一页.请检查下\n设置-->隐私/通用等权限设置"
                                                               delegate:nil
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
            break;
        }
    }
    
}

- (void)configViews{
    
//    self.cameraView = [[UIView alloc]initWithFrame:self.view.bounds];
//    self.cameraView.backgroundColor = [UIColor orangeColor];
//    self.cameraView.layer.masksToBounds = YES;
//    [self.view addSubview:self.cameraView];
    
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(oneTap:)];
    oneTap.numberOfTapsRequired = 1;
    oneTap.delaysTouchesBegan = YES;
    
    UITapGestureRecognizer *twoTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(twoTap:)];
    twoTap.numberOfTapsRequired = 2;
    twoTap.delaysTouchesBegan = YES;
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
    
    [oneTap requireGestureRecognizerToFail:twoTap];
    
    [self.view addGestureRecognizer:oneTap];
//    [self.view addGestureRecognizer:twoTap];
    
    CGFloat btnH = 44;
    CGFloat btnY = KHEIGHT - btnH;
    
    self.cameraBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, btnY, KWIDTH/3, btnH)];
    [self.cameraBtn setTitle:@"切换前置摄像头" forState:UIControlStateNormal];
    [self.cameraBtn setTitle:@"切换后置摄像头" forState:UIControlStateSelected];
    [self.cameraBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.cameraBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    self.cameraBtn.tag = BUTTONTAG_CAMERA;
    [self.cameraBtn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraBtn];
    
    self.takePicBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.cameraBtn.frame), btnY, KWIDTH/3, btnH)];
    [self.takePicBtn setTitle:@"拍照" forState:UIControlStateNormal];
    [self.takePicBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.takePicBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    self.takePicBtn.tag = BUTTONTAG_TAKEPIC;
    [self.takePicBtn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.takePicBtn];
    
    self.flashBtnBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.takePicBtn.frame), btnY, KWIDTH/3, btnH)];
    [self.flashBtnBtn setTitle:@"闪光灯(Off)" forState:UIControlStateNormal];
    [self.flashBtnBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.flashBtnBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    self.flashBtnBtn.tag = BUTTONTAG_FLASH;
    [self.flashBtnBtn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashBtnBtn];
    
    self.closeBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 10, 50, 30)];
    self.closeBtn.tag = BUTTONTAG_CLOSE;
    [self.closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [self.closeBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeBtn];
    
    // 手型图
    self.imageV = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.imageV];
//    self.imageV.image = [UIImage imageNamed:@"mianfeidai_shou"];
}

- (void)setSession{
    
    self.captureSession = [[AVCaptureSession alloc]init];
    /*  通常支持如下格式  分辨率
     (
     AVAssetExportPresetLowQuality,
     AVAssetExportPreset960x540,
     AVAssetExportPreset640x480,
     AVAssetExportPresetMediumQuality,
     AVAssetExportPreset1920x1080,
     AVAssetExportPreset1280x720,
     AVAssetExportPresetHighestQuality,
     AVAssetExportPresetAppleM4A
     )
     */
//    if ([self.captureSession canSetSessionPreset:AVAssetExportPreset640x480]) {
//        [self.captureSession setSessionPreset:AVAssetExportPreset640x480];
//    }
    
    //获取输入设备
    /* MediaType
     AVF_EXPORT NSString *const AVMediaTypeVideo                 NS_AVAILABLE(10_7, 4_0);       //视频
     AVF_EXPORT NSString *const AVMediaTypeAudio                 NS_AVAILABLE(10_7, 4_0);       //音频
     AVF_EXPORT NSString *const AVMediaTypeText                  NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeClosedCaption         NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeSubtitle              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeTimecode              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeMetadata              NS_AVAILABLE(10_8, 6_0);
     AVF_EXPORT NSString *const AVMediaTypeMuxed                 NS_AVAILABLE(10_7, 4_0);
     */
    
    /* AVCaptureDevicePosition
     typedef NS_ENUM(NSInteger, AVCaptureDevicePosition) {
     AVCaptureDevicePositionUnspecified         = 0,
     AVCaptureDevicePositionBack                = 1,            //后置摄像头
     AVCaptureDevicePositionFront               = 2             //前置摄像头
     } NS_AVAILABLE(10_7, 4_0) __TVOS_PROHIBITED;
     */
    self.captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    
    //根据输入设备 初始化输入对象
    NSError *videoError;
    self.captureInput = [[AVCaptureDeviceInput alloc]initWithDevice:self.captureDevice error:&videoError];
    if (videoError) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"获取输入设备失败"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    if ([self.captureSession canAddInput:self.captureInput]) {
        [self.captureSession addInput:self.captureInput];
    }
    
    //初始化输出设备
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = self.view.bounds;
    
    
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.view bringSubviewToFront:self.cameraBtn];
    [self.view bringSubviewToFront:self.flashBtnBtn];
    [self.view bringSubviewToFront:self.takePicBtn];
    [self.view bringSubviewToFront:self.closeBtn];
    [self.view bringSubviewToFront:self.imageV];
    
    [self.captureSession startRunning];
}
#pragma mark 获取摄像头-->前/后
- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

- (void)clickBtn:(UIButton *)btn{
    
    switch (btn.tag) {
        case BUTTONTAG_CAMERA:
            [self checkCamera];
            break;
        case BUTTONTAG_TAKEPIC:
            [self takePicture];
            break;
        case BUTTONTAG_FLASH:
            [self flashOnorClose];
            break;
        case BUTTONTAG_CLOSE:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        default:
            break;
    }
}

- (void)oneTap:(UITapGestureRecognizer *)oneTap{
    
    CGPoint point = [oneTap locationInView:self.view];
    [self setFocusCirclePoint:point];
    //聚焦 需要先锁定
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        /*
         @constant AVCaptureFocusModeLocked 锁定在当前焦距
         Indicates that the focus should be locked at the lens' current position.
         
         @constant AVCaptureFocusModeAutoFocus 自动对焦一次,然后切换到焦距锁定
         Indicates that the device should autofocus once and then change the focus mode to AVCaptureFocusModeLocked.
         
         @constant AVCaptureFocusModeContinuousAutoFocus 当需要时.自动调整焦距
         Indicates that the device should automatically focus when needed.
         */
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            NSLog(@"聚焦成功");
        }else{
            NSLog(@"聚焦失败");
        }
        //将手指点击的坐标转换成摄像头坐标
        CGPoint focusPoint = [self.previewLayer pointForCaptureDevicePointOfInterest:point];
        //设置聚焦点的位置
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:focusPoint];
        }
        /*
         @constant AVCaptureExposureModeLocked  曝光锁定在当前值
         Indicates that the exposure should be locked at its current value.
         
         @constant AVCaptureExposureModeAutoExpose 曝光自动调整一次然后锁定
         Indicates that the device should automatically adjust exposure once and then change the exposure mode to AVCaptureExposureModeLocked.
         
         @constant AVCaptureExposureModeContinuousAutoExposure 曝光自动调整
         Indicates that the device should automatically adjust exposure when needed.
         
         @constant AVCaptureExposureModeCustom 曝光只根据设定的值来
         Indicates that the device should only adjust exposure according to user provided ISO, exposureDuration values.
         
         */
        //设置曝光模式
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            NSLog(@"曝光成功");
        }else{
            NSLog(@"曝光失败");
        }
        //设置曝光点
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:focusPoint];
        }
    }];
}

//调整焦距
- (void)twoTap:(UITapGestureRecognizer *)twoTap{
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        if (captureDevice.videoZoomFactor == 1.0) {
            CGFloat current = 1.5;
            if (current < captureDevice.activeFormat.videoMaxZoomFactor) {
                [captureDevice rampToVideoZoomFactor:current withRate:10.0];
            }
        }else{
            [captureDevice rampToVideoZoomFactor:1.0 withRate:10.0];
        }
    }];
}

//聚焦的光圈
- (UIView *)focusCircle{
    if (!_focusCircle) {
        UIView *focusCircle = [[UIView alloc]init];
        focusCircle.frame = CGRectMake(0, 0, 100, 100);
        focusCircle.layer.cornerRadius = 50;
        focusCircle.layer.borderColor = [UIColor orangeColor].CGColor;
        focusCircle.layer.borderWidth = 2;
        focusCircle.layer.masksToBounds = YES;
        _focusCircle = focusCircle;
        [self.view addSubview:focusCircle];
    }
    return _focusCircle;
}

//根据点击的point改变光圈的位置
- (void)setFocusCirclePoint:(CGPoint)point{
    
    self.focusCircle.center = point;
    self.focusCircle.transform = CGAffineTransformIdentity;
    self.focusCircle.alpha = 1.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCircle.alpha = 0.0;
        self.focusCircle.transform = CGAffineTransformMakeScale(0.5, 0.5);
    }];
}

#pragma mark gestureRecognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    //判断是否所有手势都是作用在预览图层界面上的
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if (allTouchesAreOnThePreviewLayer) {

        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        NSLog(@"%f-------------->%f------------recognizerScale-%f",self.effectiveScale,self.beginGestureScale,recognizer.scale);
        CGFloat maxScaleAndCropFactor = 2.0f;//[[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
            
            [captureDevice rampToVideoZoomFactor:self.effectiveScale withRate:10.0];
            
        }];
        
    }
    
}

//拍照
- (void)takePicture{
    
    AVCaptureConnection *captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!captureConnection) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"拍照失败"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    //取照片
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == nil) {
            return ;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *outImage = [UIImage imageWithData:imageData];
        //将人手图合成
        UIGraphicsBeginImageContext(outImage.size);
        [outImage drawInRect:CGRectMake(0, 0, outImage.size.width, outImage.size.height)];
        [self.imageV.image drawInRect:CGRectMake(0, 0, outImage.size.width, outImage.size.height)];
        UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        UIImageWriteToSavedPhotosAlbum(resultImage, self, nil, NULL);
        [self.captureSession stopRunning];
        [self dismissViewControllerAnimated:YES completion:^{
            if ([self.delegate respondsToSelector:@selector(photoCapViewController:didFinishWithImage:)]) {
                [self.delegate photoCapViewController:self didFinishWithImage:resultImage];
            }
        }];
    }];
}

- (void)checkCamera{
    
    switch (self.captureDevice.position) {
        case AVCaptureDevicePositionBack:
            self.captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
            break;
        case AVCaptureDevicePositionFront:
            self.captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
            break;
        default:
            return;
            break;
    }
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&error];
        
        if (newVideoInput != nil) {
            //必选先 remove 才能询问 canAdd
            [_captureSession removeInput:self.captureInput];
            if ([self.captureSession canAddInput:newVideoInput]) {
                [self.captureSession addInput:newVideoInput];
                self.captureInput = newVideoInput;
                self.cameraBtn.selected = !self.cameraBtn.selected;
            }else{
                [_captureSession addInput:self.captureInput];
            }
            
        } else if (error) {
            NSLog(@"切换前/后摄像头失败, error = %@", error);
        }
    }];
}

//闪光灯的开关
- (void)flashOnorClose{
    
    BOOL con1 = [self.captureDevice hasTorch];    //支持手电筒模式
    BOOL con2 = [self.captureDevice hasFlash];    //支持闪光模式
    
    if (con1 && con2)
    {
        [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
            if (self.captureDevice.flashMode == AVCaptureFlashModeAuto)
            {
                [self.captureDevice setFlashMode:AVCaptureFlashModeOff];
                [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
                [self.flashBtnBtn setTitle:@"闪光灯(Off)" forState:UIControlStateNormal];
            }else if (self.captureDevice.flashMode == AVCaptureFlashModeOff)
            {
                [self.captureDevice setFlashMode:AVCaptureFlashModeOn];
                [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
                [self.flashBtnBtn setTitle:@"闪光灯(On)" forState:UIControlStateNormal];
            }
            else if (self.captureDevice.flashMode == AVCaptureFlashModeOn){                                                                    [self.captureDevice setFlashMode:AVCaptureFlashModeAuto];
                [self.captureDevice setTorchMode:AVCaptureTorchModeAuto];
                [self.flashBtnBtn setTitle:@"闪光灯(Auto)" forState:UIControlStateNormal];
            }
            NSLog(@"现在的闪光模式是AVCaptureFlashModeOn么?是你就扣1, %zd",self.captureDevice.flashMode == AVCaptureFlashModeOn);
        }];
    }else{
        NSLog(@"不能切换闪光模式");
    }

}

//更改设备属性前一定要锁上
-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    
    AVCaptureDevice *captureDevice= [self.captureInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁,意义是---进行修改期间,先锁定,防止多处同时修改
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (!lockAcquired) {
        NSLog(@"锁定设备过程error，错误信息：%@",error.localizedDescription);
    }else{
        [self.captureSession beginConfiguration];//可以更改属性
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [self.captureSession commitConfiguration];
    }
}
@end
