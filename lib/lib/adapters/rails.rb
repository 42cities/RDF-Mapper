module RDFMapper
  module Adapters
    ##
    # [-]
    ##
    class Rails < Base
      
      ##
      # [-]
      ##
      def initialize(cls, options = {})
        @rdf, @options = cls, options
        @options[:skip] ||= []
        @options[:substitute] ||= { }
        @options[:substitute][:id] ||= :uid
      end


      ##
      # [-]
      ##
      def load(query)
        @rdf.associations.values.select do |assoc|
          assoc.belongs_to?
        end.map do |assoc|
          assoc.name
        end.reject do |name|
          @options[:skip].include?(name)
        end.each do |name|
          query.include!(name)
        end
        Query.new(query, @options).find
      end
      
      ##
      # [-]
      ##
      def save(instance)
        if instance[:rails_id].nil?
          obj = instance.class.find(instance.id.to_s).from(:rails)
          instance[:rails_id] = obj.rails_id unless obj.nil?
        end
        if instance[:rails_id].nil?
          create(instance)
        else
          update(instance)
        end
      end
      
      ##
      # [-]
      ##
      def reload(instance)
        query = RDFMapper::Scope::Query.new(instance.class, :conditions => { :id => instance.id })
        Query.new(query, @options).find.first
      end
      
      ##
      # [-]
      ##
      def update(instance)
        query = RDFMapper::Scope::Query.new(instance.class, :conditions => instance.properties)
        Query.new(query, @options).update
      end
      
      ##
      # [-]
      ##
      def create(instance)
        query = RDFMapper::Scope::Query.new(instance.class, :conditions => instance.properties)
        Query.new(query, @options).create
      end
      
      
      private
      
      def check_for_rails_id(instance)
      end

      class Query
        
        include RDFMapper::Logger
        
        def initialize(query, options = {})
          @query, @options = query, options
          @rails = (@options[:class_name] || @query.cls.to_s.demodulize).constantize
          setup_replacements
        end
        
        ##
        # [-]
        ##
        def update
          record = @rails.update(@query[:rails_id], save_options)
          record_attributes(record)
        end
        
        ##
        # [-]
        ##
        def create
          record = @rails.create(save_options)
          record_attributes(record)
        end
        
        ##
        # [-]
        ##
        def find
          @query.check(:rails_id)
          #
          #debug 'Searching for %s with %s' % [@rails, @query.inspect]
          #debug 'Query: %s' % find_options.inspect
          #
          @rails.find(:all, find_options).map do |record|
            record_attributes(record)
          end
        end

        
        private
        
        ##
        # [-]
        ##
        def record_attributes(record)
          record_id = [:id, :rails_id].map do |name|
            [name, record_value(record, name)]
          end
          record_props = record_properties(record)
          record_assoc = record_associations(record)
          Hash[record_id + record_props + record_assoc]
        end
        
        ##
        # [-]
        ##
        def save_options
          Hash[@query.to_a.map do |condition|
            name = @replace[condition.name]
            if condition.value.kind_of? RDFMapper::Model
              value = condition.value[:rails_id]
            else
              value = condition.value
            end
            [name, value]
          end.reject do |name, value|
            name.nil? or value.nil?
          end]
        end
        
        ##
        # Substitutes names of those attributes specified in `options[:substitute]`
        # and raises a runtime error for attributes that could not be found in the
        # database. Returns an object which can then be used with ActiveRecord::Base.find
        ##
        def find_options #nodoc
          { :conditions => SQL.new(@query, @replace).to_a,
            :order => @query.order,
            :limit => @query.limit,
            :offset => @query.offset,
            :include => @query.include
          }.delete_if { |name, value| value.nil? }
        end
        
        ##
        # [-]
        ##
        def setup_replacements #nodoc
          @replace = default_replacements
          @query.flatten.map do |condition|
            # Original RDF name
            rdf_name = condition.name
            # Expected name in the DB
            expected_name = @replace[rdf_name] || rdf_name
            # Silently ignore attributes that are not in the DB
            rails_name = activerecord_attribute?(expected_name)
            @replace[rdf_name] = rails_name unless rails_name.nil?
          end
        end
        
        ##
        # [-]
        ##
        def default_replacements
          @options[:substitute].merge({ :rails_id => :id })
        end
        
        ##
        # [-]
        ##
        def record_properties(record) #nodoc
          @query.cls.properties.keys.map do |name|
            value = record_value(record, name)
            [name, value]
          end
        end

        ##
        # [-]
        ##
        def record_associations(record) #nodoc
          @query.include.map do |name|
            value = record_value(record, name)
            value = value.nil? ? nil : value[@replace[:id]]
            [name, value]
          end
        end
        
        ##
        # [-]
        ##
        def record_value(record, rdf_name) #nodoc
          name = default_replacements[rdf_name] || rdf_name
          unless record.respond_to?(name)
            nil
          else
            record.send(name)
          end
        end
        
        ##
        # [-]
        ##
        def activerecord_attribute?(name) #nodoc
          activerecord_property?(name) || activerecord_association?(name)
        end

        ##
        # [-]
        ##
        def activerecord_association?(name) #nodoc
          reflection = @rails.reflections[name.to_sym]
          if reflection.nil? or not reflection.belongs_to?
            return nil
          end
          reflection.primary_key_name.to_sym
        end

        ##
        # [-]
        ##
        def activerecord_property?(name) #nodoc
          @rails.column_names.include?(name.to_s) ? name.to_sym : nil
        end
        
        class SQL
          
          def initialize(query, replace)
            @query, @replace = query, replace
            @text, @values = [], []

            @query.to_a.map do |condition|
              if condition.kind_of?(query.class)
                add_query(condition)
              else
                add_condition(condition)
              end
            end
          end
          
          def add_query(query)
            child = SQL.new(query, @replace)
            unless child.text.empty?
              @text.push("(%s)" % child.text)
              @values.push(*child.values)
            end
          end
          
          def add_condition(condition)
            name = @replace[condition.name]
            if name.nil?
              return nil
            end
            if condition.value.kind_of?(Array)
              @text << "%s IN (?)" % name
            else
              @text << "%s %s ?" % [name, condition.eq]
            end
            @values << validate(condition.value)
          end
          
          def validate(value) #nodoc
            if value.kind_of? Array
              return value.map do |item|
                validate(item)
              end
            end
            if value.kind_of? RDFMapper::Model
              value[:rails_id]
            else
              value
            end
          end
          
          def text
            @text.join(' %s ' % @query.modifier)
          end
          
          def values
            @values
          end
          
          def to_a
            [text] + values
          end
          
        end # SQL
      end # Query
    end # Rails
  end # Adapters
end # RDFMapper