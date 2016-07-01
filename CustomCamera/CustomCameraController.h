//
//  CustomCameraController.h
//  CustomCamera
//
//  Created by tztddong on 16/7/1.
//  Copyright © 2016年 dongjiangpeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomCameraControllerDelegate <NSObject>

- (void)photoCapViewController:(UIViewController *)viewController didFinishWithImage:(UIImage *)image;

@end
@interface CustomCameraController : UIViewController

@property(nonatomic,weak)id<CustomCameraControllerDelegate> delegate;

@end
