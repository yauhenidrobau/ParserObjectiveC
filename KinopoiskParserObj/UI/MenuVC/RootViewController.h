//
//  RootViewController.h
//  KinopoiskParserObj
//
//  Created by Admin on 03/12/2016.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LMSideBarController.h>

@interface RootViewController : LMSideBarController <LMSideBarControllerDelegate>

@property(nonatomic,strong) UINavigationController *mainNavigationController;

@end
