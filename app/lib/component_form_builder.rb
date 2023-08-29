# frozen_string_literal: true

# NOTE: This form builder has taken a lot of inspiration, and some code snippets
# * [ViewComponent::Form](https://github.com/pantographe/view_component-form)
# * [SimpleForm](https://github.com/heartcombo/simple_form)
# Both of these projects are released under the MIT License

class ComponentFormBuilder < ActionView::Helpers::FormBuilder
  COMPONENT_MAP = {}.freeze

  def input(method, as: nil, **, &block)
    component = component_klass(method:, as:).new(form: self, name: method, **)
    component.render_in(@template, &block)
  end

  private

  def component_klass(method:, as:)
    type = as.presence || input_type(method:)
    "Forms::#{COMPONENT_MAP[type].presence || type.capitalize}InputComponent".constantize
  end

  def input_type(method:)
    input_type = find_attribute_column(method:).try(:type)
    case input_type
    when :timestamp
      :datetime
    when :string, :citext, nil
      attachment?(method:) ? :file : (string_type(method:).presence || input_type.presence || :string)
    else
      input_type
    end
  end

  def string_type(method:)
    case method.to_s
    when /(?:\b|\W|_)password(?:\b|\W|_)/  then :password
    when /(?:\b|\W|_)time_zone(?:\b|\W|_)/ then :time_zone
    when /(?:\b|\W|_)country(?:\b|\W|_)/   then :country
    when /(?:\b|\W|_)email(?:\b|\W|_)/     then :email
    when /(?:\b|\W|_)phone(?:\b|\W|_)/     then :tel
    when /(?:\b|\W|_)url(?:\b|\W|_)/       then :url
    end
  end

  def attachment?(method:)
    @object.respond_to?(:"#{method}_attachment") || @object.respond_to?(:"#{method}_attachments")
  end

  def find_attribute_column(method:)
    return unless @object.respond_to?(:type_for_attribute) && @object.has_attribute?(method)

    @object.type_for_attribute(method)
  end
end
