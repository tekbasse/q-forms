# q-forms/tcl/scheduled-procs.tcl
ad_library {

    library for Scheduled procedures of Hosting Farm
    @creation-date 2014-09-12
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/q-forms
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}

namespace eval qf::schedule {}


ad_proc -private qf::schedule::flush {

} {
    flushes used data and unused forms
} {
    set success_p 1
    # flush used forms

    set key_list [db_list qf_sched_keys_r {select sh_key_id from qf_key_map 
        where submit_timestamp is not null} ]
    set count [llength $key_list]
    if { $count > 0 } {
        ns_log Notice "qf::schedule::flush '${count}' used items"
        db_transaction {
            db_dml qf_sched_qf_key_map_d "delete from qf_key_map 
                where sh_key_id in ([template::util::tcl_to_sql_list $key_list])"
            db_dml qf_sched_qf_name_value_pairs_d "delete from qf_name_value_pairs 
                where sh_key_id in ([template::util::tcl_to_sql_list $key_list])"
        } on_error {
            ns_log Error "qf::schedule::flush.34: Error is: '${errmsg}'"
            set success_p 0
        }
    }

    # flush old forms
    # 3600 = 1 hour,  14400 = 4 hours
    set timeout_s 14400
    set stale_timestamp [expr { [ns_time] - $timeout_s } ]
    set key_list [db_list qf_sched_keys_r {select sh_key_id from qf_key_map 
        where submit_timestamp is null 
        and rendered_timestamp < :stale_timestamp } ]
    set count [llength $key_list]
    if { $count > 0 } {
        ns_log Notice "qf::schedule::flush '${count}' stale items"
        db_transaction {
            db_dml qf_sched_qf_key_map_d "delete from qf_key_map 
                where sh_key_id in ([template::util::tcl_to_sql_list $key_list])"
            db_dml qf_sched_qf_name_value_pairs_d "delete from qf_name_value_pairs 
                where sh_key_id in ([template::util::tcl_to_sql_list $key_list])"
        } on_error {
            ns_log Error "qf::schedule::flush.51: Error is: '${errmsg}'"
            set success_p 0
        }
    }

    return $success_p
}

