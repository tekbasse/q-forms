ad_library {

    routines for presenting tcl list of lists as a paginated html table
    @creation-date 14 May 2018
    @Copyright (c) 2018 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl.html
    @project home: http://github.com/tekbasse/q-forms
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com
}

# Define namespace for utility procs
namespace eval ::qfo {}

ad_proc -public qfo_sp_table_g2 {
    {-base_url ""}
    {-columns_hide_index_list ""}
    {-columns_justify_list ""}
    {-item_count ""}
    {-items_per_page "12" }
    {-list_length_limit ""}
    {-nav_current_pos_html_varname "__qfsp_nav_current_pos_html"}
    {-nav_next_links_html_varname "__qfsp_nav_next_links_html"}
    {-nav_prev_links_html_varname "__qfsp_nav_prev_links_html"}
    {-p_varname "__qfsp_p"}
    {-page_num_p "0"}
    {-s_varname "__qfsp_s"}
    {-separator "&nbsp;"}
    {-sort_type_list ""}
    {-sorted_first_attributes {style="font-family: monospace; font-size: 60%; font-style: normal; vertical-align: super;"}}
    {-sorted_last_attributes {style="font-family: monospace; font-size: 46%; font-style: normal; vertical-align: sub; margin-left: -0.63em;"}}
    {-table_html_varname "__qfsp_table_html"}
    {-table_lists_varname "__qfsp_table_lists"}
    {-table_sorted_lists_varname "__qfsp_table_sorted_lists"}
    {-table_sorted_paginated_lists_varname "__qfsp_table_sorted_paginated_lists"}
    {-table_sorted_reordered_lists_varname "__qfsp_table_sorted_reordered_lists"}
    {-table_tag_attribute_list {{class} {list-table} {cellpadding} {3} {cellspacing} {1}}}
    {-td_number_attribute_list {{style} {text-align: left;}}}
    {-td_nonnumber_attribute_list {{style} {text-align: right;}}}
    {-td_attribute_list {{class} {list-table}}}
    {-td_sorted_attribute_list {}}
    {-td_unsorted_attribute_list {{style} {opacity:0.9;}}}
    {-th_sorted_attribute_list {{style} {text-align: center; border: 1px solid #999; background-color: #eef;}}}
    {-th_unsorted_attribute_list {{style} {text-align: center; border: 1px solid #999; line-height: 90%;}}}
    {-this_start_row "1"}
    {-titles_html_list_varname "__qfsp_titles_html_list"}
    {-titles_list_varname "__qfsp_titles_list"}
    {-titles_reordered_html_list_varname "__qfsp_titles_reordered_html"}
    {-titles_reordered_list_varname "__qfsp_reordered_list"}
    {-tr_even_attribute_list {{class} {even}}}
    {-tr_header_attribute_list {{class} {list-table}}}
    {-tr_odd_attribute_list {{class} {odd}}}
    {-unsorted_attributes {style="font-family: monospace; font-size: 70%; font-style: normal; vertical-align: baseline; line-height: 1em; padding: 0; margin: 0;"}}
} {
    Creates a user customizable sorted, responsive table by
    creating a one row header into html and a table into html, 
    and complementary navigation links. This proc exposes the html elements
    TABLE TR TH TD  (open and closing bracketed ones) so that a responsive
    table can be defined instead of a classic html one.
    <br><br>
    The table and titles are exposed at various steps in the process, 
    so that customizations may be made without having to
    re-work the core functionality. 
    (The api could include new proces of this one split into its stages 
     for optimization if customization proves to be a common, practical need.)
    <strong>Highlighted parameters</strong> indicate which parameters
    provide features this proc is specificially optimized for.
    <br><br>
    Outputs are:    <br><br>
    <ul><li>These three variables hold components of a nav bar:
    <ul><li><strong>nav_prev_links_html_varname</strong></li>
    <li><strong>nav_current_pos_html_varname</strong></li>
    <li><strong>nav_next_links_html_varname</strong></li>
    </ul></li>
    <li>
    <code>table_lists_varname</code> is unchanged. 
    It gets sorted into <code>table_sorted_lists_varname</code>.
    Then the columns are re-ordered based on sort significance,
    with the primary sort column first and set to
    <code>table_sorted_reordered_lists_varname</code>.
    For tables, the progression of processing is:
    <ol><li>
    <code>table_lists_varname</code> (input, unchanged)
    </li><li>
    <code>table_sorted_lists_varname</code>
    </li><li>
    <code>table_sorted_paginated_lists_varname</code>
    </li><li>
    <code>table_sorted_reordered_lists_varname</code>
    </li><li>
    <strong><code>table_html_varname</code></strong>
    </li></ol>
    <br>
    For titles, the progression is:
    <ol><li>
    <code>titles_list_varname</code> (input, unchanged)
    </li><li>
    <code>titles_html_list_varname</code>  
    This heading row includes html for form-based UI for p and s parameters
    </li><li>
    <code>titles_reordered_list_varname</code> 
    This is the titles list re-ordered according to sort order significance, 
    with primary sort order in first column. 
    Columns are re-organized same as <code>table_sorted_reordered_lists_varname</code>.
    </li><li>
    <code>titles_reordered_html_list_varname</code>
    This is <code>titles_html_list_varname</code> with columns re-ordered 
    according to sort order significance.
    This is added to <code>table_html_varname</code>, so that
    no title-based output is specifically an optimized feature, and therefore 
    highlighted. However, this would be the closest result.
    </li></ul>

    <br><br>
    To sort by timestamp, 
    use '-dictionary' sort type,
    and a consistent length format for the column values, 
    such as ISO-8601 format: "YYYY-MM-DD HH:MM:SS". See: http://wiki.tcl.tk/1277
    <br><br>
    Required parameters:
    <br><br>
    <code>table_lists_varname</code> 
    - Variable holding a table defined as a list of lists, 
    where each list is a row containing values of columns from first to last.
    <br><br>
    <code>titles_list_varname</code> 
    - Variable name containing a list of titles of the columns in 
    <code>table_lists</code>, in cooresponding order. 
    That is first in list is title of first column in table.
    <br><br>
    An <code>s_varname</code> or <code>p_varname</code> that identifies
    at least one sorted column.
    This is not a proc based requirement, but the proc's pagination navigation
    is fairly useless unless there is some default order provided
    usually via a one column sort supplied by <code>s_varname</code>.
    See optional parameters section for details on using <code>s_varname</code>.
    <br><br>
    Optional parameters:<br>
    <br><br>
    <code>columns_justify_list</code> To force a column's data to justify
    to the left, right, center, or (fill) justify,
    create a list with lowercase elements beginning with l,r,c, f or j.
    The first index in a tcl list is '0' for column 0, second index is '1'..
    <br><br>
    <code>items_per_page</code> - number of rows (items) per page
    <br><br>
    <code>item_count</code> - number of rows (items) in the table.
    <br><br>
    <code>this_start_row</code> 
    - start row (item sequence number) for this page. First row is 1 even though tcl usually uses 0.
    <br><br>
    <code>base_url</code> - url for building page links
    <br><br>
    <code>separator</code> 
    - html used between page numbers in pagination bar, defaults to '&nbsp;'
    <br><br>
    <code>list_limit</code> - limits the list to this many items.
    <br><br>
    <code>page_num_p</code> 
    - Answers question: Use the page number in pagniation bar's display? 
    If not, the first value of the left-most (primary sort) column is used.
    <br><br>
    <code>s_varname</code> 
    - 's' is a sort_order_list as defined by the code and passed via a form. 
    It's an 'a' delimited list of column indexes of table 
    to be sorted in reverse order, 
    so that primary sort is the first in the list. 
    Secondary sort is the second in the list and on.
    For example, to indicate that the second column should be sorted in
    decreasing order,  set the value to: "-1", 
    because the first column's index is the same as Tcl's list indexing of zero.
    <br><br>
    <code>p_varname</code>
    - 'p' is a change of the sort_order_list 
    to now make this index the primary sort index. See code for details.
    <br><br>
    <code>sort_type_list</code>
    - A list of types of sort to use for each column when using 
    <code>lsort -index &lt;column&gt; -ascii &lt;list_of_lists&gt;</code> 
    to sort a table by a specific column. 
    The default value for each column is "-ascii", per tcl's default. 
    When specifying sort_type_list, define a type to use for each column. 
    For example:
    \[list "-ascii" "-dictionary" "-ascii" "-ascii" "-real" \] for a table withfive columns.
    Note: <strong>To indicate that a column is unsortable use "-ignore"</strong>
    <br><br>
    <br><br>
    <br><br>
    *_attributes attributes may be passed as a list or string. If a comma or tab character are detected, a string will be split by comma or tab delimiter. Specically, this feature is for the following parameters:<br>
    <ul><li>
    <code>tr_even_attributes</code> Applies to even numbered rows
    </li><li>
    <code>tr_odd_attributes</code> Applies to odd numbered rows
    </li><li>
    <code>td_left_attributes</code> To left justify text in TD tags
    </li><li>
    <code>td_right_attributes</code> To right justified text in TD tags
    </li><li>
    <code>td_center_attributes</code> To center justify text in TD tags
    </li><li>
    <code>td_fill_attributes</code> To fill justify text in TD tags
    </li><li>
    <code>td_sorted_attributes</code> Applies to sorted column TD tags
    </li><li>
    <code>td_unsorted_attributes</code> Applies to unsorted column TD tags
    </li></ul>
    <br><br>
    <code>columns_hide_index_list</code> - To hide a column from display,
    add its tcl index number to this list.
    The first index in a tcl list is '0', second index is '1'..
    <br><br>
    <code>columns_justify_list</code> If present, a list of letters where position in list cooresponds to table columns, and where each element indicates a left, center, right, or fill justify. Only the first letter of each element is examined. The default is to right justify numbers, and left justify everything else.
    <br><br>
    Passes html as a string wrapping the links in the title elements that change the sort pattern. The variations permit some indication of sort status for sorted columns separate from unsorted ones. Specifically, refers to the following parameters:<br>
    <ul><li>
    <code>sorted_first_attributes</code> Html preceding 'first sort' change link for a title that has been sorted.
    </li><li>
    <code>sorted_last_attributes</code> Html preceding 'last sort' change link for a title that has been sorted.
    </li><li>
    <code>unsorted_attributes</code> Html preceding 'first sort' change link for a title that has not been sorted.
    </li></ul>
    Note: Unsorted are wrapped by same html for first and last sort links.  Sorted links are wrapped individually.
} {
    upvar 1 $nav_current_pos_html_varname nav_current_pos_html
    upvar 1 $nav_next_links_html_varname nav_next_links_html
    upvar 1 $nav_prev_links_html_varname nav_prev_links_html
    upvar 1 $p_varname p
    upvar 1 $s_varname s
    upvar 1 $table_html_varname table_html
    upvar 1 $table_lists_varname table_lists
    upvar 1 $table_sorted_lists_varname table_sorted_lists
    upvar 1 $table_sorted_paginated_lists_varname table_sorted_paginated_lists
    upvar 1 $table_sorted_reordered_lists_varname table_sorted_reordered_lists
    upvar 1 $titles_html_list_varname titles_html_list
    upvar 1 $titles_list_varname titles_list
    upvar 1 $titles_reordered_html_list_varname titles_reordered_html_list
    upvar 1 $titles_reordered_list_varname titles_reordered_list
    

    # adapting from:
    # hosting-farm/lib/resource-status-summary-1.tcl

    # This version requires the entire table to be loaded for processing.
    # TODO: make another version that uses pg's select limit and offset.. 
    # to scale for larger datasets.

    # General process flow:
    # 1. Get table as table_lists
    # 2. Sort unformatted columns by row values
    # 3. Pagination_bar -- calcs including list_limit, build UI
    # 4. Sort UI -- build
    # 5. Reduce table to page from paginate parameters
    # 6. Re-order columns, primary sorted first, secondary second..
    # 7. Format output with CSS and html

    # ================================================
    # 1. Get table as list_of_lists
    # ================================================
    # Don't process list_limit here.
    
    # Set defaults and validation
    set a_h "a"

    # normalize page_num_p's value
    set page_num_p [qf_is_true $page_num_p ]
    
    if { $base_url eq "" } {
        set base_url [ad_conn url ]
    }    
    set page_html ""
    if { ![qf_is_natural_number $this_start_row ] } {
        set this_start_row 1
    }
    if  { $item_count eq "" } {
        set item_count [llength $table_lists ]
    }
    if { ![info exists s ] } {
        set s ""
    }
    if { ![info exists p ] } {
        set p ""
    }
    if { $item_count eq 0 } {
        set titles_html_list ""
        set table_html "#acs-subsite.none#"
        return 0
    }

    # ================================================
    # 2. Sort unformatted columns by row values
    # ================================================
    # Sort Table Columns
    # arguments
    #     s            a coded sort_order_list (via form post)
    #     p            primary_sort_col_new (via form post)
    #     table_lists  table represented as a list of lists
    # ================================================
    # Output:
    #   sort_order_list


    set table_cols_count [llength [lindex $table_lists 0 ] ]
    set col_idx_max [expr { $table_cols_count - 1 } ]
    # defaults and inputs
    if { $sort_type_list eq "" } {
        set sort_type_list [lrepeat $table_cols_count "-ascii" ]
    }


    # int_sequence_list is used as a column reference map.
    # That is, position N in list is column number in new/wip table, and
    # the value in position N points to a column in original tables_list.
    set int_sequence_list [list ]
    for {set i 0} { $i < $table_cols_count } { incr i } {
        lappend int_sequence_list $i
    }

    # To remove a column from display and processing:
    # Use: columns_hide_index_list
    # 1. Blank the column reference from:
    #    int_sequence_list 
    #    where  int_sequence_list is a sequential list: 0 1 2 3..
    #    So, removal of '1' becomes 0 "" 2 3..
    #    Don't remove the reference position, 
    #    or later column tracking for unsorted removals will break.
    # 2. Reduce table_cols_count by number of columns removed

    foreach col_idx $columns_hide_index_list {
        # Checked for collision with sort_order_list indexes in ns_log 631
        set int_sequence_list [lreplace $int_sequence_list $col_idx $col_idx "" ]
        incr table_cols_count -1
    }

    set sort_order_list [list ]
    set table_sorted_lists $table_lists
    # Sort table?
    if { $s ne "" } {
        # Sort table
        # A sort order has been requested
        # $s is in the form of a string of integers delimited by the letter a. 
        # Each integer is a column number ie list index, 
        # where 0 is first column.
        # A positive integer sorts column increasing.
        # A negative integer sorts column decreasing.
        # Primary sort column is listed first, followed by secondary sort etc.

        # Validate sort order, because it is user input via web
        # $s' first check and change to sort_order_scalar
        regsub -all -- {[^\-0-9a ]} $s {} sort_order_scalar

        # Converting sort_order_scalar to a list
        set sort_order_list [split $sort_order_scalar $a_h ]
        set sort_order_list [lrange $sort_order_list 0 $col_idx_max ]
    }

    # Has a sort order change been requested?
    if { $p ne "" } {
        # A new primary sort requested
        # This is a similar reference to s, but only one integer.
        # Since this is the first time used as a primary, 
        # additional validation and processing is required.
        # Validate user input, fail silently

        regsub -all -- {[^\-0-9 ]+} $p {} primary_sort_col_new
        # primary_sort_col_pos = primary sort column's position
        # primary_sort_col_new = a negative or positive column position. 
        set primary_sort_col_pos [expr { abs( $primary_sort_col_new ) } ]
        if { $primary_sort_col_new ne "" && $primary_sort_col_pos < $table_cols_count } {
            # modify sort_order_list
            set sort_order_new_list [list $primary_sort_col_new ]
            foreach ii $sort_order_list {
                set ii_num [expr { abs( ${ii} ) } ]
                if { $ii_num ne $primary_sort_col_pos } {
                    lappend sort_order_new_list $ii
                }
            }
            set sort_order_list $sort_order_new_list
        }
    }

    if { ( $s ne "" ) || ( $p ne "" ) } {
        # Screen out columns in columns_hide_index_list
        set sort_order_new_list [list ]
        foreach ii $sort_order_list {
            if { [string match {-*} $ii ] } {
                set ii_positive [string range $ii 1 end ]
            } else {
                set ii_positive $ii
            }
            if { [lsearch -exact -integer $columns_hide_index_list $ii_positive ] < 0 } {
                lappend sort_order_new_list $ii
            } else {
                ns_log Warning "qfo_sp_table_g2.343: column ii '${ii}'\
 not sorted. Found in columns_hide_index_list '${columns_hide_index_list}'"
            }
        }
        set sort_order_list $sort_order_new_list
        # Number of sorted columns:
        set sort_cols_count [llength $sort_order_list ]


        # Create a reverse index list for index countdown, 
        # because primary sort is last, secondary sort is second to last..
        # int_sequence_list 0 1 2 3..
        set sort_seq_reverse_list [lsort -integer -decreasing [lrange $int_sequence_list 0 [expr { $sort_cols_count - 1 } ] ] ]
        # sort_seq_reverse_list ..3 2 1 0
        # if sort_order_list is 9 -2 5 -4 for example, then 3 2 1 0.
        # Note: sort_order_list is primary_sort_col_idx, secondary_sort_col_idx
        # whereas sort_seq_reverse_list 
        #    is a sequence of counting numbers in reverse order.

        # The following loop has a secondary purpose to populate
        # array sort_type_arr(column_index) for later use.
        for {set i 0} { $i < $table_cols_count } {incr i} {
            set sort_order_arr(${i}) ""
        }

        set sort_reverse_order_list [list ]
        set da_decreasing_c "-decreasing"
        set da_increasing_c "-increasing"
        foreach ii $sort_seq_reverse_list {
            set col2sort [lindex $sort_order_list $ii ]
            lappend sort_reverse_order_list $col2sort
            if { [string match {-*} $col2sort ] } {
                set col2sort_wo_sign [string range $col2sort 1 end ]
                set sort_order $da_decreasing_c
            } else { 
                set col2sort_wo_sign $col2sort
                set sort_order $da_increasing_c
            }
            set sort_order_arr(${col2sort_wo_sign}) $sort_order
            # Map the negative and positive number cases, to positive numbers to speed later loops.
            set sort_col_pos_map_arr(${col2sort}) $col2sort_wo_sign
            set sort_type [lindex $sort_type_list $col2sort_wo_sign ]
            
            if {[catch { set table_sorted_lists [lsort $sort_type $sort_order -index $col2sort_wo_sign $table_sorted_lists ] } result ] } {
                # lsort errored, probably due to bad sort_type. 
                # Fall back to -ascii sort_type, or fail..
                set table_sorted_lists [lsort -ascii $sort_order -index $col2sort_wo_sign $table_sorted_lists ]
                ns_log Notice "qfo_table_g2.377: lsort resorted to sort_type \
 -ascii for index '${col2sort_wo_sign}' due to error: '${result}'"
            }
        }
    }

    # ================================================
    # 3. Pagination_bar -- 
    #    calcs including list_limit and build UI
    # ================================================
    # if $s exists, add it to to pagination urls.

    # constants
    set a_end_h "</a>"
    set a_href_h "<a href=\""
    set amp_h "&amp;"
    set amp_p_h "&amp;p="
    set amp_s_h "&amp;s="
    set class_att_h "\" class=\""
    set colon ":"
    set da_h "-"
    set div_end_h "</div>"
    set dquote_end_h "\">"
    set eq_h "="
    set gt_h ">"
    set page_num_prefix "#acs-templating.Page# "
    set q_s_h "?s="
    set qm_h "?"
    set quote_h "\""
    set sortedfirst "sortedfirst"
    set sortedlast "sortedlast"
    set sp " "
    set span_end_h "</span>"
    set span_h "<span"
    set this_start_row_h "this_start_row="
    set title_att_h "\" title=\""
    set unsorted "unsorted"

    # Add the sort links to the titles.
    # urlcode sort_order_list
    set s_urlcoded [join $sort_order_list $a_h]
    set s_url_add $amp_s_h
    append s_url_add ${s_urlcoded}

    # Sanity check 
    if { $this_start_row > $item_count } {
        set this_start_row $item_count
    }
    if { $this_start_row < 1 } {
        set this_start_row 1
    }
    set bar_list_set [hf_pagination_by_items $item_count $items_per_page $this_start_row ]

    # Previous nav links
    set prev_bar_list [lindex $bar_list_set 0 ]
    set nav_bar_prev_list [list ]
    foreach {page_num start_row} $prev_bar_list {
        if { $page_num_p } {
            set page_ref $page_num
        } else {
            set item_index [expr { ( $start_row - 1 ) } ]
            set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index ] $col2sort_wo_sign ]
            set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val ] 10 ]
            if { $page_ref eq "" } {
                set page_ref $page_num_prefix
                append page_ref ${page_num}
            }
        }
        set this_start_row_link ${a_href_h}
        append this_start_row_link ${base_url} $qm_h $this_start_row_h ${start_row}
        append this_start_row_link ${s_url_add} $dquote_end_h ${page_ref} $a_end_h
        lappend nav_bar_prev_list $this_start_row_link
    } 
    set nav_prev_links_html [join $nav_bar_prev_list $separator ]

    # Current nav 
    set current_bar_list [lindex $bar_list_set 1 ]
    set page_num [lindex $current_bar_list 0 ]
    set start_row [lindex $current_bar_list 1 ]
    if { $page_num_p } {
        set page_ref $page_num
    } else {
        set item_index [expr { ( $start_row - 1 ) } ]
        set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index ] $col2sort_wo_sign ]
        set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val ] 10 ]
        if { $page_ref eq "" } {
            set page_ref $page_num_prefix
            append page_ref ${page_num}
        }
    }
    set nav_current_pos_html $page_ref

    # Next nav links
    set next_bar_list [lindex $bar_list_set 2 ]
    set nav_bar_next_list [list ]
    foreach {page_num start_row} $next_bar_list {
        if { $page_num_p } {
            set page_ref $page_num
        } else {
            set item_index [expr { ( $page_num - 1 ) * $items_per_page  } ]
            set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index ] $col2sort_wo_sign ]
            set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val ] 10 ]
            if { $page_ref eq "" } {
                set page_ref $page_num_prefix
                append page_ref ${page_num}
            }
        }
        set next_bar_link ${sp}
        append next_bar_link ${a_href_h}
        append next_bar_link ${base_url} ${qm_h} ${this_start_row_h} ${start_row}
        append next_bar_link ${s_url_add} ${dquote_end_h} ${page_ref} ${a_end_h} ${sp}
        lappend nav_bar_next_list $next_bar_link
    }
    set nav_next_links_html [join $nav_bar_next_list $separator ]


    # add start_row to sort_urls.
    if { $this_start_row ne "1" } {
        set page_url_add ${amp_h}
        append page_url ${this_start_row_h}
        append page_url_add ${this_start_row}
    } else {
        set page_url_add ""
    }


    # ================================================
    # 4. Sort UI -- build
    # ================================================
    # Sort's abbreviated title should be context sensitive, 
    # changing depending on sort type.
    # sort_type_list is indexed by sort_column nbr (0...)
    # for UX, chagnged "ascending order" to "A first" or "1 First", 
    # and "Descending order" to "Z first" or "9 first".
    # And, so it's coded: A:Z, Z:A, 1:9, 9:1, but customizable:
    set titles_html_list [list ]
    set text_asc "A"
    set text_desc "Z"
    set nbr_asc "1"
    set nbr_desc "9"
    # increasing
    set title_asc "#acs-templating.ascending_order#"
    set title_asc_by_nbr "'${nbr_asc}' #acs-kernel.common_first#"
    set title_asc_by_text "'${text_asc}' #acs-kernel.common_first#"
    # decreasing
    set title_desc "#acs-templating.descending_order#"
    set title_desc_by_nbr "'${nbr_desc}' #acs-kernel.common_first#"
    set title_desc_by_text "'${text_desc}' #acs-kernel.common_first#"

    if { [string match { *} $sorted_first_attributes ] } {
        set sp_sorted_first_attributes $sorted_first_attributes
    } else {
        set sp_sorted_first_attributes ${sp}
        append sp_sorted_first_attributes ${sorted_first_attributes}
    }
    if { [string match { *} $sorted_last_attributes ] } {
        set sp_sorted_last_attributes $sorted_last_attributes
    } else {
        set sp_sorted_last_attributes ${sp}
        append sp_sorted_last_attributes ${sorted_last_attributes}
    }
    if { [string match { *} $unsorted_attributes ] } {
        set sp_unsorted_attributes $unsorted_attributes
    } else {
        set sp_unsorted_attributes ${sp}
        append sp_unsorted_attributes ${unsorted_attributes}
    }

    set column_idx 0
    set primary_sort_col [lindex $sort_order_list $column_idx ]
    foreach title $titles_list {
        # Identify column data type for sort button (text or nbr).
        # The column order is not changed yet.
        set column_type [string range [lindex $sort_type_list $column_idx ] 1 end ]

        switch -exact -- $column_type {
            integer -
            real {
                set abbrev_asc $nbr_asc
                set abbrev_desc $nbr_desc
                set title_asc $title_asc_by_nbr
                set title_desc $title_desc_by_nbr
                set ignore_p 0
            }
            ascii -
            dictionary {
                set abbrev_asc $text_asc
                set abbrev_desc $text_desc
                set title_asc $title_asc_by_text
                set title_desc $title_desc_by_text
                set ignore_p 0
            }
            ignore {
                set abbrev_asc ""
                set abbrev_desc ""
                set title_asc ""
                set title_desc ""
                set ignore_p 1
            }
            default {
                set abbrev_asc ""
                set abbrev_desc ""
                set title_asc ""
                set title_desc ""
                set ignore_p 1
                ns_log Warning "qfo_sp_table_g2.441 column_type '${column_type}' unrecognized."
            }
        }

        # Is column sort decreasing?
        # If so, let's reverse the order of column's sort links.

        switch -exact -- $sort_order_arr(${column_idx}) {
            -increasing {
                set decreasing_p 0
                set column_sorted_p 1
            }
            -decreasing {
                set decreasing_p 1
                set column_sorted_p 1
            }
            default {
                set decreasing_p 0
                set column_sorted_p 0
            }
        }

        set sort_link_delim ""
        # Sort button should be active if an available choice, 
        # and inactive if already chosen (primary sort case).
        # Sorted columns should reflect existing sort case, 
        # so if column is sorted descending integer, then '9:1' not '1:9'.
        # Sorted columnns should be aligned vertically,
        # to reflect column value orientation.

        # To indicate inactive choice, inactivate the left most sort link 
        # that was most recently pressed (if it has been).
        set title_new ""

        if { $primary_sort_col eq "" \
                 || $ignore_p \
                 || ( $primary_sort_col ne "" \
                          && $column_idx ne [expr { abs( $primary_sort_col ) } ] ) } {
            if { $column_sorted_p } {
                if { $decreasing_p } {

                    # reverse class styles
                    set sort_top ${a_href_h}
                    append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                    append sort_top ${title_att_h} ${title_asc} ${quote_h}
                    append sort_top ${sp_sorted_last_attributes} ${gt_h}
                    append sort_top ${abbrev_asc} ${a_end_h}
                    set sort_bottom ${a_href_h}
                    append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                    append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                    append sort_bottom ${sp_sorted_first_attributes} ${gt_h}
                    append sort_bottom ${abbrev_desc} ${a_end_h}
                } else {

                    set sort_top ${a_href_h} 
                    append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                    append sort_top ${title_att_h} ${title_asc} ${quote_h}
                    append sort_top ${sp_sorted_first_attributes} ${gt_h}
                    append sort_top ${abbrev_asc} ${a_end_h}
                    set sort_bottom ${a_href_h} 
                    append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                    append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                    append sort_bottom ${sp_sorted_last_attributes} ${gt_h}
                    append sort_bottom ${abbrev_desc} ${a_end_h}
                }
            } else {
                # Not sorted, so don't align sort order vertically.. 
                # Just use normal horizontal alignment.

                set sort_top ${span_h}
                append sort_top ${sp_unsorted_attributes} ${gt_h}
                append sort_top ${a_href_h}
                append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                append sort_top ${title_att_h} ${title_asc} ${quote_h}
                append sort_top ${gt_h}
                append sort_top ${abbrev_asc} ${a_end_h}
                set sort_bottom ${a_href_h} 
                append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                append sort_bottom ${sp_unsorted_attributes} ${gt_h}
                append sort_bottom ${abbrev_desc} ${a_end_h}
                append sort_bottom ${span_end_h}
                set sort_link_delim ${colon}
            }
        } elseif { !$ignore_p } {
            # Must be primary sort column
            if { $decreasing_p } {

                # Decreasing primary sort is chosen last, 
                # no need to make the link active
                set sort_top ${a_href_h}
                append sort_top ${base_url} ${q_s_h} ${s_urlcoded} 
                append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                append sort_top ${title_att_h} ${title_asc} ${quote_h}
                append sort_top ${sp_sorted_last_attributes} ${gt_h}
                append sort_top ${abbrev_asc} ${a_end_h}
                set sort_bottom ${span_h} 
                append sort_bottom ${sp_sorted_first_attributes} ${gt_h}
                append sort_bottom ${abbrev_desc} ${span_end_h}


            } else {
                # Increasing primary sort is chosen last, 
                # no need to make the link active

                set sort_top ${span_h} 
                append sort_top ${sp_sorted_first_attributes} ${gt_h}
                append sort_top ${abbrev_asc}
                append sort_top ${span_end_h}
                set sort_bottom ${a_href_h}
                append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                append sort_bottom ${sp_sorted_last_attributes} ${gt_h}
                append sort_bottom ${abbrev_desc} ${a_end_h}
            }
        }
        append title_new $title
        if { !$ignore_p } {
            if { $decreasing_p } {
                append title_new ${sort_bottom} ${sort_link_delim} ${sort_top}
            } else {
                append title_new ${sort_top} ${sort_link_delim} ${sort_bottom}
            }
        }
        lappend titles_html_list $title_new
        incr column_idx
    }


    # ==================================================
    # 5. Reduce table to page from paginated parameters
    # ==================================================
    # Begin building the paginated table here. 
    # Table rows have to have been sorted previously.

    # Input:

    # Output:
    # table_sorted_paginated_lists

    #set table_sorted_paginated_lists [list ]
    set lindex_start [expr { $this_start_row - 1 } ]
    set lindex_last [expr { $item_count - 1 } ]
    set last_row [expr { $lindex_start + $items_per_page - 1 } ]
    if { $lindex_last < $last_row } {
        set last_row $lindex_last
    }
    set table_sorted_paginated_lists [lrange $table_sorted_lists $lindex_start $last_row]


    # ================================================
    # 6.  Re-order columns, primary sorted first, secondary second..
    # ================================================
    # Primary sort col is leftmost, secondary is 2nd from left etc.

    # Input: 
    #  table_sorted_paginated_lists
    #  sort_order_lists
    #  sort_seq_reverse_list

    # Output:
    #  table_sorted_reordered_lists
    #  titles_reordered_list
    #  titles_reordered_html_list


    # Track the columns that aren't sorted
    # int_sequence_list may have empty strings indicating hidden col reference
    set unsorted_list $int_sequence_list
    foreach ii $sort_order_list {
        set ii_pos $sort_col_pos_map_arr(${ii})

        # Blank the reference instead of removing it, 
        # or the $ii_pos reference won't work later on..
        if { [lindex $ii_pos ] ne "" } {
            set unsorted_list [lreplace $unsorted_list $ii_pos $ii_pos "" ]
        }
    }
    set unsorted_compressed_list [list ]
    foreach ii $unsorted_list {
        if { $ii ne "" } {
            lappend unsorted_compressed_list $ii
        }
    }

    #  titles_list
    set titles_reordered_list [list ]
    #  titles_html_list
    set titles_reordered_html_list [list ]    
    set reordered_idx_list [list ]
    foreach ii $sort_order_list {
        set ii_pos $sort_col_pos_map_arr(${ii})
        lappend col_idx_reordered_list $ii_pos
        lappend titles_reordered_list [lindex $titles_list $ii_pos ]
        lappend titles_reordered_html_list [lindex $titles_html_list $ii_pos ]
    }

    # Now that the sorted columns are added to the rows, 
    # add the remaining columns
    foreach ui $unsorted_compressed_list {
        # Add unsorted column to row
        lappend titles_reordered_list [lindex $titles_list $ui ]
        lappend titles_reordered_html_list [lindex $titles_html_list $ui ]
        lappend col_idx_reordered_list $ui
    }

    # Repeat for the table rows: 

    set table_sorted_reordered_lists [list ]

    # Rebuild the table, one row at a time, 
    # Add the primary sorted column, then secondary sorted columns in order


    foreach table_row_list $table_sorted_paginated_lists {

        set table_row_new_list [list ]

        # Add the sorted columns
        foreach ii_pos $col_idx_reordered_list {
            lappend table_row_new_list [lindex $table_row_list $ii_pos ]
        }
        # Append new row to new table
        lappend table_sorted_reordered_lists $table_row_new_list
    }

    # ================================================
    # Display customizations
    # ================================================

    # Add UI Options column to table?
    # Not at this time. 
    # Must be added in advance, or added via exposed interim process variables.

    # ================================================
    # 7. Format output 
    # ================================================
    # Add attributes to the TABLE tag
    set table_tag_attribute_list 

    # Add cell formatting to TD tags
    set cell_formating_list [list ]

    set integer_c "integer"
    set real_c "real"
    set title_td_attrs_list [list ]
    set row_td_attrs_list [list ]

    # Don't use col_idx_reordered_list here, because
    # sort_order_list and unsorted_compressed_list elements
    # have different attribute sets
    foreach ii $sort_order_list {
        set ii_pos $sort_col_pos_map_arr(${ii})
        set column_type [string range [lindex $sort_type_list $ii_pos ] 1 end ]

        if { $column_type eq $integer_c || $column_type eq $real_c } {
            lappend title_td_attrs_list ${th_sorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_number_attribute_list} \
                                           ${td_sorted_attribute_list} ]
        } else {
            lappend title_td_attrs_list ${th_sorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_nonnumber_attribute_list} \
                                           ${td_sorted_attribute_list} ]
        }
    }
    foreach ii_pos $unsorted_compressed_list {
        set column_type [string range [lindex $sort_type_list $ii_pos ] 1 end ]

        if { $column_type eq $integer_c || $column_type eq $real_c } {
            lappend title_td_attrs_list ${th_unsorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_number_attribute_list} \
                                           ${td_unsorted_attribute_list} ]
        } else {
            lappend title_td_attrs_list ${th_unsorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_nonnumber_attribute_list} \
                                           ${td_unsorted_attribute_list} ]
        }
    }


    set cell_format_reordered_lists [list $title_td_attrs_list \
                                         $row_td_attrs_list \
                                         $row_td_attrs_list ]

    # Rebuild the even/odd rows, add column based variances
    # When column order changes, 
    # then formatting of the TD tags may change, too.
    # So, re-order the formatting columns, 
    # Use the same looping logic from when the table columns changed order
    # to avoid inconsistencies

    set table_row_count [llength $table_sorted_reordered_lists ]

    # Build html table
    set table_sorted_reordered_w_titles_lists [linsert $table_sorted_reordered_lists 0 $titles_reordered_html_list ]
    set table_html [qss_list_of_lists_to_html_table $table_sorted_reordered_w_titles_lists $table_tag_attribute_list $cell_format_reordered_lists "1" $tr_even_attribute_list $tr_odd_attribute_list $tr_header_attribute_list ]

    return 1
}

