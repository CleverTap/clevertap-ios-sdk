#import "CTLogger.h"

extern NSString *const kCTApiDomain;
extern NSString *const kCTNotifViewedApiDomain;
extern NSString *const kHANDSHAKE_URL;

extern NSString *const kLastSessionPing;
extern NSString *const kLastSessionTime;
extern NSString *const kSessionId;

#define CleverTapLogInfo(level, fmt, ...)  if(level >= 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogDebug(level, fmt, ...) if(level > 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogInternal(level, fmt, ...) if (level > 1) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogStaticInfo(fmt, ...)  if([CTLogger getDebugLevel] >= 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogStaticDebug(fmt, ...) if([CTLogger getDebugLevel] > 0) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }
#define CleverTapLogStaticInternal(fmt, ...) if([CTLogger getDebugLevel] > 1) { NSLog((@"%@" fmt), @"[CleverTap]: ", ##__VA_ARGS__); }

#define CT_TRY @try {
#define CT_END_TRY }\
@catch (NSException *e) {\
[CTLogger logInternalError:e]; }

#pragma mark Constants for General data
#define CLTAP_REQUEST_TIME_OUT_INTERVAL 10
#define CLTAP_ACCOUNT_ID_LABEL @"CleverTapAccountID"
#define CLTAP_TOKEN_LABEL @"CleverTapToken"
#define CLTAP_REGION_LABEL @"CleverTapRegion"
#define CLTAP_PROXY_DOMAIN_LABEL @"CleverTapProxyDomain"
#define CLTAP_SPIKY_PROXY_DOMAIN_LABEL @"CleverTapSpikyProxyDomain"
#define CLTAP_DISABLE_APP_LAUNCH_LABEL @"CleverTapDisableAppLaunched"
#define CLTAP_USE_CUSTOM_CLEVERTAP_ID_LABEL @"CleverTapUseCustomId"
#define CLTAP_DISABLE_IDFV_LABEL @"CleverTapDisableIDFV"
#define CLTAP_ENABLE_FILE_PROTECTION @"CleverTapEnableFileProtection"
#define CLTAP_BETA_LABEL @"CleverTapBeta"
#define CLTAP_SESSION_LENGTH_MINS 20
#define CLTAP_SESSION_LAST_VC_TRAIL @"last_session_vc_trail"
#define CLTAP_FB_DOB_DATE_FORMAT @"MM/dd/yyyy"
#define CLTAP_GP_DOB_DATE_FORMAT @"yyyy-MM-dd"
#define CLTAP_APNS_PROPERTY_DEVICE_TOKEN @"device_token"
#define CLTAP_NOTIFICATION_CLICKED_EVENT_NAME @"Notification Clicked"
#define CLTAP_NOTIFICATION_VIEWED_EVENT_NAME @"Notification Viewed"
#define CLTAP_GEOFENCE_ENTERED_EVENT_NAME @"Geocluster Entered"
#define CLTAP_GEOFENCE_EXITED_EVENT_NAME @"Geocluster Exited"

#define CLTAP_SIGNED_CALL_OUTGOING_EVENT_NAME @"SCOutgoing"
#define CLTAP_SIGNED_CALL_INCOMING_EVENT_NAME @"SCIncoming"
#define CLTAP_SIGNED_CALL_END_EVENT_NAME @"SCEnd"

#define CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE @"lastDailyEventsPushedDate"
#define CLTAP_SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define CLTAP_APP_LAUNCHED_EVENT @"App Launched"
#define CLTAP_CHARGED_EVENT @"Charged"
#define CLTAP_EVENT_NAME @"evtName"
#define CLTAP_EVENT_DATA @"evtData"
#define CLTAP_CHARGED_EVENT_ITEMS @"Items"
#define CLTAP_ERROR_KEY @"wzrk_error"
#define CLTAP_WZRK_FETCH_EVENT @"wzrk_fetch"
#define CLTAP_PUSH_DELAY_SECONDS 1
#define CLTAP_PING_TICK_INTERVAL 1
#define CLTAP_LOCATION_PING_INTERVAL_SECONDS 10
#define CLTAP_INBOX_MSG_JSON_RESPONSE_KEY @"inbox_notifs"
#define CLTAP_DISPLAY_UNIT_JSON_RESPONSE_KEY @"adUnit_notifs"
#define CLTAP_FEATURE_FLAGS_JSON_RESPONSE_KEY @"ff_notifs"
#define CLTAP_PRODUCT_CONFIG_JSON_RESPONSE_KEY @"pc_notifs"
#define CLTAP_GEOFENCES_JSON_RESPONSE_KEY @"geofences"
#define CLTAP_PE_VARS_RESPONSE_KEY @"vars"
#define CLTAP_DISCARDED_EVENT_JSON_KEY @"d_e"
#define CLTAP_INAPP_CLOSE_IV_WIDTH 40
#define CLTAP_NOTIFICATION_ID_TAG @"wzrk_id"
#define CLTAP_NOTIFICATION_PIVOT @"wzrk_pivot"
#define CLTAP_NOTIFICATION_PIVOT_DEFAULT @"wzrk_default"
#define CLTAP_NOTIFICATION_CONTROL_GROUP_ID @"wzrk_cgId"
#define CLTAP_WZRK_PREFIX @"wzrk_"
#define CLTAP_NOTIFICATION_TAG_SECONDARY @"wzrk_"
#define CLTAP_NOTIFICATION_CLICKED_TAG @"wzrk_cts"
#define CLTAP_NOTIFICATION_TAG @"W$"
#define CLTAP_DATE_FORMAT @"yyyyMMdd"

