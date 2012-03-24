# -*- encoding : utf-8 -*-
require 'test_helper'

class RealValuesControllerTest < ActionController::TestCase
  setup do
    @real_value = real_values(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:real_values)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create real_value" do
    assert_difference('RealValue.count') do
      post :create, real_value: @real_value.attributes
    end

    assert_redirected_to real_value_path(assigns(:real_value))
  end

  test "should show real_value" do
    get :show, id: @real_value.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @real_value.to_param
    assert_response :success
  end

  test "should update real_value" do
    put :update, id: @real_value.to_param, real_value: @real_value.attributes
    assert_redirected_to real_value_path(assigns(:real_value))
  end

  test "should destroy real_value" do
    assert_difference('RealValue.count', -1) do
      delete :destroy, id: @real_value.to_param
    end

    assert_redirected_to real_values_path
  end
end