ad_proc -public hf_pagination_by_items {
    item_count
    items_per_page
    first_item_displayed
} {
    Returns a list of 3 pagination components.
    The first is a list of page_number and start_row pairs for pages before the current page.
    The second contains page_number and start_row for the current page.
    Third is the same value pair for pages after the current page.  
    See hosting-farm/lib/paginiation-bar for an implementation example. 
    Returns 0 for each of the three, if there are no items.
} {
    # based on ecds_pagination_by_items
    set bar_list_set [list 0 0 0]
    if { $items_per_page > 0 \
             && $item_count > 0 \
             && $first_item_displayed > 0 \
             && $first_item_displayed <= $item_count } {
        set bar_list [list ]
        set end_page [expr { ( $item_count + $items_per_page - 1 ) / $items_per_page } ]

        set current_page [expr { ( $first_item_displayed + $items_per_page - 1 ) / $items_per_page } ]

        # first row of current page: {(( $current_page-1)*$items_per_page)+1}

        # create bar_list with no pages beyond end_page

        if { $item_count > [expr { $items_per_page * 81 } ] } {
            # use exponential page referencing
            set relative_step 0
            set next_bar_list [list ]
            set prev_bar_list [list ]
            # 0.69314718056 = log(2)  
            set max_search_points [expr { int( ( log( $end_page ) / 0.69314718056 ) + 1 ) } ]
            for {set exponent 0} { $exponent <= $max_search_points } { incr exponent 1 } {
                # exponent refers to a page, relative_step refers to a relative row
                set relative_step_row [expr { int( pow( 2, $exponent ) ) } ]
                set relative_step_page $relative_step_row
                lappend next_bar_list $relative_step_page
                set prev_bar_list [linsert $prev_bar_list 0 [expr { -1 * $relative_step_page } ] ]
            }

            # template_bar_list and relative_bar_list contain page numbers
            set template_bar_list [concat $prev_bar_list 0 $next_bar_list ]
            set relative_bar_list [lsort -unique -increasing -integer $template_bar_list ]
            
            # translalte bar_list relative values to absolute rows
            foreach {relative_page} $relative_bar_list {
                set new_page [expr { int ( $relative_page + $current_page ) } ]
                if { $new_page < $end_page } {
                    lappend bar_list $new_page 
                }
            }

        } elseif {  $item_count > [expr { $items_per_page * 10 } ] } {
            # use linear, stepped page referencing

            set next_bar_list [list 1 2 3 4 5 ]
            set prev_bar_list [list -5 -4 -3 -2 -1 ]
            set template_bar_list [concat $prev_bar_list 0 $next_bar_list ]
            set relative_bar_list [lsort -unique -increasing -integer $template_bar_list ]
            # translalte bar_list relative values to absolute rows
            foreach {relative_page} $relative_bar_list {
                set new_page [expr { int ( $relative_page + $current_page ) } ]
                if { $new_page < $end_page } {
                    lappend bar_list $new_page 
                }
            }
            # add absolute page references
            for {set page_number 10} { $page_number <= $end_page } { incr page_number 10 } {
                lappend bar_list $page_number
                set bar_list [linsert $bar_list 0 [expr { -1 * $page_number } ] ]
            }

        } else {
            # use complete page reference list
            for {set page_number 1} { $page_number <= $end_page } { incr page_number 1 } {
                lappend bar_list $page_number
            }
        }

        # add absolute reference for first page, last page
        lappend bar_list $end_page
        set bar_list [linsert $bar_list 0 1 ]

        # Clean up list.
        # Sort and remove any remaining nonpositive integers and duplicates.
        set filtered_bar_list [lsort -unique -increasing -integer [lsearch -all -glob -inline $bar_list {[0-9 ]*} ] ]
        # Delete any cases of page zero
        set zero_index [lsearch $filtered_bar_list 0 ]
        set bar_list [lreplace $filtered_bar_list $zero_index $zero_index ]

        # Generate list of lists 
        set prev_bar_list_pair [list ]
        set current_bar_list_pair [list ]
        set next_bar_list_pair [list ]
        foreach page $bar_list {
            set start_item [expr { ( ( $page - 1 ) * $items_per_page ) + 1 } ]
            if { $page < $current_page } {
                lappend prev_bar_list_pair $page $start_item
            } elseif { $page eq $current_page } {
                lappend current_bar_list_pair $page $start_item
            } elseif { $page > $current_page } {
                lappend next_bar_list_pair $page $start_item
            }
        }
        set bar_list_set [list $prev_bar_list_pair $current_bar_list_pair $next_bar_list_pair ]
    } else {
        ns_log Warning "hf_pagination_by_items: value(s) out of bounds  \
 item_count '${item_count}' items_per_page '${items_per_page}' \
 first_item_displayed '${first_item_displayed}'"
    }

    return $bar_list_set
}

