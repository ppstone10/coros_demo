export function localizedAuthMessage(message: string): ResourceStr {
  switch (message) {
    case 'auth_error_auth_required': return $r('app.string.auth_error_auth_required');
    case 'auth_error_invalid_param': return $r('app.string.auth_error_invalid_param');
    case 'auth_error_account_exists': return $r('app.string.auth_error_account_exists');
    case 'auth_error_account_not_found': return $r('app.string.auth_error_account_not_found');
    case 'auth_error_password_incorrect': return $r('app.string.auth_error_password_incorrect');
    case 'auth_error_new_password_same_as_old': return $r('app.string.auth_error_new_password_same_as_old');
    case 'auth_error_verify_code_invalid': return $r('app.string.auth_error_verify_code_invalid');
    case 'auth_error_verify_code_expired': return $r('app.string.auth_error_verify_code_expired');
    case 'auth_error_empty_data': return $r('app.string.auth_error_empty_data');
    case 'auth_error_corrupted_data': return $r('app.string.auth_error_corrupted_data');
    case 'auth_error_persist_failed': return $r('app.string.auth_error_persist_failed');
    case 'auth_error_region_required': return $r('app.string.auth_error_region_required');
    case 'auth_validation_account_required': return $r('app.string.auth_validation_account_required');
    case 'auth_validation_password_required': return $r('app.string.auth_validation_password_required');
    case 'auth_validation_password_length': return $r('app.string.auth_validation_password_length');
    case 'auth_validation_phone_invalid': return $r('app.string.auth_validation_phone_invalid');
    case 'auth_validation_email_invalid': return $r('app.string.auth_validation_email_invalid');
    case 'auth_validation_verify_code_required': return $r('app.string.auth_validation_verify_code_required');
    case 'auth_validation_password_alphanumeric_only': return $r('app.string.auth_validation_password_alphanumeric_only');
    case 'auth_validation_password_letter_and_digit': return $r('app.string.auth_validation_password_letter_and_digit');
    case 'auth_validation_password_mismatch': return $r('app.string.auth_validation_password_mismatch');
    case 'auth_validation_register_incomplete': return $r('app.string.auth_validation_register_incomplete');
    case 'auth_validation_login_incomplete': return $r('app.string.auth_validation_login_incomplete');
    case 'auth_submit_failed': return $r('app.string.auth_submit_failed');
    case 'auth_password_updated': return $r('app.string.auth_password_updated');
    case 'auth_login_success': return $r('app.string.auth_login_success');
    case 'auth_register_success': return $r('app.string.auth_register_success');
    case 'auth_session_expired': return $r('app.string.auth_session_expired');
    case 'account_logout_success': return $r('app.string.account_logout_success');
    case 'account_delete_success': return $r('app.string.account_delete_success');
    case 'profile_saved': return $r('app.string.profile_saved');
    case 'profile_avatar_selection_failed': return $r('app.string.profile_avatar_selection_failed');
    case 'profile_camera_pending': return $r('app.string.profile_camera_pending');
    default: return message;
  }
}
