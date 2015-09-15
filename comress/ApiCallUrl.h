//
//  ApiCallUrl.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#ifndef comress_ApiCallUrl_h
#define comress_ApiCallUrl_h

static NSString * AFkey_allowInvalidCertificates = @"allowInvalidCertificates";

static NSString *google_api_key = @"AIzaSyDAD3ZNjQ4n3AfqV-IIOklSiLbmyfX7IWo";

static NSString *google_ios_api_key = @"AIzaSyBp8nNVujNkbk13h2W05vJDZYOPvlhdiLE"; //we use this for google places api


static NSString *api_activationUrl = @"http://fmit.com.sg/comressmainservice/AddressManager.svc/json/GetUrlAddress/?group=";

static NSString *app_path = @"ComressMWCF/v1.02/";

static NSString *api_login = @"User.svc/ComressLogin";

static NSString *api_logout = @"User.svc/Logout?sessionId=";

static NSString *api_post_send = @"Messaging/Post.svc/UploadPost";

static NSString *api_comment_send = @"Messaging/Comment.svc/UploadComment";

static NSString *api_send_images = @"Messaging/PostImage.svc/UploadImageWithBase64";

static NSString *api_download_blocks = @"PublicSetup.svc/GetBlocks";

static NSString *api_download_user_blocks = @"Job/Block.svc/GetBlocksByUser";

static NSString *api_update_device_token = @"User.svc/UpdateDeviceToken?";

static NSString *api_download_posts = @"Messaging/Post.svc/GetPosts";

static NSString *api_download_comments = @"Messaging/Comment.svc/GetComments";

static NSString *api_download_images = @"Messaging/PostImage.svc/GetImages";

static NSString *api_download_comment_noti = @"Messaging/CommentNoti.svc/GetCommentNotis";

static NSString *api_upload_comment_noti = @"Messaging/CommentNoti.svc/UpdateStatusAfterRead";

static NSString *api_update_status_after_read = @"Messaging/CommentNoti.svc/UpdateStatusAfterRead";

static NSString *api_update_post_status = @"Messaging/Post.svc/UpdatePostActionStatus";

static NSString *api_download_user_block_mapping =  @"Job/Block.svc/GetBlockUserMapping";

static NSString *api_send_app_version = @"User.svc/UpdateAppVersion?";

static NSString *api_download_contract_types = @"Job/Contract.svc/GetContractTypes";

static NSString *api_download_public_contract_types = @"PublicSetup.svc/GetContractTypes";

static NSString *api_upload_reassign_posts = @"Messaging/Post.svc/UploadReAssignPost";


//routine
static NSString *api_download_block_schedule = @"Job/ScheduledBlock.svc/GetScheduledBlock";

static NSString *api_upload_unlock_block_info = @"Job/LockProcess.svc/UploadUnlockInfo";

static NSString *api_get_job_list_for_block = @"Job/Schedule.svc/GetSUPSchedulesByBlk";

static NSString *api_get_schedule_detail_by_sup = @"Job/Schedule.svc/GetScheduleDetailBySup";

static NSString *api_upload_schedule_image = @"Job/Schedule.svc/UploadScheduleImageWithBase64";


//feedback

static NSString *api_download_fed_questions = @"Survey/Question.svc/GetQuestions";

static NSString *api_upload_survey =  @"Survey/Survey.svc/UploadSurvey";

static NSString *api_download_survey = @"Survey/Survey.svc/GetSurveys";

static NSString *api_upload_crm = @"Survey/Survey.svc/UploadCRMIssue";

static NSString *api_download_feedback_issues = @"Survey/Survey.svc/GetFeedbackIssues";

static NSString *api_upload_resident_info_edit = @"Survey/Survey.svc/UpdateResidentInfo";

static NSString *api_upload_crm_image = @"Survey/Survey.svc/UploadCRMImageWithBase64";


//report

static NSString *api_survey_report_total_survey_pm = @"Survey/Report.svc/GetTotalSurveyAndFeedbackByPM";

static NSString *api_survey_report_total_issue_pm = @"Survey/Report.svc/GetTotalIssueWithStatusByPM";

static NSString *api_survey_report_average_sentiment = @"Survey/Report.svc/GetAverageSentiment";

static NSString *api_survey_report_average_sentiment_border = @"Job/Block.svc/GetBorder";

static NSString *api_survey_report_total_issue_po = @"Survey/Report.svc/GetTotalIssueWithStatusByPO";

static NSString *api_survey_report_total_survey_po = @"Survey/Report.svc/GetTotalSurveyAndFeedbackByPO";

static NSString *api_survey_report_get_divisions = @"Job/Block.svc/GetDivistions";

static NSString *api_survey_report_get_zones = @"Job/Block.svc/GetZones";


//generic webview
static NSString *user_manual_po = @"http://comress.fmit.sg/ComressMWCF/doc/UserGuide.pdf";

static NSString *user_manual_ct = @"http://comress.fmit.sg/ComressMWCF/doc/UserGuideForContractor.pdf";


//settings
static NSString *inactive_days = @"Messaging/Post.svc/GetNumberOfInactivityDays";

static NSString *action_setting = @"Messaging/Post.svc/GetActionSetting";











//routine-old

static NSString *api_download_checklist = @"Job/Setup.svc/GetCheckLists";

static NSString *api_download_checkarea = @"Job/Setup.svc/GetCheckAreas";

static NSString *api_download_scan_checklist_blk =  @"Job/Setup.svc/GetScanCheckListBlks";

static NSString *api_download_scan_checklist = @"PublicSetup.svc/GetScanCheckLists";

static NSString *api_download_jobs = @"Job/Setup.svc/GetJobs";

static NSString *api_download_sup_sked = @"Job/Schedule.svc/GetSUPSchedules";

static NSString *api_download_spo_sked = @"Job/Schedule.svc/GetSPOSchedules";

static NSString *api_updated_sup_sked = @"Job/Schedule.svc/UpdateSchedulesBySUP";

static NSString *api_update_spo_sked = @"Job/Schedule.svc/UpdateSchedulesBySPO";

static NSString *api_upload_scan_blk = @"Job/ScanBlock.svc/UploadScanBlock";

static NSString *api_upload_scan_inspection = @"Job/ScanInspection.svc/UploadScanInspection";

static NSString *api_upload_inspection_res = @"Job/InspectionResult.svc/UploadInspectionResult";

static NSString *api_download_sup_active_blocks = @"Job/Block.svc/GetActiveSUPBlocks";

#endif



