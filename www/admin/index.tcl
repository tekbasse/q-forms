set title "#acs-subsite.Administration#"
set context [list ]



set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
if { !$admin_p } {
    ad_redirect_for_registration
    ad_script_abort
}

