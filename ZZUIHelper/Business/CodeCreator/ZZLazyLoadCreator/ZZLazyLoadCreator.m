//
//  ZZLazyLoadCreator.m
//  ZZUIHelper
//
//  Created by 李伯坤 on 2017/3/8.
//  Copyright © 2017年 李伯坤. All rights reserved.
//

#import "ZZLazyLoadCreator.h"
#import "ZZUIResponder+CodeCreator.h"
#import "ZZUIView+Masonry.h"
#import "ZZUIControl.h"
#import "ZZUIView.h"
#import "ZZUIViewController.h"
#import "NSString+MMBJ.h"
#import <RegExCategories/RegExCategories.h>

@interface ZZLazyLoadCreator ()

@property (nonatomic, strong) NSArray *codeBlocks;

@property (nonatomic, strong) NSArray *swiftCodeBlocks;

@property (nonatomic, strong) NSString *(^getterMethodForViewClass)(ZZNSObject *object);

@property (nonatomic, strong) NSString *(^getterMethodForViewClass_siwft)(ZZNSObject *object,BOOL isPrivate);

@end

@implementation ZZLazyLoadCreator

- (id)init
{
    if (self = [super init]) {
        [self setGetterMethodForViewClass:^NSString *(ZZNSObject *object) {
            ZZMethod *getterMethod = [[ZZMethod alloc] initWithMethodName:[NSString stringWithFormat:@"- (%@ *)%@", object.className, object.propertyName]];
            NSMutableString *getterCode = [NSMutableString stringWithFormat:@"if (!_%@) {\n", object.propertyName];
            [getterCode appendFormat:@"_%@ = %@;\n", object.propertyName, object.allocInitMethodName];
            
            NSArray *properties = object.properties;
            for (ZZPropertyGroup *group in properties) {
                for (ZZProperty *item in group.properties) {
                    if (item.selected) {
                        if ([group.groupName isEqualToString:@"CALayer"]) {
                            [getterCode appendFormat:@"[_%@.layer %@];\n", object.propertyName, item.propertyCode];
                        }
                        else {
                            [getterCode appendFormat:@"[_%@ %@];\n", object.propertyName, item.propertyCode];
                        }
                    }
                }
                for (ZZProperty *item in group.privateProperties) {
                    if (item.selected) {
                        [getterCode appendFormat:@"[_%@ %@];\n", object.propertyName, item.propertyCode];
                    }
                }
            }
            
            [getterCode appendFormat:@"}\nreturn _%@;\n", object.propertyName];
            [getterMethod addMethodContentCode:getterCode];
            NSString *code = [[getterMethod methodCode] stringByAppendingString:@"\n"];
            return code;
        }];

//lazy var label: UILabel = {
//    let view = UILabel()
//    return view
//}()

        [self setGetterMethodForViewClass_siwft:^NSString *(ZZNSObject *object, BOOL isPublic) {
            NSMutableString *code = @"".mutableCopy;
            if (isPublic) {
                [code appendFormat:@"public lazy var %@: %@ = {",object.propertyName,object.className];
            } else {
                [code appendFormat:@"lazy var %@: %@ = {",object.propertyName,object.className];
            }
            [code appendFormat:@"\n"];
            [code appendFormat:@"\tlet view = %@()\n",object.className];
            [code appendFormat:@"\treturn view\n}()\n"];
            
            return code;
        }];
    }
    return self;
}