ad_proc -public ::qfo::css_blend {
    css_properties
} {
    Blends css styles. For example "background: #f00; background: #00f; align: right;" becomes "background: #00f; align: right;"
    <br><br>
    This is useful when sets of css are used for multiple parameters,
    and there may be some overlap of properties.
} {
    set colon_c ":"
    set semicolon_c ";"
    set css_properties_list [split $css_properties $semicolon_c]
    foreach property $css_properties_list {
        set colon_first_idx [string first $colon_c $property]
        if { $colon_first_idx > -1 } {
            set pname [string range $property 0 ${colon_first_idx}-1 ]
            set pvalue [string range $property ${colon_first_idx}+1 end ]
            set property_arr(${pname}) $pvalue
        }
    }
    set css_properties_new ""
    foreach {n v} [array get property_arr] {
        append css_properties_new ${n} ${colon_c} ${v} ${semicolon_c}
    }
    return $css_properties_new
}

ad_proc -public ::qfo::names_blend {
    name_value_list
    {delimiter " "}
} {
    Blends names, so that for example, if there are two
    names 'class', their values are combined.
    No precedence is given to order of attributes.
    A space is the default delimiter for combined values.
    @return name_value_list
} {
    foreach {n v} $name_value_list {
        lappend attributes_arr(${n}) ${v}
    }
    set attributes_list [list ]
    foreach {n v} [array get attributes_arr] {
        lappend attributes_list ${n} [join ${v} ${delimiter}]
    }
    return $attributes_list
}


