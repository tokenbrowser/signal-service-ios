//
//  SignalPreKeyBundle_Internal.h
//  Pods
//
//  Created by Chris Ballinger on 6/30/16.
//
//

#import "SignalPreKeyBundle.h"
#import "SignalService.h"
#import "SignalProtocolC.h"

@interface SignalPreKeyBundle ()

@property (nonatomic, readonly) session_pre_key_bundle *bundle;

@end
