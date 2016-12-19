#import <Foundation/Foundation.h>
#import "SignalService.h"

NS_ASSUME_NONNULL_BEGIN
@interface SignalStoreInMemoryStorage : NSObject <SignalStore>

@property (nonatomic, strong, nullable) SignalIdentityKeyPair *identityKeyPair;
@property (nonatomic) uint32_t localRegistrationId;

@end
NS_ASSUME_NONNULL_END
