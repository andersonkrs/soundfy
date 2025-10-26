require "test_helper"

class Shopify::AudioUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shop = shops(:bossa_nova_hits)
    @audio_file = fixture_file_upload("bossa_nova_serge_quadrado.mp3", "audio/mpeg")

    setup_shopify_session(session_id: "test-session", shop_domain: @shop.shopify_domain)
  end

  test "should create blob with correct attributes" do
    post shopify_audio_uploads_url, params: {file: @audio_file}

    assert_response :created

    blob = ActiveStorage::Blob.last
    assert_equal "bossa_nova_serge_quadrado.mp3", blob.filename.to_s
    assert_equal "audio/mpeg", blob.content_type
    assert blob.analyzed?, "Blob should be analyzed"
  end

  test "should successfully upload audio file" do
    post shopify_audio_uploads_url, params: {file: @audio_file}

    assert_response :created

    assert response.parsed_body["blob"]
    assert response.parsed_body["blob"]["signed_id"]
    assert_equal "bossa_nova_serge_quadrado.mp3", response.parsed_body["blob"]["filename"]
    assert response.parsed_body["blob"]["title"]
    assert response.parsed_body["blob"]["artist"]
    assert response.parsed_body["blob"]["cover_art"]
  end

  test "should reject file larger than 50MB" do
    large_file = fixture_file_upload("bossa_nova_serge_quadrado.mp3", "audio/mpeg")
    large_file_mock = mock("large_file")
    large_file_mock.stubs(:size).returns(51.megabytes)
    large_file_mock.stubs(:content_type).returns("audio/mpeg")
    large_file_mock.stubs(:original_filename).returns("test.mp3")
    large_file_mock.stubs(:tempfile).returns(large_file.tempfile)

    # Stub the controller's file method to return our mock
    Shopify::AudioUploadsController.any_instance.stubs(:file_param).returns(large_file_mock)

    post shopify_audio_uploads_url, params: {file: large_file}

    assert_response :unprocessable_entity

    assert_includes response.parsed_body["error"], "File too large. Maximum size is 50 MB"
  end

  test "should accept file at exactly 50MB" do
    exact_file = fixture_file_upload("bossa_nova_serge_quadrado.mp3", "audio/mpeg")
    exact_file_mock = mock("exact_file")
    exact_file_mock.stubs(:size).returns(50.megabytes)
    exact_file_mock.stubs(:content_type).returns("audio/mpeg")
    exact_file_mock.stubs(:original_filename).returns("test.mp3")
    exact_file_mock.stubs(:tempfile).returns(exact_file.tempfile)

    Shopify::AudioUploadsController.any_instance.stubs(:file_param).returns(exact_file_mock)

    post shopify_audio_uploads_url, params: {file: exact_file}

    assert_response :created
  end

  test "should reject invalid content type" do
    invalid_file = fixture_file_upload("bossa_nova_serge_quadrado.mp3", "video/mp4")

    post shopify_audio_uploads_url, params: {file: invalid_file}

    assert_response :unprocessable_entity

    assert_includes response.parsed_body["error"], "Invalid file type"
    assert_includes response.parsed_body["error"], "audio/mpeg"
  end

  test "should accept all allowed audio content types" do
    allowed_types = [
      "audio/mpeg",
      "audio/wav"
    ]

    allowed_types.each do |content_type|
      audio_file = fixture_file_upload("bossa_nova_serge_quadrado.mp3", content_type)

      post shopify_audio_uploads_url, params: {file: audio_file}

      assert_response :created, "Should accept #{content_type}"
    end
  end

  test "should require file parameter" do
    post shopify_audio_uploads_url, params: {}

    assert_response :bad_request
  end
end
