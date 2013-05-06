use utf8;

package AuditTestRenamedTables::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components(qw/Schema::AuditLog/);

__PACKAGE__->load_namespaces(
    result_namespace => "+AuditTest::Schema::Result",
    resultset_namespace => "+AuditTest::Schema::ResultSet",
    default_resultset_class => "+DBIx::Class::ResultSet::AuditLog" );


# renaming the table for DBIC::Schema::AuditLog::Structure::Action
DBIx::Class::Schema::AuditLog::Structure::Action->table("history_action");

1;
