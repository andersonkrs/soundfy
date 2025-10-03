class AdminController < ApplicationController
  def index
    render inertia: "Admin"
  end
end
