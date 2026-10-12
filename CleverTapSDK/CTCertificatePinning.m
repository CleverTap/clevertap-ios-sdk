#if CLEVERTAP_SSL_PINNING

#import "CTCertificatePinning.h"
#import "CTConstants.h"

@implementation CTCertificatePinning

+ (NSString *)plistFilePathForAccountId:(NSString*)accountId {
    return [NSString stringWithFormat:@"~/Library/%@-SSLPins.plist", accountId];
}

+ (BOOL)setupSSLPinsUsingDictionnary:(NSDictionary*)domainsAndCertificates forAccountId:(NSString *)accountId {
    if (domainsAndCertificates == nil) {
        return NO;
    }
    
    //APPEND TO EXISTING PINS
    NSMutableDictionary *finalPinsDict = [NSMutableDictionary dictionary];
    [finalPinsDict addEntriesFromDictionary:domainsAndCertificates];
    
    NSString *path = [self plistFilePathForAccountId:accountId];
    NSDictionary *SSLPinsDict = [NSDictionary dictionaryWithContentsOfFile:[path stringByExpandingTildeInPath]];
    if (SSLPinsDict) {
        [finalPinsDict addEntriesFromDictionary:SSLPinsDict];
    }
    
    // Serialize the dictionary to a plist
    NSError *error;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:finalPinsDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&error];
    if (plistData == nil) {
        CleverTapLogStaticInfo(@"SSL pinning: the pinned certificates could not be converted into a file. Pinning is not set up. Reason: %@", error);
        return NO;
    }
    
    // Write the plist to a pre-defined location on the filesystem
    NSError *writeError;
    if ([plistData writeToFile:[[self plistFilePathForAccountId:accountId] stringByExpandingTildeInPath]
                       options:NSDataWritingAtomic
                         error:&writeError] == NO) {
        CleverTapLogStaticInfo(@"SSL pinning: the pinned certificate file could not be saved to the device. Pinning is not set up. Reason: %@", writeError);
        return NO;
    }
    
    return YES;
}


+ (BOOL)verifyPinnedCertificateForTrust:(SecTrustRef)trust andDomain:(NSString*)domain forAccountId:(NSString *)accountId {
    if ((trust == NULL) || (domain == nil)) {
        return NO;
    }
    
    // Deserialize the plist that contains our SSL pins
    NSString *path = [self plistFilePathForAccountId:accountId];
    NSDictionary *SSLPinsDict = [NSDictionary dictionaryWithContentsOfFile:[path stringByExpandingTildeInPath]];
    if (SSLPinsDict == nil) {
        CleverTapLogStaticInfo(@"SSL pinning: the pinned certificate file could not be read at %@. The connection is refused.", path);
        return NO;
    }

    // Do we have certificates pinned for this domain ?
    NSArray *trustedCertificates = [SSLPinsDict objectForKey:domain];
    if ((trustedCertificates == nil) || ([trustedCertificates count] < 1)) {
        CleverTapLogStaticInfo(@"SSL pinning: no certificate is pinned for the domain %@. The connection is refused.", domain);
        return NO;
    }
    
    // For each pinned certificate, check if it is part of the server's cert trust chain
    // We only need one of the pinned certificates to be in the server's trust chain
    for (NSData *pinnedCertificate in trustedCertificates) {
        
        // Check each certificate in the server's trust chain (the trust object)
        // Unfortunately the anchor/CA certificate cannot be accessed this way
        CFIndex certsNb = SecTrustGetCertificateCount(trust);
        for(int i=0;i<certsNb;i++) {
            
            // Extract the certificate
            SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, i);
            NSData* DERCertificate = (__bridge NSData*) SecCertificateCopyData(certificate);
            
            // Compare the two certificates
            if ([pinnedCertificate isEqualToData:DERCertificate]) {
                CFRelease((__bridge CFTypeRef)DERCertificate);
                return YES;
            }
            CFRelease((__bridge CFTypeRef)DERCertificate);
        }
        
        // Check the anchor/CA certificate separately
        SecCertificateRef anchorCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(pinnedCertificate));
        if (anchorCertificate == NULL) {
            break;
        }
        
        NSArray *anchorArray = [NSArray arrayWithObject:(__bridge id)(anchorCertificate)];
        if (SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)(anchorArray)) != 0) {
            CFRelease(anchorCertificate);
            break;
        }
        
        SecTrustResultType trustResult;
        SecTrustEvaluate(trust, &trustResult);
        if (trustResult == kSecTrustResultUnspecified) {
            // The anchor certificate was pinned
            CFRelease(anchorCertificate);
            return YES;
        }
        CFRelease(anchorCertificate);
    }
    // If we get here, we didn't find any matching certificate in the chain
    CleverTapLogStaticInfo(@"SSL pinning: the server certificate for the domain %@ does not match any of the %lu pinned certificates. The connection is refused. The pinned certificate may have expired, or the server may have been issued a new one.", domain, (unsigned long)[trustedCertificates count]);
    return NO;
}

@end
#endif
