//
//  NewsTableViewCell.m
//  BelarusNews
//
//  Created by YAUHENI DROBAU on 01.09.16.
//  Copyright © 2016 YAUHENI DROBAU. All rights reserved.
//

#import "NewsTableViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import "DateFormatterManager.h"
#import "UIColor+BelarusNews.h"
#import "SettingsManager.h"
#import "Constants.h"
#import "Macros.h"

static const NSInteger contentOffset = 90;
static const NSInteger defaultContentOffset = 10;
static const NSInteger defaultButtonWidth = 0;
static const NSInteger buttonWidth = 40;
static const NSInteger defaultCornerRadius = 16;

@interface NewsTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageNewsView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *pubDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shareButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *favoriteButtonWidthConstraint;

@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIView *cellBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastArticlesLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellBackgroundViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellBackgroundViewLeadingConstraint;
@property (nonatomic) BOOL isUpdatedCell;
@property (nonatomic) BOOL isFavoriteArticle;

@end

@implementation NewsTableViewCell

#pragma mark - LifeCycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
    self.imageNewsView.clipsToBounds = YES;
    self.imageNewsView.contentMode = UIViewContentModeScaleAspectFill;
    self.cellBackgroundView.layer.cornerRadius = defaultCornerRadius;
    [self prepareButton:self.shareButton];
    [self prepareButton:self.favoriteButton];

    self.lastArticlesLabel.text = NSLocalizedString(@"New", nil);
    UISwipeGestureRecognizer *swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(updateCellWithLeftSwipe)];
    swipeRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.cellBackgroundView addGestureRecognizer:swipeRecognizerLeft];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - IBActions
- (IBAction)favoriteButtonDidTap:(id)sender {
    if (self.favoriteButton.tintColor == [UIColor bn_mainTitleColor]) {
        self.favoriteButton.tintColor = [UIColor bn_lightBlueColor];
    } else {
        self.favoriteButton.tintColor = [UIColor bn_mainTitleColor];
    }
    self.isFavoriteArticle = !self.isFavoriteArticle;
    [self.cellDelegate newsTableViewCell:self didTapFavoriteButton:sender];
}

- (IBAction)shareButtonDidTap:(id)sender {
    [self.cellDelegate newsTableViewCell:self didTapShareButton:sender];
}

#pragma mark - Public 
-(void)updateCellWithLeftSwipe {
    self.shareButton.userInteractionEnabled = YES;
    if (!self.isUpdatedCell) {
        [UIView animateWithDuration:0.6 animations:^{
            self.cellBackgroundViewLeadingConstraint.constant = self.cellBackgroundViewLeadingConstraint.constant - contentOffset;
            self.shareButtonWidthConstraint.constant = buttonWidth;
            self.favoriteButtonWidthConstraint.constant = buttonWidth;
            self.cellBackgroundViewTrailingConstraint.constant = self.cellBackgroundViewTrailingConstraint.constant + contentOffset;
            [self layoutIfNeeded];
        }];
        self.isUpdatedCell = YES;
    }
}

