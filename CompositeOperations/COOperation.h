//
//  COOperation.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 02/10/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol COOperation <NSObject>

@property (readonly) id result;
@property (readonly) id error;

@end

