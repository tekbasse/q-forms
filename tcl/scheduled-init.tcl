# q-forms/tcl/scheduled-init.tcl

# Schedule recurring procedures

#    @creation-date 2016-09-02
#    @Copyright (c) 2016 Benjamin Brink
#    @license GNU General Public License 2, see project home
#    @project home: http://github.com/tekbasse/q-forms
#    @address: po box 20, Marylhurst, OR 97036-0020 usa
#    @email: tekbasse@yahoo.com


# Scheduled proc scheduling:
# Nightly pi time + 1 = 4:14am
#ns_schedule_daily -thread 4 14 hf::proc...


set cycle_duration_s [expr { round( 120 + [randomRange 60] ) } ]


ad_schedule_proc -thread t $cycle_duration_s qf::schedule::flush