ad_proc -public qfo_sp_table_g3 {
    {-base_url ""}
    {-columns_hide_index_list ""}
    {-columns_justify_list ""}
    {-item_count ""}
    {-items_per_page "12" }
    {-list_length_limit ""}
    {-nav_buttons_html_varname "__qfsp_nav_buttons_html"}
    {-nav_button_div_attributes_list_varname "__qfsp_nav_div_atts_list"}
    {-nav_button_attributes_list_varname "__qfsp_nav_button_atts_list"}
    {-p_varname "__qfsp_p"}
    {-page_num_p "0"}
    {-s_varname "__qfsp_s"}
    {-sort_type_list ""}
    {-sorted_first_attributes {style="font-family: monospace; font-size: 60%; font-style: normal; vertical-align: super;"}}
    {-sorted_last_attributes {style="font-family: monospace; font-size: 46%; font-style: normal; vertical-align: sub; margin-left: -0.63em;"}}
    {-table_html_varname "__qfsp_table_html"}
    {-table_lists_varname "__qfsp_table_lists"}
    {-table_sorted_lists_varname "__qfsp_table_sorted_lists"}
    {-table_sorted_paginated_lists_varname "__qfsp_table_sorted_paginated_lists"}
    {-table_sorted_reordered_lists_varname "__qfsp_table_sorted_reordered_lists"}
    {-table_tag_attribute_list {{class} {grid-whole} }}
    {-td_number_attribute_list {{style} {text-align: left;}}}
    {-td_nonnumber_attribute_list {{style} {text-align: right;}}}
    {-td_attribute_list {{class} {content-box}}}
    {-td_sorted_attribute_list {}}
    {-td_unsorted_attribute_list {{style} {opacity:0.9;}}}
    {-th_sorted_attribute_list {{style} {text-align: center; border: 1px solid #999; background-color: #eef;}}}
    {-th_unsorted_attribute_list {{style} {text-align: center; border: 1px solid #999; line-height: 90%;}}}
    {-this_start_row "1"}
    {-titles_html_list_varname "__qfsp_titles_html_list"}
    {-titles_list_varname "__qfsp_titles_list"}
    {-titles_reordered_html_list_varname "__qfsp_titles_reordered_html"}
    {-titles_reordered_list_varname "__qfsp_reordered_list"}
    {-tr_even_attribute_list {{class} {even grid-whole}}}
    {-tr_header_attribute_list {{class} {grid-whole} {style} {display: flex;}}}
    {-tr_odd_attribute_list {{class} {odd grid-whole}}}
    {-unsorted_attributes {{style} {font-family: monospace; font-size: 70%; font-style: normal; vertical-align: baseline; line-height: 1em; padding: 0; margin: 0;}}}
} {
    Creates a user customizable sorted table by
    creating a one row header into html and a table into html, 
    and complementary navigation links.
    <br><br>
    This version uses form buttons (instead of links) to discourage
    web spiders and read-ahead browsers from wasting resources by
    re-rendering the page innumerable times.
    <br><br>
    The table and titles are exposed at various steps in the process, 
    so that customizations may be made without having to
    re-work the core functionality. 
    (The api could include new proces of this one split into its stages 
     for optimization if customization proves to be a common, practical need.)
    <strong>Highlighted parameters</strong> indicate which parameters
    provide features this proc is specificially optimized for.
    <br><br>
    Outputs are:
    <br><br>
    <ul><li>
    <strong>nav_buttons_html_varname</strong>
    </li><li>
    <code>table_lists_varname</code> is unchanged. 
    It gets sorted into <code>table_sorted_lists_varname</code>.
    Then the columns are re-ordered based on sort significance,
    with the primary sort column first and set to
    <code>table_sorted_reordered_lists_varname</code>.
    For tables, the progression of processing is:
    <ol><li>
    <code>table_lists_varname</code> (input, unchanged)
    </li><li>
    <code>table_sorted_lists_varname</code>
    </li><li>
    <code>table_sorted_paginated_lists_varname</code>
    </li><li>
    <code>table_sorted_reordered_lists_varname</code>
    </li><li>
    <strong><code>table_html_varname</code></strong>
    </li></ol>
    <br>
    For titles, the progression is:
    <ol><li>
    <code>titles_list_varname</code> (input, unchanged)
    </li><li>
    <code>titles_html_list_varname</code>  
    This heading row includes html for form-based UI for p and s parameters
    </li><li>
    <code>titles_reordered_list_varname</code> 
    This is the titles list re-ordered according to sort order significance, 
    with primary sort order in first column. 
    Columns are re-organized same as <code>table_sorted_reordered_lists_varname</code>.
    </li><li>
    <code>titles_reordered_html_list_varname</code>
    This is <code>titles_html_list_varname</code> with columns re-ordered 
    according to sort order significance.
    This is added to <code>table_html_varname</code>, so that
    no title-based output is specifically an optimized feature, and therefore 
    highlighted. However, this would be the closest result.
    </li></ul>

   
    Required parameters:
    <br><br>
    <code>table_lists_varname</code> 
    - Variable holding a table defined as a list of lists, 
    where each list is a row containing values of columns from first to last.
    <br><br>
    <code>titles_list_varname</code> 
    - Variable name containing a list of titles of the columns in 
    <code>table_lists</code>, in cooresponding order. 
    That is first in list is title of first column in table.
    <br><br>
    An <code>s_varname</code> or <code>p_varname</code> that identifies
    at least one sorted column.
    This is not a proc based requirement, but the proc's pagination navigation
    is fairly useless unless there is some default order provided
    usually via a one column sort supplied by <code>s_varname</code>.
    See optional parameters section for details on using <code>s_varname</code>.
    <br><br>
    Optional parameters:<br>
    <br><br>
    <code>columns_justify_list</code> To force a column's data to justify
    to the left, right, center, or (fill) justify,
    create a list with lowercase elements beginning with l,r,c, f or j.
    The first index in a tcl list is '0' for column 0, second index is '1'..
    <br><br>
    <code>items_per_page</code> - number of rows (items) per page
    <br><br>
    <code>item_count</code> - number of rows (items) in the table.
    <br><br>
    <code>this_start_row</code> 
    - start row (item sequence number) for this page. First row is 1 even though tcl usually uses 0.
    <br><br>
    <code>base_url</code> - url for building page links
    <br><br>
    <code>list_limit</code> - limits the list to this many items.
    <br><br>
    <code>page_num_p</code> 
    - Answers question: Use the page number in pagniation bar's display? 
    If not, the first value of the left-most (primary sort) column is used.
    <br><br>
    <code>s_varname</code> 
    - 's' is a sort_order_list as defined by the code and passed via a form. 
    It's an 'a' delimited list of column indexes of table 
    to be sorted in reverse order, 
    so that primary sort is the first in the list. 
    Secondary sort is the second in the list and on.
    For example, to indicate that the second column should be sorted in
    decreasing order,  set the value to: "-1", 
    because the first column's index is the same as Tcl's list indexing of zero.
    <br><br>
    <code>p_varname</code>
    - 'p' is a change of the sort_order_list 
    to now make this index the primary sort index. See code for details.
    <br><br>
    <code>sort_type_list</code>
    - A list of types of sort to use for each column when using: <br>
    '<code>lsort -index &lt;column&gt; -ascii &lt;list_of_lists&gt;</code>' <br>
    to sort a table by a specific column. 
    The default value for each column is '<code>-ascii</code>', per tcl's default. 
    When specifying sort_type_list, define a type to use for each column. 
    For example:<br>
    <code>\[list "-ascii" "-dictionary" "-ascii" "-ascii" "-real" \]</code> <br>
    for a table with five columns.
    Note: <strong>To indicate that a column is unsortable</strong> use
    '<code>-ignore</code>'.
    <br><strong>To sort by timestamp,</strong> use '<code>-dictionary</code>' sort type,
    and a consistent length format for the column values, 
    such as ISO-8601 format: "YYYY-MM-DD HH:MM:SS". See: http://wiki.tcl.tk/1277
    <br><br>
    *_attributes attributes may be passed as a list or string. If a comma or tab character are detected, a string will be split by comma or tab delimiter. Specically, this feature is for the following parameters:<br>
    <ul><li>
    <code>tr_even_attributes</code> Applies to even numbered rows
    </li><li>
    <code>tr_odd_attributes</code> Applies to odd numbered rows
    </li><li>
    <code>td_left_attributes</code> To left justify text in TD tags
    </li><li>
    <code>td_right_attributes</code> To right justified text in TD tags
    </li><li>
    <code>td_center_attributes</code> To center justify text in TD tags
    </li><li>
    <code>td_fill_attributes</code> To fill justify text in TD tags
    </li><li>
    <code>td_sorted_attributes</code> Applies to sorted column TD tags
    </li><li>
    <code>td_unsorted_attributes</code> Applies to unsorted column TD tags
    </li></ul>
    <br><br>
    <code>columns_hide_index_list</code> - To hide a column from display,
    add its tcl index number to this list.
    The first index in a tcl list is '0', second index is '1'..
    <br><br>
    <code>columns_justify_list</code> If present, a list of letters where position in list cooresponds to table columns, and where each element indicates a left, center, right, or fill justify. Only the first letter of each element is examined. The default is to right justify numbers, and left justify everything else.
    <br><br>
    Passes html as a string wrapping the links in the title elements that change the sort pattern. The variations permit some indication of sort status for sorted columns separate from unsorted ones. Specifically, refers to the following parameters:<br>
    <ul><li>
    <code>sorted_first_attributes</code> Html preceding 'first sort' change link for a title that has been sorted.
    </li><li>
    <code>sorted_last_attributes</code> Html preceding 'last sort' change link for a title that has been sorted.
    </li><li>
    <code>unsorted_attributes</code> Html preceding 'first sort' change link for a title that has not been sorted.
    </li></ul>
    Note: Unsorted are wrapped by same html for first and last sort links.  Sorted links are wrapped individually.
} {
    upvar 1 $nav_buttons_html_varname nav_buttons_html
    upvar 1 $nav_button_div_attributes_list_varname nav_div_atts_list
    upvar 1 $nav_button_attributes_list_varname nav_button_atts_list
    upvar 1 $p_varname p
    upvar 1 $s_varname s
    upvar 1 $table_html_varname table_html
    upvar 1 $table_lists_varname table_lists
    upvar 1 $table_sorted_lists_varname table_sorted_lists
    upvar 1 $table_sorted_paginated_lists_varname table_sorted_paginated_lists
    upvar 1 $table_sorted_reordered_lists_varname table_sorted_reordered_lists
    upvar 1 $titles_html_list_varname titles_html_list
    upvar 1 $titles_list_varname titles_list
    upvar 1 $titles_reordered_html_list_varname titles_reordered_html_list
    upvar 1 $titles_reordered_list_varname titles_reordered_list

    if { ![info exists nav_div_atts_list ] } {
        set nav_div_atts_list [list class "grid-flex content-box"]
    }
    if { ![info exists nav_button_atts_list ] } {
        set nav_button_atts_list [list class "btn-big"]
    }
    
    # This version requires the entire table to be loaded for processing.
    # TODO: make another version that uses pg's select limit and offset.. 
    # to scale for larger datasets.

    # General process flow:
    # 1. Get table as table_lists
    # 2. Sort unformatted columns by row values
    # 3. Pagination_bar -- calcs including list_limit, build UI
    # 4. Sort UI -- build
    # 5. Reduce table to page from paginate parameters
    # 6. Re-order columns, primary sorted first, secondary second..
    # 7. Format output with CSS and html

    # ================================================
    # 1. Get table as list_of_lists
    # ================================================
    # Don't process list_limit here.
    
    # Set defaults and validation
    set a_h "a"

    # normalize page_num_p's value
    set page_num_p [qf_is_true $page_num_p ]
    
    if { $base_url eq "" } {
        set base_url [ad_conn url ]
    }    
    set page_html ""
    if { ![qf_is_natural_number $this_start_row ] } {
        set this_start_row 1
    }
    if  { $item_count eq "" } {
        set item_count [llength $table_lists ]
    }
    if { ![info exists s ] } {
        set s ""
    }
    if { ![info exists p ] } {
        set p ""
    }
    if { $item_count eq 0 } {
        set titles_html_list ""
        set table_html "#acs-subsite.none#"
        return 0
    }

    # ================================================
    # 2. Sort unformatted columns by row values
    # ================================================
    # Sort Table Columns
    # arguments
    #     s            a coded sort_order_list (via form post)
    #     p            primary_sort_col_new (via form post)
    #     table_lists  table represented as a list of lists
    # ================================================
    # Output:
    #   sort_order_list


    set table_cols_count [llength [lindex $table_lists 0 ] ]
    set col_idx_max [expr { $table_cols_count - 1 } ]
    # defaults and inputs
    if { $sort_type_list eq "" } {
        set sort_type_list [lrepeat $table_cols_count "-ascii" ]
    }


    # int_sequence_list is used as a column reference map.
    # That is, position N in list is column number in new/wip table, and
    # the value in position N points to a column in original tables_list.
    set int_sequence_list [list ]
    for {set i 0} { $i < $table_cols_count } { incr i } {
        lappend int_sequence_list $i
    }

    # To remove a column from display and processing:
    # Use: columns_hide_index_list
    # 1. Blank the column reference from:
    #    int_sequence_list 
    #    where  int_sequence_list is a sequential list: 0 1 2 3..
    #    So, removal of '1' becomes 0 "" 2 3..
    #    Don't remove the reference position, 
    #    or later column tracking for unsorted removals will break.
    # 2. Reduce table_cols_count by number of columns removed

    foreach col_idx $columns_hide_index_list {
        # Checked for collision with sort_order_list indexes in ns_log 631
        set int_sequence_list [lreplace $int_sequence_list $col_idx $col_idx "" ]
        incr table_cols_count -1
    }

    set sort_order_list [list ]
    set table_sorted_lists $table_lists
    # Sort table?
    if { $s ne "" } {
        # Sort table
        # A sort order has been requested
        # $s is in the form of a string of integers delimited by the letter a. 
        # Each integer is a column number ie list index, 
        # where 0 is first column.
        # A positive integer sorts column increasing.
        # A negative integer sorts column decreasing.
        # Primary sort column is listed first, followed by secondary sort etc.

        # Validate sort order, because it is user input via web
        # $s' first check and change to sort_order_scalar
        regsub -all -- {[^\-0-9a ]} $s {} sort_order_scalar

        # Converting sort_order_scalar to a list, a_h is delimiter
        set sort_order_list [split $sort_order_scalar $a_h ]
        set sort_order_list [lrange $sort_order_list 0 $col_idx_max ]
    }

    # Has a sort order change been requested?
    if { $p ne "" } {
        # A new primary sort requested
        # This is a similar reference to s, but only one integer.
        # Since this is the first time used as a primary, 
        # additional validation and processing is required.
        # Validate user input, fail silently

        regsub -all -- {[^\-0-9 ]+} $p {} primary_sort_col_new
        # primary_sort_col_pos = primary sort column's position
        # primary_sort_col_new = a negative or positive column position. 
        set primary_sort_col_pos [expr { abs( $primary_sort_col_new ) } ]
        if { $primary_sort_col_new ne "" && $primary_sort_col_pos < $table_cols_count } {
            # modify sort_order_list
            set sort_order_new_list [list $primary_sort_col_new ]
            foreach ii $sort_order_list {
                set ii_num [expr { abs( ${ii} ) } ]
                if { $ii_num ne $primary_sort_col_pos } {
                    lappend sort_order_new_list $ii
                }
            }
            set sort_order_list $sort_order_new_list
        }
    }

    if { ( $s ne "" ) || ( $p ne "" ) } {
        # Screen out columns in columns_hide_index_list
        set sort_order_new_list [list ]
        foreach ii $sort_order_list {
            if { [string match {-*} $ii ] } {
                set ii_positive [string range $ii 1 end ]
            } else {
                set ii_positive $ii
            }
            if { [lsearch -exact -integer $columns_hide_index_list $ii_positive ] < 0 } {
                lappend sort_order_new_list $ii
            } else {
                ns_log Warning "qfo_sp_table_g2.343: column ii '${ii}'\
 not sorted. Found in columns_hide_index_list '${columns_hide_index_list}'"
            }
        }
        set sort_order_list $sort_order_new_list
        # Number of sorted columns:
        set sort_cols_count [llength $sort_order_list ]


        # Create a reverse index list for index countdown, 
        # because primary sort is last, secondary sort is second to last..
        # int_sequence_list 0 1 2 3..
        set sort_seq_reverse_list [lsort -integer -decreasing [lrange $int_sequence_list 0 [expr { $sort_cols_count - 1 } ] ] ]
        # sort_seq_reverse_list ..3 2 1 0
        # if sort_order_list is 9 -2 5 -4 for example, then 3 2 1 0.
        # Note: sort_order_list is primary_sort_col_idx, secondary_sort_col_idx
        # whereas sort_seq_reverse_list 
        #    is a sequence of counting numbers in reverse order.

        # The following loop has a secondary purpose to populate
        # array sort_type_arr(column_index) for later use.
        for {set i 0} { $i < $table_cols_count } {incr i} {
            set sort_order_arr(${i}) ""
        }

        set sort_reverse_order_list [list ]
        set da_decreasing_c "-decreasing"
        set da_increasing_c "-increasing"
        foreach ii $sort_seq_reverse_list {
            set col2sort [lindex $sort_order_list $ii ]
            lappend sort_reverse_order_list $col2sort
            if { [string match {-*} $col2sort ] } {
                set col2sort_wo_sign [string range $col2sort 1 end ]
                set sort_order $da_decreasing_c
            } else { 
                set col2sort_wo_sign $col2sort
                set sort_order $da_increasing_c
            }
            set sort_order_arr(${col2sort_wo_sign}) $sort_order
            # Map the negative and positive number cases, to positive numbers to speed later loops.
            set sort_col_pos_map_arr(${col2sort}) $col2sort_wo_sign
            set sort_type [lindex $sort_type_list $col2sort_wo_sign ]
            
            if {[catch { set table_sorted_lists [lsort $sort_type $sort_order -index $col2sort_wo_sign $table_sorted_lists ] } result ] } {
                # lsort errored, probably due to bad sort_type. 
                # Fall back to -ascii sort_type, or fail..
                set table_sorted_lists [lsort -ascii $sort_order -index $col2sort_wo_sign $table_sorted_lists ]
                ns_log Notice "qfo_table_g2.377: lsort resorted to sort_type \
 -ascii for index '${col2sort_wo_sign}' due to error: '${result}'"
            }
        }
    }

    # ================================================
    # 3. Pagination_bar -- 
    #    calcs including list_limit and build UI
    # ================================================
    # if $s exists, add it to to pagination urls.

    # constants
    set a_end_h "</a>"
    set a_href_h "<a href=\""
    set amp_h "&amp;"
    set amp_p_h "&amp;p="
    set amp_s_h "&amp;s="
    set class_att_h "\" class=\""
    set colon ":"
    set da_h "-"
    set div_end_h "</div>"
    set dquote_end_h "\">"
    set eq_h "="
    set gt_h ">"
    set page_num_prefix "#acs-templating.Page# "
    set q_s_h "?s="
    set qm_h "?"
    set quote_h "\""
    set sortedfirst "sortedfirst"
    set sortedlast "sortedlast"
    set sp " "
    set span_end_h "</span>"
    set span_h "<span"
    set this_start_row_h "this_start_row="
    set title_att_h "\" title=\""
    set unsorted "unsorted"

    # Add the sort links to the titles.
    # urlcode sort_order_list
    set s_urlcoded [join $sort_order_list $a_h]
    set s_url_add $amp_s_h
    append s_url_add ${s_urlcoded}

    # Sanity check 
    if { $this_start_row > $item_count } {
        set this_start_row $item_count
    }
    if { $this_start_row < 1 } {
        set this_start_row 1
    }
    set bar_list_set [hf_pagination_by_items $item_count $items_per_page $this_start_row ]
    set bar_list_length [llength [lindex $bar_list_set 0]]
    incr bar_list_length [llength [lindex $bar_list_set 1]]
    incr bar_list_length [llength [lindex $bar_list_set 2]]
    ns_log Notice "qf_table_g3.1596 bar_list_length $bar_list_length bar_list_set '$bar_list_set'"
    set width_pct [expr { int( 20000. / ( $bar_list_length + 0.) ) / 100. } ]
    set style_css "margin:0;clear:none;float:left;width:${width_pct}%;"
    #### upvar'd variables:
    # nav_buttons_html
    # nav_div_atts_list
    # nav_button_atts_list
    
    #### Add form tag with base_url
    #### and hidden s var to start of nav_prev_links_html
    set f_id [qf_form action ${base_url} ]    
    qf_input form_id $f_id name s value ${s_urlcoded} type hidden

    set nav_buttons_html "<div class=\"grid-flex grid-whole\">"
    set button_div_html "<div"
    lappend nav_div_atts_list style ${style_css}
    append button_div_html [qf_insert_attributes $nav_div_atts_list]
    append button_div_html $gt_h

    # Previous nav links
    set prev_bar_list [lindex $bar_list_set 0 ]
    set nav_bar_prev_list [list ]
    foreach {page_num start_row} $prev_bar_list {
        if { $page_num_p } {
            set page_ref $page_num
        } else {
            set item_index [expr { ( $start_row - 1 ) } ]
            set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index ] $col2sort_wo_sign ]
            set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val ] 10 ]
            if { $page_ref eq "" } {
                set page_ref $page_num_prefix
                append page_ref ${page_num}
            }
        }
        #set this_start_row_link ${a_href_h}
        #append this_start_row_link ${base_url} $qm_h $this_start_row_h ${start_row}
        #append this_start_row_link ${s_url_add} $dquote_end_h ${page_ref} $a_end_h
        #### convert this_start_row_link to qf_button
        qf_append form_id $f_id html $button_div_html
        qf_button form_id $f_id name this_start_row value ${start_row} content ${page_ref}
        qf_append form_id $f_id html "</div>"
    }
    
    # Current nav 
    set current_bar_list [lindex $bar_list_set 1 ]

    set page_num [lindex $current_bar_list 0 ]
    set start_row [lindex $current_bar_list 1 ]
    if { $page_num_p } {
        set page_ref $page_num
    } else {
        set item_index [expr { ( $start_row - 1 ) } ]
        set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index ] $col2sort_wo_sign ]
        set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val ] 10 ]
        if { $page_ref eq "" } {
            set page_ref $page_num_prefix
            append page_ref ${page_num}
        }
    }
    #set nav_current_pos_html $page_ref
    qf_append form_id $f_id html $button_div_html
    qf_button form_id $f_id name this_start_row value $page_num content ${page_ref} disabled 1
    qf_append form_id $f_id html "</div>"
    # Next nav links
    set next_bar_list [lindex $bar_list_set 2 ]

    
    set nav_bar_next_list [list ]
    foreach {page_num start_row} $next_bar_list {
        if { $page_num_p } {
            set page_ref $page_num
        } else {
            set item_index [expr { ( $page_num - 1 ) * $items_per_page  } ]
            set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index ] $col2sort_wo_sign ]
            set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val ] 10 ]
            if { $page_ref eq "" } {
                set page_ref $page_num_prefix
                append page_ref ${page_num}
            }
        }
        qf_append form_id $f_id html $button_div_html
        qf_button form_id $f_id name this_start_row value ${start_row} content ${page_ref}
        qf_append form_id $f_id html "</div>"
        
    }

    qf_close form_id $f_id
    append nav_buttons_html [qf_read $f_id]
    append nav_buttons_html "</div>"
    
    ####  convert page_url_add to a form hidden input tag. (used later)
    # add start_row to sort_urls.
    if { $this_start_row ne "1" } {
        set page_url_add ${amp_h}
        append page_url ${this_start_row_h}
        append page_url_add ${this_start_row}
    } else {
        set page_url_add ""
    }


    # ================================================
    # 4. Sort UI -- build
    # ================================================
    # Sort's abbreviated title should be context sensitive, 
    # changing depending on sort type.
    # sort_type_list is indexed by sort_column nbr (0...)
    # for UX, chagnged "ascending order" to "A first" or "1 First", 
    # and "Descending order" to "Z first" or "9 first".
    # And, so it's coded: A:Z, Z:A, 1:9, 9:1, but customizable:
    set titles_html_list [list ]
    set text_asc "A"
    set text_desc "Z"
    set nbr_asc "1"
    set nbr_desc "9"
    # increasing
    set title_asc "#acs-templating.ascending_order#"
    set title_asc_by_nbr "'${nbr_asc}' #acs-kernel.common_first#"
    set title_asc_by_text "'${text_asc}' #acs-kernel.common_first#"
    # decreasing
    set title_desc "#acs-templating.descending_order#"
    set title_desc_by_nbr "'${nbr_desc}' #acs-kernel.common_first#"
    set title_desc_by_text "'${text_desc}' #acs-kernel.common_first#"

    if { [string match { *} $sorted_first_attributes ] } {
        set sp_sorted_first_attributes $sorted_first_attributes
    } else {
        set sp_sorted_first_attributes ${sp}
        append sp_sorted_first_attributes ${sorted_first_attributes}
    }
    if { [string match { *} $sorted_last_attributes ] } {
        set sp_sorted_last_attributes $sorted_last_attributes
    } else {
        set sp_sorted_last_attributes ${sp}
        append sp_sorted_last_attributes ${sorted_last_attributes}
    }
    if { [string match { *} $unsorted_attributes ] } {
        set sp_unsorted_attributes $unsorted_attributes
    } else {
        set sp_unsorted_attributes ${sp}
        append sp_unsorted_attributes ${unsorted_attributes}
    }

    set column_idx 0
    set primary_sort_col [lindex $sort_order_list $column_idx ]
    foreach title $titles_list {
        # Identify column data type for sort button (text or nbr).
        # The column order is not changed yet.
        set column_type [string range [lindex $sort_type_list $column_idx ] 1 end ]

        switch -exact -- $column_type {
            integer -
            real {
                set abbrev_asc $nbr_asc
                set abbrev_desc $nbr_desc
                set title_asc $title_asc_by_nbr
                set title_desc $title_desc_by_nbr
                set ignore_p 0
            }
            ascii -
            dictionary {
                set abbrev_asc $text_asc
                set abbrev_desc $text_desc
                set title_asc $title_asc_by_text
                set title_desc $title_desc_by_text
                set ignore_p 0
            }
            ignore {
                set abbrev_asc ""
                set abbrev_desc ""
                set title_asc ""
                set title_desc ""
                set ignore_p 1
            }
            default {
                set abbrev_asc ""
                set abbrev_desc ""
                set title_asc ""
                set title_desc ""
                set ignore_p 1
                ns_log Warning "qfo_sp_table_g2.441 column_type '${column_type}' unrecognized."
            }
        }

        # Is column sort decreasing?
        # If so, let's reverse the order of column's sort links.

        switch -exact -- $sort_order_arr(${column_idx}) {
            -increasing {
                set decreasing_p 0
                set column_sorted_p 1
            }
            -decreasing {
                set decreasing_p 1
                set column_sorted_p 1
            }
            default {
                set decreasing_p 0
                set column_sorted_p 0
            }
        }

        set sort_link_delim ""
        #### Sort button should be active if an available choice, 
        #### and inactive if already chosen (primary sort case).
        # Sorted columns should reflect existing sort case, 
        # so if column is sorted descending integer, then '9:1' not '1:9'.
        # Sorted columnns should be indicated somehow.
        # Make sorted columns show sort order left to right ie A:Z or Z:Z
        # with sorted option in uppercase
        # to reflect column value orientation.
        # Unsorted columns show less contrast (lighter foreground) for both choices.

        # To indicate inactive choice, inactivate the left most sort link 
        # that was most recently pressed (if it has been).

        #### Add form tag with hidden base_url and s_url_coded hidden inputs 's'
        #### Buttons indicate sort change only ie name=p value=..
        set title_new ""

        #### Make these buttons...
        if { $primary_sort_col eq "" \
                 || $ignore_p \
                 || ( $primary_sort_col ne "" \
                          && $column_idx ne [expr { abs( $primary_sort_col ) } ] ) } {
            if { $column_sorted_p } {
                if { $decreasing_p } {

                    # reverse class styles
                    set sort_top ${a_href_h}
                    append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                    append sort_top ${title_att_h} ${title_asc} ${quote_h}
                    append sort_top ${sp_sorted_last_attributes} ${gt_h}
                    append sort_top ${abbrev_asc} ${a_end_h}
                    set sort_bottom ${a_href_h}
                    append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                    append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                    append sort_bottom ${sp_sorted_first_attributes} ${gt_h}
                    append sort_bottom ${abbrev_desc} ${a_end_h}
                } else {

                    set sort_top ${a_href_h} 
                    append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                    append sort_top ${title_att_h} ${title_asc} ${quote_h}
                    append sort_top ${sp_sorted_first_attributes} ${gt_h}
                    append sort_top ${abbrev_asc} ${a_end_h}
                    set sort_bottom ${a_href_h} 
                    append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                    append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                    append sort_bottom ${sp_sorted_last_attributes} ${gt_h}
                    append sort_bottom ${abbrev_desc} ${a_end_h}
                }
            } else {
                # Not sorted, so don't align sort order vertically.. 
                # Just use normal horizontal alignment.

                set sort_top ${span_h}
                append sort_top ${sp_unsorted_attributes} ${gt_h}
                append sort_top ${a_href_h}
                append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                append sort_top ${title_att_h} ${title_asc} ${quote_h}
                append sort_top ${gt_h}
                append sort_top ${abbrev_asc} ${a_end_h}
                set sort_bottom ${a_href_h} 
                append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                append sort_bottom ${sp_unsorted_attributes} ${gt_h}
                append sort_bottom ${abbrev_desc} ${a_end_h}
                append sort_bottom ${span_end_h}
                set sort_link_delim ${colon}
            }
        } elseif { !$ignore_p } {
            # Must be primary sort column
            if { $decreasing_p } {

                # Decreasing primary sort is chosen last, 
                # no need to make the link active
                set sort_top ${a_href_h}
                append sort_top ${base_url} ${q_s_h} ${s_urlcoded} 
                append sort_top ${amp_p_h} ${column_idx} ${page_url_add}
                append sort_top ${title_att_h} ${title_asc} ${quote_h}
                append sort_top ${sp_sorted_last_attributes} ${gt_h}
                append sort_top ${abbrev_asc} ${a_end_h}
                set sort_bottom ${span_h} 
                append sort_bottom ${sp_sorted_first_attributes} ${gt_h}
                append sort_bottom ${abbrev_desc} ${span_end_h}


            } else {
                # Increasing primary sort is chosen last, 
                # no need to make the link active

                set sort_top ${span_h} 
                append sort_top ${sp_sorted_first_attributes} ${gt_h}
                append sort_top ${abbrev_asc}
                append sort_top ${span_end_h}
                set sort_bottom ${a_href_h}
                append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_bottom ${amp_p_h} ${da_h} ${column_idx} ${page_url_add}
                append sort_bottom ${title_att_h} ${title_desc} ${quote_h}
                append sort_bottom ${sp_sorted_last_attributes} ${gt_h}
                append sort_bottom ${abbrev_desc} ${a_end_h}
            }
        }
        append title_new $title
        if { !$ignore_p } {
            if { $decreasing_p } {
                append title_new ${sort_bottom} ${sort_link_delim} ${sort_top}
            } else {
                append title_new ${sort_top} ${sort_link_delim} ${sort_bottom}
            }
        }
        lappend titles_html_list $title_new
        incr column_idx
    }


    # ==================================================
    # 5. Reduce table to page from paginated parameters
    # ==================================================
    # Begin building the paginated table here. 
    # Table rows have to have been sorted previously.

    # Input:

    # Output:
    # table_sorted_paginated_lists

    #set table_sorted_paginated_lists [list ]
    set lindex_start [expr { $this_start_row - 1 } ]
    set lindex_last [expr { $item_count - 1 } ]
    set last_row [expr { $lindex_start + $items_per_page - 1 } ]
    if { $lindex_last < $last_row } {
        set last_row $lindex_last
    }
    set table_sorted_paginated_lists [lrange $table_sorted_lists $lindex_start $last_row]


    # ================================================
    # 6.  Re-order columns, primary sorted first, secondary second..
    # ================================================
    # Primary sort col is leftmost, secondary is 2nd from left etc.

    # Input: 
    #  table_sorted_paginated_lists
    #  sort_order_lists
    #  sort_seq_reverse_list

    # Output:
    #  table_sorted_reordered_lists
    #  titles_reordered_list
    #  titles_reordered_html_list


    # Track the columns that aren't sorted
    # int_sequence_list may have empty strings indicating hidden col reference
    set unsorted_list $int_sequence_list
    foreach ii $sort_order_list {
        set ii_pos $sort_col_pos_map_arr(${ii})

        # Blank the reference instead of removing it, 
        # or the $ii_pos reference won't work later on..
        if { [lindex $ii_pos ] ne "" } {
            set unsorted_list [lreplace $unsorted_list $ii_pos $ii_pos "" ]
        }
    }
    set unsorted_compressed_list [list ]
    foreach ii $unsorted_list {
        if { $ii ne "" } {
            lappend unsorted_compressed_list $ii
        }
    }

    #  titles_list
    set titles_reordered_list [list ]
    #  titles_html_list
    set titles_reordered_html_list [list ]    
    set reordered_idx_list [list ]
    foreach ii $sort_order_list {
        set ii_pos $sort_col_pos_map_arr(${ii})
        lappend col_idx_reordered_list $ii_pos
        lappend titles_reordered_list [lindex $titles_list $ii_pos ]
        lappend titles_reordered_html_list [lindex $titles_html_list $ii_pos ]
    }

    # Now that the sorted columns are added to the rows, 
    # add the remaining columns
    foreach ui $unsorted_compressed_list {
        # Add unsorted column to row
        lappend titles_reordered_list [lindex $titles_list $ui ]
        lappend titles_reordered_html_list [lindex $titles_html_list $ui ]
        lappend col_idx_reordered_list $ui
    }

    # Repeat for the table rows: 

    set table_sorted_reordered_lists [list ]

    # Rebuild the table, one row at a time, 
    # Add the primary sorted column, then secondary sorted columns in order


    foreach table_row_list $table_sorted_paginated_lists {

        set table_row_new_list [list ]

        # Add the sorted columns
        foreach ii_pos $col_idx_reordered_list {
            lappend table_row_new_list [lindex $table_row_list $ii_pos ]
        }
        # Append new row to new table
        lappend table_sorted_reordered_lists $table_row_new_list
    }

    # ================================================
    # Display customizations
    # ================================================

    # Add UI Options column to table?
    # Not at this time. 
    # Must be added in advance, or added via exposed interim process variables.

    # ================================================
    # 7. Format output 
    # ================================================
    # Add attributes to the TABLE tag
    set table_tag_attribute_list 

    # Add cell formatting to TD tags
    set cell_formating_list [list ]

    set integer_c "integer"
    set real_c "real"
    set title_td_attrs_list [list ]
    set row_td_attrs_list [list ]

    # Don't use col_idx_reordered_list here, because
    # sort_order_list and unsorted_compressed_list elements
    # have different attribute sets
    foreach ii $sort_order_list {
        set ii_pos $sort_col_pos_map_arr(${ii})
        set column_type [string range [lindex $sort_type_list $ii_pos ] 1 end ]

        if { $column_type eq $integer_c || $column_type eq $real_c } {
            lappend title_td_attrs_list ${th_sorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_number_attribute_list} \
                                           ${td_sorted_attribute_list} ]
        } else {
            lappend title_td_attrs_list ${th_sorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_nonnumber_attribute_list} \
                                           ${td_sorted_attribute_list} ]
        }
    }
    foreach ii_pos $unsorted_compressed_list {
        set column_type [string range [lindex $sort_type_list $ii_pos ] 1 end ]

        if { $column_type eq $integer_c || $column_type eq $real_c } {
            lappend title_td_attrs_list ${th_unsorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_number_attribute_list} \
                                           ${td_unsorted_attribute_list} ]
        } else {
            lappend title_td_attrs_list ${th_unsorted_attribute_list}
            lappend row_td_attrs_list [concat ${td_attribute_list} \
                                           ${td_nonnumber_attribute_list} \
                                           ${td_unsorted_attribute_list} ]
        }
    }


    set cell_format_reordered_lists [list $title_td_attrs_list \
                                         $row_td_attrs_list \
                                         $row_td_attrs_list ]

    # Rebuild the even/odd rows, add column based variances
    # When column order changes, 
    # then formatting of the TD tags may change, too.
    # So, re-order the formatting columns, 
    # Use the same looping logic from when the table columns changed order
    # to avoid inconsistencies

    set table_row_count [llength $table_sorted_reordered_lists ]

    # Build html table
    set table_sorted_reordered_w_titles_lists [linsert $table_sorted_reordered_lists 0 $titles_reordered_html_list ]
    set c "class"
    set d "grid-flex content-box grid-1 m-grid-4 s-grid-12"
    set e "grid-3 m-grid-4 s-grid-12"
    set c_type1 [list $c $d]
    set c_type2 [list $c $e]
    set td_div_outer_attribute_lists [list $c_type1 $c_type1 $c_type1 $c_type1 $c_type1 $c_type1 $c_type1 $c_type1 $c_type1 $c_type2]

    set table_html [qss_list_of_lists_to_responsive_table \
                        -table_list_of_lists_name table_sorted_reordered_w_titles_lists \
                        -table_div_attribute_list_name table_tag_attribute_list \
                        -td_div_outer_attribute_lists_name td_div_outer_attribute_lists \
                        -td_div_inner_attribute_lists_name cell_format_reordered_lists \
                        -th_rows "1" \
                        -tr_div_even_attribute_list_name tr_even_attribute_list \
                        -tr_div_odd_attribute_list_name tr_odd_attribute_list \
                        -th_div_attribute_list_name tr_header_attribute_list ]

    return 1
}