- (NSMutableArray *)modules
{
    NSArray *moduleTitles = [[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromClass([self class])];
    NSMutableArray *modules = [[NSMutableArray alloc] init];
    if (!moduleTitles) {
        modules = self.codeBlocks.mutableCopy;
    }
    else {
        NSMutableDictionary *codeBlockDic = [[NSMutableDictionary alloc] init];
        for (ZZCreatorCodeBlock *block in self.codeBlocks) {
            [codeBlockDic setObject:block forKey:block.blockName];
        }
        for (NSString *title in moduleTitles) {
            [modules addObject:codeBlockDic[title]];
        }
    }
    return modules;
}
- (void)setModules:(NSMutableArray *)modules
{
    NSMutableArray *m = [[NSMutableArray alloc] init];
    for (ZZCreatorCodeBlock *block in modules) {
        [m addObject:block.blockName];
    }
    [[NSUserDefaults standardUserDefaults] setObject:m forKey:NSStringFromClass([self class])];
}

#pragma mark - # m
/// .m文件代码
- (NSString *)mFileForViewClass:(ZZUIResponder *)viewClass
{
    NSString *fileName = [viewClass.className stringByAppendingString:@".m"];
    NSString *copyrightCode = [[ZZUIHelperConfig sharedInstance] copyrightCodeByFileName:fileName];
    NSString *code = [copyrightCode stringByAppendingFormat:@"#import \"%@.h\"\n\n", viewClass.className];
    // 类拓展
    NSString *extensionCode = [self m_extensionCodeForViewClass:viewClass];
    if (extensionCode.length > 0) {
        code = [code stringByAppendingString:extensionCode];
    }
    // 类实现
    NSString *implementationCode = [self m_implementationCodeForViewClass:viewClass];
    code = [code stringByAppendingString:implementationCode];
    return code;
}

/// .m中，类拓展代码
- (NSString *)m_extensionCodeForViewClass:(ZZUIResponder *)viewClass
{
    NSArray *delegatesArray = viewClass.childDelegateViewsArray;
    if (viewClass.extensionProperties.count > 0 || delegatesArray.count > 0) {
        NSString *extensionCode = [NSString stringWithFormat:@"@interface %@ ()", viewClass.className];
        if (delegatesArray.count > 0) {    // 协议
            NSString *delegateCode = @"";
            for (ZZProtocol *protocol in delegatesArray) {
                if (delegateCode.length > 0) {
                    delegateCode = [delegateCode stringByAppendingString:@",\n"];
                }
                delegateCode = [delegateCode stringByAppendingString:protocol.protocolName];
            }
            if (delegateCode.length > 0) {
                extensionCode = [extensionCode stringByAppendingFormat:@" <\n%@\n>", delegateCode];
            }
        }
        
        extensionCode = [extensionCode stringByAppendingString:@"\n\n"];
        for (ZZNSObject *object in viewClass.extensionProperties) {
            if (object.propertyCode.length > 0) {
                extensionCode = [extensionCode stringByAppendingFormat:@"%@\n", object.propertyCode];
            }
        }
        extensionCode = [extensionCode stringByAppendingString:@"@end\n\n"];
        return extensionCode;
    }
    return nil;
}

/// .m中，类实现代码
- (NSString *)m_implementationCodeForViewClass:(ZZUIResponder *)viewClass
{
    NSMutableString *implementationCode = [NSMutableString stringWithFormat:@"@implementation %@\n\n", viewClass.className];
    
    for (ZZCreatorCodeBlock *block in self.modules) {
        NSString *code = block.action(viewClass);
        if (code.length > 0) {
            [implementationCode appendString:block.action(viewClass)];
        }
    }
    
    [implementationCode appendString:@"@end\n"];
    return implementationCode;
}

#pragma mark - # h
- (NSString *)hFileForViewClass:(ZZUIResponder *)viewClass
{
    NSString *fileName = [viewClass.className stringByAppendingString:@".h"];
    NSString *copyrightCode = [[ZZUIHelperConfig sharedInstance] copyrightCodeByFileName:fileName];
    NSString *code = copyrightCode;
    if ([viewClass.superClassName hasPrefix:@"UI"]) {
        code = [code stringByAppendingString:@"#import <UIKit/UIKit.h>"];
    }
    else {
        code = [code stringByAppendingFormat:@"#import \"%@.h\"", viewClass.superClassName];
    }
    code = [code stringByAppendingFormat:@"\n\n%@", [self h_interfaceCodeForViewClass:viewClass]];
    return code;
}

- (NSString *)h_interfaceCodeForViewClass:(ZZUIResponder *)viewClass
{
    NSString *interfaceCode = [NSString stringWithFormat:@"@interface %@ : %@\n\n", viewClass.className, viewClass.superClassName];
    
    for (ZZNSObject *object in viewClass.interfaceProperties) {
        if (object.propertyCode.length > 0) {
            interfaceCode = [interfaceCode stringByAppendingFormat:@"%@\n", object.propertyCode];
        }
    }
    
    interfaceCode = [interfaceCode stringByAppendingString:@"@end\n"];
    return interfaceCode;
}

#pragma mark - # swift
- (NSString *)swiftFileForViewClass:(ZZUIResponder *)viewClass {
    NSString *fileName = [viewClass.className stringByAppendingString:@".swift"];
    NSString *copyrightCode = [[ZZUIHelperConfig sharedInstance] copyrightCodeByFileName:fileName];
    NSString *code = copyrightCode;
    // 类实现
    NSString *implementationCode = [self swift_implementationCodeForViewClass:viewClass];
    code = [code stringByAppendingString:implementationCode];
    return code;
}

- (NSString *)swift_implementationCodeForViewClass:(ZZUIResponder *)viewClass {
    NSMutableString *implementationCode = [NSMutableString stringWithFormat:@"import UIKit \n\n"];
    [implementationCode appendFormat:@"class %@: %@ {\n", viewClass.className, viewClass.superClassName];
    
    NSMutableString *innerCode = @"".mutableCopy;
    for (ZZCreatorCodeBlock *block in self.swiftCodeBlocks) {
        NSString *code = block.action(viewClass);
        if (code.length > 0) {
            [innerCode appendString:block.action(viewClass)];
        }
    }
    innerCode = [[innerCode appentOneTabForPerLine] mutableCopy];
    
    [implementationCode appendString:innerCode];
    [implementationCode appendString:@"}\n"];
    return implementationCode;
}

#pragma mark - # Getter
- (NSArray *)codeBlocks
{
    if (!_codeBlocks) {
        _codeBlocks = @[self.lifeCycleCodeBlock,
                        self.delegateCodeBlock,
                        self.eventCodeBlock,
                        self.privateCodeBlock,
                        self.getterCodeBlock];
    }
    return _codeBlocks;
}

- (ZZCreatorCodeBlock *)lifeCycleCodeBlock
{
    if (!_lifeCycleCodeBlock) {
        _lifeCycleCodeBlock = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Life Cycle" action:^NSString *(ZZUIResponder *viewClass) {
            if ([[viewClass class] isSubclassOfClass:[ZZUIView class]]) {
                NSString *code = @"";
                NSArray *childViewArray = viewClass.childViewsArray;
                if (childViewArray.count > 0) {
                    ZZMethod *initMethod = [[ZZMethod alloc] initWithMethodName:[(ZZUIView *)viewClass m_initMethodName]];
                    
                    NSMutableString *initCode = [NSMutableString stringWithFormat:@"if (self = [super %@]) {", initMethod.superMethodName];
                    for (ZZUIView *view in childViewArray) {
                        [initCode appendFormat:@"[%@ addSubview:self.%@];\n", view.superViewName, view.propertyName];
                    }
                    
                    if ([ZZUIHelperConfig sharedInstance].layoutLibrary == ZZUIHelperLayoutLibraryMasonry) {
                        [initCode appendString:@"[self p_addMasonry];\n"];
                    }
                    
                    if ([[viewClass class] isSubclassOfClass:[ZZUIView class]]) {
                        [initCode appendString:@"}\nreturn self;\n"];
                    }
                    
                    [initMethod addMethodContentCode:initCode];
                    code = [initMethod methodCode];
                }
                
                return [code stringByAppendingString:@"\n"];
            }
            ZZUIViewController *vc = (ZZUIViewController *)viewClass;
            NSArray *childViewArray = viewClass.childViewsArray;
            if (childViewArray.count > 0) {
                [vc.loadView setSelected:YES];
                NSMutableString *code = [[NSMutableString alloc] initWithString:@"[super loadView];\n"];
                for (ZZUIView *view in childViewArray) {
                    [code appendFormat:@"[%@ addSubview:self.%@];\n", view.superViewName, view.propertyName];
                }
                if ([ZZUIHelperConfig sharedInstance].layoutLibrary == ZZUIHelperLayoutLibraryMasonry) {
                    [code appendString:@"[self p_addMasonry];\n"];
                }
                [vc.loadView clearMethodContent];
                [vc.loadView addMethodContentCode:code];
            }
            else {
                [vc.loadView setSelected:NO];
            }
            
            NSMutableString *initCode = [NSMutableString stringWithFormat:@"%@ Life Cycle\n", PMARK_];
            for (ZZMethod *method in vc.methodArray) {
                if (method.selected) {
                    [initCode appendFormat:@"%@\n", method.methodCode];
                }
            }
            return initCode;
        }];
        [_lifeCycleCodeBlock setRemarks:@"初始化函数，声明周期函数"];
    }
    return _lifeCycleCodeBlock;
}

