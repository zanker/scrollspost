class Api::V1::BaseController < ApplicationController
  def require_authentication
    @user = User.where(:_id => params[:user_id].to_s).only(:write_api_key).first
    unless @user
      return render_error(:no_user)
    end

    unless @user.write_api_key == params[:api_key].to_s
      return render_error(:bad_key)
    end
  end

  def respond_with_model(model)
     if model.errors.empty?
       render :json => {:id => model._id}
     else
       data = {:errors => {}.merge(model.errors.messages), :attributes => {}, :scope => model.class.collection_name.singularize}
       data[:errors].each_key {|e| data[:attributes][e] = model.class.human_attribute_name(e)}

       # Check for children
       data[:errors].merge!(load_model_errors(model, data[:attributes]))

       render :json => data
     end
  end

  def render_error(type)
    return render :json => {:error => type}
  end

  def render_response(res)
    render :json => res
  end
end