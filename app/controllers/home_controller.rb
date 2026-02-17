# frozen_string_literal: true

class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[index]

  def show
    set_seo_metadata
  end


  def index
  end

  private

  def set_seo_metadata
    set_meta_tags(
      title: @article.title,
      description: @article.summary,
      keywords: [ @article.title, "rails", "web development", @article.category ].join(", ")
    )
  end
end
