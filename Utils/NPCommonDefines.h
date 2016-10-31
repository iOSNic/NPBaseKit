//
//  NPCommonDefines.h
//  NPKit
//
//  Created by Nic on 16/10/3.
//  Copyright © 2016年 Nic. All rights reserved.
//

#ifndef NPCommonDefines_h
#define NPCommonDefines_h

#define CHECK_VALID_STRING(string) (string && [string isKindOfClass:[NSString class]] && [string length] > 0)

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#endif /* NPCommonDefines_h */
