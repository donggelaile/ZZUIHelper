//
//  ZZCodeSwiftFileViewController.m
//  ZZUIHelper
//
//  Created by dongshachen on 2022/9/3.
//  Copyright © 2022 李伯坤. All rights reserved.
//

#import "ZZCodeSwiftFileViewController.h"
#import <MGSFragaria/MGSFragaria.h>

@interface ZZCodeSwiftFileViewController ()

@property (nonatomic, strong) ZZUIResponder *curClass;

@property (nonatomic, strong) MGSFragaria *fragaria;

@end

@implementation ZZCodeSwiftFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.fragaria embedInView:self.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:NOTI_CLASS_PROPERTY_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:NOTI_CLASS_PROPERTY_EDIT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:NOTI_NEW_PROJECT object:nil];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData
{
    if ([ZZClassHelper sharedInstance].curClass) {
        ZZUIResponder *curClass = [ZZClassHelper sharedInstance].curClass;
        CGRect rect = self.fragaria.textView.visibleRect;
        [self.fragaria setString:[[ZZCreatorManager sharedInstance] swiftFileForViewClass:curClass]];
        if (curClass == self.curClass) {
            [self.fragaria.textView scrollRectToVisible:rect];
        }
        self.curClass = curClass;
    }
}

#pragma mark - # Getter
- (MGSFragaria *)fragaria
{
    if (!_fragaria) {
        _fragaria = [[MGSFragaria alloc] init];
        [_fragaria setObject:@"Objective-C" forKey:MGSFOSyntaxDefinitionName];
    }
    return _fragaria;
}

@end
