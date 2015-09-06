require 'ostruct'

module Polymorpheus
  class InterfaceBuilder

    attr_reader :interface_name,
                :associations

    def initialize(interface_name, association_names, options)
      @interface_name = interface_name
      @associations = association_names.map do |association_name|
        Polymorpheus::InterfaceBuilder::Association.new(association_name, options)
      end
    end

    def exposed_interface(calling_object)
      OpenStruct.new(
        associations: associations,
        active_association: active_association(calling_object),
        query_condition: query_condition(calling_object)
      )
    end

    def association_keys
      @association_keys ||= associations.map(&:key)
    end

    def association_names
      @association_names ||= associations.map(&:name)
    end

    def active_association(calling_object)
      active_associations = associations.select do |association|
        # If the calling object has a non-nil value for the association
        # key, we know it has an active associatin without having to
        # make a database query to retrieve the associated object itself.
        #
        # If it has a nil value for the association key, we then ask if
        # it has a non-nil result for the association itself, since it
        # may have an active association that has not yet been saved to
        # the database.
        #
        calling_object.public_send(association.key).present? ||
          calling_object.public_send(association.name).present?
      end

      active_associations.first if active_associations.length == 1
    end

    def active_association_key(calling_object)
      association = active_association(calling_object)
      return unless association

      association.key if calling_object.public_send(association.key)
    end

    def query_condition(calling_object)
      key = active_association_key(calling_object)
      object = calling_object.public_send(key) if key

      { key.to_s => object } if object
    end

    def get_associated_object(calling_object)
      association = active_association(calling_object)
      calling_object.public_send(association.name) if association
    end

    def set_associated_object(calling_object, object_to_associate)
      association = get_relevant_association_for_object(object_to_associate)
      calling_object.public_send("#{association.name}=", object_to_associate)

      (associations - [association]).each do |association|
        calling_object.public_send("#{association.name}=", nil)
      end
    end

    def get_relevant_association_for_object(object_to_associate)
      match = associations.select do |association|
        object_to_associate.is_a?(association.association_class)
      end

      if match.blank?
        raise Polymorpheus::Interface::InvalidTypeError, association_names
      elsif match.length > 1
        raise Polymorpheus::Interface::AmbiguousTypeError
      end

      match.first
    end

  end
end