#pragma mark Constants for App fields
#define CLTAP_APP_VERSION @"Version"
#define CLTAP_LATITUDE @"Latitude"
#define CLTAP_LONGITUDE @"Longitude"
#define CLTAP_OS_VERSION @"OS Version"
#define CLTAP_SDK_VERSION @"SDK Version"
#define CLTAP_CARRIER @"Carrier"
#define CLTAP_NETWORK_TYPE @"Radio"
#define CLTAP_CONNECTED_TO_WIFI @"wifi"
#define CLTAP_BLUETOOTH_VERSION @"BluetoothVersion"
#define CLTAP_BLUETOOTH_ENABLED @"BluetoothEnabled"

#pragma mark Constants for PE Variables
extern NSString *CT_KIND_INT;
extern NSString *CT_KIND_FLOAT;
extern NSString *CT_KIND_STRING;
extern NSString *CT_KIND_BOOLEAN;
extern NSString *CT_KIND_DICTIONARY;
extern NSString *CLEVERTAP_DEFAULTS_VARIABLES_KEY;
extern NSString *CLEVERTAP_DEFAULTS_VARS_JSON_KEY;

extern NSString *CT_PE_VARS_PAYLOAD_TYPE;
extern NSString *CT_PE_VARS_PAYLOAD_KEY;
extern NSString *CT_PE_VAR_TYPE;
extern NSString *CT_PE_NUMBER_TYPE;
extern NSString *CT_PE_BOOL_TYPE;
extern NSString *CT_PE_DEFAULT_VALUE;

extern NSString *CLTAP_PROFILE_IDENTITY_KEY;

#pragma mark Constants for In-App Notifications
#define CLTAP_INAPP_JSON_RESPONSE_KEY @"inapp_notifs"
#define CLTAP_INAPP_STALE_JSON_RESPONSE_KEY @"inapp_stale"
#define CLTAP_INAPP_GLOBAL_CAP_SESSION_JSON_RESPONSE_KEY @"imc"
#define CLTAP_INAPP_GLOBAL_CAP_DAY_JSON_RESPONSE_KEY @"imp"
#define CLTAP_INAPP_CS_JSON_RESPONSE_KEY @"inapp_notifs_cs"
#define CLTAP_INAPP_SS_JSON_RESPONSE_KEY @"inapp_notifs_ss"
#define CLTAP_INAPP_SS_APP_LAUNCHED_JSON_RESPONSE_KEY @"inapp_notifs_applaunched"
#define CLTAP_INAPP_MODE_JSON_RESPONSE_KEY @"inapp_delivery_mode"

#define CLTAP_INAPP_SHOWN_TODAY_META_KEY @"imp"
#define CLTAP_INAPP_COUNTS_META_KEY @"tlc"
#define CLTAP_INAPP_SS_EVAL_META_KEY @"inapps_eval"
#define CLTAP_INAPP_SUPPRESSED_META_KEY @"inapps_suppressed"
#define CLTAP_INAPP_SS_EVAL_STORAGE_KEY @"inapps_eval"
#define CLTAP_INAPP_SUPPRESSED_STORAGE_KEY @"inapps_suppressed"

#define CLTAP_PREFS_INAPP_SESSION_MAX_KEY @"imc_max"
#define CLTAP_PREFS_INAPP_LAST_DATE_KEY @"ict_date"
#define CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY @"counts_per_inapp"
#define CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY @"istc_inapp"
#define CLTAP_PREFS_INAPP_MAX_PER_DAY_KEY @"istmcd_inapp"
#define CLTAP_PREFS_INAPP_LOCAL_INAPP_COUNT_KEY @"local_in_app_count"

#define CLTAP_PREFS_INAPP_KEY @"inapp_notifs"
#define CLTAP_PREFS_INAPP_KEY_CS @"inapp_notifs_cs"
#define CLTAP_PREFS_INAPP_KEY_SS @"inapp_notifs_ss"

#define CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS @"cs_inapp_active_assets"
#define CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS @"cs_inapp_inactive_assets"
#define CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS @"cs_inapp_assets_last_deleted_timestamp"

#define CLTAP_PROP_CAMPAIGN_ID @"Campaign id"
#define CLTAP_PROP_WZRK_ID @"wzrk_id"
#define CLTAP_PROP_VARIANT @"Variant"
#define CLTAP_PROP_WZRK_PIVOT @"wzrk_pivot"

