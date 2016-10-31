//
//  NPUtil.h
//  NPKit
//
//  Created by Nic on 16/10/3.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import <Foundation/Foundation.h>

//  runtime related
void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector);