- (ZZCreatorCodeBlock *)delegateCodeBlock
{
    if (!_delegateCodeBlock) {
        _delegateCodeBlock = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Delegate" action:^NSString *(ZZUIResponder *viewClass) {
            NSArray *delegateArray = viewClass.childDelegateViewsArray;
            if (delegateArray.count > 0) {
                NSString *delegateCode = @"";
                for (ZZProtocol *protocol in delegateArray) {
                    NSString *code = protocol.protocolCode;
                    if (code.length > 0) {
                        delegateCode = [delegateCode stringByAppendingFormat:@"%@ %@\n%@", PMARK, protocol.protocolName, code];
                    }
                }
                if (delegateCode.length > 0) {
                    delegateCode = [[NSString stringWithFormat:@"%@ Delegate\n", PMARK_] stringByAppendingString:delegateCode];
                }
                return delegateCode;
            }
            return nil;
        }];
        [_delegateCodeBlock setRemarks:@"SubView的代理方法"];
    }
    return _delegateCodeBlock;
}

- (ZZCreatorCodeBlock *)eventCodeBlock
{
    if (!_eventCodeBlock) {
        _eventCodeBlock = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Event Response" action:^NSString *(ZZUIResponder *viewClass) {
            NSArray *controlsArray = viewClass.childControlsArray;
            if (controlsArray.count > 0) {
                NSString *eventCode = @"";
                for (ZZUIControl *control in controlsArray) {
                    NSString *code = control.eventsCode;
                    if (code.length > 0) {
                        eventCode = [eventCode stringByAppendingString:code];
                    }
                }
                if (eventCode.length > 0) {
                    eventCode = [NSString stringWithFormat:@"%@ Event Response\n%@", PMARK_, eventCode];
                }
                return eventCode;
            }
            return nil;
        }];
        [_eventCodeBlock setRemarks:@"SubView的事件响应函数"];
    }
    return _eventCodeBlock;
}

