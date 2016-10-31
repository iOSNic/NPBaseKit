//
//  NPUtil.m
//  NPKit
//
//  Created by Nic on 16/10/3.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import "NPUtil.h"
#import <objc/runtime.h>

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    // the method might not exist in the class, but in its superclass
    Method orignalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // class_addMethod will fail if original method already exists
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    // the method doesn’t exist and we just added one
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(orignalMethod), method_getTypeEncoding(orignalMethod));
    }
    else {
        method_exchangeImplementations(orignalMethod, swizzledMethod);
    }
}
