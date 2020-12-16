# frozen_string_literal: true

class PagesController < ApplicationController
  def privacy_policy
    respond_to :html
  end

  def terms_and_conditions
    respond_to :html
  end

  def robots
    respond_to :text
  end

  def sitemap
    respond_to :xml
  end
end
