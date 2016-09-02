-- q-forms-drop.sql
--
--  @Copyright (c) 2010-5 Benjamin Brink
--  @license GNU General Public License 2, see project home for details.
--  @project home: http://github.com/tekbasse/q-forms
--  @address: po box 20, Marylhurst, OR 97036-0020 usa
--  @email: tekbasse@yahoo.com
--
drop index qf_name_value_pairs_sh_key_id_idx;

drop table qf_name_value_pairs;

drop index qf_key_map_instance_id_idx;
drop index qf_key_map_rendered_timestamp_idx;
drop index qf_key_map_sec_hash_idx;

drop table qf_key_map;

drop sequence qf_id_seq;