- (ZZCreatorCodeBlock *)privateCodeBlock
{
    if (!_privateCodeBlock) {
        _privateCodeBlock = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Private Methods" action:^NSString *(ZZUIResponder *viewClass) {
            NSArray *childViews = viewClass.childViewsArray;
            if (childViews.count > 0 && [ZZUIHelperConfig sharedInstance].layoutLibrary == ZZUIHelperLayoutLibraryMasonry) {
                NSString *privateCode = [NSString stringWithFormat:@"%@ Private Methods\n", PMARK_];
                
                ZZMethod *method = [[ZZMethod alloc] initWithMethodName:@"- (void)p_addMasonry"];
                NSMutableString *code = [[NSMutableString alloc] init];
                for (ZZUIView *view in childViews) {
                    [code appendString:view.masonryCode];
                }
                [method addMethodContentCode:code];
                
                privateCode = [privateCode stringByAppendingFormat:@"%@\n", method.methodCode];
                return privateCode;
            }
            return nil;
        }];
        [_privateCodeBlock setRemarks:@"类的私有方法，如Masonry的布局函数"];
    }
    return _privateCodeBlock;
}

- (ZZCreatorCodeBlock *)getterCodeBlock
{
    if (!_getterCodeBlock) {
        __weak typeof(self) weakSelf = self;
        _getterCodeBlock = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Getters" action:^NSString *(ZZUIResponder *viewClass) {
            if (viewClass.interfaceProperties.count + viewClass.extensionProperties.count > 0) {
                NSString *getterCode = [NSString stringWithFormat:@"%@ Getter\n", PMARK_];
                for (ZZNSObject *resp in viewClass.interfaceProperties) {
                    NSString *code = weakSelf.getterMethodForViewClass(resp);
                    if (code.length > 0) {
                        getterCode = [getterCode stringByAppendingString:code];
                    }
                }
                for (ZZNSObject *resp in viewClass.extensionProperties) {
                    NSString *code = weakSelf.getterMethodForViewClass(resp);
                    if (code.length > 0) {
                        getterCode = [getterCode stringByAppendingString:code];
                    }
                }
                return getterCode;
            }
            return nil;
        }];
        [_getterCodeBlock setRemarks:@"Getter方法，通过惰性初始化的方式创建subViews"];
    }
    return _getterCodeBlock;
}

