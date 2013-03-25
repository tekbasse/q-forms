-- q-forms-drop.sql
--
-- @author Benjamin Brink
-- @for OpenACS
-- @cvs-id
--
drop index qf_key_map_instance_id_idx;
drop index qf_key_map_rendered_timestamp_idx;
drop index qf_key_map_sec_hash_idx;

drop table qf_key_map;
