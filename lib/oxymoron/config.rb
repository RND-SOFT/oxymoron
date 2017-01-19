module Oxymoron

  class Config
    class << self

      attr_accessor :oxymoron_js_path
      attr_accessor :rewrite_form_for
      attr_accessor :ng_notify
      attr_accessor :form_validate
      attr_accessor :form_builder

      def setup
        yield self
      end

    end
    @rewrite_form_for = true
    @form_builder = OxymoronFormBuilder
    @ng_notify = true
    @form_validate = true

  end

end