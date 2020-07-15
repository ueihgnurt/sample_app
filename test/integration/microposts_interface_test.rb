require "test_helper"

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:hieu)
  end
  test "micropost interface" do
    log_in_as(@user)
    get root_path
    assert_select "div.pagination"
    assert_select "input[type=file]"
    post microposts_path, params: { micropost: { content: "" } }
    assert_select "div#error_explanation"
    assert_select "a[href=?]", "/?page=2"
    content = "This micropost really ties the room together"
    image = fixture_file_upload("kitten.jpg", "image/jpeg")
    assert_no_difference "Micropost.count" do
      post microposts_path, params: { micropost: { content: content,
                                                   image:   image } }
    end
    assert assigns(:micropost).image.attached?
    assert root_path
    assert_match content, response.body
    assert_select "a", "delete"
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference "Micropost.count", -1 do
      delete micropost_path(first_micropost)
    end
    get user_path(users(:archer))
    assert_select "a", { text: "delete", count: 0 }
  end

  test "micropost sidebar count" do
    log_in_as(@user)
    get root_path
    assert_match "34 microposts", response.body
    other_user = users(:archer)
    log_in_as(other_user)
    get root_path
    assert_match "2 microposts", response.body
    other_user.microposts.create!(content: "A micropost")
    get root_path
    assert_match "3 micropost", response.body
  end
end
