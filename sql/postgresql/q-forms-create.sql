-- q-forms-create.sql
--
-- @author Benjamin Brink
-- @for OpenACS
-- @cvs-id
--

-- The purpose of table qf_key_map is to answer the question:
--   How do we know the posted data is directly from a form presented to a user, 
--   and not the result of some kind of surrepitious form post?
-- By logging somewhat unique aspects of a form rendering transaction,
-- and checking them against form post values.

-- Form rendering uniqueness includes: location (form action), time rendered, session_id, and port (ssl y/n)

-- Using a random key to reference the data points where we can filter the form entry by the key
-- and subsequently check its data point values, ignoring any case where the key doesn't fit.

-- For random_key, we are using a local version of sec_random_token
--  from packages/acs-tcl/tcl/security-procs.tcl
-- For general security session notes, see /doc/security-design.html
CREATE TABLE qf_key_map (
       instance_id integer,
       -- ns_time in seconds for speed, for timeout checks
       rendered_timestamp numeric,
       sec_hash varchar(256),
       -- this is just the id passed to the form tag
       key_id varchar(300),
       session_id varchar(100),
       -- this should be ns_conn url
       action_url varchar(300),
       secure_conn_p integer,
       -- client_ip may seem to duplicate session_id, but 
       -- session_id resides as a cookie so is hackable,
       -- whereas client_ip is not
       client_ip varchar(30),
       -- if avail_p is 0, then the form has already been posted
       -- and the key is no longer available.
       submit_timestamp numeric default null
);

create index qf_key_map_sec_hash_idx on qw_key_map (sec_hash);
create index qf_key_map_rendered_timestamp_idx on qw_key_map (rendered_timestamp);
create index qf_key_map_instance_idx on qw_key_map (instance_id);

--  Set up a scheduled proc to regularly clean up where submit_timestamp is null and rendered_timestamp < timeout

-- The standard is to not save the data point values, just a hash of them.
-- That makes it more difficult to reverse hack the form state even with access to the db.
-- ie an action_url couldn't be used to reduce the possilbe matches in the table.

