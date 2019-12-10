#import "CTLogger.h"

extern NSString *const kCTApiDomain;
extern NSString *const kCTNotifViewedApiDomain;

#define CleverTapLogInfo(level, fmt, ...)  if(level >= 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogDebug(level, fmt, ...) if(level > 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogInternal(level, fmt, ...) if (level > 1) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogStaticInfo(fmt, ...)  if([CTLogger getDebugLevel] >= 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogStaticDebug(fmt, ...) if([CTLogger getDebugLevel] > 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogStaticInternal(fmt, ...) if([CTLogger getDebugLevel] > 1) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }

#define CLTAP_REQUEST_TIME_OUT_INTERVAL 10
#define CLTAP_ACCOUNT_ID_LABEL @"CleverTapAccountID"
#define CLTAP_TOKEN_LABEL @"CleverTapToken"
#define CLTAP_REGION_LABEL @"CleverTapRegion"
#define CLTAP_DISABLE_APP_LAUNCH_LABEL @"CleverTapDisableAppLaunched"
#define CLTAP_USE_IFA_LABEL @"CleverTapUseIFA"
#define CLTAP_USE_CUSTOM_CLEVERTAP_ID_LABEL @"CleverTapUseCustomId"
#define CLTAP_BETA_LABEL @"CleverTapBeta"
#define CLTAP_SESSION_LENGTH_MINS 20
#define CLTAP_SESSION_LAST_VC_TRAIL @"last_session_vc_trail"
#define CLTAP_FB_DOB_DATE_FORMAT @"MM/dd/yyyy"
#define CLTAP_GP_DOB_DATE_FORMAT @"yyyy-MM-dd"
#define CLTAP_APNS_PROPERTY_DEVICE_TOKEN @"device_token"
#define CLTAP_NOTIFICATION_CLICKED_EVENT_NAME @"Notification Clicked"
#define CLTAP_NOTIFICATION_VIEWED_EVENT_NAME @"Notification Viewed"
#define CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE @"lastDailyEventsPushedDate"
#define CLTAP_SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define CLTAP_APP_LAUNCHED_EVENT @"App Launched"
#define CLTAP_ERROR_KEY @"wzrk_error"
#define CLTAP_PUSH_DELAY_SECONDS 1
#define CLTAP_PING_TICK_INTERVAL 1
#define CLTAP_LOCATION_PING_INTERVAL_SECONDS 10
#define CLTAP_INAPP_SESSION_MAX @"imc_max"
#define CLTAP_INAPP_DATA_TAG @"html"
#define CLTAP_INAPP_X_PERCENT @"xp"
#define CLTAP_INAPP_Y_PERCENT @"yp"
#define CLTAP_INAPP_X_DP @"xdp"
#define CLTAP_INAPP_Y_DP @"ydp"
#define CLTAP_INAPP_POSITION @"pos"
#define CLTAP_INAPP_POSITION_TOP 't'
#define CLTAP_INAPP_POSITION_RIGHT 'r'
#define CLTAP_INAPP_POSITION_BOTTOM 'b'
#define CLTAP_INAPP_POSITION_LEFT 'l'
#define CLTAP_INAPP_POSITION_CENTER 'c'
#define CLTAP_INAPP_NOTIF_DARKEN_SCREEN @"dk"
#define CLTAP_INAPP_NOTIF_SHOW_CLOSE @"sc"
#define CLTAP_INAPP_JSON_RESPONSE_KEY @"inapp_notifs"
#define CLTAP_INBOX_MSG_JSON_RESPONSE_KEY @"inbox_notifs"
#define CLTAP_DISPLAY_UNIT_JSON_RESPONSE_KEY @"adUnit_notifs"
#define CLTAP_PREFS_INAPP_KEY @"inapp_notifs"
#define CLTAP_AB_EXP_JSON_RESPONSE_KEY @"ab_exps"
#define CLTAP_INAPP_CLOSE_IV_WIDTH 40
#define CLTAP_NOTIFICATION_ID_TAG @"wzrk_id"
#define CLTAP_WZRK_PREFIX @"wzrk_"
#define CLTAP_NOTIFICATION_TAG_SECONDARY @"wzrk_"
#define CLTAP_NOTIFICATION_CLICKED_TAG @"wzrk_cts"
#define CLTAP_NOTIFICATION_TAG @"W$"

// Constants for persisting Facebook data
#define CLTAP_FB_NAME @"fbName"
#define CLTAP_FB_ID @"fbId"
#define CLTAP_FB_EMAIL @"fbEmail"
#define CLTAP_FB_GENDER @"fbGender"
#define CLTAP_FB_EDUCATION @"fbEducation"
#define CLTAP_FB_EMPLOYED @"fbEmployed"
#define CLTAP_FB_DOB @"fbDOB"
#define CLTAP_FB_MARRIED @"fbMarried"

// Constants for persisting G+ data
#define CLTAP_GP_NAME @"gpName"
#define CLTAP_GP_ID @"gpId"
#define CLTAP_GP_EMAIL @"gpEmail"
#define CLTAP_GP_GENDER @"gpGender"
#define CLTAP_GP_EMPLOYED @"gpEmployed"
#define CLTAP_GP_DOB @"gpDOB"
#define CLTAP_GP_MARRIED @"gpMarried"

// Constants for persisting system data
#define CLTAP_SYS_CARRIER @"sysCarrier"
#define CLTAP_SYS_CC @"sysCountryCode"
#define CLTAP_SYS_TZ @"sysTZ"

#define CLTAP_USER_NAME @"userName"
#define CLTAP_USER_EMAIL @"userEmail"
#define CLTAP_USER_EDUCATION @"userEducation"
#define CLTAP_USER_MARRIED @"userMarried"
#define CLTAP_USER_DOB @"userDOB"
#define CLTAP_USER_BIRTHDAY @"userBirthday"
#define CLTAP_USER_EMPLOYED @"userEmployed"
#define CLTAP_USER_GENDER @"userGender"
#define CLTAP_USER_PHONE @"userPhone"
#define CLTAP_USER_AGE @"userAge"

#define CLTAP_OPTOUT @"ct_optout"

// profile init/sync notifications
#define CLTAP_PROFILE_DID_INITIALIZE_NOTIFICATION @"CleverTapProfileDidInitializeNotification"
#define CLTAP_PROFILE_DID_CHANGE_NOTIFICATION @"CleverTapProfileDidChangeNotification"

// inbox notifications
#define CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION @"CleverTapInboxMessageTappedNotification"
#define CLTAP_INBOX_MESSAGE_MEDIA_PLAYING_NOTIFICATION @"CleverTapInboxMediaPlayingNotification"
#define CLTAP_INBOX_MESSAGE_MEDIA_MUTED_NOTIFICATION @"CleverTapInboxMediaMutedNotification"

// valid profile identifier keys
#define CLTAP_PROFILE_IDENTIFIER_KEYS @[@"Identity", @"Email", @"FBID", @"GPID"]
