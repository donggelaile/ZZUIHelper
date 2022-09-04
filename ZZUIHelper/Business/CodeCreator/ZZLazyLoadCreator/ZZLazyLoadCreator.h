//
//  ZZLazyLoadCreator.h
//  ZZUIHelper
//
//  Created by 李伯坤 on 2017/3/8.
//  Copyright © 2017年 李伯坤. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZCreatorProtocol.h"
#import "ZZCreatorCodeBlock.h"

@interface ZZLazyLoadCreator : NSObject <ZZCreatorProtocol>

@property (nonatomic, strong) ZZCreatorCodeBlock *lifeCycleCodeBlock;
@property (nonatomic, strong) ZZCreatorCodeBlock *delegateCodeBlock;
@property (nonatomic, strong) ZZCreatorCodeBlock *eventCodeBlock;
@property (nonatomic, strong) ZZCreatorCodeBlock *privateCodeBlock;
@property (nonatomic, strong) ZZCreatorCodeBlock *getterCodeBlock;

@property (nonatomic, strong) ZZCreatorCodeBlock *lifeCycleCodeBlock_swift;
@property (nonatomic, strong) ZZCreatorCodeBlock *delegateCodeBlock_swift;
@property (nonatomic, strong) ZZCreatorCodeBlock *eventCodeBlock_swift;
@property (nonatomic, strong) ZZCreatorCodeBlock *privateCodeBlock_swift;
@property (nonatomic, strong) ZZCreatorCodeBlock *getterCodeBlock_swift;

@end
