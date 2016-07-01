//
//  ViewController.m
//  CustomCamera
//
//  Created by tztddong on 16/7/1.
//  Copyright © 2016年 dongjiangpeng. All rights reserved.
//

#import "ViewController.h"
#import "CustomCameraController.h"

@interface ViewController ()<CustomCameraControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *takeImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)clickBtn:(id)sender {
    
    CustomCameraController *ctrl = [[CustomCameraController alloc]init];
    ctrl.delegate = self;
    [self presentViewController:ctrl animated:YES completion:nil];
}

- (void)photoCapViewController:(UIViewController *)viewController didFinishWithImage:(UIImage *)image{
    
    self.takeImageView.image = image;
}

@end
