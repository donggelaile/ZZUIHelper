//
//  ZZUITableViewCell.m
//  ZZUIHelper
//
//  Created by 李伯坤 on 2017/2/20.
//  Copyright © 2017年 李伯坤. All rights reserved.
//

#import "ZZUITableViewCell.h"

@implementation ZZUITableViewCell

- (NSString *)curView
{
    return @"self.contentView";
}

- (NSString *)m_initMethodName
{
    return @"- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier";
}

- (NSString *)m_initMethodName_swift {
    return @"override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)";
}

- (NSString *)m_superInitMethodName_swift {
    return @"super.init(style: style, reuseIdentifier: reuseIdentifier)";
}


@end
