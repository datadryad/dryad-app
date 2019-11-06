# this is a crazy monkeypatch to allow the orcid to be passed into the developer login form if it was previously chosen and this is second phase of login
OmniAuth::Strategies::Developer.class_eval do
  # pass in the request params so we can use them in the form
  def request_phase
    form = OmniAuth::Form.new(title: 'User Info', url: callback_path, params: request.params)
    options.fields.each do |field|
      form.text_field field.to_s.capitalize.tr('_', ' '), field.to_s
    end
    form.button 'Sign In'
    form.to_response
  end
end

OmniAuth::Form.class_eval do
  # this should repost any passed in values to the fields here
  def input_field(type, name)
    @html << "\n<input type='#{type}' id='#{name}' name='#{name}' value='#{options[:params][name]}'/>"
    self
  end
end
