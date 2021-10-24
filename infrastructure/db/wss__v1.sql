create schema public;

comment on schema public is 'standard public schema';

alter schema public owner to "wssAdmin";

create table regions_and_bases
(
	region varchar not null
		constraint regions_and_bases_pk
			primary key,
	base varchar not null
);

alter table regions_and_bases owner to "wssAdmin";

create unique index regions_and_bases_region_uindex
	on regions_and_bases (region);

create table variable_names
(
	variable_code varchar not null
		constraint variable_names_pk
			primary key,
	variable_name text not null,
	variable_notes text not null
);

alter table variable_names owner to "wssAdmin";

create unique index variable_names_variable_code_uindex
	on variable_names (variable_code);

create table scores_by_child
(
	fcp_id varchar(6) not null,
	local_beneficiary_id varchar(11) not null,
	gender varchar not null,
	ci_natl_office_name varchar not null,
	region varchar not null
		constraint scores_by_child_regions_and_bases_region_fk
			references regions_and_bases,
	age_group varchar not null,
	variable_code varchar not null
		constraint scores_by_child_variable_names_variable_code_fk
			references variable_names,
	score numeric not null,
	"unique" boolean not null,
	score_id serial not null
		constraint scores_by_child_pk
			primary key
);

alter table scores_by_child owner to "wssAdmin";

create unique index scores_by_child_score_id_uindex
	on scores_by_child (score_id);