#define CLTAP_INAPP_ID @"ti"
#define CLTAP_INAPP_TTL @"wzrk_ttl"
#define CLTAP_INAPP_CS_TTL_OFFSET @"wzrk_ttl_offset"
#define CLTAP_INAPP_PRIORITY @"priority"
#define CLTAP_INAPP_IS_SUPPRESSED @"suppressed"
#define CLTAP_INAPP_MAX_PER_SESSION @"mdc"
#define CLTAP_INAPP_TOTAL_DAILY_COUNT @"tdc"
#define CLTAP_INAPP_TOTAL_LIFETIME_COUNT @"tlc"
#define CLTAP_INAPP_EXCLUDE_FROM_CAPS @"efc"
#define CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS @"excludeGlobalFCaps"

#define CLTAP_TRIGGER_BOOL_STRING_YES @"true"
#define CLTAP_TRIGGER_BOOL_STRING_NO @"false"

// whenTriggers
#define CLTAP_INAPP_TRIGGERS @"whenTriggers"

// whenLimits
#define CLTAP_INAPP_FC_LIMITS @"frequencyLimits"
#define CLTAP_INAPP_OCCURRENCE_LIMITS @"occurrenceLimits"

#define CLTAP_INAPP_DATA_TAG @"d"
#define CLTAP_INAPP_HTML @"html"
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

#define CLTAP_INAPP_HTML_TYPE @"custom-html"

#define CLTAP_INAPP_TYPE @"type"
#define CLTAP_INAPP_TEMPLATE_NAME @"templateName"
#define CLTAP_INAPP_TEMPLATE_ID @"templateId"
#define CLTAP_INAPP_TEMPLATE_DESCRIPTION @"templateDescription"
#define CLTAP_INAPP_VARS @"vars"
#define CLTAP_INAPP_ACTIONS @"actions"

#define CLTAP_INAPP_PREVIEW_TYPE @"wzrk_inapp_type"
#define CLTAP_INAPP_IMAGE_INTERSTITIAL_TYPE @"image-interstitial"
#define CLTAP_INAPP_IMAGE_INTERSTITIAL_CONFIG @"imageInterstitialConfig"
#define CLTAP_INAPP_HTML_SPLIT @"\"##Vars##\""
#define CLTAP_INAPP_IMAGE_INTERSTITIAL_HTML_NAME @"image_interstitial"

#pragma mark Constants for persisting Facebook data
#define CLTAP_FB_NAME @"fbName"
#define CLTAP_FB_ID @"fbId"
#define CLTAP_FB_EMAIL @"fbEmail"
#define CLTAP_FB_GENDER @"fbGender"
#define CLTAP_FB_EDUCATION @"fbEducation"
#define CLTAP_FB_EMPLOYED @"fbEmployed"
#define CLTAP_FB_DOB @"fbDOB"
#define CLTAP_FB_MARRIED @"fbMarried"

#pragma mark Constants for persisting G+ data
#define CLTAP_GP_NAME @"gpName"
#define CLTAP_GP_ID @"gpId"
#define CLTAP_GP_EMAIL @"gpEmail"
#define CLTAP_GP_GENDER @"gpGender"
#define CLTAP_GP_EMPLOYED @"gpEmployed"
#define CLTAP_GP_DOB @"gpDOB"
#define CLTAP_GP_MARRIED @"gpMarried"

#pragma mark Constants for persisting system data
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

#pragma mark Constants for profile init/sync notifications
#define CLTAP_PROFILE_DID_INITIALIZE_NOTIFICATION @"CleverTapProfileDidInitializeNotification"
#define CLTAP_PROFILE_DID_CHANGE_NOTIFICATION @"CleverTapProfileDidChangeNotification"

#pragma mark Constants for Inbox notifications
#define CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION @"CleverTapInboxMessageTappedNotification"
#define CLTAP_INBOX_MESSAGE_MEDIA_PLAYING_NOTIFICATION @"CleverTapInboxMediaPlayingNotification"
#define CLTAP_INBOX_MESSAGE_MEDIA_MUTED_NOTIFICATION @"CleverTapInboxMediaMutedNotification"

#pragma mark Constants for Geofences update notification
#define CLTAP_GEOFENCES_DID_UPDATE_NOTIFICATION @"CleverTapGeofencesDidUpdateNotification"

#pragma mark Constants for Profile identifier keys
#define CLTAP_PROFILE_IDENTIFIER_KEYS @[@"Identity", @"Email"] // LEGACY KEYS
#define CLTAP_ALL_PROFILE_IDENTIFIER_KEYS @[@"Identity", @"Email", @"Phone"]

#pragma mark Constants for Encryption
#define CLTAP_ENCRYPTION_LEVEL @"CleverTapEncryptionLevel"
#define CLTAP_ENCRYPTION_IV @"__CL3>3Rt#P__1V_"
#define CLTAP_ENCRYPTION_PII_DATA (@[@"Identity", @"userEmail", @"userPhone", @"userName"]);


