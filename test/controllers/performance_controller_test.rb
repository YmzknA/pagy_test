require "test_helper"

class PerformanceControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get performance_index_url
    assert_response :success
  end

  test "should get pagy_demo" do
    get performance_pagy_demo_url
    assert_response :success
  end

  test "should get kaminari_demo" do
    get performance_kaminari_demo_url
    assert_response :success
  end

end
