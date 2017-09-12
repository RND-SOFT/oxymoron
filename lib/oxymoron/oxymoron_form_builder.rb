class OxymoronFormBuilder < ActionView::Helpers::FormBuilder
  (field_helpers - [:label, :check_box, :radio_button, :fields_for, :hidden_field, :file_field]).each do |selector|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{selector}(method, options = {})  # def text_field(method, options = {})
        options['ng-model'] = compute_ng_model(method, options)
        @template.send(                      #   @template.send(
          #{selector.inspect},               #     "text_field",
          @object_name,                      #     @object_name,
          method,                            #     method,
          objectify_options(options))        #     objectify_options(options))
      end                                    # end
    RUBY_EVAL
  end

  def radio_button method, tag_value, options = {}
    options['ng-model'] = compute_ng_model(method, options)
    super
  end

  def check_box method, options = {}, checked_value = "1", unchecked_value = "0"
    options['ng-model'] = compute_ng_model(method, options)
    super
  end

  def number_field method, options = {}
    options['ng-model'] = compute_ng_model(method, options)
    super
  end

  def select method, choices = nil, options = {}, html_options = {}, &block
    html_options['ng-model'] = compute_ng_model(method, html_options)
    super
  end

  def file_field method, options = {}
    options = options.with_indifferent_access
    options = options.merge({
      "ng-model" => compute_ng_model(method, options),
      "onchange" => options["onchange"] || "angular.element(this).scope().#{compute_ng_model(method, options)} = this.files[0]; angular.element(this).scope().$apply();"
    })
    super
  end

  def ng_select method, options = {}
    options = options.with_indifferent_access
    options = options.merge({
      "name" => "#{@object_name}[#{method}]",
      "ng-model" => compute_ng_model(method, options),
      "ng-options" => options["ng-options"] || "#{method}.#{options[:value_method]} as #{method}.#{options[:title_method]} for #{method} in #{options[:collection]}"
    })

    ActionController::Base.helpers.content_tag(:select, nil, options)
  end

  def ng_select2 method, options = {}
    options = options.with_indifferent_access
    options = options.merge({
      "name" => "#{@object_name}[#{method}]",
      "ng-model" => compute_ng_model(method, options),
      "s2-options" => options["s2-options"] || "#{method}.#{options[:value_method]} as #{method}.#{options[:title_method]} for #{method} in #{options[:collection]}"
    })

    ActionController::Base.helpers.content_tag(:select2, nil, options)
  end



  protected
    def ng_model method = nil
      object_name = @object_name.to_s.gsub(/\[([\w]+)\]/, "['\\1']")

      get_all_child_indexes.each do |index|
        object_name.gsub!(/'(#{index})'/, "\\1")
      end

      prefix = @options[:prefix] || 'ctrl' rescue "ctrl"

      if method
        "#{prefix}.#{object_name}['#{method}']".html_safe
      else
        "#{prefix}.#{object_name}".html_safe
      end
    end

    def compute_ng_model method, options
      options = options.with_indifferent_access
      options['ng-model'] || ng_model(options[:field] || (options[:multiple] ? "#{method}_ids" : method))
    end

    #Рассчитывает oxymoron-совместимый id, основываясь на ng-model
    def compute_id method, options = {}
      model = compute_ng_model(method, options)
      id = model.gsub(/[\[\]\.\,\'\"]+/, '_').gsub('___', '_').gsub('__', '_').gsub(/^_/, '').gsub(/_$/, '')

      get_all_child_indexes.each do |index|
        id.gsub!(/_(#{index})_/, "_{{\\1}}_")
      end

      id
    end

    #Локализатор который пытается использовать перевод из родителя
    def i18n method
      @object.class.human_attribute_name(method)
    rescue
      record_name = object_name.split('][').last.gsub(/[^\w]/, '') rescue nil
      options[:parent_builder].object.class.human_attribute_name("#{record_name}/#{method}") rescue method
    end

    #Все значения :child_index для всех вышележащих fields_for
    def get_all_child_indexes
      get_parent_builders(self).map {|b| b.options[:child_index]}.compact
    end

    def get_parent_builders builder
      if builder.options[:parent_builder]
        get_parent_builders(builder.options[:parent_builder])
      else
        []
      end + [builder]
    end



end