#pragma mark - siwft getters
- (NSArray *)swiftCodeBlocks
{
    if (!_swiftCodeBlocks) {
        _swiftCodeBlocks = @[self.getterCodeBlock_swift,
                             self.lifeCycleCodeBlock_swift,
                             self.delegateCodeBlock_swift,
                             self.eventCodeBlock_swift,
                             self.privateCodeBlock_swift];
    }
    return _swiftCodeBlocks;
}

- (ZZCreatorCodeBlock *)lifeCycleCodeBlock_swift
{
    if (!_lifeCycleCodeBlock_swift) {
        _lifeCycleCodeBlock_swift = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Life Cycle" action:^NSString *(ZZUIResponder *viewClass) {
            if ([[viewClass class] isSubclassOfClass:[ZZUIView class]]) {
                NSString *code = [NSString stringWithFormat:@"\n%@ Life Cycle\n", PMARK];
                NSArray *childViewArray = viewClass.childViewsArray;
                if (childViewArray.count > 0) {
                    ZZMethod *initMethod = [[ZZMethod alloc] initWithMethodName:[(ZZUIView *)viewClass m_initMethodName_swift] isSwift:YES];
                    
                    NSMutableString *initCode = [NSMutableString stringWithFormat:@"%@\n", [(ZZUIView *)viewClass m_superInitMethodName_swift]];
                    for (ZZUIView *view in childViewArray) {
                        [initCode appendFormat:@"%@.addSubview(%@)\n", view.superViewName, view.propertyName];
                    }
                    
                    if ([ZZUIHelperConfig sharedInstance].layoutLibrary == ZZUIHelperLayoutLibraryMasonry) {
                        [initCode appendString:@"self.setAutoLayout()\n"];
                    }
                    
                    [initMethod addMethodContentCode:initCode];
                    code = [code stringByAppendingString:[initMethod methodCode]];
                }
                code = [code stringByAppendingString:@"\n"];
                
                ZZMethod *requireCoder = [[ZZMethod alloc] initWithMethodName:@"required init?(coder: NSCoder)" isSwift:YES];
                [requireCoder addMethodContentCode:@"fatalError(\"init(coder:) has not been implemented\")"];
                code = [code stringByAppendingFormat:@"%@\n",[requireCoder methodCode]];
                return code;
            }
            return @"";
        }];
        [_lifeCycleCodeBlock_swift setRemarks:@"初始化函数，声明周期函数"];
    }
    return _lifeCycleCodeBlock_swift;
}