-(void)updateCellWithRightSwipe {
    if (self.isUpdatedCell) {
        [UIView animateWithDuration:0.6 animations:^{
            self.cellBackgroundViewLeadingConstraint.constant = defaultContentOffset;
            self.cellBackgroundViewTrailingConstraint.constant = defaultContentOffset;
            self.shareButtonWidthConstraint.constant = defaultButtonWidth;
            self.favoriteButtonWidthConstraint.constant = defaultButtonWidth;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
        self.isUpdatedCell = NO;
    }
}

#pragma mark - Private

-(void)prepareButton:(UIButton*)button {
    button.layer.cornerRadius = defaultCornerRadius;
    button.backgroundColor = [UIColor bn_mainColor];
    [button setImage:[button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [button setTintColor:[UIColor bn_mainTitleColor]];
}

-(void)updateNightModeCell:(BOOL)update {
    if (update) {
        self.titleLabel.textColor = [UIColor bn_mainNightColor];
        self.cellBackgroundView.backgroundColor = [UIColor bn_newsCellNightColor];
        self.shareButton.tintColor = [UIColor bn_nightModeTitleColor];

        self.pubDateLabel.textColor = [UIColor bn_mainNightColor];
        self.sourceLabel.textColor = [UIColor whiteColor];
        
    } else {
        self.sourceLabel.textColor = [UIColor bn_linkColor];
        self.titleLabel.textColor = [UIColor bn_mainTitleColor];
        self.cellBackgroundView.backgroundColor = [UIColor bn_mainColor];
        self.shareButton.tintColor = [UIColor bn_mainTitleColor];
        self.pubDateLabel.textColor = [UIColor bn_mainTitleColor];
    }
}

-(void)cellForNews:(NewsEntity *)entity WithIndexPath:(NSIndexPath *)indexPath  {
    [self layoutIfNeeded];
    
    self.isFavoriteArticle = entity.favorite;
    self.sourceLabel.text = entity.linkFeed;
    self.titleLabel.text = entity.titleFeed;
    self.descriptionLabel.text = entity.descriptionFeed;

    if (!entity.favorite) {
        [self.favoriteButton setTintColor:[UIColor bn_mainTitleColor]];
    } else {
        [self.favoriteButton setTintColor:[UIColor bn_lightBlueColor]];
    }
    if ([[NSDate date]timeIntervalSince1970] - entity.pubDateFeed.timeIntervalSince1970 < 2000 ) {
        [self showNewArticles:YES];
    } else {
        [self showNewArticles:NO];
    }
    if([[[DateFormatterManager sharedInstance] stringFromDate:entity.pubDateFeed withFormat:@"d MMM"] isEqualToString:[[DateFormatterManager sharedInstance] stringFromDate:[NSDate date] withFormat:@"d MMM"]]) {
        self.pubDateLabel.text =[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Today at", nil),[[DateFormatterManager sharedInstance] stringFromDate:entity.pubDateFeed withFormat:@"HH:mm"]];        
    } else {
        self.pubDateLabel.text = [[DateFormatterManager sharedInstance] stringFromDate:entity.pubDateFeed withFormat:@"d MMM HH:mm:ss"];
    }
    [self.imageNewsView sd_setImageWithURL:[NSURL URLWithString:entity.urlImage]
                 placeholderImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.jpg",entity.category]]];
    self.imageNewsView.layer.cornerRadius = 0;
    if ([SettingsManager sharedInstance].isRoundImagesEnabled) {
        self.imageNewsView.layer.cornerRadius = CGRectGetWidth(self.imageNewsView.frame) / 2;
    }
    [self updateFontSize];
}

-(UIImageView*)imageFromCell {
    return self.imageNewsView;
}

-(void)showNewArticles:(BOOL)show {
    if (show) {
        self.lastArticlesLabel.hidden = NO;
    } else {
        self.lastArticlesLabel.hidden = YES;
    }
}

-(void)updateFontSize {
    float fontSize = 14;
    if (IS_IPHONE_4_OR_LESS) {
        float fontSize = 12;

        self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        self.pubDateLabel.font = [UIFont systemFontOfSize:fontSize-1];
    } else  if (IS_IPHONE_5) {
        float fontSize = 13;
        
        self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        self.pubDateLabel.font = [UIFont systemFontOfSize:fontSize-1];
    } else if (IS_IPHONE_6 || IS_IPHONE_6P){
        float fontSize = 15;
        
        self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        self.pubDateLabel.font = [UIFont systemFontOfSize:fontSize-2];
    } else {
        self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        self.pubDateLabel.font = [UIFont systemFontOfSize:fontSize-2];
    }
}

-(void)setDefaultCellStyle {
    
    self.cellBackgroundViewLeadingConstraint.constant = 8;
    self.cellBackgroundViewTrailingConstraint.constant = 10;
    [self layoutIfNeeded];
    self.isUpdatedCell = NO;
}
@end
