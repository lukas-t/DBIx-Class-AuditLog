package DBIx::Class::AuditLog;

use base qw/DBIx::Class/;

use strict;
use warnings;

our $VERSION = '0.010000';

=head1 DBIx::Class OVERRIDDEN METHODS

=head2 insert

=cut
sub insert {
    my $self = shift;

    return $self->next::method(@_) if $self->in_storage;

    my $result = $self->next::method(@_);

    my ( $action, $table ) = $self->_action_setup( $result, 'insert' );

    if ( $action ) {
        my %column_data = $result->get_columns;
    
        foreach my $column ( keys %column_data ) {
            my $field
                = $table->find_or_create_related( 'Field', { name => $column } );
    
            $action->create_related(
                'Change',
                {   field     => $field->id,
                    new_value => $result->$column,
                }
            );
        }
    }

    return $result;

}

=head2 update

=cut
sub update {
    my $self = shift;

    my $stored_row = $self->get_from_storage;

    # find the list of passed in update values when $row->update({...}) is used
    my $updated_column_set = $_[0];

    # add any values from $row->update({...}) to the dirty_column list
    # any columns changed via $row->columnName(...) get added to this
    # list automatically
    foreach my $updated_column ( keys %{$updated_column_set}) {
        $self->$updated_column($updated_column_set->{$updated_column});
    }

    my %dirty_columns = $self->get_dirty_columns;

    my ( $action, $table ) = $self->_action_setup( $stored_row, 'update' );

    if ( $action ) {
        foreach my $column ( keys %dirty_columns ) {
            my $field
                = $table->find_or_create_related( 'Field', { name => $column } );
    
            $action->create_related(
                'Change',
                {   field     => $field->id,
                    old_value => $stored_row->$column,
                    new_value => $dirty_columns{$column},
                }
            );
        }
    }

    return $self->next::method(@_)
}

=head2 delete

=cut
sub delete {
    my $self = shift;

    my $stored_row = $self->get_from_storage;

    my ( $action, $table ) = $self->_action_setup( $stored_row, 'delete' );

    if ( $action ) {
        my %column_data = $stored_row->get_columns;
    
        foreach my $column ( keys %column_data ) {
            my $field
                = $table->find_or_create_related( 'Field', { name => $column } );
    
            $action->create_related(
                'Change',
                {   field     => $field->id,
                    old_value => $stored_row->$column,
                }
            );
        }
    }

    return $self->next::method(@_);
}

=head1 HELPER METHODS

=head2 _audit_log_schema

Returns the AuditLog schema from storage.

=cut

sub _audit_log_schema {
    my $self = shift;
    return $self->result_source->schema->audit_log_schema;
}

=head2 _action_setup

Creates a new AuditLog Action for a specific type.

Requires:
    row: primary key of the table that is being audited
    type: action type, 1 of insert/update/delete

=cut
sub _action_setup {
    my $self = shift;
    my $row  = shift;
    my $type = shift;
    
    my ($action, $table);

    ($action, $table) = $self->_audit_log_schema->audit_log_create_action(
        {   row   => $row->id,
            table => $row->result_source_instance->name,
            type  => $type,
        }
    );

    return ( $action, $table );
}

1;
