//
//  NewsTableView.h
//  KinopoiskParserObj
//
//  Created by YAUHENI DROBAU on 01.09.16.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+EmptyDataSet.h"
#import <UIViewController+LMSideBarController.h>

@interface NewsTableView: UIViewController

@property (strong, nonatomic) NSString *menuTitle;
@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) NSString *titlesString;

-(void)updateWithIndicator:(BOOL)showIndicator;

@end