- (ZZCreatorCodeBlock *)delegateCodeBlock_swift
{
    if (!_delegateCodeBlock_swift) {
        _delegateCodeBlock_swift = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Delegate" action:^NSString *(ZZUIResponder *viewClass) {
            return nil;
        }];
        [_delegateCodeBlock_swift setRemarks:@"SubView的代理方法"];
    }
    return _delegateCodeBlock_swift;
}

- (ZZCreatorCodeBlock *)eventCodeBlock_swift
{
    if (!_eventCodeBlock_swift) {
        _eventCodeBlock_swift = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Event Response" action:^NSString *(ZZUIResponder *viewClass) {
            return nil;
        }];
        [_eventCodeBlock_swift setRemarks:@"SubView的事件响应函数"];
    }
    return _eventCodeBlock_swift;
}

- (ZZCreatorCodeBlock *)privateCodeBlock_swift
{
    if (!_privateCodeBlock_swift) {
        _privateCodeBlock_swift = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Private Methods" action:^NSString *(ZZUIResponder *viewClass) {
            NSArray *childViews = viewClass.childViewsArray;
            if (childViews.count > 0 && [ZZUIHelperConfig sharedInstance].layoutLibrary == ZZUIHelperLayoutLibraryMasonry) {
                NSString *privateCode = [NSString stringWithFormat:@"%@ Private Methods\n", PMARK];
                
                ZZMethod *method = [[ZZMethod alloc] initWithMethodName:@"func setAutoLayout()" isSwift:YES];
                NSMutableString *code = [[NSMutableString alloc] init];
                for (ZZUIView *view in childViews) {
                    [code appendString:view.snapkitCode];
                }
                [method addMethodContentCode:code];
                NSString *orgStr = method.methodCode;
                NSString *methodCode = [self removerSnpapkitEnter:orgStr];
                
                privateCode = [privateCode stringByAppendingFormat:@"%@", methodCode];
                return privateCode;
            }
            return nil;
        }];
        [_privateCodeBlock_swift setRemarks:@"类的私有方法，如Masonry的布局函数"];
    }
    return _privateCodeBlock_swift;
}

- (NSString*)removerSnpapkitEnter:(NSString*)orgStr {
    NSError *error;
    NSRegularExpression *rx = [[NSRegularExpression alloc] initWithPattern:@"makeConstraints \\{\\n\\t\\tmake in" options:0 error:&error];
    return [rx replace:orgStr withDetailsBlock:^NSString *(RxMatch *match) {
        return @"makeConstraints { make in";
    }];
}


- (ZZCreatorCodeBlock *)getterCodeBlock_swift
{
    if (!_getterCodeBlock_swift) {
        __weak typeof(self) weakSelf = self;
        _getterCodeBlock_swift = [[ZZCreatorCodeBlock alloc] initWithBlockName:@"Getters" action:^NSString *(ZZUIResponder *viewClass) {
            if (viewClass.interfaceProperties.count + viewClass.extensionProperties.count > 0) {
                NSString *getterCode = [NSString stringWithFormat:@"%@ Getter\n", PMARK];
                for (ZZNSObject *resp in viewClass.interfaceProperties) {
                    NSString *code = weakSelf.getterMethodForViewClass_siwft(resp,YES);
                    if (code.length > 0) {
                        getterCode = [getterCode stringByAppendingString:code];
                    }
                }
                for (ZZNSObject *resp in viewClass.extensionProperties) {
                    NSString *code = weakSelf.getterMethodForViewClass_siwft(resp,NO);
                    if (code.length > 0) {
                        getterCode = [getterCode stringByAppendingString:code];
                    }
                }
                return getterCode;
            }
            return nil;
        }];
        [_getterCodeBlock_swift setRemarks:@"Getter方法，通过惰性初始化的方式创建subViews"];
    }
    return _getterCodeBlock_swift;
}

@end
