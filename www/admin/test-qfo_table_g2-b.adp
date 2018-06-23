<master>
<if @doc@ defined><property name="&doc">doc</property></if>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<p>
  @__qfsp_nav_prev_links_html;noquote@
  &nbsp; 
  @__qfsp_nav_current_pos_html@
  &nbsp; 
  @__qfsp_nav_next_links_html;noquote@
</p>

@content;noquote@
